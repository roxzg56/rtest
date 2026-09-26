-- ═══════════════════════════════════════════════════════════════════════════
-- PROFILE DISPLAY SLOTS FILLER + LOBBY LEGENDARY CAR v1
-- Drop-in at END of any file. Auto-boots.
-- Client-side only. Blocks server sync.
-- ═══════════════════════════════════════════════════════════════════════════

_G.DX_Settings = _G.DX_Settings or {}
if _G.DX_Settings.FillProfileSlots == nil then _G.DX_Settings.FillProfileSlots = true end
if _G.DX_Settings.LobbyLegendaryCar == nil then _G.DX_Settings.LobbyLegendaryCar = true end
if _G.DX_Settings.ProfileSlotSeed == nil then _G.DX_Settings.ProfileSlotSeed = os.time() end

-- ─── ITEM POOLS ────────────────────────────────────────────────────
local WEAPON_POOL = {
    -- AR
    101001, 101002, 101003, 101004, 101005, 101006, 101007, 101008, 101009, 101010, 101011, 101012,
    -- SR
    102001, 102002, 102003, 102004, 102005,
    -- DMR
    103001, 103002, 103003, 103004, 103005, 103006, 103007, 103008,
    -- LMG
    104001, 104002, 104003, 104004,
    -- SMG
    105001, 105002, 105003, 105004, 105005, 105006, 105007,
    -- Shotgun
    106001, 106002, 106003, 106004, 106005, 106006,
    -- Pistol
    107001, 107002, 107003, 107004, 107005, 107006, 107007, 107008,
}

local VEHICLE_POOL = {
    903, 904, 905, 906, 907, 908, 909, 910, 911, 912, 913, 914, 915, 916, 917, 918, 919, 920,
    930, 953, 960, 961, 963, 966, 967,
    -- Legendary / special
    1901001, 1902001, 1903001, 1904001, 1911001, 1913001, 1917001, 1961001, 1966001,
}

local PET_POOL = {
    50000, 50003, 50004, 50005, 50006, 50007, 50008, 50009, 50010, 50011, 50012, 50013, 50014,
    50015, 50016, 50017, 50018, 50019, 50020, 50021, 50022, 50023, 50024, 50025, 50026, 50027,
    50028, 50029, 50030, 50031, 50032, 50033, 50034, 50035, 50036, 50037, 50038, 50039, 50040,
    50041, 50042, 50043, 50044, 50045, 50046, 50047, 50048,
}

local AVATAR_POOL = {
    10008, 10010, 10011, 20010, 20011, 20012, 20013, 20014, 20015, 20016, 20017, 50002,
    401985, 40601002,
}

-- Legendary car IDs — high-tier vehicles only
local LEGENDARY_CARS = {
    1901001, 1902001, 1903001, 1911001, 1913001, 1917001, 1961001, 1966001,
    1953001, 1961068, 1908119, 19116004,
}

