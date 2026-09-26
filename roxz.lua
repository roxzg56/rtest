-- ═══════════════════════════════════════════════════════════════════
-- v23 — LOBBY CAR SPAWN (Client-Side Visual)
-- Path: /storage/emulated/0/Android/data/com.pubg.imobile/files/
-- Config: v23_car_config.txt
-- ═══════════════════════════════════════════════════════════════════

local DIR = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"
local CONFIG_FILE = "v23_car_config.txt"

local function S(name, content)
    local f = io.open(DIR .. name, "w")
    if not f then return false end
    f:write(content or ""); f:close()
    return true
end

local function R(name)
    local f = io.open(DIR .. name, "r")
    if not f then return nil end
    local c = f:read("*a"); f:close()
    return c
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
-- DEFAULT CONFIG — real vehicle IDs from DataMgr dump
-- ═══════════════════════════════════════════════════════════════════
local defaultConfig = [[
-- V23 CAR SPAWN CONFIG
-- Client-side only. Spawns car in lobby visually.
--
-- Available vehicle IDs (real from game):
--   901 = Vehicle 901 (bus/truck type)
--   902 = Vehicle 902
--   903 = Dacia          (most common)
--   904 = UAZ
--   905 = Buggy
--   906 = Mirado
--   907 = Coupe RB
--   908 = Zima (snow)
--   910 = Bike
--   911 = Mirado (variant)
--   912 = Vehicle 912
--   913 = Vehicle 913
--   915 = Vehicle 915
--   916 = Vehicle 916
--   917 = Vehicle 917
--   918 = Vehicle 918
--   919 = Vehicle 919
--   920 = Vehicle 920
--   930 = Motorcycle
--   953 = Vehicle 953
--   960 = Vehicle 960
--   961 = Vehicle 961
--   963 = Vehicle 963
--   966 = Vehicle 966
--   967 = Vehicle 967
--   968 = Vehicle 968
--   984, 985 = Special vehicles
--
-- Set below:
--   vehicleID  = base vehicle type (903 = Dacia)
--   skinID     = optional skin (0 = default)
--   autoSpawn  = true → auto spawn in lobby

return {
    vehicleID = 903,         -- Dacia default
    skinID    = 0,           -- 0 = use default skin
    autoSpawn = true,        -- spawn on lobby enter
    addLegendary = false,    -- set true to force legendary look
}
]]

if not R(CONFIG_FILE) then
    S(CONFIG_FILE, defaultConfig)
    print("[V23] Created default config: " .. DIR .. CONFIG_FILE)
end

-- Load config
local CFG = { vehicleID = 903, skinID = 0, autoSpawn = true, addLegendary = false }
pcall(function()
    local content = R(CONFIG_FILE)
    if content then
        local fn = load(content)
        if fn then
            local ok, data = pcall(fn)
            if ok and type(data) == "table" then
                for k, v in pairs(data) do CFG[k] = v end
            end
        end
    end
end)

S("v23_step0.txt", "v23 loaded at " .. os.date("%Y-%m-%d %H:%M:%S") .. 
    "\nvehicleID=" .. tostring(CFG.vehicleID) .. "\nskinID=" .. tostring(CFG.skinID))

