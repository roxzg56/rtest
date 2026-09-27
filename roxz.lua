-- ============================================================================
-- PET UNLOCKER — PURE LUA (no C++ wrapper, direct load)
-- Save: /storage/emulated/0/Android/data/com.pubg.imobile/files/PetUnlocker_save.txt
-- ============================================================================

-- ===== PROOF OF LOAD (pehla print — agar yeh dikhe, file chali) =====
print("===========================================")
print("  PET UNLOCKER — FILE LOADED SUCCESSFULLY")
print("  Time: " .. os.date("%Y-%m-%d %H:%M:%S"))
print("===========================================")

-- Guard
if _G.__PetUnlockerPureLoaded then
    print("[PetUnlocker] Already loaded — reapplying...")
    if _G.PetUnlocker and _G.PetUnlocker.ApplyNow then
        pcall(_G.PetUnlocker.ApplyNow)
    end
    return _G.PetUnlocker
end
_G.__PetUnlockerPureLoaded = true

_G.PetUnlocker = _G.PetUnlocker or {}
local PU = _G.PetUnlocker

-- ============================================================================
-- PATHS
-- ============================================================================
local DIR       = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"
local SAVE_FILE = DIR .. "PetUnlocker_save.txt"
local LOG_FILE  = DIR .. "PetUnlocker_log.txt"

local logBuf = {}
local function plog(msg)
    local line = "[" .. os.date("%H:%M:%S") .. "] " .. tostring(msg)
    print("[PetUnlocker] " .. line)
    logBuf[#logBuf+1] = line
    pcall(function()
        local f = io.open(LOG_FILE, "w")
        if f then f:write(table.concat(logBuf, "\n")) f:close() end
    end)
end

local function writeSave(data)
    pcall(function()
        local f = io.open(SAVE_FILE, "w")
        if f then f:write(data) f:close() end
    end)
end

plog("=== PURE LUA BOOT ===")
plog("DIR: " .. DIR)

-- ============================================================================
-- CONFIG
-- ============================================================================
_G.PetConfig = _G.PetConfig or {
    Enabled          = true,
    ForceEquippedPet = 50006,
    MaxLevel         = 6,
}

-- ============================================================================
-- POPUP (guaranteed visible)
-- ============================================================================
local popupShown = false
local function showPopup(ok, detail)
    if popupShown then return end
    popupShown = true

    local title = "PET UNLOCKER — LOADED"
    local body = (ok and "✅ FILE CHALI\n\n" or "⚠️ PARTIAL\n\n")
              .. tostring(detail or "")
              .. "\n\nSave: PetUnlocker_save.txt"
              .. "\nLog: PetUnlocker_log.txt"

    -- Try msg box
    local shown = false
    pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
            or require("client.slua.logic.common.logic_common_msg_box")
        if Msg and Msg.Show then
            Msg.Show(1, title, body, function() end, function() end, "OK", "CLOSE")
            shown = true
        end
    end)

    -- Fallback: ShowNotice
    if not shown then
        pcall(function()
            if ShowNotice then
                ShowNotice("[" .. title .. "] " .. tostring(detail), true)
                shown = true
            end
        end)
    end

    plog("Popup shown: " .. tostring(shown))
end

-- ============================================================================
-- PET IDs
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

