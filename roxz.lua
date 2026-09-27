-- ═══════════════════════════════════════════════════════════════════
-- v33 — MATCH EVENT DUMPER + PHASE TRACE
-- Search: spawn island, plane, drop, crate modules
-- Detect: match phase
-- Trace: full runtime during match start → drop event
-- Path: /storage/emulated/0/Android/data/com.pubg.imobile/files/
-- ═══════════════════════════════════════════════════════════════════

local DIR = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"

local function S(name, content)
    local f = io.open(DIR .. name, "w")
    if not f then return false end
    f:write(content or ""); f:close()
    return true
end

local function P(t, m)
    pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
        if not Msg then
            local ok, r = pcall(require, "client.slua.logic.common.logic_common_msg_box")
            if ok then Msg = r end
        end
        if Msg and Msg.Show then
            Msg.Show(1, tostring(t), tostring(m), function() end, function() end, "OK", "CLOSE")
        end
    end)
end

local function V(v, d, m)
    d, m = d or 0, m or 3
    if d > m then return "..." end
    local t = type(v)
    if t == "nil" or t == "boolean" or t == "number" then return tostring(v) end
    if t == "string" then return #v > 70 and ('"'..v:sub(1,67)..'..."') or ('"'..v..'"') end
    if t == "function" then return "<fn>" end
    if t == "userdata" then return "<ud>" end
    if t == "table" then
        local p, i, n = {}, 0, 0
        for _ in pairs(v) do n = n + 1 end
        for k, val in pairs(v) do
            i = i + 1
            if i > 12 then p[#p+1] = "...(+"..(n-12)..")"; break end
            p[#p+1] = tostring(k).."="..V(val,d+1,m)
        end
        return "{"..table.concat(p,",").."}"
    end
    return "<"..t..">"
end

-- ═══════════════════════════════════════════════════════════════════
-- PART 1: MATCH EVENT MODULES SEARCH
-- ═══════════════════════════════════════════════════════════════════
_G.V33_SearchModules = function()
    local out = {}
    local function w(s) out[#out+1] = tostring(s) end
    w("╔═══════════════════════════════════════════════════════════╗")
    w("║  MATCH EVENT MODULES SEARCH")
    w("║  " .. os.date("%Y-%m-%d %H:%M:%S"))
    w("╚═══════════════════════════════════════════════════════════╝")
    w("")

    local KEYWORDS = {
        -- Phases
        "spawnisland", "spawn_island", "spawnisland", "island",
        "planeflight", "plane_flight", "plane", "aircraft", "cargo",
        "freefall", "free_fall", "parachute", "parachuting",
        "matchphase", "match_phase", "gamestate", "gamephase",
        -- Events
        "matchevent", "match_event", "specialevent", "worldevent",
        "vehicledrop", "vehicle_drop", "cardrop", "crate_drop",
        "supplydrop", "airdrop", "airdroptype",
        -- Crate/Box
        "crate", "boxspawn", "cratebox", "lootbox",
        "spawnbox", "specialbox", "eventcrate",
        -- Vehicle drop
        "vehiclecollect", "vehicledebut", "granddebut",
        "vehiclespawnisland", "lobbyvehicle",
    }

    -- Search package.loaded
    w("═══ package.loaded MATCHES ═══")
    local matched = {}
    for path, mod in pairs(package.loaded) do
        if type(path) == "string" and type(mod) == "table" then
            local lk = path:lower()
            for _, kw in ipairs(KEYWORDS) do
                if lk:find(kw, 1, true) then
                    matched[#matched+1] = path
                    break
                end
            end
        end
    end
    table.sort(matched)
    for _, m in ipairs(matched) do
        w("  " .. m)
    end
    w("  Total: " .. #matched)
    w("")

    -- LobbyModuleConfig
    w("═══ ModuleManager.LobbyModuleConfig ═══")
    pcall(function()
        local MM = _G.ModuleManager
        if MM and MM.LobbyModuleConfig then
            for key, cfg in pairs(MM.LobbyModuleConfig) do
                if type(cfg) == "table" and type(cfg.ModuleName) == "string" then
                    local lk = cfg.ModuleName:lower()
                    for _, kw in ipairs(KEYWORDS) do
                        if lk:find(kw, 1, true) then
                            w("  " .. tostring(key) .. " = " .. cfg.ModuleName)
                            break
                        end
                    end
                end
            end
        end
    end)

    -- CommonModuleConfig
    w("")
    w("═══ ModuleManager.CommonModuleConfig ═══")
    pcall(function()
        local MM = _G.ModuleManager
        if MM and MM.CommonModuleConfig then
            for key, cfg in pairs(MM.CommonModuleConfig) do
                if type(cfg) == "table" and type(cfg.ModuleName) == "string" then
                    local lk = cfg.ModuleName:lower()
                    for _, kw in ipairs(KEYWORDS) do
                        if lk:find(kw, 1, true) then
                            w("  " .. tostring(key) .. " = " .. cfg.ModuleName)
                            break
                        end
                    end
                end
            end
        end
    end)

    -- DataModuleConfig
    w("")
    w("═══ ModuleManager.DataModuleConfig ═══")
    pcall(function()
        local MM = _G.ModuleManager
        if MM and MM.DataModuleConfig then
            for key, cfg in pairs(MM.DataModuleConfig) do
                if type(cfg) == "table" and type(cfg.ModuleName) == "string" then
                    local lk = cfg.ModuleName:lower()
                    for _, kw in ipairs(KEYWORDS) do
                        if lk:find(kw, 1, true) then
                            w("  " .. tostring(key) .. " = " .. cfg.ModuleName)
                            break
                        end
                    end
                end
            end
        end
    end)

    local txt = table.concat(out, "\n")
    S("v33_modules.txt", txt)
    print(txt)
    P("V33 MODULES", "Saved: v33_modules.txt\n(" .. #matched .. " matches)")
    return txt
end

-- ═══════════════════════════════════════════════════════════════════
-- PART 2: DETAILED DUMP — every matched module
-- ═══════════════════════════════════════════════════════════════════
_G.V33_DumpDetails = function()
    local out = {}
    local function w(s) out[#out+1] = tostring(s) end
    w("═══ DETAILED MODULE DUMP ═══")
    w("Time: " .. os.date("%Y-%m-%d %H:%M:%S"))
    w("")

    local KEYWORDS = {
        "spawnisland", "island", "plane", "freefall", "parachute",
        "matchevent", "vehicledrop", "cardrop", "crate", "airdrop",
        "supplydrop", "vehiclecollect", "granddebut", "lobbyvehicle",
    }

    local count = 0
    for path, mod in pairs(package.loaded) do
        if type(path) == "string" and type(mod) == "table" then
            local lk = path:lower()
            local isMatch = false
            for _, kw in ipairs(KEYWORDS) do
                if lk:find(kw, 1, true) then isMatch = true break end
            end

            if isMatch then
                count = count + 1
                w("")
                w("══════════════════════════════════════════════")
                w("MODULE: " .. path)
                w("══════════════════════════════════════════════")

                -- Top level functions
                local topFns = {}
                for k, v in pairs(mod) do
                    if type(v) == "function" and type(k) == "string" and not k:match("^__") then
                        topFns[#topFns+1] = k
                    end
                end
                table.sort(topFns, function(a,b) return tostring(a)<tostring(b) end)
                if #topFns > 0 then
                    w("── TOP FUNCTIONS (" .. #topFns .. ") ──")
                    for _, fn in ipairs(topFns) do w("  " .. tostring(fn)) end
                end

                -- Inner impl
                local i = mod.__inner_impl
                if type(i) == "table" then
                    w("")
                    w("── __inner_impl ──")
                    local fns, tbls = {}, {}
                    for k, v in pairs(i) do
                        if type(v) == "function" then fns[#fns+1] = k
                        elseif type(v) == "table" then
                            local n = 0; for _ in pairs(v) do n = n + 1 end
                            tbls[#tbls+1] = tostring(k) .. "(" .. n .. ")"
                        end
                    end
                    table.sort(fns, function(a,b) return tostring(a)<tostring(b) end)
                    table.sort(tbls, function(a,b) return tostring(a)<tostring(b) end)
                    if #fns > 0 then
                        w("  FUNCTIONS (" .. #fns .. "):")
                        for _, fn in ipairs(fns) do
                            local info = debug.getinfo(i[fn], "S")
                            w("    " .. tostring(fn) .. " (" .. 
                              tostring(info and info.linedefined or "?") .. ")")
                        end
                    end
                    if #tbls > 0 then
                        w("  TABLES (" .. #tbls .. "):")
                        for _, t in ipairs(tbls) do w("    " .. t) end
                    end
                end
            end
        end
    end

    w("")
    w("Total modules: " .. count)

    local txt = table.concat(out, "\n")
    S("v33_details.txt", txt)
    print("[V33] Details saved (" .. count .. " modules)")
    P("V33 DETAILS", "Saved: v33_details.txt\n(" .. count .. " modules)")
    return txt
end

-- ═══════════════════════════════════════════════════════════════════
-- PART 3: MATCH PHASE DETECTION
-- ═══════════════════════════════════════════════════════════════════
_G.V33_GetPhase = function()
    local phase = "unknown"
    local raw = {}

    pcall(function()
        if GameStatus then
            for _, fn in ipairs({ "IsInLobbyOrMainCity", "IsInFightingStatus", 
                                   "IsInMatch", "IsInGame" }) do
                if type(GameStatus[fn]) == "function" then
                    local ok, v = pcall(GameStatus[fn])
                    if ok then raw[fn] = v end
                end
            end
        end
        -- GameplayState
        if GameplayData then
            for _, fn in ipairs({ "GetGameState", "IsInGame" }) do
                if type(GameplayData[fn]) == "function" then
                    local ok, v = pcall(GameplayData[fn])
                    if ok then raw["GD."..fn] = v end
                end
            end
        end
    end)

    -- Determine phase
    pcall(function()
        if GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity() then
            phase = "lobby"
        elseif GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus() then
            phase = "match"
        end
    end)

    -- Sub-phase if in match
    local subPhase = "none"
    if phase == "match" then
        pcall(function()
            local GD = require("GameLua.GameCore.Data.GameplayData")
            local ch = GD.GetPlayerCharacter and GD.GetPlayerCharacter()
            if ch and slua.isValid(ch) then
                -- Check parasuit / plane / spawn island
                local E = import("EParachuteState")
                if E and ch.ParachuteState ~= nil then
                    if ch.ParachuteState == E.PS_None then subPhase = "plane"
                    elseif ch.ParachuteState == E.PS_Free then subPhase = "freefall"
                    elseif ch.ParachuteState == E.PS_Open then subPhase = "parachute_open"
                    elseif ch.ParachuteState == E.PS_Land then subPhase = "landed" end
                end
                -- Vehicle check
                if ch.GetCurrentVehicle then
                    local v = ch:GetCurrentVehicle()
                    if v and slua.isValid(v) then subPhase = subPhase .. "+vehicle" end
                end
            end
        end)
    end

    return phase, subPhase, raw
end

-- ═══════════════════════════════════════════════════════════════════
-- PART 4: RUNTIME TRACE DURING MATCH
-- ═══════════════════════════════════════════════════════════════════
_G._V33_TraceLog = {}
_G._V33_TraceActive = false

_G.V33_TraceStart = function()
    if _G._V33_TraceActive then P("V33", "Already tracing") return end
    _G._V33_TraceActive = true
    _G._V33_TraceLog = {}

    local function log(s)
        _G._V33_TraceLog[#_G._V33_TraceLog+1] = 
            string.format("[%s] %s", os.date("%H:%M:%S"), s)
    end

    log("=== TRACE STARTED ===")

    -- Hook GameStatus
    pcall(function()
        if GameStatus then
            for k, fn in pairs(GameStatus) do
                if type(fn) == "function" and type(k) == "string" then
                    local orig = fn
                    GameStatus[k] = function(...)
                        log("GameStatus." .. tostring(k))
                        local ok, r = pcall(orig, ...)
                        if not ok then log("  ✗ ERR")
                        elseif r ~= nil then log("  ↳ " .. tostring(r)) end
                        return r
                    end
                end
            end
        end
    end)

    -- Hook GameplayData
    pcall(function()
        if GameplayData then
            for k, fn in pairs(GameplayData) do
                if type(fn) == "function" and type(k) == "string" then
                    local lk = k:lower()
                    if lk:find("game") or lk:find("match") or lk:find("phase")
                       or lk:find("state") or lk:find("spawn") or lk:find("vehicle") then
                        local orig = fn
                        GameplayData[k] = function(...)
                            log("GD." .. tostring(k))
                            local ok, r = pcall(orig, ...)
                            if not ok then log("  ✗ ERR: " .. tostring(r):sub(1, 80))
                            end
                            return r
                        end
                    end
                end
            end
        end
    end)

    -- Hook SubsystemMgr for event/subsystem related
    pcall(function()
        local SubMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr and type(SubMgr.Get) == "function" then
            local subs = {
                "MatchEventSubsystem", "VehicleDropSubsystem", "EventSubsystem",
                "SpawnIslandSubsystem", "GameStateSubsystem", "MatchPhaseSubsystem",
                "VehicleCollectSubsystem", "CrateSubsystem", "AirdropSubsystem",
                "VehicleSubsystem", "GameplaySubsystem",
            }
            for _, name in ipairs(subs) do
                pcall(function()
                    local sub = SubMgr:Get(name)
                    if sub and type(sub) == "table" then
                        log("Found subsystem: " .. name)
                        for k, fn in pairs(sub) do
                            if type(fn) == "function" and type(k) == "string" then
                                local lk = k:lower()
                                if lk:find("spawn") or lk:find("drop") or lk:find("create")
                                   or lk:find("crate") or lk:find("vehicle") or lk:find("event")
                                   or lk:find("show") or lk:find("trigger") then
                                    local orig = fn
                                    sub[k] = function(self, ...)
                                        log(name .. "." .. tostring(k))
                                        local ok, r = pcall(orig, self, ...)
                                        if not ok then log("  ✗ ERR")
                                        elseif r ~= nil then log("  ↳ " .. V(r, 0, 1)) end
                                        return r
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Auto-save every 5 sec
    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerLoop then
            ticker.AddTimerLoop(0, function()
                if _G._V33_TraceActive and #_G._V33_TraceLog > 0 then
                    S("v33_trace.txt", table.concat(_G._V33_TraceLog, "\n"))
                end
            end, -1, 5.0)
        end
    end)

    log("=== HOOKS READY ===")

    -- Phase monitor loop
    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerLoop then
            local lastPhase = ""
            ticker.AddTimerLoop(0, function()
                if not _G._V33_TraceActive then return end
                local phase, subPhase = V33_GetPhase()
                local cur = tostring(phase) .. "|" .. tostring(subPhase)
                if cur ~= lastPhase then
                    log("PHASE CHANGE: " .. cur)
                    lastPhase = cur
                end
            end, -1, 1.0)
        end
    end)

    P("V33 TRACE ON",
        "Match trace active.\n\n" ..
        "Ab:\n" ..
        "1. Match start karo\n" ..
        "2. Spawn island pe wait karo\n" ..
        "3. Plane phase dekho\n" ..
        "4. Crate drop hone tak wait\n" ..
        "5. V33_TraceStop()")
end

_G.V33_TraceStop = function()
    _G._V33_TraceActive = false
    local txt = table.concat(_G._V33_TraceLog or {}, "\n")
    S("v33_trace.txt", txt)
    P("V33 TRACE STOP", 
        "Saved: v33_trace.txt\n" ..
        "Lines: " .. #(_G._V33_TraceLog or {}))
end

-- ═══════════════════════════════════════════════════════════════════
-- PART 5: PHASE MONITOR (standalone, always running)
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerLoop then
        local lastPhase = ""
        ticker.AddTimerLoop(0, function()
            pcall(function()
                local phase, subPhase = V33_GetPhase()
                local cur = tostring(phase) .. "|" .. tostring(subPhase)
                if cur ~= lastPhase then
                    print("[V33 PHASE] " .. cur)
                    if _G._V33_TraceActive then
                        _G._V33_TraceLog[#_G._V33_TraceLog+1] = 
                            string.format("[%s] PHASE: %s", os.date("%H:%M:%S"), cur)
                    end
                    lastPhase = cur
                end
            end)
        end, -1, 1.0)
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- AUTO-RUN
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(2.0, function()
            pcall(_G.V33_SearchModules)
        end)
        ticker.AddTimerOnce(4.0, function()
            pcall(_G.V33_DumpDetails)
        end)
        ticker.AddTimerOnce(6.0, function()
            pcall(_G.V33_TraceStart)
        end)
    end
end)

S("v33_report.txt",
    "v33 REPORT\n" ..
    "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n" ..
    "Commands:\n" ..
    "  V33_SearchModules()  -- find match event modules\n" ..
    "  V33_DumpDetails()    -- full structure\n" ..
    "  V33_GetPhase()       -- current phase\n" ..
    "  V33_TraceStart()     -- start runtime trace\n" ..
    "  V33_TraceStop()      -- save trace\n"
)

P("v33 LOADED",
    "Match Event Dumper\n\n" ..
    "Auto:\n" ..
    "  2s → Search modules\n" ..
    "  4s → Details dump\n" ..
    "  6s → Trace start\n\n" ..
    "Phir match start karo.\n" ..
    "Wait 15-20 sec.\n" ..
    "V33_TraceStop()")

return true
