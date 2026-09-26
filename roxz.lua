-- ═══════════════════════════════════════════════════════════════════
-- v16 — REAL CAPTURE + PERSIST
-- Captures actual item ID from AddEquipItemIdToTableBySlotType
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

S("v16_step0.txt", "v16 loaded at " .. os.date("%Y-%m-%d %H:%M:%S"))

-- ═══════════════════════════════════════════════════════════════════
-- STEP 1: NUCLEAR REVERT — saare prefix hataye
-- ═══════════════════════════════════════════════════════════════════
local PREFIXES = {
    "__mini11_", "__v12_", "__v13_", "__v14_", "__v15_",
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
    "client.slua.logic.lobby.Left.Logic_SocialLobbyModule",
    "client.slua.logic.lobby.Left.Logic_SocialLobbyEditMgrModule",
    "client.logic.lobby.ThemeVehicleManager",
    "client.logic.vehicle.VehicleCollectSystem",
    "client.logic.vehicle.LogicVehicleExtendedFeature",
    "client.logic.vehicle.LogicVehicleAccessory",
}) do
    pcall(function()
        local M = require(path)
        if M and M.__inner_impl then reverted = reverted + revertModule(M.__inner_impl) end
        if M and M ~= M.__inner_impl then reverted = reverted + revertModule(M) end
    end)
end

S("v16_step1.txt", "Reverted: " .. reverted)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 2: LOCAL STORAGE
-- ═══════════════════════════════════════════════════════════════════
_G._V16 = _G._V16 or {
    weapon = {}, vehicle = {}, pet = {}, petClothe = {},
    bgWall = {}, avatarShow = {}, achievement = {},
    raw = {},  -- raw args log
}

local function saveToDisk()
    pcall(function()
        local lines = {"return {"}
        for cat, items in pairs(_G._V16) do
            if cat ~= "raw" and type(items) == "table" then
                table.insert(lines, "  " .. cat .. " = {")
                for idx, itemID in pairs(items) do
                    table.insert(lines, string.format("    [%s] = %s,", tostring(idx), tostring(itemID)))
                end
                table.insert(lines, "  },")
            end
        end
        table.insert(lines, "}")
        S("v16_edits.txt", table.concat(lines, "\n"))
    end)
end

local function loadFromDisk()
    pcall(function()
        local f = io.open(DIR .. "v16_edits.txt", "r")
        if not f then return end
        local content = f:read("*a")
        f:close()
        local fn = load(content)
        if fn then
            local data = fn()
            if type(data) == "table" then
                for cat, items in pairs(data) do
                    if _G._V16[cat] and type(items) == "table" then
                        for idx, itemID in pairs(items) do
                            _G._V16[cat][idx] = itemID
                        end
                    end
                end
            end
        end
    end)
end

loadFromDisk()

-- ═══════════════════════════════════════════════════════════════════
-- SLOT TYPE → KEY MAP
-- ═══════════════════════════════════════════════════════════════════
local function slotTypeToKey(st)
    local s = type(st) == "string" and st:lower() or ""
    local n = tonumber(st) or 0
    if s:find("weapon") or s:find("gun") or n == 1 then return "weapon" end
    if s:find("vehicle") or s:find("car") or n == 2 then return "vehicle" end
    if s:find("petclothe") or s:find("cloth") then return "petClothe" end
    if s:find("pet") or n == 3 then return "pet" end
    if s:find("bgwall") or s:find("bg_wall") or n == 4 then return "bgWall" end
    if s:find("avatarshow") or s:find("avatar_show") or n == 5 then return "avatarShow" end
    if s:find("achievement") or n == 6 then return "achievement" end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════
