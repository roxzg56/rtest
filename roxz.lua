-- ═══════════════════════════════════════════════════════════════════
-- ROXZ-LOADER v6 — silent reload, single boot popup
-- Replace this whole block with old loader.
-- ═══════════════════════════════════════════════════════════════════

pcall(function()
    local DIR = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"
    local TARGET_SCRIPT = "active.lua"
    local LOG_FILE = DIR .. "roxz_loader.log"
    local WATCH_INTERVAL = 2.0

    if _G.__ROXZ_V6_LOADED then return end
    _G.__ROXZ_V6_LOADED = true

    -- ★ Boot popup fires ONCE per session, first load only
    _G.__ROXZ_BOOT_POPUP_DONE = _G.__ROXZ_BOOT_POPUP_DONE or false

    local function Log(msg)
        pcall(function()
            local f = io.open(LOG_FILE, "a")
            if f then f:write(string.format("[%s] %s\n", os.date("%H:%M:%S"), tostring(msg))); f:close() end
        end)
    end

    -- ★★ KILL ALL POPUPS from loaded script — even first boot we control it
    -- Two modes:
    --   BLOCK_ALL = true  → no popup ever fires (including our own)
    --   Our boot popup fires BEFORE blocking
    local _popupCache = {}
    local _popupBlocked = false

    local function showBootPopup(title, msg)
        pcall(function()
            local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
                        or require("client.slua.logic.common.logic_common_msg_box")
            if Msg and Msg.Show and not Msg.__roxz_hooked then
                Msg.Show(4, tostring(title), tostring(msg))
            end
        end)
    end

    -- Install popup killer (block everything after boot)
    local function installPopupKiller()
        _popupBlocked = true

        -- Channel 1: logic_common_msg_box
        pcall(function()
            local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
                        or require("client.slua.logic.common.logic_common_msg_box")
            if Msg and not Msg.__roxz_v6_hooked and type(Msg.Show) == "function" then
                Msg.__roxz_v6_hooked = true
                Msg.Show = function() return end
            end
        end)

        -- Channel 2: com_msg_box_slua
        pcall(function()
            local M = package.loaded["client.slua.umg.common.com_msg_box_slua"]
            if M and not M.__roxz_v6_hooked then
                M.__roxz_v6_hooked = true
                if type(M.Show) == "function" then M.Show = function() return end end
            end
        end)

        -- Channel 3: EventSystem popup event
        pcall(function()
            if EventSystem and not EventSystem.__roxz_v6_popup then
                EventSystem.__roxz_v6_popup = true
                local orig = EventSystem.postEvent
                if type(orig) == "function" then
                    EventSystem.postEvent = function(self, evtType, evtId, ...)
                        if evtId == 2395 then return end -- EVENTID_SHOW_POPUP
                        return orig(self, evtType, evtId, ...)
                    end
                end
            end
        end)

        Log("Popup killer installed")
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

    pcall(function()
        local tk = require("common.time_ticker")
        if tk and not tk._roxz_v6_hooked then
            tk._roxz_v6_hooked = true
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

    local function LoadScript(isFirstLoad)
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

        -- ★ First load: allow popups for 3 seconds
        -- ★ Reloads: popups blocked (already installed)
        local ok, e = pcall(chunk)
        if ok then
            _lastOKHash = h; _lastFailHash = nil
            Log("OK: " .. TARGET_SCRIPT .. (isFirstLoad and " [boot]" or " [reload]"))
            return true
        else
            Log("RUN ERR: " .. tostring(e))
            _lastFailHash = h; _lastFailTime = os.clock()
            return false
        end
    end

    -- ★ FIRST LOAD — popups allowed for this one
    LoadScript(true)

    -- ★ THEN INSTALL POPUP KILLER for all future reloads
    installPopupKiller()

    -- Watcher — silent
    pcall(function()
        local tk = require("common.time_ticker")
        if tk and tk.AddTimerLoop then
            tk.AddTimerLoop(0, function()
                -- Silent reload: popup killer already active
                pcall(LoadScript, false)
            end, -1, WATCH_INTERVAL)
        end
    end)

    _G.ROXZ_RELOAD = function()
        _lastOKHash = nil
        _lastFailHash = nil
        -- Temporarily allow popups for manual reload
        pcall(function()
            local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
            if Msg and Msg.Show then
                Msg.Show = _G.__ROXZ_ORIG_MSG_SHOW or Msg.Show
            end
        end)
        LoadScript(true)
        installPopupKiller()
    end

    _G.ROXZ_STATUS = function()
        print("[ROXZ] Timers: " .. #_G.__ROXZ_TIMERS .. " OK=" .. tostring(_lastOKHash) .. " popupsBlocked=" .. tostring(_popupBlocked))
    end

    Log("--- Loader v6 active ---")
end)
