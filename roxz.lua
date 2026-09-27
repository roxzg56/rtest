-- ============================================================================
-- PET UNLOCKER v3 — REAL MODULE PATHS (from dump)
-- Log: /storage/emulated/0/Android/data/com.pubg.imobile/files/PetUnlocker_log.txt
-- Real modules: client.slua.logic.pet.logic_pet
--               client.slua.logic.pet.pet_manager
--               client.slua.logic.pet.traits.TLogicPetData
--               client.slua.logic.pet.traits.TLogicPetCfg
--               GameLua.Mod.BRMod.Gameplay.Actor.Pet.LuaPetBase
-- ============================================================================

if _G.__PetUnlockerV3Loaded then return _G.PetUnlocker end
_G.__PetUnlockerV3Loaded = true

_G.PetUnlocker = _G.PetUnlocker or {}
local PU = _G.PetUnlocker

_G.PetConfig = _G.PetConfig or {
    Enabled        = true,
    ForceShowLobby = true,
    ForceShowMatch = true,
    ForceSkinOverride = true,
    ForceEquippedPet  = 50006,   -- from PetInfoDefine
    ForceSkinID       = 0,        -- 0 = keep server skin
    MaxLevel          = 6,
    Debug             = true,
}

-- ============================================================================
-- LOG — FIXED PATH
-- ============================================================================
local LOG_DIR  = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"
local LOG_PATH = LOG_DIR .. "PetUnlocker_log.txt"
local logBuf   = {}

