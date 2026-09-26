-- ═══════════════════════════════════════════════════════════════════
-- v29 — REPEATTAGS FIX + McLAREN SKIN FORCE
-- Fix: nil RepeatTags crash + force 1961014 skin
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

-- ═══════════════════════════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════════════════════════
local CFG = {
    baseVehicleID = 902,
    skinResID = 1961014,                -- McLaren
    defaultSkinResID = 1961001,          -- Coupe RB default (jo trace mein aya)
    insID = 7247538342442672640,
    skinInsID = 7247538342442672654,
}

-- ═══════════════════════════════════════════════════════════════════
-- REVERT
-- ═══════════════════════════════════════════════════════════════════
local PREFIXES = {
    "__mini11_", "__v12_", "__v13_", "__v14_", "__v15_", "__v16_",
    "__v17_", "__v18_", "__v19_", "__v20_", "__v21_", "__v22_",
    "__v23_", "__v25_", "__v26_", "__v27_", "__v28_",
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
    if M and M ~= M.__inner_impl then
        reverted = reverted + revertModule(M)
    end
end)

S("v29_step1.txt", "Reverted: " .. reverted)

-- ═══════════════════════════════════════════════════════════════════
-- ⭐ FIX 1: INITIALIZE RepeatTags (CRASH ROOT CAUSE)
-- ═══════════════════════════════════════════════════════════════════
_G.V29_InitState = function()
    local M = require("client.logic.lobby.ThemeVehicleManager")
    if type(M) ~= "table" then return false end
    local i = M.__inner_impl
    if type(i) ~= "table" then return false end

    -- THE FIX: init all tables that are nil
    if type(i.RepeatTags) ~= "table" then
        i.RepeatTags = {}
        print("[V29] Init RepeatTags = {}")
    end
    if type(i.Vehicles) ~= "table" then
        i.Vehicles = {}
        print("[V29] Init Vehicles = {}")
    end
    if type(i._tVehicleToSlots) ~= "table" then
        i._tVehicleToSlots = {}
    end
    if type(i._tSlotToVehicle) ~= "table" then
        i._tSlotToVehicle = {}
    end
    if type(i._tVehicleInfoMap) ~= "table" then
        i._tVehicleInfoMap = {}
    end
    if type(i._tCarInfoMap) ~= "table" then
        i._tCarInfoMap = {}
    end
    if type(i._tVehicleTypes) ~= "table" then
        i._tVehicleTypes = {}
    end

    print("[V29] All state tables initialized")
    return true
end

V29_InitState()

