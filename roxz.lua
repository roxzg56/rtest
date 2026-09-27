-- ============================================================================
-- PET UNLOCKER v4 — Realskin1 Wardrobe Pattern + Popup + Save File
-- Popup: game load hote hi dikhega
-- Save:  /storage/emulated/0/Android/data/com.pubg.imobile/files/PetUnlocker_save.txt
-- Log:   /storage/emulated/0/Android/data/com.pubg.imobile/files/PetUnlocker_log.txt
-- ============================================================================

if _G.__PetUnlockerV4Loaded then return _G.PetUnlocker end
_G.__PetUnlockerV4Loaded = true

_G.PetUnlocker = _G.PetUnlocker or {}
local PU = _G.PetUnlocker

-- ============================================================================
-- PATHS (user-specified)
-- ============================================================================
local DIR       = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"
local SAVE_FILE = "PetUnlocker_save.txt"
local LOG_FILE  = "PetUnlocker_log.txt"

local function readFile(name)
    local f = io.open(DIR .. name, "r")
    if not f then return nil end
    local c = f:read("*a") f:close()
    return c
end

local function writeFile(name, content)
    local f = io.open(DIR .. name, "w")
    if not f then return false end
    f:write(content or "") f:close()
    return true
end

-- ============================================================================
-- CONFIG
-- ============================================================================
_G.PetConfig = _G.PetConfig or {
    Enabled          = true,
    ForceEquippedPet = 50006,
    MaxLevel         = 6,
    ShowPopup        = true,
}