local function plog(msg)
    msg = tostring(msg)
    print("[PetUnlocker] " .. msg)
    if _G.PetConfig.Debug then
        logBuf[#logBuf+1] = "[" .. os.date("%H:%M:%S") .. "] " .. msg
        if #logBuf % 8 == 0 then
            pcall(function()
                local f = io.open(LOG_PATH, "w")
                if f then f:write(table.concat(logBuf, "\n")) f:close() end
            end)
        end
    end
end

local function flushLog()
    pcall(function()
        local f = io.open(LOG_PATH, "w")
        if f then f:write(table.concat(logBuf, "\n")) f:close() end
    end)
end

-- ============================================================================
-- UTILS
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

local function getPC()
    local ok, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if ok and GD and GD.GetPlayerController then
        local pc = GD.GetPlayerController()
        if pc and slua.isValid(pc) then return pc end
    end
    if slua_GameFrontendHUD then
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if pc and slua.isValid(pc) then return pc end
    end
    return nil
end

local function getChar()
    local pc = getPC()
    if slua.isValid(pc) and pc.GetPlayerCharacterSafety then
        local c = pc:GetPlayerCharacterSafety()
        if c and slua.isValid(c) then return c end
    end
    return nil
end

local function getImpl(m) if not m then return nil end return m.__inner_impl or m end

-- ============================================================================
-- PET ID TABLE — from PetInfoDefine dump
-- ============================================================================
local PET_IDS = {
    50000, 50001, 50002, 50003, 50004, 50005, 50006, 50007, 50008, 50009,
    50010, 50011, 50012, 50013, 50014, 50015, 50016, 50017, 50018, 50019,
    50020, 50021, 50022, 50023, 50024, 50025, 50026, 50027, 50028, 50029,
    50030, 50031, 50032, 50033, 50034, 50035, 50036, 50037, 50038, 50039,
    50040, 50041, 50042, 50043, 50044, 50045, 50046, 50047, 50048,
}
local PET_SET = {}
for _, id in ipairs(PET_IDS) do PET_SET[id] = true end

plog("Loaded " .. #PET_IDS .. " pet IDs from PetInfoDefine")

-- ============================================================================
-- REAL MODULE RESOLVERS (using dump-discovered paths)
-- ============================================================================
local function getLogicPet()
    return package.loaded["client.slua.logic.pet.logic_pet"]
end

local function getPetManager()
    -- Direct load first
    local m = package.loaded["client.slua.logic.pet.pet_manager"]
    if m then return m end
    -- Try via registry
    local ok, M = pcall(require, "client.slua.logic.pet.pet_manager")
    if ok and M then return M end
    return nil
end

local function getPetDataTrait()
    local m = package.loaded["client.slua.logic.pet.traits.TLogicPetData"]
    if m then return m end
    local ok, M = pcall(require, "client.slua.logic.pet.traits.TLogicPetData")
    if ok and M then return M end
    return nil
end

local function getPetCfgTrait()
    local m = package.loaded["client.slua.logic.pet.traits.TLogicPetCfg"]
    if m then return m end
    local ok, M = pcall(require, "client.slua.logic.pet.traits.TLogicPetCfg")
    if ok and M then return M end
    return nil
end

local function getPetBase()
    return package.loaded["GameLua.Mod.BRMod.Gameplay.Actor.Pet.LuaPetBase"]
end

local function getPetPawnPool()
    local m = package.loaded["client.slua.logic.pet.pet_pawn_pool"]
    if m then return m end
    local ok, M = pcall(require, "client.slua.logic.pet.pet_pawn_pool")
    if ok and M then return M end
    return nil
end

-- ============================================================================
-- FAKE PET DATA
-- ============================================================================
local function buildFakePetData(petItemID)
    petItemID = tonumber(petItemID)
    if not petItemID or not PET_SET[petItemID] then return nil end
    return {
        petItemID    = petItemID,
        PetItemID    = petItemID,
        PetID        = petItemID,
        petID        = petItemID,
        Level        = _G.PetConfig.MaxLevel,
        level        = _G.PetConfig.MaxLevel,
        Exp          = 0,
        exp          = 0,
        IsEquipped   = false,
        bIsEquipped  = false,
        expireTS     = 0,
        expire_ts    = 0,
        ExpireTime   = 0,
        ValidTime    = 0,
        Count        = 1,
        count        = 1,
        OwnedTime    = 0,
        LastUseTime  = 0,
        bIsNew       = false,
        IsNew        = false,
        SkinID       = 0,
        skinID       = 0,
    }
end

-- ============================================================================
-- HOOK TLogicPetData — the REAL ownership/state trait
-- ============================================================================
local function hookPetDataTrait()
    local T = getPetDataTrait()
    if not T then
        plog("!! TLogicPetData NOT FOUND")
        return false
    end
    if T.__PetUnlockerData then return true end
    T.__PetUnlockerData = true

    local impl = getImpl(T)
    local targets = { T, impl }

    for _, tbl in ipairs(targets) do
        if type(tbl) == "table" then
            -- HasPet(petItemID) -> true
            if type(tbl.HasPet) == "function" and not tbl.__PU_HasPet then
                tbl.__PU_HasPet = tbl.HasPet
                tbl.HasPet = function(self, petItemID, ...)
                    if PET_SET[tonumber(petItemID)] then return true end
                    return tbl.__PU_HasPet(self, petItemID, ...)
                end
                plog("wrapped HasPet")
            end

            -- HavePermanentPet -> true
            if type(tbl.HavePermanentPet) == "function" and not tbl.__PU_HavePermanent then
                tbl.__PU_HavePermanent = tbl.HavePermanentPet
                tbl.HavePermanentPet = function(self, ...)
                    return true
                end
                plog("wrapped HavePermanentPet")
            end

            if type(tbl.HasPetPermanently) == "function" and not tbl.__PU_HasPermanent then
                tbl.__PU_HasPermanent = tbl.HasPetPermanently
                tbl.HasPetPermanently = function(self, petItemID, ...)
                    if PET_SET[tonumber(petItemID)] then return true end
                    return tbl.__PU_HasPermanent(self, petItemID, ...)
                end
            end

            if type(tbl.HasPetIncludeInherit) == "function" and not tbl.__PU_HasIncludeInherit then
                tbl.__PU_HasIncludeInherit = tbl.HasPetIncludeInherit
                tbl.HasPetIncludeInherit = function(self, petItemID, ...)
                    if PET_SET[tonumber(petItemID)] then return true end
                    return tbl.__PU_HasIncludeInherit(self, petItemID, ...)
                end
            end

            -- GetOwnedPetList -> all IDs
            if type(tbl.GetOwnedPetList) == "function" and not tbl.__PU_OwnedList then
                tbl.__PU_OwnedList = tbl.GetOwnedPetList
                tbl.GetOwnedPetList = function(self, ...)
                    return PET_IDS
                end
                plog("wrapped GetOwnedPetList")
            end

            -- GetOwnedPetItemIDByPetID
            if type(tbl.GetOwnedPetItemIDByPetID) == "function" and not tbl.__PU_OwnedByID then
                tbl.__PU_OwnedByID = tbl.GetOwnedPetItemIDByPetID
                tbl.GetOwnedPetItemIDByPetID = function(self, petID, ...)
                    if PET_SET[tonumber(petID)] then return petID end
                    return tbl.__PU_OwnedByID(self, petID, ...)
                end
            end

            -- GetPetDataByPetItemID
            if type(tbl.GetPetDataByPetItemID) == "function" and not tbl.__PU_PetDataByItem then
                tbl.__PU_PetDataByItem = tbl.GetPetDataByPetItemID
                tbl.GetPetDataByPetItemID = function(self, petItemID, ...)
                    local fake = buildFakePetData(petItemID)
                    if fake then return fake end
                    return tbl.__PU_PetDataByItem(self, petItemID, ...)
                end
                plog("wrapped GetPetDataByPetItemID")
            end

            -- GetPetDataByInsID
            if type(tbl.GetPetDataByInsID) == "function" and not tbl.__PU_PetDataByIns then
                tbl.__PU_PetDataByIns = tbl.GetPetDataByInsID
                tbl.GetPetDataByInsID = function(self, insID, ...)
                    -- insID format: petItemID * N (unknown), try reverse
                    local n = tonumber(insID)
                    if n then
                        -- Try petItemID = insID / 1000
                        local guess = math.floor(n / 1000)
                        if PET_SET[guess] then return buildFakePetData(guess) end
                    end
                    return tbl.__PU_PetDataByIns(self, insID, ...)
                end
            end

            -- GetMaxCarryPetCount -> high
            if type(tbl.GetMaxCarryPetCount) == "function" and not tbl.__PU_MaxCarry then
                tbl.__PU_MaxCarry = tbl.GetMaxCarryPetCount
                tbl.GetMaxCarryPetCount = function(self, ...)
                    return 6
                end
            end

            -- GetCurrentCarryCount
            if type(tbl.GetCurrentCarryCount) == "function" and not tbl.__PU_CurCarry then
                tbl.__PU_CurCarry = tbl.GetCurrentCarryCount
                tbl.GetCurrentCarryCount = function(self, ...)
                    return 0
                end
            end

            -- HasEquipedPet -> true
            if type(tbl.HasEquipedPet) == "function" and not tbl.__PU_HasEquip then
                tbl.__PU_HasEquip = tbl.HasEquipedPet
                tbl.HasEquipedPet = function(self, ...)
                    return true
                end
                plog("wrapped HasEquipedPet")
            end

            -- GetEquipedPetItemID -> our forced pet
            if type(tbl.GetEquipedPetItemID) == "function" and not tbl.__PU_EquipItemID then
                tbl.__PU_EquipItemID = tbl.GetEquipedPetItemID
                tbl.GetEquipedPetItemID = function(self, ...)
                    local force = _G.PetConfig.ForceEquippedPet
                    if force and PET_SET[force] then return force end
                    return tbl.__PU_EquipItemID(self, ...)
                end
                plog("wrapped GetEquipedPetItemID")
            end

            -- GetEquipedPetInsID -> deterministic insID for our pet
            if type(tbl.GetEquipedPetInsID) == "function" and not tbl.__PU_EquipInsID then
                tbl.__PU_EquipInsID = tbl.GetEquipedPetInsID
                tbl.GetEquipedPetInsID = function(self, ...)
                    local force = _G.PetConfig.ForceEquippedPet
                    if force and PET_SET[force] then return force * 1000 end
                    return tbl.__PU_EquipInsID(self, ...)
                end
            end

            -- IsPetEquip
            if type(tbl.IsPetEquip) == "function" and not tbl.__PU_IsEquip then
                tbl.__PU_IsEquip = tbl.IsPetEquip
                tbl.IsPetEquip = function(self, petItemID, ...)
                    local force = _G.PetConfig.ForceEquippedPet
                    if tonumber(petItemID) == force then return true end
                    return tbl.__PU_IsEquip(self, petItemID, ...)
                end
            end

            -- GetMyPetLevel -> max
            if type(tbl.GetMyPetLevel) == "function" and not tbl.__PU_MyLevel then
                tbl.__PU_MyLevel = tbl.GetMyPetLevel
                tbl.GetMyPetLevel = function(self, petItemID, ...)
                    if PET_SET[tonumber(petItemID)] then return _G.PetConfig.MaxLevel end
                    return tbl.__PU_MyLevel(self, petItemID, ...)
                end
            end

            -- Freeze/expiry checks -> false
            for _, fn in ipairs({"IsPetFrozen", "IsPetDressFrozen", "IsPetTimeLimitedOwning",
                                 "IsDressTimeLimitedOwning", "IsInheritPet"}) do
                if type(tbl[fn]) == "function" and not tbl["__PU_" .. fn] then
                    tbl["__PU_" .. fn] = tbl[fn]
                    tbl[fn] = function(self, ...) return false end
                end
            end

            -- HasPetDress / HasValidPetDress / HasPetActionDress -> true
            for _, fn in ipairs({"HasPetDress", "HasValidPetDress", "HasPetActionDress",
                                 "HasPetDressPermanently", "HasExpandSlotPriv"}) do
                if type(tbl[fn]) == "function" and not tbl["__PU_" .. fn] then
                    tbl["__PU_" .. fn] = tbl[fn]
                    tbl[fn] = function(self, ...) return true end
                end
            end
        end
    end

    return true
end

-- ============================================================================
-- HOOK TLogicPetCfg — validity/blocking trait
-- ============================================================================
local function hookPetCfgTrait()
    local T = getPetCfgTrait()
    if not T then
        plog("!! TLogicPetCfg NOT FOUND")
        return false
    end
    if T.__PetUnlockerCfg then return true end
    T.__PetUnlockerCfg = true

    local impl = getImpl(T)
    for _, tbl in ipairs({ T, impl }) do
        if type(tbl) == "table" then
            if type(tbl.IsPetItemID) == "function" and not tbl.__PU_IsPetItemID then
                tbl.__PU_IsPetItemID = tbl.IsPetItemID
                tbl.IsPetItemID = function(self, itemID, ...)
                    if PET_SET[tonumber(itemID)] then return true end
                    return tbl.__PU_IsPetItemID(self, itemID, ...)
                end
                plog("wrapped IsPetItemID")
            end

            if type(tbl.IsPetIDBlocked) == "function" and not tbl.__PU_IDBlocked then
                tbl.__PU_IDBlocked = tbl.IsPetIDBlocked
                tbl.IsPetIDBlocked = function(self, petID, ...)
                    if PET_SET[tonumber(petID)] then return false end
                    return tbl.__PU_IDBlocked(self, petID, ...)
                end
                plog("wrapped IsPetIDBlocked")
            end

            if type(tbl.IsPetItemValid) == "function" and not tbl.__PU_ItemValid then
                tbl.__PU_ItemValid = tbl.IsPetItemValid
                tbl.IsPetItemValid = function(self, itemID, ...)
                    if PET_SET[tonumber(itemID)] then return true end
                    return tbl.__PU_ItemValid(self, itemID, ...)
                end
                plog("wrapped IsPetItemValid")
            end

            if type(tbl.GetPetCfgs) == "function" and not tbl.__PU_GetCfgs then
                tbl.__PU_GetCfgs = tbl.GetPetCfgs
                tbl.GetPetCfgs = function(self, ...)
                    local r = tbl.__PU_GetCfgs(self, ...)
                    if type(r) == "table" and next(r) then return r end
                    local out = {}
                    for _, id in ipairs(PET_IDS) do
                        out[id] = { PetID = id, PetItemID = id, Level = _G.PetConfig.MaxLevel }
                    end
                    return out
                end
            end

            if type(tbl.IsUpgradablePet) == "function" and not tbl.__PU_Upgradable then
                tbl.__PU_Upgradable = tbl.IsUpgradablePet
                tbl.IsUpgradablePet = function(self, petID, ...)
                    if PET_SET[tonumber(petID)] then return true end
                    return tbl.__PU_Upgradable(self, petID, ...)
                end
            end

            if type(tbl.GetPetLevelCfg) == "function" and not tbl.__PU_LevelCfg then
                tbl.__PU_LevelCfg = tbl.GetPetLevelCfg
                tbl.GetPetLevelCfg = function(self, petID, level, ...)
                    local r = tbl.__PU_LevelCfg(self, petID, level, ...)
                    if r then return r end
                    if PET_SET[tonumber(petID)] then
                        return { PetID = petID, Level = level or _G.PetConfig.MaxLevel,
                                 NeedExp = 0, AddExp = 0 }
                    end
                    return r
                end
            end
        end
    end

    return true
end

-- ============================================================================
-- HOOK logic_pet top-level — MyPetInfo + state
-- ============================================================================
local function hookLogicPet()
    local L = getLogicPet()
    if not L then
        plog("!! logic_pet NOT FOUND")
        return false
    end
    if L.__PetUnlockerLogic then return true end
    L.__PetUnlockerLogic = true

    -- Force MyPetInfo
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

    plog("logic_pet.MyPetInfo forced: pet=" .. tostring(L.MyPetInfo.equip_pet_id)
        .. " lvl=" .. tostring(L.MyPetInfo.equip_pet_level)
        .. " owned=" .. tostring(#PET_IDS))

    -- Hook __inner_impl methods
    local impl = getImpl(L)
    if type(impl) == "table" then
        -- GetMyPetData -> return our pet
        if type(impl.GetMyPetData) == "function" and not impl.__PU_GetMyPetData then
            impl.__PU_GetMyPetData = impl.GetMyPetData
            impl.GetMyPetData = function(self, ...)
                local fake = buildFakePetData(_G.PetConfig.ForceEquippedPet)
                if fake then return fake end
                return impl.__PU_GetMyPetData(self, ...)
            end
            plog("wrapped logic_pet.GetMyPetData")
        end

        -- IsMaxLevel -> true
        if type(impl.IsMaxLevel) == "function" and not impl.__PU_IsMax then
            impl.__PU_IsMax = impl.IsMaxLevel
            impl.IsMaxLevel = function(self, petID, ...)
                if PET_SET[tonumber(petID)] then return true end
                return impl.__PU_IsMax(self, petID, ...)
            end
            plog("wrapped logic_pet.IsMaxLevel")
        end

        -- GetPetListIncludeInherit -> all
        if type(impl.GetPetListIncludeInherit) == "function" and not impl.__PU_ListInherit then
            impl.__PU_ListInherit = impl.GetPetListIncludeInherit
            impl.GetPetListIncludeInherit = function(self, ...)
                local out = {}
                for _, id in ipairs(PET_IDS) do out[#out+1] = id end
                return out
            end
        end

        -- EnablePetFeature -> true
        if type(impl.EnablePetFeature) == "function" and not impl.__PU_Enable then
            impl.__PU_Enable = impl.EnablePetFeature
            impl.EnablePetFeature = function(self, ...)
                return true
            end
        end

        -- IsPetStartAccessible -> true
        if type(impl.IsPetStartAccessible) == "function" and not impl.__PU_StartAccess then
            impl.__PU_StartAccess = impl.IsPetStartAccessible
            impl.IsPetStartAccessible = function(self, ...) return true end
        end

        -- IsPetInAccessibleTime -> true
        if type(impl.IsPetInAccessibleTime) == "function" and not impl.__PU_InAccessTime then
            impl.__PU_InAccessTime = impl.IsPetInAccessibleTime
            impl.IsPetInAccessibleTime = function(self, ...) return true end
        end

        -- IsOutOfAccessibleEndTime -> false
        if type(impl.IsOutOfAccessibleEndTime) == "function" and not impl.__PU_OutAccessTime then
            impl.__PU_OutAccessTime = impl.IsOutOfAccessibleEndTime
            impl.IsOutOfAccessibleEndTime = function(self, ...) return false end
        end
    end

    return true
end

-- ============================================================================
-- HOOK pet_manager — lobby spawn
-- ============================================================================
local function hookPetManager()
    local M = getPetManager()
    if not M then
        plog("!! pet_manager NOT FOUND")
        return false
    end
    if M.__PetUnlockerMgr then return true end
    M.__PetUnlockerMgr = true

    -- GetPet -> if returns nil, force spawn
    local impl = getImpl(M)
    if type(impl) == "table" then
        if type(impl.RefreshOrCreatePet) == "function" and not impl.__PU_Refresh then
            impl.__PU_Refresh = impl.RefreshOrCreatePet
            impl.RefreshOrCreatePet = function(self, ...)
                pcall(function()
                    local L = getLogicPet()
                    if L then
                        L.MyPetInfo = L.MyPetInfo or {}
                        L.MyPetInfo.equip_pet_id = _G.PetConfig.ForceEquippedPet
                        L.MyPetInfo.equip_pet_level = _G.PetConfig.MaxLevel
                    end
                end)
                local r = impl.__PU_Refresh(self, ...)
                return r
            end
            plog("wrapped pet_manager.RefreshOrCreatePet")
        end

        if type(impl.RegisterPet) == "function" and not impl.__PU_Register then
            impl.__PU_Register = impl.RegisterPet
            impl.RegisterPet = function(self, pet, ...)
                local r = impl.__PU_Register(self, pet, ...)
                pcall(function()
                    if slua.isValid(pet) then
                        -- Force scale/visibility if present
                        if pet.SetActorHiddenInGame then pet:SetActorHiddenInGame(false) end
                    end
                end)
                return r
            end
        end
    end

    return true
end

-- ============================================================================
-- HOOK LuaPetBase — actor skin/animation override
-- ============================================================================
local function hookLuaPetBase()
    local B = getPetBase()
    if not B then
        plog("!! LuaPetBase NOT FOUND")
        return false
    end
    if B.__PetUnlockerBase then return true end
    B.__PetUnlockerBase = true

    local impl = getImpl(B)
    if type(impl) == "table" then
        -- GetCurrentSkin -> our forced skin (if set)
        if type(impl.GetCurrentSkin) == "function" and not impl.__PU_GetSkin then
            impl.__PU_GetSkin = impl.GetCurrentSkin
            impl.GetCurrentSkin = function(self, ...)
                local forceSkin = _G.PetConfig.ForceSkinID
                if forceSkin and tonumber(forceSkin) > 0 then return forceSkin end
                return impl.__PU_GetSkin(self, ...)
            end
            plog("wrapped LuaPetBase.GetCurrentSkin")
        end

        -- PlayPetAnimation -> allow any
        if type(impl.PlayPetAnimation) == "function" and not impl.__PU_PlayAnim then
            impl.__PU_PlayAnim = impl.PlayPetAnimation
            impl.PlayPetAnimation = function(self, animID, ...)
                local ok, r = pcall(function() return impl.__PU_PlayAnim(self, animID, ...) end)
                if ok then return r end
                return impl.__PU_PlayAnim(self, animID, ...)
            end
        end

        -- CanPlay -> true
        if type(impl.CanPlay) == "function" and not impl.__PU_CanPlay then
            impl.__PU_CanPlay = impl.CanPlay
            impl.CanPlay = function(self, ...) return true end
        end
    end

    return true
end

-- ============================================================================
-- HOOK Player Controller — PetID / bShowMyPet
-- ============================================================================
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
        pc.bPetShowInLobby  = true
        pc.bPetShowInBattle = true
    end)

    if pc.__PetUnlockerPC then return true end
    pc.__PetUnlockerPC = true

    for _, fn in ipairs({"GetPetID","GetShowPetID","GetPetId","GetCurPetID"}) do
        if type(pc[fn]) == "function" and not pc["__PU_" .. fn] then
            pc["__PU_" .. fn] = pc[fn]
            pc[fn] = function(self, ...) return force end
            plog("wrapped PC." .. fn)
        end
    end
    for _, fn in ipairs({"GetPetLevel","GetCurPetLevel"}) do
        if type(pc[fn]) == "function" and not pc["__PU_" .. fn] then
            pc["__PU_" .. fn] = pc[fn]
            pc[fn] = function(self, ...) return _G.PetConfig.MaxLevel end
        end
    end
    for _, fn in ipairs({"IsShowPet","IsPetVisible","GetShowMyPet"}) do
        if type(pc[fn]) == "function" and not pc["__PU_" .. fn] then
            pc["__PU_" .. fn] = pc[fn]
            pc[fn] = function(self, ...) return true end
        end
    end

    return true
end

-- ============================================================================
-- HOOK Character
-- ============================================================================
local function hookChar()
    local c = getChar()
    if not slua.isValid(c) then return false end
    if c.__PetUnlockerChar then return true end
    c.__PetUnlockerChar = true
    local force = _G.PetConfig.ForceEquippedPet

    pcall(function()
        c.PetID       = force
        c.nPetID      = force
        c.PetLevel    = _G.PetConfig.MaxLevel
        c.bShowMyPet  = true
    end)

    for _, fn in ipairs({"OnRep_PetID","OnRep_PetInfo","OnRep_PetLevel"}) do
        if type(c[fn]) == "function" and not c["__PU_" .. fn] then
            c["__PU_" .. fn] = c[fn]
            c[fn] = function(self, ...)
                self["__PU_" .. fn](self, ...)
                self.PetID = force
                self.PetLevel = _G.PetConfig.MaxLevel
                self.bShowMyPet = true
            end
        end
    end

    plog("char hooked")
    return true
end

-- ============================================================================
-- MAIN APPLY
-- ============================================================================
local _applied = false

local function apply()
    if not _G.PetConfig.Enabled then return end
    plog("=== APPLY v3 ===")

    hookLogicPet()
    hookPetDataTrait()
    hookPetCfgTrait()
    hookPetManager()
    hookLuaPetBase()
    hookPC()
    hookChar()

    _applied = true
    plog("=== DONE ===")
    flushLog()
end

-- ============================================================================
-- AUTO-BOOT
-- ============================================================================
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
    if n < 80 then later(0.5, function() waitAndBoot(n + 1) end) end
end

-- Immediate fire
pcall(function()
    if io and io.open then
        local f = io.open(LOG_PATH, "w")
        if f then f:write("[PetUnlocker] boot " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n") f:close() end
    end
end)

waitAndBoot(0)

-- Re-hook on mode switch
pcall(function()
    if EventSystem and EventSystem.registEvent and EVENTTYPE_STATE and EVENTID_ON_MODE_POST_SWITCH then
        EventSystem:registEvent(EVENTTYPE_STATE, EVENTID_ON_MODE_POST_SWITCH, function()
            later(0.5, apply)
            later(2, apply)
            later(5, apply)
        end)
    end
end)

pcall(function()
    if EventSystem and EventSystem.registEvent and EVENTTYPE_LOBBY and EVENTID_SHOW_LOBBY then
        EventSystem:registEvent(EVENTTYPE_LOBBY, EVENTID_SHOW_LOBBY, function()
            later(1, apply)
        end)
    end
end)

-- Periodic re-hook
pcall(function()
    local tt = require("common.time_ticker")
    if tt and tt.AddTimerLoop then
        tt.AddTimerLoop(0, function()
            if not _applied then return end
            hookPC()
            hookChar()
        end, -1, 3.0)
    end
end)

-- ============================================================================
-- PUBLIC API
-- ============================================================================
PU.ApplyNow = apply
PU.GetPets  = function() return PET_IDS end
PU.GetLog   = function() return logBuf end
PU.SetPet   = function(id)
    id = tonumber(id)
    if PET_SET[id] then
        _G.PetConfig.ForceEquippedPet = id
        apply()
    end
end
PU.SetSkin  = function(id)
    _G.PetConfig.ForceSkinID = tonumber(id) or 0
end
PU.SetLevel = function(lvl)
    _G.PetConfig.MaxLevel = tonumber(lvl) or 6
    apply()
end

plog("PetUnlocker v3 loaded — pets=" .. #PET_IDS)
plog("Log file: " .. LOG_PATH)
flushLog()

return _G.PetUnlocker
