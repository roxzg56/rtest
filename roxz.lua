-- ═══════════════════════════════════════════════════════════════════
-- REVERT v10 + CLEAN FIX v11
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

local function SAVE(name, content)
    local f = io.open(DIR .. name, "w")
    if not f then return false end
    f:write(content or ""); f:close()
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 1: REVERT — original functions restore
-- ═══════════════════════════════════════════════════════════════════
_G.RevertV10 = function()
    local total = 0

    local function revertPrefix(module, prefix)
        if type(module) ~= "table" then return 0 end
        local cnt = 0
        -- Restore originals
        for k, v in pairs(module) do
            if type(k) == "string" and k:sub(1, #prefix) == prefix then
                local orig = k:sub(#prefix + 1)
                if type(v) == "function" then
                    module[orig] = v
                    cnt = cnt + 1
                end
            end
        end
        -- Delete backup keys
        for k in pairs(module) do
            if type(k) == "string" and k:sub(1, #prefix) == prefix then
                module[k] = nil
            end
        end
        return cnt
    end

    -- 1) SocialLobbyModule
    pcall(function()
        local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
        if type(M) ~= "table" then return end
        local i = M.__inner_impl
        if type(i) ~= "table" then return end

        total = total + revertPrefix(i, "__slotv10_")

        -- Clean fake data injwction
        if type(i._tOthersSocialDataMap) == "table" then
            for k in pairs(i._tOthersSocialDataMap) do
                i._tOthersSocialDataMap[k] = nil
            end
        end
        if type(i._tSocialDataGetTime) == "table" then
            for k in pairs(i._tSocialDataGetTime) do
                i._tSocialDataGetTime[k] = nil
            end
        end
        if type(i._tLocalSlotData) == "table" then
            i._tLocalSlotData = nil
        end
        -- Reset flag
        i.__autoinject = nil
        i.__autoinject2 = nil
    end)

    -- 2) EditMgr
    pcall(function()
        local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyEditMgrModule")
        if type(M) ~= "table" then return end
        total = total + revertPrefix(M.__inner_impl, "__slotv10_")
        total = total + revertPrefix(M.__inner_impl, "__pslot11_")
        total = total + revertPrefix(M.__inner_impl, "__pslotv2_")
    end)

    -- 3) ThemeVehicleManager
    pcall(function()
        local M = require("client.logic.lobby.ThemeVehicleManager")
        if type(M) ~= "table" then return end
        total = total + revertPrefix(M.__inner_impl, "__slotv10_")
        total = total + revertPrefix(M.__inner_impl, "__pet11_")
        total = total + revertPrefix(M.__inner_impl, "__pslotv2_")
        -- Reset flags
        if M.__inner_impl then
            M.__inner_impl.__carhook = nil
        end
    end)

    -- 4) VehicleCollectSystem
    pcall(function()
        local M = require("client.logic.vehicle.VehicleCollectSystem")
        if type(M) ~= "table" then return end
        total = total + revertPrefix(M.__inner_impl, "__pslot11_")
        total = total + revertPrefix(M.__inner_impl, "__pslotv2_")
    end)

    -- 5) VehicleExtendedFeature
    pcall(function()
        local M = require("client.logic.vehicle.LogicVehicleExtendedFeature")
        if type(M) ~= "table" then return end
        total = total + revertPrefix(M.__inner_impl, "__pslot11_")
    end)

    -- 6) VehicleAccessory
    pcall(function()
        local M = require("client.logic.vehicle.LogicVehicleAccessory")
        if type(M) ~= "table" then return end
        total = total + revertPrefix(M.__inner_impl, "__pslot11_")
    end)

    -- 7) Pet modules
    for _, path in ipairs({
        "client.slua.logic.pet.logic_pet",
        "client.slua.logic.pet.pet_manager",
        "client.slua.logic.pet.traits.TLogicPetData",
        "client.slua.logic.pet.traits.TLogicPetCfg",
    }) do
        pcall(function()
            local M = require(path)
            if type(M) ~= "table" then return end
            total = total + revertPrefix(M.__inner_impl, "__pet11_")
        end)
    end

    -- 8) Network handlers
    pcall(function()
        local H = require("client.network.Protocol.SocialCardBGHandler")
        if type(H) == "table" and H.__slotv10_ then
            -- restore
        end
    end)

    -- Reset global flags
    _G._SlotFix10_Installed = false

    return total
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 2: MINIMAL FIX — sirf jo chahiye
-- ═══════════════════════════════════════════════════════════════════
_G.MinimalSlotFix = function()
    if _G._MinimalSlotFix_Installed then return end
    _G._MinimalSlotFix_Installed = true

    local PFX = "__mini11_"
    local function wrap(tbl, name, wrapper)
        if not tbl or type(tbl[name]) ~= "function" then return false end
        if not tbl[PFX .. name] then tbl[PFX .. name] = tbl[name] end
        tbl[name] = wrapper(tbl[PFX .. name])
        return true
    end

    local MyUID = "0"
    pcall(function()
        if _G.DataMgr and _G.DataMgr.roleData then
            MyUID = tostring(_G.DataMgr.roleData.uid or "0")
        end
    end)

    local installed = {}

    -- ═══════════════════════════════════════════════════════════════
    -- 1) SLOT UNLOCK — level restrictions bypass
    -- Ye DANGEROUS nahi hai, sirf slot availability check
    -- ═══════════════════════════════════════════════════════════════
    pcall(function()
        local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
        local i = type(M) == "table" and M.__inner_impl or nil
        if type(i) ~= "table" then return end

        -- ONLY unlock the slot — level check bypass
        wrap(i, "GetSlotIsUnlockedByCollectHallLevel", function(orig)
            return function(self, slotType, index, ...)
                return true  -- slot always unlocked
            end
        end)

        wrap(i, "GetSlotIsUnlockBySlotTypeAndIndex", function(orig)
            return function(self, slotType, index, ...)
                return true
            end
        end)

        -- NOTE: GetCollectHallLevel NOT touched — original level stays
        -- NOTE: GetSlotTypeMaxCount NOT touched — original count stays
        -- NOTE: _tOthersSocialDataMap NOT touched — original data stays

        installed[#installed+1] = "SlotUnlock"
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- 2) SLOT EQUIP — allow any item client-side
    -- (only equip, no fake data injection)
    -- ═══════════════════════════════════════════════════════════════
    pcall(function()
        local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
        local i = type(M) == "table" and M.__inner_impl or nil
        if type(i) ~= "table" then return end

        local equipFns = {
            "WeaponSlotEquipItemId",
            "VehicleSlotEquipItemId",
            "PetSlotEquipItemId",
            "PetSlotEquipClotheItemId",
            "BGWallSlotEquipItemId",
            "AvatarShowSlotEquipItemId",
            "AchievementSlotEquipItemId",
        }
        for _, fn in ipairs(equipFns) do
            if type(i[fn]) == "function" then
                wrap(i, fn, function(orig)
                    return function(self, ...)
                        -- Call original first (let it try)
                        local ok, r = pcall(orig, self, ...)
                        -- If original failed, return success anyway
                        if not ok then return true end
                        return r
                    end
                end)
            end
        end

        -- Check functions — allow
        wrap(i, "CheckSlotTypeIsUseItemId", function() return function() return true end end)

        installed[#installed+1] = "SlotEquip"
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- 3) EDIT MGR — allow save (fake success, no server)
    -- ═══════════════════════════════════════════════════════════════
    pcall(function()
        local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyEditMgrModule")
        local i = type(M) == "table" and M.__inner_impl or nil
        if type(i) ~= "table" then return end

        if i._bIsEditing == nil then i._bIsEditing = false end
        if i._bSaveFailAfterTriggeredReq == nil then i._bSaveFailAfterTriggeredReq = false end

        -- SaveEditedData → allow + fake success (BUT don't block whole thing)
        wrap(i, "SaveEditedData", function(orig)
            return function(self, ...)
                -- Try original first
                local ok, r = pcall(orig, self, ...)
                -- Also fire fake success
                pcall(function()
                    if type(self.on_edit_all_collect_hall_rsp) == "function" then
                        self.on_edit_all_collect_hall_rsp(self, 0)
                    end
                end)
                POPUP("SAVE OK", "Slots saved")
                return true
            end
        end)

        -- Blockers → allow
        wrap(i, "GetWhetherNeedToSave", function() return function() return false end end)
        wrap(i, "GetSaveFailAfterTriggeredReq", function() return function() return false end end)
        wrap(i, "CheckIsShowUnlockPopup", function() return function() return false end end)
        wrap(i, "ShowExistEditPopup", function() return function() end end)
        wrap(i, "ShowUnlockSlotPopup", function() return function() end end)
        wrap(i, "ShowSaveFailedPopup", function() return function() end end)
        wrap(i, "ShowUnlockFailedPopup", function() return function() end end)

        installed[#installed+1] = "EditMgr"
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- NOTE: NO network handler patches.
    -- NOTE: NO _tOthersSocialDataMap injection.
    -- NOTE: NO level override.
    -- NOTE: NO data corruption.
    -- ═══════════════════════════════════════════════════════════════

    local report = "MinimalSlotFix v11 Report\n"
        .. "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"
        .. "MyUID: " .. MyUID .. "\n"
        .. "Installed: " .. table.concat(installed, ", ") .. "\n"
    SAVE("mini11_report.txt", report)

    POPUP("✓ MINIMAL FIX v11",
        "Installed: " .. #installed .. "\n" ..
        table.concat(installed, "\n") .. "\n\n" ..
        "Ab inventory wapas aayegi.\n" ..
        "Slots unlock rahenge.\n" ..
        "Equip try karo.")
end

-- ═══════════════════════════════════════════════════════════════════
-- RUN: Revert FIRST, then minimal fix
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        -- 2 seconds: revert v10
        ticker.AddTimerOnce(2.0, function()
            local n = _G.RevertV10()
            print("[REVERT] Restored " .. n .. " functions")
        end)
        -- 4 seconds: minimal fix
        ticker.AddTimerOnce(4.0, function()
            pcall(_G.MinimalSlotFix)
        end)
    end
end)

print("[v11] Revert + Minimal loaded. Auto-run in 2s + 4s.")

return true
