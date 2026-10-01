-- ===============================================================
-- hotload.lua v2 — hot-reload loader, io.popen-free
-- Enumerates mods via: manifest file, os.execute+redirect, lfs,
-- hardcoded candidates. Runs every .lua found. Re-runs on change.
-- ===============================================================

local CFG = {
    MODS_DIR = "/storage/emulated/0/Android/data/com.pubg.imobile/files/mods/",
    LOG = "/storage/emulated/0/Android/data/com.pubg.imobile/files/mods/hotload.log",
    MANIFEST = "/storage/emulated/0/Android/data/com.pubg.imobile/files/mods/mods.txt",
    SCAN_INTERVAL = 3,
    POPUP = false,
    MAX_FILE_SIZE = 512 * 1024,
    -- Filenames to try even if enumeration fails. Add yours here.
    KNOWN = {
        "hotload.lua",
        "gdump.lua",
        "mdump.lua",
        "pdump.lua",
        "mod.lua",
        "main.lua",
        "init.lua",
        "loader.lua",
        "script.lua",
        "hack.lua",
        "cheat.lua",
        "dumper.lua",
    },
}

-- ============ POPUP ============
local function POPUP(title, msg)
    pcall(function()
        local M = package.loaded["client.slua.logic.common.logic_common_msg_box"]
                    or require("client.slua.logic.common.logic_common_msg_box")
        if M and M.Show then M.Show(4, tostring(title), tostring(msg)) end
    end)
end

-- ============ LOG ============
local logN = 0
local function logLine(msg)
    logN = logN + 1
    local line = string.format("[%s] %s", os.date("%H:%M:%S"), msg)
    pcall(function()
        local f = io.open(CFG.LOG, "a")
        if f then f:write(line .. "\n"); f:close() end
    end)
    print("[HL] " .. line)
end

-- ============ ENUMERATION STRATEGIES ============

