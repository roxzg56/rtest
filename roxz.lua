-- ═══════════════════════════════════════════════════════════════════
-- v30 — VEHICLE VISIBILITY CHECK + DROP TRIGGER
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

local CFG = {
    baseVehicleID = 902,
    skinResID = 1961014,
    skinInsID = 7247538342442672654,
}

-- ═══════════════════════════════════════════════════════════════════
-- ⭐ CHECK 1: Vehicle spawned in lobby?
-- ═══════════════════════════════════════════════════════════════════
_G.V30_CheckSpawn = function()
    local out = {}
    local function w(s) out[#out+1] = tostring(s) end
    w("═══ VEHICLE SPAWN CHECK ═══")
    w("Time: " .. os.date("%Y-%m-%d %H:%M:%S"))
    w("")

    local M = require("client.logic.lobby.ThemeVehicleManager")
    local i = M and M.__inner_impl
    if not i then
        w("ThemeVehicleManager NOT loaded")
        S("v30_spawn_check.txt", table.concat(out, "\n"))
        return
    end

    -- Vehicles table
    w("── i.Vehicles ──")
    if type(i.Vehicles) == "table" then
        local n = 0
        for slot, veh in pairs(i.Vehicles) do
            n = n + 1
            w("  Slot " .. tostring(slot) .. ":")
            w("    " .. tostring(veh))
            w("    type: " .. type(veh))
            if type(veh) == "table" then
                for k, v in pairs(veh) do
                    w("      " .. tostring(k) .. " = " .. tostring(v))
                end
            elseif type(veh) == "userdata" then
                pcall(function()
                    w("      (userdata object)")
                end)
            end
        end
        w("  Total: " .. n)
    else
        w("  NOT TABLE: " .. type(i.Vehicles))
    end
    w("")

    -- RepeatTags
    w("── i.RepeatTags ──")
    if type(i.RepeatTags) == "table" then
        local n = 0
        for k, v in pairs(i.RepeatTags) do
            n = n + 1
            w("  " .. tostring(k) .. " = " .. tostring(v))
        end
        w("  Count: " .. n)
    else
        w("  NOT TABLE: " .. type(i.RepeatTags))
    end
    w("")

    -- GetSelfVehicleInfo
    w("── GetSelfVehicleInfo ──")
    pcall(function()
        if type(i.GetSelfVehicleInfo) == "function" then
            local r = i.GetSelfVehicleInfo(i)
            if type(r) == "table" then
                for k, v in pairs(r) do
                    w("  [" .. tostring(k) .. "] = " .. tostring(v))
                    if type(v) == "table" then
                        for k2, v2 in pairs(v) do
                            w("      " .. tostring(k2) .. " = " .. tostring(v2))
                        end
                    end
                end
            end
        end
    end)

    local txt = table.concat(out, "\n")
    S("v30_spawn_check.txt", txt)
    print(txt)
    P("V30 SPAWN CHECK", "Saved: v30_spawn_check.txt")
    return txt
end

-- ═══════════════════════════════════════════════════════════════════
-- ⭐ CHECK 2: Find drop/debut/parachute functions
-- ═══════════════════════════════════════════════════════════════════
_G.V30_FindDropFn = function()
    local out = {}
    local function w(s) out[#out+1] = tostring(s) end
    w("═══ DROP ANIMATION FUNCTION SEARCH ═══")
    w("")

    local keywords = { "drop", "debut", "parachute", "grand", "reward",
                       "unlock", "collect", "spawn", "reveal", "open",
                       "showcase", "container", "crate" }

    local hits = {}

    -- Search ThemeVehicleManager
    local M = require("client.logic.lobby.ThemeVehicleManager")
    if M and M.__inner_impl then
        local i = M.__inner_impl
        for k, v in pairs(i) do
            if type(v) == "function" and type(k) == "string" then
                local lk = k:lower()
                for _, kw in ipairs(keywords) do
                    if lk:find(kw) then
                        hits[#hits+1] = "TVM." .. k
                        break
                    end
                end
            end
        end
    end

    -- Search ALL package.loaded for these keywords
    for path, mod in pairs(package.loaded) do
        if type(path) == "string" and type(mod) == "table" then
            local lk_path = path:lower()
            -- Only vehicle/lobby related
            if lk_path:find("vehicle") or lk_path:find("lobby") 
               or lk_path:find("garage") or lk_path:find("collect") then
                for k, v in pairs(mod) do
                    if type(v) == "function" and type(k) == "string" then
                        local lk = k:lower()
                        for _, kw in ipairs(keywords) do
                            if lk:find(kw) then
                                hits[#hits+1] = path .. "." .. k
                                break
                            end
                        end
                    end
                end
                -- Also inner_impl
                local i = mod.__inner_impl
                if type(i) == "table" then
                    for k, v in pairs(i) do
                        if type(v) == "function" and type(k) == "string" then
                            local lk = k:lower()
                            for _, kw in ipairs(keywords) do
                                if lk:find(kw) then
                                    hits[#hits+1] = path .. "__inner_impl." .. k
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(hits)
    -- Dedup
    local seen = {}
    w("── MATCHING FUNCTIONS (" .. #hits .. ") ──")
    for _, h in ipairs(hits) do
        if not seen[h] then
            seen[h] = true
            w("  ⭐ " .. h)
        end
    end

    local txt = table.concat(out, "\n")
    S("v30_drop_functions.txt", txt)
    print(txt)
    P("V30 DROP FN", "Saved: v30_drop_functions.txt\n(" .. #hits .. " functions)")
    return txt
end

-- ═══════════════════════════════════════════════════════════════════
-- ⭐ CHECK 3: Trace vehicle model creation
-- ═══════════════════════════════════════════════════════════════════
_G._V30_TraceLog = {}
_G._V30_TraceActive = false

_G.V30_TraceStart = function()
    if _G._V30_TraceActive then
        P("V30", "Already tracing")
        return
    end
    _G._V30_TraceActive = true
    _G._V30_TraceLog = {}

    local function log(s)
        _G._V30_TraceLog[#_G._V30_TraceLog+1] = 
            string.format("[%s] %s", os.date("%H:%M:%S"), s)
    end

    log("=== TRACE START ===")

    -- Hook ThemeVehicleManager specific functions
    local M = require("client.logic.lobby.ThemeVehicleManager")
    if M and M.__inner_impl then
        local i = M.__inner_impl
        local HOOK_FNS = {
            "_TryCreateVehicleModel",
            "_CreateVehicleModel",
            "_ShowSelfVehicle",
            "ShowThemeVehicle",
            "DestoryThemeVehicle",
            "DestroyAllThemeVehiclesOnly",
            "RefreshSpecialEffect",
            "_ReinitShowModelActor",
            "GetSelfVehicleInfo",
            "GetVehiclesType",
            "SetVehicleTick",
        }
        for _, fnName in ipairs(HOOK_FNS) do
            if type(i[fnName]) == "function" then
                local orig = i[fnName]
                i[fnName] = function(self, ...)
                    local args = {}
                    for n = 1, math.min(6, select("#", ...)) do
                        local v = select(n, ...)
                        if type(v) == "table" then
                            args[#args+1] = "tbl{" .. (next(v) and tostring(next(v)) or "") .. "}"
                        else
                            args[#args+1] = tostring(v):sub(1, 30)
                        end
                    end
                    log("→ " .. fnName .. "(" .. table.concat(args, ",") .. ")")
                    local ok, r = pcall(orig, self, ...)
                    if not ok then
                        log("  ✗ ERR: " .. tostring(r):sub(1, 150))
                    else
                        log("  ↳ RET: " .. tostring(r):sub(1, 60))
                    end
                    return r
                end
                log("Hooked: " .. fnName)
            end
        end
    end

    -- Auto-save every 5 sec
    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerLoop then
            ticker.AddTimerLoop(0, function()
                if _G._V30_TraceActive and #_G._V30_TraceLog > 0 then
                    S("v30_trace.txt", table.concat(_G._V30_TraceLog, "\n"))
                end
            end, -1, 5.0)
        end
    end)

    P("V30 TRACE", "Started.\n\nNow:\n1. Lobby jao\n2. Garage kholo\n3. Coupe RB select karo\n4. Wait 15 sec\n5. V30_TraceStop()")
end

_G.V30_TraceStop = function()
    _G._V30_TraceActive = false
    local txt = table.concat(_G._V30_TraceLog or {}, "\n")
    S("v30_trace.txt", txt)
    P("V30 TRACE STOP", "Saved: v30_trace.txt\nLines: " .. #(_G._V30_TraceLog or {}))
end

-- ═══════════════════════════════════════════════════════════════════
-- ⭐ FIX: Force model visibility + re-apply
-- ═══════════════════════════════════════════════════════════════════
local PFX = "__v30_"
local function wrap(mod, name, wrapper)
    if not mod or type(mod[name]) ~= "function" then return false end
    if not mod[PFX .. name] then mod[PFX .. name] = mod[name] end
    mod[name] = wrapper(mod[PFX .. name])
    return true
end

pcall(function()
    local M = require("client.logic.lobby.ThemeVehicleManager")
    local i = M and M.__inner_impl
    if not i then return end

    -- Force RepeatTags + Vehicles before ANY call
    local function ensureState()
        if type(i.RepeatTags) ~= "table" then i.RepeatTags = {} end
        if type(i.Vehicles) ~= "table" then i.Vehicles = {} end
    end

    ensureState()

    -- Wrap _TryCreateVehicleModel — after success, force visible
    if wrap(i, "_TryCreateVehicleModel", function(orig)
        return function(self, skinResID, slotData, bForce, slotIndex, ...)
            ensureState()

            -- Force McLaren skin
            local useSkin = skinResID
            if useSkin == 1961001 then useSkin = CFG.skinResID end

            local ok, err = pcall(orig, self, useSkin, slotData, bForce, slotIndex, ...)
            if not ok then
                print("[V30] _TryCreate err: " .. tostring(err):sub(1, 100))
            end

            -- Force visibility of created model
            pcall(function()
                if type(self.Vehicles) == "table" then
                    for slot, veh in pairs(self.Vehicles) do
                        if type(veh) == "table" and veh.SetActorHiddenInGame then
                            veh:SetActorHiddenInGame(false)
                        elseif type(veh) == "userdata" then
                            pcall(function() veh:SetActorHiddenInGame(false) end)
                        end
                    end
                end
            end)

            return ok
        end
    end) then print("[V30] Wrapped _TryCreateVehicleModel") end

    -- Wrap ShowThemeVehicle to ensure state
    if wrap(i, "ShowThemeVehicle", function(orig)
        return function(self, ...)
            ensureState()
            local ok = pcall(orig, self, CFG.baseVehicleID)
            return ok
        end
    end) then print("[V30] Wrapped ShowThemeVehicle") end

    -- Wrap _ReinitShowModelActor — force visible after
    if wrap(i, "_ReinitShowModelActor", function(orig)
        return function(self, ...)
            ensureState()
            local ok = pcall(orig, self, ...)
            pcall(function()
                if type(self.Vehicles) == "table" then
                    for _, veh in pairs(self.Vehicles) do
                        if type(veh) == "table" then
                            if veh.SetActorHiddenInGame then veh:SetActorHiddenInGame(false) end
                            if veh.SetVisibility then veh:SetVisibility(true) end
                        elseif type(veh) == "userdata" then
                            pcall(function() veh:SetActorHiddenInGame(false) end)
                        end
                    end
                end
            end)
            return ok
        end
    end) then print("[V30] Wrapped _ReinitShowModelActor") end
end)

-- ═══════════════════════════════════════════════════════════════════
-- MANUAL FULL SPAWN SEQUENCE
-- ═══════════════════════════════════════════════════════════════════
_G.V30_Spawn = function()
    local M = require("client.logic.lobby.ThemeVehicleManager")
    local i = M and M.__inner_impl
    if not i then P("V30", "TVM not loaded") return end

    -- Ensure state
    if type(i.RepeatTags) ~= "table" then i.RepeatTags = {} end
    if type(i.Vehicles) ~= "table" then i.Vehicles = {} end

    local results = {}

    -- Step 1: Set vst_skin
    pcall(function()
        local DM = _G.DataMgr
        if DM and DM.roleData then
            DM.roleData.vst_skin = CFG.skinInsID
            results[#results+1] = "✓ vst_skin"
        end
    end)

    -- Step 2: Fake ownership data
    pcall(function()
        local DM = _G.DataMgr
        if DM then
            if type(DM.vehicleSkinInsIDTable) == "table" then
                DM.vehicleSkinInsIDTable[902] = CFG.skinInsID
                DM.vehicleSkinInsIDTable[961] = CFG.skinInsID
            end
            if type(DM.VehicleSlotList) == "table" then
                DM.VehicleSlotList[902] = { [1] = CFG.skinInsID }
                DM.VehicleSlotList[961] = { [1] = CFG.skinInsID }
            end
            if type(DM.defaultVehicleSkinResIDTable) == "table" then
                DM.defaultVehicleSkinResIDTable[902] = CFG.skinResID
                DM.defaultVehicleSkinResIDTable[961] = CFG.skinResID
            end
            results[#results+1] = "✓ DataMgr faked"
        end
    end)

    -- Step 3: Show theme vehicle
    pcall(function()
        if type(i.ShowThemeVehicle) == "function" then
            local ok = pcall(i.ShowThemeVehicle, i, CFG.baseVehicleID)
            results[#results+1] = "ShowThemeVehicle(902): " .. (ok and "OK" or "ERR")
        end
    end)

    -- Step 4: Show self vehicle
    pcall(function()
        if type(i._ShowSelfVehicle) == "function" then
            local ok = pcall(i._ShowSelfVehicle, i, CFG.baseVehicleID, CFG.skinInsID)
            results[#results+1] = "_ShowSelfVehicle: " .. (ok and "OK" or "ERR")
        end
    end)

    -- Step 5: Reinit model
    pcall(function()
        if type(i._ReinitShowModelActor) == "function" then
            pcall(i._ReinitShowModelActor, i)
            results[#results+1] = "✓ _ReinitShowModelActor"
        end
    end)

    -- Step 6: Refresh effect
    pcall(function()
        if type(i.RefreshSpecialEffect) == "function" then
            pcall(i.RefreshSpecialEffect, i)
            results[#results+1] = "✓ RefreshSpecialEffect"
        end
    end)

    -- Step 7: Set tick
    pcall(function()
        if type(i.SetVehicleTick) == "function" then
            pcall(i.SetVehicleTick, i, true)
            results[#results+1] = "✓ SetVehicleTick"
        end
    end)

    -- Step 8: Force visible
    pcall(function()
        if type(i.Vehicles) == "table" then
            local count = 0
            for slot, veh in pairs(i.Vehicles) do
                count = count + 1
                if type(veh) == "table" then
                    if veh.SetActorHiddenInGame then veh:SetActorHiddenInGame(false) end
                    if veh.SetVisibility then veh:SetVisibility(true) end
                elseif type(veh) == "userdata" then
                    pcall(function() veh:SetActorHiddenInGame(false) end)
                end
            end
            results[#results+1] = "Visible check: " .. count .. " vehicles"
        end
    end)

    -- Save
    local txt = table.concat(results, "\n")
    S("v30_spawn.txt", txt)
    P("V30 SPAWN", txt)

    -- Auto-check after 2 sec
    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(2.0, function()
                V30_CheckSpawn()
            end)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- AUTO-BOOT
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        -- 5s: first spawn try
        ticker.AddTimerOnce(5.0, function()
            pcall(_G.V30_Spawn)
        end)
        -- 12s: check spawn
        ticker.AddTimerOnce(12.0, function()
            pcall(_G.V30_CheckSpawn)
        end)
        -- 15s: find drop functions
        ticker.AddTimerOnce(15.0, function()
            pcall(_G.V30_FindDropFn)
        end)
    end
end)

S("v30_report.txt",
    "v30 REPORT\n" ..
    "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n" ..
    "Base: 902 | Skin: 1961014\n" ..
    "InsID: " .. CFG.skinInsID .. "\n\n" ..
    "Commands:\n" ..
    "  V30_Spawn()          -- force spawn\n" ..
    "  V30_CheckSpawn()     -- verify spawned\n" ..
    "  V30_FindDropFn()     -- find drop/animation fn\n" ..
    "  V30_TraceStart()     -- start trace\n" ..
    "  V30_TraceStop()      -- save trace\n"
)

P("v30 LOADED",
    "Spawn + Drop Discovery\n\n" ..
    "Auto:\n" ..
    "  5s → spawn try\n" ..
    "  12s → check spawn\n" ..
    "  15s → find drop functions\n\n" ..
    "Manual:\n" ..
    "V30_Spawn()\n" ..
    "V30_CheckSpawn()\n" ..
    "V30_FindDropFn()")

return true