-- ============================================================================
-- LOG
-- ============================================================================
local logBuf = {}
local function plog(msg)
    msg = "[" .. os.date("%H:%M:%S") .. "] " .. tostring(msg)
    print("[PetUnlocker] " .. msg)
    logBuf[#logBuf+1] = msg
    if #logBuf % 5 == 0 then
        pcall(function() writeFile(LOG_FILE, table.concat(logBuf, "\n")) end)
    end
end
local function flushLog() pcall(function() writeFile(LOG_FILE, table.concat(logBuf, "\n")) end) end

-- ============================================================================
-- SAVE / LOAD (like Realskin1)
-- ============================================================================
local function saveState()
    local lines = {
        "equip_pet=" .. tostring(_G.PetConfig.ForceEquippedPet),
        "level=" .. tostring(_G.PetConfig.MaxLevel),
        "last_apply=" .. tostring(os.time()),
        "applied=1",
    }
    local ok = writeFile(SAVE_FILE, table.concat(lines, "\n"))
    if ok then plog("State saved to " .. SAVE_FILE) else plog("!! save write fail") end
    return ok
end

local function loadState()
    local content = readFile(SAVE_FILE)
    if not content or content == "" then
        plog("No save file — fresh start")
        return false
    end
    for k, v in content:gmatch("([%w_]+)=([^\n]+)") do
        local n = tonumber(v)
        if k == "equip_pet" and n then _G.PetConfig.ForceEquippedPet = n end
        if k == "level" and n then _G.PetConfig.MaxLevel = n end
    end
    plog("Save loaded: pet=" .. tostring(_G.PetConfig.ForceEquippedPet)
        .. " level=" .. tostring(_G.PetConfig.MaxLevel))
    return true
end

-- ============================================================================
-- POPUP / NOTIFICATION
-- ============================================================================
local popupShown = false
local function showPopup(success, detail)
    if not _G.PetConfig.ShowPopup then return end
    if popupShown then return end
    popupShown = true

    local title = "PET UNLOCKER v4"
    local body
    if success then
        body = "✅ SCRIPT CHALI\n\n" .. tostring(detail or "") ..
               "\n\nSave: " .. SAVE_FILE ..
               "\nLog:  " .. LOG_FILE
    else
        body = "⚠️ SCRIPT CHALI LEKIN\n\n" .. tostring(detail or "Pet system not found")
    end

    -- Try message box first (big popup)
    pcall(function()
        local Msg = require("client.slua.logic.common.logic_common_msg_box")
        if Msg and Msg.Show then
            Msg.Show(1, title, body,
                function() end,
                function() end,
                "OK", "CLOSE")
            return
        end
    end)

    -- Fallback: notice toast
    pcall(function()
        if ShowNotice then ShowNotice("[" .. title .. "] " .. body, true) end
    end)

    plog("Popup shown: " .. tostring(success))
end

-- ============================================================================
-- PET IDs (from PetInfoDefine)
-- ============================================================================
local PET_IDS = {
    50000,50001,50002,50003,50004,50005,50006,50007,50008,50009,
    50010,50011,50012,50013,50014,50015,50016,50017,50018,50019,
    50020,50021,50022,50023,50024,50025,50026,50027,50028,50029,
    50030,50031,50032,50033,50034,50035,50036,50037,50038,50039,
    50040,50041,50042,50043,50044,50045,50046,50047,50048,
}
local PET_SET = {}
for _, id in ipairs(PET_IDS) do PET_SET[id] = true end

-- ============================================================================
-- WARDROBE INJECT (EXACT Realskin1 PATTERN)
-- ============================================================================
local INS_BASE = 2000000000
local R = { insToRes = {}, resToIns = {} }  -- maps

local function getEntity()
    local ok, dc = pcall(require, "client.slua.logic.wardrobe.logic_wardrobe_data_center")
    if not ok or not dc then return nil end
    local ok2, e = pcall(dc.GetWardrobeData)
    return ok2 and e or nil
end

local function alreadyHave(entity, resID)
    local arr = entity.ResIDToIndexArrayMap and entity.ResIDToIndexArrayMap[resID]
    if not arr then return false end
    for _, idx in pairs(arr) do
        local d = entity._data[idx]
        if d and d.count and d.count > 0 then return true end
    end
    return false
end

local function injectOne(entity, resID, insID)
    if alreadyHave(entity, resID) then
        -- Find existing insID
        local arr = entity.ResIDToIndexArrayMap[resID]
        for _, idx in pairs(arr) do
            local d = entity._data[idx]
            if d and d.count and d.count > 0 then
                local existing = tonumber(d.instid or d.insID)
                if existing then
                    R.insToRes[existing] = resID
                    R.resToIns[resID] = existing
                end
                return existing or insID
            end
        end
        return insID
    end
    entity:AddData({
        instid      = insID,
        res_id      = resID,
        count       = 1,
        lock_cnt    = 0,
        isnew       = 0,
        valid_hours = 0,
        expire_ts   = 0,
    })
    R.insToRes[insID] = resID
    R.resToIns[resID] = insID
    return insID
end

local function injectAllPets()
    local entity = getEntity()
    if not entity or not entity.bInit then
        plog("entity not ready (bInit=" .. tostring(entity and entity.bInit) .. ")")
        return 0
    end
    local n = 0
    for i, resID in ipairs(PET_IDS) do
        local insID = INS_BASE + i + 9000000  -- offset from skin insIDs to avoid clash
        pcall(function()
            injectOne(entity, resID, insID)
            n = n + 1
        end)
    end
    plog("Injected " .. n .. " pets into wardrobe depot")
    return n
end

-- ============================================================================
-- WARDROBE HOOKS (so pets are recognised as owned)
-- ============================================================================
local function hookWardrobe()
    local W = package.loaded["client.slua.logic.wardrobe.wardrobe_data"]
    if not W then
        local ok, m = pcall(require, "client.slua.logic.wardrobe.wardrobe_data")
        if ok then W = m end
    end
    if not W or W.__PetUnlockerHooked then return false end
    W.__PetUnlockerHooked = true

    local function isPetRes(id) return PET_SET[tonumber(id)] end
    local function isPetIns(id) return R.insToRes[tonumber(id)] ~= nil end

    local o1 = W.GetValidHallDepotItemDataByInsID
    if o1 then W.GetValidHallDepotItemDataByInsID = function(self, insID, ...)
        if isPetIns(insID) then
            local entity = getEntity()
            if entity then
                local d = entity:GetDataByInsID(insID)
                if d then return d end
            end
        end
        return o1(self, insID, ...)
    end end

    local o2 = W.GetHallDepotItemDataByInsID
    if o2 then W.GetHallDepotItemDataByInsID = function(self, insID, ...)
        if isPetIns(insID) then
            local entity = getEntity()
            if entity then
                local d = entity:GetDataByInsID(insID)
                if d then return d end
            end
        end
        return o2(self, insID, ...)
    end end

    if W.HasItem then
        local oH = W.HasItem
        W.HasItem = function(self, id, ...)
            if isPetRes(id) or isPetIns(id) then return true end
            return oH(self, id, ...)
        end
    end
    if W.HasValidItem then
        local oV = W.HasValidItem
        W.HasValidItem = function(self, id, ...)
            if isPetRes(id) or isPetIns(id) then return true end
            return oV(self, id, ...)
        end
    end
    if W.CheckHasPermanentItem then
        local oP = W.CheckHasPermanentItem
        W.CheckHasPermanentItem = function(self, id, ...)
            if isPetRes(id) or isPetIns(id) then return true end
            return oP(self, id, ...)
        end
    end

    plog("wardrobe hooked")
    return true
end

-- ============================================================================
-- LOGIC_PET HOOKS (real module path from dump)
-- ============================================================================
local function getLogicPet()
    return package.loaded["client.slua.logic.pet.logic_pet"]
end

local function buildFakePetData(petItemID)
    petItemID = tonumber(petItemID)
    if not petItemID or not PET_SET[petItemID] then return nil end
    return {
        petItemID = petItemID, PetItemID = petItemID,
        PetID = petItemID, petID = petItemID,
        Level = _G.PetConfig.MaxLevel, level = _G.PetConfig.MaxLevel,
        Exp = 0, exp = 0,
        IsEquipped = false, bIsEquipped = false,
        expireTS = 0, expire_ts = 0, ExpireTime = 0, ValidTime = 0,
        Count = 1, count = 1,
        OwnedTime = 0, LastUseTime = 0,
        bIsNew = false, IsNew = false,
        SkinID = 0, skinID = 0,
    }
end

local function hookLogicPet()
    local L = getLogicPet()
    if not L then plog("!! logic_pet NOT loaded") return false end
    if L.__PetUnlockerHooked then return true end
    L.__PetUnlockerHooked = true

    -- Force MyPetInfo (like Realskin1 forces equipped cache)
    L.MyPetInfo = L.MyPetInfo or {}
    L.MyPetInfo.equip_pet_id    = _G.PetConfig.ForceEquippedPet
    L.MyPetInfo.equip_pet_level = _G.PetConfig.MaxLevel
    L.MyPetInfo.show_pet        = true
    L.MyPetInfo.bShowPet        = true
    L.MyPetInfo.bShowMyPet      = true
    L.MyPetInfo.owned_pets      = PET_IDS
    L.MyPetInfo.pet_levels      = L.MyPetInfo.pet_levels or {}
    for _, id in ipairs(PET_IDS) do
        L.MyPetInfo.pet_levels[id] = _G.PetConfig.MaxLevel
    end
    plog("logic_pet.MyPetInfo forced: pet=" .. tostring(L.MyPetInfo.equip_pet_id))

    local impl = L.__inner_impl or L
    if type(impl) ~= "table" then return true end

    local function wrap(name, fn)
        if type(impl[name]) == "function" and not impl["__PU_" .. name] then
            impl["__PU_" .. name] = impl[name]
            impl[name] = fn(impl["__PU_" .. name])
            plog("wrapped logic_pet." .. name)
        end
    end

    wrap("GetMyPetData", function(orig)
        return function(self, ...)
            local fake = buildFakePetData(_G.PetConfig.ForceEquippedPet)
            if fake then return fake end
            return orig(self, ...)
        end
    end)
    wrap("IsMaxLevel", function(orig)
        return function(self, petID, ...)
            if PET_SET[tonumber(petID)] then return true end
            return orig(self, petID, ...)
        end
    end)
    wrap("EnablePetFeature", function(orig)
        return function(self, ...) return true end
    end)
    wrap("IsPetStartAccessible", function(orig)
        return function(self, ...) return true end
    end)
    wrap("IsPetInAccessibleTime", function(orig)
        return function(self, ...) return true end
    end)
    wrap("IsOutOfAccessibleEndTime", function(orig)
        return function(self, ...) return false end
    end)
    wrap("GetPetListIncludeInherit", function(orig)
        return function(self, ...)
            local out = {}
            for _, id in ipairs(PET_IDS) do out[#out+1] = id end
            return out
        end
    end)

    return true
end

-- ============================================================================
-- TLogicPetData HOOKS (real module path from dump)
-- ============================================================================
local function hookPetData()
    local T = package.loaded["client.slua.logic.pet.traits.TLogicPetData"]
    if not T then plog("!! TLogicPetData NOT loaded") return false end
    if T.__PetUnlockerHooked then return true end
    T.__PetUnlockerHooked = true

    local impl = T.__inner_impl or T

    local function wrap(name, fn)
        if type(impl[name]) == "function" and not impl["__PU_" .. name] then
            impl["__PU_" .. name] = impl[name]
            impl[name] = fn(impl["__PU_" .. name])
            plog("wrapped TLogicPetData." .. name)
        end
    end

    wrap("HasPet", function(orig)
        return function(self, petItemID, ...)
            if PET_SET[tonumber(petItemID)] then return true end
            return orig(self, petItemID, ...)
        end
    end)
    wrap("HasPetPermanently", function(orig)
        return function(self, petItemID, ...)
            if PET_SET[tonumber(petItemID)] then return true end
            return orig(self, petItemID, ...)
        end
    end)
    wrap("HasPetIncludeInherit", function(orig)
        return function(self, petItemID, ...)
            if PET_SET[tonumber(petItemID)] then return true end
            return orig(self, petItemID, ...)
        end
    end)
    wrap("HavePermanentPet", function(orig)
        return function(self, ...) return true end
    end)
    wrap("GetOwnedPetList", function(orig)
        return function(self, ...) return PET_IDS end
    end)
    wrap("GetOwnedPetItemIDByPetID", function(orig)
        return function(self, petID, ...)
            if PET_SET[tonumber(petID)] then return petID end
            return orig(self, petID, ...)
        end
    end)
    wrap("GetPetDataByPetItemID", function(orig)
        return function(self, petItemID, ...)
            local fake = buildFakePetData(petItemID)
            if fake then return fake end
            return orig(self, petItemID, ...)
        end
    end)
    wrap("GetMyPetLevel", function(orig)
        return function(self, petItemID, ...)
            if PET_SET[tonumber(petItemID)] then return _G.PetConfig.MaxLevel end
            return orig(self, petItemID, ...)
        end
    end)
    wrap("GetMaxCarryPetCount", function(orig)
        return function(self, ...) return 6 end
    end)
    wrap("HasEquipedPet", function(orig)
        return function(self, ...) return true end
    end)
    wrap("GetEquipedPetItemID", function(orig)
        return function(self, ...)
            local force = _G.PetConfig.ForceEquippedPet
            if PET_SET[force] then return force end
            return orig(self, ...)
        end
    end)
    wrap("GetEquipedPetInsID", function(orig)
        return function(self, ...)
            local force = _G.PetConfig.ForceEquippedPet
            if PET_SET[force] then return force * 1000 end
            return orig(self, ...)
        end
    end)
    wrap("IsPetEquip", function(orig)
        return function(self, petItemID, ...)
            if tonumber(petItemID) == _G.PetConfig.ForceEquippedPet then return true end
            return orig(self, petItemID, ...)
        end
    end)
    -- freeze/expiry checks -> false
    for _, fn in ipairs({"IsPetFrozen","IsPetDressFrozen","IsPetTimeLimitedOwning",
                         "IsDressTimeLimitedOwning","IsInheritPet"}) do
        wrap(fn, function(orig) return function(self, ...) return false end end)
    end
    -- dress checks -> true
    for _, fn in ipairs({"HasPetDress","HasValidPetDress","HasPetActionDress",
                         "HasPetDressPermanently","HasExpandSlotPriv"}) do
        wrap(fn, function(orig) return function(self, ...) return true end end)
    end

    return true
end

-- ============================================================================
-- TLogicPetCfg HOOKS
-- ============================================================================
local function hookPetCfg()
    local T = package.loaded["client.slua.logic.pet.traits.TLogicPetCfg"]
    if not T then plog("!! TLogicPetCfg NOT loaded") return false end
    if T.__PetUnlockerHooked then return true end
    T.__PetUnlockerHooked = true

    local impl = T.__inner_impl or T

    local function wrap(name, fn)
        if type(impl[name]) == "function" and not impl["__PU_" .. name] then
            impl["__PU_" .. name] = impl[name]
            impl[name] = fn(impl["__PU_" .. name])
            plog("wrapped TLogicPetCfg." .. name)
        end
    end

    wrap("IsPetItemID", function(orig)
        return function(self, id, ...)
            if PET_SET[tonumber(id)] then return true end
            return orig(self, id, ...)
        end
    end)
    wrap("IsPetIDBlocked", function(orig)
        return function(self, id, ...)
            if PET_SET[tonumber(id)] then return false end
            return orig(self, id, ...)
        end
    end)
    wrap("IsPetItemValid", function(orig)
        return function(self, id, ...)
            if PET_SET[tonumber(id)] then return true end
            return orig(self, id, ...)
        end
    end)
    wrap("IsUpgradablePet", function(orig)
        return function(self, id, ...)
            if PET_SET[tonumber(id)] then return true end
            return orig(self, id, ...)
        end
    end)

    return true
end

-- ============================================================================
-- PC + CHAR HOOKS
-- ============================================================================
local function hookPC()
    local ok, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if not ok then return false end
    local pc = GD.GetPlayerController and GD.GetPlayerController()
    if not slua.isValid(pc) then return false end
    local force = _G.PetConfig.ForceEquippedPet

    pcall(function()
        pc.PetID      = force
        pc.nPetID     = force
        pc.PetLevel   = _G.PetConfig.MaxLevel
        pc.nPetLevel  = _G.PetConfig.MaxLevel
        pc.bShowMyPet = true
        pc.bPetVisible = true
    end)

    if pc.__PetUnlockerPC then return true end
    pc.__PetUnlockerPC = true

    for _, fn in ipairs({"GetPetID","GetShowPetID","GetPetId","GetCurPetID"}) do
        if type(pc[fn]) == "function" then
            pc[fn] = function(self, ...) return force end
        end
    end
    for _, fn in ipairs({"GetPetLevel","GetCurPetLevel"}) do
        if type(pc[fn]) == "function" then
            pc[fn] = function(self, ...) return _G.PetConfig.MaxLevel end
        end
    end
    for _, fn in ipairs({"IsShowPet","IsPetVisible","GetShowMyPet"}) do
        if type(pc[fn]) == "function" then
            pc[fn] = function(self, ...) return true end
        end
    end

    plog("PC hooked")
    return true
end

local function hookChar()
    local ok, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if not ok then return false end
    local pc = GD.GetPlayerController and GD.GetPlayerController()
    if not slua.isValid(pc) then return false end
    local c = pc.GetPlayerCharacterSafety and pc:GetPlayerCharacterSafety()
    if not slua.isValid(c) then return false end
    if c.__PetUnlockerChar then return true end
    c.__PetUnlockerChar = true

    local force = _G.PetConfig.ForceEquippedPet
    pcall(function()
        c.PetID      = force
        c.nPetID     = force
        c.PetLevel   = _G.PetConfig.MaxLevel
        c.bShowMyPet = true
    end)

    plog("char hooked")
    return true
end

-- ============================================================================
-- MAIN APPLY
-- ============================================================================
local applied = false
local function apply()
    if not _G.PetConfig.Enabled then return end
    plog("=== APPLY v4 ===")

    local n = injectAllPets()
    hookWardrobe()
    hookLogicPet()
    hookPetData()
    hookPetCfg()
    hookPC()
    hookChar()

    applied = true
    saveState()
    plog("=== DONE — pets=" .. tostring(n) .. " ===")
    flushLog()
end

-- ============================================================================
-- BOOT
-- ============================================================================
loadState()

local function waitAndBoot(n)
    n = n or 0
    local uid = DataMgr and DataMgr.roleData and tonumber(DataMgr.roleData.uid)
    if uid and uid > 0 then
        apply()
        later(1, apply)
        later(3, apply)
        later(6, apply)
        later(12, apply)
        later(20, apply)
        later(40, apply)
        -- show popup once
        later(2, function()
            local L = getLogicPet()
            local detail = "Pets: " .. #PET_IDS .. "\nLogicPet: " .. (L and "OK" or "MISSING")
            showPopup(true, detail)
        end)
        return
    end
    if n < 80 then later(0.5, function() waitAndBoot(n + 1) end) end
end

local function later(sec, fn)
    pcall(function()
        if _G.SetTimer then _G.SetTimer(sec, fn)
        else
            local tt = require("common.time_ticker")
            if tt and tt.AddTimerOnce then tt.AddTimerOnce(sec, fn) end
        end
    end)
end

waitAndBoot(0)

pcall(function()
    if EventSystem and EventSystem.registEvent and EVENTTYPE_STATE and EVENTID_ON_MODE_POST_SWITCH then
        EventSystem:registEvent(EVENTTYPE_STATE, EVENTID_ON_MODE_POST_SWITCH, function()
            later(0.5, apply)
            later(2, apply)
        end)
    end
end)

pcall(function()
    local tt = require("common.time_ticker")
    if tt and tt.AddTimerLoop then
        tt.AddTimerLoop(0, function()
            if not applied then return end
            hookPC()
            hookChar()
        end, -1, 3.0)
    end
end)

-- ============================================================================
-- PUBLIC API
-- ============================================================================
PU.ApplyNow   = apply
PU.Save       = saveState
PU.GetPets    = function() return PET_IDS end
PU.GetLog     = function() return logBuf end
PU.SetPet     = function(id)
    id = tonumber(id)
    if PET_SET[id] then
        _G.PetConfig.ForceEquippedPet = id
        apply()
    end
end
PU.SetLevel   = function(lvl)
    _G.PetConfig.MaxLevel = tonumber(lvl) or 6
    apply()
end
PU.ShowPopup  = function(success, detail)
    popupShown = false
    showPopup(success, detail)
end

plog("PetUnlocker v4 loaded — pets=" .. #PET_IDS)
plog("Save: " .. DIR .. SAVE_FILE)
plog("Log:  " .. DIR .. LOG_FILE)
flushLog()

return _G.PetUnlocker
