-- ═══════════════════════════════════════════════════════════════════
-- loader.lua — auto-scans mod folder + runs every .lua file
-- Drop-in. Any .lua in the folder loads automatically.
-- Logs success/fail per file to loader_log.txt
-- ═══════════════════════════════════════════════════════════════════

if _G._ModLoader_Loaded then return end
_G._ModLoader_Loaded = true

-- ─── PATHS ─────────────────────────────────────────────────────────
local SAVE_DIRS = {
    "/storage/emulated/0/Android/data/com.pubg.imobile/files/",
    "/storage/emulated/0/Android/data/com.pubg.krmobile/files/",
    "/storage/emulated/0/Android/data/com.vng.pubgmobile/files/",
    "/storage/emulated/0/Android/data/com.rekoo.pubgm/files/",
}
local function getSaveDir()
    local i
    for i = 1, #SAVE_DIRS do
        local f = io.open(SAVE_DIRS[i] .. "config.ini", "r")
        if f then f:close(); return SAVE_DIRS[i] end
    end
    return SAVE_DIRS[1]
end

-- ★ Folder jahan mods hain — yahan apne mod .lua files daalo
local MOD_DIR = getSaveDir() .. "mods/"
local LOADER_LOG = getSaveDir() .. "loader_log.txt"

-- Create mods folder if missing
pcall(function()
    local testf = io.open(MOD_DIR .. "test.txt", "w")
    if testf then testf:close() end
end)

-- ─── LOG ───────────────────────────────────────────────────────────
local logBuf = {}
local function L(msg)
    logBuf[#logBuf + 1] = "[" .. os.date("%H:%M:%S") .. "] " .. tostring(msg)
    -- Flush every 10 lines
    if #logBuf >= 10 then
        pcall(function()
            local f = io.open(LOADER_LOG, "a")
            if f then
                f:write(table.concat(logBuf, "\n") .. "\n")
                f:close()
            end
        end)
        logBuf = {}
    end
end

local function flushLog()
    if #logBuf == 0 then return end
    pcall(function()
        local f = io.open(LOADER_LOG, "a")
        if f then
            f:write(table.concat(logBuf, "\n") .. "\n")
            f:close()
        end
    end)
    logBuf = {}
end

-- ─── SCAN FOLDER ───────────────────────────────────────────────────
-- Lua io doesn't have listdir. We use a trick with popen if available.
local function listDir(path)
    local files = {}
    -- Try popen (works on some builds)
    pcall(function()
        local pipe = io.popen('ls "' .. path .. '" 2>/dev/null')
        if pipe then
            for line in pipe:lines() do
                if line and line ~= "" then
                    files[#files + 1] = line
                end
            end
            pipe:close()
        end
    end)
    return files
end

-- ─── LOAD SINGLE FILE ──────────────────────────────────────────────
local function loadFile(filepath)
    local f = io.open(filepath, "r")
    if not f then return false, "cannot open" end
    local content = f:read("*a")
    f:close()
    if not content or content == "" then return false, "empty file" end

    local chunk, err = loadstring(content, "@" .. filepath)
    if not chunk then
        return false, "compile error: " .. tostring(err)
    end

    local ok, runErr = pcall(chunk)
    if not ok then
        return false, "runtime error: " .. tostring(runErr)
    end
    return true, "ok"
end

-- ─── LOAD ALL MODS ─────────────────────────────────────────────────
local function loadAllMods()
    L("════════════════════════════════════════════════")
    L("LOADER START — " .. os.date("%Y-%m-%d %H:%M:%S"))
    L("MOD DIR: " .. MOD_DIR)
    L("════════════════════════════════════════════════")

    local files = listDir(MOD_DIR)
    L("Scanned: " .. #files .. " entries")

    local loaded, failed = 0, 0
    local i
    for i = 1, #files do
        local name = files[i]
        -- Only .lua files
        if name:sub(-4):lower() == ".lua" then
            local fullpath = MOD_DIR .. name
            L("")
            L("→ Loading: " .. name)
            local ok, err = loadFile(fullpath)
            if ok then
                loaded = loaded + 1
                L("  ✅ SUCCESS")
            else
                failed = failed + 1
                L("  ❌ FAIL: " .. err)
            end
        end
    end

    L("")
    L("════════════════════════════════════════════════")
    L("RESULT: " .. loaded .. " loaded, " .. failed .. " failed")
    L("════════════════════════════════════════════════")
    flushLog()

    print("[ModLoader] " .. loaded .. " mods loaded, " .. failed .. " failed")
    print("[ModLoader] log: " .. LOADER_LOG)
end

-- ─── BOOT ──────────────────────────────────────────────────────────
pcall(function()
    local t = require("common.time_ticker")
    if t and t.AddTimerOnce then
        t.AddTimerOnce(2.0, loadAllMods)
    else
        loadAllMods()
    end
end)

-- Auto-flush log every 5s
pcall(function()
    local t = require("common.time_ticker")
    if t and t.AddTimerLoop then
        t.AddTimerLoop(0, flushLog, -1, 5.0)
    end
end)

print("[ModLoader] armed — mod dir: " .. MOD_DIR)
print("[ModLoader] drop .lua files there, restart, they auto-load")

return _G._ModLoader_Loaded