-- ═══════════════════════════════════════════════════════════════════
-- WRAP HELPER
-- ═══════════════════════════════════════════════════════════════════
local PFX = "__v29_"
local function wrap(mod, name, wrapper)
    if not mod or type(mod[name]) ~= "function" then return false end
    if not mod[PFX .. name] then mod[PFX .. name] = mod[name] end
    mod[name] = wrapper(mod[PFX .. name])
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- ⭐ FIX 2: PATCH ThemeVehicleManager
-- ═══════════════════════════════════════════════════════════════════
local patched = 0
pcall(function()
    local M = require("client.logic.lobby.ThemeVehicleManager")
    local i = M and M.__inner_impl
    if not i then return end

    -- ═══ FIX: Wrap DestoryThemeVehicle to safety-check RepeatTags ═══
    if wrap(i, "DestoryThemeVehicle", function(orig)
        return function(self, slotIndex, ...)
            -- Init before call
            if type(self.RepeatTags) ~= "table" then
                self.RepeatTags = {}
            end
            local ok, err = pcall(orig, self, slotIndex, ...)
            if not ok then
                print("[V29] DestoryThemeVehicle(" .. tostring(slotIndex) .. ") err: " .. tostring(err):sub(1, 100))
                -- fallback — reset RepeatTags
                self.RepeatTags = {}
            end
            return ok
        end
    end) then patched = patched + 1 end

    -- ═══ FIX: Wrap _TryCreateVehicleModel — FORCE McLaren skin ═══
    -- Original: _TryCreateVehicleModel(1961001, tbl, false, 1, nil)
    -- We want:  _TryCreateVehicleModel(1961014, tbl, false, 1, nil)
    if wrap(i, "_TryCreateVehicleModel", function(orig)
        return function(self, skinResID, slotData, bForce, slotIndex, ...)
            -- Init state
            if type(self.RepeatTags) ~= "table" then self.RepeatTags = {} end
            if type(self.Vehicles) ~= "table" then self.Vehicles = {} end

            -- Force McLaren skin if Coupe RB base
            local origSkin = skinResID
            if skinResID == CFG.defaultSkinResID then
                skinResID = CFG.skinResID
                print("[V29] Skin forced: 1961001 → " .. CFG.skinResID)
            end

            -- Try with correct args
            local ok, err = pcall(orig, self, skinResID, slotData, bForce, slotIndex, ...)
            if not ok then
                print("[V29] _TryCreateVehicleModel(" .. tostring(skinResID) .. 
                      "," .. tostring(slotIndex) .. ") err: " .. tostring(err):sub(1, 120))
                
                -- Retry with original skin
                if skinResID ~= origSkin then
                    local ok2, err2 = pcall(orig, self, origSkin, slotData, bForce, slotIndex, ...)
                    if not ok2 then
                        print("[V29] Retry err: " .. tostring(err2):sub(1, 100))
                    end
                    return ok2
                end
            end
            return ok
        end
    end) then patched = patched + 1 end

    -- ═══ FIX: _ShowSelfVehicle — pass correct skin ═══
    if wrap(i, "_ShowSelfVehicle", function(orig)
        return function(self, vehicleID, insID, ...)
            if type(self.RepeatTags) ~= "table" then self.RepeatTags = {} end
            if type(self.Vehicles) ~= "table" then self.Vehicles = {} end
            
            -- Force base vehicle to Coupe RB
            local targetVID = CFG.baseVehicleID
            local targetIns = CFG.skinInsID  -- Use McLaren skin insID
            
            print("[V29] _ShowSelfVehicle(" .. tostring(targetVID) .. ", " .. tostring(targetIns) .. ")")
            local ok, err = pcall(orig, self, targetVID, targetIns, ...)
            if not ok then
                print("[V29] _ShowSelfVehicle err: " .. tostring(err):sub(1, 120))
            end
            return ok
        end
    end) then patched = patched + 1 end

    -- ═══ FIX: _CreateVehicleModel ═══
    if wrap(i, "_CreateVehicleModel", function(orig)
        return function(self, ...)
            if type(self.RepeatTags) ~= "table" then self.RepeatTags = {} end
            if type(self.Vehicles) ~= "table" then self.Vehicles = {} end
            local ok, err = pcall(orig, self, ...)
            if not ok then
                print("[V29] _CreateVehicleModel err: " .. tostring(err):sub(1, 100))
            end
            return ok
        end
    end) then patched = patched + 1 end

    -- ═══ FIX: GetSelfVehicleInfo — inject McLaren in slot 1 ═══
    if wrap(i, "GetSelfVehicleInfo", function(orig)
        return function(self, ...)
            local r = orig(self, ...)
            if type(r) ~= "table" then r = {} end
            
            -- Force slot 1 to have McLaren info
            r[1] = r[1] or {}
            r[1].ItemID = CFG.skinResID        -- McLaren skin
            r[1].SkinID = CFG.skinResID
            r[1].VehicleID = CFG.baseVehicleID
            r[1].InsID = CFG.skinInsID
            r[1].Source = r[1].Source or 1
            
            return r
        end
    end) then patched = patched + 1 end

    -- ═══ Unlock checks ═══
    if wrap(i, "CheckVehicleTypeHasUnlock", function(orig)
        return function(self, ...) return true end
    end) then patched = patched + 1 end

    if wrap(i, "HaveEnoughVehicleShowSpecial", function(orig)
        return function(self, ...) return true end
    end) then patched = patched + 1 end

    if wrap(i, "NeedShowSpecialThemeEffect", function(orig)
        return function(self, ...) return true end
    end) then patched = patched + 1 end

    if wrap(i, "GetValidVehicleNum", function(orig)
        return function(self, ...) return 999 end
    end) then patched = patched + 1 end

    if wrap(i, "GetVehiclesType", function(orig)
        return function(self, ...) return 1 end  -- Was -1, force to valid
    end) then patched = patched + 1 end

    -- Show theme vehicle force
    if wrap(i, "ShowThemeVehicle", function(orig)
        return function(self, vehicleID, ...)
            if type(self.RepeatTags) ~= "table" then self.RepeatTags = {} end
            if type(self.Vehicles) ~= "table" then self.Vehicles = {} end
            local ok = pcall(orig, self, CFG.baseVehicleID)
            return ok
        end
    end) then patched = patched + 1 end
end)

S("v29_step2.txt", "Patched: " .. patched)

