-- ═══════════════════════════════════════════════════════════════════
-- ROXZ-LOADER v4 — OPTIMIZED & SAFE
-- Location: End of BRPlayerCharacterBase.lua
-- Purpose: Loads active.lua safely without lag or crashes.
-- ═══════════════════════════════════════════════════════════════════

pcall(function()
    -- 1. CONFIGURATION
    local DIR = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"
    local TARGET_SCRIPT = "active.lua" -- Main script to load
    local LOG_FILE = DIR .. "roxz_loader.log"
    
    -- Prevent double loading in same session
    if _G.__ROXZ_V4_LOADED then 
        return 
    end
    _G.__ROXZ_V4_LOADED = true

    -- Logger Helper (Lightweight)
    local function Log(msg)
        pcall(function()
            local f = io.open(LOG_FILE, "a")
            if f then
                f:write(string.format("[%s] %s\n", os.date("%H:%M:%S"), tostring(msg)))
                f:close()
            end
        end)
    end

    Log("--- Loader v4 Started ---")

    -- 2. TIMER MANAGEMENT SYSTEM (The Anti-Lag Core)
    -- We track all timer IDs created by our scripts so we can kill them on reload
    _G.__ROXZ_TIMERS = _G.__ROXZ_TIMERS or {}
    
    local function RegisterTimer(tid)
        if tid then table.insert(_G.__ROXZ_TIMERS, tid) end
    end

    local function KillAllOldTimers()
        local count = #_G.__ROXZ_TIMERS
        if count == 0 then return end
        
        Log("Killing " .. count .. " old timers...")
        
        -- Try multiple removal methods for compatibility
        pcall(function()
            local tk = require("common.time_ticker")
            if tk and tk.RemoveTimerLoop then
                for _, tid in ipairs(_G.__ROXZ_TIMERS) do
                    pcall(tk.RemoveTimerLoop, tid)
                    pcall(tk.RemoveTimer, tid)
                end
            end
        end)
        
        -- Fallback for GameEngine timers
        pcall(function()
            local pc = getPlayerController and getPlayerController()
            if pc and pc.RemoveGameTimer then
                 for _, tid in ipairs(_G.__ROXZ_TIMERS) do
                     pcall(pc.RemoveGameTimer, pc, tid)
                 end
            end
        end)

        -- Clear registry
        _G.__ROXZ_TIMERS = {}
        Log("Timers cleared.")
    end

    -- Hook the ticker globally to auto-register new timers from active.lua
    pcall(function()
        local tk = require("common.time_ticker")
        if tk and not tk._roxz_v4_hooked then
            tk._roxz_v4_hooked = true
            
            -- Wrap AddTimerLoop
            if tk.AddTimerLoop then
                local origLoop = tk.AddTimerLoop
                tk.AddTimerLoop = function(delay, fn, n, interval, ...)
                    local tid = origLoop(delay, fn, n, interval, ...)
                    RegisterTimer(tid)
                    return tid
                end
            end
            
            -- Wrap AddTimerOnce
            if tk.AddTimerOnce then
                local origOnce = tk.AddTimerOnce
                tk.AddTimerOnce = function(delay, fn, ...)
                    local tid = origOnce(delay, fn, ...)
                    RegisterTimer(tid)
                    return tid
                end
            end
            Log("Ticker Hooks Installed.")
        end
    end)

    -- 3. FILE LOADING LOGIC
    local _lastHash = nil
    
    local function GetFileHash(content)
        -- Simple checksum to detect changes
        local h = 0
        for i = 1, #content do
            h = (h * 31 + content:byte(i)) % 4294967296
        end
        return h
    end

    local function LoadScript()
        local path = DIR .. TARGET_SCRIPT
        local f = io.open(path, "r")
        
        if not f then
            Log("ERROR: Cannot open " .. TARGET_SCRIPT)
            return false
        end
        
        local src = f:read("*a")
        f:close()
        
        if not src or #src < 10 then
            Log("WARN: Script is empty or too small.")
            return false
        end

        -- Check if changed
        local currentHash = GetFileHash(src)
        if currentHash == _lastHash then
            -- No change, skip reload to save performance
            return true 
        end
        
        Log("Detected Change. Reloading...")
        
        -- STEP A: KILL OLD TIMERS FIRST (Critical for stability)
        KillAllOldTimers()
        
        -- STEP B: EXECUTE NEW SCRIPT
        local chunk, err = (loadstring or load)(src, TARGET_SCRIPT)
        if not chunk then
            Log("PARSE ERROR: " .. tostring(err))
            return false
        end
        
        local success, runtimeErr = pcall(chunk)
        if success then
            _lastHash = currentHash
            Log("SUCCESS: Loaded " .. TARGET_SCRIPT)
            return true
        else
            Log("RUNTIME ERROR: " .. tostring(runtimeErr))
            return false
        end
    end

    -- 4. INITIALIZATION & WATCHER
    -- Initial Load
    LoadScript()

    -- Background Watcher (Checks every 3 seconds instead of 1.5 to reduce IO stress)
    pcall(function()
        local tk = require("common.time_ticker")
        if tk and tk.AddTimerLoop then
            tk.AddTimerLoop(0, function()
                pcall(LoadScript)
            end, -1, 3.0) -- 3 Second Interval
            Log("Watcher Active (Interval: 3.0s)")
        end
    end)

    -- Public API for Debugging
    _G.ROXZ_RELOAD = function()
        _lastHash = nil -- Force hash mismatch
        LoadScript()
    end
    
    _G.ROXZ_STATUS = function()
        print("[ROXZ] Timers Tracked: " .. #_G.__ROXZ_TIMERS)
        print("[ROXZ] Last Hash: " .. tostring(_lastHash))
    end

end)