-- WRAP HELPER
-- ═══════════════════════════════════════════════════════════════════
local PFX = "__v16_"
local function wrap(mod, name, wrapper)
    if not mod or type(mod[name]) ~= "function" then return false end
    if not mod[PFX .. name] then mod[PFX .. name] = mod[name] end
    mod[name] = wrapper(mod[PFX .. name])
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 3: SLOT UNLOCK (re-apply, ye working hai)
-- ═══════════════════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════════════
-- STEP 4: ⭐ MAIN CAPTURE — AddEquipItemIdToTableBySlotType ⭐
-- Ye wahi function hai jo (slotType, index, itemID) receive karta hai
-- ═══════════════════════════════════════════════════════════════════
local captured = 0
pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    local i = M and M.__inner_impl
    if not i then return end

    if type(i.AddEquipItemIdToTableBySlotType) == "function" then
        wrap(i, "AddEquipItemIdToTableBySlotType", function(orig)
            return function(self, ...)
                local n = select("#", ...)
                local args = {...}
                
                -- RAW LOG (for debugging)
                local logLine = "AddEquipItemIdToTableBySlotType:"
                for k = 1, n do
                    logLine = logLine .. " [" .. k .. "]=" .. tostring(args[k]) .. " (" .. type(args[k]) .. ")"
                end
                _G._V16.raw[#_G._V16.raw+1] = logLine
                print("[V16] " .. logLine)
                
                -- TRY MULTIPLE ARG INTERPRETATIONS
                local function tryCapture(st, idx, itemID)
                    if type(itemID) ~= "number" then return end
                    if itemID < 100 or itemID > 99999999 then return end
                    local key = slotTypeToKey(st)
                    if not key then return end
                    _G._V16[key][idx or 1] = itemID
                    captured = captured + 1
                    saveToDisk()
                    print("[V16] CAPTURED: " .. key .. "[" .. tostring(idx) .. "] = " .. tostring(itemID))
                end
                
                -- Interpretation 1: (slotType, index, itemID)
                if n >= 3 then
                    tryCapture(args[1], args[2], args[3])
                end
                -- Interpretation 2: (slotType, itemID)
                if n >= 2 then
                    tryCapture(args[1], 1, args[2])
                end
                -- Interpretation 3: (itemID, slotType)
                if n >= 2 then
                    tryCapture(args[2], 1, args[1])
                end
                -- Interpretation 4: (uid, slotType, index, itemID)
                if n >= 4 then
                    tryCapture(args[2], args[3], args[4])
                end
                -- Interpretation 5: table arg
                if type(args[1]) == "table" then
                    local t = args[1]
                    local st = t.slotType or t.SlotType or t.type
                    local idx = t.index or t.slotIndex or t.Index
                    local itemID = t.itemID or t.itemId or t.ItemID or t.resID
                    tryCapture(st, idx, itemID)
                end
                
                return orig(self, ...)
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 5: BACKUP CAPTURE — SetSocialDataByKey + SetSlotUnlocked
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    local i = M and M.__inner_impl
    if not i then return end

    if type(i.SetSocialDataByKey) == "function" then
        wrap(i, "SetSocialDataByKey", function(orig)
            return function(self, key, value, ...)
                local logLine = "SetSocialDataByKey: key=" .. tostring(key) .. " value=" .. tostring(value)
                _G._V16.raw[#_G._V16.raw+1] = logLine
                print("[V16] " .. logLine)
                return orig(self, key, value, ...)
            end
        end)
    end

    if type(i.SetSlotUnlocked) == "function" then
        wrap(i, "SetSlotUnlocked", function(orig)
            return function(self, st, idx, locked, ...)
                print("[V16] SetSlotUnlocked: " .. tostring(st) .. " idx=" .. tostring(idx) .. " locked=" .. tostring(locked))
                return orig(self, st, idx, locked, ...)
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 6: SLOT EQUIP — log UID+slotIndex args
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    local i = M and M.__inner_impl
    if not i then return end

    local equipFns = {
        "WeaponSlotEquipItemId", "VehicleSlotEquipItemId",
        "PetSlotEquipItemId", "PetSlotEquipClotheItemId",
        "BGWallSlotEquipItemId", "AvatarShowSlotEquipItemId",
        "AchievementSlotEquipItemId",
    }
    for _, fnName in ipairs(equipFns) do
        if type(i[fnName]) == "function" then
            wrap(i, fnName, function(orig)
                return function(self, ...)
                    local args = {...}
                    local n = select("#", ...)
                    local logLine = fnName .. ":"
                    for k = 1, n do
                        logLine = logLine .. " [" .. k .. "]=" .. tostring(args[k])
                    end
                    _G._V16.raw[#_G._V16.raw+1] = logLine
                    print("[V16] " .. logLine)
                    return orig(self, ...)
                end
            end)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 7: GETTER OVERRIDE — return local edits always
-- ═══════════════════════════════════════════════════════════════════
local getters = 0
pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    local i = M and M.__inner_impl
    if not i then return end

    -- Main getter
    if type(i.GetSlotDataBySlotTypeAndIndex) == "function" then
        wrap(i, "GetSlotDataBySlotTypeAndIndex", function(orig)
            return function(self, slotType, index, ...)
                local key = slotTypeToKey(slotType)
                if key and _G._V16[key] and _G._V16[key][index] then
                    local itemID = _G._V16[key][index]
                    return {
                        slotType = slotType, slotTypeID = slotType, type = slotType,
                        index = index, slotIndex = index,
                        itemID = itemID, itemId = itemID, ItemID = itemID,
                        resID = itemID, resId = itemID,
                        skinID = itemID, skinId = itemID,
                        isLock = false, isUnlock = true, isOwned = true,
                        expire_ts = 0, expireTime = 0, isPermanent = true,
                        _v16 = true,
                    }
                end
                return orig(self, slotType, index, ...)
            end
        end)
        getters = getters + 1
    end

    -- All slot data getter
    if type(i.GetSlotTypeAllSlotData) == "function" then
        wrap(i, "GetSlotTypeAllSlotData", function(orig)
            return function(self, slotType, ...)
                local r = orig(self, slotType, ...)
                local key = slotTypeToKey(slotType)
                if key and _G._V16[key] then
                    if type(r) ~= "table" then r = {} end
                    for idx, itemID in pairs(_G._V16[key]) do
                        r[idx] = {
                            slotType = slotType, itemID = itemID, index = idx,
                            isLock = false, isOwned = true, _v16 = true,
                        }
                    end
                end
                return r
            end
        end)
        getters = getters + 1
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 8: RSP INJECT — merge our edits into server data BEFORE processing
-- ═══════════════════════════════════════════════════════════════════
local injected = 0
pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    local i = M and M.__inner_impl
    if not i then return end

    if type(i.on_get_collect_hall_data_rsp) == "function" then
        wrap(i, "on_get_collect_hall_data_rsp", function(orig)
            return function(self, data, ...)
                -- Enrich server data with our edits
                pcall(function()
                    if type(data) ~= "table" then return end
                    data.slotData = data.slotData or {}
                    -- Inject per slotType
                    local SLOT_KEYS = {
                        weapon = 1, vehicle = 2, pet = 3,
                        bgWall = 4, avatarShow = 5, achievement = 6,
                    }
                    for key, st in pairs(SLOT_KEYS) do
                        if _G._V16[key] then
                            data.slotData[st] = data.slotData[st] or {}
                            for idx, itemID in pairs(_G._V16[key]) do
                                data.slotData[st][idx] = {
                                    slotType = st, slotTypeID = st, type = st,
                                    index = idx, slotIndex = idx,
                                    itemID = itemID, itemId = itemID, ItemID = itemID,
                                    resID = itemID, resId = itemID,
                                    skinID = itemID, skinId = itemID,
                                    isLock = false, isUnlock = true, isOwned = true,
                                    expire_ts = 0, isPermanent = true, _v16 = true,
                                }
                            end
                        end
                    end
                end)
                return orig(self, data, ...)
            end
        end)
        injected = injected + 1
    end

    -- Also: edit mgr RSP
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
                        saveToDisk()
                        pcall(orig, self, 0, ...)
                        return true
                    end
                end)
                injected = injected + 1
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- FINAL REPORT
-- ═══════════════════════════════════════════════════════════════════
local editCount = 0
for _, items in pairs(_G._V16) do
    if type(items) == "table" then
        for _ in pairs(items) do editCount = editCount + 1 end
    end
end

local report = "v16 REPORT\n"
    .. "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"
    .. "Reverted: " .. reverted .. "\n"
    .. "Unlocked: " .. unlocked .. "\n"
    .. "Captured items: " .. captured .. "\n"
    .. "Getters wrapped: " .. getters .. "\n"
    .. "RSP injected: " .. injected .. "\n"
    .. "Total edits: " .. editCount .. "\n"

S("v16_report.txt", report)

-- Also save raw log
S("v16_raw_log.txt", table.concat(_G._V16.raw, "\n"))

P("v16 LOADED",
    "Reverted: " .. reverted .. "\n" ..
    "Unlocked: " .. unlocked .. "\n" ..
    "Getters: " .. getters .. "\n" ..
    "RSP: " .. injected .. "\n\n" ..
    "Test:\n" ..
    "1. Slot pe gun select karo\n" ..
    "2. Save dabao\n" ..
    "3. Cross dabao\n" ..
    "4. Wapas kholo\n\n" ..
    "Agar capture hua toh v16_raw_log.txt mein dikhega")

return true
