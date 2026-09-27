-- ═══════════════════════════════════════════════════════════════════
-- v34 — BORN ISLAND FAKE DROP (Phase Detection Fixed)
-- Target: Spawn Island / Plane phase vehicle drop
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
            or (pcall(require, "client.slua.logic.common.logic_common_msg_box")
                and require("client.slua.logic.common.logic_common_msg_box"))
        if Msg and Msg.Show then
            Msg.Show(1, tostring(t), tostring(m), function() end, function() end, "OK", "CLOSE")
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- PHASE DETECTOR — Corrected for Spawn Island
-- ═══════════════════════════════════════════════════════════════════
_G.V34_GetPhase = function()
    local phase = "unknown"
    local subPhase = "none"

    -- 1. Basic status
    pcall(function()
        if GameStatus then
            if GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity() then
                phase = "lobby"
            elseif GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus() then
                phase = "match"
            end
        end
    end)

    -- 2. Sub-phase for match
    if phase == "match" then
        pcall(function()
            local GD = require("GameLua.GameCore.Data.GameplayData")
            local ch = GD.GetPlayerCharacter and GD.GetPlayerCharacter()
            if ch and slua.isValid(ch) then
                -- Check Born Island first
                local mapName = ""
                if ch.GetMapName then mapName = ch:GetMapName() or "" end
                if mapName:lower():find("born") or mapName:lower():find("island") then
                    subPhase = "born_island"
                    return
                end

                -- Check Parasuit / Plane
                local E = import("EParachuteState")
                if E and ch.ParachuteState ~= nil then
                    if ch.ParachuteState == E.PS_None then subPhase = "plane"
                    elseif ch.ParachuteState == E.PS_Free then subPhase = "freefall"
                    elseif ch.ParachuteState == E.PS_Open then subPhase = "parachute_open"
                    elseif ch.ParachuteState == E.PS_Land then subPhase = "landed" end
                end

                -- Check Vehicle
                if ch.GetCurrentVehicle then
                    local v = ch:GetCurrentVehicle()
                    if v and slua.isValid(v) then subPhase = subPhase .. "+vehicle" end
                end
            end
        end)
    end

    return phase, subPhase
end

