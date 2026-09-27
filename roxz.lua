-- ============================================================================
-- DANCE SYSTEM MOD MENU — Standalone Lua Module
-- Drop this file next to your main mod file. Auto-boots. Idempotent.
-- Adds: Lobby Emotes, Battle Emotes, Pet Auto-Equip, Pet Emotes, Dance System
-- Menu: Settings > DANCE SYSTEM (custom tab)
-- Config: /sdcard/DanceSystem_config.txt
-- ============================================================================

-- Idempotency guard
if _G.__DanceSystemMenuLoaded then return _G.DanceSystem end
_G.__DanceSystemMenuLoaded = true

-- ============================================================================
-- CONFIG STATE
-- ============================================================================
_G.DanceConfig = _G.DanceConfig or {
    LobbyEmotes    = true,
    BattleEmotes   = true,
    PetAutoEquip   = true,
    PetEmotes      = true,
    PetID          = 50006,
    PetLevel       = 6,
}

local CONFIG_PATHS = {
    "/storage/emulated/0/DanceSystem_config.txt",
    "/storage/emulated/0/Android/data/com.tencent.ig/files/DanceSystem_config.txt",
    "/storage/emulated/0/Android/data/com.vng.pubgmobile/files/DanceSystem_config.txt",
    "/storage/emulated/0/Android/data/com.pubg.krmobile/files/DanceSystem_config.txt",
    "/storage/emulated/0/Android/data/com.rekoo.pubgm/files/DanceSystem_config.txt",
    "/storage/emulated/0/Android/data/com.pubg.imobile/files/DanceSystem_config.txt",
    "/sdcard/DanceSystem_config.txt",
}

