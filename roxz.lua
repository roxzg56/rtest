-- ===============================================================
-- hotload.lua — hot-reload loader for gacha mods
-- Watches mods/ folder. Any .lua file added/changed runs instantly.
-- No game restart needed. Idempotent hooks re-apply cleanly.
-- ===============================================================

local CFG = {
    MODS_DIR = "/storage/emulated/0/Android/data/com.pubg.imobile/files/mods/",
    SCAN_INTERVAL = 3,      -- seconds between scans
    POPUP = false,          -- change to true for load confirmation
    MAX_FILE_SIZE = 512 * 1024,  -- skip > 512KB (sanity)
}

-- ============ POPUP ============
local function POPUP(title, msg)
    pcall(function()
        local M = package.loaded["client.slua.logic.common.logic_common_msg_box"]
                    or require("client.slua.logic.common.logic_common_msg_box")
        if M and M.Show then M.Show(4, tostring(title), tostring(msg)) end
    end)
end

-- ============ FILE LIST ============
local function listModFiles()
    local files = {}
    -- Method A: io.popen ls (best case)
    pcall(function()
        local p = io.popen("ls " .. CFG.MODS_DIR .. " 2>/dev/null")
        if p then
            for line in p:lines() do
                if line:match("%.lua$") and line:sub(1,1) ~= "." then
                    files[#files+1] = CFG.MODS_DIR .. line
                end
            end
            p:close()
        end
    end)
    return files
end

-- ============ SIMPLE HASH (size + byte-sum + head/tail) ============
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
    local head = data:sub(1, 32)
    local tail = data:sub(-32)
    return string.format("%d|%d|%s|%s", #data, sum, head, tail)
end

-- ============ LOAD ONE FILE ============
local function execFile(path)
    local f = io.open(path, "r")
    if not f then return false, "open failed" end
    local src = f:read("*a") or ""
    f:close()
    if #src == 0 then return false, "empty" end
    if #src > CFG.MAX_FILE_SIZE then return false, "too big" end
    -- strip UTF-8 BOM
    src = src:gsub("^\239\187\191", "")
    -- build loader fn
    local fn, err
    if loadstring then
        fn, err = loadstring(src, "@" .. path)
    elseif load then
        fn, err = load(src, "@" .. path, "t")
    end
    if not fn then return false, "compile: " .. tostring(err) end
    local ok, res = pcall(fn)
    if not ok then return false, "run: " .. tostring(res) end
    return true, res
end

-- ============ STATE ============
local fileState = {}   -- [path] = hash
local loadCount, failCount = 0, 0
local log = {}

local function logLine(msg)
    log[#log+1] = string.format("[%s] %s", os.date("%H:%M:%S"), msg)
    -- also write to a log file
    pcall(function()
        local f = io.open(CFG.MODS_DIR .. "hotload.log", "a")
        if f then f:write(log[#log] .. "\n"); f:close() end
    end)
end

local function scanOnce()
    local files = listModFiles()
    for _, path in ipairs(files) do
        local h = fileHash(path)
        if h and fileState[path] ~= h then
            fileState[path] = h
            local name = path:match("([^/]+)$") or path
            local ok, err = execFile(path)
            if ok then
                loadCount = loadCount + 1
                logLine("LOADED " .. name)
                if CFG.POPUP then POPUP("HOTLOAD", "Loaded: " .. name) end
            else
                failCount = failCount + 1
                logLine("FAILED " .. name .. " — " .. tostring(err))
                if CFG.POPUP then POPUP("HOTLOAD FAIL", name .. "\n" .. tostring(err)) end
            end
        end
    end
end

-- ============ INITIAL SCAN (catches existing files) ============
logLine("=== hotload boot ===")
scanOnce()
logLine(string.format("initial: loaded=%d fail=%d", loadCount, failCount))

-- ============ TICKER LOOP ============
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

logLine("=== hotload active ===")

-- ============ PUBLIC API ============
_G.HotloadStatus = function()
    local msg = string.format("loaded=%d fail=%d\nfiles=%d\nwatch=%s",
        loadCount, failCount,
        (function() local n=0 for _ in pairs(fileState) do n=n+1 end return n end)(),
        CFG.MODS_DIR)
    POPUP("HOTLOAD", msg)
end

_G.HotloadRescan = function()
    fileState = {}   -- clear so all files reload
    scanOnce()
    POPUP("HOTLOAD", "Rescan: loaded=" .. loadCount)
end

_G.HotloadWatch = function()  -- force a fresh single file
    scanOnce()
end
