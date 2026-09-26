-- ═══════════════════════════════════════════════════════════════════
-- v15 — CLEAN REBUILD
-- Sirf is path pe likhega: /storage/emulated/0/Android/data/com.pubg.imobile/files/
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

S("v15_step0.txt", "v15 loaded at " .. os.date("%Y-%m-%d %H:%M:%S"))

-- ═══════════════════════════════════════════════════════════════════
-- STEP 1: NUCLEAR REVERT — saare purane prefixes saaf karo
-- ═══════════════════════════════════════════════════════════════════
local PREFIXES = {
    "__mini11_",    -- v11
    "__v12_",       -- v12
    "__v13_",       -- v13
    "__v14_",       -- v14
    "__slotv10_",   -- v10
    "__pet11_",     -- pet v11
    "__pslotv2_",   -- pslot v2
    "__pslot11_",   -- pslot v11
}

local reverted = 0

local function revertModule(mod)
    if type(mod) ~= "table" then return 0 end
    local cnt = 0
    local backups = {}
    -- Find all backup keys
    for k in pairs(mod) do
        if type(k) == "string" then
            for _, pfx in ipairs(PREFIXES) do
                local plen = #pfx
                if k:sub(1, plen) == pfx then
                    local origName = k:sub(plen + 1)
                    backups[#backups+1] = {backupKey = k, origName = origName}
                    break
                end
            end
        end
    end
    -- Restore originals
    for _, item in ipairs(backups) do
        if type(mod[item.backupKey]) == "function" then
            mod[item.origName] = mod[item.backupKey]
            cnt = cnt + 1
        end
        mod[item.backupKey] = nil
    end
    return cnt
end

-- Revert every module we've touched
local modules = {
    "client.slua.logic.lobby.Left.Logic_SocialLobbyModule",
    "client.slua.logic.lobby.Left.Logic_SocialLobbyEditMgrModule",
    "client.logic.lobby.ThemeVehicleManager",
    "client.logic.vehicle.VehicleCollectSystem",
    "client.logic.vehicle.LogicVehicleExtendedFeature",
    "client.logic.vehicle.LogicVehicleAccessory",
    "client.slua.logic.pet.logic_pet",
    "client.slua.logic.pet.pet_manager",
    "client.slua.logic.pet.traits.TLogicPetData",
    "client.slua.logic.pet.traits.TLogicPetCfg",
}

for _, path in ipairs(modules) do
    pcall(function()
        local M = require(path)
        if M and M.__inner_impl then
            reverted = reverted + revertModule(M.__inner_impl)
        end
        if M and M ~= M.__inner_impl then
            reverted = reverted + revertModule(M)
        end
    end)
end

S("v15_step1.txt", "Reverted: " .. reverted .. " functions")
print("[V15] STEP 1 — reverted " .. reverted)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 2: REBUILD LOCAL STORAGE (persistent)
-- ═══════════════════════════════════════════════════════════════════
_G._V15_EDITS = _G._V15_EDITS or {
    weapon = {},       -- weapon[idx] = itemID
    vehicle = {},
    pet = {},
    petClothe = {},
    bgWall = {},
    avatarShow = {},
    achievement = {},
}

local function saveEditsToDisk()
    pcall(function()
        local lines = {"return {"}
        for cat, items in pairs(_G._V15_EDITS) do
            table.insert(lines, "  " .. cat .. " = {")
            for idx, itemID in pairs(items) do
                table.insert(lines, string.format("    [%s] = %s,", tostring(idx), tostring(itemID)))
            end
            table.insert(lines, "  },")
        end
        table.insert(lines, "}")
        S("v15_edits.txt", table.concat(lines, "\n"))
    end)
end

local function loadEditsFromDisk()
    pcall(function()
        local f = io.open(DIR .. "v15_edits.txt", "r")
        if not f then return end
        local content = f:read("*a")
        f:close()
        local fn = load(content)
        if fn then
            local data = fn()
            if type(data) == "table" then
                for cat, items in pairs(data) do
                    if _G._V15_EDITS[cat] then
                        for idx, itemID in pairs(items) do
                            _G._V15_EDITS[cat][idx] = itemID
                        end
                    end
                end
            end
        end
    end)
end

loadEditsFromDisk()

local editCount = 0
for _, items in pairs(_G._V15_EDITS) do
    for _ in pairs(items) do editCount = editCount + 1 end
end

S("v15_step2.txt", "Local storage ready. Existing edits: " .. editCount)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 3: APPLY SLOT UNLOCK (ye zaroori hai — pehle re-apply karo)
-- ═══════════════════════════════════════════════════════════════════
local PFX = "__v15_"
local function wrap(mod, name, wrapper)
    if not mod or type(mod[name]) ~= "function" then return false end
    if not mod[PFX .. name] then mod[PFX .. name] = mod[name] end
    mod[name] = wrapper(mod[PFX .. name])
    return true
end

local unlocked = 0

pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    local i = M and M.__inner_impl
    if not i then return end

    if wrap(i, "GetSlotIsUnlockedByCollectHallLevel", function(orig)
        return function(self, st, idx, ...) return true end
    end) then unlocked = unlocked + 1 end

    if wrap(i, "GetSlotIsUnlockBySlotTypeAndIndex", function(orig)
        return function(self, st, idx, ...) return true end
    end) then unlocked = unlocked + 1 end

    if wrap(i, "GetSlotUnlockCountByCollectHallLevel", function(orig)
        return function(self, st, ...) return 6 end
    end) then unlocked = unlocked + 1 end

    if wrap(i, "GetUnlockSlotByCollectHallMinLevel", function(orig)
        return function(self, ...) return 1 end
    end) then unlocked = unlocked + 1 end
end)

