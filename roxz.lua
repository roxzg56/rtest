-- ═══════════════════════════════════════════════════════════════════
-- v17 — CONFIG DRIVEN FORCE DISPLAY
-- Tu IDs daalega config file mein, hum force display karenge
-- Config: /storage/emulated/0/Android/data/com.pubg.imobile/files/pslot_config.txt
-- ═══════════════════════════════════════════════════════════════════

local DIR = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"
local CONFIG_FILE = "pslot_config.txt"
local EDITS_FILE  = "pslot_edits.txt"

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
-- STEP 1: WRITE DEFAULT CONFIG (if not exists)
-- ═══════════════════════════════════════════════════════════════════
local defaultConfig = [[
-- PSLOT CONFIG v17
-- EDIT THIS FILE to change what appears in your profile display slots
-- Save and reload game for changes to apply
--
-- SLOT TYPES:
--   weapon    = Weapon slots (AR, SR, etc)
--   vehicle   = Vehicle showcase slots
--   pet       = Pet display slots
--   bgWall    = Background wall
--   avatarShow = Avatar showcase
--   achievement = Achievement badges
--
-- ITEM ID ranges (approximate, may need tuning):
--   Weapons:  101001-101020 (AR), 102001-102010 (SR), etc
--   Vehicles: 903=Dacia, 904=UAZ, 905=Buggy, 906=Mirado, 907=Coupe,
--             908=Zima, 909=Scooter, 910=UAZ, 911=Mirado, 912=...
--   Pets:     50008=Cat, 50009=Dog, 50017=Wolf, 50018=Panda

return {
    weapon = {
        [1] = 101008,   -- AR slot 1
        [2] = 101004,   -- AR slot 2
        [3] = 102001,   -- SR slot 1
        [4] = 102002,   -- SR slot 2
        [5] = 101003,   -- AR slot 3
        [6] = 101005,   -- AR slot 4
    },
    vehicle = {
        [1] = 903,      -- Dacia
        [2] = 904,      -- UAZ
        [3] = 906,      -- Mirado
        [4] = 907,      -- Coupe RB
        [5] = 960,      -- 
        [6] = 961,
    },
    pet = {
        [1] = 50008,    -- Cat
        [2] = 50009,    -- Dog
        [3] = 50017,    -- Wolf
        [4] = 50018,    -- Panda
        [5] = 50033,    -- Lion
        [6] = 50010,    -- Penguin
    },
    bgWall = {
        [1] = 50008,
    },
    avatarShow = {
        [1] = 20010,
    },
    achievement = {
        [1] = 20011,
    },
}
]]

if not R(CONFIG_FILE) then
    S(CONFIG_FILE, defaultConfig)
    print("[V17] Created default config: " .. DIR .. CONFIG_FILE)
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 2: LOAD CONFIG
-- ═══════════════════════════════════════════════════════════════════
local function loadConfig()
    local content = R(CONFIG_FILE)
    if not content then return nil end
    local fn = load(content)
    if not fn then return nil end
    local ok, data = pcall(fn)
    if ok and type(data) == "table" then return data end
    return nil
end

local CFG = loadConfig() or {}

-- ═══════════════════════════════════════════════════════════════════
-- STEP 3: NUCLEAR REVERT
-- ═══════════════════════════════════════════════════════════════════
local PREFIXES = {
    "__mini11_", "__v12_", "__v13_", "__v14_", "__v15_", "__v16_",
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
}) do
    pcall(function()
        local M = require(path)
        if M and M.__inner_impl then reverted = reverted + revertModule(M.__inner_impl) end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- SLOT KEY MAPPING
-- ═══════════════════════════════════════════════════════════════════
local function slotTypeToKey(st)
    if st == nil then return nil end
    local s = type(st) == "string" and st:lower() or ""
    local n = tonumber(st)
    if s:find("weapon") or s:find("gun") or n == 1 then return "weapon" end
    if s:find("vehicle") or s:find("car") or n == 2 then return "vehicle" end
    if s:find("petclothe") then return "petClothe" end
    if s:find("pet") or n == 3 then return "pet" end
    if s:find("bgwall") or n == 4 then return "bgWall" end
    if s:find("avatarshow") or n == 5 then return "avatarShow" end
    if s:find("achievement") or n == 6 then return "achievement" end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════
-- MAKE FAKE SLOT DATA
-- ═══════════════════════════════════════════════════════════════════
local function makeSlotData(slotType, index, itemID)
    return {
        slotType = slotType, slotTypeID = slotType, type = slotType,
        SlotType = slotType, SlotTypeID = slotType,
        index = index, slotIndex = index, Index = index, SlotIndex = index,
        itemID = itemID, itemId = itemID, ItemID = itemID,
        resID = itemID, resId = itemID, ResID = itemID,
        skinID = itemID, skinId = itemID, SkinID = itemID,
        skin_res_id = itemID, res_id = itemID,
        isLock = false, isUnlock = true, isLocked = false, isOwned = true,
        bIsLock = false, bLock = false, bIsUnlock = true, bIsOwned = true,
        expire_ts = 0, expireTime = 0, ExpireTS = 0, isPermanent = true,
        _v17 = true,
    }
end

-- Build full slot tree from config
local function buildSlotData()
    local out = {}
    for key, items in pairs(CFG) do
        if type(items) == "table" then
            out[key] = {}
            for idx, itemID in pairs(items) do
                out[key][idx] = itemID
            end
        end
    end
    return out
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 4: WRAP HELPER
-- ═══════════════════════════════════════════════════════════════════
local PFX = "__v17_"
local function wrap(mod, name, wrapper)
    if not mod or type(mod[name]) ~= "function" then return false end
    if not mod[PFX .. name] then mod[PFX .. name] = mod[name] end
    mod[name] = wrapper(mod[PFX .. name])
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 5: SLOT UNLOCK
-- ═══════════════════════════════════════════════════════════════════
local unlocked = 0
pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    local i = M and M.__inner_impl
    if not i then return end

    if wrap(i, "GetSlotIsUnlockedByCollectHallLevel", function(orig)
        return function(self, ...) return true end
    end) then unlocked = unlocked + 1 end
    if wrap(i, "GetSlotIsUnlockBySlotTypeAndIndex", function(orig)
        return function(self, ...) return true end
    end) then unlocked = unlocked + 1 end
    if wrap(i, "GetSlotUnlockCountByCollectHallLevel", function(orig)
        return function(self, ...) return 6 end
    end) then unlocked = unlocked + 1 end
    if wrap(i, "GetUnlockSlotByCollectHallMinLevel", function(orig)
        return function(self, ...) return 1 end
    end) then unlocked = unlocked + 1 end
end)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 6: FORCE GETTERS — return config data ALWAYS
-- ═══════════════════════════════════════════════════════════════════
local forced = 0

pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    local i = M and M.__inner_impl
    if not i then return end

    -- Main slot getter
    if wrap(i, "GetSlotDataBySlotTypeAndIndex", function(orig)
        return function(self, slotType, index, ...)
            local key = slotTypeToKey(slotType)
            if key and CFG[key] and CFG[key][index] then
                return makeSlotData(slotType, index, CFG[key][index])
            end
            return orig(self, slotType, index, ...)
        end
    end) then forced = forced + 1 end

    -- All slots getter
    if wrap(i, "GetSlotTypeAllSlotData", function(orig)
        return function(self, slotType, ...)
            local key = slotTypeToKey(slotType)
            if key and CFG[key] then
                local result = {}
                for idx, itemID in pairs(CFG[key]) do
                    result[idx] = makeSlotData(slotType, idx, itemID)
                end
                return result
            end
            return orig(self, slotType, ...)
        end
    end) then forced = forced + 1 end

    -- All unlock data
    if wrap(i, "GetSlotTypeAllUnlockData", function(orig)
        return function(self, slotType, ...)
            local key = slotTypeToKey(slotType)
            if key and CFG[key] then
                local result = {}
                for idx, itemID in pairs(CFG[key]) do
                    result[idx] = true
                end
                return result
            end
            return orig(self, slotType, ...)
        end
    end) then forced = forced + 1 end

    -- Equipped count
    if wrap(i, "GetSlotTypeEquippedSlotCount", function(orig)
        return function(self, slotType, ...)
            local key = slotTypeToKey(slotType)
            if key and CFG[key] then
                local n = 0
                for _ in pairs(CFG[key]) do n = n + 1 end
                return n
            end
            return orig(self, slotType, ...)
        end
    end) then forced = forced + 1 end

    -- Have any
    if wrap(i, "GetHaveAnySlotIsEquipped", function(orig)
        return function(self, ...) return true end
    end) then forced = forced + 1 end

    -- Check is use
    if wrap(i, "CheckSlotTypeIsUseItemId", function(orig)
        return function(self, ...) return true end
    end) then forced = forced + 1 end
end)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 7: FORCE RSP — inject config into server data
-- ═══════════════════════════════════════════════════════════════════
local injected = 0

pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    local i = M and M.__inner_impl
    if not i then return end

    local function injectInto(data)
        if type(data) ~= "table" then return end
        -- Common structure fields
        if not data.slotData then data.slotData = {} end
        if not data.slots then data.slots = {} end
        if not data.allSlotData then data.allSlotData = {} end
        if not data.slotMap then data.slotMap = {} end

        -- Slot type numeric map
        local SLOT_NUMS = { weapon = 1, vehicle = 2, pet = 3, bgWall = 4, avatarShow = 5, achievement = 6 }

        for key, items in pairs(CFG) do
            local stNum = SLOT_NUMS[key]
            if stNum and type(items) == "table" then
                for idx, itemID in pairs(items) do
                    local slotObj = makeSlotData(stNum, idx, itemID)
                    data.slotData[stNum] = data.slotData[stNum] or {}
                    data.slotData[stNum][idx] = slotObj
                    data.allSlotData[stNum] = data.allSlotData[stNum] or {}
                    data.allSlotData[stNum][idx] = slotObj
                    data.slots[#data.slots+1] = slotObj
                    data.slotMap[stNum] = data.slotMap[stNum] or {}
                    data.slotMap[stNum][idx] = slotObj
                end
            end
        end
    end

    -- Patch collect hall RSP
    if wrap(i, "on_get_collect_hall_data_rsp", function(orig)
        return function(self, data, ...)
            injectInto(data)
            return orig(self, data, ...)
        end
    end) then injected = injected + 1 end

    -- Patch other mixed hall RSP
    if wrap(i, "on_get_other_mixed_hall_data_rsp", function(orig)
        return function(self, data, ...)
            injectInto(data)
            return orig(self, data, ...)
        end
    end) then injected = injected + 1 end

    -- Patch unlock RSP
    if wrap(i, "on_unlock_collect_hall_slot_rsp", function(orig)
        return function(self, err, ...)
            return orig(self, 0, ...)
        end
    end) then injected = injected + 1 end

    -- Patch edit mgr RSP
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
                        return orig(self, 0, ...)
                    end
                end)
                injected = injected + 1
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 8: PERIODIC FORCE — every 1 second, re-inject into internal state
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerLoop then
        ticker.AddTimerLoop(0, function()
            pcall(function()
                local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
                local i = M and M.__inner_impl
                if not i then return end

                -- Force-fill _tOthersSocialDataMap with our data
                local MyUID = "self"
                pcall(function()
                    if _G.DataMgr and _G.DataMgr.roleData then
                        MyUID = tostring(_G.DataMgr.roleData.uid or "self")
                    end
                end)

                -- Ensure map exists
                if not i._tOthersSocialDataMap then
                    i._tOthersSocialDataMap = {}
                end

                -- Build fake social data
                local socialData = {
                    uid = MyUID,
                    slotData = {},
                    slots = {},
                    allSlotData = {},
                    collectHallLevel = 999,
                }

                local SLOT_NUMS = { weapon = 1, vehicle = 2, pet = 3, bgWall = 4, avatarShow = 5, achievement = 6 }
                for key, items in pairs(CFG) do
                    local stNum = SLOT_NUMS[key]
                    if stNum and type(items) == "table" then
                        socialData.slotData[stNum] = {}
                        for idx, itemID in pairs(items) do
                            local slotObj = makeSlotData(stNum, idx, itemID)
                            socialData.slotData[stNum][idx] = slotObj
                            socialData.slots[#socialData.slots+1] = slotObj
                            socialData.allSlotData[#socialData.allSlotData+1] = slotObj
                        end
                    end
                end

                -- Inject for all keys (self, uid, etc)
                i._tOthersSocialDataMap[MyUID] = socialData
                i._tOthersSocialDataMap["self"] = socialData
                i._tOthersSocialDataMap["me"] = socialData
                i._tOthersSocialDataMap[0] = socialData
                i._tOthersSocialDataMap[1] = socialData
            end)
        end, -1, 1.0)
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 9: NEUTRALIZE SAVE (no-op, no server)
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local E = require("client.slua.logic.lobby.Left.Logic_SocialLobbyEditMgrModule")
    local ei = E and E.__inner_impl
    if not ei then return end

    if wrap(ei, "SaveEditedData", function(orig)
        return function(self, ...)
            P("SAVE", "Saved (client-only)")
            return true
        end
    end) then end

    if wrap(ei, "SaveEditData", function(orig)
        return function(self, ...) return true end
    end) then end

    if wrap(ei, "GetWhetherNeedToSave", function(orig)
        return function(self, ...) return false end
    end) then end

    -- Blockers
    for _, fn in ipairs({
        "GetSaveFailAfterTriggeredReq", "ShowSaveFailedPopup",
        "ShowUnlockFailedPopup", "ShowUnlockSlotPopup",
        "CheckIsShowUnlockPopup",
    }) do
        if type(ei[fn]) == "function" then
            wrap(ei, fn, function(orig)
                return function(self, ...) 
                    if fn == "GetSaveFailAfterTriggeredReq" then return false end
                    return 
                end
            end)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- FINAL REPORT + POPUP
-- ═══════════════════════════════════════════════════════════════════
local cfgCount = 0
for _, items in pairs(CFG) do
    if type(items) == "table" then
        for _ in pairs(items) do cfgCount = cfgCount + 1 end
    end
end

S("v17_report.txt",
    "v17 REPORT\n" ..
    "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n" ..
    "Reverted: " .. reverted .. "\n" ..
    "Unlocked: " .. unlocked .. "\n" ..
    "Forced getters: " .. forced .. "\n" ..
    "RSP injected: " .. injected .. "\n" ..
    "Config items: " .. cfgCount .. "\n"
)

P("v17 LOADED",
    "Config items: " .. cfgCount .. "\n" ..
    "Forced: " .. forced .. "\n" ..
    "RSP: " .. injected .. "\n\n" ..
    "Config file:\n" .. CONFIG_FILE .. "\n\n" ..
    "Edit karo, reload karo,\n" ..
    "IDs change karo,\n" ..
    "display change hoga")

return true
