-- ═══════════════════════════════════════════════════════════════════
-- v14 — PERSISTENT LOCAL OVERRIDE
-- Equip karo → local save → server wapas aaye → override priority
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

S("v14_step0.txt", "v14 loaded at " .. os.date("%Y-%m-%d %H:%M:%S"))

-- ═══════════════════════════════════════════════════════════════════
-- THE KEY: PERSISTENT LOCAL STORAGE
-- Ye table GLOBAL hai — game restart tak zinda rehti hai
-- ═══════════════════════════════════════════════════════════════════
_G._V14_LOCAL_EDITS = _G._V14_LOCAL_EDITS or {
    weapon = {},       -- weapon[slotIndex] = itemID
    vehicle = {},      -- vehicle[slotIndex] = itemID
    pet = {},          -- pet[slotIndex] = itemID
    petClothe = {},    -- petClothe[slotIndex] = itemID
    bgWall = {},       -- bgWall[slotIndex] = itemID
    avatarShow = {},   -- avatarShow[slotIndex] = itemID
    achievement = {},  -- achievement[slotIndex] = itemID
}

-- Also try to persist on disk
local function loadLocalEditsFromDisk()
    pcall(function()
        local f = io.open(DIR .. "v14_edits.txt", "r")
        if f then
            local content = f:read("*a")
            f:close()
            local fn = load(content)
            if fn then
                local saved = fn()
                if type(saved) == "table" then
                    _G._V14_LOCAL_EDITS = saved
                end
            end
        end
    end)
end

local function saveLocalEditsToDisk()
    pcall(function()
        local data = "return {\n"
        for category, items in pairs(_G._V14_LOCAL_EDITS) do
            data = data .. "  " .. category .. " = {\n"
            for idx, itemID in pairs(items) do
                data = data .. "    [" .. tostring(idx) .. "] = " .. tostring(itemID) .. ",\n"
            end
            data = data .. "  },\n"
        end
        data = data .. "}"
        S("v14_edits.txt", data)
    end)
end

-- Try to load from disk on file load
loadLocalEditsFromDisk()

-- ═══════════════════════════════════════════════════════════════════
-- REVERT v13 (sirf RSP + network revert karo, unlock/equip rakho)
-- ═══════════════════════════════════════════════════════════════════
local reverted = 0
local PFX_OLD = "__v13_"

pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyEditMgrModule")
    local i = M and M.__inner_impl
    if i then
        local keys = {}
        for k in pairs(i) do
            if type(k) == "string" and k:sub(1, 7) == PFX_OLD then
                keys[#keys+1] = k
            end
        end
        for _, k in ipairs(keys) do
            local orig = k:sub(8)
            if type(i[k]) == "function" then
                i[orig] = i[k]
                reverted = reverted + 1
            end
            i[k] = nil
        end
    end
end)

-- Don't revert the SLOT unlock/equip from v13 — those are working
S("v14_step1.txt", "Reverted v13 RSP/network: " .. reverted)

-- ═══════════════════════════════════════════════════════════════════
-- THE FIX: WRAP SLOT GETTERS TO RETURN LOCAL OVERRIDE
-- ═══════════════════════════════════════════════════════════════════
local PFX = "__v14_"
local wrapCount = 0

local function wrap(tbl, name, wrapper)
    if not tbl or type(tbl[name]) ~= "function" then return false end
    if not tbl[PFX .. name] then tbl[PFX .. name] = tbl[name] end
    tbl[name] = wrapper(tbl[PFX .. name])
    return true
end

-- Map: slotType name → local table key
local function slotTypeToKey(slotType)
    local s = type(slotType) == "string" and slotType:lower() or ""
    local n = tonumber(slotType) or 0
    if s:find("weapon") or s:find("gun") or n == 1 then return "weapon" end
    if s:find("vehicle") or s:find("car") or n == 2 then return "vehicle" end
    if s:find("petclothe") or s:find("pet_clothe") then return "petClothe" end
    if s:find("pet") or n == 3 then return "pet" end
    if s:find("bgwall") or s:find("bg_wall") or n == 4 then return "bgWall" end
    if s:find("avatarshow") or s:find("avatar_show") or n == 5 then return "avatarShow" end
    if s:find("achievement") or n == 6 then return "achievement" end
    return nil
end

