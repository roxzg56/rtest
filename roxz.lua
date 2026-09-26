-- ═══════════════════════════════════════════════════════════════════
-- v26 — McLAREN LEGENDARY DROP
-- Skin 1961014 (McLaren 570S Royal Black) on Coupe RB
-- Trigger: Drop box + parachute + legendary bypass
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
-- CONFIG — McLaren IDs
-- ═══════════════════════════════════════════════════════════════════
local CFG = {
    baseVehicleID  = 961,           -- Coupe RB / McLaren base vehicle
    skinResID      = 1961014,       -- McLaren 570S Royal Black
    dropEnabled    = true,          -- trigger drop animation
    fakeLegendary  = true,          -- force legendary flag
}

S("v26_config.txt",
    "-- v26 McLaren Config\n" ..
    "-- Skin: McLaren 570S Royal Black\n" ..
    "-- Base Vehicle: Coupe RB\n" ..
    "return {\n" ..
    "    baseVehicleID = 961,\n" ..
    "    skinResID     = 1961014,\n" ..
    "    dropEnabled   = true,\n" ..
    "    fakeLegendary = true,\n" ..
    "}\n"
)

-- Generate InsID for McLaren
local McLarenInsID = 7656927787236720000 + (961 * 1000) + 1014
-- = 7656927787236720010 + 961014 
-- = ~7656927787237681xxx

-- Real known InsID for 961 default is 7247538342442672628
-- Our fake: 7247538342442672628 + (1961014 - 1961001) = +13
local McLarenFakeInsID = 7247538342442672641