local function saveConfig()
    pcall(function()
        local lines = {}
        for k, v in pairs(_G.DanceConfig) do
            lines[#lines+1] = tostring(k) .. "=" .. tostring(v)
        end
        local data = table.concat(lines, "\n")
        for _, p in ipairs(CONFIG_PATHS) do
            local f = io.open(p, "w")
            if f then f:write(data) f:close() break end
        end
    end)
end

local function loadConfig()
    pcall(function()
        for _, p in ipairs(CONFIG_PATHS) do
            local f = io.open(p, "r")
            if f then
                local content = f:read("*a") f:close()
                for k, v in content:gmatch("([%w_]+)=([^\n]+)") do
                    if _G.DanceConfig[k] ~= nil then
                        if v == "true" then _G.DanceConfig[k] = true
                        elseif v == "false" then _G.DanceConfig[k] = false
                        else
                            local n = tonumber(v)
                            if n then _G.DanceConfig[k] = n end
                        end
                    end
                end
                break
            end
        end
    end)
end

loadConfig()

-- ============================================================================
-- CORE EMOTE + PET SYSTEM (from C++ Lua, cleaned for standalone)
-- ============================================================================

local EXTRA_EMOTES = {
    12201001, 12201701, 12203901, 12207901, 12219094, 12219090,
    12219248, 12220082, 12207401, 12220210, 12220320, 12201401,
    12219309, 12220470, 12220401, 12220413, 12220228, 12201301,
    12219207, 12210001, 12210801, 12212601, 12205601, 12219208,
    2200901, 12220475, 12220446, 12220412, 12219819, 12220288,
    12216101, 12209001, 12219022, 12200701, 12206001, 12206801,
    2203601, 12220543, 12220441, 12220407, 12219814, 12212201,
    12219561, 12208801, 12219242, 12205401, 12205201, 12209801,
    12220028, 12204601, 2200401, 12200801, 12204001,
}

local SHOW_EXPRESSION = 2
local SHOW_PET = 6
local DEFAULT_PET_LEVEL = 6

local _fakeDepot = {}
local _fakeDepotByRes = {}
local _extraResSet = {}
local _petActionSet = {}
local _hooksDone = false
local _motionGuardDone = false
local _lastApply = 0

-- ============================================================================
-- UTILITIES
-- ============================================================================
local function luaDefer(sec, fn)
    pcall(function()
        if _G.SetTimer then _G.SetTimer(sec, fn)
        else
            local tt = require("common.time_ticker")
            if tt and tt.AddTimerOnce then tt.AddTimerOnce(sec, fn) end
        end
    end)
end

local function myUid()
    return DataMgr and DataMgr.roleData and tonumber(DataMgr.roleData.uid)
end

local function makeInsId(resID)
    return tostring(resID * 1000 + 1)
end

local function getItemSubType(resID)
    local ok, cfg = pcall(function() return CDataTable.GetTableData("Item", resID) end)
    if ok and cfg and cfg.ItemSubType then return cfg.ItemSubType end
    return 2201
end

local function isInjectedResID(resID)
    return _extraResSet[tonumber(resID)] == true
end

local function isInjectedInsID(insID)
    return _fakeDepot[tostring(insID)] ~= nil
end

local function buildFakeDepotEntry(resID)
    resID = tonumber(resID)
    if not resID or not isInjectedResID(resID) then return nil end
    if not _fakeDepotByRes[resID] then
        local insID = makeInsId(resID)
        local entry = {
            resID = resID, res_id = resID,
            insID = insID, instid = insID,
            expireTS = 0, count = 1,
            itemType = 22,
            itemSubType = getItemSubType(resID),
            colorID = 0, patternID = 0, isNew = false,
        }
        _fakeDepotByRes[resID] = entry
        _fakeDepot[insID] = entry
    end
    return _fakeDepotByRes[resID]
end

local function isInMotionSlotList(insID)
    if not DataMgr or not DataMgr.MotionSlotList then return false end
    insID = tostring(insID)
    for _, v in ipairs(DataMgr.MotionSlotList) do
        if tostring(v) == insID then return true end
    end
    return false
end

local function isInLobby()
    if GameStatus and GameStatus.GetCurrent and GameStatus.InLobby then
        return GameStatus.GetCurrent() == GameStatus.InLobby
    end
    return false
end

local function isBattleContext()
    return not isInLobby()
end

local function collapsed()
    return UEnums and UEnums.ESlateVisibility and UEnums.ESlateVisibility.Collapsed or 1
end

local function visible()
    return UEnums and UEnums.ESlateVisibility and UEnums.ESlateVisibility.SelfHitTestInvisible or 0
end

local function getImpl(mod)
    if not mod then return nil end
    return mod.__inner_impl or mod
end

local function getActivePanel()
    local ok, ui = pcall(function()
        local UIManager = require("client.slua_ui_framework.manager")
        if not UIManager or not UIManager.UI_Config_InGame then return nil end
        return UIManager.GetUI(UIManager.UI_Config_InGame.QuickExpressionDecalSubPanel)
    end)
    return ok and ui or nil
end

-- ============================================================================
-- LOBBY EMOTES BUILDER
-- ============================================================================
local function buildFullMotionList()
    local list, seen = {}, {}
    pcall(function()
        local wardrobe_data = require("client.slua.logic.wardrobe.wardrobe_data")
        local TeamAvatarManager = require("client.logic.avatar.logic_team_avatar_manager")
        local showingAvatar = TeamAvatarManager.GetMainAvatar()
        local XMissionSystem = require("client.slua.logic.TxMission.logic_xmission_main")
        if XMissionSystem and XMissionSystem.IsInXMission and XMissionSystem.IsInXMission() then
            local XMissionAvatarMgr = require("client.slua.logic.TxMission.logic_xmission_avatar_mgr")
            showingAvatar = XMissionAvatarMgr.GetMainAvatar()
        end
        if showingAvatar then
            local CurWeaponID = showingAvatar:GetCurHoldingWeaponSkinID()
            local Cfg = CDataTable.GetTableData("WeaponAvatarBattleEffect", CurWeaponID)
            if Cfg then
                local ModuleManager = require("client.module_framework.ModuleManager")
                local ItemUpgradeMgr = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.ItemUpgradeManager)
                if ItemUpgradeMgr and ItemUpgradeMgr.IsWeaponEmoteUnlockedWithOutCheckWeapon
                    and ItemUpgradeMgr:IsWeaponEmoteUnlockedWithOutCheckWeapon(Cfg.WeaponEmoteID) then
                    local id = Cfg.WeaponEmoteID
                    seen[id] = true
                    list[#list + 1] = { itemId = id, bWeaponBindEmote = true }
                end
            end
        end
        if DataMgr and DataMgr.MotionSlotList then
            for _, insID in ipairs(DataMgr.MotionSlotList) do
                local itemData = wardrobe_data:GetValidHallDepotItemDataByInsID(insID)
                if itemData and itemData.resID and itemData.resID > 0 and not seen[itemData.resID] then
                    seen[itemData.resID] = true
                    list[#list + 1] = { itemId = itemData.resID }
                end
            end
        end
    end)
    if _G.DanceConfig.LobbyEmotes then
        for _, resID in ipairs(EXTRA_EMOTES) do
            resID = tonumber(resID)
            if resID and resID > 0 and not seen[resID] then
                seen[resID] = true
                list[#list + 1] = { itemId = resID }
            end
        end
    end
    return list
end

local function buildLobbyPetActionList()
    local list = {}
    pcall(function()
        local ModuleManager = require("client.module_framework.ModuleManager")
        local logic_pet = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_pet)
        local petID = _G.DanceConfig.PetID
        if logic_pet and type(logic_pet.MyPetInfo) == "table" and (logic_pet.MyPetInfo.equip_pet_id or 0) > 0 then
            petID = logic_pet.MyPetInfo.equip_pet_id
        end
        local cfg = logic_pet and logic_pet.GetPetActionCfg and logic_pet:GetPetActionCfg()
        if cfg then
            for _, v in pairs(cfg) do
                if v.PetID == petID and v.ShowInLobby == 1 then
                    list[#list + 1] = {
                        PetID = v.PetID, PetActionID = v.PetActionID,
                        NeedLevel = 0, PetActionIcon = v.PetActionIcon,
                    }
                end
            end
        end
        if #list == 0 then
            for _, v in pairs(CDataTable.GetTable("PetActionTable") or {}) do
                if v.PetID == petID and v.ShowInLobby == 1 then
                    list[#list + 1] = {
                        PetID = v.PetID, PetActionID = v.PetActionID,
                        NeedLevel = 0, PetActionIcon = v.PetActionIcon,
                    }
                end
            end
        end
    end)
    return list
end

local function applyMotionSlots()
    if not DataMgr then return 0 end
    DataMgr.MotionSlotList = DataMgr.MotionSlotList or {}
    local wantMax = #EXTRA_EMOTES + 10
    DataMgr.MotionSlotMax = math.max(tonumber(DataMgr.MotionSlotMax) or 0, wantMax)
    local n = 0
    if _G.DanceConfig.LobbyEmotes then
        for _, resID in ipairs(EXTRA_EMOTES) do
            local entry = buildFakeDepotEntry(resID)
            if entry and not isInMotionSlotList(entry.insID) then
                table.insert(DataMgr.MotionSlotList, entry.insID)
                n = n + 1
            end
        end
    end
    return n
end

local function refreshExpressionPopUI()
    pcall(function()
        local UIManager = require("client.slua_ui_framework.manager")
        if not UIManager or not UIManager.GetUI or not UIManager.UI_Config then return end
        local ui = UIManager.GetUI(UIManager.UI_Config.ExpressionPop_New_UIBP)
        if ui then _G.DanceSystemPatchPopInstance(ui) end
    end)
end

local function reapplyAfterMotionSync()
    applyMotionSlots()
    luaDefer(0.05, refreshExpressionPopUI)
    luaDefer(0.3, refreshExpressionPopUI)
end

-- ============================================================================
-- LOBBY UI PATCH
-- ============================================================================
_G.DanceSystemPatchPopInstance = function(ui)
    if not ui then return end
    if not ui.__LobbyEmotesInstPatched then
        ui.__LobbyEmotesInstPatched = true
        if ui.UpdateActionUI then
            local orig = ui.UpdateActionUI
            ui.UpdateActionUI = function(self, ...)
                local r = orig(self, ...)
                self.expressList = buildFullMotionList()
                if self.LoopScrollGrid_Action and self.LoopScrollGrid_Action.SetData then
                    self.LoopScrollGrid_Action:SetData(self.expressList)
                end
                return r
            end
        end
        if ui.UpdatePetUI then
            local orig = ui.UpdatePetUI
            ui.UpdatePetUI = function(self, ...)
                if _G.DanceConfig.PetEmotes then
                    local petDatas = buildLobbyPetActionList()
                    if petDatas and #petDatas > 0 then
                        self.nCurPetID = _G.DanceConfig.PetID
                        if self.LoopScrollGrid_Pet and self.LoopScrollGrid_Pet.SetData then
                            self.LoopScrollGrid_Pet:SetData(petDatas)
                        end
                        return
                    end
                end
                return orig(self, ...)
            end
        end
    end
    ui.expressList = buildFullMotionList()
    if ui.LoopScrollGrid_Action and ui.LoopScrollGrid_Action.SetData then
        ui.LoopScrollGrid_Action:SetData(ui.expressList)
    end
    if _G.DanceConfig.PetEmotes then
        local pets = buildLobbyPetActionList()
        if pets and #pets > 0 and ui.LoopScrollGrid_Pet and ui.LoopScrollGrid_Pet.SetData then
            ui.LoopScrollGrid_Pet:SetData(pets)
        end
    end
end

-- ============================================================================
-- LOBBY WARDROBE HOOKS
-- ============================================================================
local function installWardrobeHooks()
    local ok, WardrobeData = pcall(require, "client.slua.logic.wardrobe.wardrobe_data")
    if not ok or not WardrobeData or WardrobeData.__LobbyEmotesWardrobe then return false end
    WardrobeData.__LobbyEmotesWardrobe = true

    for _, resID in ipairs(EXTRA_EMOTES) do buildFakeDepotEntry(resID) end

    local origValid = WardrobeData.GetValidHallDepotItemDataByInsID
    WardrobeData.GetValidHallDepotItemDataByInsID = function(self, insID, ...)
        if isInjectedInsID(insID) then return _fakeDepot[tostring(insID)] end
        return origValid(self, insID, ...)
    end

    local origIns = WardrobeData.GetHallDepotItemDataByInsID
    WardrobeData.GetHallDepotItemDataByInsID = function(self, insID, ...)
        if isInjectedInsID(insID) then return _fakeDepot[tostring(insID)] end
        return origIns(self, insID, ...)
    end

    local origRes = WardrobeData.GetHallDepotItemDataByResID
    WardrobeData.GetHallDepotItemDataByResID = function(self, resID, ...)
        if isInjectedResID(resID) then return buildFakeDepotEntry(resID) end
        return origRes(self, resID, ...)
    end

    if WardrobeData.GetHallDepotItemDataByResIDAndValidExpireTime then
        local origResValid = WardrobeData.GetHallDepotItemDataByResIDAndValidExpireTime
        WardrobeData.GetHallDepotItemDataByResIDAndValidExpireTime = function(self, resID, ...)
            if isInjectedResID(resID) then return buildFakeDepotEntry(resID) end
            return origResValid(self, resID, ...)
        end
    end

    if WardrobeData.HasItem then
        local origHas = WardrobeData.HasItem
        WardrobeData.HasItem = function(self, itemId, forever, ...)
            if isInjectedResID(itemId) then return true end
            return origHas(self, itemId, forever, ...)
        end
    end
    if WardrobeData.HasValidItem then
        local origHasValid = WardrobeData.HasValidItem
        WardrobeData.HasValidItem = function(self, itemId, forever, ...)
            if isInjectedResID(itemId) then return true end
            return origHasValid(self, itemId, forever, ...)
        end
    end
    return true
end

local function installExpressionHook()
    pcall(function()
        local mod = require("client.slua.umg.Souvenirs.Expression_Util")
        if mod then
            mod.GetMotionDataList = function() return buildFullMotionList() end
            mod.GetMotionGridMax = function()
                return math.max(tonumber(DataMgr and DataMgr.MotionSlotMax) or 10, #EXTRA_EMOTES + 10)
            end
            mod.GetPetActionList = function() return buildLobbyPetActionList() or {} end
        end
    end)
end

local function installExpressionPopHook()
    pcall(function()
        local ok, Panel = pcall(require, "client.slua.umg.Souvenirs.ExpressionPop_New_UIBP")
        if ok and Panel then
            local impl = Panel.__inner_impl or Panel
            if impl and not impl.__LobbyEmotesPopHook then
                impl.__LobbyEmotesPopHook = true
                if impl.OnPostInitialize then
                    local orig = impl.OnPostInitialize
                    impl.OnPostInitialize = function(self, ...)
                        local r = orig(self, ...)
                        luaDefer(0.1, function() _G.DanceSystemPatchPopInstance(self) end)
                        return r
                    end
                end
            end
        end
    end)
    pcall(function()
        local UIManager = require("client.slua_ui_framework.manager")
        if not UIManager or UIManager.__LobbyEmotesPopUIHook then return end
        UIManager.__LobbyEmotesPopUIHook = true
        if UIManager.ShowUI then
            local orig = UIManager.ShowUI
            UIManager.ShowUI = function(cfg, ...)
                local ui = orig(cfg, ...)
                pcall(function()
                    if cfg == UIManager.UI_Config.ExpressionPop_New_UIBP and ui then
                        _G.DanceSystemPatchPopInstance(ui)
                        luaDefer(0.15, function() _G.DanceSystemPatchPopInstance(ui) end)
                        luaDefer(0.5, function() _G.DanceSystemPatchPopInstance(ui) end)
                    end
                end)
                return ui
            end
        end
    end)
end

local function installMotionGuard()
    if _motionGuardDone then return end
    _motionGuardDone = true
    pcall(function()
        if DataMgr and DataMgr.InitMotionInfo and not DataMgr.__LobbyEmotesMotionGuard then
            DataMgr.__LobbyEmotesMotionGuard = true
            local orig = DataMgr.InitMotionInfo
            DataMgr.InitMotionInfo = function(motion_info, limit)
                local forced = math.max(tonumber(limit) or 0, #EXTRA_EMOTES + 10)
                orig(motion_info, forced)
                reapplyAfterMotionSync()
            end
        end
        if DataMgr and DataMgr.sync_motion_info and not DataMgr.__LobbyEmotesSyncGuard then
            DataMgr.__LobbyEmotesSyncGuard = true
            local orig = DataMgr.sync_motion_info
            DataMgr.sync_motion_info = function(motion_info, limit)
                local forced = math.max(tonumber(limit) or 0, #EXTRA_EMOTES + 10)
                orig(motion_info, forced)
                reapplyAfterMotionSync()
            end
        end
    end)
    pcall(function()
        if EventSystem and EVENTID_MOTION_UPDATE_SLOT_LIST and not EventSystem.__LobbyEmotesSlotEvt then
            EventSystem.__LobbyEmotesSlotEvt = true
            EventSystem:registEvent(EVENTTYPE_MOTION, EVENTID_MOTION_UPDATE_SLOT_LIST, function()
                reapplyAfterMotionSync()
            end)
        end
    end)
end

-- ============================================================================
-- BATTLE EMOTES
-- ============================================================================
local function collectNativeEmoteIDs()
    local ids, seen = {}, {}
    pcall(function()
        local GameplayData = require("GameLua.GameCore.Data.GameplayData")
        local STExtra = import("STExtraBlueprintFunctionLibrary")
        local BackpackUtils = import("BackpackUtils")
        local pc = GameplayData.GetPlayerController()
        if not pc or not slua.isValid(pc) then return end
        local comp = STExtra.GetBackpackComponentFromController(pc)
        if not comp or not slua.isValid(comp) then return end
        local items = BackpackUtils.GetEmoteItemInBackpack(comp)
        if not items then return end
        for _, data in pairs(items) do
            if data and data.DefineID then
                local id = tonumber(data.DefineID.TypeSpecificID)
                if id and id > 0 and not seen[id] then
                    seen[id] = true; ids[#ids+1] = id
                end
            end
        end
    end)
    return ids, seen
end

local function rebuildPlayerEmoteCache(self)
    local ids, seen = collectNativeEmoteIDs()
    if _G.DanceConfig.BattleEmotes then
        for _, resID in ipairs(EXTRA_EMOTES) do
            resID = tonumber(resID)
            if resID and resID > 0 and not seen[resID] then
                seen[resID] = true; ids[#ids+1] = resID
            end
        end
    end
    self.__BattlePlayerEmoteIDs = ids
    return ids
end

local function buildPetEmoteList()
    local list = {}
    _petActionSet = {}
    pcall(function()
        local tbl = CDataTable.GetTable("PetActionTable")
        if not tbl then return end
        for _, v in pairs(tbl) do
            if v.PetID == _G.DanceConfig.PetID and (v.CanPlayInBattle == 1 or v.CanPlayInBattle == 2) then
                list[#list + 1] = {
                    ID = v.PetActionID, IsLocked = false,
                    SortKey = v.SortKey or 0, MasterSkillID = v.MasterSkillID,
                }
                _petActionSet[tonumber(v.PetActionID)] = true
            end
        end
    end)
    table.sort(list, function(a, b) return a.SortKey < b.SortKey end)
    return list
end

local function placeEmoteSlot(self, idx, resID, isPet, isLocked)
    local Item = self.GetQuickExpressionDecalItemByIndex and self:GetQuickExpressionDecalItemByIndex(idx)
    if not Item then return false end
    pcall(function()
        if Item.UIRoot and Item.UIRoot.WidgetSwitcher_Effect then
            Item.UIRoot.WidgetSwitcher_Effect:SetVisibility(collapsed())
        end
        if Item.UIRoot and Item.UIRoot.Image_Weapon then
            Item.UIRoot.Image_Weapon:SetVisibility(collapsed())
        end
    end)
    Item:Show()
    Item:RefreshData(resID, -1, isPet == true, isLocked == true)
    return true
end

local function hideEmptyMessage(self)
    pcall(function()
        if self.UIRoot then
            if self.UIRoot.VerticalBox_Empty then self.UIRoot.VerticalBox_Empty:SetVisibility(collapsed()) end
            if self.UIRoot.WrapBox_List then self.UIRoot.WrapBox_List:SetVisibility(visible()) end
            if self.UIRoot.CanvasPanel_List then self.UIRoot.CanvasPanel_List:SetVisibility(visible()) end
        end
    end)
end

local function expandScrollForCount(self, count)
    pcall(function()
        if not self.UIRoot or not self.UIRoot.ScrollBox_0 or count <= 0 then return end
        local rowNum = math.ceil(count / 4)
        local targetY = math.min(rowNum * 60, 360)
        local slot = self.UIRoot.ScrollBox_0.Slot
        if slot and slot.GetSize then
            local origin = slot:GetSize()
            if origin then slot:SetSize(FVector2D(origin.X, targetY)) end
        end
        self.UIRoot.ScrollBox_0.SizeY = targetY
    end)
end

local function renderPlayerEmoteGrid(self)
    if not self or not self.QuickExpressionDecalItemList then return 0 end
    local ids = self.__BattlePlayerEmoteIDs
    if not ids or #ids == 0 then ids = rebuildPlayerEmoteCache(self) end
    if #ids == 0 then return 0 end
    local cnt = 0
    for i, resID in ipairs(ids) do
        if placeEmoteSlot(self, i, resID, false, false) then cnt = i end
    end
    hideEmptyMessage(self)
    if self.HideRestBlocks then self:HideRestBlocks(cnt) end
    expandScrollForCount(self, cnt)
    return cnt
end

local function renderPetEmoteGrid(self)
    if not self then return 0 end
    if not _G.DanceConfig.PetEmotes then return 0 end
    if not self.__BattlePetEmoteList then self.__BattlePetEmoteList = buildPetEmoteList() end
    local list = self.__BattlePetEmoteList
    if #list == 0 then return 0 end
    self.PetID = _G.DanceConfig.PetID
    self.PetLevel = _G.DanceConfig.PetLevel
    self.bShowMyPet = true
    self.CurPetExpressionList = list
    local cnt = 0
    for i, v in ipairs(list) do
        if placeEmoteSlot(self, i, v.ID, true, false) then cnt = i end
    end
    hideEmptyMessage(self)
    if self.HideRestBlocks then self:HideRestBlocks(cnt) end
    expandScrollForCount(self, cnt)
    return cnt
end

local function restoreCurrentGrid(self)
    if not self then return end
    if self.CurrentShowState == SHOW_PET then renderPetEmoteGrid(self)
    elseif self.CurrentShowState == SHOW_EXPRESSION then renderPlayerEmoteGrid(self) end
end

local function playPlayerEmote(self, ID)
    if isInjectedResID(ID) and self.PlayEmoteInternal then
        self:PlayEmoteInternal(ID, false); return true
    end
    if self.TryToPlayEmote then self:TryToPlayEmote(ID); return true end
    return false
end

local function playPetEmote(self, ID)
    if not _G.DanceConfig.PetEmotes then return false end
    local PlayerController = nil
    pcall(function()
        local GameplayData = require("GameLua.GameCore.Data.GameplayData")
        PlayerController = GameplayData.GetPlayerController()
    end)
    if not PlayerController or not slua.isValid(PlayerController) then return false end
    if PlayerController.PlaySpecifiedPetAnimation then
        pcall(function() PlayerController:PlaySpecifiedPetAnimation(ID) end)
        return true
    end
    return false
end

-- ============================================================================
-- PANEL INSTANCE PATCH (battle)
-- ============================================================================
local function patchPanelInstance(ui)
    if not ui or ui.__DanceSystemPatched then return end
    ui.__DanceSystemPatched = true

    if ui.GetIsEmoteExist and not ui.__OrigGetIsEmoteExist then
        ui.__OrigGetIsEmoteExist = ui.GetIsEmoteExist
        ui.GetIsEmoteExist = function(self, defineID)
            if isInjectedResID(defineID) or _petActionSet[tonumber(defineID)] then return true end
            return self.__OrigGetIsEmoteExist(self, defineID)
        end
    end
    if ui.GetCurPet and not ui.__OrigGetCurPet then
        ui.__OrigGetCurPet = ui.GetCurPet
        ui.GetCurPet = function(self)
            if self.CurrentShowState == SHOW_PET then
                return _G.DanceConfig.PetID, _G.DanceConfig.PetLevel
            end
            return self.__OrigGetCurPet(self)
        end
    end
    if ui.GetShowMyPet and not ui.__OrigGetShowMyPet then
        ui.__OrigGetShowMyPet = ui.GetShowMyPet
        ui.GetShowMyPet = function(self)
            if self.CurrentShowState == SHOW_PET then return true end
            return self.__OrigGetShowMyPet(self)
        end
    end
    if ui.RefreshExpression and not ui.__OrigRefreshExpression then
        ui.__OrigRefreshExpression = ui.RefreshExpression
        ui.RefreshExpression = function(self, ...)
            self.__OrigRefreshExpression(self, ...)
            rebuildPlayerEmoteCache(self)
            renderPlayerEmoteGrid(self)
        end
    end
    if ui.RefreshPetExpression and not ui.__OrigRefreshPetExpression then
        ui.__OrigRefreshPetExpression = ui.RefreshPetExpression
        ui.RefreshPetExpression = function(self, ...)
            self.__BattlePetEmoteList = self.__BattlePetEmoteList or buildPetEmoteList()
            renderPetEmoteGrid(self)
        end
    end
    if ui.OnClickItem and not ui.__OrigOnClickItem then
        ui.__OrigOnClickItem = ui.OnClickItem
        ui.OnClickItem = function(self, ID)
            if not ID or ID <= 0 then return end
            if self.CurrentShowState == SHOW_EXPRESSION then
                playPlayerEmote(self, ID)
                luaDefer(0.05, function() restoreCurrentGrid(self) end)
                luaDefer(0.2, function() restoreCurrentGrid(self) end)
                return
            end
            if self.CurrentShowState == SHOW_PET then
                playPetEmote(self, ID)
                luaDefer(0.05, function() restoreCurrentGrid(self) end)
                luaDefer(0.2, function() restoreCurrentGrid(self) end)
                return
            end
            return self.__OrigOnClickItem(self, ID)
        end
    end
    if ui.RefreshGridPanel and not ui.__OrigRefreshGridPanel then
        ui.__OrigRefreshGridPanel = ui.RefreshGridPanel
        ui.RefreshGridPanel = function(self, ...)
            self.__OrigRefreshGridPanel(self, ...)
            luaDefer(0.05, function() restoreCurrentGrid(self) end)
        end
    end
    if ui.OnButtonPetExpression and not ui.__OrigOnButtonPetExpression then
        ui.__OrigOnButtonPetExpression = ui.OnButtonPetExpression
        ui.OnButtonPetExpression = function(self, ...)
            local r = self.__OrigOnButtonPetExpression(self, ...)
            luaDefer(0.1, function() renderPetEmoteGrid(self) end)
            return r
        end
    end
    if ui.OnButtonPlayerExpression and not ui.__OrigOnButtonPlayerExpression then
        ui.__OrigOnButtonPlayerExpression = ui.OnButtonPlayerExpression
        ui.OnButtonPlayerExpression = function(self, ...)
            local r = self.__OrigOnButtonPlayerExpression(self, ...)
            luaDefer(0.1, function() renderPlayerEmoteGrid(self) end)
            return r
        end
    end
end

local function patchActivePanel()
    local ui = getActivePanel()
    if ui then patchPanelInstance(ui) end
    return ui
end

-- ============================================================================
-- CLASS HOOKS
-- ============================================================================
local function hookLogicEmote()
    pcall(function()
        local logic_emote = require("GameLua.Mod.Library.GamePlay.Avatar.Emote.logic_emote")
        if not logic_emote or logic_emote.__DanceSystemHook then return end
        logic_emote.__DanceSystemHook = true
        local impl = getImpl(logic_emote)
        if impl.CheckEmoteDownloaded then
            local orig = impl.CheckEmoteDownloaded
            impl.CheckEmoteDownloaded = function(EmoteID, ...)
                if isInjectedResID(EmoteID) or _petActionSet[tonumber(EmoteID)] then return true end
                return orig(EmoteID, ...)
            end
        end
        if impl.IsEmoteExist then
            local orig = impl.IsEmoteExist
            impl.IsEmoteExist = function(EmoteID)
                if isInjectedResID(EmoteID) or _petActionSet[tonumber(EmoteID)] then return true end
                return orig(EmoteID)
            end
        end
    end)
end

local function hookDecalClass()
    pcall(function()
        local Panel = require("GameLua.Mod.BaseMod.Client.Emote.QuickExpressionDecalSubPanel")
        if not Panel or Panel.__DanceSystemClassHook then return end
        Panel.__DanceSystemClassHook = true
        local impl = getImpl(Panel)
        if impl.GetIsEmoteExist then
            local orig = impl.GetIsEmoteExist
            impl.GetIsEmoteExist = function(self, defineID)
                if isInjectedResID(defineID) or _petActionSet[tonumber(defineID)] then return true end
                return orig(self, defineID)
            end
        end
        if impl.RefreshExpression then
            local orig = impl.RefreshExpression
            impl.RefreshExpression = function(self, ...)
                orig(self, ...)
                rebuildPlayerEmoteCache(self)
                renderPlayerEmoteGrid(self)
            end
        end
        if impl.RefreshPetExpression then
            local orig = impl.RefreshPetExpression
            impl.RefreshPetExpression = function(self, ...)
                self.__BattlePetEmoteList = self.__BattlePetEmoteList or buildPetEmoteList()
                renderPetEmoteGrid(self)
            end
        end
    end)
end

local function hookUIManager()
    pcall(function()
        local UIManager = require("client.slua_ui_framework.manager")
        if not UIManager or UIManager.__DanceSystemUIHook then return end
        UIManager.__DanceSystemUIHook = true
        if UIManager.ShowUI then
            local origShow = UIManager.ShowUI
            UIManager.ShowUI = function(cfg, ...)
                local ui = origShow(cfg, ...)
                pcall(function()
                    if cfg == UIManager.UI_Config_InGame.QuickExpressionDecalSubPanel and ui then
                        luaDefer(0.1, function() patchPanelInstance(ui); restoreCurrentGrid(ui) end)
                    end
                end)
                return ui
            end
        end
        if UIManager.GetUI then
            local origGet = UIManager.GetUI
            UIManager.GetUI = function(cfg, ...)
                local ui = origGet(cfg, ...)
                pcall(function()
                    if cfg == UIManager.UI_Config_InGame.QuickExpressionDecalSubPanel and ui then
                        patchPanelInstance(ui)
                    end
                end)
                return ui
            end
        end
    end)
end

local function installEvents()
    pcall(function()
        if not EventSystem or EventSystem.__DanceSystemEvents then return end
        EventSystem.__DanceSystemEvents = true
        local function onPanelOpen()
            installClassHooks()
            local ui = patchActivePanel()
            if ui then restoreCurrentGrid(ui) end
            luaDefer(0.25, function()
                local p = getActivePanel()
                if p then restoreCurrentGrid(p) end
            end)
        end
        if EVENTTYPE_INGAME and EVENTID_INGAME_QUICK_EXPRESSION_DECAL_CLICK then
            EventSystem:registEvent(EVENTTYPE_INGAME, EVENTID_INGAME_QUICK_EXPRESSION_DECAL_CLICK, onPanelOpen)
        end
        if EVENTTYPE_INGAME and EVENTID_INGAME_QUICK_EXPRESSION_CLICK then
            EventSystem:registEvent(EVENTTYPE_INGAME, EVENTID_INGAME_QUICK_EXPRESSION_CLICK, onPanelOpen)
        end
        if EVENTTYPE_INGAME and EVENTID_REFRESH_EMOTE_ACTION_DATA then
            EventSystem:registEvent(EVENTTYPE_INGAME, EVENTID_REFRESH_EMOTE_ACTION_DATA, function()
                luaDefer(0.05, function()
                    local ui = getActivePanel()
                    if ui then restoreCurrentGrid(ui) end
                end)
            end)
        end
    end)
end

function installClassHooks()
    _extraResSet = {}
    for _, id in ipairs(EXTRA_EMOTES) do _extraResSet[tonumber(id)] = true end
    buildPetEmoteList()
    hookLogicEmote()
    hookDecalClass()
    hookUIManager()
    installEvents()
end

-- ============================================================================
-- PET AUTO-EQUIP
-- ============================================================================
local function ForceAutoEquipPet()
    if not _G.DanceConfig.PetAutoEquip then return end
    local petID = _G.DanceConfig.PetID
    local petLvl = _G.DanceConfig.PetLevel
    pcall(function()
        local ModuleManager = require("client.module_framework.ModuleManager")
        local logic_pet = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_pet)
        if logic_pet then
            logic_pet.MyPetInfo = logic_pet.MyPetInfo or {}
            logic_pet.MyPetInfo.equip_pet_id = petID
            logic_pet.MyPetInfo.equip_pet_level = petLvl
        end
    end)
    pcall(function()
        local GameplayData = require("GameLua.GameCore.Data.GameplayData")
        local pc = GameplayData.GetPlayerController()
        if pc and slua.isValid(pc) then
            pc.PetID = petID
            pc.PetLevel = petLvl
            pc.bShowMyPet = true
        end
    end)
end

-- ============================================================================
-- PUBLIC API (DanceSystem)
-- ============================================================================
_G.DanceSystem = _G.DanceSystem or {}
function _G.DanceSystem.ApplyNow()
    pcall(ForceAutoEquipPet)
    if _G.DanceConfig.LobbyEmotes then
        pcall(function()
            installWardrobeHooks()
            installExpressionHook()
            installExpressionPopHook()
            installMotionGuard()
            applyMotionSlots()
            reapplyAfterMotionSync()
        end)
    end
    if _G.DanceConfig.BattleEmotes then
        pcall(function()
            installClassHooks()
            local ui = patchActivePanel()
            if ui then restoreCurrentGrid(ui) end
        end)
    end
end
function _G.DanceSystem.Refresh() _G.DanceSystem.ApplyNow() end

-- ============================================================================
-- MOD MENU TAB — Settings > DANCE SYSTEM
-- ============================================================================
local function InitDanceMenuTab()
    if _G.__DanceMenuInit then return end
    _G.__DanceMenuInit = true

    pcall(function()
        local LocUtil = package.loaded["client.common.LocUtil"] or require("client.common.LocUtil")
        if LocUtil and not LocUtil.__DanceMenuHooked then
            local oldGet = LocUtil.GetLocalizeResStr
            local DanceTextMap = {
                [998000] = "DANCE SYSTEM",
                [998001] = "Lobby Emotes (52 unlock)",
                [998002] = "Battle Emotes (in-match)",
                [998003] = "Pet Auto-Equip (lobby + match)",
                [998004] = "Pet Emotes (pet action menu)",
                [998005] = "Pet ID",
                [998006] = "Pet Level",
            }
            LocUtil.GetLocalizeResStr = function(id)
                if DanceTextMap[id] then return DanceTextMap[id] end
                if type(id) == "string" and not tonumber(id) then return id end
                return oldGet(id)
            end
            LocUtil.__DanceMenuHooked = true
        end
    end)

    pcall(function()
        local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine")
        local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")
        local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")

        local DanceStack = {
            { Key = "Dance_Lobby", UI = AliasMap.Switcher, Text = 998001,
              GetFunc = function() return _G.DanceConfig.LobbyEmotes end,
              SetFunc = function(_, v) _G.DanceConfig.LobbyEmotes = v; saveConfig(); _G.DanceSystem.ApplyNow(); return true end },
            { Key = "Dance_Battle", UI = AliasMap.Switcher, Text = 998002,
              GetFunc = function() return _G.DanceConfig.BattleEmotes end,
              SetFunc = function(_, v) _G.DanceConfig.BattleEmotes = v; saveConfig(); _G.DanceSystem.ApplyNow(); return true end },
            { Key = "Dance_PetAuto", UI = AliasMap.Switcher, Text = 998003,
              GetFunc = function() return _G.DanceConfig.PetAutoEquip end,
              SetFunc = function(_, v) _G.DanceConfig.PetAutoEquip = v; saveConfig(); ForceAutoEquipPet(); return true end },
            { Key = "Dance_PetEmotes", UI = AliasMap.Switcher, Text = 998004,
              GetFunc = function() return _G.DanceConfig.PetEmotes end,
              SetFunc = function(_, v) _G.DanceConfig.PetEmotes = v; saveConfig(); _G.DanceSystem.ApplyNow(); return true end },
            { Key = "Dance_PetID", UI = AliasMap.Slider, Text = 998005,
              MinValue = 1, MaxValue = 100, min = 1, max = 100,
              GetFunc = function() return math.floor(_G.DanceConfig.PetID / 10000) end,
              SetFunc = function(_, v) _G.DanceConfig.PetID = math.floor(v * 10000); saveConfig(); ForceAutoEquipPet(); return true end },
            { Key = "Dance_PetLvl", UI = AliasMap.Slider, Text = 998006,
              MinValue = 1, MaxValue = 10, min = 1, max = 10,
              GetFunc = function() return _G.DanceConfig.PetLevel end,
              SetFunc = function(_, v) _G.DanceConfig.PetLevel = math.floor(v); saveConfig(); ForceAutoEquipPet(); return true end },
        }

        if not SettingPageDefine.DanceMenu then
            SettingPageDefine.DanceMenu = {
                Key = "DanceMenu",
                Text = 998000,
                UIKey = "Setting_Page_Privacy",
                Category = {
                    { Key = "Cat_Dance", Text = 998000, Stack = DanceStack },
                },
            }
            table.insert(SettingCatalog, 1, SettingPageDefine.DanceMenu)
        end

        local UIManager = _G.UIManager
        if UIManager and not UIManager.__DanceMenuHooked then
            local oldShow = UIManager.ShowUI
            UIManager.ShowUI = function(config, ...)
                local args = {...}
                local n = select('#', ...)
                if config and config.keyName and string.find(string.lower(config.keyName), "setting_main") then
                    local catalog = args[1]
                    if type(catalog) == "table" then
                        local has = false
                        for _, page in ipairs(catalog) do
                            if type(page) == "table" and page.Key == "DanceMenu" then has = true; break end
                        end
                        if not has then table.insert(catalog, 1, SettingPageDefine.DanceMenu) end
                    end
                end
                local unpack = table.unpack or unpack
                return oldShow(config, unpack(args, 1, n))
            end
            UIManager.__DanceMenuHooked = true
        end
    end)
end

-- ============================================================================
-- BOOT
-- ============================================================================
local function boot()
    ForceAutoEquipPet()
    _G.DanceSystem.ApplyNow()
end

local function waitUid(attempt)
    attempt = attempt or 0
    if myUid() then boot(); return end
    if attempt < 60 then luaDefer(0.5, function() waitUid(attempt + 1) end) end
end

pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(0.5, InitDanceMenuTab)
        ticker.AddTimerOnce(1.0, waitUid)
    end
end)

-- Re-apply on lobby entry + match entry
pcall(function()
    if EventSystem and EventSystem.registEvent then
        if EVENTTYPE_STATE and EVENTID_ON_MODE_POST_SWITCH then
            EventSystem:registEvent(EVENTTYPE_STATE, EVENTID_ON_MODE_POST_SWITCH, function(_, _, next)
                if next == GameStatus and GameStatus.Lobby then
                    luaDefer(0.3, boot); luaDefer(2, boot)
                else
                    luaDefer(1, boot)
                end
            end)
        end
        if EVENTTYPE_LOBBY and EVENTID_SHOW_LOBBY then
            EventSystem:registEvent(EVENTTYPE_LOBBY, EVENTID_SHOW_LOBBY, function()
                luaDefer(1, boot)
            end)
        end
    end
end)

luaDefer(0.5, boot)
luaDefer(1, boot)
luaDefer(2, boot)
luaDefer(4, boot)
luaDefer(8, boot)
luaDefer(15, boot)

-- Config autosave on toggle
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerLoop then
        ticker.AddTimerLoop(0, saveConfig, -1, 10)
    end
end)

print("[DanceSystem] Mod Menu module loaded — check Settings > DANCE SYSTEM")
_G.__DanceSystemLoaded = true

return _G.DanceSystem
