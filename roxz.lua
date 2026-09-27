-- ═══════════════════════════════════════════════════════════════════
-- ROXZ-Loader v2 — Hot reload with kill-old-timers
-- PAK me BRPlayerCharacterBase.lua me daal
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local DIR = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"
    local LOGF = DIR .. "loader.log"

    local function A(line)
        local f = io.open(LOGF, "a")
        if f then f:write("[" .. os.date("%H:%M:%S") .. "] " .. tostring(line) .. "\n"); f:close() end
    end

    -- Only install once per session
    if _G.__ROXZ_LOADER then
        A("loader already active — rescanning")
        if _G.__ROXZ_SCAN then pcall(_G.__ROXZ_SCAN) end
        return
    end
    _G.__ROXZ_LOADER = true

    -- Fresh log
    local f0 = io.open(LOGF, "w")
    if f0 then f0:write("=== ROXZ-Loader v2 " .. os.date("%Y-%m-%d %H:%M:%S") .. " ===\n"); f0:close() end
    A("boot")

    -- ═══════════════════════════════════════════════════════════════
    -- HARDCODED FILENAME LIST — io.popen fail hone pe ye use hoga
    -- Naya script daala to yahan naam add kar dena (ya 'active.lua' naam rakho)
    -- ═══════════════════════════════════════════════════════════════
    local KNOWN = {
        "active.lua",
        "run.lua",
        "main.lua",
        "inject.lua",
        "script.lua",
        "mod.lua",
        "v79.lua", "v80.lua", "v81.lua", "v82.lua", "v83.lua",
        "v84.lua", "v85.lua", "v86.lua", "v87.lua", "v88.lua", "v89.lua", "v90.lua",
    }

    -- ═══════════════════════════════════════════════════════════════
    -- TIMER TRACKING — per-script
    -- ═══════════════════════════════════════════════════════════════
    _G.__TIMER_REG   = _G.__TIMER_REG   or {}   -- [tid] = scriptName
    _G.__SCRIPT_OF   = _G.__SCRIPT_OF   or {}   -- [scriptName] = {tid,...}
    _G.__CUR_SCRIPT  = nil

    local function trackTimer(tid)
        if not tid then return end
        local cur = _G.__CUR_SCRIPT or "session"
        _G.__TIMER_REG[tid] = cur
        _G.__SCRIPT_OF[cur] = _G.__SCRIPT_OF[cur] or {}
        table.insert(_G.__SCRIPT_OF[cur], tid)
    end

    local function killTimersOf(name)
        local list = _G.__SCRIPT_OF[name]
        if not list then return 0 end
        local tk = nil
        pcall(function() tk = require("common.time_ticker") end)
        local killed = 0
        for _, tid in ipairs(list) do
            pcall(function()
                if tk then
                    if tk.RemoveTimerLoop then tk.RemoveTimerLoop(tid) end
                    if tk.RemoveTimer     then tk.RemoveTimer(tid)     end
                    if tk.ClearTimer      then tk.ClearTimer(tid)      end
                end
                if _G.RemoveGameTimer then pcall(_G.RemoveGameTimer, tid) end
            end)
            _G.__TIMER_REG[tid] = nil
            killed = killed + 1
        end
        _G.__SCRIPT_OF[name] = {}
        return killed
    end

    -- ═══════════════════════════════════════════════════════════════
    -- HOOK time_ticker — auto-track har script ke timers
    -- ═══════════════════════════════════════════════════════════════
    pcall(function()
        local tk = require("common.time_ticker")
        if not tk or tk._roxz_hooked then return end
        tk._roxz_hooked = true

        if tk.AddTimerLoop then
            local orig = tk.AddTimerLoop
            tk.AddTimerLoop = function(delay, fn, n, interval, ...)
                local tid = orig(delay, fn, n, interval, ...)
                trackTimer(tid)
                return tid
            end
        end

        if tk.AddTimerOnce then
            local orig = tk.AddTimerOnce
            tk.AddTimerOnce = function(delay, fn, ...)
                local tid = orig(delay, fn, ...)
                trackTimer(tid)
                return tid
            end
        end
        A("timer hooks installed")
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- HASH — skip same-content reloads
    -- ═══════════════════════════════════════════════════════════════
    local function hash(s)
        local h = 5381
        for i = 1, #s do h = (h * 33 + s:byte(i)) % 4294967296 end
        return h
    end

    local HASHES = {}

    -- ═══════════════════════════════════════════════════════════════
    -- LOAD ONE SCRIPT
    -- ═══════════════════════════════════════════════════════════════
    local function tryLoad(name)
        local path = DIR .. name
        local f = io.open(path, "r")
        if not f then return "missing" end
        local src = f:read("*a")
        f:close()
        if not src or #src == 0 then return "empty" end

        local h = hash(src)
        if HASHES[name] == h then return "skip" end

        -- Kill old timers of this script (reload case)
        local killed = killTimersOf(name)
        if killed > 0 then A("killed " .. killed .. " old timers of " .. name) end

        _G.__CUR_SCRIPT = name

        local fn, perr = (loadstring or load)(src, name)
        if not fn then
            A("PARSE FAIL " .. name .. " :: " .. tostring(perr):sub(1,120))
            _G.__CUR_SCRIPT = nil
            return "parse_fail"
        end

        local ok, rerr = pcall(fn)
        _G.__CUR_SCRIPT = nil
        HASHES[name] = h

        if ok then
            A("OK " .. name .. " (hash=" .. h .. ")")
            return "ok"
        else
            A("RUN ERR " .. name .. " :: " .. tostring(rerr):sub(1,200))
            return "run_err"
        end
    end

    -- ═══════════════════════════════════════════════════════════════
    -- SCAN — list + load
    -- ═══════════════════════════════════════════════════════════════
    local LAST_SEEN = {}

    local function scan()
        local loaded, missing = 0, 0
        local current = {}

        -- Try io.popen first (some devices support)
        local used_popen = false
        pcall(function()
            local pipe = io.popen("ls " .. DIR .. " 2>/dev/null")
            if pipe then
                for line in pipe:lines() do
                    local n = line:match("([^%s/]+)$")
                    if n and n:match("%.lua$") and n ~= "ROXZ-Loader.lua" then
                        current[n] = true
                        used_popen = true
                    end
                end
                pipe:close()
            end
        end)

        -- Fallback: hardcoded list
        if not used_popen then
            for _, n in ipairs(KNOWN) do
                local f = io.open(DIR .. n, "r")
                if f then
                    f:close()
                    current[n] = true
                end
            end
        end

        -- Load all found
        for n in pairs(current) do
            local r = tryLoad(n)
            if r == "ok" then loaded = loaded + 1
            elseif r == "missing" then missing = missing + 1 end
        end

        -- Files that disappeared — kill their timers
        for old in pairs(LAST_SEEN) do
            if not current[old] then
                local k = killTimersOf(old)
                if k > 0 then A("killed " .. k .. " timers of deleted " .. old) end
                HASHES[old] = nil
            end
        end
        LAST_SEEN = current

        A("scan: loaded=" .. loaded .. " active=" .. (function() local c=0 for _ in pairs(current) do c=c+1 end return c end)())
    end

    _G.__ROXZ_SCAN = scan

    A("initial scan")
    scan()

    -- ═══════════════════════════════════════════════════════════════
    -- WATCHER
    -- ═══════════════════════════════════════════════════════════════
    pcall(function()
        local tk = require("common.time_ticker")
        if tk and tk.AddTimerLoop then
            tk.AddTimerLoop(0, function()
                pcall(scan)
            end, -1, 1.5)
            A("watcher @ 1.5s")
        end
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- PUBLIC API
    -- ═══════════════════════════════════════════════════════════════
    _G.ROXZ_SCAN = scan
    _G.ROXZ_KILL_ALL = function()
        local n = 0
        for name in pairs(_G.__SCRIPT_OF) do n = n + killTimersOf(name) end
        A("manual killAll: " .. n)
        return n
    end
    _G.ROXZ_KILL_ONE = function(name)
        local n = killTimersOf(name)
        A("killed " .. n .. " timers of " .. tostring(name))
        return n
    end

    A("loader ready")
end)
-- ═══════════════════════════════════════════════════════════════════
-- END LOADER — original code continue
-- ═══════════════════════════════════════════════════════════════════