S("v15_step3.txt", "Slot unlock applied: " .. unlocked)
print("[V15] STEP 3 — unlock: " .. unlocked)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 4: SLOT EQUIP — capture selection + persist
-- ═══════════════════════════════════════════════════════════════════
local equipCount = 0

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
                    -- Capture selection locally
                    local idx = slotIndex or 1
                    if _G._V15_EDITS[category] then
                        _G._V15_EDITS[category][idx] = itemID
                        saveEditsToDisk()
                    end
                    -- Try original
                    pcall(orig, self, slotIndex, itemID, ...)
                    return true
                end
            end)
            equipCount = equipCount + 1
        end
    end
end)

S("v15_step4.txt", "Slot equip wrapped: " .. equipCount)
print("[V15] STEP 4 — equip: " .. equipCount)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 5: THE KILLER — inject edits INTO server response
-- ═══════════════════════════════════════════════════════════════════
local rspCount = 0

pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    local i = M and M.__inner_impl
    if not i then return end

    -- KEY: Modify DATA BEFORE original processes it
    if type(i.on_get_collect_hall_data_rsp) == "function" then
        wrap(i, "on_get_collect_hall_data_rsp", function(orig)
            return function(self, data, ...)
                -- Merge our edits into DATA before original reads it
                pcall(function()
                    if type(data) ~= "table" then return end

                    -- Try multiple structures
                    if not data.slotData then data.slotData = {} end
                    if not data.slots then data.slots = {} end

                    -- Inject weapon edits into slotType 1
                    for idx, itemID in pairs(_G._V15_EDITS.weapon) do
                        data.slotData[1] = data.slotData[1] or {}
                        data.slotData[1][idx] = {
                            slotType = 1, slotTypeID = 1, type = 1,
                            index = idx, slotIndex = idx,
                            itemID = itemID, itemId = itemID, ItemID = itemID,
                            resID = itemID, resId = itemID, skinID = itemID, skinId = itemID,
                            isLock = false, isUnlock = true, isOwned = true,
                            expire_ts = 0, isPermanent = true, _v15 = true,
                        }
                    end

                    -- Vehicle into slotType 2
                    for idx, itemID in pairs(_G._V15_EDITS.vehicle) do
                        data.slotData[2] = data.slotData[2] or {}
                        data.slotData[2][idx] = {
                            slotType = 2, slotTypeID = 2, type = 2,
                            index = idx, slotIndex = idx,
                            itemID = itemID, itemId = itemID, ItemID = itemID,
                            resID = itemID, resId = itemID, skinID = itemID, skinId = itemID,
                            isLock = false, isUnlock = true, isOwned = true,
                            expire_ts = 0, isPermanent = true, _v15 = true,
                        }
                    end

                    -- Pet into slotType 3
                    for idx, itemID in pairs(_G._V15_EDITS.pet) do
                        data.slotData[3] = data.slotData[3] or {}
                        data.slotData[3][idx] = {
                            slotType = 3, slotTypeID = 3, type = 3,
                            index = idx, slotIndex = idx,
                            itemID = itemID, itemId = itemID, ItemID = itemID,
                            resID = itemID, resId = itemID, skinID = itemID, skinId = itemID,
                            isLock = false, isUnlock = true, isOwned = true,
                            expire_ts = 0, isPermanent = true, _v15 = true,
                        }
                    end
                end)
                -- Now call original with enriched data
                return orig(self, data, ...)
            end
        end)
        rspCount = rspCount + 1
    end

    -- Also: Edit mgr RSP handlers
    local E = require("client.slua.logic.lobby.Left.Logic_SocialLobbyEditMgrModule")
    local ei = E and E.__inner_impl
    if ei then
        for _, fn in ipairs({
            "on_edit_all_collect_hall_rsp",
            "on_edit_honor_display_rsp",
            "on_set_collect_hall_background_rsp",
        }) do
            if type(ei[fn]) == "function" then
                wrap(ei, fn, function(orig)
                    return function(self, err, ...)
                        saveEditsToDisk()
                        pcall(orig, self, 0, ...)
                        return true
                    end
                end)
                rspCount = rspCount + 1
            end
        end
    end
