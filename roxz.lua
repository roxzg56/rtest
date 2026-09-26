-- ═══════════════════════════════════════════════════════════════════
-- SLOT SAVE + SHOWROOM BYPASS v10
-- Path: /storage/emulated/0/Android/data/com.pubg.imobile/files/ ONLY
-- ═══════════════════════════════════════════════════════════════════

local DIR = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"

local function POPUP(t, m)
    pcall(function()
        local M = package.loaded["client.slua.logic.common.logic_common_msg_box"]
            or (pcall(require, "client.slua.logic.common.logic_common_msg_box")
                and require("client.slua.logic.common.logic_common_msg_box"))
        if M and M.Show then M.Show(1, tostring(t), tostring(m), function() end, function() end, "OK", "CLOSE") end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- PATH LOCKED — only this path
-- ═══════════════════════════════════════════════════════════════════
local function SAVE(name, content)
    local f = io.open(DIR .. name, "w")
    if not f then return false, DIR .. name end
    f:write(content or ""); f:close()
    return true, DIR .. name
end

-- ═══════════════════════════════════════════════════════════════════
-- WRAP HELPER
-- ═══════════════════════════════════════════════════════════════════
local PFX = "__slotv10_"
local function wrap(tbl, name, wrapper)
    if not tbl or type(tbl[name]) ~= "function" then return false end
    if not tbl[PFX .. name] then tbl[PFX .. name] = tbl[name] end
    tbl[name] = wrapper(tbl[PFX .. name])
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- MAIN INSTALL
-- ═══════════════════════════════════════════════════════════════════
_G.SlotFix10 = function()
    if _G._SlotFix10_Installed then return end
    _G._SlotFix10_Installed = true

    local MyUID = "0"
    pcall(function()
        if _G.DataMgr and _G.DataMgr.roleData then
            MyUID = tostring(_G.DataMgr.roleData.uid or "0")
        end
    end)

    local installed = {}

    -- ═══════════════════════════════════════════════════════════════
    -- 1) SOCIAL LOBBY MODULE — patch class __inner_impl
    -- ═══════════════════════════════════════════════════════════════
    pcall(function()
        local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
        if type(M) ~= "table" then return end
        local i = M.__inner_impl
        if type(i) ~= "table" then return end

        -- Init data tables
        i._tOthersSocialDataMap = i._tOthersSocialDataMap or {}
        i._tSocialDataGetTime = i._tSocialDataGetTime or {}
        i._tSlotTypeMaxCountMap = i._tSlotTypeMaxCountMap or {}
        i._tUCUnlockSlotMaxCount = i._tUCUnlockSlotMaxCount or {}

        -- ─── SHOWROOM LEVEL BYPASS ───
        -- Slot type max count → 6 always
        wrap(i, "GetSlotTypeMaxCount", function(orig)
            return function(self, slotType, ...)
                local ok, r = pcall(orig, self, slotType, ...)
                if ok and type(r) == "number" and r > 0 then return r end
                return 6
            end
        end)

        -- Collect hall level → 999 (bypass showroom level lock)
        wrap(i, "GetCollectHallLevel", function(orig)
            return function(self, ...)
                return 999
            end
        end)

        wrap(i, "GetCollectHallMaxLevel", function(orig)
            return function(self, ...)
                return 999
            end
        end)

        -- Slot unlocked → always true
        wrap(i, "GetSlotIsUnlockedByCollectHallLevel", function(orig)
            return function(self, slotType, index, ...)
                return true
            end
        end)

        wrap(i, "GetSlotIsUnlockBySlotTypeAndIndex", function(orig)
            return function(self, slotType, index, ...)
                return true
            end
        end)

        wrap(i, "GetSlotUnlockCountByCollectHallLevel", function(orig)
            return function(self, slotType, ...)
                return 6
            end
        end)

        wrap(i, "GetUnlockSlotByCollectHallMinLevel", function(orig)
            return function(self, ...)
                return 1
            end
        end)

        -- UC check → always unlocked
        wrap(i, "CheckSlotTypeIsUCUnlock", function(orig)
            return function(self, slotType, ...)
                return true
            end
        end)

        wrap(i, "GetSlotTypeUCUnlockMaxCount", function(orig)
            return function(self, slotType, ...)
                return 999
            end
        end)

        wrap(i, "GetSlotTypeUCUnlockedCount", function(orig)
            return function(self, slotType, ...)
                return 999
            end
        end)

        -- ─── SLOT DATA INJECT (fill empty slots) ───
        i._tOthersSocialDataMap = i._tOthersSocialDataMap or {}

        -- Build fake slot data
        local SLOT_TYPES = { 1, 2, 3, 4, 5, 6, 7, 8 }
        local ITEMS = {
            [1] = { 101001, 101002, 101003, 101004, 101005, 101006 },
            [2] = { 903, 904, 905, 906, 907, 908 },
            [3] = { 50008, 50009, 50010, 50017, 50018, 50033 },
            [4] = { 10008, 10010, 10011, 20010, 20011, 20012 },
            [5] = { 10008, 10010, 10011, 20010, 20011, 20012 },
            [6] = { 10008, 10010, 10011, 20010, 20011, 20012 },
            [7] = { 10008, 10010, 10011, 20010, 20011, 20012 },
            [8] = { 10008, 10010, 10011, 20010, 20011, 20012 },
        }

        local function mkSlot(st, idx, itemID)
            return {
                slotType = st, slotTypeID = st, type = st,
                index = idx, slotIndex = idx,
                itemID = itemID, itemId = itemID, ItemID = itemID,
                resID = itemID, resId = itemID,
                skinID = itemID, skinId = itemID,
                isLock = false, isUnlock = true, isOwned = true,
                expire_ts = 0, expireTime = 0, isPermanent = true,
            }
        end

        local byType = {}
        for _, st in ipairs(SLOT_TYPES) do
            byType[st] = {}
            local pool = ITEMS[st] or ITEMS[1]
            for idx = 1, 6 do
                byType[st][idx] = mkSlot(st, idx, pool[((idx-1) % #pool) + 1])
            end
        end

        local flat = {}
        for idx = 1, 20 do
            local st = SLOT_TYPES[((idx-1) % #SLOT_TYPES) + 1]
            local pool = ITEMS[st] or ITEMS[1]
            flat[idx] = mkSlot(st, idx, pool[((idx-1) % #pool) + 1])
        end

        local socialData = {
            uid = MyUID, UID = MyUID, playerUID = MyUID,
            slotData = byType, slots = flat, allSlotData = flat,
            collectHallLevel = 999,
        }

        for _, k in ipairs({ MyUID, "self", "me", "current", "_self", 0, 1, "" }) do
            i._tOthersSocialDataMap[k] = socialData
        end

        for _, st in ipairs(SLOT_TYPES) do
            i._tSlotTypeMaxCountMap[st] = 6
            i._tUCUnlockSlotMaxCount[st] = 0
        end

        -- ─── GETTER — return fake if empty ───
        wrap(i, "GetSlotDataBySlotTypeAndIndex", function(orig)
            return function(self, slotType, index, ...)
                if self._tOthersSocialDataMap == nil then
                    self._tOthersSocialDataMap = {}
                end
                local ok, r = pcall(orig, self, slotType, index, ...)
                if ok and r and type(r) == "table" then
                    for _ in pairs(r) do return r end
                end
                local stLower = type(slotType) == "string" and slotType:lower() or ""
                local stNum = tonumber(slotType) or 0
                local itemID
                if stLower:find("weapon") or stLower:find("gun") or stNum == 1 then
                    itemID = ITEMS[1][(index % 6) + 1]
                elseif stLower:find("vehicle") or stLower:find("car") or stNum == 2 then
                    itemID = ITEMS[2][(index % 6) + 1]
                elseif stLower:find("pet") or stNum == 3 then
                    itemID = ITEMS[3][(index % 6) + 1]
                else
                    itemID = ITEMS[4][(index % 6) + 1]
                end
                return mkSlot(slotType, index, itemID)
            end
        end)

        -- ─── SLOT EQUIP FUNCTIONS — accept any item ───
        wrap(i, "WeaponSlotEquipItemId", function(orig)
            return function(self, slotIndex, itemID, ...)
                -- Store in local data
                pcall(function()
                    if type(self._tLocalSlotData) ~= "table" then self._tLocalSlotData = {} end
                    self._tLocalSlotData["weapon_" .. slotIndex] = itemID
                end)
                return true
            end
        end)

        wrap(i, "VehicleSlotEquipItemId", function(orig)
            return function(self, slotIndex, itemID, ...)
                pcall(function()
                    if type(self._tLocalSlotData) ~= "table" then self._tLocalSlotData = {} end
                    self._tLocalSlotData["vehicle_" .. slotIndex] = itemID
                end)
                return true
            end
        end)

        wrap(i, "PetSlotEquipItemId", function(orig)
            return function(self, slotIndex, itemID, ...)
                pcall(function()
                    if type(self._tLocalSlotData) ~= "table" then self._tLocalSlotData = {} end
                    self._tLocalSlotData["pet_" .. slotIndex] = itemID
                end)
                return true
            end
        end)

        wrap(i, "PetSlotEquipClotheItemId", function(orig)
            return function(self, slotIndex, itemID, ...)
                return true
            end
        end)

        wrap(i, "BGWallSlotEquipItemId", function(orig)
            return function(self, slotIndex, itemID, ...)
                return true
            end
        end)

        wrap(i, "AvatarShowSlotEquipItemId", function(orig)
            return function(self, slotIndex, itemID, ...)
                return true
            end
        end)

        wrap(i, "AchievementSlotEquipItemId", function(orig)
            return function(self, slotIndex, itemID, ...)
                return true
            end
        end)

        -- Check functions → true
        wrap(i, "WeaponSlotCheckIsEquipItem", function() return function() return true end end)
        wrap(i, "PetSlotCheckIsEquipItem", function() return function() return true end end)
        wrap(i, "AvatarSlotCheckIsEquipItem", function() return function() return true end end)
        wrap(i, "BGWallSlotCheckIsEquipItem", function() return function() return true end end)

        wrap(i, "CheckSlotTypeIsUseItemId", function() return function() return true end end)
        wrap(i, "GetHaveAnySlotIsEquipped", function() return function() return true end end)
        wrap(i, "GetWeaponSlotIsShowBySlotIndex", function() return function() return true end end)

        -- ─── RSP HANDLERS — force success ───
        wrap(i, "on_get_collect_hall_data_rsp", function(orig)
            return function(self, data, ...)
                if type(data) == "table" then
                    data.slotData = data.slotData or byType
                    data.slots = data.slots or flat
                    data.allSlotData = data.allSlotData or flat
                    data.collectHallLevel = 999
                end
                local ok, err = pcall(orig, self, data, ...)
                return ok, err
            end
        end)

        wrap(i, "on_unlock_collect_hall_slot_rsp", function(orig)
            return function(self, res, ...)
                return orig(self, 0, ...)
            end
        end)

        wrap(i, "on_get_other_mixed_hall_data_rsp", function(orig)
            return function(self, data, ...)
                if type(data) == "table" then
                    data.slotData = data.slotData or byType
                    data.collectHallLevel = 999
                end
                return orig(self, data, ...)
            end
        end)

        installed[#installed+1] = "SocialLobbyModule"
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- 2) EDIT MGR — block server, fake success
    -- ═══════════════════════════════════════════════════════════════
    pcall(function()
        local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyEditMgrModule")
        if type(M) ~= "table" then return end
        local i = M.__inner_impl
        if type(i) ~= "table" then return end

        if i._bIsEditing == nil then i._bIsEditing = false end
        if i._bSaveFailAfterTriggeredReq == nil then i._bSaveFailAfterTriggeredReq = false end

        -- SAVE → client-side only, fake success
        wrap(i, "SaveEditedData", function(orig)
            return function(self, ...)
                -- Fire fake success rsp
                pcall(function()
                    if type(self.on_edit_all_collect_hall_rsp) == "function" then
                        self.on_edit_all_collect_hall_rsp(self, 0)
                    end
                end)
                POPUP("✓ SAVE OK", "Slots saved (client-side)")
                return true
            end
        end)

        wrap(i, "SaveEditData", function(orig)
            return function(self, ...)
                return true
            end
        end)

        -- All edit blockers → allow
        wrap(i, "CheckBGWallSlotIfCanEquipItemId", function() return function() return true end end)
        wrap(i, "GetWhetherNeedToSave", function() return function() return false end end)
        wrap(i, "GetSaveFailAfterTriggeredReq", function() return function() return false end end)
        wrap(i, "CheckIsShowUnlockPopup", function() return function() return false end end)
        wrap(i, "ShowExistEditPopup", function() return function() end end)
        wrap(i, "ShowUnlockSlotPopup", function() return function() end end)
        wrap(i, "CheckIsShowUnlockPopup", function() return function() return false end end)
        wrap(i, "SaveFailedAfterTriggeredReq", function() return function() return false end end)
        wrap(i, "ShowSaveFailedPopup", function() return function() end end)
        wrap(i, "ShowUnlockFailedPopup", function() return function() end end)

        installed[#installed+1] = "EditMgr"
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- 3) NETWORK HANDLER — block server sends
    -- ═══════════════════════════════════════════════════════════════
    pcall(function()
        local ok, H = pcall(require, "client.network.Protocol.SocialCardBGHandler")
        if ok and type(H) == "table" then
            for _, fn in ipairs({ "send_set_social_card_floor_req" }) do
                if type(H[fn]) == "function" then
                    H[fn] = function() return true end
                end
            end
        end

        -- Slot request handler
        local ok2, H2 = pcall(require, "client.network.Protocol.SocialLobbyHandler")
        if ok2 and type(H2) == "table" then
            for name, fn in pairs(H2) do
                if type(fn) == "function" and type(name) == "string" then
                    if name:find("send_") then
                        local rspName = name:gsub("^send_", "on_"):gsub("_req$", "_rsp")
                        H2[name] = function(...)
                            if type(H2[rspName]) == "function" then
                                pcall(H2[rspName], 0)
                            end
                            return true
                        end
                    elseif name:find("^on_") then
                        local orig = fn
                        H2[name] = function(...)
                            local args = {...}
                            if type(args[1]) == "number" and args[1] ~= 0 then args[1] = 0 end
                            return orig(table.unpack(args))
                        end
                    end
                end
            end
        end

        installed[#installed+1] = "NetworkHandlers"
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- 4) SHOWROOM LEVEL BYPASS — check other modules
    -- ═══════════════════════════════════════════════════════════════
    pcall(function()
        -- collect_hall / showroom related modules
        for _, path in ipairs({
            "GameLua.Mod.Lobby.Base.Collect.logic.collect_module",
            "client.slua.logic.CollectionHall.LogicCollectionHallEntry",
        }) do
            local ok, M = pcall(require, path)
            if ok and type(M) == "table" then
                local i = M.__inner_impl
                if type(i) == "table" then
                    for name, fn in pairs(i) do
                        if type(fn) == "function" and type(name) == "string" then
                            local lk = name:lower()
                            if lk:find("level") or lk:find("unlock") or lk:find("canuse") 
                               or lk:find("checklevel") or lk:find("hallenough") then
                                i[name] = function() return true end
                            end
                        end
                    end
                end
            end
        end

        installed[#installed+1] = "ShowroomBypass"
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- 5) VEHICLE LOBBY — force spawn
    -- ═══════════════════════════════════════════════════════════════
    pcall(function()
        local M = require("client.logic.lobby.ThemeVehicleManager")
        if type(M) ~= "table" then return end
        local i = M.__inner_impl
        if type(i) ~= "table" then return end

        if i.Vehicles == nil then i.Vehicles = {} end

        wrap(i, "GetSelfVehicleIDs", function(orig)
            return function(self, ...)
                local ok, r = pcall(orig, self, ...)
                if ok and type(r) == "table" and next(r) then return r end
                return { 903, 904, 905, 906 }
            end
        end)

        wrap(i, "CheckVehicleTypeHasUnlock", function() return function() return true end end)
        wrap(i, "HaveEnoughVehicleShowSpecial", function() return function() return true end end)
        wrap(i, "NeedShowSpecialThemeEffect", function() return function() return true end end)

        installed[#installed+1] = "ThemeVehicle"
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- WRITE REPORT
    -- ═══════════════════════════════════════════════════════════════
    local report = "SlotFix10 Report\n"
        .. "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"
        .. "MyUID: " .. MyUID .. "\n"
        .. "Installed: " .. table.concat(installed, ", ") .. "\n"
    local ok, path = SAVE("slotfix10_report.txt", report)

    POPUP("✓ FIX v10 INSTALLED",
        "Modules patched: " .. #installed .. "\n" ..
        table.concat(installed, "\n") .. "\n\n" ..
        "Report: " .. (ok and path or "SAVE FAIL"))

    print("[v10] Installed: " .. table.concat(installed, ", "))
end

-- ═══════════════════════════════════════════════════════════════════
-- CAR SPAWN — call separately
-- ═══════════════════════════════════════════════════════════════════
_G.CarSpawn = function(vehicleID)
    vehicleID = vehicleID or 903
    local M = require("client.logic.lobby.ThemeVehicleManager")
    local i = type(M) == "table" and M.__inner_impl or nil
    if type(i) ~= "table" then POPUP("CAR", "Not loaded") return end

    for _, fnName in ipairs({ "ShowThemeVehicle", "_ShowSelfVehicle", "_CreateVehicleModel",
                              "PreviewGarageVehicle", "OnVehicleChange" }) do
        if type(i[fnName]) == "function" then
            pcall(i[fnName], i, vehicleID)
        end
    end

    POPUP("CAR SPAWN", "ID: " .. vehicleID)
end

-- ═══════════════════════════════════════════════════════════════════
-- AUTO-BOOT
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        for _, d in ipairs({ 2, 5, 10, 20, 40, 60, 120 }) do
            ticker.AddTimerOnce(d, function()
                pcall(_G.SlotFix10)
            end)
        end
    end
end)

print("[v10] Loaded. Auto-boot active. Call SlotFix10() if needed.")

return true
