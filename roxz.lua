-- ═══════════════════════════════════════════════════════════════════
-- PSLOT + CAR FIX v2 — Real Structure Based
-- ═══════════════════════════════════════════════════════════════════

_G.DX_Settings = _G.DX_Settings or {}
_G.DX_Settings.FixSlotsV2 = _G.DX_Settings.FixSlotsV2 ~= false
_G.DX_Settings.FixCarV2 = _G.DX_Settings.FixCarV2 ~= false

-- ─── REAL ITEM IDs (from your CDataTable[Item] + vehicle types) ───
-- Vehicle TYPES (base) — these are real, seen in VehicleSlotList
local VEHICLE_TYPES = {
    901, 902, 903, 904, 905, 906, 907, 908, 910, 911, 912, 913,
    915, 916, 917, 918, 919, 920, 930, 953, 960, 961, 963, 966,
    -- UAZ=904, Dacia=903, Buggy=905, Mirado=906, etc.
}

-- Vehicle SKIN resIDs (from defaultVehicleSkinResIDTable)
local VEHICLE_SKINS = {
    1901001, 1902001, 1903001, 1904001, 1905001, 1906001, 1907001,
    1908001, 1909001, 1910001, 1911001, 1912001, 1913001, 1914001,
    1915001, 1916001, 1917001, 1918001, 1919001, 1920001,
    1930001, 1953001, 1960001, 1961001, 1963001, 1966001, 1967001,
}

-- Weapon IDs — from Item table range, sample verified IDs
-- Base weapons in PUBGM: 101xxx (AR), 102xxx (SR), 103xxx (DMR),
-- 104xxx (LMG), 105xxx (SMG), 106xxx (SG), 107xxx (Pistol), 108xxx (Melee)
local WEAPONS = {
    -- AR
    101001, 101002, 101003, 101004, 101005, 101006, 101007, 101008,
    101009, 101010, 101011, 101012, 101013, 101014,
    -- SR
    103001, 103002, 103003, 103004, 103005, 103006, 103007,
    -- DMR
    103008, 103009, 103010, 103011, 103012, 103013,
    -- SMG
    102001, 102002, 102003, 102004, 102005, 102006, 102007,
    -- LMG
    104001, 104002, 104003,
    -- Shotgun
    105001, 105002, 105003, 105004, 105005,
    -- Pistol
    106001, 106002, 106003, 106004, 106005, 106006, 106007, 106008,
    -- Melee
    108001, 108002, 108003, 108004,
}

local PETS = {
    50000, 50003, 50004, 50005, 50006, 50007, 50008, 50009, 50010,
    50011, 50012, 50013, 50014, 50015, 50016, 50017, 50018, 50019,
    50020, 50021, 50022, 50023, 50024, 50025, 50026, 50027, 50028,
    50029, 50030, 50031, 50032, 50033, 50034, 50035, 50036, 50037,
    50038, 50039, 50040, 50041, 50042, 50043, 50044, 50045, 50046,
    50047, 50048,
}

local AVATARS = {
    10008, 10010, 10011, 20010, 20011, 20012, 20013, 20014, 20015,
    20016, 20017, 50002, 401985, 40601002,
}