-- Strategy A: manifest file mods.txt (one filename per line)
local function enumManifest()
    local out = {}
    local f = io.open(CFG.MANIFEST, "r")
    if not f then return out end
    for line in f:lines() do
        line = line:gsub("%s+$", ""):gsub("^%s+", "")
        if line ~= "" and line:sub(1,1) ~= "#" then
            out[#out+1] = CFG.MODS_DIR .. line
        end
    end
    f:close()
    return out
end

-- Strategy B: os.execute + redirect to temp file, read it
local function enumShellRedirect()
    local out = {}
    local tmp = CFG.MODS_DIR .. "_ls_tmp.txt"
    -- Try several shell variants
    local cmds = {
        "ls -1 '" .. CFG.MODS_DIR .. "' 2>/dev/null > '" .. tmp .. "'",
        "ls '" .. CFG.MODS_DIR .. "' > '" .. tmp .. "' 2>&1",
        "find '" .. CFG.MODS_DIR .. "' -maxdepth 1 -name '*.lua' > '" .. tmp .. "' 2>&1",
    }
    for _, cmd in ipairs(cmds) do
        pcall(function() os.execute(cmd) end)
        local f = io.open(tmp, "r")
        if f then
            for line in f:lines() do
                local name = line:match("([^/]+)$")
                if name and name:find("%.lua$") then
                    out[#out+1] = CFG.MODS_DIR .. name
                end
            end
            f:close()
            if #out > 0 then
                pcall(function() os.remove(tmp) end)
                return out
            end
        end
    end
    pcall(function() os.remove(tmp) end)
    return out
end

-- Strategy C: io.popen (still try, some builds have it)
local function enumPopen()
    local out = {}
    pcall(function()
        local p = io.popen("ls -1 '" .. CFG.MODS_DIR .. "' 2>/dev/null")
        if p then
            for line in p:lines() do
                local name = line:match("([^/]+)$")
                if name and name:find("%.lua$") then
                    out[#out+1] = CFG.MODS_DIR .. name
                end
            end
            p:close()
        end
    end)
    return out
end

-- Strategy D: lfs (LuaFileSystem) if available
local function enumLFS()
    local out = {}
    pcall(function()
        local ok, lfs = pcall(require, "lfs")
        if not ok or not lfs then return end
        for file in lfs.dir(CFG.MODS_DIR) do
            if file ~= "." and file ~= ".." and file:find("%.lua$") then
                out[#out+1] = CFG.MODS_DIR .. file
            end
        end
    end)
    return out
end

-- Strategy E: hardcoded candidate names
local function enumKnown()
    local out = {}
    for _, name in ipairs(CFG.KNOWN) do
        local path = CFG.MODS_DIR .. name
        local f = io.open(path, "r")
        if f then
            f:close()
            out[#out+1] = path
        end
    end
    return out
end

-- Dedupe
local function dedupe(list)
    local seen, out = {}, {}
    for _, p in ipairs(list) do
        if not seen[p] then
            seen[p] = true
            out[#out+1] = p
        end
    end
    return out
end

-- Master enumerator
local function listModFiles()
    local a = enumManifest()
    if #a > 0 then return dedupe(a), "manifest" end
    local b = enumShellRedirect()
    if #b > 0 then return dedupe(b), "shell" end
    local c = enumPopen()
    if #c > 0 then return dedupe(c), "popen" end
    local d = enumLFS()
    if #d > 0 then return dedupe(d), "lfs" end
    local e = enumKnown()
    return dedupe(e), "known"
end

-- ============ FILE HASH ============
local function fileHash(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local data = f:read("*a") or ""
    f:close()
    if #data == 0 then return "empty" end
    local sum = 0
    for i = 1, math.min(#data, 4096) do
        sum = (sum + data:byte(i)) % 1000000007
    end
    return string.format("%d|%d|%s|%s", #data, sum, data:sub(1, 32), data:sub(-32))
end

-- ============ EXEC ============
local function execFile(path)
    local f = io.open(path, "r")
    if not f then return false, "open failed" end
    local src = f:read("*a") or ""
    f:close()
    if #src == 0 then return false, "empty" end
    if #src > CFG.MAX_FILE_SIZE then return false, "too big" end
    src = src:gsub("^\239\187\191", "")
    local fn, err
    if loadstring then fn, err = loadstring(src, "@" .. path)
    elseif load then fn, err = load(src, "@" .. path, "t") end
    if not fn then return false, "compile: " .. tostring(err) end
    local ok, res = pcall(fn)
    if not ok then return false, "run: " .. tostring(res) end
    return true, res
end

-- ============ STATE ============
local fileState = {}
local loadCount, failCount = 0, 0
local lastStrategy = "?"

local function scanOnce()
    local files, strat = listModFiles()
    lastStrategy = strat
    if strat ~= "manifest" and #files == 0 then
        -- Nothing found on first scan — log once
        if logN < 5 then logLine("WARN: 0 files found. strategy=" .. strat) end
    end
    for _, path in ipairs(files) do
        local h = fileHash(path)
        if h and fileState[path] ~= h then
            fileState[path] = h
            local name = path:match("([^/]+)$") or path
            local ok, err = execFile(path)
            if ok then
                loadCount = loadCount + 1
                logLine("LOADED " .. name .. " (via " .. strat .. ")")
                if CFG.POPUP then POPUP("HOTLOAD", "Loaded: " .. name) end
            else
                failCount = failCount + 1
                logLine("FAILED " .. name .. " — " .. tostring(err))
                if CFG.POPUP then POPUP("HOTLOAD FAIL", name .. "\n" .. tostring(err)) end
            end
        end
    end
end

-- ============ BOOT ============
logLine("=== hotload v2 boot ===")
logLine("MODS_DIR=" .. CFG.MODS_DIR)

-- Sanity: can we even see the dir?
do
    local probe = CFG.MODS_DIR .. ".probe"
    local f = io.open(probe, "w")
    if f then f:write("ok"); f:close()
        logLine("dir writable: yes")
        pcall(function() os.remove(probe) end)
    else
        logLine("dir writable: NO — path wrong or perms")
    end
end

scanOnce()
logLine(string.format("initial: loaded=%d fail=%d strategy=%s", loadCount, failCount, lastStrategy))

-- ============ LOOP ============
local function safeReq(...)
    for _, p in ipairs({...}) do
        local ok, m = pcall(require, p)
        if ok and m then return m end
    end
    return nil
end

local ticker = safeReq("common.time_ticker")
if not ticker or not ticker.AddTimerLoop then
    logLine("FATAL: no time_ticker")
    if CFG.POPUP then POPUP("HOTLOAD", "No time_ticker") end
    return
end

ticker.AddTimerLoop(0, function()
    pcall(scanOnce)
end, -1, CFG.SCAN_INTERVAL)

logLine("=== hotload v2 active ===")

-- ============ PUBLIC API ============
_G.HotloadStatus = function()
    local n = 0
    for _ in pairs(fileState) do n = n + 1 end
    local msg = string.format("loaded=%d fail=%d\nfiles=%d\nstrategy=%s\n%s",
        loadCount, failCount, n, lastStrategy, CFG.MODS_DIR)
    POPUP("HOTLOAD", msg)
end

_G.HotloadRescan = function()
    fileState = {}
    scanOnce()
    POPUP("HOTLOAD", "Rescan: loaded=" .. loadCount .. " strat=" .. lastStrategy)
end

-- Convenience: write mods.txt manifest from Lua
_G.HotloadWriteManifest = function(names)
    local f = io.open(CFG.MANIFEST, "w")
    if not f then return false end
    for _, n in ipairs(names or {}) do
        f:write(n .. "\n")
    end
    f:close()
    return true
end
