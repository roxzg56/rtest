-- ═══════════════════════════════════════════════════════════════════
-- v78-Loader.lua — REPLACE the loader inside BRPlayerCharacterBase.lua
-- Naya script load hote hi PURANI script ke saare timers KILL ho jaate hain
-- ═══════════════════════════════════════════════════════════════════

local DIR = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"
local LOGF = DIR .. "loader.log"

local function A(line)
    local f = io.open(LOGF, "a")
    if f then f:write("[" .. os.date("%H:%M:%S") .. "] " .. tostring(line) .. "\n"); f:close() end
end

local f0 = io.open(LOGF, "w")
if f0 then f0:write("=== Loader " .. os.date("%Y-%m-%d %H:%M:%S") .. " ===\n"); f0:close() end

A("boot")

-- ═══════════════════════════════════════════════════════════════════
-- GUARD: only install once per session
-- ═══════════════════════════════════════════════════════════════════
if _G.__LOADER_V78 then
    A("loader already active — rescanning")
    if _G.__LOADER_SCAN then pcall(_G.__LOADER_SCAN) end
    return true
end
_G.__LOADER_V78 = true

-- ═══════════════════════════════════════════════════════════════════
-- GLOBAL TIMER REGISTRY
-- Every AddTimerLoop/AddTimerOnce call gets tracked per-script
-- ═══════════════════════════════════════════════════════════════════
_G.__TIMER_REG = _G.__TIMER_REG or {}     -- [tid] = {script = name, tk = tickerAPI}
_G.__SCRIPT_OF = _G.__SCRIPT_OF or {}     -- [scriptName] = {tids...}
_G.__CURRENT_SCRIPT = nil                  -- jo abhi load ho rahi hai

local function trackTimer(tid, scriptName)
    if not tid then return end
    _G.__TIMER_REG[tid] = { script = scriptName or "?" }
    local s = scriptName or "?"
    _G.__SCRIPT_OF[s] = _G.__SCRIPT_OF[s] or {}
    table.insert(_G.__SCRIPT_OF[s], tid)
end

local function killTimersOf(scriptName)
    local list = _G.__SCRIPT_OF[scriptName]
    if not list then return 0 end
    local killed = 0
    local tk = nil
    pcall(function() tk = require("common.time_ticker") end)
    for _, tid in ipairs(list) do
        pcall(function()
            if tk then
                if tk.RemoveTimerLoop then tk.RemoveTimerLoop(tid) end
                if tk.RemoveTimer then tk.RemoveTimer(tid) end
                if tk.ClearTimer then tk.ClearTimer(tid) end
            end
            -- Also try engine-side
            if _G.RemoveGameTimer then pcall(_G.RemoveGameTimer, tid) end
        end)
        _G.__TIMER_REG[tid] = nil
        killed = killed + 1
    end
    _G.__SCRIPT_OF[scriptName] = {}
    return killed
end

local function killAll()
    local total = 0
    for name in pairs(_G.__SCRIPT_OF) do
        total = total + killTimersOf(name)
    end
    return total
end

-- ═══════════════════════════════════════════════════════════════════
-- HOOK time_ticker.AddTimerLoop + AddTimerOnce (GLOBAL)
-- Taaki koi bhi script timer lagaye — hum use track karein
-- ═══════════════════════════════════════════════════════════════════
local function installTimerHooks()
    pcall(function()
        local tk = require("common.time_ticker")
        if not tk or tk._v78_hooked then return end
        tk._v78_hooked = true

        -- AddTimerLoop wrapper
        if tk.AddTimerLoop then
            local orig = tk.AddTimerLoop
            tk.AddTimerLoop = function(delay, fn, n, interval, ...)
                local cur = _G.__CURRENT_SCRIPT or "session"
                -- Wrap fn with generation guard
                local wrapped = function(...)
                    -- If the script that registered this was killed, exit
                    local reg = _G.__TIMER_REG
                    if reg and _G.__SCRIPT_OF[cur] then
                        local found = false
                        for _, t in ipairs(_G.__SCRIPT_OF[cur]) do
                            if t == tid_holder or not t then found = true; break end
                        end
                    end
                    return fn(...)
                end
                local tid = orig(delay, wrapped, n, interval, ...)
                trackTimer(tid, cur)
                return tid
            end
        end

        if tk.AddTimerOnce then
            local orig = tk.AddTimerOnce
            tk.AddTimerOnce = function(delay, fn, ...)
                local cur = _G.__CURRENT_SCRIPT or "session"
                local tid = orig(delay, fn, ...)
                trackTimer(tid, cur)
                return tid
            end
        end
        A("timer hooks installed")
    end)
