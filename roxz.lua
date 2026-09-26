-- ═══════════════════════════════════════════════════════════════════
-- SLOT FIX v12 — CLEAN, MINIMAL
-- Path: /storage/emulated/0/Android/data/com.pubg.imobile/files/
-- ═══════════════════════════════════════════════════════════════════

local DIR = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"

local function save(name, content)
    local f = io.open(DIR .. name, "w")
    if f then f:write(content or ""); f:close(); return true end
    return false
end

local function popup(t, m)
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

-- ═══ PROOF OF LIFE — happens immediately on file load ═══
save("v12_loaded.txt", "v12 loaded at " .. os.date("%Y-%m-%d %H:%M:%S"))
print("[V12] FILE PARSED OK — " .. os.date("%H:%M:%S"))

-- ═══ STEP 1: REVERT v11 ═══
local reverted = 0

pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    if M and M.__inner_impl then
        local i = M.__inner_impl
        local keys = {}
        for k in pairs(i) do
            if type(k) == "string" and k:sub(1, 9) == "__mini11_" then
                keys[#keys+1] = k
            end
        end
        for _, k in ipairs(keys) do
            local orig = k:sub(10)
            if type(i[k]) == "function" then
                i[orig] = i[k]
                reverted = reverted + 1
            end
            i[k] = nil
        end
    end
end)

pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyEditMgrModule")
    if M and M.__inner_impl then
        local i = M.__inner_impl
        local keys = {}
        for k in pairs(i) do
            if type(k) == "string" and k:sub(1, 9) == "__mini11_" then
                keys[#keys+1] = k
            end
        end
        for _, k in ipairs(keys) do
            local orig = k:sub(10)
            if type(i[k]) == "function" then
                i[orig] = i[k]
                reverted = reverted + 1
            end
            i[k] = nil
        end
    end
end)

print("[V12] Reverted v11: " .. reverted .. " functions")

-- ═══ STEP 2: APPLY CLEAN FIX ═══
local PFX = "__v12_"
local function wrap(tbl, name, wrapper)
    if not tbl or type(tbl[name]) ~= "function" then return false end
    if not tbl[PFX .. name] then tbl[PFX .. name] = tbl[name] end
    tbl[name] = wrapper(tbl[PFX .. name])
    return true
end

local fixed = 0

-- Slot unlock (this worked in v11, keep it)
pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    if M and M.__inner_impl then
        local i = M.__inner_impl
        if wrap(i, "GetSlotIsUnlockedByCollectHallLevel", function()
            return function(self, slotType, index, ...) return true end
        end) then fixed = fixed + 1 end
        if wrap(i, "GetSlotIsUnlockBySlotTypeAndIndex", function()
            return function(self, slotType, index, ...) return true end
        end) then fixed = fixed + 1 end
    end
end)

-- Slot equip (this worked too, keep it)
pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    if M and M.__inner_impl then
        local i = M.__inner_impl
        for _, fn in ipairs({
            "WeaponSlotEquipItemId", "VehicleSlotEquipItemId",
            "PetSlotEquipItemId", "PetSlotEquipClotheItemId",
            "BGWallSlotEquipItemId", "AvatarShowSlotEquipItemId",
            "AchievementSlotEquipItemId",
        }) do
            if type(i[fn]) == "function" then
                wrap(i, fn, function(orig)
                    return function(self, ...)
                        local ok = pcall(orig, self, ...)
                        return true
                    end
                end)
                fixed = fixed + 1
            end
        end
        if wrap(i, "CheckSlotTypeIsUseItemId", function()
            return function() return true end
        end) then fixed = fixed + 1 end
    end
end)

-- CRITICAL: Edit Mgr — DO NOT touch GetWhetherNeedToSave, SaveEditedData
-- ONLY force RSP success
pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyEditMgrModule")
    if M and M.__inner_impl then
        local i = M.__inner_impl
        
        -- Only RSP handlers — force err=0
        local rspHandlers = {
            "on_edit_all_collect_hall_rsp",
            "on_edit_honor_display_rsp",
            "on_set_collect_hall_background_rsp",
        }
        for _, fn in ipairs(rspHandlers) do
            if type(i[fn]) == "function" then
                wrap(i, fn, function(orig)
                    return function(self, err, ...)
                        local ok, r = pcall(orig, self, 0, ...)
                        return ok and r
                    end
                end)
                fixed = fixed + 1
            end
        end
    end
end)

-- Network handlers — force server accept
pcall(function()
    local paths = {
        "client.network.Protocol.SocialLobbyHandler",
        "client.network.Protocol.CollectHallHandler",
    }
    for _, path in ipairs(paths) do
        local ok, H = pcall(require, path)
        if ok and type(H) == "table" then
            for name, fn in pairs(H) do
                if type(fn) == "function" and type(name) == "string" and name:find("send_") then
                    local rspName = name:gsub("^send_", "on_"):gsub("_req$", "_rsp")
                    if type(H[rspName]) == "function" then
                        H[name] = function(...)
                            pcall(H[rspName], 0)
                            return true
                        end
                        fixed = fixed + 1
                    end
                end
            end
        end
    end
end)

-- Write report
save("v12_report.txt", 
    "SlotFix v12 Report\n" ..
    "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n" ..
    "Reverted: " .. reverted .. " functions\n" ..
    "Fixed: " .. fixed .. " functions\n"
)

print("[V12] Fixed: " .. fixed .. " functions")

-- ═══ POPUP — proof of success ═══
popup("V12 LOADED", 
    "Reverted v11: " .. reverted .. "\n" ..
    "Applied v12: " .. fixed .. "\n\n" ..
    "Ab test karo:\n" ..
    "1. Social lobby kholo\n" ..
    "2. Slot pe click\n" ..
    "3. Gun select\n" ..
    "4. Save button dekho")

return true
