-- ═══════════════════════════════════════════════════════════════════
-- ROXZ-LOADER v7 — single boot popup, silent reloads
-- Replace old loader with this whole block.
-- ═══════════════════════════════════════════════════════════════════

pcall(function()
    local DIR = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"
    local TARGET_SCRIPT = "active.lua"
    local LOG_FILE = DIR .. "roxz_loader.log"
    local WATCH_INTERVAL = 2.0

    if _G.__ROXZ_V7_LOADED then return end
    _G.__ROXZ_V7_LOADED = true

    local function Log(msg)
        pcall(function()
            local f = io.open(LOG_FILE, "a")
            if f then f:write(string.format("[%s] %s\n", os.date("%H:%M:%S"), tostring(msg))); f:close() end
        end)
    end

    -- ★ SINGLE popup, only on first boot
    local function bootPopup()
        pcall(function()
            local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
                        or require("client.slua.logic.common.logic_common_msg_box")
            if Msg and Msg.Show then
                Msg.Show(4, "ROXZ", "Loader active\nWatching: active.lua")
            end
        end)
    end

    -- Timer registry
    _G.__ROXZ_TIMERS = _G.__ROXZ_TIMERS or {}
    local function RegisterTimer(tid)
        if tid then table.insert(_G.__ROXZ_TIMERS, tid) end
    end
    local function KillAllOldTimers()
        local count = #_G.__ROXZ_TIMERS
        if count == 0 then return end
        pcall(function()
            local tk = require("common.time_ticker")
            if tk then
                for _, tid in ipairs(_G.__ROXZ_TIMERS) do
                    if tk.RemoveTimerLoop then pcall(tk.RemoveTimerLoop, tid) end
                    if tk.RemoveTimer then pcall(tk.RemoveTimer, tid) end
                end
            end
        end)
        _G.__ROXZ_TIMERS = {}
    end

    -- Ticker hooks
    pcall(function()
        local tk = require("common.time_ticker")
        if tk and not tk._roxz_v7_hooked then
            tk._roxz_v7_hooked = true
            if tk.AddTimerLoop then
                local o = tk.AddTimerLoop
                tk.AddTimerLoop = function(...)
                    local tid = o(...); RegisterTimer(tid); return tid
                end
            end
            if tk.AddTimerOnce then
                local o = tk.AddTimerOnce
                tk.AddTimerOnce = function(...)
                    local tid = o(...); RegisterTimer(tid); return tid
                end
            end
        end
    end)

    local _lastOKHash = nil
    local _lastFailHash = nil
    local _lastFailTime = 0
    local FAIL_BACKOFF = 15

    local function Hash(content)
        local h = 0
        for i = 1, #content do h = (h * 31 + content:byte(i)) % 4294967296 end
        return h
    end

    local function LoadScript()
        local f = io.open(DIR .. TARGET_SCRIPT, "r")
        if not f then return false end
        local src = f:read("*a"); f:close()
        if not src or #src < 10 then return false end
        local h = Hash(src)
        if h == _lastOKHash then return true end
        if h == _lastFailHash and (os.clock() - _lastFailTime) < FAIL_BACKOFF then return false end

        KillAllOldTimers()

        local chunk, err = (loadstring or load)(src, TARGET_SCRIPT)
        if not chunk then
            Log("PARSE ERR: " .. tostring(err))
            _lastFailHash = h; _lastFailTime = os.clock()
            return false
        end

        local ok, e = pcall(chunk)
        if ok then
            _lastOKHash = h; _lastFailHash = nil
            Log("OK: " .. TARGET_SCRIPT)
            return true
        else
            Log("RUN ERR: " .. tostring(e))
            _lastFailHash = h; _lastFailTime = os.clock()
            return false
        end
    end

    -- First load
    LoadScript()

    -- ★ Single popup after first load
    bootPopup()

    -- Silent watcher
    pcall(function()
        local tk = require("common.time_ticker")
        if tk and tk.AddTimerLoop then
            tk.AddTimerLoop(0, function()
                pcall(LoadScript)
            end, -1, WATCH_INTERVAL)
        end
    end)

    _G.ROXZ_RELOAD = function()
        _lastOKHash = nil
        _lastFailHash = nil
        LoadScript()
    end

    _G.ROXZ_STATUS = function()
        print("[ROXZ] Timers=" .. #_G.__ROXZ_TIMERS .. " OK=" .. tostring(_lastOKHash))
    end

    Log("--- Loader v7 active ---")
end)