plog("Pets in list: " .. #PET_IDS)

-- ============================================================================
-- FAKE PET DATA BUILDER
-- ============================================================================
local function fakePetData(petItemID)
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

-- ============================================================================
-- HOOK 1: logic_pet (direct MyPetInfo override)
-- ============================================================================
local function getLogicPet()
    return package.loaded["client.slua.logic.pet.logic_pet"]
end

local function hookLogicPet()
    local L = getLogicPet()
    if not L then
        plog("!! logic_pet NOT loaded yet")
        return false
    end
    plog("logic_pet found")

    -- Direct table override
    L.MyPetInfo = L.MyPetInfo or {}
    L.MyPetInfo.equip_pet_id    = _G.PetConfig.ForceEquippedPet
    L.MyPetInfo.equip_pet_level = _G.PetConfig.MaxLevel
    L.MyPetInfo.show_pet        = true
    L.MyPetInfo.bShowPet        = true
    L.MyPetInfo.bShowMyPet      = true

    plog("MyPetInfo forced: pet=" .. tostring(L.MyPetInfo.equip_pet_id)
        .. " lvl=" .. tostring(L.MyPetInfo.equip_pet_level))

    -- Wrap __inner_impl methods (only once)
    if L.__PUwrapped then return true end
    L.__PUwrapped = true

    local impl = L.__inner_impl or L
    if type(impl) ~= "table" then return true end

    local function wrap(name, fn)
        if type(impl[name]) == "function" and not impl["__PU_" .. name] then
            impl["__PU_" .. name] = impl[name]
            impl[name] = fn(impl["__PU_" .. name])
            plog("  wrap logic_pet." .. name)
        end
    end

    wrap("GetMyPetData", function(orig)
        return function(self, ...)
            local f = fakePetData(_G.PetConfig.ForceEquippedPet)
            if f then return f end
            return orig(self, ...)
        end
    end)
    wrap("IsMaxLevel", function(orig)
        return function(self, id, ...)
            if PET_SET[tonumber(id)] then return true end
            return orig(self, id, ...)
        end
    end)
    wrap("EnablePetFeature", function(orig) return function() return true end end)
    wrap("IsPetStartAccessible", function(orig) return function() return true end end)
    wrap("IsPetInAccessibleTime", function(orig) return function() return true end end)
    wrap("IsOutOfAccessibleEndTime", function(orig) return function() return false end end)
    wrap("GetPetListIncludeInherit", function(orig)
        return function() return PET_IDS end
    end)

    return true
end

-- ============================================================================
-- HOOK 2: TLogicPetData (ownership / state)
-- ============================================================================
local function hookPetData()
    local T = package.loaded["client.slua.logic.pet.traits.TLogicPetData"]
    if not T then plog("!! TLogicPetData not loaded") return false end
    if T.__PUwrapped then return true end
    T.__PUwrapped = true
    plog("TLogicPetData found, wrapping")

    local impl = T.__inner_impl or T
    if type(impl) ~= "table" then return true end

    local function wrap(name, fn)
        if type(impl[name]) == "function" and not impl["__PU_" .. name] then
            impl["__PU_" .. name] = impl[name]
            impl[name] = fn(impl["__PU_" .. name])
        end
    end

    wrap("HasPet", function(orig)
        return function(self, id, ...)
            if PET_SET[tonumber(id)] then return true end
            return orig(self, id, ...)
        end
    end)
    wrap("HasPetPermanently", function(orig)
        return function(self, id, ...)
            if PET_SET[tonumber(id)] then return true end
            return orig(self, id, ...)
        end
    end)
    wrap("HasPetIncludeInherit", function(orig)
        return function(self, id, ...)
            if PET_SET[tonumber(id)] then return true end
            return orig(self, id, ...)
        end
    end)
    wrap("HavePermanentPet", function() return function() return true end end)
    wrap("GetOwnedPetList", function() return function() return PET_IDS end end)
    wrap("GetOwnedPetItemIDByPetID", function(orig)
        return function(self, id, ...)
            if PET_SET[tonumber(id)] then return id end
            return orig(self, id, ...)
        end
    end)
    wrap("GetPetDataByPetItemID", function(orig)
        return function(self, id, ...)
            local f = fakePetData(id)
            if f then return f end
            return orig(self, id, ...)
        end
    end)
    wrap("GetMyPetLevel", function(orig)
        return function(self, id, ...)
            if PET_SET[tonumber(id)] then return _G.PetConfig.MaxLevel end
            return orig(self, id, ...)
        end
    end)
    wrap("GetMaxCarryPetCount", function() return function() return 6 end end)
    wrap("HasEquipedPet", function() return function() return true end end)
    wrap("GetEquipedPetItemID", function(orig)
        return function(self, ...)
            local f = _G.PetConfig.ForceEquippedPet
            if PET_SET[f] then return f end
            return orig(self, ...)
        end
    end)
    wrap("GetEquipedPetInsID", function(orig)
        return function(self, ...)
            local f = _G.PetConfig.ForceEquippedPet
            if PET_SET[f] then return f * 1000 end
            return orig(self, ...)
        end
    end)
    wrap("IsPetEquip", function(orig)
        return function(self, id, ...)
            if tonumber(id) == _G.PetConfig.ForceEquippedPet then return true end
            return orig(self, id, ...)
        end
    end)
    for _, fn in ipairs({"IsPetFrozen","IsPetDressFrozen","IsPetTimeLimitedOwning",
                         "IsDressTimeLimitedOwning","IsInheritPet"}) do
        wrap(fn, function(orig) return function() return false end end)
    end
    for _, fn in ipairs({"HasPetDress","HasValidPetDress","HasPetActionDress",
                         "HasPetDressPermanently","HasExpandSlotPriv"}) do
        wrap(fn, function(orig) return function() return true end end)
    end

    plog("TLogicPetData wrapped")
    return true
end

-- ============================================================================
-- HOOK 3: TLogicPetCfg
-- ============================================================================
local function hookPetCfg()
    local T = package.loaded["client.slua.logic.pet.traits.TLogicPetCfg"]
    if not T then plog("!! TLogicPetCfg not loaded") return false end
    if T.__PUwrapped then return true end
    T.__PUwrapped = true
    plog("TLogicPetCfg found, wrapping")

    local impl = T.__inner_impl or T
    if type(impl) ~= "table" then return true end

    local function wrap(name, fn)
        if type(impl[name]) == "function" and not impl["__PU_" .. name] then
            impl["__PU_" .. name] = impl[name]
            impl[name] = fn(impl["__PU_" .. name])
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
-- HOOK 4: PetHandler — inject fake data into server sync
-- ============================================================================
local function hookPetHandler()
    local H = package.loaded["client.network.Protocol.PetHandler"]
    if not H then plog("!! PetHandler not loaded") return false end
    if H.__PUwrapped then return true end
    H.__PUwrapped = true
    plog("PetHandler found, wrapping")

    -- on_sync_pet_data is called when server sends pet data.
    -- We inject our pets into the payload.
    if type(H.on_sync_pet_data) == "function" and not H.__PU_sync then
        H.__PU_sync = H.on_sync_pet_data
        H.on_sync_pet_data = function(data, ...)
            pcall(function()
                if type(data) ~= "table" then return end
                -- Try common field names
                local listKey = nil
                for _, k in ipairs({"pet_list","pet_info_list","pets","owned_pets","pet_data"}) do
                    if type(data[k]) == "table" then listKey = k break end
                end
                if not listKey then
                    data.pet_list = {}
                    listKey = "pet_list"
                end
                local existing = {}
                for _, v in ipairs(data[listKey]) do
                    local id = tonumber(v.petItemID or v.PetItemID or v.PetID or v.petID)
                    if id then existing[id] = true end
                end
                for _, id in ipairs(PET_IDS) do
                    if not existing[id] then
                        table.insert(data[listKey], fakePetData(id))
                    end
                end
                plog("Injected " .. #PET_IDS .. " pets into on_sync_pet_data")
            end)
            return H.__PU_sync(data, ...)
        end
        plog("  wrap PetHandler.on_sync_pet_data")
    end

    if type(H.on_get_pet_tab_info_rsp) == "function" and not H.__PU_tab then
        H.__PU_tab = H.on_get_pet_tab_info_rsp
        H.on_get_pet_tab_info_rsp = function(data, ...)
            pcall(function()
                if type(data) == "table" then
                    if type(data.pet_list) ~= "table" then data.pet_list = {} end
                    for _, id in ipairs(PET_IDS) do
                        table.insert(data.pet_list, fakePetData(id))
                    end
                end
            end)
            return H.__PU_tab(data, ...)
        end
        plog("  wrap PetHandler.on_get_pet_tab_info_rsp")
    end

    -- Block equip reject (pretend success)
    if type(H.on_equip_pet_rsp) == "function" and not H.__PU_equip then
        H.__PU_equip = H.on_equip_pet_rsp
        H.on_equip_pet_rsp = function(err, ...)
            if err ~= 0 then err = 0 end
            return H.__PU_equip(err, ...)
        end
        plog("  wrap PetHandler.on_equip_pet_rsp (force success)")
    end

    return true
end

-- ============================================================================
-- HOOK 5: PC + Char
-- ============================================================================
local function getPC()
    local ok, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if ok and GD and GD.GetPlayerController then
        return GD.GetPlayerController()
    end
    if slua_GameFrontendHUD then
        return slua_GameFrontendHUD:GetPlayerController()
    end
    return nil
end

local function hookPC()
    local pc = getPC()
    if not slua.isValid(pc) then return false end
    local force = _G.PetConfig.ForceEquippedPet

    pcall(function()
        pc.PetID       = force
        pc.nPetID      = force
        pc.PetLevel    = _G.PetConfig.MaxLevel
        pc.nPetLevel   = _G.PetConfig.MaxLevel
        pc.bShowMyPet  = true
        pc.bPetVisible = true
    end)

    if pc.__PUwrapped then return true end
    pc.__PUwrapped = true

    for _, fn in ipairs({"GetPetID","GetShowPetID","GetPetId","GetCurPetID"}) do
        if type(pc[fn]) == "function" then
            pc[fn] = function() return force end
        end
    end
    for _, fn in ipairs({"GetPetLevel","GetCurPetLevel"}) do
        if type(pc[fn]) == "function" then
            pc[fn] = function() return _G.PetConfig.MaxLevel end
        end
    end
    for _, fn in ipairs({"IsShowPet","IsPetVisible","GetShowMyPet"}) do
        if type(pc[fn]) == "function" then
            pc[fn] = function() return true end
        end
    end

    plog("PC wrapped")
    return true
end

local function hookChar()
    local pc = getPC()
    if not slua.isValid(pc) then return false end
    local c = pc.GetPlayerCharacterSafety and pc:GetPlayerCharacterSafety()
    if not slua.isValid(c) then return false end
    if c.__PUwrapped then return true end
    c.__PUwrapped = true

    local force = _G.PetConfig.ForceEquippedPet
    pcall(function()
        c.PetID      = force
        c.nPetID     = force
        c.PetLevel   = _G.PetConfig.MaxLevel
        c.bShowMyPet = true
    end)

    plog("Char wrapped")
    return true
end

-- ============================================================================
-- MAIN APPLY
-- ============================================================================
local applied = false
local function apply()
    if not _G.PetConfig.Enabled then return end
    plog("=== APPLY ===")

    hookLogicPet()
    hookPetData()
    hookPetCfg()
    hookPetHandler()
    hookPC()
    hookChar()

    applied = true

    -- Save state
    writeSave(
        "equip_pet=" .. tostring(_G.PetConfig.ForceEquippedPet) ..
        "\nlevel=" .. tostring(_G.PetConfig.MaxLevel) ..
        "\nlast_apply=" .. tostring(os.time()) ..
        "\napplied=1\n"
    )
    plog("State saved")
    plog("=== DONE ===")
end

-- ============================================================================
-- BOOT LOOP
-- ============================================================================
local function later(sec, fn)
    pcall(function()
        if _G.SetTimer then _G.SetTimer(sec, fn)
        else
            local tt = require("common.time_ticker")
            if tt and tt.AddTimerOnce then tt.AddTimerOnce(sec, fn) end
        end
    end)
end

-- Immediate first attempt (in case modules already loaded)
apply()

-- Show popup fast (proves file ran)
later(1.5, function()
    local L = getLogicPet()
    local H = package.loaded["client.network.Protocol.PetHandler"]
    local detail = "Pets: " .. #PET_IDS
        .. "\nlogic_pet: " .. (L and "OK" or "MISSING")
        .. "\nPetHandler: " .. (H and "OK" or "MISSING")
    showPopup(true, detail)
end)

-- Wait for UID then reapply repeatedly
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
        return
    end
    if n < 60 then later(0.5, function() waitAndBoot(n + 1) end) end
end
waitAndBoot(0)

-- Reapply on mode switch
pcall(function()
    if EventSystem and EventSystem.registEvent
       and EVENTTYPE_STATE and EVENTID_ON_MODE_POST_SWITCH then
        EventSystem:registEvent(EVENTTYPE_STATE, EVENTID_ON_MODE_POST_SWITCH, function()
            later(0.5, apply)
            later(2, apply)
        end)
    end
end)

-- Periodic rehook
pcall(function()
    local tt = require("common.time_ticker")
    if tt and tt.AddTimerLoop then
        tt.AddTimerLoop(0, function()
            if applied then
                hookPC()
                hookChar()
            end
        end, -1, 3.0)
    end
end)

-- ============================================================================
-- PUBLIC API
-- ============================================================================
PU.ApplyNow  = apply
PU.GetPets   = function() return PET_IDS end
PU.GetLog    = function() return logBuf end
PU.SetPet    = function(id)
    id = tonumber(id)
    if PET_SET[id] then
        _G.PetConfig.ForceEquippedPet = id
        apply()
    end
end
PU.SetLevel  = function(lvl)
    _G.PetConfig.MaxLevel = tonumber(lvl) or 6
    apply()
end
PU.ShowPopup = function()
    popupShown = false
    local L = getLogicPet()
    local H = package.loaded["client.network.Protocol.PetHandler"]
    showPopup(true, "Pets: " .. #PET_IDS
        .. "\nlogic_pet: " .. (L and "OK" or "MISSING")
        .. "\nPetHandler: " .. (H and "OK" or "MISSING"))
end

plog("Boot complete")
plog("Save path: " .. SAVE_FILE)
plog("Log path: " .. LOG_FILE)

print("===========================================")
print("  PET UNLOCKER — BOOT COMPLETE")
print("  Pets: " .. #PET_IDS)
print("  logic_pet: " .. (getLogicPet() and "OK" or "MISSING"))
print("  PetHandler: " .. (package.loaded["client.network.Protocol.PetHandler"] and "OK" or "MISSING"))
print("===========================================")

return _G.PetUnlocker