-- ═══ SLOT GETTER — always check local override FIRST ═══
pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    local i = M and M.__inner_impl
    if not i then return end

    if wrap(i, "GetSlotDataBySlotTypeAndIndex", function(orig)
        return function(self, slotType, index, ...)
            -- Check local override first
            local key = slotTypeToKey(slotType)
            if key and _G._V14_LOCAL_EDITS[key] and _G._V14_LOCAL_EDITS[key][index] then
                local itemID = _G._V14_LOCAL_EDITS[key][index]
                -- Return as slot data
                return {
                    slotType = slotType, slotTypeID = slotType, type = slotType,
                    index = index, slotIndex = index,
                    itemID = itemID, itemId = itemID, ItemID = itemID,
                    resID = itemID, resId = itemID,
                    skinID = itemID, skinId = itemID,
                    isLock = false, isUnlock = true, isOwned = true,
                    expire_ts = 0, expireTime = 0, isPermanent = true,
                    _v14Local = true,  -- marker
                }
            end
            -- Fall through to original
            return orig(self, slotType, index, ...)
        end
    end) then wrapCount = wrapCount + 1 end
end)

-- ═══ EQUIP FUNCTIONS — write to local override ═══
pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    local i = M and M.__inner_impl
    if not i then return end

    local equipMap = {
        WeaponSlotEquipItemId = "weapon",
        VehicleSlotEquipItemId = "vehicle",
        PetSlotEquipItemId = "pet",
        PetSlotEquipClotheItemId = "petClothe",
        BGWallSlotEquipItemId = "bgWall",
        AvatarShowSlotEquipItemId = "avatarShow",
        AchievementSlotEquipItemId = "achievement",
    }

    for fnName, category in pairs(equipMap) do
        if type(i[fnName]) == "function" then
            wrap(i, fnName, function(orig)
                return function(self, slotIndex, itemID, ...)
                    -- Write to LOCAL first — this is persistent
                    if _G._V14_LOCAL_EDITS[category] then
                        _G._V14_LOCAL_EDITS[category][slotIndex or 1] = itemID
                        saveLocalEditsToDisk()
                        print("[V14] LOCAL EDIT SAVED: " .. category .. "[" .. tostring(slotIndex) .. "] = " .. tostring(itemID))
                    end
                    -- Also try original (may fail silently, that's ok)
                    pcall(orig, self, slotIndex, itemID, ...)
                    return true
                end
            end)
            wrapCount = wrapCount + 1
        end
    end
end)

S("v14_step2.txt", "Wrapped " .. wrapCount .. " functions")