end)

S("v15_step5.txt", "RSP handlers: " .. rspCount)
print("[V15] STEP 5 — rsp: " .. rspCount)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 6: SLOT DATA GETTER — return local override on top of original
-- ═══════════════════════════════════════════════════════════════════
local getterCount = 0

pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    local i = M and M.__inner_impl
    if not i then return end

    local function slotTypeToKey(slotType)
        local s = type(slotType) == "string" and slotType:lower() or ""
        local n = tonumber(slotType) or 0
        if s:find("weapon") or s:find("gun") or n == 1 then return "weapon" end
        if s:find("vehicle") or s:find("car") or n == 2 then return "vehicle" end
        if s:find("petclothe") then return "petClothe" end
        if s:find("pet") or n == 3 then return "pet" end
        if s:find("bgwall") or s:find("bg_wall") or n == 4 then return "bgWall" end
        if s:find("avatarshow") or n == 5 then return "avatarShow" end
        if s:find("achievement") or n == 6 then return "achievement" end
        return nil
    end

    if wrap(i, "GetSlotDataBySlotTypeAndIndex", function(orig)
        return function(self, slotType, index, ...)
            -- Priority: local edit
            local key = slotTypeToKey(slotType)
            if key and _G._V15_EDITS[key] and _G._V15_EDITS[key][index] then
                local itemID = _G._V15_EDITS[key][index]
                return {
                    slotType = slotType, slotTypeID = slotType, type = slotType,
                    index = index, slotIndex = index,
                    itemID = itemID, itemId = itemID, ItemID = itemID,
                    resID = itemID, resId = itemID, skinID = itemID, skinId = itemID,
                    isLock = false, isUnlock = true, isOwned = true,
                    expire_ts = 0, expireTime = 0, isPermanent = true,
                    _v15 = true,
                }
            end
            return orig(self, slotType, index, ...)
        end
    end) then getterCount = getterCount + 1 end
end)

S("v15_step6.txt", "Getter wrapped: " .. getterCount)
print("[V15] STEP 6 — getter: " .. getterCount)

-- ═══════════════════════════════════════════════════════════════════
-- FINAL REPORT
-- ═══════════════════════════════════════════════════════════════════
local finalEdits = 0
for _, items in pairs(_G._V15_EDITS) do
    for _ in pairs(items) do finalEdits = finalEdits + 1 end
end

local report = "v15 REPORT\n"
    .. "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"
    .. "Reverted: " .. reverted .. "\n"
    .. "Slot Unlock: " .. unlocked .. "\n"
    .. "Slot Equip: " .. equipCount .. "\n"
    .. "RSP Handlers: " .. rspCount .. "\n"
    .. "Getter: " .. getterCount .. "\n"
    .. "Existing Local Edits: " .. finalEdits .. "\n"

S("v15_report.txt", report)

P("v15 LOADED",
    "Reverted: " .. reverted .. "\n" ..
    "Unlock: " .. unlocked .. "\n" ..
    "Equip: " .. equipCount .. "\n" ..
    "RSP: " .. rspCount .. "\n" ..
    "Getter: " .. getterCount .. "\n\n" ..
    "Test:\n" ..
    "1. Slot pe gun select\n" ..
    "2. Save dabao\n" ..
    "3. Cross dabao\n" ..
    "4. Wapas kholo — dekho bacha")

return true