-- ═══════════════════════════════════════════════════════════════════
-- REVERT EVERYTHING previous
-- ═══════════════════════════════════════════════════════════════════
local PREFIXES = {
    "__mini11_", "__v12_", "__v13_", "__v14_", "__v15_", "__v16_",
    "__v17_", "__v18_", "__v19_", "__v20_", "__v21_", "__v22_",
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

for _, path in ipairs({
    "client.slua.logic.pet.logic_pet",
    "client.slua.logic.pet.pet_manager",
    "client.slua.logic.pet.traits.TLogicPetData",
    "client.slua.logic.pet.traits.TLogicPetCfg",
    "client.slua.logic.pet.traits.TLogicPetNetUtil",
    "client.slua.logic.pet.logic_pet_privilege_guide",
    "client.slua.logic.pet.reddot_pet",
    "client.network.Protocol.PetHandler",
    "GameLua.Mod.Lobby.Base.Collect.logic.collect_pet_module",
    "client.slua.logic.lobby.Left.Logic_SocialLobbyModule",
    "client.slua.logic.lobby.Left.Logic_SocialLobbyEditMgrModule",
    "client.logic.lobby.ThemeVehicleManager",
    "client.logic.vehicle.VehicleCollectSystem",
    "client.logic.vehicle.LogicVehicleExtendedFeature",
    "client.logic.vehicle.LogicVehicleAccessory",
    "client.network.Protocol.SocialLobbyHandler",
    "client.network.Protocol.CollectHallHandler",
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

S("v23_step1.txt", "Reverted: " .. reverted)

-- ═══════════════════════════════════════════════════════════════════
-- WRAP HELPER
-- ═══════════════════════════════════════════════════════════════════
local PFX = "__v23_"
local function wrap(mod, name, wrapper)
    if not mod or type(mod[name]) ~= "function" then return false end
    if not mod[PFX .. name] then mod[PFX .. name] = mod[name] end
    mod[name] = wrapper(mod[PFX .. name])
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- REAL IDs (from dump)
-- ═══════════════════════════════════════════════════════════════════
-- defaultVehicleSkinResIDTable: type → default skin resID
local DEFAULT_SKIN = {
    [901] = 1901001, [902] = 1902001, [903] = 1903001, [904] = 1904001,
    [905] = 1905001, [906] = 1906001, [907] = 1907001, [908] = 1908001,
    [909] = 1909001, [910] = 1910001, [911] = 1911001, [912] = 1912001,
    [913] = 1913001, [914] = 1914001, [915] = 1915001, [916] = 1916001,
    [917] = 1917001, [918] = 1918001, [919] = 1919001, [920] = 1920001,
    [930] = 1930001, [953] = 1953001, [960] = 1960001, [961] = 1961001,
    [963] = 1963001, [966] = 1966001, [967] = 1967001,
    -- Legendary IDs (from upgradeVehicle + WOW)
    [1901001] = 1901001, [1902001] = 1902001,
    [1911001] = 1911001, [1913001] = 1913001, [1917001] = 1917001,
    [1961001] = 1961001, [1966001] = 1966001,
    -- WOW vehicles
    [1991014] = 1991014, [1991015] = 1991015,
    [1991016] = 1991016, [1991017] = 1991017,
}

-- Generate a valid 19-digit InsID
local function makeInsID(vehicleID, skinID)
    local base = 7656927787236720000
    return base + (vehicleID * 1000) + (skinID or 0)
end

-- Build fake vehicle data
local function makeVehicleData(vehicleID, skinID)
    local sid = skinID
    if not sid or sid == 0 then sid = DEFAULT_SKIN[vehicleID] or 1903001 end
    local insID = makeInsID(vehicleID, sid)
    return {
        VehicleID = vehicleID, vehicleID = vehicleID, vehicle_id = vehicleID,
        vID = vehicleID, id = vehicleID,
        SkinID = sid, skinID = sid, skin_id = sid,
        ResID = sid, resID = sid,
        InsID = insID, insID = insID, instanceID = insID,
        InstanceId = insID, InsId = insID,
        Level = 1, level = 1,
        isOwned = true, bIsOwned = true, IsOwned = true,
        isUnlock = true, unlocked = true,
        IsLocked = false, bIsLock = false,
        isPermanent = true, IsPermanent = true,
        expire_ts = 0, expireTime = 0,
    }
end

-- ═══════════════════════════════════════════════════════════════════
-- PATCH: THEME VEHICLE MANAGER
-- ═══════════════════════════════════════════════════════════════════
local p1 = {}
pcall(function()
    local M = require("client.logic.lobby.ThemeVehicleManager")
    local i = M and M.__inner_impl
    if not i then return end

    -- Force our vehicle ID in list
    if wrap(i, "GetSelfVehicleIDs", function(orig)
        return function(self, ...)
            local r = orig(self, ...)
            if type(r) ~= "table" then r = {} end
            -- Always include our config vehicle first
            if CFG.vehicleID and CFG.vehicleID > 0 then
                r[1] = CFG.vehicleID
            end
            return r
        end
    end) then p1[#p1+1] = "GetSelfVehicleIDs" end

    -- Force unlock check
    if wrap(i, "CheckVehicleTypeHasUnlock", function(orig)
        return function(self, ...) return true end
    end) then p1[#p1+1] = "CheckVehicleTypeHasUnlock" end

    -- Force special effects
    if wrap(i, "HaveEnoughVehicleShowSpecial", function(orig)
        return function(self, ...) return true end
    end) then p1[#p1+1] = "HaveEnoughVehicleShowSpecial" end

    if wrap(i, "NeedShowSpecialThemeEffect", function(orig)
        return function(self, ...) return true end
    end) then p1[#p1+1] = "NeedShowSpecialThemeEffect" end

    -- Show vehicle — force our config
    if wrap(i, "ShowThemeVehicle", function(orig)
        return function(self, vehicleID, ...)
            local targetID = CFG.vehicleID or vehicleID
            print("[V23] ShowThemeVehicle forced: " .. tostring(targetID))
            local ok, err = pcall(orig, self, targetID, ...)
            if not ok then
                print("[V23] ShowThemeVehicle err: " .. tostring(err):sub(1, 100))
            end
            return ok
        end
    end) then p1[#p1+1] = "ShowThemeVehicle" end

    -- _ShowSelfVehicle — force our config
    if wrap(i, "_ShowSelfVehicle", function(orig)
        return function(self, vehicleID, ...)
            local targetID = CFG.vehicleID or vehicleID
            print("[V23] _ShowSelfVehicle forced: " .. tostring(targetID))
            local ok, err = pcall(orig, self, targetID, ...)
            if not ok then
                print("[V23] _ShowSelfVehicle err: " .. tostring(err):sub(1, 100))
            end
            return ok
        end
    end) then p1[#p1+1] = "_ShowSelfVehicle" end

    -- _CreateVehicleModel — force our config
    if wrap(i, "_CreateVehicleModel", function(orig)
        return function(self, vehicleID, ...)
            local targetID = CFG.vehicleID or vehicleID
            print("[V23] _CreateVehicleModel forced: " .. tostring(targetID))
            local ok, err = pcall(orig, self, targetID, ...)
            if not ok then
                print("[V23] _CreateVehicleModel err: " .. tostring(err):sub(1, 100))
            end
            return ok
        end
    end) then p1[#p1+1] = "_CreateVehicleModel" end

    -- _TryCreateVehicleModel
    if wrap(i, "_TryCreateVehicleModel", function(orig)
        return function(self, vehicleID, ...)
            local targetID = CFG.vehicleID or vehicleID
            local ok = pcall(orig, self, targetID, ...)
            return ok
        end
    end) then p1[#p1+1] = "_TryCreateVehicleModel" end

    -- PreviewGarageVehicle
    if wrap(i, "PreviewGarageVehicle", function(orig)
        return function(self, vehicleID, ...)
            local targetID = CFG.vehicleID or vehicleID
            return orig(self, targetID, ...)
        end
    end) then p1[#p1+1] = "PreviewGarageVehicle" end

    -- OnVehicleChange
    if wrap(i, "OnVehicleChange", function(orig)
        return function(self, vehicleID, ...)
            local targetID = CFG.vehicleID or vehicleID
            return orig(self, targetID, ...)
        end
    end) then p1[#p1+1] = "OnVehicleChange" end

    -- OnGarageVehicleChange
    if wrap(i, "OnGarageVehicleChange", function(orig)
        return function(self, vehicleID, ...)
            local targetID = CFG.vehicleID or vehicleID
            return orig(self, targetID, ...)
        end
    end) then p1[#p1+1] = "OnGarageVehicleChange" end
end)

-- ═══════════════════════════════════════════════════════════════════
-- PATCH: VEHICLE COLLECT SYSTEM — for showcase slots
-- ═══════════════════════════════════════════════════════════════════
local p2 = {}
pcall(function()
    local M = require("client.logic.vehicle.VehicleCollectSystem")
    local i = M and M.__inner_impl
    if not i then return end

    if wrap(i, "GetDefaultShowVehicle", function(orig)
        return function(self, ...)
            return CFG.vehicleID or 903
        end
    end) then p2[#p2+1] = "GetDefaultShowVehicle" end

    if wrap(i, "GetPreviewVehicleList", function(orig)
        return function(self, ...)
            local r = orig(self, ...) or {}
            if type(r) ~= "table" then r = {} end
            table.insert(r, 1, CFG.vehicleID or 903)
            return r
        end
    end) then p2[#p2+1] = "GetPreviewVehicleList" end

    if wrap(i, "HasUnlockFeature", function(orig)
        return function(self, ...) return true end
    end) then p2[#p2+1] = "HasUnlockFeature" end

    if wrap(i, "HasUnlockFeature2", function(orig)
        return function(self, ...) return true end
    end) then p2[#p2+1] = "HasUnlockFeature2" end

    if wrap(i, "IsOpenHighTire", function(orig)
        return function(self, ...) return true end
    end) then p2[#p2+1] = "IsOpenHighTire" end
end)

-- ═══════════════════════════════════════════════════════════════════
-- PATCH: VEHICLE ACCESSORY — always allow
-- ═══════════════════════════════════════════════════════════════════
local p3 = {}
pcall(function()
    local M = require("client.logic.vehicle.LogicVehicleAccessory")
    local i = M and M.__inner_impl
    if not i then return end

    if wrap(i, "CheckVehicleCanEquipAccessory", function(orig)
        return function(self, ...) return true end
    end) then p3[#p3+1] = "CheckVehicleCanEquipAccessory" end

    if wrap(i, "CheckHasGetVehicle", function(orig)
        return function(self, ...) return true end
    end) then p3[#p3+1] = "CheckHasGetVehicle" end

    if wrap(i, "CheckHasGetAccessoryItem", function(orig)
        return function(self, ...) return true end
    end) then p3[#p3+1] = "CheckHasGetAccessoryItem" end

    if wrap(i, "CheckHasEnoughCost", function(orig)
        return function(self, ...) return true end
    end) then p3[#p3+1] = "CheckHasEnoughCost" end
end)

-- ═══════════════════════════════════════════════════════════════════
-- PATCH: VEHICLE EXTENDED FEATURE — all parts
-- ═══════════════════════════════════════════════════════════════════
local p4 = {}
pcall(function()
    local M = require("client.logic.vehicle.LogicVehicleExtendedFeature")
    local i = M and M.__inner_impl
    if not i then return end

    if wrap(i, "CheckVehicleSupportMultiSlot", function(orig)
        return function(self, ...) return true end
    end) then p4[#p4+1] = "CheckVehicleSupportMultiSlot" end

    if wrap(i, "CheckHasNewItemReddot", function(orig)
        return function(self, ...) return false end
    end) then p4[#p4+1] = "CheckHasNewItemReddot" end

    if wrap(i, "CheckHasNewItemReddot_AllType", function(orig)
        return function(self, ...) return false end
    end) then p4[#p4+1] = "CheckHasNewItemReddot_AllType" end
end)

-- ═══════════════════════════════════════════════════════════════════
-- MANUAL COMMANDS
-- ═══════════════════════════════════════════════════════════════════
_G.V23_SpawnCar = function(vehicleID, skinID)
    vehicleID = vehicleID or CFG.vehicleID or 903
    skinID = skinID or CFG.skinID or 0
    CFG.vehicleID = vehicleID
    CFG.skinID = skinID
    print("[V23] Manual spawn: vehicleID=" .. tostring(vehicleID) .. " skinID=" .. tostring(skinID))

    local results = {}
    pcall(function()
        local M = require("client.logic.lobby.ThemeVehicleManager")
        local i = M and M.__inner_impl
        if not i then results[#results+1] = "ThemeVehicleManager not loaded" return end

        -- Try every spawn method
        for _, fnName in ipairs({
            "ShowThemeVehicle", "_ShowSelfVehicle", "_CreateVehicleModel",
            "_TryCreateVehicleModel", "PreviewGarageVehicle",
            "OnVehicleChange", "OnGarageVehicleChange"
        }) do
            if type(i[fnName]) == "function" then
                local ok, err = pcall(i[fnName], i, vehicleID, skinID)
                results[#results+1] = fnName .. " = " .. (ok and "OK" or ("ERR " .. tostring(err):sub(1, 50)))
            end
        end

        -- Also try with table arg
        pcall(function()
            if type(i.ShowThemeVehicle) == "function" then
                i.ShowThemeVehicle(i, makeVehicleData(vehicleID, skinID))
            end
        end)
    end)

    P("V23 SPAWN", "vehicleID=" .. vehicleID .. "\n" .. table.concat(results, "\n"))
    return results
end

_G.V23_DestroyCar = function()
    pcall(function()
        local M = require("client.logic.lobby.ThemeVehicleManager")
        local i = M and M.__inner_impl
        if not i then return end
        if type(i.DestoryThemeVehicle) == "function" then i.DestoryThemeVehicle(i) end
        if type(i.DestroyAllThemeVehiclesOnly) == "function" then i.DestroyAllThemeVehiclesOnly(i) end
    end)
    P("V23", "Car destroyed")
end

_G.V23_ReloadConfig = function()
    pcall(function()
        local content = R(CONFIG_FILE)
        if content then
            local fn = load(content)
            if fn then
                local ok, data = pcall(fn)
                if ok and type(data) == "table" then
                    for k, v in pairs(data) do CFG[k] = v end
                end
            end
        end
    end)
    P("V23 CONFIG", "vehicleID=" .. tostring(CFG.vehicleID) .. "\nskinID=" .. tostring(CFG.skinID))
    V23_SpawnCar()
end

-- ═══════════════════════════════════════════════════════════════════
-- AUTO-SPAWN LOOP — every 10 sec re-apply if in lobby
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerLoop then
        ticker.AddTimerLoop(0, function()
            pcall(function()
                -- Check if in lobby
                local inLobby = false
                pcall(function()
                    if GameStatus and GameStatus.IsInLobbyOrMainCity then
                        inLobby = GameStatus.IsInLobbyOrMainCity()
                    end
                end)
                if inLobby and CFG.autoSpawn then
                    local M = require("client.logic.lobby.ThemeVehicleManager")
                    local i = M and M.__inner_impl
                    if i and type(i.RefreshSpecialEffect) == "function" then
                        pcall(i.RefreshSpecialEffect, i)
                    end
                end
            end)
        end, -1, 10.0)
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- FINAL
-- ═══════════════════════════════════════════════════════════════════
local total = #p1 + #p2 + #p3 + #p4

S("v23_report.txt",
    "v23 REPORT\n" ..
    "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n" ..
    "Reverted: " .. reverted .. "\n" ..
    "ThemeVehicleManager: " .. #p1 .. "\n" ..
    "VehicleCollectSystem: " .. #p2 .. "\n" ..
    "VehicleAccessory: " .. #p3 .. "\n" ..
    "VehicleExtendedFeature: " .. #p4 .. "\n" ..
    "TOTAL: " .. total .. "\n\n" ..
    "Config:\n" ..
    "  vehicleID = " .. tostring(CFG.vehicleID) .. "\n" ..
    "  skinID = " .. tostring(CFG.skinID) .. "\n" ..
    "  autoSpawn = " .. tostring(CFG.autoSpawn) .. "\n"
)

P("v23 LOADED",
    "Reverted: " .. reverted .. "\n" ..
    "Patched: " .. total .. "\n\n" ..
    "Config file:\nv23_car_config.txt\n\n" ..
    "Vehicle: " .. tostring(CFG.vehicleID) .. "\n\n" ..
    "Commands:\n" ..
    "V23_SpawnCar(903)\n" ..
    "V23_DestroyCar()\n" ..
    "V23_ReloadConfig()")

return true
