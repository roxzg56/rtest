-- ═══════════════════════════════════════════════════════════════════
-- SLOT SAVE FIX v12 — Real save/edit state handling
-- Path: /storage/emulated/0/Android/data/com.pubg.imobile/files/
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
-- STEP 1: REVERT v11 wrong patches
-- ═══════════════════════════════════════════════════════════════════
_G.RevertV11 = function()
    local total = 0
    local PFX = "__mini11_"

    local function revert(module)
        if type(module) ~= "table" then return 0 end
        local cnt = 0
        for k, v in pairs(module) do
            if type(k) == "string" and k:sub(1, #PFX) == PFX then
                local orig = k:sub(#PFX + 1)
                if type(v) == "function" then
                    module[orig] = v
                    cnt = cnt + 1
                end
            end
        end
        for k in pairs(module) do
            if type(k) == "string" and k:sub(1, #PFX) == PFX then
                module[k] = nil
            end
        end
        return cnt
    end

    pcall(function()
        local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
        total = total + revert(M and M.__inner_impl)
    end)
    pcall(function()
        local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyEditMgrModule")
        total = total + revert(M and M.__inner_impl)
    end)

    _G._MinimalSlotFix_Installed = false
    return total
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 2: CORRECT FIX — only RSP handlers
-- ═══════════════════════════════════════════════════════════════════
_G.SlotSaveFixV12 = function()
    if _G._SlotSaveFixV12_Installed then return end
    _G._SlotSaveFixV12_Installed = true

    local PFX = "__v12_"
    local function wrap(tbl, name, wrapper)
        if not tbl or type(tbl[name]) ~= "function" then return false end
        if not tbl[PFX .. name] then tbl[PFX .. name] = tbl[name] end
        tbl[name] = wrapper(tbl[PFX .. name])
        return true
    end

    local installed = {}

    -- ═══════════════════════════════════════════════════════════════
    -- 1) SLOT UNLOCK — keep from v11 (this worked, don't touch)
    -- ═══════════════════════════════════════════════════════════════
    pcall(function()
        local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
        local i = type(M) == "table" and M.__inner_impl or nil
        if type(i) ~= "table" then return end

        wrap(i, "GetSlotIsUnlockedByCollectHallLevel", function()
            return function(self, slotType, index, ...) return true end
        end)
        wrap(i, "GetSlotIsUnlockBySlotTypeAndIndex", function()
            return function(self, slotType, index, ...) return true end
        end)

        installed[#installed+1] = "SlotUnlock"
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- 2) SLOT EQUIP — allow client-side equip (keep from v11)
    -- ═══════════════════════════════════════════════════════════════
    pcall(function()
        local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
        local i = type(M) == "table" and M.__inner_impl or nil
        if type(i) ~= "table" then return end

        local equipFns = {
            "WeaponSlotEquipItemId", "VehicleSlotEquipItemId",
            "PetSlotEquipItemId", "PetSlotEquipClotheItemId",
            "BGWallSlotEquipItemId", "AvatarShowSlotEquipItemId",
            "AchievementSlotEquipItemId",
        }
        for _, fn in ipairs(equipFns) do
            if type(i[fn]) == "function" then
                wrap(i, fn, function(orig)
                    return function(self, ...)
                        local ok, r = pcall(orig, self, ...)
                        if not ok then
                            -- FAIL — still try to write to local slot data
                            pcall(function()
                                if not self._tV12LocalEdits then self._tV12LocalEdits = {} end
                                self._tV12LocalEdits[fn] = {...}
                            end)
                            return true
                        end
                        return r
                    end
                end)
            end
        end

        wrap(i, "CheckSlotTypeIsUseItemId", function()
            return function() return true end
        end)

        installed[#installed+1] = "SlotEquip"
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- 3) EDIT MGR — DON'T touch state trackers!
    --    Only patch RSP handlers to force success
    -- ═══════════════════════════════════════════════════════════════
    pcall(function()
        local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyEditMgrModule")
        local i = type(M) == "table" and M.__inner_impl or nil
        if type(i) ~= "table" then return end

        -- CRITICAL: Do NOT touch these:
        --   ❌ GetWhetherNeedToSave (breaks "already saved" state)
        --   ❌ SaveEditedData (breaks edit flow)
        --   ❌ SaveEditData
        --   ❌ EnterEditState / QuitEditState
        --   ❌ ShowExistEditPopup / ShowUnlockSlotPopup
        --
        -- ONLY touch RSP handlers — force success after server rejects

        if type(i.on_edit_all_collect_hall_rsp) == "function" then
            wrap(i, "on_edit_all_collect_hall_rsp", function(orig)
                return function(self, err, ...)
                    -- Force err = 0 (success)
                    local ok, r = pcall(orig, self, 0, ...)
                    if ok then
                        -- Also try to update the LOCAL slot data with what we edited
                        pcall(function()
                            if type(self.SaveEditedData) == "function" then
                                -- Don't call SaveEditedData again — it would re-send
                                -- Instead, manually apply local edits if we cached them
                                if self._tV12PendingEdits then
                                    for k, v in pairs(self._tV12PendingEdits) do
                                        self[k] = v
                                    end
                                    self._tV12PendingEdits = nil
                                end
                            end
                        end)
                    end
                    return ok and r or true
                end
            end)
        end

        if type(i.on_edit_honor_display_rsp) == "function" then
            wrap(i, "on_edit_honor_display_rsp", function(orig)
                return function(self, err, ...)
                    return orig(self, 0, ...)
                end
            end)
        end

        if type(i.on_set_collect_hall_background_rsp) == "function" then
            wrap(i, "on_set_collect_hall_background_rsp", function(orig)
                return function(self, err, ...)
                    return orig(self, 0, ...)
                end
            end)
        end

        -- Init state properly
        if i._bIsEditing == nil then i._bIsEditing = false end
        if i._bSaveFailAfterTriggeredReq == nil then i._bSaveFailAfterTriggeredReq = false end

        installed[#installed+1] = "EditMgr_RSP_only"
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- 4) NETWORK — force success on slot save sends
    --    Ye zaroori hai — server "not owned" reject karta hai
    -- ═══════════════════════════════════════════════════════════════
    pcall(function()
        local paths = {
            "client.network.Protocol.SocialLobbyHandler",
            "client.network.Protocol.CollectHallHandler",
            "client.network.Protocol.RoleInfoHandler",
        }
        for _, path in ipairs(paths) do
            local ok, H = pcall(require, path)
            if ok and type(H) == "table" then
                for name, fn in pairs(H) do
                    if type(fn) == "function" and type(name) == "string" then
                        -- Only slot-related send functions
                        if name:find("send_") and (name:find("slot") or name:find("edit") 
                           or name:find("collect_hall") or name:find("save")) then
                            local rspName = name:gsub("^send_", "on_"):gsub("_req$", "_rsp")
                            H[name] = function(...)
                                -- Call fake rsp
                                if type(H[rspName]) == "function" then
                                    pcall(H[rspName], 0)
                                end
                                return true
                            end
                        end
                    end
                end
            end
        end

        installed[#installed+1] = "NetworkRsp"
    end)

    -- Report
    local report = "SlotSaveFixV12 Report\n"
        .. "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"
        .. "Installed: " .. table.concat(installed, ", ") .. "\n"
    SAVE("v12_report.txt", report)

    POPUP("✓ FIX v12",
        "Installed: " .. #installed .. "\n" ..
        table.concat(installed, "\n") .. "\n\n" ..
        "Ab test karo:\n" ..
        "1. Slot pe click\n" ..
        "2. Gun select\n" ..
        "3. Save button dikhega\n" ..
        "4. Cross button kaam karega")
end

-- ═══════════════════════════════════════════════════════════════════
-- AUTO-RUN: revert v11 first, then v12
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(2.0, function()
            local n = _G.RevertV11()
            print("[V12] Reverted v11: " .. n .. " functions")
        end)
        ticker.AddTimerOnce(4.0, function()
            pcall(_G.SlotSaveFixV12)
        end)
    end
end)

print("[v12] Loaded. Revert + Fix auto-run in 2s + 4s.")

return true