-- ═══════════════════════════════════════════════════════════════════
-- DUMP 1: Search Born Island modules
-- ═══════════════════════════════════════════════════════════════════
_G.V34_SearchBornIsland = function()
    local out = {}
    local function w(s) out[#out+1] = tostring(s) end
    w("═══ BORN ISLAND MODULE SEARCH ═══")

    local KEYWORDS = { "bornisland", "born_island", "island", "airdrop", "spawnisland", "specialevent", "dropvehicle", "vehicledrop" }

    for path, mod in pairs(package.loaded) do
        if type(path) == "string" and type(mod) == "table" then
            local lk = path:lower()
            for _, kw in ipairs(KEYWORDS) do
                if lk:find(kw, 1, true) then
                    w("  FOUND: " .. path)
                    local inner = mod.__inner_impl
                    if type(inner) == "table" then
                        local fns, tbls = {}, {}
                        for k, v in pairs(inner) do
                            if type(v) == "function" then fns[#fns+1] = k
                            elseif type(v) == "table" then
                                local n = 0; for _ in pairs(v) do n = n + 1 end
                                tbls[#tbls+1] = k .. "(" .. n .. ")"
                            end
                        end
                        table.sort(fns)
                        table.sort(tbls)
                        if #fns > 0 then w("    FUNCTIONS: " .. table.concat(fns, ", ")) end
                        if #tbls > 0 then w("    TABLES: " .. table.concat(tbls, ", ")) end
                    end
                    break
                end
            end
        end
    end
    local txt = table.concat(out, "\n")
    S("v34_born_search.txt", txt)
    print(txt)
    return txt
end

-- ═══════════════════════════════════════════════════════════════════
-- DUMP 2: BornIslandAirDropSystem — Full Structure
-- ═══════════════════════════════════════════════════════════════════
_G.V34_DumpAirDropSys = function()
    local out = {}
    local function w(s) out[#out+1] = tostring(s) end
    w("═══ BORN ISLAND AIR DROP SYSTEM DUMP ═══")

    local path = "GameLua.Mod.Library.GamePlay.Subsystem.BornIslandAirDropSystem"
    local M = package.loaded[path]
    if not M then
        w("MODULE NOT LOADED")
        local txt = table.concat(out, "\n")
        S("v34_airdrop_dump.txt", txt)
        return txt
    end

    w("MODULE: " .. path)
    w("Top keys: " .. (function() local n=0; for _ in pairs(M) do n=n+1 end; return n end)())

    local i = M.__inner_impl
    if type(i) == "table" then
        w("")
        w("── __inner_impl ──")
        for k, v in pairs(i) do
            local vt = type(v)
            if vt == "function" then
                local info = debug.getinfo(v, "S")
                w(string.format("  fn %s (line %s)", tostring(k), tostring(info and info.linedefined or "?")))
            elseif vt == "table" then
                local n = 0; for _ in pairs(v) do n = n + 1 end
                w(string.format("  tbl %s (%d keys)", tostring(k), n))
            else
                w(string.format("  %s %s = %s", vt, tostring(k), tostring(v)))
            end
        end
    end

    local txt = table.concat(out, "\n")
    S("v34_airdrop_dump.txt", txt)
    print(txt)
    return txt
end

-- ═══════════════════════════════════════════════════════════════════
-- HOOK: CreateAirDrop — Capture parameters
-- ═══════════════════════════════════════════════════════════════════
_G._V34_TraceLog = {}
_G._V34_TraceActive = false

_G.V34_HookAirDrop = function()
    if _G._V34_TraceActive then return end
    _G._V34_TraceActive = true
    _G._V34_TraceLog = {}

    local function log(s)
        _G._V34_TraceLog[#_G._V34_TraceLog+1] = string.format("[%s] %s", os.date("%H:%M:%S"), s)
    end

    log("=== AIRDROP TRACE STARTED ===")

    -- Hook BornIslandAirDropSystem
    local M = require("GameLua.Mod.Library.GamePlay.Subsystem.BornIslandAirDropSystem")
    local i = M and M.__inner_impl
    if type(i) == "table" then
        -- Hook CreateAirDrop
        if type(i.CreateAirDrop) == "function" then
            local orig = i.CreateAirDrop
            i.CreateAirDrop = function(self, dropData, ...)
                log("CreateAirDrop CALLED")
                log("  dropData = " .. tostring(dropData))
                if type(dropData) == "table" then
                    for k, v in pairs(dropData) do
                        log("    " .. tostring(k) .. " = " .. tostring(v))
                    end
                end
                log("  self type = " .. type(self))
                if type(self) == "table" then
                    for k, v in pairs(self) do
                        if type(v) ~= "function" then
                            log("    self." .. tostring(k) .. " = " .. tostring(v))
                        end
                    end
                end
                local r = orig(self, dropData, ...)
                log("  RETURN = " .. tostring(r))
                return r
            end
            log("Hooked CreateAirDrop")
        end

        -- Hook other related functions
        for _, fnName in ipairs({ "InitConfig", "OnInit", "StartFight", "GetCurrentDropTimeInfoItem" }) do
            if type(i[fnName]) == "function" then
                local orig = i[fnName]
                i[fnName] = function(self, ...)
                    log("CALL " .. fnName)
                    local ok, r = pcall(orig, self, ...)
                    if not ok then log("  ERR: " .. tostring(r):sub(1, 100))
                    elseif r ~= nil then log("  RET: " .. tostring(r):sub(1, 80)) end
                    return r
                end
                log("Hooked " .. fnName)
            end
        end
    end

    -- Auto-save
    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerLoop then
            ticker.AddTimerLoop(0, function()
                if _G._V34_TraceActive and #_G._V34_TraceLog > 0 then
                    S("v34_airdrop_trace.txt", table.concat(_G._V34_TraceLog, "\n"))
                end
            end, -1, 10.0)
        end
    end)

    log("=== HOOKS READY ===")
    P("V34 TRACE", "Airdrop trace active.\n\nMatch start karo, spawn island pe wait karo.\nDrop aane tak wait karo.\nPhir V34_Stop()")
end

_G.V34_Stop = function()
    _G._V34_TraceActive = false
    local txt = table.concat(_G._V34_TraceLog or {}, "\n")
    S("v34_airdrop_trace.txt", txt)
    P("V34 STOP", "Saved: v34_airdrop_trace.txt\nLines: " .. #(_G._V34_TraceLog or {}))
end

-- ═══════════════════════════════════════════════════════════════════
-- AUTO-BOOT
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(3.0, function()
            pcall(_G.V34_SearchBornIsland)
        end)
        ticker.AddTimerOnce(5.0, function()
            pcall(_G.V34_DumpAirDropSys)
        end)
        ticker.AddTimerOnce(8.0, function()
            pcall(_G.V34_HookAirDrop)
        end)
    end
end)

S("v34_report.txt", "v34 loaded at " .. os.date() .. "\nTarget: BornIslandAirDropSystem\n")
print("[V34] Loaded. Born Island dumper + air drop hook active.")

return true