-- ═══════════════════════════════════════════════════════════════════
-- NUCLEAR REVERT
-- ═══════════════════════════════════════════════════════════════════
local PREFIXES = {
    "__mini11_", "__v12_", "__v13_", "__v14_", "__v15_", "__v16_",
    "__v17_", "__v18_", "__v19_", "__v20_", "__v21_", "__v22_",
    "__v23_", "__v25_", "__slotv10_", "__pet11_", "__pslotv2_", "__pslot11_",
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

for _, path in ipairs({
    "client.logic.lobby.ThemeVehicleManager",
    "client.logic.vehicle.VehicleCollectSystem",
    "client.logic.vehicle.LogicVehicleExtendedFeature",
    "client.logic.vehicle.LogicVehicleAccessory",
}) do
    pcall(function()
        local M = require(path)
        if M and M.__inner_impl and M.__inner_impl ~= M then
            reverted = reverted + revertModule(M.__inner_impl)
        end
        if M and M ~= M.__inner_impl then
            reverted = reverted + revertModule(M)
        end
    end)
end

S("v26_step1.txt", "Reverted: " .. reverted)

-- ═══════════════════════════════════════════════════════════════════
-- WRAP HELPER
-- ═══════════════════════════════════════════════════════════════════
local PFX = "__v26_"
local function wrap(mod, name, wrapper)
    if not mod or type(mod[name]) ~= "function" then return false end
    if not mod[PFX .. name] then mod[PFX .. name] = mod[name] end
    mod[name] = wrapper(mod[PFX .. name])
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 1: SET VST_SKIN — displayed vehicle
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local DM = _G.DataMgr
    if DM and DM.roleData then
        DM.roleData.vst_skin = McLarenFakeInsID
        print("[V26] Set vst_skin = " .. McLarenFakeInsID)
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 2: PATCH VehicleCollectSystem — McLaren in vehicle list
-- ═══════════════════════════════════════════════════════════════════
local p1 = {}
pcall(function()
    local M = require("client.logic.vehicle.VehicleCollectSystem")
    local i = M and M.__inner_impl
    if not i then return end

    -- Ensure CollectCarInfo doesn't break
    if i.CollectCarInfo == nil then i.CollectCarInfo = {} end

    -- Default show vehicle
    if wrap(i, "GetDefaultShowVehicle", function(orig)
        return function(self, ...)
            return CFG.baseVehicleID
        end
    end) then p1[#p1+1] = "GetDefaultShowVehicle" end

    -- Preview list include McLaren
    if wrap(i, "GetPreviewVehicleList", function(orig)
        return function(self, ...)
            local r = orig(self, ...) or {}
            if type(r) ~= "table" then r = {} end
            table.insert(r, 1, CFG.baseVehicleID)
            return r
        end
    end) then p1[#p1+1] = "GetPreviewVehicleList" end

    -- Owned vehicle num
    if wrap(i, "GetOwnVehicleNumByType", function(orig)
        return function(self, ...) return 999 end
    end) then p1[#p1+1] = "GetOwnVehicleNumByType" end

    -- Unlock everything
    if wrap(i, "HasUnLockFeature", function(orig)
        return function(self, ...) return true end
    end) then p1[#p1+1] = "HasUnLockFeature" end

    if wrap(i, "HasUnlockFeature2", function(orig)
        return function(self, ...) return true end
    end) then p1[#p1+1] = "HasUnlockFeature2" end

    if wrap(i, "IsOpenHighTire", function(orig)
        return function(self, ...) return true end
    end) then p1[#p1+1] = "IsOpenHighTire" end
end)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 3: PATCH ThemeVehicleManager — FORCE McLaren spawn
-- ═══════════════════════════════════════════════════════════════════
local p2 = {}
pcall(function()
    local M = require("client.logic.lobby.ThemeVehicleManager")
    local i = M and M.__inner_impl
    if not i then return end

    if i.Vehicles == nil then i.Vehicles = {} end

    -- ═══ Ownership checks → true ═══
    if wrap(i, "CheckVehicleTypeHasUnlock", function(orig)
        return function(self, ...) return true end
    end) then p2[#p2+1] = "CheckVehicleTypeHasUnlock" end

    if wrap(i, "HaveEnoughVehicleShowSpecial", function(orig)
        return function(self, ...) return true end
    end) then p2[#p2+1] = "HaveEnoughVehicleShowSpecial" end

    if wrap(i, "NeedShowSpecialThemeEffect", function(orig)
        return function(self, ...) return true end
    end) then p2[#p2+1] = "NeedShowSpecialThemeEffect" end

    -- ═══ Vehicle list → our McLaren ═══
    if wrap(i, "GetSelfVehicleIDs", function(orig)
        return function(self, ...)
            local r = orig(self, ...)
            if type(r) == "table" and next(r) then
                -- Include McLaren
                table.insert(r, 1, CFG.baseVehicleID)
                return r
            end
            return { CFG.baseVehicleID }
        end
    end) then p2[#p2+1] = "GetSelfVehicleIDs" end

    -- ═══ ShowThemeVehicle — FORCE McLaren ═══
    if wrap(i, "ShowThemeVehicle", function(orig)
        return function(self, vehicleID, ...)
            print("[V26] ShowThemeVehicle intercepted: " .. tostring(vehicleID))
            -- Force our config
            local ok = pcall(orig, self, CFG.baseVehicleID, ...)
            if not ok then
                pcall(orig, self, CFG.baseVehicleID)
            end
            return true
        end
    end) then p2[#p2+1] = "ShowThemeVehicle" end

    -- ═══ _ShowSelfVehicle — with CORRECT args ═══
    -- Error tha: ERR: .\client\logic\lobby\ThemeVehicleManager...
    -- Isse pata chalta hai args maang raha hai
    if wrap(i, "_ShowSelfVehicle", function(orig)
        return function(self, ...)
            print("[V26] _ShowSelfVehicle intercepted")
            -- Try multiple arg styles
            local tries = {
                function() return orig(self, CFG.baseVehicleID) end,
                function() return orig(self, CFG.baseVehicleID, McLarenFakeInsID) end,
                function() return orig(self, CFG.baseVehicleID, CFG.skinResID) end,
                function() return orig(self, {VehicleID = CFG.baseVehicleID, InsID = McLarenFakeInsID}) end,
                function() return orig(self, McLarenFakeInsID) end,
                function() return orig(self) end,  -- no args
            }
            for idx, fn in ipairs(tries) do
                local ok, err = pcall(fn)
                if ok then
                    print("[V26] _ShowSelfVehicle OK with arg style #" .. idx)
                    return true
                end
            end
            print("[V26] _ShowSelfVehicle all args failed")
            return false
        end
    end) then p2[#p2+1] = "_ShowSelfVehicle" end

    -- ═══ _CreateVehicleModel — with multiple arg styles ═══
    if wrap(i, "_CreateVehicleModel", function(orig)
        return function(self, ...)
            print("[V26] _CreateVehicleModel intercepted")
            local tries = {
                function() return orig(self, CFG.baseVehicleID) end,
                function() return orig(self, CFG.baseVehicleID, McLarenFakeInsID) end,
                function() return orig(self, CFG.baseVehicleID, CFG.skinResID) end,
                function() return orig(self, {VehicleID = CFG.baseVehicleID, InsID = McLarenFakeInsID}) end,
                function() return orig(self, McLarenFakeInsID) end,
                function() return orig(self) end,
            }
            for idx, fn in ipairs(tries) do
                local ok, err = pcall(fn)
                if ok then
                    print("[V26] _CreateVehicleModel OK with arg style #" .. idx)
                    return true
                end
            end
            return false
        end
    end) then p2[#p2+1] = "_CreateVehicleModel" end

    -- ═══ _TryCreateVehicleModel ═══
    if wrap(i, "_TryCreateVehicleModel", function(orig)
        return function(self, ...)
            local tries = {
                function() return orig(self, CFG.baseVehicleID) end,
                function() return orig(self, CFG.baseVehicleID, McLarenFakeInsID) end,
                function() return orig(self) end,
            }
            for _, fn in ipairs(tries) do
                if pcall(fn) then return true end
            end
            return false
        end
    end) then p2[#p2+1] = "_TryCreateVehicleModel" end

    -- ═══ PreviewGarageVehicle — force McLaren ═══
    if wrap(i, "PreviewGarageVehicle", function(orig)
        return function(self, vehicleID, ...)
            return orig(self, CFG.baseVehicleID, ...)
        end
    end) then p2[#p2+1] = "PreviewGarageVehicle" end

    -- ═══ OnVehicleChange — force McLaren ═══
    if wrap(i, "OnVehicleChange", function(orig)
        return function(self, vehicleID, ...)
            return orig(self, CFG.baseVehicleID, ...)
        end
    end) then p2[#p2+1] = "OnVehicleChange" end

    -- ═══ OnGarageVehicleChange — force McLaren ═══
    if wrap(i, "OnGarageVehicleChange", function(orig)
        return function(self, vehicleID, ...)
            return orig(self, CFG.baseVehicleID, ...)
        end
    end) then p2[#p2+1] = "OnGarageVehicleChange" end

    -- ═══ GetValidVehicleNum ═══
    if wrap(i, "GetValidVehicleNum", function(orig)
        return function(self, ...) return 999 end
    end) then p2[#p2+1] = "GetValidVehicleNum" end
end)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 4: FAKE OWNERSHIP via skin data
-- ═══════════════════════════════════════════════════════════════════
local p3 = {}
pcall(function()
    local DM = _G.DataMgr
    if not DM then return end
    
    -- Fake vehicle skin ownership
    if type(DM.vehicleSkinInsIDTable) == "table" then
        DM.vehicleSkinInsIDTable[961] = McLarenFakeInsID
        p3[#p3+1] = "vehicleSkinInsIDTable[961]"
    end
    
    -- Add McLaren to VehicleSlotList
    if type(DM.VehicleSlotList) == "table" then
        DM.VehicleSlotList[961] = DM.VehicleSlotList[961] or {}
        DM.VehicleSlotList[961][1] = McLarenFakeInsID
        p3[#p3+1] = "VehicleSlotList[961]"
    end
    
    -- Ensure defaultVehicleSkinResIDTable has McLaren
    if type(DM.defaultVehicleSkinResIDTable) == "table" then
        DM.defaultVehicleSkinResIDTable[961] = CFG.skinResID
        p3[#p3+1] = "defaultVehicleSkinResIDTable[961]"
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 5: PATCH OTHER MODULES — remove blocks
-- ═══════════════════════════════════════════════════════════════════
local p4 = {}
pcall(function()
    local M = require("client.logic.vehicle.LogicVehicleAccessory")
    local i = M and M.__inner_impl
    if i then
        if wrap(i, "CheckVehicleCanEquipAccessory", function(orig)
            return function(self, ...) return true end
        end) then p4[#p4+1] = "VAC:CanEquip" end
        
        if wrap(i, "CheckHasGetVehicle", function(orig)
            return function(self, ...) return true end
        end) then p4[#p4+1] = "VAC:HasGetVehicle" end
    end
end)

pcall(function()
    local M = require("client.logic.vehicle.LogicVehicleExtendedFeature")
    local i = M and M.__inner_impl
    if i then
        if wrap(i, "CheckVehicleSupportMultiSlot", function(orig)
            return function(self, ...) return true end
        end) then p4[#p4+1] = "VEF:SupportMultiSlot" end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 6: MANUAL TRIGGER — _G.V26_Spawn()
-- ═══════════════════════════════════════════════════════════════════
_G.V26_Spawn = function()
    local results = {}
    
    -- 1. Set vst_skin again
    pcall(function()
        local DM = _G.DataMgr
        if DM and DM.roleData then
            DM.roleData.vst_skin = McLarenFakeInsID
            results[#results+1] = "✓ vst_skin = " .. McLarenFakeInsID
        end
    end)
    
    -- 2. Trigger ThemeVehicleManager
    pcall(function()
        local M = require("client.logic.lobby.ThemeVehicleManager")
        local i = M and M.__inner_impl
        if not i then results[#results+1] = "✗ TVM not loaded" return end
        
        -- Try ShowThemeVehicle with McLaren base
        if type(i.ShowThemeVehicle) == "function" then
            local ok = pcall(i.ShowThemeVehicle, i, CFG.baseVehicleID)
            results[#results+1] = "ShowThemeVehicle(" .. CFG.baseVehicleID .. ") = " .. (ok and "OK" or "ERR")
        end
        
        -- Try _ShowSelfVehicle with multiple args
        if type(i._ShowSelfVehicle) == "function" then
            local ok = pcall(i._ShowSelfVehicle, i, CFG.baseVehicleID, McLarenFakeInsID)
            results[#results+1] = "_ShowSelfVehicle = " .. (ok and "OK" or "ERR")
        end
        
        -- Refresh effects
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
    S("v26_spawn.txt", txt)
    P("V26 SPAWN", txt)
    return txt
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 7: AUTO-SPAWN on lobby enter
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerLoop then
        ticker.AddTimerLoop(0, function()
            pcall(function()
                local inLobby = false
                if GameStatus and GameStatus.IsInLobbyOrMainCity then
                    inLobby = GameStatus.IsInLobbyOrMainCity()
                end
                if inLobby then
                    local DM = _G.DataMgr
                    if DM and DM.roleData and DM.roleData.vst_skin ~= McLarenFakeInsID then
                        DM.roleData.vst_skin = McLarenFakeInsID
                    end
                end
            end)
        end, -1, 5.0)
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 8: EVENT HOOK — lobby enter
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    if EventSystem and EventSystem.registEvent then
        if EVENTTYPE_LOBBY and EVENTID_SHOW_LOBBY then
            EventSystem:registEvent(EVENTTYPE_LOBBY, EVENTID_SHOW_LOBBY, function()
                pcall(function()
                    local t = require("common.time_ticker")
                    if t and t.AddTimerOnce then
                        t.AddTimerOnce(2.0, V26_Spawn)
                    end
                end)
            end)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- REPORT
-- ═══════════════════════════════════════════════════════════════════
local total = #p1 + #p2 + #p3 + #p4

S("v26_report.txt",
    "v26 McLAREN DROP REPORT\n" ..
    "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n" ..
    "Reverted: " .. reverted .. "\n" ..
    "Base Vehicle: " .. CFG.baseVehicleID .. " (Coupe RB)\n" ..
    "Skin: " .. CFG.skinResID .. " (McLaren Royal Black)\n" ..
    "Fake InsID: " .. McLarenFakeInsID .. "\n" ..
    "Patches:\n" ..
    "  VehicleCollectSystem: " .. #p1 .. "\n" ..
    "  ThemeVehicleManager: " .. #p2 .. "\n" ..
    "  DataMgr fake data: " .. #p3 .. "\n" ..
    "  Other modules: " .. #p4 .. "\n" ..
    "  TOTAL: " .. total .. "\n\n" ..
    "Commands:\n" ..
    "  V26_Spawn()  -- manual trigger McLaren drop\n"
)

-- Auto-trigger after 5 sec
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(5.0, function()
            V26_Spawn()
        end)
    end
end)

P("v26 LOADED",
    "McLaren Drop Setup\n\n" ..
    "Base: Coupe RB (961)\n" ..
    "Skin: 1961014\n" ..
    "Fake InsID: " .. McLarenFakeInsID .. "\n\n" ..
    "5 sec mein auto-spawn try hoga.\n" ..
    "Ya manually: V26_Spawn()")

return true