end

installTimerHooks()

-- ═══════════════════════════════════════════════════════════════════
-- SCRIPT LOADER — purani script kill karke nayi load karo
-- ═══════════════════════════════════════════════════════════════════
local function hash(s)
    local h = 5381
    for i = 1, #s do h = (h * 33 + s:byte(i)) % 4294967296 end
    return h
end

local HASHES = {}    -- [name] = hash

local function loadScript(name, src)
    local h = hash(src)
    if HASHES[name] == h then return "skip" end

    -- ★ NAYA VERSION — pehle iske purane timers kill karo
    local killed = killTimersOf(name)
    if killed > 0 then A("killed " .. killed .. " old timers of " .. name) end

    -- ★ SET CURRENT SCRIPT — iske andar jo bhi AddTimerLoop hoga, humare naam se track
    _G.__CURRENT_SCRIPT = name

    local fn, perr = (loadstring or load)(src, name)
    if not fn then
        A("parse fail " .. name .. " :: " .. tostring(perr):sub(1,120))
        _G.__CURRENT_SCRIPT = nil
        return "fail"
    end

    local ok, rerr = pcall(fn)
    _G.__CURRENT_SCRIPT = nil

    HASHES[name] = h
    if ok then
        A("loaded " .. name .. " hash=" .. h)
        return "ok"
    else
        A("run err " .. name .. " :: " .. tostring(rerr):sub(1,200))
        return "err"
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- SCAN FOLDER + RELOAD
-- ═══════════════════════════════════════════════════════════════════
local function listLua()
    local names = {}
    local ok, pipe = pcall(io.popen, "ls " .. DIR .. "*.lua 2>/dev/null")
    if ok and pipe then
        for line in pipe:lines() do
            local n = line:match("([^/]+)$")
            if n and n:match("%.lua$") and n ~= "v78-Loader.lua" then
                names[#names+1] = n
            end
        end
        pipe:close()
    end
    return names
end

-- ★ TRACK which files exist RIGHT NOW — jo delete ho gaye unke timers bhi kill
local LAST_FILE_SET = {}

local function scan()
    local current = {}
    for _, n in ipairs(listLua()) do
        current[n] = true
        local f = io.open(DIR .. n, "r")
        if f then
            local src = f:read("*a"); f:close()
            if src and #src > 0 then
                pcall(loadScript, n, src)
            end
        end
    end
    -- ★ Files that DISAPPEARED — kill their timers too
    for old in pairs(LAST_FILE_SET) do
        if not current[old] then
            local k = killTimersOf(old)
            if k > 0 then A("killed " .. k .. " timers of deleted " .. old) end
            HASHES[old] = nil
        end
    end
    LAST_FILE_SET = current
end

A("initial scan")
scan()

-- ═══════════════════════════════════════════════════════════════════
-- WATCHER — har 1.5s folder scan
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local tk = require("common.time_ticker")
    if tk and tk.AddTimerLoop then
        tk.AddTimerLoop(0, function()
            pcall(scan)
        end, -1, 1.5)
        A("watcher @ 1.5s")
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════════════════
_G.LOADER_SCAN = scan
_G.LOADER_KILL_ALL = function()
    local k = killAll()
    A("manual killAll → " .. k)
    return k
end

A("loader ready")
return true