-- ─── RANDOM PICKER ─────────────────────────────────────────────────
local function pick(pool, key)
    if not pool or #pool == 0 then return nil end
    local seed = (_G.DX_Settings.ProfileSlotSeed or os.time()) + (key or 0)
    return pool[(seed % #pool) + 1]
end

-- ─── FAKE SLOT DATA BUILDER ────────────────────────────────────────
local function makeSlot(slotType, index, itemID)
    return {
        slotType    = slotType,
        SlotType    = slotType,
        slotTypeID  = slotType,
        index       = index,
        Index       = index,
        slotIndex   = index,
        SlotIndex   = index,
        itemID      = itemID,
        itemId      = itemID,
        ItemID      = itemID,
        resID       = itemID,
        resId       = itemID,
        ResID       = itemID,
        skinID      = itemID,
        skinId      = itemID,
        SkinID      = itemID,
        isLock      = false,
        isUnlock    = true,
        isOwned     = true,
        expire_ts   = 0,
        expireTime  = 0,
        isPermanent = true,
    }
end

-- ─── WRAP HELPER ───────────────────────────────────────────────────
local PFX = "__pslotv2_"
local function wrapFn(tbl, name, wrapper)
    if not tbl or type(tbl[name]) ~= "function" then return false end
    if not tbl[PFX .. name] then
        tbl[PFX .. name] = tbl[name]
    end
    tbl[name] = wrapper(tbl[PFX .. name])
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- MAIN INSTALLER
-- ═══════════════════════════════════════════════════════════════════
_G.PSlotFixV2_Install = function()

    if _G._PSlotFixV2_Installed then return true end
    _G._PSlotFixV2_Installed = true

    local MyUID = nil
    pcall(function()
        if _G.DataMgr and _G.DataMgr.roleData then
            MyUID = tostring(_G.DataMgr.roleData.uid or "")
        end
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- 1) LOGIC_SOCIAL_LOBBY_MODULE — FIX _tOthersSocialDataMap
    -- ═══════════════════════════════════════════════════════════════
    pcall(function()
        local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
        if type(M) ~= "table" then return end
        local i = M.__inner_impl
        if type(i) ~= "table" then return end

        -- FIX 1a: Initialize the missing table
        if i._tOthersSocialDataMap == nil then
            i._tOthersSocialDataMap = {}
        end
        if i._tSocialDataGetTime == nil then
            i._tSocialDataGetTime = {}
        end
        if i._tSlotTypeMaxCountMap == nil then
            i._tSlotTypeMaxCountMap = {}
        end
        if i._tUCUnlockSlotMaxCount == nil then
            i._tUCUnlockSlotMaxCount = {}
        end
        if i._tWeaponSlotIndex == nil then
            i._tWeaponSlotIndex = { [1] = {}, [2] = {} }
        end

        -- FIX 1b: Set current UID if not set
        if type(i.SetCurUId) == "function" then
            pcall(i.SetCurUId, i, MyUID)
        end
        if type(i.GetCurUId) == "function" then
            local ok, cur = pcall(i.GetCurUId, i)
            if not ok or not cur then
                -- Patch GetCurUId to always return MyUID
                wrapFn(i, "GetCurUId", function()
                    return function() return MyUID end
                end)
            end
        end

        -- FIX 1c: GetSlotDataBySlotTypeAndIndex — safe wrapper
        wrapFn(i, "GetSlotDataBySlotTypeAndIndex", function(orig)
            return function(self, slotType, index, ...)
                -- Ensure table exists before call
                if self._tOthersSocialDataMap == nil then
                    self._tOthersSocialDataMap = {}
                end
                local ok, r = pcall(orig, self, slotType, index, ...)
                if ok and r and type(r) == "table" then
                    -- Check if has content
                    for _ in pairs(r) do return r end
                end
                -- Empty — return fake data
                local stLower = type(slotType) == "string" and slotType:lower() or ""
                local stNum = tonumber(slotType) or 0
                local itemID
                if stLower:find("weapon") or stLower:find("gun") or stNum == 1 then
                    itemID = pick(WEAPONS, index)
                elseif stLower:find("vehicle") or stLower:find("car") or stNum == 2 then
                    itemID = pick(VEHICLE_TYPES, index)
                elseif stLower:find("pet") or stNum == 3 then
                    itemID = pick(PETS, index)
                elseif stLower:find("avatar") or stLower:find("show") or stNum == 4 then
                    itemID = pick(AVATARS, index)
                elseif stLower:find("bg") or stLower:find("wall") or stNum == 5 then
                    itemID = pick(AVATARS, index)
                elseif stLower:find("achievement") or stNum == 6 then
                    itemID = pick(AVATARS, index)
                else
                    itemID = pick(WEAPONS, index)
                end
                return makeSlot(slotType, index, itemID)
            end
        end)

        -- FIX 1d: Slot max count
        wrapFn(i, "GetSlotTypeMaxCount", function(orig)
            return function(self, slotType, ...)
                local ok, r = pcall(orig, self, slotType, ...)
                if ok and type(r) == "number" and r > 0 then return r end
                return 6  -- 6 slots max
            end
        end)

        -- FIX 1e: Slot unlock — always true
        wrapFn(i, "GetSlotIsUnlockedByCollectHallLevel", function(orig)
            return function(self, slotType, index, ...)
                return true
            end
        end)

        -- FIX 1f: Equip functions — accept
        wrapFn(i, "PetSlotEquipClotheItemId", function() return function() return true end end)
        wrapFn(i, "BGWallSlotEquipItemId", function() return function() return true end end)
        wrapFn(i, "AvatarShowSlotEquipItemId", function() return function() return true end end)
        wrapFn(i, "AchievementSlotEquipItemId", function() return function() return true end end)

        -- FIX 1g: on_get_collect_hall_data_rsp — inject fake slot data
        wrapFn(i, "on_get_collect_hall_data_rsp", function(orig)
            return function(self, data, ...)
                if type(data) == "table" then
                    data.slotData = data.slotData or {}
                    data.allSlotData = data.allSlotData or {}
                    data.slots = data.slots or {}
                    -- Seed slot data
                    for idx = 1, 6 do
                        if not data.slotData[idx] then
                            data.slotData[idx] = makeSlot("Weapon", idx, pick(WEAPONS, idx))
                        end
                        if not data.slots[idx] then
                            data.slots[idx] = makeSlot("Weapon", idx, pick(WEAPONS, idx))
                        end
                    end
                end
                -- Ensure internal table
                if self._tOthersSocialDataMap == nil then
                    self._tOthersSocialDataMap = {}
                end
                local ok, err = pcall(orig, self, data, ...)
                return ok, err
            end
        end)

        print("[PSLOTV2] Logic_SocialLobbyModule fixed")
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- 2) LOGIC_SOCIAL_LOBBY_EDIT_MGR — allow edits (client-side)
    -- ═══════════════════════════════════════════════════════════════
    pcall(function()
        local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyEditMgrModule")
        if type(M) ~= "table" then return end
        local i = M.__inner_impl
        if type(i) ~= "table" then return end

        -- Init missing fields
        if i._bIsEditing == nil then i._bIsEditing = false end
        if i._bSaveFailAfterTriggeredReq == nil then i._bSaveFailAfterTriggeredReq = false end
        if i._bAchievementSlotDataIsLatest == nil then i._bAchievementSlotDataIsLatest = true end
        if i._bBgWallPicIsLatest == nil then i._bBgWallPicIsLatest = true end
        if i._bCollectionHallSlotIsLatest == nil then i._bCollectionHallSlotIsLatest = true end

        -- Save — no server, fake response
        wrapFn(i, "SaveEditedData", function(orig)
            return function(self, ...)
                if type(i.on_edit_all_collect_hall_rsp) == "function" then
                    pcall(i.on_edit_all_collect_hall_rsp, self, 0)
                end
                return true
            end
        end)

        wrapFn(i, "SaveEditData", function() return function() return true end end)
        wrapFn(i, "CheckBGWallSlotIfCanEquipItemId", function() return function() return true end end)
        wrapFn(i, "GetWhetherNeedToSave", function() return function() return false end end)
        wrapFn(i, "GetSaveFailAfterTriggeredReq", function() return function() return false end end)
        wrapFn(i, "CheckIsShowUnlockPopup", function() return function() return false end end)
        wrapFn(i, "ShowExistEditPopup", function() return function() end end)
        wrapFn(i, "ShowUnlockSlotPopup", function() return function() end end)

        print("[PSLOTV2] EditMgr fixed")
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- 3) THEME VEHICLE MANAGER — spawn car in lobby
    -- ═══════════════════════════════════════════════════════════════
    pcall(function()
        local M = require("client.logic.lobby.ThemeVehicleManager")
        if type(M) ~= "table" then return end
        local i = M.__inner_impl
        if type(i) ~= "table" then return end

        -- GetSelfVehicleIDs — inject our list
        wrapFn(i, "GetSelfVehicleIDs", function(orig)
            return function(self, ...)
                local ok, r = pcall(orig, self, ...)
                if ok and type(r) == "table" then
                    local n = 0; for _ in pairs(r) do n = n + 1 end
                    if n > 0 then return r end
                end
                -- Return our list
                return { 903, 904, 905, 906, 907 }  -- real vehicle types
            end
        end)

        -- CheckVehicleTypeHasUnlock — always true
        wrapFn(i, "CheckVehicleTypeHasUnlock", function()
            return function() return true end
        end)

        -- HasEnoughVehicleShowSpecial — true
        wrapFn(i, "HaveEnoughVehicleShowSpecial", function()
            return function() return true end
        end)

        -- NeedShowSpecialThemeEffect — true
        wrapFn(i, "NeedShowSpecialThemeEffect", function()
            return function() return true end
        end)

        print("[PSLOTV2] ThemeVehicleManager fixed")
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- 4) VEHICLE COLLECT SYSTEM — guard nil CollectCarInfo
    -- ═══════════════════════════════════════════════════════════════
    pcall(function()
        local M = require("client.logic.vehicle.VehicleCollectSystem")
        if type(M) ~= "table" then return end
        local i = M.__inner_impl
        if type(i) ~= "table" then return end

        -- Init missing
        if i.CollectCarInfo == nil then i.CollectCarInfo = {} end
        if i.EffectVehicleList == nil then i.EffectVehicleList = {} end
        if i.inherit_car_collection == nil then i.inherit_car_collection = {} end
        if i.car_collection == nil then i.car_collection = {} end

        wrapFn(i, "GetDefaultShowVehicle", function(orig)
            return function(self, ...)
                local ok, r = pcall(orig, self, ...)
                if ok and r then return r end
                return 903  -- Dacia default
            end
        end)

        print("[PSLOTV2] VehicleCollectSystem fixed")
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- 5) DIRECT CAR SPAWN — call ShowThemeVehicle with proper vehicle
    -- ═══════════════════════════════════════════════════════════════
    _G.SpawnLegendaryCarInLobby = function(vehicleID)
        vehicleID = vehicleID or 903  -- default Dacia
        local spawned = false
        pcall(function()
            local M = require("client.logic.lobby.ThemeVehicleManager")
            if type(M) ~= "table" then return end
            local i = M.__inner_impl
            if type(i) ~= "table" then return end

            -- Try ShowThemeVehicle
            if type(i.ShowThemeVehicle) == "function" then
                local ok, err = pcall(i.ShowThemeVehicle, i, vehicleID)
                if ok then spawned = true end
                print("[SPAWN] ShowThemeVehicle(" .. tostring(vehicleID) .. ") = " .. tostring(ok))
            end
        end)
        return spawned
    end

    -- ═══════════════════════════════════════════════════════════════
    -- 6) RESEED — call to reshuffle
    -- ═══════════════════════════════════════════════════════════════
    _G.ReseedSlots = function()
        _G.DX_Settings.ProfileSlotSeed = os.time() + math.random(1000, 99999)
        print("[PSLOTV2] Reseeded, seed=" .. tostring(_G.DX_Settings.ProfileSlotSeed))
    end

    print("[PSLOTV2] Install complete. MyUID=" .. tostring(MyUID))
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- AUTO-BOOT
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        for _, d in ipairs({ 2, 5, 10, 20, 40, 60 }) do
            ticker.AddTimerOnce(d, function()
                pcall(_G.PSlotFixV2_Install)
            end)
        end
    end
end)

return true
