-- ═══════════════════════════════════════════════════════════════════
-- LOADER v79-FIX — Hardcoded filename list (no io.popen)
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local DIR = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"
    local LOGF = DIR .. "loader.log"

    local function A(line)
        local f = io.open(LOGF, "a")
        if f then f:write("[" .. os.date("%H:%M:%S") .. "] " .. tostring(line) .. "\n"); f:close() end
    end

    -- Fresh log
    local f0 = io.open(LOGF, "w")
    if f0 then f0:write("=== Loader v79-FIX " .. os.date("%Y-%m-%d %H:%M:%S") .. " ===\n"); f0:close() end

    A("boot")

    if _G.__LOADER_FIX then
        A("already active, rescanning")
        if _G.__LOADER_FIX_SCAN then pcall(_G.__LOADER_FIX_SCAN) end
        return
    end
    _G.__LOADER_FIX = true

    -- ★ HARDCODED FILENAME LIST — no io.popen
    -- Apni script ka naam yahan add kar
    local KNOWN = {
        "active.lua",
        "run.lua",
        "main.lua",
        "inject.lua",
        "script.lua",
        "mod.lua",
        "v79.lua", "v80.lua", "v81.lua", "v82.lua", "v83.lua",
        "v84.lua", "v85.lua", "v86.lua", "v87.lua", "v88.lua",
        "v89.lua", "v90.lua",
        "test.lua",
    }

    -- Timer tracking
    _G.__TIMERS = _G.__TIMERS or {}
    _G.__SCRIPT_OF = _G.__SCRIPT_OF or {}
    _G.__CUR = nil

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
                    if tk.RemoveTimer then tk.RemoveTimer(tid) end
                end
            end)
            killed = killed + 1
        end
        _G.__SCRIPT_OF[name] = {}
        return killed
    end

    -- Hook timer API to track per-script
    pcall(function()
        local tk = require("common.time_ticker")
        if tk and not tk._fix_hooked then
            tk._fix_hooked = true
            if tk.AddTimerLoop then
                local orig = tk.AddTimerLoop
                tk.AddTimerLoop = function(delay, fn, n, interval, ...)
                    local cur = _G.__CUR or "session"
                    local tid = orig(delay, fn, n, interval, ...)
                    if tid then
                        _G.__SCRIPT_OF[cur] = _G.__SCRIPT_OF[cur] or {}
                        table.insert(_G.__SCRIPT_OF[cur], tid)
                    end
                    return tid
                end
            end
            if tk.AddTimerOnce then
                local orig = tk.AddTimerOnce
                tk.AddTimerOnce = function(delay, fn, ...)
                    local cur = _G.__CUR or "session"
                    local tid = orig(delay, fn, ...)
                    if tid then
                        _G.__SCRIPT_OF[cur] = _G.__SCRIPT_OF[cur] or {}
                        table.insert(_G.__SCRIPT_OF[cur], tid)
                    end
                    return tid
                end
            end
        end
    end)

    -- Hash
    local function hash(s)
        local h = 5381
        for i = 1, #s do h = (h * 33 + s:byte(i)) % 4294967296 end
        return h
    end

    local HASHES = {}

    local function tryLoad(name)
        local path = DIR .. name
        local f = io.open(path, "r")
        if not f then return "missing" end
        local src = f:read("*a")
        f:close()
        if not src or #src == 0 then return "empty" end

        local h = hash(src)
        if HASHES[name] == h then return "skip" end

        -- Kill old timers for this name
        local killed = killTimersOf(name)
        if killed > 0 then A("killed " .. killed .. " timers of old " .. name) end

        _G.__CUR = name

        local fn, perr = (loadstring or load)(src, name)
        if not fn then
            A("PARSE FAIL " .. name .. " :: " .. tostring(perr):sub(1,120))
            _G.__CUR = nil
            return "parse_fail"
        end

        local ok, rerr = pcall(fn)
        _G.__CUR = nil
        HASHES[name] = h

        if ok then
            A("OK " .. name .. " (hash=" .. h .. ")")
            return "ok"
        else
            A("RUN ERR " .. name .. " :: " .. tostring(rerr):sub(1,200))
            return "run_err"
        end
    end

    local function scan()
        local loaded = 0
        local missing = 0
        for _, name in ipairs(KNOWN) do
            local r = tryLoad(name)
            if r == "ok" then loaded = loaded + 1
            elseif r == "missing" then missing = missing + 1 end
        end
        A("scan: loaded=" .. loaded .. " missing=" .. missing .. " total_checked=" .. #KNOWN)
    end

    _G.__LOADER_FIX_SCAN = scan

    A("initial scan")
    scan()

    -- Watch loop
    pcall(function()
        local tk = require("common.time_ticker")
        if tk and tk.AddTimerLoop then
            tk.AddTimerLoop(0, function()
                pcall(scan)
            end, -1, 1.5)
            A("watcher @ 1.5s")
        end
    end)

    _G.LOADER_FIX_SCAN = scan
    _G.LOADER_FIX_KILL = function()
        local n = 0
        for name in pairs(_G.__SCRIPT_OF) do n = n + killTimersOf(name) end
        A("manual kill: " .. n)
        return n
    end

    A("loader ready")
end)
