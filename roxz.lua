-- ============================================================
-- apk_loader.lua â€” APK-injected watchdog
-- Boot pe khud fire hota hai (APK ke andar se call hoga)
-- Watch dir: /storage/emulated/0/Android/data/com.pubg.imobile/files/LUA/
-- Behavior: scan all *.lua, run, watch for changes, re-run on change
-- ============================================================

local WATCH_DIR = "/storage/emulated/0/Android/data/com.pubg.imobile/files/LUA/"
local LOG_FILE  = WATCH_DIR .. "_loader.log"
local POLL_SEC  = 1.0
local MAX_FILES = 200

-- ============================================================
-- POPUP
-- ============================================================
local function POPUP(title, msg)
    pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
                    or require("client.slua.logic.common.logic_common_msg_box")
        if Msg and Msg.Show then Msg.Show(4, tostring(title), tostring(msg)) end
    end)
end

-- ============================================================
-- LOG (turant disk pe)
-- ============================================================
local function LOG(msg)
    pcall(function()
        local f = io.open(LOG_FILE, "a")
        if f then
            f:write(string.format("[%s] %s\n", os.date("%H:%M:%S"), tostring(msg)))
            f:close()
        end
    end)
end

LOG("=== LOADER BOOT "..os.date("%Y-%m-%d %H:%M:%S").." ===")
LOG("WATCH_DIR: "..WATCH_DIR)

-- ============================================================
-- FILE LIST â€” ls first, brute fallback
-- ============================================================
local function listLuaFiles()
    local out, seen = {}, {}

    -- Method 1: ls via popen
    pcall(function()
        local p = io.popen("ls -1 "..WATCH_DIR.." 2>/dev/null")
        if p then
            for line in p:lines() do
                line = line:gsub("^%s+", ""):gsub("%s+$", "")
                if line ~= "" and line:sub(-4) == ".lua" and not seen[line] then
                    seen[line] = true
                    out[#out+1] = line
                end
            end
            p:close()
        end
    end)

    if #out > 0 then return out, "ls" end

    -- Method 2: brute numeric (1.lua .. 50.lua)
    for i = 1, 50 do
        local name = i..".lua"
        local f = io.open(WATCH_DIR..name, "r")
        if f then
            f:close()
            if not seen[name] then seen[name] = true; out[#out+1] = name end
        end
    end

    -- Method 3: common names
    local common = {
        "loader.lua","dumper.lua","ur_dumper.lua","main.lua","script.lua",
        "hack.lua","mod.lua","test.lua","ur.lua","ultimate.lua",
        "security.lua","bypass.lua","esp.lua","aim.lua","menu.lua",
        "config.lua","init.lua","start.lua",
    }
    for _, name in ipairs(common) do
        local f = io.open(WATCH_DIR..name, "r")
        if f then
            f:close()
            if not seen[name] then seen[name] = true; out[#out+1] = name end
        end
    end

    return out, "brute"
end

-- ============================================================
-- HASH â€” content fingerprint
-- ============================================================
local function HASH(s)
    if not s then return nil end
    local h = 5381
    for i = 1, #s do h = (h * 33 + s:byte(i)) % 4294967296 end
    return string.format("%x_%d", h, #s)
end

local function READ(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local c = f:read("*a")
    f:close()
    return c
end

-- ============================================================
-- RUNNER
-- ============================================================
local _state    = {}       -- filename -> last content hash
local _runs     = 0
local _errs     = 0

local function RUN_FILE(fname)
    local path = WATCH_DIR..fname
    local src = READ(path)
    if not src or #src == 0 then return false end

    local h = HASH(src)
    if _state[fname] == h then return false end   -- unchanged

    _state[fname] = h
    LOG("RUN "..fname.." bytes="..#src.." hash="..h)

    local chunk, err
    if loadstring then
        chunk, err = loadstring(src, "@"..fname)
    else
        chunk, err = load(src, "@"..fname)
    end

    if not chunk then
        _errs = _errs + 1
        LOG("COMPILE-FAIL "..fname.." : "..tostring(err))
        POPUP("LOADER: compile fail", fname.."\n"..tostring(err):sub(1,180))
        return false
    end

    local ok, rerr = pcall(chunk)
    if not ok then
        _errs = _errs + 1
        LOG("RUNTIME-FAIL "..fname.." : "..tostring(rerr))
        POPUP("LOADER: runtime fail", fname.."\n"..tostring(rerr):sub(1,180))
        return false
    end

    _runs = _runs + 1
    LOG("OK "..fname)
    return true
end

-- ============================================================
-- SCAN LOOP
-- ============================================================
local function SCAN(reason)
    local files, method = listLuaFiles()
    LOG("scan("..reason..") method="..method.." found="..#files)

    if #files == 0 then return end
    if #files > MAX_FILES then
        LOG("too many files, truncating to "..MAX_FILES)
        files = { unpack(files, 1, MAX_FILES) }
    end

    for _, fname in ipairs(files) do
        pcall(RUN_FILE, fname)
    end
end

-- ============================================================
-- BOOT SCAN
-- ============================================================
POPUP("LOADER", "Booting...\n"..WATCH_DIR)

SCAN("boot")

POPUP("LOADER READY",
    string.format("Files run: %d\nErrors: %d\nWatching every %.1fs",
        _runs, _errs, POLL_SEC))

LOG("boot done runs=".._runs.." errs=".._errs)

-- ============================================================
-- WATCHDOG TIMER
-- ============================================================
local _armed = false

local function ARM()
    if _armed then return end
    local ticker = nil
    pcall(function() ticker = require("common.time_ticker") end)

    if ticker and ticker.AddTimerLoop then
        ticker.AddTimerLoop(0, function() pcall(SCAN, "poll") end, -1, POLL_SEC)
        _armed = true
        LOG("watchdog armed "..POLL_SEC.."s")
    else
        LOG("FATAL: no time_ticker â€” loader cannot poll")
        POPUP("LOADER", "no time_ticker\npoll disabled")
    end
end

pcall(ARM)

-- ============================================================
-- OPTIONAL MANUAL API
-- ============================================================
_G.LOADER_Scan = function() pcall(SCAN, "manual") end
_G.LOADER_Status = function()
    local n = 0; for _ in pairs(_state) do n = n + 1 end
    local msg = string.format("runs=%d errs=%d tracked=%d\n%s", _runs, _errs, n, LOG_FILE)
    POPUP("LOADER", msg)
    LOG("status "..msg)
end
_G.LOADER_Run = function(name) pcall(RUN_FILE, name) end
_G.LOADER_Clear = function()
    _state = {}
    LOG("state cleared")
end

print("[apk_loader] armed â€” dir="..WATCH_DIR.." poll="..POLL_SEC.."s")