-- ─── SEEDED RANDOM (deterministic per seed) ───────────────────────
local _slotCache = {}
local function pickRandom(pool, slotKey)
    if not pool or #pool == 0 then return nil end
    local cache = _slotCache[slotKey]
    if cache then return cache end
    local idx = ((_G.DX_Settings.ProfileSlotSeed + #slotKey) % #pool) + 1
    _slotCache[slotKey] = pool[idx]
    return pool[idx]
end

-- ─── FAKE SLOT DATA BUILDER ────────────────────────────────────────
local function makeSlotData(slotType, index, itemID)
    return {
        slotType    = slotType,
        SlotType    = slotType,
        index       = index,
        Index       = index,
        slotIndex   = index,
        SlotIndex   = index,
        itemID      = itemID,
        itemId      = itemID,
        ItemID      = itemID,
        resID       = itemID,
        ResID       = itemID,
        resId       = itemID,
        skinID      = itemID,
        SkinID      = itemID,
        isUnlocked  = true,
        bIsUnlocked = true,
        IsUnlocked  = true,
        isOwned     = true,
        bIsOwned    = true,
        expire_ts   = 0,
        ExpireTS    = 0,
        expire_time = 0,
        ExpireTime  = 0,
        isPermanent = true,
        IsPermanent = true,
        is_expired  = false,
    }
end

-- ─── WRAP HELPER ───────────────────────────────────────────────────
local PCU_PFX = "__pslot11_"
local function wrapFn(tbl, name, wrapper)
    if not tbl or type(tbl[name]) ~= "function" then return false end
    if not tbl[PCU_PFX .. name] then
        tbl[PCU_PFX .. name] = tbl[name]
    end
    tbl[name] = wrapper(tbl[PCU_PFX .. name])
    return true
end

-- ─── MAIN INSTALLER ────────────────────────────────────────────────
_G.NTHUY2004_InstallProfileSlotsAndLegendaryCar = function()

    if not (_G.DX_Settings and _G.DX_Settings.FillProfileSlots == true) then
        return false
    end
    if _G.NTHUY2004_ProfileSlotsVer and _G.NTHUY2004_ProfileSlotsVer >= 12 then
        return true
    end

    local installed = 0

    -- ═══════════════════════════════════════════════════════════════
    -- 1) LOGIC_SOCIAL_LOBBY_MODULE — main slot system
    -- ═══════════════════════════════════════════════════════════════
    pcall(function()
        local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
        if type(M) ~= "table" then return end
        local i = M.__inner_impl
        if type(i) ~= "table" then return end

        -- 1a) GetSlotDataBySlotTypeAndIndex → return fake random data
        wrapFn(i, "GetSlotDataBySlotTypeAndIndex", function(orig)
            return function(self, slotType, index, ...)
                local r = orig(self, slotType, index, ...)
                if r and type(r) == "table" and (r.itemID or r.ItemID or r.resID) then
                    -- Slot has data — return orig
                    return r
                end
                -- Empty slot — fill with random based on slotType
                local stLower = type(slotType) == "string" and slotType:lower() or ""
                local itemID
                if stLower:find("pet") then
                    itemID = pickRandom(PET_POOL, "pet_" .. tostring(index))
                elseif stLower:find("weapon") or stLower:find("gun") then
                    itemID = pickRandom(WEAPON_POOL, "gun_" .. tostring(index))
                elseif stLower:find("vehicle") or stLower:find("car") then
                    itemID = pickRandom(VEHICLE_POOL, "car_" .. tostring(index))
                elseif stLower:find("avatar") or stLower:find("show") or stLower:find("bg") then
                    itemID = pickRandom(AVATAR_POOL, "avatar_" .. tostring(index))
                else
                    -- Unknown type — random across pools
                    local mixed = (math.floor(_G.DX_Settings.ProfileSlotSeed + index) % 3)
                    if mixed == 0 then itemID = pickRandom(WEAPON_POOL, "mx_" .. tostring(index))
                    elseif mixed == 1 then itemID = pickRandom(VEHICLE_POOL, "mx_" .. tostring(index))
                    else itemID = pickRandom(PET_POOL, "mx_" .. tostring(index)) end
                end
                if itemID then
                    return makeSlotData(slotType, index, itemID)
                end
                return r
            end
        end)

        -- 1b) Slot unlock checks → always true
        wrapFn(i, "GetSlotIsUnlockedByCollectHallLevel", function(orig)
            return function(self, slotType, index, ...)
                return true
            end
        end)

        -- 1c) Max count → 999
        wrapFn(i, "GetSlotTypeMaxCount", function(orig)
            return function(self, slotType, ...)
                local r = orig(self, slotType, ...)
                if type(r) == "number" and r > 0 then return r end
                return 999
            end
        end)

        wrapFn(i, "GetSlotTypeUCUnlockMaxCount", function() return function() return 999 end end)
        wrapFn(i, "GetSlotTypeUCUnlockedCount",   function() return function() return 999 end end)
        wrapFn(i, "GetCollectHallLevel",          function() return function() return 999 end end)

        -- 1d) Pet slot clothe → always accept
        wrapFn(i, "PetSlotEquipClotheItemId", function(orig)
            return function(self, slotIndex, itemID, ...)
                return true
            end
        end)

        -- 1e) BG wall slot → always accept
        wrapFn(i, "BGWallSlotEquipItemId", function(orig)
            return function(self, slotIndex, itemID, ...)
                return true
            end
        end)

        -- 1f) Avatar show slot → always accept
        wrapFn(i, "AvatarShowSlotEquipItemId", function(orig)
            return function(self, slotIndex, itemID, ...)
                return true
            end
        end)

        -- 1g) Achievement slot → always accept
        wrapFn(i, "AchievementSlotEquipItemId", function(orig)
            return function(self, slotIndex, itemID, ...)
                return true
            end
        end)

        -- 1h) Spotlight → true
        wrapFn(i, "GetSpotlightIsShow", function() return function() return true end end)

        -- 1i) on_get_collect_hall_data_rsp → inject fake items into response
        wrapFn(i, "on_get_collect_hall_data_rsp", function(orig)
            return function(self, data, ...)
                -- Pre-fill slot data before orig parses
                if type(data) == "table" then
                    data.slotData = data.slotData or {}
                    data.allSlotData = data.allSlotData or {}
                    -- Seed with random picks
                    for idx = 1, 6 do
                        data.slotData[idx] = data.slotData[idx] or makeSlotData("weapon", idx,
                            pickRandom(WEAPON_POOL, "seed_" .. idx))
                    end
                end
                local ok, err = pcall(orig, self, data, ...)
                return ok, err
            end
        end)

        installed = installed + 1
        print("[PSLOT11] Logic_SocialLobbyModule patched")
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- 2) LOGIC_SOCIAL_LOBBY_EDIT_MGR — block server sync
    -- ═══════════════════════════════════════════════════════════════
    pcall(function()
        local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyEditMgrModule")
        if type(M) ~= "table" then return end
        local i = M.__inner_impl
        if type(i) ~= "table" then return end

        -- SaveEditedData → no-op (don't send to server)
        wrapFn(i, "SaveEditedData", function(orig)
            return function(self, ...)
                -- Local-only: fire fake rsp
                if i["on_edit_all_collect_hall_rsp"] then
                    pcall(i["on_edit_all_collect_hall_rsp"], self, 0)
                end
                return true
            end
        end)

        -- SaveEditData → collect locally only
        wrapFn(i, "SaveEditData", function(orig)
            return function(self, ...)
                return true
            end
        end)

        -- All edit-blockers → allow
        wrapFn(i, "CheckBGWallSlotIfCanEquipItemId", function() return function() return true end end)
        wrapFn(i, "GetWhetherNeedToSave", function() return function() return false end end)
        wrapFn(i, "GetSaveFailAfterTriggeredReq", function() return function() return false end end)
        wrapFn(i, "CheckIsShowUnlockPopup", function() return function() return false end end)
        wrapFn(i, "ShowExistEditPopup", function() return function() end end)
        wrapFn(i, "ShowUnlockSlotPopup", function() return function() end end)

        installed = installed + 1
        print("[PSLOT11] Logic_SocialLobbyEditMgrModule patched")
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- 3) THEME VEHICLE MANAGER — legendary car in lobby
    -- ═══════════════════════════════════════════════════════════════
    pcall(function()
        local M = require("client.logic.lobby.ThemeVehicleManager")
        if type(M) ~= "table" then return end
        local i = M.__inner_impl
        if type(i) ~= "table" then return end

        -- GetSelfVehicleIDs → override with legendary
        wrapFn(i, "GetSelfVehicleIDs", function(orig)
            return function(self, ...)
                local r = orig(self, ...)
                if not _G.DX_Settings.LobbyLegendaryCar then return r end
                local legend = LEGENDARY_CARS[
                    (math.floor(_G.DX_Settings.ProfileSlotSeed) % #LEGENDARY_CARS) + 1
                ]
                if r and type(r) == "table" then
                    r[1] = legend
                    return r
                end
                return { legend }
            end
        end)

        -- PreviewGarageVehicle → force legendary car preview
        wrapFn(i, "PreviewGarageVehicle", function(orig)
            return function(self, vehicleID, ...)
                if not _G.DX_Settings.LobbyLegendaryCar then
                    return orig(self, vehicleID, ...)
                end
                local legend = LEGENDARY_CARS[
                    (math.floor(_G.DX_Settings.ProfileSlotSeed) % #LEGENDARY_CARS) + 1
                ]
                return orig(self, legend, ...)
            end
        end)

        -- _ShowSelfVehicle → force legendary
        wrapFn(i, "_ShowSelfVehicle", function(orig)
            return function(self, ...)
                if not _G.DX_Settings.LobbyLegendaryCar then
                    return orig(self, ...)
                end
                local legend = LEGENDARY_CARS[
                    (math.floor(_G.DX_Settings.ProfileSlotSeed) % #LEGENDARY_CARS) + 1
                ]
                -- Try direct call with legendary
                local ok, err = pcall(orig, self, legend, ...)
                if not ok then
                    return orig(self, ...)
                end
                return ok
            end
        end)

        -- CheckVehicleTypeHasUnlock → always true
        wrapFn(i, "CheckVehicleTypeHasUnlock", function() return function() return true end end)

        installed = installed + 1
        print("[PSLOT11] ThemeVehicleManager patched")
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- 4) VEHICLE COLLECT SYSTEM — showcase with legendary
    -- ═══════════════════════════════════════════════════════════════
    pcall(function()
        local M = require("client.logic.vehicle.VehicleCollectSystem")
        if type(M) ~= "table" then return end
        local i = M.__inner_impl
        if type(i) ~= "table" then return end

        wrapFn(i, "GetDefaultShowVehicle", function(orig)
            return function(self, ...)
                if not _G.DX_Settings.LobbyLegendaryCar then
                    return orig(self, ...)
                end
                return LEGENDARY_CARS[
                    (math.floor(_G.DX_Settings.ProfileSlotSeed) % #LEGENDARY_CARS) + 1
                ]
            end
        end)

        wrapFn(i, "GetPreviewVehicleList", function(orig)
            return function(self, ...)
                local r = orig(self, ...)
                if not _G.DX_Settings.LobbyLegendaryCar then return r end
                if type(r) ~= "table" then r = {} end
                -- Prepend legendary
                local legend = LEGENDARY_CARS[
                    (math.floor(_G.DX_Settings.ProfileSlotSeed) % #LEGENDARY_CARS) + 1
                ]
                table.insert(r, 1, legend)
                return r
            end
        end)

        wrapFn(i, "HasUnlockFeature", function() return function() return true end end)
        wrapFn(i, "HasUnlockFeature2", function() return function() return true end end)
        wrapFn(i, "IsOpenHighTire", function() return function() return true end end)

        installed = installed + 1
        print("[PSLOT11] VehicleCollectSystem patched")
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- 5) VEHICLE EXTENDED FEATURE — chassis light, wheel hub etc.
    -- ═══════════════════════════════════════════════════════════════
    pcall(function()
        local M = require("client.logic.vehicle.LogicVehicleExtendedFeature")
        if type(M) ~= "table" then return end
        local i = M.__inner_impl
        if type(i) ~= "table" then return end

        wrapFn(i, "CheckVehicleSupportMultiSlot", function() return function() return true end end)
        wrapFn(i, "CheckIsFeatureItemHasReddot", function() return function() return false end end)
        wrapFn(i, "CheckHasNewItemReddot", function() return function() return false end end)
        wrapFn(i, "CheckHasNewItemReddot_AllType", function() return function() return false end end)

        installed = installed + 1
        print("[PSLOT11] LogicVehicleExtendedFeature patched")
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- 6) VEHICLE ACCESSORY — accessories always available
    -- ═══════════════════════════════════════════════════════════════
    pcall(function()
        local M = require("client.logic.vehicle.LogicVehicleAccessory")
        if type(M) ~= "table" then return end
        local i = M.__inner_impl
        if type(i) ~= "table" then return end

        wrapFn(i, "CheckVehicleCanEquipAccessory", function() return function() return true end end)
        wrapFn(i, "CheckHasGetVehicle", function() return function() return true end end)
        wrapFn(i, "CheckHasGetAccessoryItem", function() return function() return true end end)
        wrapFn(i, "CheckIsEquipAccessoryItem", function() return function() return true end end)
        wrapFn(i, "CheckHasEnoughCost", function() return function() return true end end)

        -- Auto-equip accessory on any vehicle
        wrapFn(i, "OnGetCarInfoRsp", function(orig)
            return function(self, ...)
                local ok, err = pcall(orig, self, ...)
                return ok, err
            end
        end)

        installed = installed + 1
        print("[PSLOT11] LogicVehicleAccessory patched")
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- 7) RESEED COMMAND — call NTHUY2004_ReseedProfileSlots() to shuffle
    -- ═══════════════════════════════════════════════════════════════
    _G.NTHUY2004_ReseedProfileSlots = function()
        _G.DX_Settings.ProfileSlotSeed = os.time() + math.random(1000, 99999)
        _slotCache = {}
        print("[PSLOT11] Reseeded with seed=" .. tostring(_G.DX_Settings.ProfileSlotSeed))
    end

    _G.NTHUY2004_ProfileSlotsVer = 12
    _G.NTHUY2004_ProfileSlotsInstalled = true

    print("[PSLOT11] Installed — sections: " .. installed)
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- AUTO-BOOT
-- ═══════════════════════════════════════════════════════════════════════════
pcall(function()
    local ok, ticker = pcall(require, "common.time_ticker")
    local function boot()
        if not (_G.DX_Settings and _G.DX_Settings.FillProfileSlots == true) then
            return
        end
        pcall(_G.NTHUY2004_InstallProfileSlotsAndLegendaryCar)
    end

    if ok and ticker and ticker.AddTimerOnce then
        for _, d in ipairs({ 1, 3, 8, 15, 25, 40, 60 }) do
            ticker.AddTimerOnce(d, boot)
        end
    else
        boot()
    end
end)

return true
