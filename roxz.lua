-- ═══════════════════════════════════════════════════════════════════
-- v31 — FORCE McLAREN IN GetSelfVehicleInfo
-- Root cause: server returns ItemID=1961001 (default), we want 1961014
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
    skinResID = 1961014,         -- McLaren
    defaultSkin = 1961001,       -- Coupe RB default (jo server de raha)
    skinInsID = 7247538342442672654,
}

-- ═══════════════════════════════════════════════════════════════════
-- NUCLEAR REVERT
-- ═══════════════════════════════════════════════════════════════════
local PREFIXES = {
    "__mini11_", "__v12_", "__v13_", "__v14_", "__v15_", "__v16_",
    "__v17_", "__v18_", "__v19_", "__v20_", "__v21_", "__v22_",
    "__v23_", "__v25_", "__v26_", "__v27_", "__v28_", "__v29_", "__v30_",
    "__slotv10_", "__pet11_", "__pslotv2_", "__pslot11_",
}
local reverted = 0
local function revertModule(mod)
    if type(mod) ~= "table" then return 0 end
    local cnt = 0
    local backups = {}
    for k in pairs(mod) do
        if type(k) == "string" then
            for _, pfx in ipairs(PREFIXES) do
                if k:sub(1, #pfx) == pfx then
                    backups[#backups+1] = {bk = k, orig = k:sub(#pfx+1)}
                    break
                end
            end
        end
    end
    for _, item in ipairs(backups) do
        if type(mod[item.bk]) == "function" then
            mod[item.orig] = mod[item.bk]
            cnt = cnt + 1
        end
        mod[item.bk] = nil
    end
    return cnt
end

pcall(function()
    local M = require("client.logic.lobby.ThemeVehicleManager")
    if M and M.__inner_impl and M.__inner_impl ~= M then
        reverted = reverted + revertModule(M.__inner_impl)
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- WRAP HELPER
-- ═══════════════════════════════════════════════════════════════════
local PFX = "__v31_"
local function wrap(mod, name, wrapper)
    if not mod or type(mod[name]) ~= "function" then return false end
    if not mod[PFX .. name] then mod[PFX .. name] = mod[name] end
    mod[name] = wrapper(mod[PFX .. name])
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- ⭐ CRITICAL FIX — GetSelfVehicleInfo return McLaren
-- ═══════════════════════════════════════════════════════════════════
local patched = 0
pcall(function()
    local M = require("client.logic.lobby.ThemeVehicleManager")
    local i = M and M.__inner_impl
    if not i then return end

    -- Init state
    if type(i.Vehicles) ~= "table" then i.Vehicles = {} end
    if type(i.RepeatTags) ~= "table" then i.RepeatTags = {} end

    -- ⭐⭐⭐ THE FIX ⭐⭐⭐
    -- Force slot 1 to McLaren skin
    if wrap(i, "GetSelfVehicleInfo", function(orig)
        return function(self, ...)
            local r = orig(self, ...)
            if type(r) ~= "table" then r = {} end

            -- Force slot 1 to McLaren
            r[1] = r[1] or {}
            r[1].Source = r[1].Source or 1
            r[1].ItemID = CFG.skinResID       -- 1961014 (McLaren)
            r[1].SkinID = CFG.skinResID
            r[1].ResID = CFG.skinResID
            r[1].VehicleID = CFG.baseVehicleID
            r[1].InsID = CFG.skinInsID
            r[1].Level = r[1].Level or 1

            print("[V31] GetSelfVehicleInfo forced slot1 ItemID=1961014")
            return r
        end
    end) then patched = patched + 1 end

    -- GetSelfVehicleIDs — force Coupe RB in list
    if wrap(i, "GetSelfVehicleIDs", function(orig)
        return function(self, ...)
            local r = orig(self, ...)
            if type(r) ~= "table" then r = {} end
            table.insert(r, 1, CFG.baseVehicleID)
            return r
        end
    end) then patched = patched + 1 end

    -- _TryCreateVehicleModel — force McLaren skin
    if wrap(i, "_TryCreateVehicleModel", function(orig)
        return function(self, skinResID, slotData, bForce, slotIndex, ...)
            -- Replace default with McLaren
            local newSkin = skinResID
            if skinResID == CFG.defaultSkin then
                newSkin = CFG.skinResID
            end

            -- Also inject skin into slotData if table
            if type(slotData) == "table" then
                slotData.ItemID = CFG.skinResID
                slotData.SkinID = CFG.skinResID
                slotData.VehicleID = CFG.baseVehicleID
                slotData.InsID = CFG.skinInsID
            end

            print("[V31] _TryCreateVehicleModel skin: " .. tostring(skinResID) .. 
                  " → " .. tostring(newSkin) .. " slot " .. tostring(slotIndex))

            local ok, err = pcall(orig, self, newSkin, slotData, bForce, slotIndex, ...)
            if not ok then
                print("[V31] ERR: " .. tostring(err):sub(1, 120))
            end
            return ok
        end
    end) then patched = patched + 1 end

    -- DestoryThemeVehicle — safety init RepeatTags
    if wrap(i, "DestoryThemeVehicle", function(orig)
        return function(self, ...)
            if type(self.RepeatTags) ~= "table" then self.RepeatTags = {} end
            return pcall(orig, self, ...)
        end
    end) then patched = patched + 1 end

    -- _ShowSelfVehicle — correct args
    if wrap(i, "_ShowSelfVehicle", function(orig)
        return function(self, ...)
            if type(self.Vehicles) ~= "table" then self.Vehicles = {} end
            if type(self.RepeatTags) ~= "table" then self.RepeatTags = {} end
            local ok = pcall(orig, self, CFG.baseVehicleID, CFG.skinInsID, ...)
            return ok
        end
    end) then patched = patched + 1 end

    -- _CreateVehicleModel
    if wrap(i, "_CreateVehicleModel", function(orig)
        return function(self, ...)
            if type(self.Vehicles) ~= "table" then self.Vehicles = {} end
            if type(self.RepeatTags) ~= "table" then self.RepeatTags = {} end
            local ok = pcall(orig, self, ...)
            return ok
        end
    end) then patched = patched + 1 end

    -- GetVehiclesType — force 1
    if wrap(i, "GetVehiclesType", function(orig)
        return function(self, ...) return 1 end
    end) then patched = patched + 1 end

    -- Unlock checks
    if wrap(i, "CheckVehicleTypeHasUnlock", function(orig)
        return function(self, ...) return true end
    end) then patched = patched + 1 end

    if wrap(i, "HaveEnoughVehicleShowSpecial", function(orig)
        return function(self, ...) return true end
    end) then patched = patched + 1 end

    if wrap(i, "NeedShowSpecialThemeEffect", function(orig)
        return function(self, ...) return true end
    end) then patched = patched + 1 end
end)

-- ═══════════════════════════════════════════════════════════════════
-- ⭐ MINI TV DROP EVENT TRIGGER (found from search)
-- ═══════════════════════════════════════════════════════════════════
_G.V31_TriggerMiniTvDrop = function()
    local results = {}

    pcall(function()
        local M = package.loaded["client.lobby_ue_object.Actor.MiniTV.MiniTVActor"]
        if type(M) == "table" then
            local i = M.__inner_impl
            if type(i) == "table" then
                -- Try DropEvent
                if type(i.DropEvent) == "function" then
                    local ok = pcall(i.DropEvent, i, CFG.baseVehicleID)
                    results[#results+1] = "MiniTVActor.DropEvent: " .. (ok and "OK" or "ERR")
                end
                -- Try PlayAirDropAnimEvent
                if type(i.PlayAirDropAnimEvent) == "function" then
                    local ok = pcall(i.PlayAirDropAnimEvent, i)
                    results[#results+1] = "PlayAirDropAnimEvent: " .. (ok and "OK" or "ERR")
                end
                -- Try SetDropHigh
                if type(i.SetDropHigh) == "function" then
                    local ok = pcall(i.SetDropHigh, i, 1000)
                    results[#results+1] = "SetDropHigh: " .. (ok and "OK" or "ERR")
                end
                -- Try TryFloatOrDrop
                if type(i.TryFloatOrDrop) == "function" then
                    local ok = pcall(i.TryFloatOrDrop, i)
                    results[#results+1] = "TryFloatOrDrop: " .. (ok and "OK" or "ERR")
                end
            end
        else
            results[#results+1] = "MiniTVActor not loaded"
        end
    end)

    return results
end

-- ═══════════════════════════════════════════════════════════════════
-- ⭐ LOOT TRUCK CRATE TRIGGER (found from search)
-- ═══════════════════════════════════════════════════════════════════
_G.V31_TriggerLootTruckCrate = function()
    local results = {}
    pcall(function()
        local M = package.loaded["GameLua.Mod.Library.Gameplay.Vehicle.LootTruck.LootTruckCrateFeature"]
        if type(M) == "table" then
            local i = M.__inner_impl
            if type(i) == "table" and type(i.TriggerCrate) == "function" then
                local ok = pcall(i.TriggerCrate, i)
                results[#results+1] = "TriggerCrate: " .. (ok and "OK" or "ERR")
            end
        end
    end)
    return results
end

-- ═══════════════════════════════════════════════════════════════════
-- MAIN — FULL SPAWN SEQUENCE
-- ═══════════════════════════════════════════════════════════════════
_G.V31_Spawn = function()
    local results = {}

    local M = require("client.logic.lobby.ThemeVehicleManager")
    local i = M and M.__inner_impl
    if not i then P("V31", "TVM not loaded") return end

    -- Init state
    if type(i.Vehicles) ~= "table" then i.Vehicles = {} end
    if type(i.RepeatTags) ~= "table" then i.RepeatTags = {} end

    -- 1. DataMgr data
    pcall(function()
        local DM = _G.DataMgr
        if DM and DM.roleData then
            DM.roleData.vst_skin = CFG.skinInsID
            results[#results+1] = "✓ vst_skin"
        end
        if DM then
            if type(DM.vehicleSkinInsIDTable) == "table" then
                DM.vehicleSkinInsIDTable[902] = CFG.skinInsID
            end
            if type(DM.VehicleSlotList) == "table" then
                DM.VehicleSlotList[902] = { [1] = CFG.skinInsID }
            end
            if type(DM.defaultVehicleSkinResIDTable) == "table" then
                DM.defaultVehicleSkinResIDTable[902] = CFG.skinResID
            end
        end
    end)

    -- 2. ShowThemeVehicle
    pcall(function()
        if type(i.ShowThemeVehicle) == "function" then
            local ok = pcall(i.ShowThemeVehicle, i, CFG.baseVehicleID)
            results[#results+1] = "ShowThemeVehicle: " .. (ok and "OK" or "ERR")
        end
    end)

    -- 3. _ShowSelfVehicle
    pcall(function()
        if type(i._ShowSelfVehicle) == "function" then
            local ok = pcall(i._ShowSelfVehicle, i, CFG.baseVehicleID, CFG.skinInsID)
            results[#results+1] = "_ShowSelfVehicle: " .. (ok and "OK" or "ERR")
        end
    end)

    -- 4. _ReinitShowModelActor
    pcall(function()
        if type(i._ReinitShowModelActor) == "function" then
            pcall(i._ReinitShowModelActor, i)
            results[#results+1] = "✓ _ReinitShowModelActor"
        end
    end)

    -- 5. RefreshSpecialEffect
    pcall(function()
        if type(i.RefreshSpecialEffect) == "function" then
            pcall(i.RefreshSpecialEffect, i)
            results[#results+1] = "✓ RefreshSpecialEffect"
        end
    end)

    -- 6. MiniTv drop
    local mt = V31_TriggerMiniTvDrop()
    for _, r in ipairs(mt) do
        results[#results+1] = r
    end

    -- 7. LootTruck crate
    local lt = V31_TriggerLootTruckCrate()
    for _, r in ipairs(lt) do
        results[#results+1] = r
    end

    -- 8. Verify Vehicles
    pcall(function()
        local count = 0
        if type(i.Vehicles) == "table" then
            for _ in pairs(i.Vehicles) do count = count + 1 end
        end
        results[#results+1] = "Vehicles count after: " .. count
    end)

    local txt = table.concat(results, "\n")
    S("v31_spawn.txt", txt)
    P("V31 SPAWN", txt)
    return txt
end

-- ═══════════════════════════════════════════════════════════════════
-- AUTO-RUN
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(3.0, function()
            pcall(_G.V31_Spawn)
        end)
    end
end)

S("v31_report.txt",
    "v31 REPORT\n" ..
    "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n" ..
    "Reverted: " .. reverted .. "\n" ..
    "Patched: " .. patched .. "\n" ..
    "Base: 902 | Skin: 1961014\n" ..
    "InsID: " .. CFG.skinInsID .. "\n\n" ..
    "KEY FIX: GetSelfVehicleInfo now returns McLaren\n" ..
    "Instead of server's 1961001 default.\n"
)

P("v31 LOADED",
    "McLaren Force Inject\n\n" ..
    "⭐ GetSelfVehicleInfo → McLaren 1961014\n" ..
    "⭐ MiniTVActor drop trigger\n" ..
    "⭐ LootTruck crate trigger\n\n" ..
    "3 sec mein auto-spawn.\n" ..
    "Manual: V31_Spawn()")

return true