-- ═══════════════════════════════════════════════════════════════════
-- FIX DataMgr — force McLaren skin in data
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local DM = _G.DataMgr
    if not DM then return end

    if DM.roleData then
        DM.roleData.vst_skin = CFG.skinInsID
    end

    if type(DM.vehicleSkinInsIDTable) == "table" then
        DM.vehicleSkinInsIDTable[902] = CFG.skinInsID
        DM.vehicleSkinInsIDTable[961] = CFG.skinInsID
    end

    if type(DM.VehicleSlotList) == "table" then
        DM.VehicleSlotList[902] = { [1] = CFG.skinInsID }
        DM.VehicleSlotList[961] = { [1] = CFG.skinInsID }
    end

    -- CRITICAL: ensure default skin also points to McLaren for display
    if type(DM.defaultVehicleSkinResIDTable) == "table" then
        DM.defaultVehicleSkinResIDTable[902] = CFG.skinResID
        DM.defaultVehicleSkinResIDTable[961] = CFG.skinResID
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- MANUAL SPAWN with RepeatTags init
-- ═══════════════════════════════════════════════════════════════════
_G.V29_Spawn = function()
    -- STEP 1: Always init state first
    V29_InitState()

    local results = {}

    -- STEP 2: Set vst_skin
    pcall(function()
        local DM = _G.DataMgr
        if DM and DM.roleData then
            DM.roleData.vst_skin = CFG.skinInsID
            results[#results+1] = "✓ vst_skin = " .. CFG.skinInsID
        end
    end)

    -- STEP 3: Trigger
    pcall(function()
        local M = require("client.logic.lobby.ThemeVehicleManager")
        local i = M and M.__inner_impl
        if not i then results[#results+1] = "✗ TVM not loaded" return end

        -- Ensure RepeatTags before any call
        if type(i.RepeatTags) ~= "table" then i.RepeatTags = {} end
        if type(i.Vehicles) ~= "table" then i.Vehicles = {} end

        if type(i.ShowThemeVehicle) == "function" then
            local ok = pcall(i.ShowThemeVehicle, i, CFG.baseVehicleID)
            results[#results+1] = "ShowThemeVehicle(902): " .. (ok and "OK" or "ERR")
        end

        if type(i._ShowSelfVehicle) == "function" then
            local ok = pcall(i._ShowSelfVehicle, i, CFG.baseVehicleID, CFG.skinInsID)
            results[#results+1] = "_ShowSelfVehicle: " .. (ok and "OK" or "ERR")
        end

        if type(i.RefreshSpecialEffect) == "function" then
            pcall(i.RefreshSpecialEffect, i)
            results[#results+1] = "✓ RefreshSpecialEffect"
        end

        if type(i._ReinitShowModelActor) == "function" then
            pcall(i._ReinitShowModelActor, i)
            results[#results+1] = "✓ _ReinitShowModelActor"
        end

        if type(i.SetVehicleTick) == "function" then
            pcall(i.SetVehicleTick, i, true)
            results[#results+1] = "✓ SetVehicleTick"
        end
    end)

    local txt = table.concat(results, "\n")
    S("v29_spawn.txt", txt)
    P("V29 SPAWN", txt)
    return txt
end

-- ═══════════════════════════════════════════════════════════════════
-- REPORT
-- ═══════════════════════════════════════════════════════════════════
S("v29_report.txt",
    "v29 REPORT\n" ..
    "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n" ..
    "Reverted: " .. reverted .. "\n" ..
    "Patched: " .. patched .. "\n" ..
    "\nFIXES:\n" ..
    "  1. RepeatTags = {} (crash fix)\n" ..
    "  2. Vehicles = {} (crash fix)\n" ..
    "  3. _TryCreateVehicleModel → force skin 1961014\n" ..
    "  4. _ShowSelfVehicle → correct args\n" ..
    "  5. GetSelfVehicleInfo → McLaren in slot 1\n" ..
    "  6. GetVehiclesType → 1 (was -1)\n" ..
    "\nCONFIG:\n" ..
    "  baseVehicleID = " .. CFG.baseVehicleID .. "\n" ..
    "  skinResID = " .. CFG.skinResID .. "\n" ..
    "  skinInsID = " .. CFG.skinInsID .. "\n"
)

-- Auto-spawn 5 sec after load
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(5.0, function()
            pcall(_G.V29_Spawn)
        end)
    end
end)

-- Auto-init state every 10 sec
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerLoop then
        ticker.AddTimerLoop(0, function()
            pcall(_G.V29_InitState)
        end, -1, 10.0)
    end
end)

P("v29 LOADED",
    "McLaren Drop (RepeatTags FIXED)\n\n" ..
    "Root cause: RepeatTags nil crash\n" ..
    "Fix: auto-init + retry\n\n" ..
    "Base: 902 | Skin: 1961014\n" ..
    "InsID: " .. CFG.skinInsID .. "\n\n" ..
    "5 sec mein auto-spawn hoga.\n" ..
    "Manual: V29_Spawn()")

return true