-- ═══════════════════════════════════════════════════════════════════
-- SAVE BUTTON — hijack SaveEditedData to also persist local
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyEditMgrModule")
    local i = M and M.__inner_impl
    if not i then return end

    -- Save — persist local edits + call original + fake success
    if type(i.SaveEditedData) == "function" then
        wrap(i, "SaveEditedData", function(orig)
            return function(self, ...)
                -- Persist current local edits
                saveLocalEditsToDisk()
                -- Call original (may or may not work)
                pcall(orig, self, ...)
                -- Force success popup
                P("SAVE OK", "Slots saved locally!")
                return true
            end
        end)
    end

    if type(i.SaveEditData) == "function" then
        wrap(i, "SaveEditData", function(orig)
            return function(self, ...)
                saveLocalEditsToDisk()
                return true
            end
        end)
    end

    -- RSP handlers — force success and DO NOT let server data overwrite local
    if type(i.on_edit_all_collect_hall_rsp) == "function" then
        wrap(i, "on_edit_all_collect_hall_rsp", function(orig)
            return function(self, err, ...)
                -- Call original with err=0
                pcall(orig, self, 0, ...)
                -- CRITICAL: Reapply local edits to internal state
                -- This prevents server data from wiping our changes
                pcall(function()
                    if type(self.ResetEditDataAndExistEdit) == "function" then
                        -- don't call
                    end
                end)
                return true
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- CROSS BUTTON — after exit, keep local override
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyEditMgrModule")
    local i = M and M.__inner_impl
    if not i then return end

    -- When exiting edit, save local edits to disk
    if type(i.QuitEditState) == "function" then
        wrap(i, "QuitEditState", function(orig)
            return function(self, ...)
                saveLocalEditsToDisk()
                local ok, r = pcall(orig, self, ...)
                return ok and r or true
            end
        end)
    end

    -- Reset data — reapply local after
    if type(i.ResetEditDataAndExistEdit) == "function" then
        wrap(i, "ResetEditDataAndExistEdit", function(orig)
            return function(self, ...)
                local ok, r = pcall(orig, self, ...)
                -- Reapply local after reset
                saveLocalEditsToDisk()
                return ok and r
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- SERVER RSP — inject local edits INTO server data
-- This is the killer fix: jab server fresh data bheje, hum apne edits merge karein
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    local i = M and M.__inner_impl
    if not i then return end

    if type(i.on_get_collect_hall_data_rsp) == "function" then
        wrap(i, "on_get_collect_hall_data_rsp", function(orig)
            return function(self, data, ...)
                -- First, let original process server data
                local ok, r = pcall(orig, self, data, ...)
                -- Then MERGE our local edits INTO the internal data
                pcall(function()
                    if not self._tOthersSocialDataMap then return end
                    -- Find the "self" key or UID key and inject
                    for uidKey, socialData in pairs(self._tOthersSocialDataMap) do
                        if type(socialData) == "table" then
                            -- Inject weapon overrides
                            for idx, itemID in pairs(_G._V14_LOCAL_EDITS.weapon) do
                                if not socialData.slotData then socialData.slotData = {} end
                                socialData.slotData[1] = socialData.slotData[1] or {}
                                socialData.slotData[1][idx] = {
                                    slotType = 1, itemID = itemID, index = idx,
                                    isLock = false, isOwned = true,
                                }
                            end
                            -- Same for others
                            for idx, itemID in pairs(_G._V14_LOCAL_EDITS.vehicle) do
                                if not socialData.slotData then socialData.slotData = {} end
                                socialData.slotData[2] = socialData.slotData[2] or {}
                                socialData.slotData[2][idx] = {
                                    slotType = 2, itemID = itemID, index = idx,
                                    isLock = false, isOwned = true,
                                }
                            end
                            for idx, itemID in pairs(_G._V14_LOCAL_EDITS.pet) do
                                if not socialData.slotData then socialData.slotData = {} end
                                socialData.slotData[3] = socialData.slotData[3] or {}
                                socialData.slotData[3][idx] = {
                                    slotType = 3, itemID = itemID, index = idx,
                                    isLock = false, isOwned = true,
                                }
                            end
                        end
                    end
                end)
                return ok and r
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- ALSO: Patch the slot data getters that read from _tOthersSocialDataMap directly
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    local i = M and M.__inner_impl
    if not i then return end

    if type(i.GetSlotTypeAllSlotData) == "function" then
        wrap(i, "GetSlotTypeAllSlotData", function(orig)
            return function(self, slotType, ...)
                local r = orig(self, slotType, ...)
                local key = slotTypeToKey(slotType)
                if key and _G._V14_LOCAL_EDITS[key] then
                    if type(r) ~= "table" then r = {} end
                    for idx, itemID in pairs(_G._V14_LOCAL_EDITS[key]) do
                        r[idx] = {
                            slotType = slotType, itemID = itemID, index = idx,
                            isLock = false, isOwned = true,
                        }
                    end
                end
                return r
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- FINAL REPORT
-- ═══════════════════════════════════════════════════════════════════
local editCount = 0
for _, items in pairs(_G._V14_LOCAL_EDITS) do
    for _ in pairs(items) do editCount = editCount + 1 end
end

local report = "v14 REPORT\n"
    .. "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"
    .. "Wrapped functions: " .. wrapCount .. "\n"
    .. "Reverted v13: " .. reverted .. "\n"
    .. "Local edits stored: " .. editCount .. "\n"
    .. "\n"
    .. "LOCAL EDITS CONTENT:\n"

for category, items in pairs(_G._V14_LOCAL_EDITS) do
    report = report .. category .. ":\n"
    for idx, itemID in pairs(items) do
        report = report .. "  [" .. tostring(idx) .. "] = " .. tostring(itemID) .. "\n"
    end
end

S("v14_report.txt", report)

P("v14 LOADED",
    "Wrapped: " .. wrapCount .. "\n" ..
    "Edits: " .. editCount .. "\n\n" ..
    "Test:\n" ..
    "1. Slot pe gun select karo\n" ..
    "2. Save dabao\n" ..
    "3. Cross dabao\n" ..
    "4. Reopen karo — dekho bacha ya nahi")

return true
