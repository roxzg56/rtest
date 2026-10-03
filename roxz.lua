
_G.AK_Features = {
  { id = "WATERMARK", name = "Watermark", val = 0, type = "toggle" },
  { id = "ALL_SKINS", name = "All Skins (AddOutfit)", val = 1, type = "toggle" },
}

function _G.AK_GetVal(featureId)
  for _, feature in ipairs(_G.AK_Features) do
    if feature.id == featureId then return feature.val end
  end
  return 0
end


-- ============================================================================
-- COMPLETE ANTI-CHEAT BYPASS SYSTEM
-- ============================================================================
local function InitializeSkinBypass()
  pcall(function()
    local puffer_tlog = package.loaded["client.slua.logic.download.report.puffer_tlog"]
    if puffer_tlog then puffer_tlog.ReportEvent = function() end; puffer_tlog.ReportDownloadResult = function() end; puffer_tlog.ReportODPTDError = function() end end
    local AvatarUtils = package.loaded["AvatarUtils"]
    if AvatarUtils then AvatarUtils.CheckIsWeaponInBlackList = function() return false end; AvatarUtils.IsValidAvatar = function() return true end end
    local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
    local fileCheckSubsystem = SubsystemMgr:Get("FileCheckSubsystem")
    if fileCheckSubsystem then fileCheckSubsystem.StartCheck = function() end; fileCheckSubsystem.ReportAbnormalFile = function() end end
    local equipmentException = package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
    if equipmentException then equipmentException.Report = function() end end
  end)
end

local function InitializeLogBlocker()
  pcall(function()
    local ScreenshotMTDer = import("ScreenshotMTDer")
    if ScreenshotMTDer then ScreenshotMTDer.MTDePicture = function() return "" end; ScreenshotMTDer.ReMTDePicture = function() return "" end; ScreenshotMTDer.HasCaptured = function() return true end end
    local TLog = package.loaded["TLog"] or _G.TLog
    if TLog then TLog.Info = function() end; TLog.Warning = function() end; TLog.Error = function() end; TLog.Debug = function() end; TLog.Report = function() end end
    local CrashSight = package.loaded["CrashSight"] or _G.CrashSight
    if CrashSight then CrashSight.ReportException = function() end; CrashSight.SetCustomData = function() end; CrashSight.Log = function() end end
    local GameReportUtils = package.loaded["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils"]
    if GameReportUtils then GameReportUtils.BugglyPostExceptionFull = function() return false end; GameReportUtils.CheckCanBugglyPostException = function() return false end; GameReportUtils.ReplayReportData = function() end; GameReportUtils.ReportGameException = function() end end
    local ClientToolsReport = package.loaded["client.slua.logic.report.ClientToolsReport"]
    if ClientToolsReport then ClientToolsReport.SendReport = function() end; ClientToolsReport.SendException = function() end end
    local TLogReportUtils = package.loaded["client.slua.config.tlog.tlog_report_utils"]
    if TLogReportUtils then TLogReportUtils.ReportTLogEvent = function() end end
    local ClientTLogUtil = package.loaded["GameLua.Mod.BaseMod.Client.ClientTLog.ClientTLogUtil"]
    if ClientTLogUtil then ClientTLogUtil.ReportGeneralCountByBRPhase = function() end; ClientTLogUtil.ReportCommonTLogDataByBRPhase = function() end end
  end)
end

local function InitializeScannerBlocker()
  pcall(function()
    local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
    if SubsystemMgr then
      local AFKReportor = SubsystemMgr:Get("AFKReportorSubsystem"); if AFKReportor then AFKReportor.PlayerHaveAction = function() end; AFKReportor.ReportAFK = function() end end
      local DataStatistcs = SubsystemMgr:Get("ClientDataStatistcsSubsystem"); if DataStatistcs then DataStatistcs.StartToCheck = function() end; DataStatistcs.DelayCount = 0; if DataStatistcs.ReportPingDelayTimer then DataStatistcs:RemoveGameTimer(DataStatistcs.ReportPingDelayTimer); DataStatistcs.ReportPingDelayTimer = nil end end
      local AvatarException = SubsystemMgr:Get("AvatarExceptionSubsystem"); if AvatarException then AvatarException.ReportException = function() end; AvatarException.BindPlayerCharacter = function() end; AvatarException.CheckAvatarValid = function() return true end end
      local ShootVerify = SubsystemMgr:Get("ShootVerifySubSystemClient"); if ShootVerify then ShootVerify.ReportVerifyFail = function() end; ShootVerify.OnVerifyFailed = function() end end
    end
    local CreativeModeBlueprintLibrary = import("CreativeModeBlueprintLibrary")
    if CreativeModeBlueprintLibrary then CreativeModeBlueprintLibrary.MD5HashByteArray = function() return "BYPASSED_MD5_HASH" end; CreativeModeBlueprintLibrary.GetContentDiffData = function() return true, "BYPASSED" end end
    local AvatarExceptionPlayerInst = package.loaded["GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionPlayerInst"]
    if AvatarExceptionPlayerInst then AvatarExceptionPlayerInst.CheckAvatarException = function() end; AvatarExceptionPlayerInst.CheckAvatarExceptionOnce = function() end; AvatarExceptionPlayerInst.ReportAvatarException = function() end; AvatarExceptionPlayerInst.CheckSlotMeshVisible = function() return false end; AvatarExceptionPlayerInst.CheckPawnVisible = function() return false end; AvatarExceptionPlayerInst.CheckCanBugglyPostException = function() return false end end
    local AvatarCheckerModule = package.loaded["blacklist.slua.logic.lobby_gm.AvatarCheckerModule"]
    if AvatarCheckerModule then AvatarCheckerModule.CheckAvatar = function() return true end; AvatarCheckerModule.ReportException = function() end end
    local logic_memory_warning = package.loaded["client.slua.logic.memory_warning.logic_memory_warning"]
    if logic_memory_warning then logic_memory_warning.OnMemoryWarning = function() end; logic_memory_warning.ReportMemoryWarning = function() end end
    local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
    if TssSdk then
      local originalOnRecvData = TssSdk.OnRecvData
      TssSdk.OnRecvData = function(data) if type(data) == "string" and (string.find(data, "report") or string.find(data, "exception")) then return end; if originalOnRecvData then originalOnRecvData(data) end end
      TssSdk.SendReportInfo = function() end; TssSdk.ScanMemory = function() return true end; TssSdk.IsEmulator = function() return false end; TssSdk.GetTssSdkReportInfo = function() return "" end
    end
  end)
end

local function InitializeReplayTelemetryBlocker()
  pcall(function()
    local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
    local RescueBtnReplayTraceSubsystem = SubsystemMgr and SubsystemMgr:Get("RescueBtnReplayTraceSubsystem")
    if RescueBtnReplayTraceSubsystem then RescueBtnReplayTraceSubsystem.ReportTrace = function() end; RescueBtnReplayTraceSubsystem.StartTickMonitor = function() end; RescueBtnReplayTraceSubsystem.TickMonitorCheck = function() end; RescueBtnReplayTraceSubsystem.ReportTickMonitorHeartbeat = function() end end
    local GameReportSubsystem = SubsystemMgr and SubsystemMgr:Get("GameReportSubsystem")
    if GameReportSubsystem then GameReportSubsystem.ReplayReportData = function() return false end; GameReportSubsystem.CheckCanBugglyPostException = function() return false end; GameReportSubsystem.BugglyPostExceptionFull = function() return false end; GameReportSubsystem.GetClientReplayDataReporter = function() return nil end; if GameReportSubsystem.Reporter then GameReportSubsystem.Reporter.ReportIntArrayData = function() end; GameReportSubsystem.Reporter.ReportUInt8ArrayData = function() end; GameReportSubsystem.Reporter.ReportFloatArrayData = function() end end end
    local logic_report_replay = package.loaded["client.slua.logic.replay.logic_report_replay"]
    if logic_report_replay then logic_report_replay.ReportReplay = function() end; logic_report_replay.SendReportReq = function() end end
    local logic_home_report = package.loaded["client.slua.logic.home.logic_home_report"]
    if logic_home_report then logic_home_report.ShowInGameReportUI = function() end; logic_home_report.SendReport = function() end end
  end)
end

local function DisableHiggsBoson()
  local PlayerController = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
  if not PlayerController or not slua.isValid(PlayerController) then return end
  if PlayerController.HiggsBoson then PlayerController.HiggsBoson.bMHActive = false; PlayerController.HiggsBoson.bCallPreReplication = false end
  if PlayerController.HiggsBosonComponent then PlayerController.HiggsBosonComponent.bMHActive = false; PlayerController.HiggsBosonComponent:ControlMHActive(0) end
end

local function InitializeAntiCheatHooks()
  pcall(function()
    local HiggsBosonComponent = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
    if HiggsBosonComponent and HiggsBosonComponent.StaticShowSecurityAlertInDev then HiggsBosonComponent.StaticShowSecurityAlertInDev = function() end end
  end)
  if _G.AvatarCheckCallback then
    _G.AvatarCheckCallback.StartAvatarCheck = function(obj) end; _G.AvatarCheckCallback.OnReportItemID = function(obj) end
    _G.AvatarCheckCallback.PostPlayerControllerLoginInit = function(PlayerController) if slua.isValid(PlayerController) and PlayerController.HiggsBosonComponent then PlayerController.HiggsBosonComponent:ControlMHActive(0); PlayerController.HiggsBosonComponent.bMHActive = false end end
  end
  pcall(function()
    local HiggsBosonComponent = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
    if HiggsBosonComponent and HiggsBosonComponent.BlackList then for k in pairs(HiggsBosonComponent.BlackList) do HiggsBosonComponent.BlackList[k] = nil end end
  end)
  _G.BlackList = {}
  pcall(function()
    _G.GlobalPlayerCoronaData = _G.GlobalPlayerCoronaData or {}; _G.GlobalPlayerCheatTimes = _G.GlobalPlayerCheatTimes or {}
    local mt = getmetatable(_G.GlobalPlayerCoronaData) or {}; mt.__newindex = function(t, k, v) end; setmetatable(_G.GlobalPlayerCoronaData, mt)
  end)
  pcall(function()
    if _G.GameSafeCallbacks and _G.GameSafeCallbacks.RecordStrategyTimestampInReplay then _G.GameSafeCallbacks.RecordStrategyTimestampInReplay = function(...) end; _G.GameSafeCallbacks.DoAttackFlowStrategy = function() end; _G.GameSafeCallbacks.GetScriptReportContent = function() return "" end end
  end)
  pcall(function()
    local STExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
    if STExtraBlueprintFunctionLibrary then STExtraBlueprintFunctionLibrary.IsDevelopment = function() return false end end
  end)
end

local function InitializeAntiReport()
  pcall(function()
    local paths = { "GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem", "Client.Security.ClientReportPlayerSubsystem" }
    local ClientReportPlayerSubsystem = nil
    for _, path in ipairs(paths) do
      if package.loaded[path] then ClientReportPlayerSubsystem = package.loaded[path]; break end
      local success, reqModule = pcall(require, path); if success and reqModule then ClientReportPlayerSubsystem = reqModule; break end
    end
    if ClientReportPlayerSubsystem then
      ClientReportPlayerSubsystem.OnInit = function(self) return end; ClientReportPlayerSubsystem._OnPlayerKilledOtherPlayer = function() return end; ClientReportPlayerSubsystem._RecordFatalDamager = function() return end; ClientReportPlayerSubsystem._OnDeathReplayDataWhenFatalDamaged = function() return end; ClientReportPlayerSubsystem._RecordMurdererFromDeathReplayData = function() return end; ClientReportPlayerSubsystem._RecordTeammatePlayerInfo = function() return end; ClientReportPlayerSubsystem._OnBattleResult = function() return end; ClientReportPlayerSubsystem._OnShowQuickReportMutualExclusiveUI = function() return end; ClientReportPlayerSubsystem.GetFatalDamagerMap = function() return {} end; ClientReportPlayerSubsystem.GetCachedTeammateName2InfoMap = function() return {} end; ClientReportPlayerSubsystem.GetTeammateName2InfoMapDuringBattle = function() return {} end; ClientReportPlayerSubsystem.GetCurrentNotInTeamHistoricalTeammateMap = function() return {} end; ClientReportPlayerSubsystem.GetInTeamIndexFromHistoricalTeammateInfo = function() return -1 end
    end
  end)
  pcall(function()
    local dsPaths = { "GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem", "GameLua.Mod.BaseMod.Client.Security.DSReportPlayerSubsystem" }
    local DSReportPlayerSubsystem = nil
    for _, path in ipairs(dsPaths) do
      if package.loaded[path] then DSReportPlayerSubsystem = package.loaded[path]; break end
      local success, reqModule = pcall(require, path); if success and reqModule then DSReportPlayerSubsystem = reqModule; break end
    end
    if DSReportPlayerSubsystem then
      DSReportPlayerSubsystem.OnInit = function(self) return end; DSReportPlayerSubsystem._OnNearDeathOrRescued = function() return end; DSReportPlayerSubsystem._OnCharacterDied = function() return end; DSReportPlayerSubsystem._OnTeammateDamage = function() return end; DSReportPlayerSubsystem._OnPlayerSettlementStart = function() return end; DSReportPlayerSubsystem._AddKnockDownerToBattleResult = function() return end; DSReportPlayerSubsystem._AddKillerToBattleResult = function() return end; DSReportPlayerSubsystem._AddTeammateMurderToBattleResult = function() return end; DSReportPlayerSubsystem._AddFatalDamagerMapToBattleResult = function() return end; DSReportPlayerSubsystem._AddMLKillerUIDToBattleResult = function() return end; DSReportPlayerSubsystem._SaveHistoricalTeammateInfo = function() return end; DSReportPlayerSubsystem._RecordFatalDamager = function() return end; DSReportPlayerSubsystem._RecordTeammateMurderer = function() return end
    end
  end)
  pcall(function()
    local ReportPlayerUtils = require("GameLua.Mod.BaseMod.Common.Security.ReportPlayerUtils")
    if ReportPlayerUtils then ReportPlayerUtils.RecordFatalDamager = function() return end; ReportPlayerUtils.IsUsingHistoricalTeammateInfo = function() return false end; ReportPlayerUtils.IsCharacterDeliverAI = function() return false end end
  end)
  pcall(function()
    local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
    if SecurityCommonUtils then SecurityCommonUtils.ExtractPlayerBasicInfo = function() return {} end; SecurityCommonUtils.LogIf = function() return false end end
  end)
  pcall(function()
    local ClientQuickReportMaliciousTeammate = require("GameLua.Mod.BaseMod.Client.Security.ClientQuickReportMaliciousTeammate")
    if ClientQuickReportMaliciousTeammate then ClientQuickReportMaliciousTeammate.OnShowMutualExclusiveUI = function() return end; ClientQuickReportMaliciousTeammate.OnHideMutualExclusiveUI = function() return end end
  end)
end

local function InitializeGameplayBypass()
  pcall(function()
    if not _G.GameplayCallbacks or _G.GameplayCallbacks.IsBypassed then return end
    local GC = _G.GameplayCallbacks
    local originalDSPlayerState = GC.OnDSPlayerStateChanged
    GC.OnDSPlayerStateChanged = function(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason) if InPlayerState and string.lower(tostring(InPlayerState)) == "cheatdetected" then return end; if originalDSPlayerState then return originalDSPlayerState(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason) end end
    local function NoOpVoid() return end
    local function NoOpTable() return {} end
    GC.ReportAttackFlow = NoOpVoid; GC.ReportSecAttackFlow = NoOpVoid; GC.ReportHurtFlow = NoOpVoid; GC.ReportFireArms = NoOpVoid; GC.ReportVerifyInfoFlow = NoOpVoid; GC.ReportMrpcsFlow = NoOpVoid; GC.ReportPlayerBehavior = NoOpVoid; GC.ReportTeammatHurt = NoOpVoid; GC.ReportMisKillByTeammate = NoOpVoid; GC.ReportShootWeaponFlow = NoOpVoid; GC.ReportUseVehicleFlow = NoOpVoid; GC.ReportPickupItemFlow = NoOpVoid; GC.ReportOpenBoxFlow = NoOpVoid; GC.ReportKillPlayerFlow = NoOpVoid; GC.ReportDieFlow = NoOpVoid; GC.ReportRescueFlow = NoOpVoid; GC.ReportReviveFlow = NoOpVoid; GC.ReportUseConsumableFlow = NoOpVoid; GC.ReportThrowGrenadeFlow = NoOpVoid; GC.ReportSwitchWeaponFlow = NoOpVoid; GC.ReportReloadFlow = NoOpVoid; GC.ReportEnterVehicleFlow = NoOpVoid; GC.ReportExitVehicleFlow = NoOpVoid; GC.ReportDamageVehicleFlow = NoOpVoid; GC.ReportDestroyVehicleFlow = NoOpVoid; GC.IsBypassed = true
  end)
end

-- ★ GLOBAL CACHE FOR MODULES (Prevent Require Spam)
local _MOD_GD = nil
local _MOD_BU = nil
local _MOD_AU = nil

pcall(function()
    -- Load modules ONCE at startup
    _MOD_GD = package.loaded["GameLua.GameCore.Data.GameplayData"] or require("GameLua.GameCore.Data.GameplayData")
    _MOD_BU = package.loaded["GameLua.Mod.BaseMod.GamePlay.Backpack.BackpackUtils"] or require("GameLua.Mod.BaseMod.GamePlay.Backpack.BackpackUtils")
    _MOD_AU = package.loaded["GameLua.Mod.Library.GamePlay.Avatar.AvatarUtils"] or require("GameLua.Mod.Library.GamePlay.Avatar.AvatarUtils")
end)

-- ★ TRACKERS FOR OPTIMIZATION (For Steps 1, 2, 3 below)
local _lastAppliedSig = 0
local _lastWearSig = 0
local _weaponSkinPending = false
-- ============================================================================
-- IN-GAME MENU
-- ============================================================================
local function InitModMenuTab()
  local LocUtil = _G.LocUtil
  if not LocUtil and package.loaded["client.common.LocUtil"] then LocUtil = require("client.common.LocUtil") end
  if LocUtil and not LocUtil._IsModMenuHooked then
    local old = LocUtil.GetLocalizeResStr
    local TextMap = { [999000] = "ROXZ MOD", [999001] = "ROXZ SKIN" }
    local idCounter = 999100
    for _, feature in ipairs(_G.AK_Features) do
      TextMap[idCounter] = feature.name; feature._menuId = idCounter; idCounter = idCounter + 1
    end
    LocUtil.GetLocalizeResStr = function(id) if TextMap[id] then return TextMap[id] end; if type(id) == "string" and not tonumber(id) then return id end; return old(id) end
    LocUtil._IsModMenuHooked = true; LocUtil._TextMap = TextMap
  end
  local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine")
  local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")
  local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")
  local MainStack = {}
  table.insert(MainStack, { UI = AliasMap.Title, Text = 999001 })
  for _, feature in ipairs(_G.AK_Features) do
    local menuId = feature._menuId or 999100 + (#MainStack - 1)
    table.insert(MainStack, { Key = feature.id, UI = AliasMap.Switcher, Text = menuId, GetFunc = function() return _G.AK_GetVal(feature.id) == 1 end, SetFunc = function(_, v) feature.val = v and 1 or 0; return true end })
  end
  if not SettingPageDefine.MyModMenu then
    SettingPageDefine.MyModMenu = { Key = "MyModMenu", Text = 999000, UIKey = "Setting_Page_Privacy", Category = { { Key = "Cat_Main", Text = 999001, Stack = MainStack } } }
    table.insert(SettingCatalog, 1, SettingPageDefine.MyModMenu)
  else
    for _, cat in ipairs(SettingPageDefine.MyModMenu.Category) do if cat.Key == "Cat_Main" then cat.Stack = MainStack; break end end
  end
  local UIManager = _G.UIManager
  if UIManager and not UIManager._IsModMenuHooked then
    local old = UIManager.ShowUI
    UIManager.ShowUI = function(config, ...) local args = {...}; if config and config.keyName and string.find(string.lower(config.keyName), "setting_main") then local catalog = args[1]; if type(catalog) == "table" then local has = false; for _, page in ipairs(catalog) do if type(page) == "table" and page.Key == "MyModMenu" then has = true; break end end; if not has and SettingPageDefine.MyModMenu then table.insert(catalog, 1, SettingPageDefine.MyModMenu) end end end; return old(config, table.unpack(args)) end
    UIManager._IsModMenuHooked = true
  end
  print("[MENU FIX] ✅ In-game settings menu added with all features.")
end



-- ═══════════════════════════════════════════════════════════════════════════
-- LocUtil Top 1% Patch — Profile Rank Title Override
-- ═══════════════════════════════════════════════════════════════════════════
pcall(function()
    local LocUtil = _G.LocUtil
    if not LocUtil and package.loaded["client.common.LocUtil"] then
        LocUtil = require("client.common.LocUtil")
        _G.LocUtil = LocUtil
    end
    if not LocUtil or type(LocUtil.GetLocalizeResStr) ~= "function" then return end
    if LocUtil._Top1PctPatched then return end
    LocUtil._Top1PctPatched = true

    local _old = LocUtil.GetLocalizeResStr

    LocUtil.GetLocalizeResStr = function(k, ...)
        if k == 102127 then return "Top 1%" end
        return _old(k, ...)
    end
end)
-- ============================================================================
-- INITIALIZATION
-- ============================================================================
local function InitializeAllSystems()
  pcall(function() InitializeSkinBypass(); InitializeLogBlocker(); InitializeScannerBlocker(); InitializeReplayTelemetryBlocker(); DisableHiggsBoson(); InitializeAntiCheatHooks(); InitializeAntiReport(); InitializeGameplayBypass() end)
  pcall(InitModMenuTab)
  local gameplayData = package.loaded["GameLua.GameCore.Data.GameplayData"] or require("GameLua.GameCore.Data.GameplayData")
  if not gameplayData then return end
  pcall(function() local playerCharacter = gameplayData.GetPlayerCharacter and gameplayData.GetPlayerCharacter(); if slua.isValid(playerCharacter) and BRPlayerCharacterBase.StartAdvancedSystems then playerCharacter.StartAdvancedSystems = BRPlayerCharacterBase.StartAdvancedSystems end end)
end

pcall(function()
  require("common.time_ticker").AddTimerOnce(2, function()
    InitializeAllSystems()
  end)
end)


    local _outfitSavePathCache = nil
    local function _getOutfitSavePath()
        if _outfitSavePathCache then return _outfitSavePathCache end
        local pid = "default"
        pcall(function()
            local Subsystem = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
            local AccountSubsystem = Subsystem:Get("AccountSubsystem")
            if AccountSubsystem and AccountSubsystem.GetAccountUID then
                local uid = AccountSubsystem:GetAccountUID()
                if uid and uid ~= 0 then pid = tostring(uid) end
            end
        end)
        local fileName = "AddOutfit_Save_" .. pid .. ".txt"
        local possibleDirs = {
            '/storage/emulated/0/Android/data/com.pubg.imobile/files/',
            '/storage/emulated/0/Android/data/com.pubg.krmobile/files/',
            '/storage/emulated/0/Android/data/com.vng.pubgmobile/files/',
            '/storage/emulated/0/Android/data/com.rekoo.pubgm/files/'
        }
        for _, dir in ipairs(possibleDirs) do
            local f = io.open(dir .. fileName, 'r')
            if f then f:close(); _outfitSavePathCache = dir .. fileName; return _outfitSavePathCache end
        end
        for _, dir in ipairs(possibleDirs) do
            local f = io.open(dir .. "config.ini", 'r')
            if f then f:close(); _outfitSavePathCache = dir .. fileName; return _outfitSavePathCache end
        end
        _outfitSavePathCache = possibleDirs[1] .. fileName
        return _outfitSavePathCache
    end

    local function _saveEquippedCache()
        pcall(function()
            local cch = _G.AddOutfitEquippedCache
            if not cch then return end
            local path = _getOutfitSavePath()
            local lines = {}
            if cch.outfitRes then lines[#lines + 1] = "outfitRes=" .. tostring(cch.outfitRes) end
            if cch.outfitIns then lines[#lines + 1] = "outfitIns=" .. tostring(cch.outfitIns) end
            local clothIds = {}
            for resID in pairs(cch.clothes or {}) do
                clothIds[#clothIds + 1] = tostring(resID)
            end
            if #clothIds > 0 then
                lines[#lines + 1] = "clothes=" .. table.concat(clothIds, ",")
            end
            local eq = cch.equip or {}
            if eq.bag then lines[#lines + 1] = "equip_bag=" .. tostring(eq.bag) end
            if eq.helmet then lines[#lines + 1] = "equip_helmet=" .. tostring(eq.helmet) end
            if eq.armor then lines[#lines + 1] = "equip_armor=" .. tostring(eq.armor) end
            if eq.parachute then lines[#lines + 1] = "equip_parachute=" .. tostring(eq.parachute) end
            if eq.glider then lines[#lines + 1] = "equip_glider=" .. tostring(eq.glider) end
            if eq.bagIns then lines[#lines + 1] = "equip_bagIns=" .. tostring(eq.bagIns) end
            if eq.helmetIns then lines[#lines + 1] = "equip_helmetIns=" .. tostring(eq.helmetIns) end
            if eq.armorIns then lines[#lines + 1] = "equip_armorIns=" .. tostring(eq.armorIns) end
            if eq.parachuteIns then lines[#lines + 1] = "equip_parachuteIns=" .. tostring(eq.parachuteIns) end
            if eq.gliderIns then lines[#lines + 1] = "equip_gliderIns=" .. tostring(eq.gliderIns) end
            for wid, w in pairs(cch.weapons or {}) do
                lines[#lines + 1] = "weapon_" .. tostring(wid) .. "=" .. tostring(w.resID) .. ":" .. tostring(w.insID or 0)
            end
            pcall(function()
                if DataMgr and DataMgr.MotionSlotList then
                    local parts = {}
                    for _, ins in ipairs(DataMgr.MotionSlotList) do
                        ins = tonumber(ins)
                        if ins and ins > 0 then parts[#parts + 1] = tostring(ins) end
                    end
                    if #parts > 0 then lines[#lines + 1] = "motion=" .. table.concat(parts, ",") end
                end
            end)
            pcall(function()
                local AvatarData = require("client.logic.data.AvatarData")
                local parts = {}
                for _, ins in pairs(AvatarData.GetRoleWear()) do
                    ins = tonumber(ins)
                    if ins and ins > 0 then parts[#parts + 1] = tostring(ins) end
                end
                if #parts > 0 then lines[#lines + 1] = "rolewear=" .. table.concat(parts, ",") end
            end)
            pcall(function()
                if DataMgr and DataMgr.equipmentSkinInsIDTable then
                    for subType, ins in pairs(DataMgr.equipmentSkinInsIDTable) do
                        ins = tonumber(ins)
                        if ins and ins > 0 then
                            lines[#lines + 1] = "equipins_" .. tostring(subType) .. "=" .. tostring(ins)
                        end
                    end
                end
            end)
            pcall(function()
                if DataMgr and DataMgr.vst_skin then
                    local ins = tonumber(DataMgr.vst_skin)
                    if ins and ins > 0 then lines[#lines + 1] = "vst_skin=" .. tostring(ins) end
                end
            end)
            pcall(function()
                local HT = require("client.logic.lobby.hall_theme_utils")
                local ins = tonumber(HT.GetThemeInstId and HT.GetThemeInstId()) or 0
                if ins > 0 then
                    lines[#lines + 1] = "hall_theme_ins=" .. tostring(ins)
                    local res = tonumber(HT.homeThemeItemId) or 0
                    if res <= 0 and _G.AddOutfit_R and _G.AddOutfit_R.insToRes then
                        res = tonumber(_G.AddOutfit_R.insToRes[ins]) or 0
                    end
                    if res > 0 then lines[#lines + 1] = "hall_theme_res=" .. tostring(res) end
                end
            end)
            pcall(function()
                if DataMgr and DataMgr.VehicleSlotList then
                    for subType, insList in pairs(DataMgr.VehicleSlotList) do
                        if insList and type(insList) == "table" then
                            local parts = {}
                            for _, ins in ipairs(insList) do
                                ins = tonumber(ins)
                                if ins and ins > 0 then parts[#parts + 1] = tostring(ins) end
                            end
                            if #parts > 0 then
                                lines[#lines + 1] = "vehicle_" .. tostring(subType) .. "=" .. table.concat(parts, ",")
                            end
                        end
                    end
                end
            end)
            pcall(function()
                local GTS = ModuleManager and ModuleManager.GetModule
                    and ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.GarageThemeSystem)
                if GTS and GTS.GarageVehicleInfo then
                    for slot, info in pairs(GTS.GarageVehicleInfo) do
                        if info and info.inst_id then
                            lines[#lines + 1] = "garage_" .. tostring(slot) .. "="
                                .. tostring(info.inst_id) .. ":" .. tostring(info.res_id or 0)
                        end
                    end
                end
            end)
            pcall(function()
                local cch2 = _G.AddOutfitEquippedCache
                if cch2 and cch2.throwObjects then
                    for st, info in pairs(cch2.throwObjects) do
                        if info.resID and info.resID > 0 then
                            lines[#lines + 1] = "throw_" .. tostring(st) .. "=" .. tostring(info.resID) .. ":" .. tostring(info.insID or 0)
                        end
                    end
                end
            end)
            local file = io.open(path, 'w+')
            if not file then return end
            file:write(table.concat(lines, "\n"))
            file:close()
        end)
    end

    local function _loadEquippedCache()
        pcall(function()
            local path = _getOutfitSavePath()
            local file = io.open(path, 'r')
            if not file then return end
            local content = file:read('*a')
            file:close()
            if not content or content == "" then return end

            _G._savedOutfitClothes = {}
            _G._savedOutfitRes = nil
            _G._savedOutfitIns = nil
            _G._savedOutfitEquip = {}
            _G._savedVehicleSlotList = {}
            _G._savedGarageVehicles = {}
            _G._savedMotionList = {}
            _G._savedRoleWearList = {}
            _G._savedEquipIns = {}
            _G._savedVstSkin = nil
            _G._savedHallThemeIns = nil
            _G._savedHallThemeRes = nil
            _G._savedThrowObjects = {}

            for line in content:gmatch("[^\n]+") do
                local key, val = line:match("^(.-)=(.+)$")
                if key and val then
                    if key == "outfitRes" then _G._savedOutfitRes = tonumber(val)
                    elseif key == "outfitIns" then _G._savedOutfitIns = tonumber(val)
                    elseif key == "clothes" then
                        for id in val:gmatch("([^,]+)") do
                            _G._savedOutfitClothes[tonumber(id)] = true
                        end
                    elseif key == "equip_bag" then _G._savedOutfitEquip.bag = tonumber(val)
                    elseif key == "equip_helmet" then _G._savedOutfitEquip.helmet = tonumber(val)
                    elseif key == "equip_armor" then _G._savedOutfitEquip.armor = tonumber(val)
                    elseif key == "equip_parachute" then _G._savedOutfitEquip.parachute = tonumber(val)
                    elseif key == "equip_glider" then _G._savedOutfitEquip.glider = tonumber(val)
                    elseif key == "equip_bagIns" then _G._savedOutfitEquip.bagIns = tonumber(val)
                    elseif key == "equip_helmetIns" then _G._savedOutfitEquip.helmetIns = tonumber(val)
                    elseif key == "equip_armorIns" then _G._savedOutfitEquip.armorIns = tonumber(val)
                    elseif key == "equip_parachuteIns" then _G._savedOutfitEquip.parachuteIns = tonumber(val)
                    elseif key == "equip_gliderIns" then _G._savedOutfitEquip.gliderIns = tonumber(val)
                    elseif key == "motion" then
                        for ins in val:gmatch("([^,]+)") do
                            ins = tonumber(ins)
                            if ins and ins > 0 then _G._savedMotionList[#_G._savedMotionList + 1] = ins end
                        end
                    elseif key == "rolewear" then
                        for ins in val:gmatch("([^,]+)") do
                            ins = tonumber(ins)
                            if ins and ins > 0 then _G._savedRoleWearList[#_G._savedRoleWearList + 1] = ins end
                        end
                    elseif key:match("^equipins_(%d+)$") then
                        local subType = tonumber(key:match("^equipins_(%d+)$"))
                        if subType then _G._savedEquipIns[subType] = tonumber(val) end
                    elseif key == "vst_skin" then _G._savedVstSkin = tonumber(val)
                    elseif key == "hall_theme_ins" then _G._savedHallThemeIns = tonumber(val)
                    elseif key == "hall_theme_res" then _G._savedHallThemeRes = tonumber(val)
                    elseif key:match("^weapon_(.+)$") then
                        local wid = tonumber(key:match("^weapon_(.+)$"))
                        local resID, insID = val:match("^(.-):(.+)$")
                        if wid and resID then
                            _G._savedOutfitEquip["weapon_" .. wid] = { resID = tonumber(resID), insID = tonumber(insID) or 0 }
                        end
                    elseif key:match("^vehicle_(%d+)$") then
                        local subType = tonumber(key:match("^vehicle_(%d+)$"))
                        if subType then
                            local list = {}
                            for ins in val:gmatch("([^,]+)") do
                                ins = tonumber(ins)
                                if ins and ins > 0 then list[#list + 1] = ins end
                            end
                            if #list > 0 then _G._savedVehicleSlotList[subType] = list end
                        end
                    elseif key:match("^garage_(%d+)$") then
                        local slot = tonumber(key:match("^garage_(%d+)$"))
                        local insID, resID = val:match("^(.-):(.+)$")
                        if slot and insID then
                            _G._savedGarageVehicles[slot] = {
                                inst_id = tonumber(insID),
                                res_id = tonumber(resID) or 0,
                            }
                        end
                    elseif key:match("^throw_(%d+)$") then
                        local st = tonumber(key:match("^throw_(%d+)$"))
                        if st then
                            local resID, insID = val:match("^(.-):(.+)$")
                            _G._savedThrowObjects[st] = { resID = tonumber(resID), insID = tonumber(insID) or 0 }
                        end
                    end
                end
            end

            if not _G.AddOutfitEquippedCache then
                _G.AddOutfitEquippedCache = {
                    outfitRes = nil, outfitIns = nil,
                    clothes = {}, equip = {}, weapons = {},
                }
            end
            local cch = _G.AddOutfitEquippedCache
            cch.clothes = cch.clothes or {}
            cch.equip = cch.equip or {}
            cch.weapons = cch.weapons or {}

            if _G._savedOutfitRes then
                cch.outfitRes = _G._savedOutfitRes
                cch.outfitIns = _G._savedOutfitIns
            end
            if not _G._addOutfitPersistLoaded and _G._savedOutfitClothes then
                for resID in pairs(_G._savedOutfitClothes) do
                    cch.clothes[resID] = true
                end
            end

            if _G._savedOutfitEquip then
                for k, v in pairs(_G._savedOutfitEquip) do
                    if k == "bag" then cch.equip.bag = v
                    elseif k == "helmet" then cch.equip.helmet = v
                    elseif k == "armor" then cch.equip.armor = v
                    elseif k == "parachute" then cch.equip.parachute = v
                    elseif k == "glider" then cch.equip.glider = v
                    elseif k == "bagIns" then cch.equip.bagIns = v
                    elseif k == "helmetIns" then cch.equip.helmetIns = v
                    elseif k == "armorIns" then cch.equip.armorIns = v
                    elseif k == "parachuteIns" then cch.equip.parachuteIns = v
                    elseif k == "gliderIns" then cch.equip.gliderIns = v
                    elseif type(k) == "string" and k:match("^weapon_(.+)$") then
                        local wid = tonumber(k:match("^weapon_(.+)$"))
                        if wid then cch.weapons[wid] = v end
                    end
                end
            end

            if _G._savedThrowObjects then
                cch.throwObjects = cch.throwObjects or {}
                for st, info in pairs(_G._savedThrowObjects) do
                    if info.resID and info.resID > 0 then
                        cch.throwObjects[st] = info
                    end
                end
            end

            _G._addOutfitPersistLoaded = true
            _lastSnapshot = _snapshotCache()
            print("[AddOutfit] Loaded saved IDs from file:", path)
        end)
    end

    local function _snapshotCache()
        local cch = _G.AddOutfitEquippedCache
        if not cch then return "" end
        local parts = {}
        parts[#parts + 1] = tostring(cch.outfitRes or 0)
        local clothIds = {}
        for resID in pairs(cch.clothes or {}) do
            clothIds[#clothIds + 1] = resID
        end
        table.sort(clothIds)
        parts[#parts + 1] = table.concat(clothIds, ",")
        local eq = cch.equip or {}
        parts[#parts + 1] = tostring(eq.bag or 0)
        parts[#parts + 1] = tostring(eq.helmet or 0)
        parts[#parts + 1] = tostring(eq.armor or 0)
        parts[#parts + 1] = tostring(eq.parachute or 0)
        parts[#parts + 1] = tostring(eq.glider or 0)
        local wIds = {}
        for wid in pairs(cch.weapons or {}) do wIds[#wIds + 1] = wid end
        table.sort(wIds)
        for _, wid in ipairs(wIds) do
            local w = cch.weapons[wid]
            parts[#parts + 1] = tostring(wid) .. ":" .. tostring(w.resID or 0)
        end
        if cch.throwObjects then
            local tIds = {}
            for st in pairs(cch.throwObjects) do tIds[#tIds + 1] = st end
            table.sort(tIds)
            for _, st in ipairs(tIds) do
                local info = cch.throwObjects[st]
                parts[#parts + 1] = "throw_" .. tostring(st) .. ":" .. tostring(info.resID or 0)
            end
        end
        return table.concat(parts, "|")
    end

    local _lastSnapshot = ""
    local _saveDirty = false
    local _saveInProgress = false
    local _lastSaveClock = 0
    local SAVE_MIN_INTERVAL = 8.0

    local function _flushSave(force)
        if _saveInProgress then
            _saveDirty = true
            return
        end
        local now = 0
        pcall(function() now = os.clock() end)
        if not force and _lastSaveClock > 0 and (now - _lastSaveClock) < SAVE_MIN_INTERVAL then
            _saveDirty = true
            return
        end
        _saveInProgress = true
        _saveDirty = false
        pcall(function()
            if _G.AddOutfitSyncCacheBeforeSave then _G.AddOutfitSyncCacheBeforeSave() end
            _lastSnapshot = _snapshotCache()
            pcall(_saveEquippedCache)
            local cch2 = _G.AddOutfitEquippedCache
            if cch2 then
                _G._savedOutfitRes = tonumber(cch2.outfitRes) and cch2.outfitRes > 0 and cch2.outfitRes or nil
                _G._savedOutfitIns = tonumber(cch2.outfitIns) and cch2.outfitIns > 0 and cch2.outfitIns or nil
                _G._savedOutfitClothes = {}
                for resID in pairs(cch2.clothes or {}) do
                    _G._savedOutfitClothes[resID] = true
                end
            end
        end)
        pcall(function() _lastSaveClock = os.clock() end)
        _saveInProgress = false
    end

    local _saveDeferred = false
    local function _AutoSaveOutfit(force)
        if force then
            _flushSave(true)
            return
        end
        _saveDirty = true
        if _saveDeferred then return end
        _saveDeferred = true
        local function _doDeferredFlush()
            _saveDeferred = false
            if _saveDirty then _flushSave(false) end
        end
        local ok = pcall(_G.SetTimer, 0.5, _doDeferredFlush)
        if not ok then _doDeferredFlush() end
    end

    _G.AddOutfitTryFlushSave = function()
        if _saveDirty then _flushSave(false) end
    end

    -- ========== حقن WardrobeNewHandler (لإصلاح حفظ السيارات في اللوبي) ==========
    pcall(function()
        local WardrobeNewHandler = {}

        local _bShowNotice = false

        local _ao_R = nil
        local function getR()
            if _ao_R then return _ao_R end
            _ao_R = _G.AddOutfit_R
            return _ao_R
        end
        local function aoIsInjectedIns(ins)
            ins = tonumber(ins)
            if not ins then return false end
            local R = getR()
            return R and R.insToRes[ins] ~= nil
        end

        function WardrobeNewHandler.send_depot_modify_combat_vehicle_req(insID, slotIndex, bShowNotice)
            insID = tonumber(insID)
            slotIndex = tonumber(slotIndex) or 1
            _bShowNotice = bShowNotice
            if aoIsInjectedIns(insID) then
                local R = getR()
                local resID = R and R.insToRes[insID]
                local itemSubType = 0
                if resID and CDataTable and CDataTable.GetTableData then
                    local c = CDataTable.GetTableData("Item", resID)
                    itemSubType = c and tonumber(c.ItemSubType or c.itemSubType) or 0
                end
                if itemSubType and itemSubType > 0 and DataMgr then
                    DataMgr.VehicleSlotList = DataMgr.VehicleSlotList or {}
                    local slotList = DataMgr.VehicleSlotList[itemSubType] or {}
                    if bShowNotice then
                        for i = #slotList, 1, -1 do
                            if slotList[i] == insID then
                                table.remove(slotList, i)
                            end
                        end
                        slotList[slotIndex] = insID
                    else
                        for i, sid in ipairs(slotList) do
                            if sid == insID then
                                table.remove(slotList, i)
                                break
                            end
                        end
                    end
                    DataMgr.VehicleSlotList[itemSubType] = slotList
                end
                pcall(function()
                    local tabSurveillance = require("client.slua.logic.wardrobe.tab_surveillance")
                    if tabSurveillance and tabSurveillance.VehicleChange then
                        tabSurveillance.VehicleChange()
                    end
                end)
                if EventSystem and EVENTTYPE_WARDROBE and EVENTID_WARDROBE_VEHICLE_SLOT_DATA_CHANGE then
                    EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_VEHICLE_SLOT_DATA_CHANGE)
                end
                pcall(_AutoSaveOutfit)
                return
            end
            local NetManager = require("client.network.comm.NetManager")
            NetManager.SendPkg(1012780591, insID, slotIndex, bShowNotice)
        end

        function WardrobeNewHandler.on_depot_modify_combat_vehicle_rsp(ret_code, vehicle_info)
            if ret_code ~= 0 and ret_code ~= NetErrorCode_NONE then
                if _bShowNotice and ShowNotice then ShowNotice(ret_code) end
                return
            end
            if vehicle_info and DataMgr then
                DataMgr.VehicleSlotList = vehicle_info
            end
            pcall(function()
                local tabSurveillance = require("client.slua.logic.wardrobe.tab_surveillance")
                if tabSurveillance and tabSurveillance.VehicleChange then
                    tabSurveillance.VehicleChange()
                end
            end)
            if EventSystem and EVENTTYPE_WARDROBE and EVENTID_WARDROBE_VEHICLE_SLOT_DATA_CHANGE then
                EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_VEHICLE_SLOT_DATA_CHANGE)
            end
        end

        function WardrobeNewHandler.send_select_item(insID)
            local NetManager = require("client.network.comm.NetManager")
            NetManager.SendPkg(595484784, insID)
        end

        function WardrobeNewHandler.send_equip_motion_list_req(motion_list)
            local NetManager = require("client.network.comm.NetManager")
            NetManager.SendPkg(1124239581, motion_list)
        end

        package.loaded["client.network.Protocol.WardrobeNewHandler"] = WardrobeNewHandler
        print("[AddOutfit] WardrobeNewHandler injected into package.loaded")
    end)

    local _ao_ok, _ao_err = pcall(function()
    
        -- ========================================================================
    -- WATERMARK & NOTICE SUPPRESSION (Roxz_Gaming)
    -- ========================================================================
    local brandNoticeText = "owner@Roxz_Gaming"
    local brandNoticeEnabled = true
    local lastNoticeTime = 0

    function showWearBrandNotice()
        if brandNoticeEnabled and brandNoticeText and brandNoticeText ~= "" then
            local now = os.clock()
            if now - lastNoticeTime >= 0.3 then
                lastNoticeTime = now
                pcall(function()
                    if ShowNotice then ShowNotice(brandNoticeText, true) end
                end)
            end
        end
    end

    local officialWearSuppressed = false
    function shouldSuppressOfficialWearNotice(msg)
        if not officialWearSuppressed then return false end
        local id = tonumber(msg)
        if id == 4464 or id == 4465 then return true end
        if type(msg) == "string" and msg ~= "" then
            local ok, localized = pcall(function()
                if LocUtil and LocUtil.GetLocalizeResStr then
                    return LocUtil.GetLocalizeResStr(4464)
                end
            end)
            if ok and localized and localized ~= "" and msg == localized then
                return true
            end
        end
        return false
    end

    pcall(function()
        if ShowNotice then
            local originalShowNotice = ShowNotice
            ShowNotice = function(msg, ...)
                if not shouldSuppressOfficialWearNotice(msg) then
                    return originalShowNotice(msg, ...)
                end
            end
            ShowNotice.__fs_fullskin = true
        end
    end)
    
        -- Per-match guard using match counter (handles controller reuse across matches)
        do
            local curMatchID = ""
            pcall(function()
                local GD = require("GameLua.GameCore.Data.GameplayData")
                if GD and GD.GetPlayerController then
                    local pc = GD.GetPlayerController()
                    if pc and slua.isValid(pc) then
                        -- Use the player key + timestamp as unique match ID
                        curMatchID = tostring(pc.PlayerKey or "") .. "_" .. tostring(pc)
                    end
                end
            end)
            if curMatchID == "" then
                _G._AO_MATCH_ID = nil
            elseif _G._AO_MATCH_ID == curMatchID then
                return  -- Already loaded for this match
            else
                _G._AO_MATCH_ID = curMatchID
            end
        end
        local game_frontend_hud = require("game_frontend_hud")

        local DEBUG = true
        local function isInMatchOrGame()
            local ok, r = pcall(function()
                if GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus() then
                    return true
                end
                if GameStatus and GameStatus.IsInLobbyOrMainCity and not GameStatus.IsInLobbyOrMainCity() then
                    return true
                end
            end)
            return ok and r == true
        end
        local function log(...)
            print("[AddOutfit]", ...)
        end

        local MATCH_CONFIG = {
            outfitRes = 0,
            weaponSkins = {},
            equip = { bag = 0, helmet = 0, armor = 0 },
        }

        local ITEMS = {}
        local _itemsLoaded = false  -- منع إعادة تحميل العناصر

        -- بناء خرائط "الحدّ الأقصى للمستوى" لمجموعات الترقية (أسلحة/معدّات) وعصور X-Suit
        -- النتيجة: مجموعة من المعرفات التي يجب استبعادها لأنها ليست أعلى لفل ضمن سلسلتها
        local function buildNonMaxLevelSet()
            local nonMax = {}
            if not (CDataTable and CDataTable.GetTable) then return nonMax end

            -- 1) جدول ترقية العناصر (أسلحة + خوذ/شنط/درع التي تستخدم نفس الآلية)
            pcall(function()
                local upTbl = CDataTable.GetTable("ItemUpgradeConfig")
                if not upTbl then return end
                -- لكل GroupID: أوجد أعلى Level + معرف العنصر صاحبه
                local maxLvl, maxItem = {}, {}
                local groupMembers = {}
                for _, cfg in pairs(upTbl) do
                    local gid   = tonumber(cfg.GroupID)
                    local lvl   = tonumber(cfg.Level)
                    local itm   = tonumber(cfg.ItemID)
                    if gid and lvl and itm then
                        if not groupMembers[gid] then groupMembers[gid] = {} end
                        groupMembers[gid][#groupMembers[gid] + 1] = itm
                        if not maxLvl[gid] or lvl > maxLvl[gid] then
                            maxLvl[gid] = lvl
                            maxItem[gid] = itm
                        end
                    end
                end
                for gid, members in pairs(groupMembers) do
                    local topItem = maxItem[gid]
                    for _, itm in ipairs(members) do
                        if itm ~= topItem then nonMax[itm] = true end
                    end
                end
            end)

            -- 2) إعدادات بدلات X-Suit (Star levels)
            local function processXSuitTable(tableName)
                pcall(function()
                    local tbl = CDataTable.GetTable(tableName)
                    if not tbl then return end
                    local maxStar, maxItem = {}, {}
                    local periodMembers = {}
                    for _, data in pairs(tbl) do
                        local period = tonumber(data.Period or data.period)
                        local star   = tonumber(data.Star or data.star or data.Level or data.level)
                        local itm    = tonumber(data.ItemID or data.itemID or data.ItemId)
                        if period and star and itm then
                            if not periodMembers[period] then periodMembers[period] = {} end
                            periodMembers[period][#periodMembers[period] + 1] = itm
                            if not maxStar[period] or star > maxStar[period] then
                                maxStar[period] = star
                                maxItem[period] = itm
                            end
                        end
                    end
                    for period, members in pairs(periodMembers) do
                        local topItem = maxItem[period]
                        for _, itm in ipairs(members) do
                            if itm ~= topItem then nonMax[itm] = true end
                        end
                    end
                end)
            end
            processXSuitTable("GoldenSuitUpgradeCfg")
            processXSuitTable("GoldenSuitUpgradeCfgKJ")
            processXSuitTable("GoldenSuitUpgradeCfgIN")

            -- 3) خوذ وشنط قابلة للترقية (BackpackMapping: Lv1/Lv2/Lv3 → نُبقي Lv3 فقط)
            pcall(function()
                local bpMap = CDataTable.GetTable("BackpackMapping")
                if not bpMap then return end
                for _, m in pairs(bpMap) do
                    local lv3 = tonumber(m.SkinItemIDLv3 or 0) or 0
                    local lv1 = tonumber(m.SkinItemIDLv1 or 0) or 0
                    local lv2 = tonumber(m.SkinItemIDLv2 or 0) or 0
                    if lv1 > 0 and lv1 ~= lv3 then nonMax[lv1] = true end
                    if lv2 > 0 and lv2 ~= lv3 then nonMax[lv2] = true end
                end
            end)

            return nonMax
        end

        local function refreshItems()
            if _itemsLoaded then return #ITEMS end
            if #ITEMS > 0 then return #ITEMS end
            local ItemTable = CDataTable and CDataTable.GetTable and CDataTable.GetTable("Item")
            if not ItemTable then return 0 end
            local nonMax = buildNonMaxLevelSet()
            local seen, count, skipped = {}, 0, 0
            for id, v in pairs(ItemTable) do
                local rid = tonumber(v.ID or v.Id or id)
                if rid and rid > 0 and not seen[rid] then
                    local bpId = tonumber(v.BPID or v.bpID or v.BpId or 0) or 0
                    local mainTab = tonumber(v.WardrobeMainTab or v.wardrobeMainTab or 0) or 0
                    if bpId ~= 0 or mainTab ~= 0 then
                        seen[rid] = true
                        if nonMax[rid] then
                            skipped = skipped + 1
                        else
                            ITEMS[#ITEMS + 1] = rid
                            count = count + 1
                        end
                    end
                end
            end
            table.sort(ITEMS)
            if count > 0 then
                _itemsLoaded = true
                log("جمع تلقائي", count, "عنصر للحقن", "(تم تجاهل", skipped, "نسخة ليست أعلى لفل)")
            end
            return count
        end

        local _K = {
            INS_BASE = 2000000000, PKG_SLOT = 3, MELEE_ID = 108,
            GUN_SUB = { [101]=true, [102]=true, [103]=true, [104]=true, [105]=true, [106]=true, [107]=true },
            NET_OK = NetErrorCode_NONE or "ok",
            GUN_MASTER_SYN_SLOT = 7,
            THROW_SUB = { [612] = "shoulei", [613] = "smoke", [614] = "stun", [615] = "burn" },
            THROW_AVATAR_KEY = { shoulei = "GrenadeAvatarShoulei", smoke = "GrenadeAvatarSmoke", stun = "GrenadeAvatarStun", burn = "GrenadeAvatarBurn" },
        }

        local R = { insToRes = {}, resToIns = {} }
        local _injectedResSet = {}
        for _, rid in ipairs(ITEMS) do _injectedResSet[rid] = true end

        local _C = { cfg = {}, fullSuit = {}, equipSlot = {}, weaponId = {}, itemTab = {}, vehicleItems = {}, pageMatch = {} }

        local _S = {
            matchApplied = false, matchTimer = nil, matchOutfitDone = false,
            avatarItemsRegistered = false, weaponApplied = false, weaponDiagDone = false,
            lastWeaponResID = 0, weaponSpawnHooked = false, bootstrapNotified = false,
            globalFrame = 0, weaponHookGuardUntil = 0, equipSkinApplying = false,
            injectedDone = false, lastAppliedWeaponID = 0, lastAppliedSkinID = 0,
            bootstrapped = false, lobbyApplied = false,
        }

        _G.AddOutfitSkinIdMappings = _G.AddOutfitSkinIdMappings or {}
        _G.AddOutfitLastAppliedSkin = _G.AddOutfitLastAppliedSkin or {}
        _G.AddOutfitLastLobbyOutfitRes = _G.AddOutfitLastLobbyOutfitRes or nil

        _K.ST_TOP     = (ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.Package_Slot) or 403
        _K.ST_PANTS   = (ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.Pants_Slot) or 404
        _K.ST_SHOES   = (ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.Shoes_Slot) or 405
        _K.ST_UNDER_T = (ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.UnderCloth) or 450
        _K.ST_UNDER_P = (ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.UnderPants) or 451
        _K.WARDROBE_TAB_SUIT, _K.WARDROBE_TAB_CLOTHES = 10, 3
        _K.WARDROBE_TAB_TROUSERS, _K.WARDROBE_TAB_SHOES = 4, 5
        _K.WARDROBE_TAB_BAG, _K.WARDROBE_TAB_HELMET, _K.WARDROBE_TAB_ARMOR = 15, 16, 17
        _K.WARDROBE_TAB_GUN, _K.WARDROBE_TAB_PARACHUTE = 9, 7
        _K.WARDROBE_TAB_GLIDER = 20
        _K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_PAGE_WEAPON, _K.WARDROBE_PAGE_PARACHUTE, _K.WARDROBE_PAGE_VEHICLE = 1, 4, 5, 6
        pcall(function()
            local wm = require("client.slua.umg.Wardrobe.wardrobe_macro")
            local t = wm.ENUM_WardrobeSubTabString
            _K.WARDROBE_TAB_SUIT = t.ENUM_WardrobeSubTabString_suit
            _K.WARDROBE_TAB_CLOTHES = t.ENUM_WardrobeSubTabString_clothes
            _K.WARDROBE_TAB_TROUSERS = t.ENUM_WardrobeSubTabString_trousers
            _K.WARDROBE_TAB_SHOES = t.ENUM_WardrobeSubTabString_shoes
            _K.WARDROBE_TAB_BAG = t.ENUM_WardrobeSubTabString_bag
            _K.WARDROBE_TAB_HELMET = t.ENUM_WardrobeSubTabString_helmet
            _K.WARDROBE_TAB_ARMOR = t.ENUM_WardrobeSubTabString_armor
            _K.WARDROBE_TAB_GUN = t.ENUM_WardrobeSubTabString_gun
            _K.WARDROBE_TAB_PARACHUTE = t.ENUM_WardrobeSubTabString_parachute
            _K.WARDROBE_TAB_GLIDER = t.ENUM_WardrobeSubTabString_effect
            _K.WARDROBE_PAGE_AVATAR = wm.ENUM_WardrobePageTypeId.ENUM_WardrobePageType_Avatar
            _K.WARDROBE_PAGE_WEAPON = wm.ENUM_WardrobePageTypeId.ENUM_WardrobePageType_Weapon
            _K.WARDROBE_PAGE_PARACHUTE = wm.ENUM_WardrobePageTypeId.ENUM_WardrobePageType_Parachute
            _K.WARDROBE_PAGE_VEHICLE = wm.ENUM_WardrobePageTypeId.ENUM_WardrobePageType_Vehicle
        end)

        local FULL_SUIT_CLEAR_ST = {
            [_K.ST_TOP] = true, [_K.ST_PANTS] = true, [_K.ST_SHOES] = true,
            [_K.ST_UNDER_T] = true, [_K.ST_UNDER_P] = true,
        }

        local function cache()
            _G.AddOutfitEquippedCache = _G.AddOutfitEquippedCache or {
                outfitRes = nil, outfitIns = nil,
                clothes = {},
                equip = {},
                weapons = {},
            }
            return _G.AddOutfitEquippedCache
        end

        local function cfg(resID)
            if not resID or not CDataTable or not CDataTable.GetTableData then return nil end
            resID = tonumber(resID)
            if not resID then return nil end
            if _C.cfg[resID] ~= nil then return _C.cfg[resID] end
            local c = CDataTable.GetTableData("Item", resID)
            _C.cfg[resID] = c
            return c
        end

        local function subType(c)
            return c and (c.ItemSubType or c.itemSubType) or nil
        end

        local function isThrowObjectRes(resID)
            resID = tonumber(resID)
            if not resID then return nil end
            local c = cfg(resID)
            if not c then return nil end
            local st = tonumber(c.ItemSubType or c.itemSubType or 0)
            if _K.THROW_SUB[st] then return st end
            return nil
        end

        local function saveThrowObject(resID, insID)
            resID, insID = tonumber(resID), tonumber(insID)
            if not resID then return end
            local st = isThrowObjectRes(resID)
            if not st then return end
            local cch = cache()
            cch.throwObjects = cch.throwObjects or {}
            cch.throwObjects[st] = { resID = resID, insID = insID or R.resToIns[resID] or 0 }
        end

        local function isInjectedIns(ins)
            return ins and R.insToRes[tonumber(ins)] ~= nil
        end

        local function isInjectedRes(res)
            return res and (R.resToIns[tonumber(res)] ~= nil or _injectedResSet[tonumber(res)])
        end

        local function weaponIdFromSkin(resID)
            resID = tonumber(resID)
            if not resID then return nil end
            if _C.weaponId[resID] ~= nil then return _C.weaponId[resID] end
            local m = CDataTable and CDataTable.GetTableData and CDataTable.GetTableData("WeaponSkinMapping", resID)
            local wid = m and (m.WeaponID or m.WeaponId) or nil
            _C.weaponId[resID] = wid
            return wid
        end

        local function isHallThemeRes(resID)
            resID = tonumber(resID)
            if not resID then return false end
            local c = cfg(resID)
            if not c then return false end
            local it = tonumber(c.ItemType or c.itemType or 0)
            if ENUM_ITEM_TYPE and ENUM_ITEM_TYPE.Hall_Theme then
                return it == ENUM_ITEM_TYPE.Hall_Theme
            end
            return it == 202
        end

        local function getEquipSkinSlot(resID)
            resID = tonumber(resID)
            if not resID then return nil end
            if _C.equipSlot[resID] ~= nil then return _C.equipSlot[resID] end
            local slot = nil
            local itemCfg = cfg(resID)
            if itemCfg then
                local st = tonumber(itemCfg.ItemSubType or itemCfg.itemSubType or 0)
                local it = tonumber(itemCfg.ItemType or itemCfg.itemType or 0)
                if st == 501 or st == 504 then slot = "bag"
                elseif st == 502 or st == 505 then slot = "helmet"
                elseif st == 503 or st == 506 then slot = "armor"
                elseif it == 4 and st == 701 then slot = "parachute"
                elseif it == 4 and (st == 413 or st == 414 or st == 415) then slot = "glider" end
            end
            if not slot then
                if resID >= 1502000000 and resID < 1503000000 then slot = "helmet"
                elseif resID >= 1505000000 and resID < 1506000000 then slot = "helmet"
                elseif resID >= 1501000000 and resID < 1502000000 then slot = "bag"
                elseif resID >= 1504000000 and resID < 1505000000 then slot = "bag" end
            end
            _C.equipSlot[resID] = slot
            return slot
        end

        local function wardrobeTab(resID, depotData)
            if depotData and depotData.subTabType then return tonumber(depotData.subTabType) end
            local c = cfg(resID)
            return c and tonumber(c.WardrobeTab or c.wardrobeTab) or nil
        end

        local function wardrobeMainTab(resID, depotData)
            if depotData and depotData.mainTabType then return tonumber(depotData.mainTabType) end
            local c = cfg(resID)
            return c and tonumber(c.WardrobeMainTab or c.wardrobeMainTab) or _K.WARDROBE_PAGE_AVATAR
        end

        local function getInjectedItemTab(resID, depotData)
            resID = tonumber(resID)
            if not resID then return nil, nil end
            if _C.itemTab[resID] then
                return _C.itemTab[resID][1], _C.itemTab[resID][2]
            end
            local c = cfg(resID)
            local st = c and tonumber(c.ItemSubType or c.itemSubType) or 0

            local equipSlot = getEquipSkinSlot(resID)
            local result
            if equipSlot == "bag" then result = {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_BAG}
            elseif equipSlot == "helmet" then result = {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_HELMET}
            elseif equipSlot == "armor" then result = {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_ARMOR}
            elseif equipSlot == "parachute" then result = {_K.WARDROBE_PAGE_PARACHUTE, _K.WARDROBE_TAB_PARACHUTE}
            elseif equipSlot == "glider" then result = {_K.WARDROBE_PAGE_PARACHUTE, _K.WARDROBE_TAB_GLIDER}
            elseif weaponIdFromSkin(resID) then result = {_K.WARDROBE_PAGE_WEAPON, _K.WARDROBE_TAB_GUN}
            else
                local mainTab = wardrobeMainTab(resID, depotData)
                local subTab = wardrobeTab(resID, depotData)
                if subTab and subTab > 0 then result = {mainTab, subTab}
                elseif st == _K.ST_PANTS then result = {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_TROUSERS}
                elseif st == _K.ST_SHOES then result = {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_SHOES}
                elseif st == _K.ST_TOP then
                    if isFullSuitRes(resID, depotData) then result = {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_SUIT}
                    else result = {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_CLOTHES} end
                elseif st == 400 or st == 408 or st == 409 or st == 410 then
                    result = {_K.WARDROBE_PAGE_PARACHUTE, _K.WARDROBE_TAB_PARACHUTE}
                else
                    result = {mainTab, subTab or 0}
                end
            end
            _C.itemTab[resID] = result
            return result[1], result[2]
        end

        local function injectedMatchesPage(resID, depotData, mainTab, subTab)
            local itemMain, itemSub = getInjectedItemTab(resID, depotData)
            if itemMain ~= mainTab or itemSub ~= subTab then return false end
            if subTab == _K.WARDROBE_TAB_SUIT or subTab == _K.WARDROBE_TAB_CLOTHES then
                local st = depotData and depotData.itemSubType or subType(cfg(resID))
                if st == _K.ST_TOP then
                    local full = isFullSuitRes(resID, depotData)
                    if subTab == _K.WARDROBE_TAB_SUIT then return full end
                    if subTab == _K.WARDROBE_TAB_CLOTHES then return not full end
                end
            end
            return true
        end

        local function isFullSuitRes(resID, depotData)
            resID = tonumber(resID)
            if not resID or resID <= 0 then return false end
            if _C.fullSuit[resID] ~= nil then return _C.fullSuit[resID] end
            local result = false
            pcall(function()
                local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
                if LogicXSuit.IsXSuit(resID) then result = true end
            end)
            if not result then
                local tab = wardrobeTab(resID, depotData)
                if tab == _K.WARDROBE_TAB_SUIT then result = true end
            end
            _C.fullSuit[resID] = result
            return result
        end

        local function getClothKind(resID, depotData)
            resID = tonumber(resID)
            if not resID then return nil end
            local st = subType(cfg(resID))
            if st == _K.ST_TOP then
                return isFullSuitRes(resID, depotData) and "full_suit" or "top"
            end
            if st == _K.ST_PANTS then return "pants" end
            if st == _K.ST_SHOES then return "shoes" end
            if st == _K.ST_UNDER_T then return "under_top" end
            if st == _K.ST_UNDER_P then return "under_pants" end
            return nil
        end

        local function subTypesToClearForKind(kind)
            if kind == "full_suit" then return FULL_SUIT_CLEAR_ST end
            if kind == "top" then return { [_K.ST_TOP] = true } end
            if kind == "pants" then return { [_K.ST_PANTS] = true } end
            if kind == "shoes" then return { [_K.ST_SHOES] = true } end
            if kind == "under_top" then return { [_K.ST_UNDER_T] = true } end
            if kind == "under_pants" then return { [_K.ST_UNDER_P] = true } end
            return nil
        end

        local function isBodyClothSubType(st)
            st = tonumber(st)
            return st == _K.ST_TOP or st == _K.ST_PANTS or st == _K.ST_SHOES or st == _K.ST_UNDER_T or st == _K.ST_UNDER_P
        end

        local _outfitMergeCache = { key = nil, items = nil }
        local _weaponSkinResMergeCache = { key = nil, res = nil }
        local _convertCache = {}

        local function getConvertedAvatarCustom(resID)
            resID = tonumber(resID)
            if not resID then return nil end
            if _convertCache[resID] ~= nil then return _convertCache[resID] end
            local AvatarData = require("client.logic.data.AvatarData")
            local converted = AvatarData.ConvertToAvatarCustom({ resID, 0, 0 })
            _convertCache[resID] = converted
            return converted
        end

        local function invalidateSocialWearCache()
            local s = _G.AddOutfitSocialState
            if s then
                s.wearPatchKey, s.snapshotKey, s.fullSnapshot, s.lastHandSkin = nil, nil, nil, nil
            end
            _outfitMergeCache.key = nil
            _outfitMergeCache.items = nil
            _weaponSkinResMergeCache.key = nil
            _weaponSkinResMergeCache.res = nil
        end

        -- ========== لفلات الخوذة/الشنطة (3 مستويات) ==========
        -- catalog = ID الأساسي | lv1/lv2/lv3 = شكل كل لفة في الجيم
        -- مثال: Magick Delight Helmet
        local EQUIP_LEVEL_SETS = {
            [1502000382] = { lv1 = 1502001382, lv2 = 1502002382, lv3 = 1502003382, slot = "helmet" },
        }
        local _equipLevelByRes = {}
        local function registerEquipLevelSet(catalog, lv1, lv2, lv3, slot)
            catalog = tonumber(catalog)
            if not catalog then return end
            local set = {
                catalog = catalog,
                lv1 = tonumber(lv1) or 0,
                lv2 = tonumber(lv2) or 0,
                lv3 = tonumber(lv3) or 0,
                slot = slot or "helmet",
            }
            EQUIP_LEVEL_SETS[catalog] = set
            for _, rid in ipairs({ catalog, set.lv1, set.lv2, set.lv3 }) do
                if rid and rid > 0 then _equipLevelByRes[rid] = set end
            end
        end
        for catalog, set in pairs(EQUIP_LEVEL_SETS) do
            registerEquipLevelSet(catalog, set.lv1, set.lv2, set.lv3, set.slot)
        end
        _G.AddOutfitRegisterEquipLevelSet = registerEquipLevelSet

        -- نطاقات معدات بـ 3 لفلات (نفس البنية: 15XX00Y### حيث Y = اللفة)
        local EQUIP_LEVEL_RANGES = {
            { base = 1502000000, slot = "helmet" }, -- خوذة
            { base = 1501000000, slot = "bag"    }, -- شنطة
        }

        local function findEquipLevelRange(resID)
            resID = tonumber(resID)
            if not resID then return nil end
            for _, r in ipairs(EQUIP_LEVEL_RANGES) do
                if resID >= r.base and resID < r.base + 1000000 then return r end
            end
            return nil
        end

        local function detectLevelFromPattern(resID)
            resID = tonumber(resID)
            if not resID then return nil, nil end
            local r = findEquipLevelRange(resID)
            if not r then return nil, nil end
            if resID < r.base + 1000 or resID >= r.base + 4000 then return nil, nil end
            local tail = resID - r.base
            local levelDigit = math.floor(tail / 1000)
            if levelDigit >= 1 and levelDigit <= 3 then
                return levelDigit, r.base + (tail - levelDigit * 1000)
            end
            return nil, nil
        end

        local function buildPatternLevelSet(catalog)
            catalog = tonumber(catalog)
            if not catalog then return nil end
            local r = findEquipLevelRange(catalog)
            if not r then return nil end
            local tail = catalog - r.base
            if tail < 0 or tail >= 1000 then return nil end
            return {
                catalog = catalog,
                lv1 = catalog + 1000,
                lv2 = catalog + 2000,
                lv3 = catalog + 3000,
                slot = r.slot,
            }
        end

        local function getEquipLevelSet(resID)
            resID = tonumber(resID)
            if not resID then return nil end
            local set = _equipLevelByRes[resID]
            if set then return set end
            local level, catalog = detectLevelFromPattern(resID)
            if catalog then
                if EQUIP_LEVEL_SETS[catalog] then return EQUIP_LEVEL_SETS[catalog] end
                if level then return buildPatternLevelSet(catalog) end
            end
            -- resID نفسه ممكن يكون الـ catalog (بدون رقم لفل) — جرّب نبني set مباشرة
            local direct = buildPatternLevelSet(resID)
            if direct then
                _equipLevelByRes[resID] = direct
                if direct.lv1 > 0 then _equipLevelByRes[direct.lv1] = direct end
                if direct.lv2 > 0 then _equipLevelByRes[direct.lv2] = direct end
                if direct.lv3 > 0 then _equipLevelByRes[direct.lv3] = direct end
            end
            return direct
        end

        local function normalizeEquipCatalogRes(resID)
            resID = tonumber(resID)
            if not resID or resID <= 0 then return 0 end
            local set = getEquipLevelSet(resID)
            if set then return set.catalog end
            return resID
        end

        local function detectLevelFromEquipRes(resID)
            resID = tonumber(resID)
            if not resID then return nil end
            local set = getEquipLevelSet(resID)
            if set then
                if resID == set.lv1 then return 1
                elseif resID == set.lv2 then return 2
                elseif resID == set.lv3 then return 3 end
            end
            local level = detectLevelFromPattern(resID)
            return level
        end

        local function mapEquipLevelSet(set, level)
            if not set then return 0 end
            level = tonumber(level) or 3
            if level == 1 then return set.lv1 or 0
            elseif level == 2 then return set.lv2 or 0 end
            return set.lv3 or 0
        end

        local function mapEquipSkinRes(resID, level)
            resID, level = tonumber(resID), tonumber(level) or 3
            if not resID or resID <= 0 then return 0 end
            local catalogRes = normalizeEquipCatalogRes(resID)
            local set = getEquipLevelSet(catalogRes)
            if set then
                local mapped = mapEquipLevelSet(set, level)
                if mapped > 0 then return mapped end
            end
            local mapped = 0
            pcall(function()
                local itemMappingCfg = CDataTable.GetTableData("BackpackMapping", catalogRes)
                if itemMappingCfg then
                    if level == 1 then mapped = tonumber(itemMappingCfg.SkinItemIDLv1) or 0
                    elseif level == 2 then mapped = tonumber(itemMappingCfg.SkinItemIDLv2) or 0
                    else mapped = tonumber(itemMappingCfg.SkinItemIDLv3) or 0 end
                end
                if mapped <= 0 and DataMgr and DataMgr.GetEquipmentItemIDByResID then
                    mapped = tonumber(DataMgr.GetEquipmentItemIDByResID(level, catalogRes)) or 0
                end
            end)
            if mapped > 0 then return mapped end
            if isInjectedRes(catalogRes) then return catalogRes end
            return 0
        end

        local function buildEquipSkinLists(resID)
            resID = normalizeEquipCatalogRes(resID)
            return {
                mapEquipSkinRes(resID, 1),
                mapEquipSkinRes(resID, 2),
                mapEquipSkinRes(resID, 3),
            }
        end

        local function ensureMatchEquipCache()
            local cch = cache()
            local eq = MATCH_CONFIG.equip or {}
            if (not cch.equip.bag or cch.equip.bag <= 0) and eq.bag and eq.bag > 0 then
                cch.equip.bag = eq.bag
            end
            if (not cch.equip.helmet or cch.equip.helmet <= 0) and eq.helmet and eq.helmet > 0 then
                cch.equip.helmet = eq.helmet
            end
            if (not cch.equip.armor or cch.equip.armor <= 0) and eq.armor and eq.armor > 0 then
                cch.equip.armor = eq.armor
            end
            if (not cch.equip.parachute or cch.equip.parachute <= 0) and eq.parachute and eq.parachute > 0 then
                cch.equip.parachute = eq.parachute
            end
            if (not cch.equip.glider or cch.equip.glider <= 0) and eq.glider and eq.glider > 0 then
                cch.equip.glider = eq.glider
            end
        end

        local function syncMatchConfigFromCache()
            local cch = cache()
            if cch.outfitRes and cch.outfitRes > 0 then
                MATCH_CONFIG.outfitRes = cch.outfitRes
            else
                MATCH_CONFIG.outfitRes = 0
            end
            MATCH_CONFIG.weaponSkins = MATCH_CONFIG.weaponSkins or {}
            for wid, w in pairs(cch.weapons or {}) do
                if w.resID and w.resID > 0 then
                    MATCH_CONFIG.weaponSkins[wid] = w.resID
                end
            end
            MATCH_CONFIG.equip = MATCH_CONFIG.equip or {}
            for _, slot in ipairs({ "bag", "helmet", "armor", "parachute", "glider" }) do
                if cch.equip[slot] and cch.equip[slot] > 0 then
                    MATCH_CONFIG.equip[slot] = cch.equip[slot]
                end
            end
        end

        local function restorePersistedVehicles()
            if not _G._addOutfitPersistLoaded then return end
            pcall(function()
                if _G._savedVehicleSlotList and DataMgr then
                    DataMgr.VehicleSlotList = DataMgr.VehicleSlotList or {}
                    for subType, insList in pairs(_G._savedVehicleSlotList) do
                        if insList and #insList > 0 then
                            DataMgr.VehicleSlotList[subType] = insList
                        end
                    end
                end
            end)
            pcall(function()
                if _G._savedGarageVehicles then
                    local GTS = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.GarageThemeSystem)
                    if GTS then
                        GTS.GarageVehicleInfo = GTS.GarageVehicleInfo or {}
                        for slot, info in pairs(_G._savedGarageVehicles) do
                            if info and info.inst_id then
                                GTS.GarageVehicleInfo[slot] = info
                            end
                        end
                    end
                end
            end)
        end

        local function restorePersistedMotions()
            if not _G._addOutfitPersistLoaded then return end
            pcall(function()
                if not _G._savedMotionList or #_G._savedMotionList == 0 then return end
                if not DataMgr then return end
                DataMgr.MotionSlotList = {}
                for i, ins in ipairs(_G._savedMotionList) do
                    DataMgr.MotionSlotList[i] = ins
                end
                if EventSystem and EVENTTYPE_MOTION and EVENTID_MOTION_UPDATE_SLOT_LIST then
                    EventSystem:postEvent(EVENTTYPE_MOTION, EVENTID_MOTION_UPDATE_SLOT_LIST)
                end
            end)
        end

        local function restorePersistedEquipIns()
            if not _G._addOutfitPersistLoaded then return end
            pcall(function()
                if not DataMgr then return end
                if _G._savedEquipIns then
                    DataMgr.equipmentSkinInsIDTable = DataMgr.equipmentSkinInsIDTable or {}
                    for subType, ins in pairs(_G._savedEquipIns) do
                        if ins and ins > 0 then
                            DataMgr.equipmentSkinInsIDTable[subType] = ins
                        end
                    end
                end
                if _G._savedVstSkin and _G._savedVstSkin > 0 then
                    DataMgr.vst_skin = _G._savedVstSkin
                end
            end)
        end

        local function restorePersistedThrowObjects()
            if not _G._addOutfitPersistLoaded then return end
            pcall(function()
                if not _G._savedThrowObjects then return end
                local cch = cache()
                cch.throwObjects = cch.throwObjects or {}
                for st, info in pairs(_G._savedThrowObjects) do
                    if info.resID and info.resID > 0 then
                        cch.throwObjects[st] = info
                    end
                end
            end)
        end

        local GAME_HELMET_LEVEL = {
            [502001] = 1, [502004] = 1,
            [502002] = 2, [502005] = 2,
            [502003] = 3,
        }
        local GAME_BAG_LEVEL = {
            [501001] = 1, [501004] = 1,
            [501002] = 2, [501005] = 2,
            [501003] = 3,
        }

        local function detectEquipLevelFromBaseId(baseId, catalogResID)
            baseId, catalogResID = tonumber(baseId), tonumber(catalogResID)
            if not baseId or baseId <= 0 then return nil end
            local level
            pcall(function()
                catalogResID = catalogResID and normalizeEquipCatalogRes(catalogResID) or catalogResID
                if catalogResID then
                    local set = getEquipLevelSet(catalogResID)
                    if set then
                        if baseId == set.lv1 then level = 1
                        elseif baseId == set.lv2 then level = 2
                        elseif baseId == set.lv3 then level = 3 end
                    end
                    if not level then
                        local m = CDataTable.GetTableData("BackpackMapping", catalogResID)
                        if m then
                            if tonumber(m.SkinItemIDLv1) == baseId then level = 1
                            elseif tonumber(m.SkinItemIDLv2) == baseId then level = 2
                            elseif tonumber(m.SkinItemIDLv3) == baseId then level = 3 end
                        end
                    end
                end
                if not level then
                    local patLevel, patCatalog = detectLevelFromPattern(baseId)
                    if patLevel and (not catalogResID or patCatalog == catalogResID) then
                        level = patLevel
                    end
                end
                if not level then level = GAME_HELMET_LEVEL[baseId] or GAME_BAG_LEVEL[baseId] end
                if not level and baseId >= 1505000001 and baseId <= 1505000003 then
                    level = baseId - 1505000000
                end
                if not level then
                    pcall(function()
                        local BU = require("GameLua.Mod.BaseMod.GamePlay.Backpack.BackpackUtils")
                        if BU.GetEquipmentHelmetLevel then
                            local hl = BU.GetEquipmentHelmetLevel(baseId)
                            if hl and hl >= 1 and hl <= 3 then level = hl end
                        end
                        if not level and BU.GetEquipmentBagLevel then
                            local bl = BU.GetEquipmentBagLevel(baseId)
                            if bl and bl >= 1 and bl <= 3 then level = bl end
                        end
                    end)
                end
            end)
            return level
        end

        local function isBaseEquipItemId(itemId)
            itemId = tonumber(itemId)
            if not itemId or itemId <= 0 then return false end
            if GAME_HELMET_LEVEL[itemId] or GAME_BAG_LEVEL[itemId] then return true end
            if itemId >= 1505000001 and itemId <= 1505000100 then return true end
            if itemId >= 1501000000 and itemId < 1502000000 then return true end
            if itemId >= 502001 and itemId <= 502999 then return true end
            if itemId >= 501001 and itemId <= 501999 then return true end
            return false
        end

        local function resolveMatchEquipSkin(catalogResID, baseItemID)
            catalogResID = normalizeEquipCatalogRes(catalogResID)
            if not catalogResID or catalogResID <= 0 then return 0 end
            local level = detectEquipLevelFromBaseId(baseItemID, catalogResID) or 3
            return mapEquipSkinRes(catalogResID, level)
        end

        local function getEquipDisplayLevel(resID, slot)
            local wornLevel = detectLevelFromEquipRes(resID)
            if wornLevel then return wornLevel end
            pcall(function()
                local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                if slot == "bag" then wornLevel = fbd:GetBagLevel() or 3
                elseif slot == "helmet" then wornLevel = fbd:GetHelmetLevel() or 3 end
            end)
            return wornLevel or 3
        end

        local function syncEquipLevelFromRes(resID, slot)
            local level = detectLevelFromEquipRes(resID)
            if not level then return end
            pcall(function()
                local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                if slot == "helmet" then
                    fbd:SetHelmetLevel(level)
                elseif slot == "bag" then
                    fbd:SetBagLevel(level)
                end
            end)
        end

        local function saveEquipSkin(resID, insID)
            resID, insID = tonumber(resID), tonumber(insID)
            if not resID then return end
            local slot = getEquipSkinSlot(resID)
            if not slot then return end
            local cch = cache()
            cch.equip[slot] = resID
            if insID then cch.equip[slot .. "Ins"] = insID end
            MATCH_CONFIG.equip = MATCH_CONFIG.equip or {}
            MATCH_CONFIG.equip[slot] = resID
            _S.matchApplied = false
            invalidateSocialWearCache()
            log("ذاكرة معدات", slot, resID)
            pcall(_AutoSaveOutfit)
        end

        local function saveClothPiece(resID)
            resID = tonumber(resID)
            if not resID then return end
            local cch = cache()
            cch.clothes[resID] = true
            _S.matchApplied = false
            invalidateSocialWearCache()
            pcall(_AutoSaveOutfit)
        end

        local function clearClothesForKind(kind)
            local clearMap = subTypesToClearForKind(kind)
            if not clearMap then return end
            local cch = cache()
            for resID in pairs(cch.clothes) do
                local st = subType(cfg(resID))
                if st and clearMap[st] then cch.clothes[resID] = nil end
            end
            if kind == "full_suit" then
                cch.outfitRes, cch.outfitIns = nil, nil
            end
        end

        local function saveWeaponToCache(weaponID, resID, insID)
            weaponID, resID, insID = tonumber(weaponID), tonumber(resID), tonumber(insID)
            if not weaponID or not resID or resID <= 0 then return end
            local cch = cache()
            cch.weapons[weaponID] = { resID = resID, insID = insID or 0 }
            _G.AddOutfitLastAppliedSkin = {}
            _S.matchApplied = false
            invalidateSocialWearCache()
            log("ذاكرة سكن", weaponID, "→", resID)
            pcall(_AutoSaveOutfit)
        end

        local function cacheWeaponSkinFromIns(weaponID, insID)
            weaponID, insID = tonumber(weaponID), tonumber(insID)
            if not weaponID or not insID or insID <= 0 then return end
            if isInjectedIns(insID) then
                saveWeaponToCache(weaponID, R.insToRes[insID], insID)
                return
            end
            pcall(function()
                local wd = require("client.slua.logic.wardrobe.wardrobe_data")
                local d = wd:GetValidHallDepotItemDataByInsID(insID) or wd:GetHallDepotItemDataByInsID(insID)
                if d and d.resID and tonumber(d.resID) > 0 then
                    saveWeaponToCache(weaponID, tonumber(d.resID), insID)
                end
            end)
        end

        local function saveEquip(resID, insID)
            resID, insID = tonumber(resID), tonumber(insID)
            if not resID or not insID then return end
            local c = cfg(resID)
            local st = subType(c)
            local kind = getClothKind(resID)
            local cch = cache()
            if kind == "full_suit" then
                clearClothesForKind("full_suit")
                cch.outfitRes, cch.outfitIns = resID, insID
                _G.AddOutfitLastLobbyOutfitRes = resID
                invalidateSocialWearCache()
            elseif kind then
                if cch.outfitRes and isFullSuitRes(cch.outfitRes) then
                    cch.outfitRes, cch.outfitIns = nil, nil
                    _G.AddOutfitLastLobbyOutfitRes = nil
                end
                clearClothesForKind(kind)
                saveClothPiece(resID)
            elseif getEquipSkinSlot(resID) then
                saveEquipSkin(resID, insID)
            elseif _K.GUN_SUB[st] then
                local wid = weaponIdFromSkin(resID)
                if not wid then
                    pcall(function()
                        local wgl = require("client.slua.logic.wardrobe.logic_wardrobe_gun")
                        wid = wgl.GetCurGunID and wgl:GetCurGunID() or nil
                        if not wid and wgl.GetCurrentGunID then
                            wid = wgl:GetCurrentGunID()
                        end
                    end)
                end
                if wid then saveWeaponToCache(wid, resID, insID) end
            elseif st == _K.MELEE_ID then
                saveWeaponToCache(_K.MELEE_ID, resID, insID)
            elseif isThrowObjectRes(resID) then
                saveThrowObject(resID, insID)
            elseif isInjectedRes(resID) then
                local mt = wardrobeMainTab(resID)
                if mt ~= _K.WARDROBE_PAGE_VEHICLE then
                    saveClothPiece(resID)
                end
            end
            _S.matchApplied = false
            pcall(_AutoSaveOutfit)
        end

        local _lastSyncWeaponCache = 0
        local function syncWeaponCacheFromLobby()
            local now = 0
            pcall(function() now = os.clock() end)
            if (now - _lastSyncWeaponCache) < 0.3 then return end  -- throttle: max ~3x per second
            _lastSyncWeaponCache = now
            local cch = cache()
            pcall(function()
                local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                local bag = fbd.GetCurrentFashionBag and fbd:GetCurrentFashionBag()
                if bag then
                    if bag.bag_skin and tonumber(bag.bag_skin) > 0 then
                        local rid = isInjectedIns(bag.bag_skin) and R.insToRes[bag.bag_skin]
                            or (function()
                                local wd = require("client.slua.logic.wardrobe.wardrobe_data")
                                local d = wd:GetHallDepotItemDataByInsID(bag.bag_skin)
                                return d and tonumber(d.resID)
                            end)()
                        if rid and isInjectedRes(rid) then cch.equip.bag = rid end
                    end
                    if bag.helmet_skin and tonumber(bag.helmet_skin) > 0 then
                        local rid = isInjectedIns(bag.helmet_skin) and R.insToRes[bag.helmet_skin]
                            or (function()
                                local wd = require("client.slua.logic.wardrobe.wardrobe_data")
                                local d = wd:GetHallDepotItemDataByInsID(bag.helmet_skin)
                                return d and tonumber(d.resID)
                            end)()
                        if rid and isInjectedRes(rid) then cch.equip.helmet = rid end
                    end
                    if bag.weapon_skin_list then
                        for weaponID, entry in pairs(bag.weapon_skin_list) do
                            cacheWeaponSkinFromIns(weaponID, entry and (entry.skin_id or entry.skinId))
                        end
                    end
                end
            end)
            pcall(function()
                local Arm = require("client.logic.armory.logic_armory")
                if Arm.rsp_list and Arm.rsp_list.install_list then
                    for weaponID, entry in pairs(Arm.rsp_list.install_list) do
                        cacheWeaponSkinFromIns(weaponID, entry and entry.skin_id)
                    end
                end
            end)
            pcall(function()
                if DataMgr and DataMgr.equipmentSkinInsIDTable then
                    local function ridFromIns(ins)
                        ins = tonumber(ins)
                        if not ins or ins <= 0 then return nil end
                        if isInjectedIns(ins) then return R.insToRes[ins] end
                        local wd = require("client.slua.logic.wardrobe.wardrobe_data")
                        local d = wd:GetHallDepotItemDataByInsID(ins)
                        return d and tonumber(d.resID)
                    end
                    local bagRid = ridFromIns(DataMgr.equipmentSkinInsIDTable[504])
                    if bagRid and isInjectedRes(bagRid) then cch.equip.bag = bagRid end
                    local helmRid = ridFromIns(DataMgr.equipmentSkinInsIDTable[505])
                    if helmRid and isInjectedRes(helmRid) then cch.equip.helmet = helmRid end
                    local armorRid = ridFromIns(DataMgr.equipmentSkinInsIDTable[506])
                    if armorRid and isInjectedRes(armorRid) then cch.equip.armor = armorRid end
                end
            end)
        end

        local _lastSyncClothesCache = 0
        local function syncClothesCacheFromLobby()
            local now = 0
            pcall(function() now = os.clock() end)
            if (now - _lastSyncClothesCache) < 0.3 then return end  -- throttle: max ~3x per second
            _lastSyncClothesCache = now
            local cch = cache()
            pcall(function()
                local inLobby = false
                if GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity() then
                    inLobby = true
                end
                
                if inLobby and not _G._addOutfitPersistLoaded then
                    cch.outfitRes = nil
                    cch.outfitIns = nil
                    _G.AddOutfitLastLobbyOutfitRes = nil
                    cch.clothes = {}
                end

                local AvatarData = require("client.logic.data.AvatarData")
                local wd = require("client.slua.logic.wardrobe.wardrobe_data")
                for _, ins in pairs(AvatarData.GetRoleWear()) do
                    ins = tonumber(ins)
                    if ins and ins > 0 then
                        local resID = isInjectedIns(ins) and R.insToRes[ins]
                            or (function()
                                local d = wd:GetHallDepotItemDataByInsID(ins)
                                return d and tonumber(d.resID)
                            end)()
                        if resID and isInjectedRes(resID) then
                            if isFullSuitRes(resID) then
                                cch.outfitRes, cch.outfitIns = resID, ins
                                _G.AddOutfitLastLobbyOutfitRes = resID
                            elseif not getEquipSkinSlot(resID) and not weaponIdFromSkin(resID) then
                                -- يشمل الملابس + الإكسسوارات (ماسك/نظارة/طاقية) كي تُنقل للجيم
                                cch.clothes[resID] = true
                            elseif getEquipSkinSlot(resID) then
                                local slot = getEquipSkinSlot(resID)
                                cch.equip[slot] = resID
                                cch.equip[slot .. "Ins"] = ins
                            end
                        end
                    end
                end

                -- مزامنة سكن البراشوت من FashionBag
                pcall(function()
                    local fashionbag_data = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                    local paraInsID = tonumber(fashionbag_data:GetParachute())
                    if paraInsID and paraInsID > 0 then
                        local paraResID
                        if isInjectedIns(paraInsID) then
                            paraResID = R.insToRes[paraInsID]
                        else
                            local d = wd:GetHallDepotItemDataByInsID(paraInsID)
                            paraResID = d and tonumber(d.resID)
                        end
                        if paraResID and paraResID > 0 then
                            cch.equip.parachute = paraResID
                            cch.equip.parachuteIns = paraInsID
                            MATCH_CONFIG.equip = MATCH_CONFIG.equip or {}
                            MATCH_CONFIG.equip.parachute = paraResID
                        end
                    end
                end)

                -- مزامنة سكن الجلايدر من FashionBag
                pcall(function()
                    local fashionbag_data = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                    local gliderInsID = tonumber(fashionbag_data:GetAircraftOrGliding())
                    if gliderInsID and gliderInsID > 0 then
                        local gliderResID
                        if isInjectedIns(gliderInsID) then
                            gliderResID = R.insToRes[gliderInsID]
                        else
                            local d = wd:GetHallDepotItemDataByInsID(gliderInsID)
                            gliderResID = d and tonumber(d.resID)
                        end
                        if gliderResID and gliderResID > 0 then
                            cch.equip.glider = gliderResID
                            cch.equip.gliderIns = gliderInsID
                            MATCH_CONFIG.equip = MATCH_CONFIG.equip or {}
                            MATCH_CONFIG.equip.glider = gliderResID
                        end
                    end
                end)
            end)
        end

        local function syncClothesCacheFromLive()
            local cch = cache()
            pcall(function()
                local AvatarData = require("client.logic.data.AvatarData")
                local wd = require("client.slua.logic.wardrobe.wardrobe_data")
                for _, ins in pairs(AvatarData.GetRoleWear()) do
                    ins = tonumber(ins)
                    if ins and ins > 0 then
                        local resID = isInjectedIns(ins) and R.insToRes[ins]
                            or (function()
                                local d = wd:GetHallDepotItemDataByInsID(ins)
                                return d and tonumber(d.resID)
                            end)()
                        if resID and isInjectedRes(resID) then
                            if isFullSuitRes(resID) then
                                cch.outfitRes, cch.outfitIns = resID, ins
                                _G.AddOutfitLastLobbyOutfitRes = resID
                            elseif not getEquipSkinSlot(resID) and not weaponIdFromSkin(resID) then
                                cch.clothes[resID] = true
                            else
                                local slot = getEquipSkinSlot(resID)
                                if slot then
                                    cch.equip[slot] = resID
                                    cch.equip[slot .. "Ins"] = ins
                                end
                            end
                        end
                    end
                end
                pcall(function()
                    local fashionbag_data = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                    local paraInsID = tonumber(fashionbag_data:GetParachute())
                    if paraInsID and paraInsID > 0 then
                        local paraResID = isInjectedIns(paraInsID) and R.insToRes[paraInsID]
                            or (function()
                                local d = wd:GetHallDepotItemDataByInsID(paraInsID)
                                return d and tonumber(d.resID)
                            end)()
                        if paraResID and paraResID > 0 then
                            cch.equip.parachute = paraResID
                            cch.equip.parachuteIns = paraInsID
                        end
                    end
                    local gliderInsID = tonumber(fashionbag_data:GetAircraftOrGliding())
                    if gliderInsID and gliderInsID > 0 then
                        local gliderResID = isInjectedIns(gliderInsID) and R.insToRes[gliderInsID]
                            or (function()
                                local d = wd:GetHallDepotItemDataByInsID(gliderInsID)
                                return d and tonumber(d.resID)
                            end)()
                        if gliderResID and gliderResID > 0 then
                            cch.equip.glider = gliderResID
                            cch.equip.gliderIns = gliderInsID
                        end
                    end
                end)
            end)
        end

        local function syncThrowObjectCacheFromLobby()
            local cch = cache()
            pcall(function()
                local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                local bag = fbd.GetCurrentFashionBag and fbd:GetCurrentFashionBag()
                if not bag or not bag.throw_object_list then return end
                cch.throwObjects = cch.throwObjects or {}
                for subType, insID in pairs(bag.throw_object_list) do
                    insID = tonumber(insID)
                    subType = tonumber(subType)
                    if insID and insID > 0 and subType and _K.THROW_SUB[subType] then
                        local resID
                        if isInjectedIns(insID) then
                            resID = R.insToRes[insID]
                        else
                            local wd = require("client.slua.logic.wardrobe.wardrobe_data")
                            local d = wd:GetHallDepotItemDataByInsID(insID)
                            resID = d and tonumber(d.resID)
                        end
                        if resID and isInjectedRes(resID) then
                            cch.throwObjects[subType] = { resID = resID, insID = insID }
                        end
                    end
                end
            end)
        end

        local function syncAllCacheFromLive()
            syncWeaponCacheFromLobby()
            syncClothesCacheFromLive()
            syncThrowObjectCacheFromLobby()
            ensureMatchEquipCache()
            syncMatchConfigFromCache()
        end
        _G.AddOutfitSyncCacheBeforeSave = syncAllCacheFromLive

        local function snapshotLobbyWear()
            syncWeaponCacheFromLobby()
            syncClothesCacheFromLobby()
            syncThrowObjectCacheFromLobby()
            ensureMatchEquipCache()
        end

        local function getCachedWeaponSkin(weaponID)
            weaponID = tonumber(weaponID) or 0
            if weaponID <= 0 then return nil end
            syncWeaponCacheFromLobby()
            local w = cache().weapons[weaponID]
            if w and w.resID and w.resID > 0 then return w.resID end
            return nil
        end

        local function getMatchWeaponSkin(weaponID)
            weaponID = tonumber(weaponID) or 0
            local fromCache = getCachedWeaponSkin(weaponID)
            if fromCache then return fromCache end
            if MATCH_CONFIG.weaponSkins then
                local fixed = tonumber(MATCH_CONFIG.weaponSkins[weaponID])
                if fixed and fixed > 0 then return fixed end
            end
            return nil
        end

        local _ticker
        pcall(function() _ticker = require("common.time_ticker") end)
        local function later(sec, fn)
            if _G.SetTimer then pcall(_G.SetTimer, sec, fn) return end
            if _ticker and _ticker.AddTimer then pcall(_ticker.AddTimer, sec, fn) end
        end

        local function getEntity()
            local ok, dc = pcall(require, "client.slua.logic.wardrobe.logic_wardrobe_data_center")
            if not ok or not dc then return nil end
            local ok2, e = pcall(dc.GetWardrobeData, EWardrobeDataSource and EWardrobeDataSource.Wardrobe or nil)
            if ok2 and e then return e end
            ok2, e = pcall(dc.GetWardrobeData)
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

        local function ensureDepotTabFields(entity, data, resID)
            if not data then return end
            pcall(function()
                if entity and entity.LoadConfigForData and CDataTable.GetTableData then
                    entity:LoadConfigForData(data, CDataTable.GetTableData)
                end
            end)
            local equipSlot = getEquipSkinSlot(resID)
            if equipSlot == "bag" then
                data.mainTabType = _K.WARDROBE_PAGE_AVATAR
                data.subTabType = _K.WARDROBE_TAB_BAG
            elseif equipSlot == "helmet" then
                data.mainTabType = _K.WARDROBE_PAGE_AVATAR
                data.subTabType = _K.WARDROBE_TAB_HELMET
            elseif equipSlot == "armor" then
                data.mainTabType = _K.WARDROBE_PAGE_AVATAR
                data.subTabType = _K.WARDROBE_TAB_ARMOR
            end
            local c = cfg(resID)
            if c then data.itemSubType = tonumber(c.ItemSubType or c.itemSubType) or data.itemSubType end
            if c then
                local wmTab = tonumber(c.WardrobeMainTab or c.wardrobeMainTab) or 0
                if wmTab == _K.WARDROBE_PAGE_VEHICLE then
                    data.mainTabType = _K.WARDROBE_PAGE_VEHICLE
                    data.subTabType = tonumber(c.WardrobeTab or c.wardrobeTab) or data.subTabType
                end
            end
        end

        local function depotResID(v)
            return v and tonumber(v.resID or v.res_id) or nil
        end

        local function injectedEquipAllowed(resID, mainTab, subTab)
            local slot = getEquipSkinSlot(resID)
            if slot == "bag" then
                return mainTab == _K.WARDROBE_PAGE_AVATAR and subTab == _K.WARDROBE_TAB_BAG
            end
            if slot == "helmet" then
                return mainTab == _K.WARDROBE_PAGE_AVATAR and subTab == _K.WARDROBE_TAB_HELMET
            end
            if slot == "armor" then
                return mainTab == _K.WARDROBE_PAGE_AVATAR and subTab == _K.WARDROBE_TAB_ARMOR
            end
            if slot == "parachute" then
                return mainTab == _K.WARDROBE_PAGE_PARACHUTE and subTab == _K.WARDROBE_TAB_PARACHUTE
            end
            if slot == "glider" then
                return mainTab == _K.WARDROBE_PAGE_PARACHUTE and subTab == _K.WARDROBE_TAB_GLIDER
            end
            return nil
        end

        local function injectOne(entity, resID, insID)
            if alreadyHave(entity, resID) then
                R.resToIns[resID] = R.resToIns[resID] or insID
                R.insToRes[insID] = resID
                pcall(function()
                    local data = entity.GetDataByInsID and entity:GetDataByInsID(R.resToIns[resID])
                    if data then ensureDepotTabFields(entity, data, resID) end
                end)
                return true
            end
            entity:AddData({
                instid = insID, res_id = resID, count = 1,
                lock_cnt = 0, isnew = 0, valid_hours = 0, expire_ts = 0,
            })
            pcall(function()
                local data = entity.GetDataByInsID and entity:GetDataByInsID(insID)
                if data then
                    ensureDepotTabFields(entity, data, resID)
                end
            end)
            R.insToRes[insID] = resID
            R.resToIns[resID] = insID
            -- log("حقن", resID, insID)
            return true
        end

        local function injectArmory(resID, insID)
            local wid = weaponIdFromSkin(resID)
            if not wid then return end
            local Arm = require("client.logic.armory.logic_armory")
            Arm.rsp_list = Arm.rsp_list or { skin_list = {}, install_list = {} }
            Arm.rsp_list.skin_list = Arm.rsp_list.skin_list or {}
            if not Arm.rsp_list.skin_list[wid] then Arm.rsp_list.skin_list[wid] = {} end
            Arm.rsp_list.skin_list[wid][resID] = { is_open = 1 }
            Arm.WardrobeInsList = Arm.WardrobeInsList or {}
            Arm.WardrobeInsList[resID] = insID
        end

        -- تعديل: منع إعادة الحقن
        local function injectAll(entity)
            if _S.injectedDone then return true end
            refreshItems()
            entity = entity or getEntity()
            if not entity or not entity.bInit then return false end

            if next(_C.fullSuit) == nil then
                pcall(function()
                    for _, rid in ipairs(ITEMS) do
                        local c = cfg(rid)
                        if c then
                            local st = tonumber(c.ItemSubType or c.itemSubType) or 0
                            if st == _K.ST_TOP then
                                local tab = tonumber(c.WardrobeTab or c.wardrobeTab) or 0
                                if tab == _K.WARDROBE_TAB_SUIT then
                                    _C.fullSuit[rid] = true
                                else
                                    pcall(function()
                                        local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
                                        if LogicXSuit.IsXSuit(rid) then _C.fullSuit[rid] = true end
                                    end)
                                end
                            end
                            local wmTab = tonumber(c.WardrobeMainTab or c.wardrobeMainTab) or 0
                            if wmTab == _K.WARDROBE_PAGE_VEHICLE then
                                _C.vehicleItems[#_C.vehicleItems + 1] = rid
                            end
                        end
                        getEquipSkinSlot(rid)
                        weaponIdFromSkin(rid)
                    end
                    for _, rid in ipairs(ITEMS) do
                        getInjectedItemTab(rid)
                    end
                    local allTabs = {
                        {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_SUIT},
                        {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_CLOTHES},
                        {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_TROUSERS},
                        {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_SHOES},
                        {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_BAG},
                        {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_HELMET},
                        {_K.WARDROBE_PAGE_AVATAR, _K.WARDROBE_TAB_ARMOR},
                        {_K.WARDROBE_PAGE_WEAPON, _K.WARDROBE_TAB_GUN},
                        {_K.WARDROBE_PAGE_PARACHUTE, _K.WARDROBE_TAB_PARACHUTE},
                        {_K.WARDROBE_PAGE_PARACHUTE, _K.WARDROBE_TAB_GLIDER},
                        {_K.WARDROBE_PAGE_VEHICLE, 0},
                    }
                    -- pageMatch is now computed lazily in IsValidCurrentPageItem
                    for k in pairs(_C.pageMatch) do _C.pageMatch[k] = nil end
                end)
            end

            local n = 0
            for i, resID in ipairs(ITEMS) do
                local insID = _K.INS_BASE + i
                if injectOne(entity, resID, insID) then
                    n = n + 1
                    local c = cfg(resID)
                    if _K.GUN_SUB[subType(c)] or subType(c) == _K.MELEE_ID then
                        injectArmory(resID, insID)
                    end
                end
            end
            if n > 0 then
                _S.injectedDone = true
                _G.AddOutfit_R = R
                log("حقن", n, "items")
            end
            return n > 0
        end

        local function injectAllSources()
            return injectAll(getEntity())
        end
        -- ★ Expose ITEMS for external modules (crate/shop bypass)
pcall(function()
    refreshItems()
    _G.AddOutfitAllItems = ITEMS
end)

        local function refreshWardrobe()
            pcall(function()
                if EventSystem and EVENTTYPE_WARDROBE then
                    if EVENTID_WARDROBE_UPDATE_ITEM_LIST then
                        EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_ITEM_LIST)
                    end
                    if EVENTID_WARDROBE_UPDATE_AVATAR_LIST then
                        EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_AVATAR_LIST)
                    end
                    if EVENTID_WARDROBE_UPDATE_GUN_LIST then
                        EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_GUN_LIST, -1)
                    end
                end
            end)
        end

        local function findWornInsBySubType(st)
            st = tonumber(st)
            if not st then return nil end
            local wd = require("client.slua.logic.wardrobe.wardrobe_data")
            local AvatarData = require("client.logic.data.AvatarData")
            for _, ins in pairs(AvatarData.GetRoleWear()) do
                ins = tonumber(ins)
                if ins and ins > 0 then
                    local d = wd:GetHallDepotItemDataByInsID(ins)
                    if d and tonumber(d.itemSubType) == st then
                        return ins, d.resID
                    end
                end
            end
            return nil
        end

        local function removeRoleWearBySubTypes(stMap)
            if not stMap then return end
            local wd = require("client.slua.logic.wardrobe.wardrobe_data")
            local AvatarData = require("client.logic.data.AvatarData")
            for _, ins in pairs(AvatarData.GetRoleWear()) do
                ins = tonumber(ins)
                if ins and ins > 0 then
                    local d = wd:GetHallDepotItemDataByInsID(ins)
                    if d and stMap[tonumber(d.itemSubType)] then
                        AvatarData.RemoveRoleWearDataByValue(ins)
                    end
                end
            end
        end

        local function clearFashionBagSlots(stMap)
            if not stMap then return end
            pcall(function()
                local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                local wfu = require("client.slua.logic.wardrobe.fashionbag.wardrobe_fashion_utils")
                local bag = fbd.GetCurrentFashionBag and fbd:GetCurrentFashionBag()
                if not bag or not bag.rolewear_list then return end
                for st, _ in pairs(stMap) do
                    local idx = wfu.GetRoleWearIndexBySubType and wfu:GetRoleWearIndexBySubType(st)
                    if idx then bag.rolewear_list[idx] = 0 end
                end
            end)
        end

        local function syncFashionBagRolewear()
            pcall(function()
                local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                fbd:SaveRolewearToFashionBag(fbd:GetFashionBagUseIndex())
            end)
        end

        local function ensureKnapsackExtInfo()
            pcall(function()
                local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                local idx = fbd:GetFashionBagUseIndex()
                if not fbd:GetKnapsackExtInfoByIndex(idx) then
                    fbd:SetKnapsackExtInfoByIndex(idx, {})
                end
            end)
        end

        local function getEquipSubType(resID, slot)
            local c = cfg(resID)
            if c then
                local st = tonumber(c.ItemSubType or c.itemSubType)
                if st then return st end
            end
            if slot == "bag" then return ENUM_ITEM_SUBTYPE.Backpack end
            if slot == "helmet" then return ENUM_ITEM_SUBTYPE.Helmet_NoLevel end
            return nil
        end

        local function softRemoveEquipVisual(oldResID, slot)
            oldResID = normalizeEquipCatalogRes(oldResID)
            if not oldResID or oldResID <= 0 or not slot then return end
            pcall(function()
                local TAM = require("client.logic.avatar.logic_team_avatar_manager")
                local AvatarData = require("client.logic.data.AvatarData")
                for lvl = 1, 3 do
                    local displayRes = mapEquipSkinRes(oldResID, lvl)
                    if displayRes > 0 then
                        TAM.ChangeAvatarEquipment(tostring(DataMgr.roleData.uid),
                            AvatarData.CreateAvatarCustom(displayRes), false)
                    end
                end
            end)
        end

        local function applyEquipVisual(resID, insID, slot)
            pcall(function()
                local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                local HT = require("client.logic.lobby.hall_theme_utils")
                local TAM = require("client.logic.avatar.logic_team_avatar_manager")
                local AvatarData = require("client.logic.data.AvatarData")
                local lds = require("client.slua.logic.wardrobe.logic_display_setting")
                local lav = require("client.slua.logic.wardrobe.logic_wardrobe_avatar")
                syncEquipLevelFromRes(resID, slot)
                local level = getEquipDisplayLevel(resID, slot)
                local catalogRes = normalizeEquipCatalogRes(resID)
                local itemSt = getEquipSubType(catalogRes, slot)
                if itemSt then lav:AddToWearInfo(itemSt, insID, catalogRes, 0, 0) end
                lav:AvatarChange(catalogRes, true)
                local displayRes = mapEquipSkinRes(catalogRes, level)
                if displayRes > 0 then
                    TAM.ChangeAvatarEquipment(tostring(DataMgr.roleData.uid),
                        AvatarData.CreateAvatarCustom(displayRes), true)
                end
                if lds.data then
                    if slot == "bag" then lds.data.OpenBag = true end
                    if slot == "helmet" then lds.data.OpenHelmet = true end
                end
                if slot == "helmet" then
                    fbd:SetHeadShow(insID)
                    local WRH = require("client.network.Protocol.WardRobeHandler")
                    WRH.send_depot_set_head_show_req(insID)
                end
                if slot == "bag" then HT.PutOnBag(fbd:GetFashionBagUseIndex()) end
            end)
        end

        -- ========== دوال الخلع المُحسَّنة ==========
        local takeOffEquipSkinVisual, takeOffClothVisual, takeOffWeaponSkinVisual

        local function takeOffItem(insID)
            insID = tonumber(insID)
            if not insID or insID <= 0 then return false end
            local resID = R.insToRes[insID]
            if not resID then return false end

            local cch = cache()
            local kind = getClothKind(resID)
            local slot = getEquipSkinSlot(resID)
            local wid  = weaponIdFromSkin(resID)
            local handled = false

            if slot then
                local oldRes = cch.equip[slot] or resID
                takeOffEquipSkinVisual(slot, oldRes, insID)
                cch.equip[slot]          = nil
                cch.equip[slot .. "Ins"] = nil
                if MATCH_CONFIG.equip then MATCH_CONFIG.equip[slot] = 0 end
                handled = true
            elseif kind then
                takeOffClothVisual(resID, insID, kind)
                if kind == "full_suit" then
                    cch.outfitRes, cch.outfitIns = nil, nil
                    _G.AddOutfitLastLobbyOutfitRes = nil
                else
                    cch.clothes[resID] = nil
                end
                handled = true
            elseif wid then
                takeOffWeaponSkinVisual(wid, resID, insID)
                cch.weapons[wid] = nil
                _G.AddOutfitLastAppliedSkin = {}
                _S.weaponApplied = false
                _S.weaponDiagDone = false
                _S.lastAppliedWeaponID = 0
                _S.lastAppliedSkinID = 0
                buildSkinMappings()
                handled = true
            elseif isHallThemeRes(resID) then
                pcall(function()
                    local HT = require("client.logic.lobby.hall_theme_utils")
                    HT.homeThemeItemId = 0
                    HT.SetThemeInstId(0)
                    local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                    local idx = fbd:GetFashionBagUseIndex()
                    local bag = fbd:GetCurrentFashionBag()
                    if bag and bag.avatar_show then
                        bag.avatar_show[HT.knapsack_ext_background] = nil
                    end
                end)
                handled = true
            end

            if not handled then return false end

            _S.matchApplied = false
            _S.matchOutfitDone = false
            invalidateSocialWearCache()
            pcall(_AutoSaveOutfit)
            return true
        end

        takeOffEquipSkinVisual = function(slot, resID, insID)
            if not slot then return end
            resID, insID = tonumber(resID), tonumber(insID)
            if _S.equipSkinApplying then return end
            _S.equipSkinApplying = true
            pcall(function()
                if resID and resID > 0 then softRemoveEquipVisual(resID, slot) end
                local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                local lds = require("client.slua.logic.wardrobe.logic_display_setting")
                local lav = require("client.slua.logic.wardrobe.logic_wardrobe_avatar")
                local HT = require("client.logic.lobby.hall_theme_utils")
                local itemSt = resID and getEquipSubType(resID, slot)
                if itemSt and insID and insID > 0 then
                    pcall(function() lav:SetCurrentWearPreview(itemSt, nil) end)
                end
                if slot == "bag" then
                    fbd:SetBagSkin(0)
                    if lds.data then lds.data.OpenBag = false end
                    HT.PutOnBag(fbd:GetFashionBagUseIndex())
                elseif slot == "helmet" then
                    fbd:SetHelmetSkin(0)
                    if lds.data then lds.data.OpenHelmet = false end
                    fbd:SetHeadShow(0)
                elseif slot == "armor" then
                    pcall(function()
                        local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
                        wl:on_putdown_rsp(_K.NET_OK, { res_id = resID or 0, instid = insID or 0, count = 1 }, nil)
                    end)
                end
                if DataMgr and DataMgr.equipmentSkinInsIDTable then
                    local subKey = (slot == "bag") and 504 or (slot == "helmet") and 505 or (slot == "armor") and 506
                    if subKey then DataMgr.equipmentSkinInsIDTable[subKey] = 0 end
                end
                syncFashionBagRolewear()
            end)
            _S.equipSkinApplying = false
        end

        takeOffClothVisual = function(resID, insID, kind)
            resID, insID = tonumber(resID), tonumber(insID)
            if not resID or not insID then return end
            kind = kind or getClothKind(resID)
            local clearMap = subTypesToClearForKind(kind)
            if not clearMap then return end
            pcall(function()
                removeRoleWearBySubTypes(clearMap)
                clearFashionBagSlots(clearMap)
                local WRH = require("client.network.Protocol.WardRobeHandler")
                WRH.on_depot_put_down_rsp(_K.NET_OK, { res_id = resID, count = 1, instid = insID }, nil)
                local av = require("client.slua.logic.wardrobe.logic_wardrobe_avatar")
                local TAM = require("client.logic.avatar.logic_team_avatar_manager")
                local AvatarData = require("client.logic.data.AvatarData")
                local uid = tostring(DataMgr.roleData.uid)
                local itemSt = subType(cfg(resID)) or _K.ST_TOP
                if kind == "full_suit" then
                    itemSt = _K.ST_TOP
                    for st in pairs(clearMap) do
                        local oIns, oRes = findWornInsBySubType(st)
                        if oIns and oRes and oRes > 0 then
                            TAM.ChangeAvatarEquipment(uid, AvatarData.CreateAvatarCustom(oRes), false)
                        end
                    end
                end
                TAM.ChangeAvatarEquipment(uid, AvatarData.CreateAvatarCustom(resID), false)
                pcall(function() AvatarData.RemoveRoleWearDataByValue(insID) end)
                pcall(function() av:SetCurrentWearPreview(itemSt, nil) end)
                later(0.05, function()
                    pcall(function() av:ProcessTakeOff() end)
                    syncFashionBagRolewear()
                    pcall(function()
                        local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
                        wl:on_putdown_rsp(_K.NET_OK, { res_id = resID, instid = insID, count = 1 }, nil)
                    end)
                    if av.InitCurrentWearPreviewMap then av:InitCurrentWearPreviewMap(true) end
                end)
            end)
        end

        takeOffWeaponSkinVisual = function(weaponID, resID, insID)
            weaponID, resID, insID = tonumber(weaponID), tonumber(resID), tonumber(insID)
            if not weaponID then return end
            pcall(function()
                local Arm = require("client.logic.armory.logic_armory")
                local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                local HT = require("client.logic.lobby.hall_theme_utils")
                local wgl = require("client.slua.logic.wardrobe.logic_wardrobe_gun")
                -- مسح من install_list
                if Arm.rsp_list and Arm.rsp_list.install_list then
                    Arm.rsp_list.install_list[weaponID] = nil
                end
                -- مسح من FashionBag
                if fbd.UpdateCurrentFashionBagWeaponSkin then
                    fbd:UpdateCurrentFashionBagWeaponSkin(weaponID, 0)
                end
                local bag = fbd.GetCurrentFashionBag and fbd:GetCurrentFashionBag()
                if bag and bag.weapon_skin_list then
                    bag.weapon_skin_list[weaponID] = nil
                end
                -- تحديث واجهة السلاح
                local bagIdx = fbd:GetFashionBagUseIndex()
                HT.proc_skin_list_chg("weapon_skin", weaponID, 0, bagIdx, {})
                wgl:SetGunID(weaponID)
                if wgl.UpdateCurrentGunAvatar then
                    wgl:UpdateCurrentGunAvatar(weaponID, 0)
                end
                -- أحداث التحديث
                if EventSystem and EVENTTYPE_ARMORY and EVENTID_ARMORY_EQUIP_STAT_CHANGE then
                    EventSystem:postEvent(EVENTTYPE_ARMORY, EVENTID_ARMORY_EQUIP_STAT_CHANGE, 0)
                end
                if EventSystem and EVENTTYPE_WARDROBE and EVENTID_WARDROBE_UPDATE_CURRENT_PUT_ON_GUN then
                    EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_CURRENT_PUT_ON_GUN, 0)
                end
                if EventSystem and EVENTID_WARDROBE_UPDATE_GUN_LIST then
                    EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_GUN_LIST, weaponID)
                end
                log("خلع سكن سلاح", weaponID)
            end)
        end
        -- ========== نهاية دوال الخلع ==========

        local function putOnThrowObject(insID)
    insID = tonumber(insID)
    if not insID or not isInjectedIns(insID) then return end
    local resID = R.insToRes[insID]
    if not resID then return end
    local st = isThrowObjectRes(resID)
    if not st then return end
    pcall(function()
        local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
        fbd:PutOnThrowObjectSkin(insID)
    end)
    saveThrowObject(resID, insID)
    pcall(_AutoSaveOutfit)
    log("لبس قنبلة", st, resID)
    showWearBrandNotice()   -- <--- YEH LINE ADD KI HAI
end

        local function putOnEquipSkin(insID)
    insID = tonumber(insID)
    local resID = R.insToRes[insID]
    if not resID then return end
    local slot = getEquipSkinSlot(resID)
    if not slot then return end
    if _S.equipSkinApplying then return end
    _S.equipSkinApplying = true
    pcall(function()
        local cch = cache()
        local oldResID = cch.equip[slot]
        local oldInsID = cch.equip[slot .. "Ins"]
        ensureKnapsackExtInfo()
        local item = { res_id = resID, instid = insID, count = 1, color = 0, pattern = 0 }
        local oldItem = nil
        if oldInsID and oldInsID > 0 and oldResID and oldResID > 0 then
            oldItem = { res_id = oldResID, instid = oldInsID, count = 1, color = 0, pattern = 0 }
        end
        local HT = require("client.logic.lobby.hall_theme_utils")
        if slot == "helmet" then
            HT.ProcPutOnHelmet(item, oldItem)
        elseif slot == "bag" then
            HT.ProcPutOnBagSkin(item, oldItem)
        elseif slot == "parachute" then
            local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
            local lav = require("client.slua.logic.wardrobe.logic_wardrobe_avatar")
            local origAddToWearInfo = lav.AddToWearInfo
            lav.AddToWearInfo = function(self2, subType, ...)
                if tonumber(subType) == 701 then return end
                return origAddToWearInfo(self2, subType, ...)
            end
            pcall(function()
                wl:on_puton_rsp(_K.NET_OK, item, oldItem, 1, insID, 0)
            end)
            lav.AddToWearInfo = origAddToWearInfo
        elseif slot == "glider" then
            local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
            local lav = require("client.slua.logic.wardrobe.logic_wardrobe_avatar")
            local origAddToWearInfo = lav.AddToWearInfo
            lav.AddToWearInfo = function(self2, subType, ...)
                local st = tonumber(subType)
                if st == 413 or st == 414 or st == 415 then return end
                return origAddToWearInfo(self2, subType, ...)
            end
            pcall(function()
                wl:on_puton_rsp(_K.NET_OK, item, oldItem, 1, insID, 0)
            end)
            lav.AddToWearInfo = origAddToWearInfo
        else
            local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
            wl:on_puton_rsp(_K.NET_OK, item, oldItem, 1, insID, 0)
        end
        saveEquipSkin(resID, insID)
        if oldResID and oldResID > 0 and oldResID ~= resID then
            softRemoveEquipVisual(oldResID, slot)
        end
        if slot ~= "parachute" and slot ~= "glider" then
            applyEquipVisual(resID, insID, slot)
        end
        invalidateSocialWearCache()
        log("لبس معدات", slot, resID)
        showWearBrandNotice()   -- <--- YEH LINE ADD KI HAI
    end)
    _S.equipSkinApplying = false
end

        local function putOnCloth(insID)
    insID = tonumber(insID)
    local resID = R.insToRes[insID]
    if not resID then return end
    local wd = require("client.slua.logic.wardrobe.wardrobe_data")
    local d = wd:GetHallDepotItemDataByInsID(insID)
    if not d then return end

    local kind = getClothKind(resID, d)
    if not kind then return end

    local cch = cache()
    local switchingFromSuit = (kind ~= "full_suit") and cch.outfitRes and isFullSuitRes(cch.outfitRes)
    local switchingToSuit = (kind == "full_suit") and not cch.outfitRes and next(cch.clothes) ~= nil

    local clearMap
    if switchingFromSuit then
        clearMap = FULL_SUIT_CLEAR_ST
    else
        clearMap = subTypesToClearForKind(kind)
    end
    if not clearMap then return end

    local itemSt = subType(cfg(resID)) or _K.ST_TOP

    local function doPutOn()
        local oldIns, oldRes = findWornInsBySubType(itemSt)
        removeRoleWearBySubTypes(clearMap)
        clearFashionBagSlots(clearMap)
        saveEquip(resID, insID)

        local slot = _K.PKG_SLOT
        pcall(function()
            local wfu = require("client.slua.logic.wardrobe.fashionbag.wardrobe_fashion_utils")
            local idx = wfu.GetRoleWearIndexBySubType and wfu:GetRoleWearIndexBySubType(itemSt)
            if idx then slot = idx end
        end)

        local olditem
        if oldIns and oldIns ~= insID then
            olditem = { res_id = oldRes or R.insToRes[oldIns], count = 1, instid = oldIns }
        end

        local WRH = require("client.network.Protocol.WardRobeHandler")
        local item = { res_id = resID, count = 1, instid = insID }
        WRH.on_depot_put_on_rsp(_K.NET_OK, item, olditem, slot, insID, oldIns or 0)

        pcall(function()
            local av = require("client.slua.logic.wardrobe.logic_wardrobe_avatar")
            av:AddToWearInfo(itemSt, insID, resID, 0, 0)
            local displayResID = resID
            local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
            if LogicXSuit.IsXSuit(displayResID) then
                displayResID = LogicXSuit.GetItemShowID(insID) or displayResID
            end
            av:AvatarChange(displayResID, true, 0, 0)
            later(0.05, function()
                pcall(function() av:ProcessTakeOff() end)
                syncFashionBagRolewear()
            end)
        end)
        log("لبس", kind, resID)
        showWearBrandNotice()   -- <--- YEH LINE ADD KI HAI
    end

    if switchingFromSuit then
        local suitRes = cch.outfitRes
        local suitIns = cch.outfitIns
        cch.outfitRes, cch.outfitIns = nil, nil
        _G.AddOutfitLastLobbyOutfitRes = nil
        if suitRes and suitIns then
            pcall(function() takeOffClothVisual(suitRes, suitIns, "full_suit") end)
            later(0.15, doPutOn)
        else
            doPutOn()
        end
    elseif switchingToSuit then
        local toTakeOff = {}
        for clothRes in pairs(cch.clothes) do
            local clothIns = R.resToIns[clothRes]
            local clothKind = getClothKind(clothRes)
            if clothIns and clothKind then
                toTakeOff[#toTakeOff + 1] = { resID = clothRes, insID = clothIns, kind = clothKind }
            end
        end
        for _, c in ipairs(toTakeOff) do
            cch.clothes[c.resID] = nil
            pcall(function() takeOffClothVisual(c.resID, c.insID, c.kind) end)
        end
        later(0.15, doPutOn)
    else
        doPutOn()
    end
end

        local function equipWeaponSkin(weaponID, insID)
    weaponID, insID = tonumber(weaponID), tonumber(insID)
    if not weaponID or not insID or not isInjectedIns(insID) then return end
    local resID = R.insToRes[insID]
    saveEquip(resID, insID)

    local Arm = require("client.logic.armory.logic_armory")
    local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
    local HT = require("client.logic.lobby.hall_theme_utils")
    local wgl = require("client.slua.logic.wardrobe.logic_wardrobe_gun")

    injectArmory(resID, insID)
    Arm.rsp_list.install_list = Arm.rsp_list.install_list or {}
    Arm.rsp_list.install_list[weaponID] = { skin_id = insID }
    if fbd.UpdateCurrentFashionBagWeaponSkin then
        fbd:UpdateCurrentFashionBagWeaponSkin(weaponID, insID)
    end

    local bagIdx = fbd:GetFashionBagUseIndex()
    HT.proc_skin_list_chg("weapon_skin", weaponID, insID, bagIdx, {})

    wgl:SetGunID(weaponID)
    wgl:UpdateCurrentGunAvatar(weaponID, insID)

    if EventSystem and EVENTTYPE_ARMORY and EVENTID_ARMORY_EQUIP_STAT_CHANGE then
        EventSystem:postEvent(EVENTTYPE_ARMORY, EVENTID_ARMORY_EQUIP_STAT_CHANGE, resID)
    end
    if EventSystem and EVENTTYPE_WARDROBE and EVENTID_WARDROBE_UPDATE_CURRENT_PUT_ON_GUN then
        EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_CURRENT_PUT_ON_GUN, resID)
    end
    log("سكن سلاح", weaponID, resID, insID)
    showWearBrandNotice()   -- <--- YEH LINE ADD KI HAI
end

        local function putOnHallTheme(insID)
    insID = tonumber(insID)
    if not insID or not isInjectedIns(insID) then return end
    local resID = R.insToRes[insID]
    if not resID or not isHallThemeRes(resID) then return end
    local item = { res_id = resID, count = 1, instid = insID }
    pcall(function()
        local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
        wl:on_puton_rsp(_K.NET_OK, item, nil, 1, insID, 0)
    end)
    pcall(_AutoSaveOutfit)
    log("ثيم لوبي", resID, insID)
    showWearBrandNotice()   -- <--- YEH LINE ADD KI HAI
end

        local function restorePersistedHallTheme()
            if not _G._addOutfitPersistLoaded then return end
            local ins = tonumber(_G._savedHallThemeIns)
            if not ins or ins <= 0 then return end
            later(2.5, function()
                if isInjectedIns(ins) then putOnHallTheme(ins) end
            end)
        end

        -- ========== لوبي سوشيال ==========
        local SOCIAL = _G.AddOutfitSocialState or {}
        _G.AddOutfitSocialState = SOCIAL
        SOCIAL.debGen = SOCIAL.debGen or 0

        local function socialDebounce(sec, fn)
            SOCIAL.debGen = (SOCIAL.debGen or 0) + 1
            local gen = SOCIAL.debGen
            later(sec, function()
                if gen ~= SOCIAL.debGen then return end
                pcall(fn)
            end)
        end

        local function getLobbyCurPage()
            local p = nil
            pcall(function()
                local LMC = require("client.slua.logic.lobby.Main.Lobby_Main_Control")
                if LMC.GetCurPage then p = LMC.GetCurPage() end
            end)
            return p
        end

        local function getWeaponSkinResFast()
            local cch = cache()
            local wid = tonumber(DataMgr.Weapon_ID) or 0
            local w = wid > 0 and cch.weapons[wid] or nil
            if w and w.resID and w.resID > 0 then return w.resID end
            for _, ww in pairs(cch.weapons) do
                if ww.resID and ww.resID > 0 then return ww.resID end
            end
            return nil
        end

        local function resolveLobbyWeaponSkinRes()
            local wid = tonumber(DataMgr.Weapon_ID) or 0
            local skin = getWeaponSkinResFast()
            if skin and skin > 0 then return skin end
            if wid > 0 then
                local fromMatch = getMatchWeaponSkin(wid)
                if fromMatch and fromMatch > 0 then return fromMatch end
            end
            return nil
        end

        local function rememberLobbyOutfitRes(resID)
            resID = tonumber(resID)
            if not resID or resID <= 0 or not isFullSuitRes(resID) then return end
            _G.AddOutfitLastLobbyOutfitRes = resID
            local cch = cache()
            if not cch.outfitRes or cch.outfitRes <= 0 then
                cch.outfitRes = resID
                if isInjectedRes(resID) then cch.outfitIns = R.resToIns[resID] end
            end
        end

        local function resolveLobbyOutfitRes()
            local cch = cache()
            if tonumber(cch.outfitRes) and cch.outfitRes > 0 then return cch.outfitRes end
            if tonumber(_G.AddOutfitLastLobbyOutfitRes) and _G.AddOutfitLastLobbyOutfitRes > 0 then
                return tonumber(_G.AddOutfitLastLobbyOutfitRes)
            end
            if MATCH_CONFIG.outfitRes and tonumber(MATCH_CONFIG.outfitRes) > 0 then
                return tonumber(MATCH_CONFIG.outfitRes)
            end
            for resID in pairs(cch.clothes) do
                if isFullSuitRes(resID) then return resID end
            end
            return nil
        end

        local function collectAllClothResIDs()
            local ids = {}
            local cch = cache()
            if tonumber(cch.outfitRes) and cch.outfitRes > 0 then
                ids[cch.outfitRes] = true
            end
            for resID in pairs(cch.clothes) do
                if not getEquipSkinSlot(resID) and not weaponIdFromSkin(resID) then
                    ids[resID] = true
                end
            end
            return ids
        end

        local function wearPatchKey()
            local outfit = resolveLobbyOutfitRes() or 0
            local skin = resolveLobbyWeaponSkinRes() or 0
            local cch = cache()
            local eq = (cch.equip.bag or 0) .. "_" .. (cch.equip.helmet or 0)
            return outfit .. "_" .. skin .. "_" .. eq
        end

        local function applyInjectedPspace(roleData)
            if not roleData then return end
            roleData.bshow = true
            roleData.pspace_wear_ext = roleData.pspace_wear_ext or {}
            local outfitRes = resolveLobbyOutfitRes()
            if outfitRes and outfitRes > 0 then
                roleData.pspace_wear_ext[ENUM_AVATAR_SHOW_TYPE.SHOW_POS_CLOTH] = { outfitRes, 0, 0 }
            end
            local skinRes = resolveLobbyWeaponSkinRes()
            if skinRes and skinRes > 0 then
                roleData.pspace_wear_ext[ENUM_AVATAR_SHOW_TYPE.SHOW_POS_WEAPON] = { 0, 0, 0 }
                roleData.pspace_wear_ext[ENUM_AVATAR_SHOW_TYPE.SHOW_POS_WEAPONSKIN] = { skinRes, 0, 0 }
                roleData.depot_show_info = roleData.depot_show_info or {}
                if roleData.depot_show_info.weapon == nil then roleData.depot_show_info.weapon = true end
            end
        end

        -- ★ GLOBAL VARIABLE FOR SIG TRACKING (Add this line just above the function if not present)
local _lastWearSig = 0 

-- ★ HELPER: Get Active Weapon ResID Safely
local function getPrimaryWeaponRes()
    local cch = cache()
    if not cch or not cch.weapons then return nil end
    
    -- Try current weapon ID first
    local curWid = tonumber(DataMgr.Weapon_ID) or 0
    if curWid > 0 and cch.weapons[curWid] then
        return cch.weapons[curWid].resID
    end
    
    -- Fallback: First available weapon in cache
    for _, w in pairs(cch.weapons) do
        if w.resID and w.resID > 0 then
            return w.resID
        end
    end
    return nil
end

-- ★ OPTIMIZED PATCH: Integer Signature instead of String Key
local function patchSelfWearCache(force)
    local cch = cache()
    if not cch then return false end
    
    -- Calculate lightweight signature (No Strings!)
    local outfitVal = cch.outfitRes or 0
    local weaponVal = getPrimaryWeaponRes() or 0
    local sig = (outfitVal * 100000) + (weaponVal % 100000)
    
    if not force and sig == _lastWearSig then 
        return false 
    end
    _lastWearSig = sig

    local myUid = tonumber(DataMgr.roleData.uid)
    if not myUid then return false end
    
    pcall(function()
        local BD = ModuleManager.GetModule(ModuleManager.DataModuleConfig.BasicDataAvatarWearInfo)
        local d = BD:GetCacheData(myUid)
        if d then 
            applyInjectedPspace(d) -- Keep existing injector
            requestSocialAvatarRefresh() -- Ensure UI updates only when needed
        end
    end)
    return true
end

        local function requestSocialAvatarRefresh()
            pcall(function()
                if EventSystem and EVENTTYPE_LOBBY_SOCIAL and EVENTID_SOCIAL_LOBBY_REFRESH_AVATAR then
                    EventSystem:postEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_SOCIAL_LOBBY_REFRESH_AVATAR)
                end
            end)
        end

        local function onSocialWearDirty(forceRefresh)
            SOCIAL.lastHandSkin = nil
            if patchSelfWearCache(forceRefresh) then requestSocialAvatarRefresh() end
        end

        local _myUidCached
        local function isMyWearData(wearData)
            if not wearData then return false end
            if not _myUidCached then
                pcall(function() _myUidCached = tonumber(DataMgr.roleData.uid) end)
            end
            return _myUidCached and tonumber(wearData.uid) == _myUidCached
        end

        local function mergeInjectedWeaponIntoWearData(wearData)
            if not isMyWearData(wearData) then return end
            local cch = cache()
            local wKey = ""
            for wid, w in pairs(cch.weapons) do wKey = wKey .. wid .. ":" .. (w.resID or 0) .. "," end
            wKey = wKey .. "|" .. tostring(DataMgr.Weapon_ID or 0)
            local skinRes
            if _weaponSkinResMergeCache.key == wKey then
                skinRes = _weaponSkinResMergeCache.res
            else
                skinRes = resolveLobbyWeaponSkinRes()
                _weaponSkinResMergeCache.key = wKey
                _weaponSkinResMergeCache.res = skinRes
            end
            if not skinRes or skinRes <= 0 then return end
            wearData.mainWeaponInfo = wearData.mainWeaponInfo or {
                weaponResId = 0, weaponSkinId = 0,
                diyInfo = { diyWeaponId = 0, diyDefaultScheme = false, diyScheme = nil },
            }
            wearData.mainWeaponInfo.weaponSkinId = skinRes
            wearData.mainWeaponInfo.weaponResId = 0
        end

        local function getOutfitMergeItems()
            local cch = cache()
            local clothKey = ""
            for resID in pairs(cch.clothes) do clothKey = clothKey .. resID .. "," end
            local key = (cch.outfitRes or 0) .. "_" .. clothKey .. "_" .. (cch.equip.bag or 0) .. "_" .. (cch.equip.helmet or 0)
            if _outfitMergeCache.key == key and _outfitMergeCache.items then
                return _outfitMergeCache.items
            end
            local outfitRes = resolveLobbyOutfitRes()
            local AvatarData = require("client.logic.data.AvatarData")
            local items = {}
            if outfitRes and outfitRes > 0 and isFullSuitRes(outfitRes) then
                rememberLobbyOutfitRes(outfitRes)
                local converted = AvatarData.ConvertToAvatarCustom({ outfitRes, 0, 0 })
                if converted then items[#items + 1] = converted end
                for resID in pairs(collectAllClothResIDs()) do
                    if resID ~= outfitRes and not isFullSuitRes(resID)
                        and not isBodyClothSubType(subType(cfg(resID))) then
                        local cv = AvatarData.ConvertToAvatarCustom({ resID, 0, 0 })
                        if cv then items[#items + 1] = cv end
                    end
                end
            else
                for resID in pairs(collectAllClothResIDs()) do
                    if not isFullSuitRes(resID) then
                        local converted = AvatarData.ConvertToAvatarCustom({ resID, 0, 0 })
                        if converted then items[#items + 1] = converted end
                    end
                end
            end
            _outfitMergeCache.key = key
            _outfitMergeCache.items = items
            return items
        end

        local function mergeInjectedOutfitIntoWearData(wearData)
            if not isMyWearData(wearData) then return end
            local outfitRes = resolveLobbyOutfitRes()
            local items = getOutfitMergeItems()
            if #items == 0 then return end
            if outfitRes and outfitRes > 0 and isFullSuitRes(outfitRes) then
                local newList = {}
                for _, e in ipairs(wearData.WearInfoList or {}) do
                    if not (e and e.ItemID and isBodyClothSubType(subType(cfg(e.ItemID)))) then
                        newList[#newList + 1] = e
                    end
                end
                for _, item in ipairs(items) do
                    newList[#newList + 1] = item
                end
                wearData.WearInfoList = newList
            else
                wearData.WearInfoList = wearData.WearInfoList or {}
                for _, item in ipairs(items) do
                    wearData.WearInfoList[#wearData.WearInfoList + 1] = item
                end
            end
        end

        local function mergeInjectedEquipIntoWearData(wearData)
            if not isMyWearData(wearData) then return end
            local cch = cache()
            wearData.depot_show_info = wearData.depot_show_info or {}
            if cch.equip.bag and cch.equip.bag > 0 then
                local catalogBag = normalizeEquipCatalogRes(cch.equip.bag)
                local bagLevel = getEquipDisplayLevel(cch.equip.bag, "bag")
                wearData.depot_show_info.bag = true
                wearData.bagSkinInsId = mapEquipSkinRes(catalogBag, bagLevel)
                wearData.skin_info = wearData.skin_info or {}
                wearData.skin_info.bag_skin = cch.equip.bagIns or R.resToIns[cch.equip.bag] or cch.equip.bag
                wearData.skin_info.bag_level = bagLevel
            end
            if cch.equip.helmet and cch.equip.helmet > 0 then
                local catalogHelm = normalizeEquipCatalogRes(cch.equip.helmet)
                local helmLevel = getEquipDisplayLevel(cch.equip.helmet, "helmet")
                local helmDisplay = mapEquipSkinRes(catalogHelm, helmLevel)
                wearData.depot_show_info.helmet = true
                wearData.helmet_skin = helmDisplay
                wearData.headShow = helmDisplay
                wearData.skin_info = wearData.skin_info or {}
                wearData.skin_info.helmet_skin = cch.equip.helmetIns or R.resToIns[cch.equip.helmet] or cch.equip.helmet
                wearData.skin_info.head_show = wearData.skin_info.helmet_skin
                wearData.skin_info.helmet_level = helmLevel
            end
        end

        -- ★ SAFE MERGE: Only applies to LOCAL USER in LOBBY/PROFILE context
local function mergeInjectedIntoWearData(wearData)
    -- 1. HARD GUARD: Must exist
    if not wearData then return end
    
    -- 2. CONTEXT CHECK: If we are in a MATCH, DO NOT TOUCH SOCIAL WEAR DATA
    -- This prevents the gun-swapping glitch during gameplay transitions
    if isInGamePlay() then 
        return 
    end

    -- 3. OWNERSHIP CHECK: Only process if it's MY data
    if not isMyWearData(wearData) then 
        return 
    end

    -- Now safely merge components
    pcall(function()
        mergeInjectedWeaponIntoWearData(wearData)
        mergeInjectedOutfitIntoWearData(wearData)
        mergeInjectedEquipIntoWearData(wearData)
    end)
end

        -- تعديل: منع إعادة التطبيق المتكرر في اللوبي
        local function reapplyAccessoryIns(insID)
            insID = tonumber(insID)
            local resID = R.insToRes[insID]
            if not resID then return end
            local c = cfg(resID)
            local st = subType(c)
            saveClothPiece(resID)
            local itemSt = st
            local oldIns, oldRes
            if itemSt then
                oldIns, oldRes = findWornInsBySubType(itemSt)
                if oldIns == insID then oldIns, oldRes = nil, nil end
                removeRoleWearBySubTypes({ [itemSt] = true })
            end
            local WRH = require("client.network.Protocol.WardRobeHandler")
            local olditem
            if oldIns then
                olditem = { res_id = oldRes or R.insToRes[oldIns], count = 1, instid = oldIns }
            end
            WRH.on_depot_put_on_rsp(_K.NET_OK, { res_id = resID, count = 1, instid = insID }, olditem, 1, insID, oldIns or 0)
            pcall(function()
                local av = require("client.slua.logic.wardrobe.logic_wardrobe_avatar")
                if oldIns and itemSt then av:SetCurrentWearPreview(itemSt, nil) end
                if itemSt then av:AddToWearInfo(itemSt, insID, resID, 0, 0) end
                av:AvatarChange(resID, true, 0, 0)
                av:ProcessTakeOff()
                syncFashionBagRolewear()
            end)
        end

        local function reapplyInjectedIns(insID)
            insID = tonumber(insID)
            if not insID or not isInjectedIns(insID) then return end
            local resID = R.insToRes[insID]
            if not resID then return end
            if isHallThemeRes(resID) then
                putOnHallTheme(insID)
            elseif getEquipSkinSlot(resID) then
                putOnEquipSkin(insID)
            elseif getClothKind(resID) then
                putOnCloth(insID)
            elseif weaponIdFromSkin(resID) then
                equipWeaponSkin(weaponIdFromSkin(resID), insID)
            elseif _K.GUN_SUB[subType(cfg(resID))] then
                local cch = cache()
                local foundWid = nil
                for wid, w in pairs(cch.weapons or {}) do
                    if w.resID == resID then foundWid = wid; break end
                end
                if foundWid then equipWeaponSkin(foundWid, insID) end
            elseif subType(cfg(resID)) == _K.MELEE_ID then
                equipWeaponSkin(_K.MELEE_ID, insID)
            elseif isThrowObjectRes(resID) then
                putOnThrowObject(insID)
            else
                reapplyAccessoryIns(insID)
            end
        end

        local function reapplyLobbyEquipped()
            if not GameStatus or not GameStatus.IsInLobbyOrMainCity or not GameStatus.IsInLobbyOrMainCity() then
                return
            end
            if _S.lobbyApplied then return end
            _S.lobbyApplied = true
            later(2.0, function() _S.lobbyApplied = false end)

            restorePersistedVehicles()
            restorePersistedMotions()
            restorePersistedEquipIns()
            restorePersistedThrowObjects()
            restorePersistedHallTheme()
            syncMatchConfigFromCache()

            if not _G._addOutfitPersistLoaded then
                snapshotLobbyWear()
            end
            local cch = cache()
            if not _G._addOutfitPersistLoaded and _G._savedOutfitClothes then
                for resID in pairs(_G._savedOutfitClothes) do
                    cch.clothes[resID] = true
                end
            end
            if not _G._addOutfitPersistLoaded and _G._savedOutfitRes and (not cch.outfitRes or cch.outfitRes <= 0) then
                cch.outfitRes = _G._savedOutfitRes
                cch.outfitIns = _G._savedOutfitIns or R.resToIns[_G._savedOutfitRes]
            end
            syncMatchConfigFromCache()

            local applyStep = 0
            local function scheduleApply(fn)
                applyStep = applyStep + 1
                later(applyStep * 0.12, fn)
            end

            if not _G._addOutfitPersistLoaded and _G._savedRoleWearList and #_G._savedRoleWearList > 0 then
                for _, insID in ipairs(_G._savedRoleWearList) do
                    local id = insID
                    scheduleApply(function() reapplyInjectedIns(id) end)
                end
            elseif cch.outfitIns and isInjectedIns(cch.outfitIns) then
                scheduleApply(function() putOnCloth(cch.outfitIns) end)
            else
                for resID in pairs(cch.clothes) do
                    local ins = R.resToIns[resID]
                    local rid = resID
                    if ins and isInjectedIns(ins) then
                        scheduleApply(function()
                            if getClothKind(rid) then
                                putOnCloth(ins)
                            else
                                reapplyAccessoryIns(ins)
                            end
                        end)
                    end
                end
            end
            for wid, w in pairs(cch.weapons) do
                local weaponID, entry = wid, w
                scheduleApply(function()
                    if entry.insID and isInjectedIns(entry.insID) then
                        equipWeaponSkin(weaponID, entry.insID)
                    elseif entry.resID and R.resToIns[entry.resID] and isInjectedIns(R.resToIns[entry.resID]) then
                        equipWeaponSkin(weaponID, R.resToIns[entry.resID])
                    end
                end)
            end
            for _, slot in ipairs({ "bag", "helmet", "armor", "parachute", "glider" }) do
                local resID = cch.equip[slot]
                local insID = cch.equip[slot .. "Ins"]
                scheduleApply(function()
                    if insID and isInjectedIns(insID) then
                        putOnEquipSkin(insID)
                    elseif resID and R.resToIns[resID] then
                        putOnEquipSkin(R.resToIns[resID])
                    end
                end)
            end
            if cch.throwObjects then
                for st, info in pairs(cch.throwObjects) do
                    local tInfo = info
                    scheduleApply(function()
                        if tInfo.insID and isInjectedIns(tInfo.insID) then
                            putOnThrowObject(tInfo.insID)
                        elseif tInfo.resID and R.resToIns[tInfo.resID] and isInjectedIns(R.resToIns[tInfo.resID]) then
                            putOnThrowObject(R.resToIns[tInfo.resID])
                        end
                    end)
                end
            end
            later(math.max(applyStep * 0.12 + 0.3, 0.5), function()
                syncMatchConfigFromCache()
                pcall(_AutoSaveOutfit, true)
                log("إعادة تطبيق لوبي (مرة واحدة)")
            end)

            pcall(function()
                if _G._addOutfitPersistLoaded then return end
                local GTS = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.GarageThemeSystem)
                if not GTS then return end
                local maxSlots = GTS:GetMaxPositionNum()
                GTS.GarageVehicleInfo = GTS.GarageVehicleInfo or {}
                local usedIns = {}
                for slot, info in pairs(GTS.GarageVehicleInfo) do
                    if info and info.inst_id then
                        usedIns[tonumber(info.inst_id)] = true
                    end
                end
                local changed = false
                for slot = 1, maxSlots do
                    if not GTS.GarageVehicleInfo[slot] then
                        for _, resID in ipairs(_C.vehicleItems) do
                            if isInjectedRes(resID) then
                                local insID = R.resToIns[resID]
                                if insID and not usedIns[insID] then
                                    GTS.GarageVehicleInfo[slot] = { inst_id = insID, res_id = resID }
                                    usedIns[insID] = true
                                    changed = true
                                    break
                                end
                            end
                        end
                    end
                end
                if changed then
                    if EventSystem and EVENTTYPE_LOBBY_THEME and EVENTID_GARAGE_VEHICLE_DATA_CHANGE then
                        EventSystem:postEvent(EVENTTYPE_LOBBY_THEME, EVENTID_GARAGE_VEHICLE_DATA_CHANGE)
                    end
                end
            end)
        end

        local function initHooks()
        local function hookLobbySwipePersistence()
            pcall(function()
                local AC = require("client.slua.logic.avatar.avatar_common")
                local oGetWear = AC.GetWearDataFromRoleData
                AC.GetWearDataFromRoleData = function(roleData)
                    local wearData = oGetWear(roleData)
                    if wearData and roleData and tonumber(roleData.uid) == tonumber(DataMgr.roleData.uid) then
                        mergeInjectedIntoWearData(wearData)
                    end
                    return wearData
                end
                local oUp = AC.UpdateAvatar
                AC.UpdateAvatar = function(avatar, wearData, isShowWeapon, isShowHelmet, isShowBag)
                    if isMyWearData(wearData) then mergeInjectedIntoWearData(wearData) end
                    return oUp(avatar, wearData, isShowWeapon, isShowHelmet, isShowBag)
                end
            end)
            pcall(function()
                if EventSystem and EventSystem.registEvent and EVENTTYPE_LOBBY and EVENTID_SWITCHTO_PAGE_END then
                    EventSystem:registEvent(EVENTTYPE_LOBBY, EVENTID_SWITCHTO_PAGE_END, function(_, _, _, toPage)
                        if ENUM_LobbyPageType and toPage == ENUM_LobbyPageType.Mid then
                            socialDebounce(0.5, reapplyLobbyEquipped) -- زمن أطول لتجنب التكرار
                        end
                    end)
                end
            end)
        end

        -- ========== هوكات اللوبي ==========
        local function hookCDataTableCache()
            pcall(function()
                if not CDataTable or CDataTable._lava_cached then return end
                CDataTable._lava_cached = true
                local origGetTableData = CDataTable.GetTableData
                CDataTable.GetTableData = function(tableName, resID, ...)
                    if tableName == "Item" then
                        resID = tonumber(resID)
                        if resID and _C.cfg[resID] ~= nil then
                            return _C.cfg[resID]
                        end
                        local result = origGetTableData(tableName, resID, ...)
                        if resID then
                            _C.cfg[resID] = result
                        end
                        return result
                    end
                    return origGetTableData(tableName, resID, ...)
                end
            end)
        end

        local function hookDepotInit()
            pcall(function()
                local WDE = require("client.slua.logic.wardrobe.WardrobeDataEntity")
                local orig = WDE.InitData
                WDE.InitData = function(self, pkg)
                    orig(self, pkg)
                    injectAll(self)
                    refreshWardrobe()
                end
            end)
        end

        local function hookWardrobeData()
            pcall(function()
                local wd = require("client.slua.logic.wardrobe.wardrobe_data")
                local function wrapGet(name)
                    local o = wd[name]
                    if not o then return end
                    wd[name] = function(self, insID, ...)
                        insID = tonumber(insID)
                        if isInjectedIns(insID) then
                            local e = getEntity()
                            if e then return e:GetDataByInsID(insID) end
                        end
                        return o(self, insID, ...)
                    end
                end
                wrapGet("GetHallDepotItemDataByInsID")
                wrapGet("GetValidHallDepotItemDataByInsID")
                local function wrapBool(name)
                    local o = wd[name]
                    if not o then return end
                    wd[name] = function(self, id, ...)
                        if isInjectedRes(tonumber(id)) or isInjectedIns(tonumber(id)) then return true end
                        return o(self, id, ...)
                    end
                end
                wrapBool("HasItem")
                wrapBool("HasValidItem")
                wrapBool("CheckHasPermanentItem")
                if not wd._lava_global_equip then
                    wd._lava_global_equip = true
                    local origGetEquipped = wd.GetEquippedSkinIDByWeaponID
                    wd.GetEquippedSkinIDByWeaponID = function(self, weaponID)
                        local w = cache().weapons[tonumber(weaponID)]
                        if w and w.resID and w.resID > 0 then return w.resID end
                        return origGetEquipped(self, weaponID)
                    end
                end
                if not wd._lava_global_equip_ins then
                    wd._lava_global_equip_ins = true
                    if wd.GetEquippedSkinInsIDByWeaponID then
                        local origGetEquippedIns = wd.GetEquippedSkinInsIDByWeaponID
                        wd.GetEquippedSkinInsIDByWeaponID = function(self, weaponID)
                            local w = cache().weapons[tonumber(weaponID)]
                            if w and w.insID and w.insID > 0 and isInjectedIns(w.insID) then return w.insID end
                            return origGetEquippedIns(self, weaponID)
                        end
                    end
                    if wd.GetWeaponSkinInsID then
                        local origGetWSI = wd.GetWeaponSkinInsID
                        wd.GetWeaponSkinInsID = function(self, weaponID)
                            local w = cache().weapons[tonumber(weaponID)]
                            if w and w.insID and w.insID > 0 and isInjectedIns(w.insID) then return w.insID end
                            return origGetWSI(self, weaponID)
                        end
                    end
                end
            end)
            pcall(function()
                local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
                local oPutDownReq = wl.wardrobe_put_down_req
                if oPutDownReq then
                    wl.wardrobe_put_down_req = function(self, ins_id, unequip_by_server)
                        ins_id = tonumber(ins_id)
                        if isInjectedIns(ins_id) then
                            local resID = R.insToRes[ins_id]
                            takeOffItem(ins_id)
                            pcall(function()
                                self:on_putdown_rsp(_K.NET_OK, {
                                    instid = ins_id,
                                    res_id = resID or 0,
                                }, nil)
                            end)
                            pcall(function()
                                if EventSystem and EVENTTYPE_WARDROBE and EVENTID_WARDROBE_UPDATE_PUT_DOWN_DATA then
                                    EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_PUT_DOWN_DATA, {
                                        instid = ins_id,
                                        res_id = resID or 0,
                                        count = 1,
                                    })
                                end
                            end)
                            refreshWardrobe()
                            return
                        end
                        return oPutDownReq(self, ins_id, unequip_by_server)
                    end
                end
            end)
        end

        local function hookPageFilter()
            pcall(function()
                local SubTab = require("client.slua.umg.Wardrobe.subtab_item_list_base")
                if SubTab._lava_prefilter then return end
                SubTab._lava_prefilter = true
                local origGet = SubTab.GetArrayHallDepotItemInfo
                SubTab.GetArrayHallDepotItemInfo = function(self)
                    local allData = origGet(self)
                    if not allData or not next(allData) then return allData end
                    local pageId = self.subTabConfig and self.subTabConfig.pageId
                    local subTabId = self.subTabConfig and self.subTabConfig.subTabId
                    if not pageId or not subTabId then return allData end
                    local result = {}
                    for _, data in pairs(allData) do
                        local resID = depotResID(data)
                        if resID and isInjectedRes(resID) then
                            local itemMain, itemSub = getInjectedItemTab(resID, data)
                            if itemMain == pageId then
                                if pageId == _K.WARDROBE_PAGE_AVATAR then
                                    if subTabId == _K.WARDROBE_TAB_SUIT or subTabId == _K.WARDROBE_TAB_CLOTHES then
                                        local st = data.itemSubType or subType(cfg(resID))
                                        if st == _K.ST_TOP then
                                            local full = isFullSuitRes(resID, data)
                                            if (subTabId == _K.WARDROBE_TAB_SUIT and full) or
                                            (subTabId == _K.WARDROBE_TAB_CLOTHES and not full) then
                                                result[#result + 1] = data
                                            end
                                        end
                                    elseif itemSub == subTabId then
                                        result[#result + 1] = data
                                    end
                                elseif itemSub == subTabId then
                                    result[#result + 1] = data
                                end
                            end
                        else
                            result[#result + 1] = data
                        end
                    end
                    return result
                end
            end)
            pcall(function()
                local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
                local o1 = wl.IsValidCurrentPageItem
                wl.IsValidCurrentPageItem = function(self, mainTab, subTab, v, t)
                    local resID = depotResID(v)
                    if resID and isInjectedRes(resID) then
                        local cacheKey = resID .. "_" .. mainTab .. "_" .. subTab
                        if _C.pageMatch[cacheKey] ~= nil then
                            return _C.pageMatch[cacheKey]
                        end
                        local result
                        if not (v.expireTS == 0 or not t or t < v.expireTS) then
                            result = false
                        else
                            local equipOk = injectedEquipAllowed(resID, mainTab, subTab)
                            if equipOk ~= nil then
                                result = equipOk
                            elseif weaponIdFromSkin(resID) then
                                result = mainTab == _K.WARDROBE_PAGE_WEAPON and subTab == _K.WARDROBE_TAB_GUN
                            elseif mainTab == _K.WARDROBE_PAGE_VEHICLE then
                                local c = cfg(resID)
                                local wmTab = c and tonumber(c.WardrobeMainTab or c.wardrobeMainTab) or 0
                                if wmTab ~= mainTab and v.mainTabType ~= mainTab then
                                    result = false
                                else
                                    local wTab = c and tonumber(c.WardrobeTab or c.wardrobeTab) or nil
                                    local vTab = v.subTabType and tonumber(v.subTabType) or nil
                                    if wTab and wTab == subTab then result = true
                                    elseif vTab and vTab == subTab then result = true
                                    else result = o1(self, mainTab, subTab, v, t) end
                                end
                            elseif mainTab == _K.WARDROBE_PAGE_AVATAR then
                                local st = v.itemSubType or subType(cfg(resID))
                                if st == _K.ST_TOP then
                                    local full = isFullSuitRes(resID, v)
                                    if subTab == _K.WARDROBE_TAB_SUIT and full then result = true
                                    elseif subTab == _K.WARDROBE_TAB_CLOTHES and not full then result = true
                                    else result = false end
                                elseif st == _K.ST_PANTS and subTab == _K.WARDROBE_TAB_TROUSERS then
                                    result = true
                                elseif st == _K.ST_SHOES and subTab == _K.WARDROBE_TAB_SHOES then
                                    result = true
                                elseif v.subTabType == subTab then
                                    result = true
                                else
                                    result = false
                                end
                            else
                                result = o1(self, mainTab, subTab, v, t)
                            end
                        end
                        _C.pageMatch[cacheKey] = result
                        return result
                    end
                    return o1(self, mainTab, subTab, v, t)
                end
                local o2 = wl.IsCanUse
                wl.IsCanUse = function(self, resId)
                    if isInjectedRes(resId) then return true end
                    return o2(self, resId)
                end
                local o4 = wl.GetWardrobeInsIdByResId
                wl.GetWardrobeInsIdByResId = function(self, resid)
                    resid = tonumber(resid)
                    if isInjectedRes(resid) then return R.resToIns[resid] end
                    return o4(self, resid)
                end
            end)
        end

        local function hookArmory()
            pcall(function()
                local Arm = require("client.logic.armory.logic_armory")
                if not Arm._lava_global_own then
                    Arm._lava_global_own = true
                    local origIsOwn = Arm.IsSkinOwn
                    Arm.IsSkinOwn = function(weaponID, skinID)
                        if isInjectedRes(skinID) then return 1 end
                        return origIsOwn(weaponID, skinID)
                    end
                end
                if not Arm._lava_global_get_install then
                    Arm._lava_global_get_install = true
                    if Arm.get_install_skin then
                        local origGetInstall = Arm.get_install_skin
                        Arm.get_install_skin = function(weaponID)
                            local w = cache().weapons[tonumber(weaponID)]
                            if w and w.insID and w.insID > 0 and isInjectedIns(w.insID) then
                                return { skin_id = w.insID }
                            end
                            return origGetInstall(weaponID)
                        end
                    end
                    if Arm.GetInstallSkinInsID then
                        local origGetInstall2 = Arm.GetInstallSkinInsID
                        Arm.GetInstallSkinInsID = function(weaponID)
                            local w = cache().weapons[tonumber(weaponID)]
                            if w and w.insID and w.insID > 0 and isInjectedIns(w.insID) then
                                return w.insID
                            end
                            return origGetInstall2(weaponID)
                        end
                    end
                end
                local oi = Arm.install_weapon_skin
                Arm.install_weapon_skin = function(cd, wid, ins)
                    ins = tonumber(ins)
                    if isInjectedIns(ins) then
                        wid = tonumber(weaponIdFromSkin(R.insToRes[ins]) or wid)
                        equipWeaponSkin(wid, ins)
                        return
                    end
                    return oi(cd, wid, ins)
                end
                local function hookArmoryUninstall(fnName)
                    local orig = Arm[fnName]
                    if not orig then return end
                    Arm[fnName] = function(cd, wid, ins, ...)
                        ins = tonumber(ins)
                        wid = tonumber(wid)
                        if ins and isInjectedIns(ins) then
                            local resID = R.insToRes[ins]
                            wid = weaponIdFromSkin(resID) or wid
                            if takeOffItem(ins) then
                                refreshWardrobe()
                                return
                            end
                        elseif wid and wid > 0 then
                            local cch = cache()
                            local w = cch.weapons[wid]
                            if w and w.insID and isInjectedIns(w.insID) then
                                if takeOffItem(w.insID) then
                                    refreshWardrobe()
                                    return
                                end
                            end
                        end
                        return orig(cd, wid, ins, ...)
                    end
                end
                hookArmoryUninstall("uninstall_weapon_skin")
                hookArmoryUninstall("remove_weapon_skin")
            end)
        end

        local function hookLobbyTheme()
            pcall(function()
                local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
                if wl._lava_hooked_hall_theme then return end
                wl._lava_hooked_hall_theme = true
                local origPutOn = wl.wardrobe_puton_req
                wl.wardrobe_puton_req = function(self, insID, extra)
                    insID = tonumber(insID)
                    if insID and isInjectedIns(insID) and isHallThemeRes(R.insToRes[insID]) then
                        putOnHallTheme(insID)
                        return
                    end
                    return origPutOn(self, insID, extra)
                end
            end)
        end

        local function hookPutOn()
            pcall(function()
                local WRH = require("client.network.Protocol.WardRobeHandler")
                local o = WRH.send_depot_put_on_req
                WRH.send_depot_put_on_req = function(insID, extra)
                    insID = tonumber(insID)
                    if isInjectedIns(insID) then
                        local resID = R.insToRes[insID]
                        local c = cfg(resID)
                        local st = subType(c)
                        if getEquipSkinSlot(resID) then
                            putOnEquipSkin(insID)
                            return
                        end
                        if getClothKind(resID) then
                            putOnCloth(insID)
                            return
                        end
                        if _K.GUN_SUB[st] then
                            local wid = weaponIdFromSkin(resID)
                            if not wid then
                                pcall(function()
                                    local wgl = require("client.slua.logic.wardrobe.logic_wardrobe_gun")
                                    wid = wgl.GetCurGunID and wgl:GetCurGunID() or nil
                                    if not wid and wgl.GetCurrentGunID then
                                        wid = wgl:GetCurrentGunID()
                                    end
                                end)
                            end
                            if wid then equipWeaponSkin(wid, insID) end
                            return
                        end
                        if st == _K.MELEE_ID then
                            equipWeaponSkin(_K.MELEE_ID, insID)
                            return
                        end
                        if isHallThemeRes(resID) then
                            putOnHallTheme(insID)
                            return
                        end
                        if isThrowObjectRes(resID) then
                            local st = isThrowObjectRes(resID)
                            local cch = cache()
                            local oldThrow = cch.throwObjects and cch.throwObjects[st]
                            local oldInsID = oldThrow and oldThrow.insID or 0
                            local oldResID = oldThrow and oldThrow.resID or 0
                            putOnThrowObject(insID)
                            local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                            local bagIndex = fbd:GetFashionBagUseIndex()
                            local olditem
                            if oldInsID and oldInsID ~= insID and oldInsID ~= 0 then
                                olditem = { res_id = oldResID, count = 1, instid = oldInsID }
                            end
                            WRH.on_depot_put_on_rsp(_K.NET_OK, { res_id = resID, count = 1, instid = insID }, olditem, bagIndex, insID, oldInsID, extra)
                            return
                        end
                        local mainTab = wardrobeMainTab(resID)
                        if mainTab == _K.WARDROBE_PAGE_VEHICLE then
                            local item = { res_id = resID, count = 1, instid = insID }
                            WRH.on_depot_put_on_rsp(_K.NET_OK, item, nil, 1, insID, 0, extra)
                            return
                        end
                        local wd = require("client.slua.logic.wardrobe.wardrobe_data")
                        if wd:GetHallDepotItemDataByInsID(insID) then
                            -- إكسسوار (ماسك/نظارة/طاقية): اخلع القديم بنفس النوع أولاً
                            -- كي لا تظهر أكثر من علامة صح على عناصر نفس الخانة
                            local itemSt = st or subType(cfg(resID))
                            local oldIns, oldRes
                            if itemSt then
                                oldIns, oldRes = findWornInsBySubType(itemSt)
                                if oldIns == insID then oldIns, oldRes = nil, nil end
                                removeRoleWearBySubTypes({ [itemSt] = true })
                            end
                            saveClothPiece(resID)
                            local olditem
                            if oldIns then
                                olditem = { res_id = oldRes or R.insToRes[oldIns], count = 1, instid = oldIns }
                            end
                            WRH.on_depot_put_on_rsp(_K.NET_OK, { res_id = resID, count = 1, instid = insID }, olditem, 1, insID, oldIns or 0, extra)
                            pcall(function()
                                local av = require("client.slua.logic.wardrobe.logic_wardrobe_avatar")
                                if oldIns and itemSt then av:SetCurrentWearPreview(itemSt, nil) end
                                if itemSt then av:AddToWearInfo(itemSt, insID, resID, 0, 0) end
                                av:AvatarChange(resID, true, 0, 0)
                                av:ProcessTakeOff()
                                syncFashionBagRolewear()
                            end)
                            pcall(_AutoSaveOutfit)
                        end
                        return
                    end
                    return o(insID, extra)
                end
            end)

            pcall(function()
                local WRH = require("client.network.Protocol.WardRobeHandler")
                local oPutDown = WRH.send_depot_put_down_req
                WRH.send_depot_put_down_req = function(insID, extra)
                    insID = tonumber(insID)
                    if isInjectedIns(insID) then
                        local resID = R.insToRes[insID]
                        local removed = takeOffItem(insID)
                        if removed then
                            local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
                            pcall(function()
                                wl:on_putdown_rsp(_K.NET_OK, {
                                    res_id = resID or 0,
                                    instid = insID,
                                    count  = 1,
                                }, nil)
                            end)
                            pcall(function()
                                if EventSystem and EVENTTYPE_WARDROBE and EVENTID_WARDROBE_UPDATE_PUT_DOWN_DATA then
                                    EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_PUT_DOWN_DATA, {
                                        instid = insID,
                                        res_id = resID or 0,
                                        count = 1,
                                    })
                                end
                            end)
                            refreshWardrobe()
                            return
                        end
                    end
                    return oPutDown(insID, extra)
                end
            end)

            pcall(function()
                local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
                local oPutDownReq = wl.wardrobe_put_down_req
                if oPutDownReq then
                    wl.wardrobe_put_down_req = function(self, ins_id, unequip_by_server)
                        ins_id = tonumber(ins_id)
                        if isInjectedIns(ins_id) then
                            local resID = R.insToRes[ins_id]
                            takeOffItem(ins_id)
                            pcall(function()
                                self:on_putdown_rsp(_K.NET_OK, {
                                    instid = ins_id,
                                    res_id = resID or 0,
                                }, nil)
                            end)
                            pcall(function()
                                if EventSystem and EVENTTYPE_WARDROBE and EVENTID_WARDROBE_UPDATE_PUT_DOWN_DATA then
                                    EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_PUT_DOWN_DATA, {
                                        instid = ins_id,
                                        res_id = resID or 0,
                                        count = 1,
                                    })
                                end
                            end)
                            refreshWardrobe()
                            return
                        end
                        return oPutDownReq(self, ins_id, unequip_by_server)
                    end
                end
            end)

            pcall(function()
                local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
                local oEquipSlot = wl.EquipSlotVehicle
                if oEquipSlot and not wl._lava_hooked_equip_slot_vehicle then
                    wl._lava_hooked_equip_slot_vehicle = true
                    wl.EquipSlotVehicle = function(self, resid, dragVehicleInsID, Index)
                        dragVehicleInsID = tonumber(dragVehicleInsID)
                        if dragVehicleInsID and isInjectedIns(dragVehicleInsID) then
                            local resID = R.insToRes[dragVehicleInsID]
                            local c = cfg(resID)
                            local itemSubType = c and tonumber(c.ItemSubType or c.itemSubType) or 0
                            if itemSubType and itemSubType > 0 then
                                DataMgr.VehicleSlotList = DataMgr.VehicleSlotList or {}
                                local slotList = DataMgr.VehicleSlotList[itemSubType] or {}
                                local idx = Index or 1
                                for i = #slotList, 1, -1 do
                                    if slotList[i] == dragVehicleInsID then
                                        table.remove(slotList, i)
                                    end
                                end
                                slotList[idx] = dragVehicleInsID
                                DataMgr.VehicleSlotList[itemSubType] = slotList
                                if DataMgr.vehicleSkinInsIDTable then
                                    DataMgr.vehicleSkinInsIDTable[resID] = DataMgr.vehicleSkinInsIDTable[resID] or dragVehicleInsID
                                end
                            end
                            DataMgr.UpdateVehicleSkin(itemSubType, dragVehicleInsID)
                            pcall(function()
                                local tabSurveillance = require("client.slua.logic.wardrobe.tab_surveillance")
                                if tabSurveillance and tabSurveillance.VehicleChange then
                                    tabSurveillance.VehicleChange()
                                end
                            end)
                            if EventSystem and EVENTTYPE_WARDROBE and EVENTID_WARDROBE_VEHICLE_SLOT_DATA_CHANGE then
                                EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_VEHICLE_SLOT_DATA_CHANGE)
                            end
                            return
                        end
                        return oEquipSlot(self, resid, dragVehicleInsID, Index)
                    end
                end
            end)

            pcall(function()
                local GarageThemeSystem = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.GarageThemeSystem)
                if GarageThemeSystem and not GarageThemeSystem._lava_hooked_equip_vehicle then
                    GarageThemeSystem._lava_hooked_equip_vehicle = true
                    local oEquip = GarageThemeSystem.EquipVehicle
                    GarageThemeSystem.EquipVehicle = function(self, Position, InsID)
                        InsID = tonumber(InsID)
                        if InsID and isInjectedIns(InsID) then
                            self:OnEquipVehicle(Position, InsID)
                            return
                        end
                        return oEquip(self, Position, InsID)
                    end
                    local oBatch = GarageThemeSystem.BatchEquipVehicle
                    GarageThemeSystem.BatchEquipVehicle = function(self, InsIDList)
                        if InsIDList and type(InsIDList) == "table" then
                            local hasInjected = false
                            local filtered = {}
                            for slot, ins in pairs(InsIDList) do
                                if isInjectedIns(tonumber(ins)) then
                                    hasInjected = true
                                    self:OnEquipVehicle(slot, tonumber(ins))
                                else
                                    filtered[slot] = ins
                                end
                            end
                            if hasInjected and not next(filtered) then
                                return
                            end
                            InsIDList = filtered
                        end
                        return oBatch(self, InsIDList)
                    end

                    local oReceive = GarageThemeSystem.OnReceiveGarageData
                    GarageThemeSystem.OnReceiveGarageData = function(self, VehicleInfo)
                        local injectedSlots = {}
                        if self.GarageVehicleInfo then
                            for slot, info in pairs(self.GarageVehicleInfo) do
                                if info and info.inst_id and isInjectedIns(tonumber(info.inst_id)) then
                                    injectedSlots[slot] = info
                                end
                            end
                        end
                        oReceive(self, VehicleInfo)
                        for slot, info in pairs(injectedSlots) do
                            if not self.GarageVehicleInfo[slot] then
                                self.GarageVehicleInfo[slot] = info
                            end
                        end
                    end

                    local oGetInfo = GarageThemeSystem.GetGarageVehicleInfo
                    GarageThemeSystem.GetGarageVehicleInfo = function(self)
                        if not self.bDataReceived and self.GarageVehicleInfo and next(self.GarageVehicleInfo) then
                            return self.GarageVehicleInfo
                        end
                        return oGetInfo(self)
                    end

                    local oGetShowList = GarageThemeSystem.GetGarageShowCarInsIDList
                    if oGetShowList then
                        GarageThemeSystem.GetGarageShowCarInsIDList = function(self, VehicleType)
                            local List = oGetShowList(self, VehicleType) or {}
                            for _, resID in ipairs(_C.vehicleItems) do
                                if isInjectedRes(resID) and #List < self:GetMaxPositionNum() then
                                    local c = cfg(resID)
                                    if c then
                                        local itemSubType = tonumber(c.ItemSubType or c.itemSubType) or 0
                                        local taxonomy = CDataTable.GetTableDataByFilter("WardrobeVehiclesTaxonomy", "ItemSubType", itemSubType)
                                        if taxonomy and taxonomy.UseInGarage == 1 and taxonomy.CategoryID == VehicleType then
                                            local insID = R.resToIns[resID]
                                            if insID then
                                                local alreadyIn = false
                                                for _, existingIns in ipairs(List) do
                                                    if tonumber(existingIns) == tonumber(insID) then
                                                        alreadyIn = true
                                                        break
                                                    end
                                                end
                                                if not alreadyIn then
                                                    table.insert(List, insID)
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            return List
                        end
                    end
                end
            end)
        end

        local function hookMotionEquip()
            pcall(function()
                local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
                if wl._lava_hooked_motion then return end
                wl._lava_hooked_motion = true

                local origEquip = wl.EquipMotion
                wl.EquipMotion = function(self, instid, dst_slot)
                    instid = tonumber(instid)
                    if instid and isInjectedIns(instid) then
                        local insSlot = 0
                        for i, v in ipairs(DataMgr.MotionSlotList) do
                            if v == instid then insSlot = i; break end
                        end
                        if insSlot > 0 then
                            local curIns = DataMgr.MotionSlotList[dst_slot]
                            if curIns == instid then return end
                            DataMgr.MotionSlotList[insSlot] = curIns or 0
                            DataMgr.MotionSlotList[dst_slot] = instid
                        else
                            while #DataMgr.MotionSlotList < dst_slot do
                                table.insert(DataMgr.MotionSlotList, 0)
                            end
                            DataMgr.MotionSlotList[dst_slot] = instid
                        end
                        if EventSystem and EVENTTYPE_MOTION and EVENTID_MOTION_UPDATE_SLOT_LIST then
                            EventSystem:postEvent(EVENTTYPE_MOTION, EVENTID_MOTION_UPDATE_SLOT_LIST)
                        end
                        pcall(_AutoSaveOutfit)
                        return
                    end
                    return origEquip(self, instid, dst_slot)
                end

                local origUnequip = wl.unequip_motion_req
                wl.unequip_motion_req = function(self, instid, slot)
                    instid = tonumber(instid)
                    if instid and isInjectedIns(instid) then
                        for i, v in ipairs(DataMgr.MotionSlotList) do
                            if v == instid then
                                table.remove(DataMgr.MotionSlotList, i)
                                break
                            end
                        end
                        if EventSystem and EVENTTYPE_MOTION and EVENTID_MOTION_UPDATE_SLOT_LIST then
                            EventSystem:postEvent(EVENTTYPE_MOTION, EVENTID_MOTION_UPDATE_SLOT_LIST)
                        end
                        pcall(_AutoSaveOutfit)
                        return
                    end
                    return origUnequip(self, instid, slot)
                end
            end)
        end

        local _emoteSlotKey = nil
        local _emoteSlotCache = {}
        local function getInjectedEmotes()
            local slotList = DataMgr and DataMgr.MotionSlotList or {}
            local key = table.concat(slotList, ",")
            if key == _emoteSlotKey then return _emoteSlotCache end
            _emoteSlotKey = key
            _emoteSlotCache = {}
            for _, insID in ipairs(slotList) do
                insID = tonumber(insID)
                if insID and insID > 0 and isInjectedIns(insID) then
                    local resID = R.insToRes[insID]
                    if resID then
                        local c = cfg(resID)
                        if c and tonumber(c.ItemType) == 22 then
                            _emoteSlotCache[#_emoteSlotCache + 1] = {
                                resID = resID,
                                name = c.ItemName or "",
                                icon = c.ItemSmallIcon or c.ItemIcon or ""
                            }
                        end
                    end
                end
            end
            return _emoteSlotCache
        end

        local function hookIngameEmote()
            pcall(function()
                local QEU = require("GameLua.Mod.BaseMod.Client.Emote.QuickExpressionUtils")
                if QEU._lava_hooked then return end
                QEU._lava_hooked = true

                local origGetList = QEU.GetShowExpressionList
                QEU.GetShowExpressionList = function()
                    local tShowEmoteList, nWeaponEmoteId = origGetList()
                    tShowEmoteList = tShowEmoteList or {}
                    local emotes = getInjectedEmotes()
                    if #emotes > 0 then
                        local existingIDs = {}
                        for _, existing in pairs(tShowEmoteList) do
                            if existing.DefineID then
                                existingIDs[tonumber(existing.DefineID.TypeSpecificID) or 0] = true
                            end
                        end
                        for _, em in ipairs(emotes) do
                            if not existingIDs[em.resID] then
                                tShowEmoteList[#tShowEmoteList + 1] = {
                                    DefineID = {TypeSpecificID = em.resID},
                                    Name = em.name
                                }
                            end
                        end
                    end
                    return tShowEmoteList, nWeaponEmoteId
                end
            end)

            pcall(function()
                local QE = require("GameLua.Mod.BaseMod.Client.Emote.QuickExpression")
                if QE._lava_hooked_img then return end
                QE._lava_hooked_img = true

                local origGetImg = QE.GetEmoteImagePalthMap
                QE.GetEmoteImagePalthMap = function(self, ...)
                    origGetImg(self, ...)
                    local emotes = getInjectedEmotes()
                    for _, em in ipairs(emotes) do
                        if em.icon ~= "" then
                            self.ItemIDToImagePathMap[em.resID] = em.icon
                        end
                    end
                end
            end)

            pcall(function()
                local le = require("GameLua.Mod.Library.GamePlay.Avatar.Emote.logic_emote")
                if le._lava_hooked_exist then return end
                le._lava_hooked_exist = true

                local origExist = le.IsEmoteExist
                le.IsEmoteExist = function(EmoteID)
                    if isInjectedRes(tonumber(EmoteID)) then return true end
                    return origExist(EmoteID)
                end

                local origDownloaded = le.CheckEmoteDownloaded
                if origDownloaded then
                    le.CheckEmoteDownloaded = function(EmoteID, bUseCache, bLobby, bForeceLobby)
                        if isInjectedRes(tonumber(EmoteID)) then return true end
                        return origDownloaded(EmoteID, bUseCache, bLobby, bForeceLobby)
                    end
                end
            end)
        end

        local function hookFashionBag()
            pcall(function()
                local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                if fbd._lava_hooked_bag then return end
                fbd._lava_hooked_bag = true
                local function onFashionBagSkinChanged(skin, slot)
                    skin = tonumber(skin)
                    if _S.equipSkinApplying or not skin or skin <= 0 or not isInjectedIns(skin) then return end
                    local rid = R.insToRes[skin]
                    if not rid or not isInjectedRes(rid) then return end
                    local cch = cache()
                    local oldRes = cch.equip[slot]
                    if oldRes and oldRes > 0 and oldRes ~= rid then
                        softRemoveEquipVisual(oldRes, slot)
                    end
                    saveEquipSkin(rid, skin)
                    if slot ~= "parachute" and slot ~= "glider" then
                        applyEquipVisual(rid, skin, slot)
                    end
                end
                local origBag = fbd.SetBagSkin
                fbd.SetBagSkin = function(self, skin)
                    local r = origBag(self, skin)
                    onFashionBagSkinChanged(skin, "bag")
                    return r
                end
                local origHelm = fbd.SetHelmetSkin
                fbd.SetHelmetSkin = function(self, skin)
                    local r = origHelm(self, skin)
                    onFashionBagSkinChanged(skin, "helmet")
                    return r
                end
                local function reInjectThrowObjects(bagIndex)
                    pcall(function()
                        local cch = cache()
                        if not cch.throwObjects then return end
                        local bags = fbd.GetFashionBags and fbd:GetFashionBags()
                        if not bags or not bags.bags then return end
                        local bag = bags.bags[bagIndex]
                        if not bag then return end
                        bag.throw_object_list = bag.throw_object_list or {}
                        for st, info in pairs(cch.throwObjects) do
                            if info.insID and info.insID > 0 and _K.THROW_SUB[st] then
                                bag.throw_object_list[st] = info.insID
                            end
                        end
                    end)
                end
                local origUpdateAll = fbd.UpdateAllFashionBagExtraInfos
                if origUpdateAll then
                    fbd.UpdateAllFashionBagExtraInfos = function(self, all_knapsack_ext_info)
                        origUpdateAll(self, all_knapsack_ext_info)
                        if all_knapsack_ext_info then
                            for i, _ in pairs(all_knapsack_ext_info) do
                                reInjectThrowObjects(i)
                            end
                        end
                    end
                end
                local origUpdateOne = fbd.UpdateFashionBagExtraInfoByIndex
                if origUpdateOne then
                    fbd.UpdateFashionBagExtraInfoByIndex = function(self, index, knapsack_ext_info)
                        origUpdateOne(self, index, knapsack_ext_info)
                        if index then reInjectThrowObjects(index) end
                    end
                end
            end)
            pcall(function()
                if not DataMgr or DataMgr._lava_hooked_equip_skin then return end
                DataMgr._lava_hooked_equip_skin = true
                local orig = DataMgr.UpdateEquipmentSkin
                DataMgr.UpdateEquipmentSkin = function(itemSubType, putOnId)
                    putOnId = tonumber(putOnId)
                    if putOnId and putOnId > 0 and isInjectedIns(putOnId) and not _S.equipSkinApplying then
                        putOnEquipSkin(putOnId)
                    elseif putOnId == 0 then
                        local slot = (itemSubType == ENUM_ITEM_SUBTYPE.Backpack) and "bag"
                            or (itemSubType == ENUM_ITEM_SUBTYPE.Helmet_NoLevel) and "helmet" or nil
                        if slot then
                            local cch = cache()
                            takeOffEquipSkinVisual(slot, cch.equip[slot], cch.equip[slot .. "Ins"])
                            cch.equip[slot]          = nil
                            cch.equip[slot .. "Ins"] = nil
                            if MATCH_CONFIG.equip then MATCH_CONFIG.equip[slot] = 0 end
                            _S.matchApplied = false
                            invalidateSocialWearCache()
                            pcall(_AutoSaveOutfit)
                        end
                    end
                    return orig(itemSubType, putOnId)
                end
            end)
        end

        local function hookBackpackValid()
            if _G.DEV_WARDROBE_BP_HOOKED then return end
            _G.DEV_WARDROBE_BP_HOOKED = true
            pcall(function()
                local BU = import("BackpackUtils")
                if BU and BU.GetBPIDByResID then
                    local orig = BU.GetBPIDByResID
                    BU.GetBPIDByResID = function(resID)
                        resID = tonumber(resID)
                        if resID and isInjectedRes(resID) then
                            local bp = orig(resID)
                            if bp and bp > 0 then return bp end
                            return resID
                        end
                        return orig(resID)
                    end
                end
            end)
            pcall(function()
                local AU = import("AvatarUtils")
                if AU and AU.GetBPIDByResID then
                    local orig = AU.GetBPIDByResID
                    -- ★ STRICT SELF-CHECK IN WEAPON HOOK
AU.GetBPIDByResID = function(resID, ...)
    resID = tonumber(resID)
    
    -- 1. If not an injected resource, pass through normally
    if not isInjectedRes(resID) then
        return orig(resID, ...)
    end
    
    -- 2. CRITICAL: Are we rendering OURSELF?
    -- In Social/Lobby views, the 'context' might be ambiguous.
    -- We rely on the fact that we ONLY want to inject if we are in Match OR explicitly viewing Own Profile.
    
    if isInGamePlay() then
        -- In Match: Always allow injection for Local Player
        return resID
    elseif isInLobby() then
        -- In Lobby: Only allow if this call comes from OUR OWN Avatar Component
        -- Since this is a static util, we can't easily check 'self'. 
        -- SAFEST BYPASS: Disable injection entirely in Lobby unless forced by Profile Open Event.
        -- To prevent flickering, we let the native game handle lobby previews UNLESS we specifically patched it via mergeInjectedIntoWearData.
        return orig(resID, ...) 
    end
    
    return orig(resID, ...)
end
                end
            end)
        end

        local function hookAvatarValid()
            pcall(function()
                local CAC = require("GameLua.Mod.Library.GamePlay.Avatar.Component.CharacterAvatarComponent")
                if not CAC._lava_hooked_check_valid then
                    CAC._lava_hooked_check_valid = true
                    local orig = CAC.CheckItemValid
                    CAC.CheckItemValid = function(self, resID)
                        if isInjectedRes(resID) then return true end
                        return orig(self, resID)
                    end
                end
                if not CAC._lava_hooked_puton then
                    CAC._lava_hooked_puton = true
                    local origPutOn = CAC.PutOnCustomEquipmentByID
                    CAC.PutOnCustomEquipmentByID = function(self, resID, CustomData)
                        -- Skip non-local player to avoid lag
                        if self.IsSelf and not self:IsSelf() then
                            return origPutOn(self, resID, CustomData)
                        end
                        resID = tonumber(resID)
                        if resID and isInjectedRes(resID) then
                            local ok, result = pcall(function()
                                local ItemDefineID = FItemDefineID(4, resID)
                                local EAvatarCustomType = import("EAvatarCustomType")
                                local AvatarCustom = FAvatarCustomDefault()
                                if CustomData then AvatarCustom = CustomData end
                                AvatarCustom.CustomType = EAvatarCustomType.AvatarCustomCharacter
                                return self:HandleEquipItem(ItemDefineID, AvatarCustom)
                            end)
                            if ok and result == true then return true end
                            if ok and result ~= false and result ~= nil then return result end
                        end
                        return origPutOn(self, resID, CustomData)
                    end
                end
            end)
        end

        -- ========== ماتش ==========
        local function isInLobby()
            local ok, r = pcall(function()
                return GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity() == true
            end)
            return ok and r == true
        end

        local function isInRealMatch()
            local ok, r = pcall(function()
                return GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus() == true
            end)
            return ok and r == true
        end

        local function isInGamePlay()
            if isInLobby() then return false end
            if isInRealMatch() then return true end
            local ok, r = pcall(function()
                local SingleTrainTool = require("GameLua.Mod.SingleTraining.GamePlay.Data.SingleTrainTool")
                return SingleTrainTool.IsSelfInTraining and SingleTrainTool.IsSelfInTraining()
            end)
            if ok and r then return true end
            local char = getLocalChar()
            return char and slua.isValid(char) and slua.isValid(char.CharacterAvatarComp2_BP)
        end

        local function getPlayerController()
            local ok, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
            if ok and GD and GD.GetPlayerController then
                local pc = GD.GetPlayerController()
                if pc and slua.isValid(pc) then return pc end
            end
            local pc = nil
            pcall(function()
                if slua_GameFrontendHUD and slua_GameFrontendHUD.GetPlayerController then
                    pc = slua_GameFrontendHUD:GetPlayerController()
                end
            end)
            return pc and slua.isValid(pc) and pc or nil
        end

        function getLocalChar()
    -- ★ USE CACHED MODULE (_MOD_GD) instead of requiring every time
    if _MOD_GD and _MOD_GD.GetPlayerCharacter then
        local char = _MOD_GD.GetPlayerCharacter()
        if char and slua.isValid(char) then return char end
    end
    
    -- Fallback if cache failed initially
    local pc = getPlayerController() 
    if pc then
        local char = nil
        pcall(function()
            if pc.GetPlayerCharacterSafety then char = pc:GetPlayerCharacterSafety() end
            if (not char or not slua.isValid(char)) and pc.GetPawn then char = pc:GetPawn() end
            if (not char or not slua.isValid(char)) and pc.K2_GetPawn then char = pc:K2_GetPawn() end
        end)
        if char and slua.isValid(char) then return char end
    end
    return nil
end

        local function notify(msg)
            if not DEBUG or isInMatchOrGame() then return end
            msg = "[AddOutfit] " .. tostring(msg)
            log(msg:gsub("^%[AddOutfit%] ", ""))
            pcall(function()
                if ShowNotice then ShowNotice(msg, false, 10) end
            end)
        end

        local function getDesiredOutfit()
            if MATCH_CONFIG.outfitRes and tonumber(MATCH_CONFIG.outfitRes) > 0 then
                return tonumber(MATCH_CONFIG.outfitRes)
            end
            local cch = cache()
            if tonumber(cch.outfitRes) and cch.outfitRes > 0 then return cch.outfitRes end
            if tonumber(_G.AddOutfitLastLobbyOutfitRes) and _G.AddOutfitLastLobbyOutfitRes > 0 then
                return tonumber(_G.AddOutfitLastLobbyOutfitRes)
            end
            return nil
        end

        local function getWearSlotForResID(resID)
            resID = tonumber(resID)
            if not resID then return nil end
            local itemCfg = cfg(resID)
            if not itemCfg then return 3 end
            local st = tonumber(itemCfg.ItemSubType or itemCfg.itemSubType or 0)
            if st == 401 then return 1 end
            if st == 402 then return 2 end
            if st == 403 then return 3 end
            if st == 404 then return 4 end
            if st == 405 then return 5 end
            if st == 407 then return 6 end
            if st == 400 or st == 408 then return 9 end
            if st == 409 or st == 410 then return 10 end
            if getEquipSkinSlot(resID) then return nil end
            if weaponIdFromSkin(resID) then return nil end
            return 3
        end

        local function makeWearEntry(resID)
            local ENUM = ENUM_AVATAR_DATA_TYPE or { ItemID = 1, ColorID = 2, PatternID = 3 }
            return { [ENUM.ItemID] = resID, [ENUM.ColorID] = 0, [ENUM.PatternID] = 0 }
        end

        local function isApplySuccess(r) return r ~= false end

        local function refreshMatchAvatar(comp)
            if not slua.isValid(comp) then return end
            pcall(function() if comp.ProcessAvatarRectify then comp:ProcessAvatarRectify() end end)
            pcall(function() if comp.OnRep_BodySlotStateChanged then comp:OnRep_BodySlotStateChanged() end end)
            pcall(function() if comp.RefreshAvatarReAttach then comp:RefreshAvatarReAttach() end end)
        end

        local function applyItemToMatchAvatar(comp, resID)
            if not slua.isValid(comp) or not resID or not isInjectedRes(resID) then return false end
            resID = tonumber(resID)
            local applied = false
            pcall(function()
                comp.bSyncAvatar = false
                comp.forceLodMode = true
                comp.bIsLobbyAvatar = false
            end)
            local AvatarData = require("client.logic.data.AvatarData")
            local wearEntry = makeWearEntry(resID)
            local AData = AvatarData.ConvertToAvatarCustom and AvatarData.ConvertToAvatarCustom(wearEntry)
                or AvatarData.CreateAvatarCustom(resID, 0, 0)
            pcall(function()
                if comp.PutOnEquipmentByResID then
                    local r = comp:PutOnEquipmentByResID(AData.ItemID or resID, AData)
                    if isApplySuccess(r) then applied = true end
                end
            end)
            if not applied then
                pcall(function()
                    if comp.PutOnCustomEquipmentByID then
                        local r = comp:PutOnCustomEquipmentByID(resID, AData)
                        if isApplySuccess(r) then applied = true end
                    end
                end)
            end
            if not applied then
                pcall(function()
                    local ItemDefineID = FItemDefineID(4, resID)
                    local EAvatarCustomType = import("EAvatarCustomType")
                    local AvatarCustom = FAvatarCustomDefault()
                    AvatarCustom.CustomType = EAvatarCustomType.AvatarCustomCharacter
                    local r = comp:HandleEquipItem(ItemDefineID, AvatarCustom)
                    if isApplySuccess(r) then applied = true end
                end)
            end
            if applied then refreshMatchAvatar(comp) end
            return applied
        end

        local function applyClothToComp(comp, resID)
            if not slua.isValid(comp) then return false end
            local ok = false
            pcall(function()
                if comp.PutOnCustomEquipmentByID then
                    local r = comp:PutOnCustomEquipmentByID(resID)
                    if isApplySuccess(r) then ok = true end
                end
            end)
            if ok then return true end
            return applyItemToMatchAvatar(comp, resID)
        end

        local function matchApplyOutfit(char)
            syncWeaponCacheFromLobby()
            syncClothesCacheFromLobby()
            local comp = char.CharacterAvatarComp2_BP
            if not slua.isValid(comp) then return false end

            local outfitRes = getDesiredOutfit()
            local applied = false

            if outfitRes and isFullSuitRes(outfitRes) then
                pcall(function()
                    local r = comp:PutOnCustomEquipmentByID(outfitRes)
                    if isApplySuccess(r) then applied = true end
                end)
                if not applied then
                    pcall(function()
                        local r = comp:HandleEquipItem(FItemDefineID(4, outfitRes), FAvatarCustomDefault())
                        if isApplySuccess(r) then applied = true end
                    end)
                end
                if applied then notify("بدلة OK " .. outfitRes) end
                -- تطبيق الإكسسوارات (ماسك/نظارة/طاقية) فوق البدلة الكاملة
                for resID in pairs(collectAllClothResIDs()) do
                    if resID ~= outfitRes and not isFullSuitRes(resID)
                        and not isBodyClothSubType(subType(cfg(resID)))
                        and applyClothToComp(comp, resID) then
                        applied = true
                        notify("إكسسوار OK " .. resID)
                    end
                end
            else
                for resID in pairs(collectAllClothResIDs()) do
                    if not isFullSuitRes(resID) and applyClothToComp(comp, resID) then
                        applied = true
                        notify("ملابس OK " .. resID)
                    end
                end
            end
            return applied
        end

        local _lastPatchTime = 0
local function patchPlayerInfoForMatch(PlayerInfo)
    if not PlayerInfo then return end
    local now = 0
    pcall(function() now = os.clock() end)
    if (now - _lastPatchTime) < 3.0 then return end  -- ★ 1s → 3s
    _lastPatchTime = now
    -- ★ snapshotLobbyWear() HATA DIYA — yehi match 1s stutter ka source tha
    local cch = cache()
            if cch.equip.bag then PlayerInfo.bag_skin = cch.equip.bag end
            if cch.equip.helmet then PlayerInfo.helmet_skin = cch.equip.helmet end
            if cch.equip.armor then PlayerInfo.armor_skin = cch.equip.armor end

            local idx = tonumber(PlayerInfo.use_rolewear) or 1
            PlayerInfo.use_rolewear = idx
            PlayerInfo.all_knapsack_ext_info = PlayerInfo.all_knapsack_ext_info or {}
            PlayerInfo.all_knapsack_ext_info[idx] = PlayerInfo.all_knapsack_ext_info[idx] or {}
            local ext = PlayerInfo.all_knapsack_ext_info[idx]
            if cch.equip.bag then
                local catalogBag = normalizeEquipCatalogRes(cch.equip.bag)
                local bagLists = buildEquipSkinLists(catalogBag)
                ext.bag_skin = catalogBag
                ext.bag_skin_list = bagLists
                PlayerInfo.bag_skin = catalogBag
            end
            if cch.equip.helmet then
                local catalogHelm = normalizeEquipCatalogRes(cch.equip.helmet)
                local helmLists = buildEquipSkinLists(catalogHelm)
                ext.helmet_skin = catalogHelm
                ext.helmet_skin_list = helmLists
                PlayerInfo.helmet_skin = catalogHelm
            end
            if cch.equip.armor then ext.armor_skin = cch.equip.armor end
            if cch.equip.parachute and cch.equip.parachute > 0 then
                ext.parachute = cch.equip.parachuteIns or cch.equip.parachute
            end
            if cch.equip.glider and cch.equip.glider > 0 then
                ext.gliding = cch.equip.glider
            end

            pcall(function()
                if cch.throwObjects then
                    local throwList = {}
                    for st, info in pairs(cch.throwObjects) do
                        if info.resID and info.resID > 0 and _K.THROW_SUB[st] then
                            throwList[st] = info.resID
                        end
                    end
                    if next(throwList) then
                        local function applyThrowList(kext)
                            if not kext then return end
                            kext.throw_object_list = kext.throw_object_list or {}
                            for st, resID in pairs(throwList) do
                                kext.throw_object_list[st] = resID
                            end
                        end
                        applyThrowList(ext)
                        applyThrowList(PlayerInfo.knapsack_ext_info)
                        PlayerInfo.all_knapsack_ext_info = PlayerInfo.all_knapsack_ext_info or {}
                        for i = 1, 6 do
                            PlayerInfo.all_knapsack_ext_info[i] = PlayerInfo.all_knapsack_ext_info[i] or {}
                            applyThrowList(PlayerInfo.all_knapsack_ext_info[i])
                        end
                        for i, kext in pairs(PlayerInfo.all_knapsack_ext_info) do
                            applyThrowList(kext)
                        end
                        log("patchPlayerInfoForMatch: throw_object_list injected into all knapsack entries")
                    end
                end
            end)

            pcall(function()
                if DataMgr and DataMgr.VehicleSlotList then
                    PlayerInfo.vst_in_battle = PlayerInfo.vst_in_battle or {}
                    for subType, insList in pairs(DataMgr.VehicleSlotList) do
                        if insList and type(insList) == "table" then
                            local resList = {}
                            for i, insID in ipairs(insList) do
                                insID = tonumber(insID)
                                if insID and insID > 0 then
                                    local resID
                                    if isInjectedIns(insID) then
                                        resID = R.insToRes[insID]
                                    else
                                        local wd = require("client.slua.logic.wardrobe.wardrobe_data")
                                        local d = wd:GetHallDepotItemDataByInsID(insID)
                                        resID = d and tonumber(d.resID)
                                    end
                                    if resID and resID > 0 then
                                        resList[#resList + 1] = resID
                                    end
                                end
                            end
                            if #resList > 0 then
                                PlayerInfo.vst_in_battle[subType] = resList
                            end
                        end
                    end
                    if DataMgr.vst_skin then
                        local skinIns = tonumber(DataMgr.vst_skin)
                        if skinIns and skinIns > 0 then
                            local skinRes
                            if isInjectedIns(skinIns) then
                                skinRes = R.insToRes[skinIns]
                            else
                                local wd = require("client.slua.logic.wardrobe.wardrobe_data")
                                local d = wd:GetHallDepotItemDataByInsID(skinIns)
                                skinRes = d and tonumber(d.resID)
                            end
                            if skinRes and skinRes > 0 then
                                PlayerInfo.vst_skin = skinRes
                            end
                        end
                    end
                end
            end)
        end

        local _lastApplyEquipToController = 0
        local function applyMatchEquipAvatarToController()
            local now = 0
            pcall(function() now = os.clock() end)
            if (now - _lastApplyEquipToController) < 0.3 then return false end  -- throttle: max 3x/sec
            _lastApplyEquipToController = now
            local pc = getPlayerController()
            if not pc or not slua.isValid(pc) then return false end
            local cch = cache()
            if not cch.equip.bag and not cch.equip.helmet and not cch.equip.armor and not cch.equip.parachute and not cch.equip.glider then return false end

            local char = getLocalChar()
            local eq = pc.InitialEquipmentAvatar or {}

            -- طبّق سكن الشنطة فقط لو اللاعب لابس شنطة فعلاً
            if cch.equip.bag and cch.equip.bag > 0 and isWearingEquip(char, "bag") then
                local catalogBag = normalizeEquipCatalogRes(cch.equip.bag)
                local bagLists = buildEquipSkinLists(catalogBag)
                eq.BagAvatar = catalogBag
                eq.BagAvatarList = bagLists
                local realBagId = getCharEquipLevel(char, 8) or 0
                local bagLevel
                if realBagId > 0 and isBaseEquipItemId(realBagId) then
                    bagLevel = detectEquipLevelFromBaseId(realBagId, catalogBag)
                elseif realBagId > 0 then
                    bagLevel = detectLevelFromEquipRes(realBagId)
                end
                bagLevel = bagLevel or getEquipDisplayLevel(cch.equip.bag, "bag")
                local bagDisplay = mapEquipSkinRes(catalogBag, bagLevel)
                if bagDisplay > 0 then eq.BagAvatar = bagDisplay end
            else
                eq.BagAvatar = 0
                eq.BagAvatarList = nil
            end
            -- طبّق سكن الخوذة فقط لو اللاعب لابس خوذة فعلاً
            if cch.equip.helmet and cch.equip.helmet > 0 and isWearingEquip(char, "helmet") then
                local catalogHelm = normalizeEquipCatalogRes(cch.equip.helmet)
                local helmLists = buildEquipSkinLists(catalogHelm)
                eq.HelmetAvatar = catalogHelm
                eq.HelmetAvatarList = helmLists
                local realHelmId = getCharEquipLevel(char, 9) or 0
                local helmLevel
                if realHelmId > 0 and isBaseEquipItemId(realHelmId) then
                    helmLevel = detectEquipLevelFromBaseId(realHelmId, catalogHelm)
                elseif realHelmId > 0 then
                    helmLevel = detectLevelFromEquipRes(realHelmId)
                end
                helmLevel = helmLevel or getEquipDisplayLevel(cch.equip.helmet, "helmet")
                local helmDisplay = mapEquipSkinRes(catalogHelm, helmLevel)
                if helmDisplay > 0 then eq.HelmetAvatar = helmDisplay end
            else
                eq.HelmetAvatar = 0
                eq.HelmetAvatarList = nil
            end
            if cch.equip.armor then eq.ArmorAvatar = cch.equip.armor end
            if cch.equip.parachute and cch.equip.parachute > 0 then
                eq.ParachuteAvatar = cch.equip.parachute
            end
            if cch.equip.glider and cch.equip.glider > 0 then
                eq.GliderAvatar = cch.equip.glider
            end

            pc.InitialEquipmentAvatar = eq
            pcall(function()
                if slua.isValid(pc.PlayerState) and pc.PlayerState.MetroPlayerStateAvatarFeature then
                    pc.PlayerState.MetroPlayerStateAvatarFeature.InitialEquipmentAvatar = eq
                end
            end)
            pcall(function()
                local comp = char and char.CharacterAvatarComp2_BP
                if slua.isValid(comp) and comp.GetEquipmentSkinItemID then
                    if cch.equip.helmet and isWearingEquip(char, "helmet") then
                        pcall(function() comp:GetEquipmentSkinItemID(cch.equip.helmet) end)
                    end
                    if cch.equip.bag and isWearingEquip(char, "bag") then
                        pcall(function() comp:GetEquipmentSkinItemID(cch.equip.bag) end)
                    end
                    if cch.equip.parachute and isWearingEquip(char, "parachute") then
                        pcall(function() comp:GetEquipmentSkinItemID(cch.equip.parachute) end)
                    end
                    if cch.equip.glider and cch.equip.glider > 0 then
                        pcall(function() comp:GetEquipmentSkinItemID(cch.equip.glider) end)
                    end
                end
            end)
            pcall(function()
                if pc.OnEquipmentAvatarChange and pc.OnEquipmentAvatarChange.Broadcast then
                    pc.OnEquipmentAvatarChange:Broadcast()
                end
            end)
            notify("معدات: خوذة=" .. tostring(eq.HelmetAvatar) .. " شنطة=" .. tostring(eq.BagAvatar))
            return true
        end

        local function hookEquipMapping()
            pcall(function()
                if DataMgr and not DataMgr._lava_equip_map_hooked then
                    DataMgr._lava_equip_map_hooked = true
                    local orig = DataMgr.GetEquipmentItemIDByResID
                    DataMgr.GetEquipmentItemIDByResID = function(level, itemResID)
                        level, itemResID = tonumber(level) or 3, tonumber(itemResID)
                        local catalogRes = normalizeEquipCatalogRes(itemResID)
                        local r = orig(level, catalogRes)
                        if r and r > 0 then return r end
                        if isInjectedIns(itemResID) then
                            return mapEquipSkinRes(normalizeEquipCatalogRes(R.insToRes[itemResID]), level)
                        end
                        if isInjectedRes(itemResID) then
                            return mapEquipSkinRes(catalogRes, level)
                        end
                        return r or 0
                    end
                end
            end)
            pcall(function()
                local lav = require("client.slua.logic.wardrobe.logic_wardrobe_avatar")
                if lav._lava_skinins_hooked then return end
                lav._lava_skinins_hooked = true
                local orig2 = lav.GetEquipmentItemIDBySkinInsID
                lav.GetEquipmentItemIDBySkinInsID = function(self, itemSubType, itemInsID)
                    local level = lav.GetEquipmentItemShowLevel(lav, itemSubType)
                    local r = orig2(self, itemSubType, itemInsID)
                    if r and r > 0 then return r end
                    itemInsID = tonumber(itemInsID)
                    if isInjectedIns(itemInsID) then
                        return mapEquipSkinRes(normalizeEquipCatalogRes(R.insToRes[itemInsID]), level)
                    end
                    pcall(function()
                        local wd = require("client.slua.logic.wardrobe.wardrobe_data")
                        local d = wd:GetHallDepotItemDataByInsID(itemInsID)
                        if d and isInjectedRes(d.resID) then
                            return mapEquipSkinRes(normalizeEquipCatalogRes(d.resID), level)
                        end
                    end)
                    return r
                end
            end)
            pcall(function()
                local CAC = require("GameLua.Mod.Library.GamePlay.Avatar.Component.CharacterAvatarComponent")
                if CAC._lava_equip_skin_hooked then return end
                CAC._lava_equip_skin_hooked = true
                local orig3 = CAC.GetEquipmentSkinItemID
                CAC.GetEquipmentSkinItemID = function(self, InItemID)
                    -- Skip non-local player equipment to avoid lag
                    if self.IsSelf and not self:IsSelf() then
                        return orig3(self, InItemID)
                    end
                    local cch = cache()
                    InItemID = tonumber(InItemID) or 0

                    local function tryGetSkin(catalogRes)
                        if not catalogRes or catalogRes <= 0 then return 0 end
                        catalogRes = normalizeEquipCatalogRes(catalogRes)
                        local skin = resolveMatchEquipSkin(catalogRes, InItemID)
                        if skin > 0 then return skin end
                        for lvl = 1, 3 do
                            local s = mapEquipSkinRes(catalogRes, lvl)
                            if s > 0 then return s end
                        end
                        return 0
                    end

                    if InItemID > 0 and isBaseEquipItemId(InItemID) then
                        local isHelmetBase = GAME_HELMET_LEVEL[InItemID] ~= nil
                            or (InItemID >= 1505000001 and InItemID <= 1505000100)
                            or (InItemID >= 502001 and InItemID <= 502999)
                        local isBagBase = GAME_BAG_LEVEL[InItemID] ~= nil
                            or (InItemID >= 501001 and InItemID <= 501999)
                            or (InItemID >= 1501000000 and InItemID < 1502000000)

                        local char = getLocalChar()
                        if isHelmetBase and cch.equip.helmet and cch.equip.helmet > 0 then
                            if char and isWearingEquip(char, "helmet") then
                                local skin = tryGetSkin(cch.equip.helmet)
                                if skin > 0 then return skin end
                            end
                        end
                        if isBagBase and cch.equip.bag and cch.equip.bag > 0 then
                            if char and isWearingEquip(char, "bag") then
                                local skin = tryGetSkin(cch.equip.bag)
                                if skin > 0 then return skin end
                            end
                        end
                    end

                    local origResult = orig3(self, InItemID)
                    if origResult and origResult > 0 and origResult ~= InItemID then
                        return origResult
                    end

                    -- fallback مع تحقق isWearingEquip
                    local isHelmetQuery = GAME_HELMET_LEVEL[InItemID] ~= nil or (InItemID >= 502001 and InItemID <= 502999)
                    local isBagQuery = GAME_BAG_LEVEL[InItemID] ~= nil or (InItemID >= 501001 and InItemID <= 501999)
                    local char = getLocalChar()

                    if isHelmetQuery and cch.equip.helmet and cch.equip.helmet > 0 then
                        if char and isWearingEquip(char, "helmet") then
                            local skin = tryGetSkin(cch.equip.helmet)
                            if skin > 0 then return skin end
                        end
                    end
                    if isBagQuery and cch.equip.bag and cch.equip.bag > 0 then
                        if char and isWearingEquip(char, "bag") then
                            local skin = tryGetSkin(cch.equip.bag)
                            if skin > 0 then return skin end
                        end
                    end
                    return origResult
                end
                local origEquipFinish = CAC.OnAvatarEquipFinish
                CAC.OnAvatarEquipFinish = function(self, slotType, isEquipped, itemID)
                    if origEquipFinish then origEquipFinish(self, slotType, isEquipped, itemID) end
                    if not isEquipped then return end
                    -- Only process local player equipment to avoid lag
                    if not self.IsSelf or not self:IsSelf() then return end
                    pcall(function()
                        if self.IsLobbyActor and self:IsLobbyActor() then return end
                        local EAvatarSlotType = import("EAvatarSlotType")
                        local cch = cache()
                        local isHelmet = slotType == EAvatarSlotType.EAvatarSlotType_HelmetEquipemtSlot
                        local isBag = slotType == EAvatarSlotType.EAvatarSlotType_BackpackEquipemtSlot
                        if (isHelmet and cch.equip.helmet and cch.equip.helmet > 0)
                            or (isBag and cch.equip.bag and cch.equip.bag > 0) then
                            local owner = self.GetOwner and self:GetOwner()
                            if owner and slua.isValid(owner) and owner.AddGameTimer then
                                owner:AddGameTimer(0.25, false, function()
                                    if slua.isValid(owner) then matchApplyEquipSkins(owner) end
                                end)
                            end
                        end
                        applyMatchEquipAvatarToController()
                    end)
                end
            end)
        end

        local function applyMatchEquipSkinAtLevel(comp, catalogResID, level)
            if not slua.isValid(comp) or not catalogResID or catalogResID <= 0 then return false end
            catalogResID = normalizeEquipCatalogRes(catalogResID)
            level = tonumber(level) or 3
            local skinId = mapEquipSkinRes(catalogResID, level)
            if not skinId or skinId <= 0 then skinId = catalogResID end
            local ok = false
            pcall(function()
                if comp.PutOnCustomEquipmentByID then
                    local r = comp:PutOnCustomEquipmentByID(skinId)
                    if isApplySuccess(r) then ok = true end
                end
            end)
            if not ok then
                pcall(function()
                    local r = comp:HandleEquipItem(FItemDefineID(4, skinId), FAvatarCustomDefault())
                    if isApplySuccess(r) then ok = true end
                end)
            end
            if ok then refreshMatchAvatar(comp) end
            return ok
        end

            -- أضف الدالة دي قبل matchApplyEquipSkins
        local function getCharEquipLevel(char, slotID)
            local found = nil
            pcall(function()
                local comp = char and char.CharacterAvatarComp2_BP
                if not slua.isValid(comp) then return end
                local NetAvatarData = slua.IndexReference(comp, "NetAvatarData")
                if not NetAvatarData then return end
                local TempSlotSyncData = slua.IndexReference(NetAvatarData, "SlotSyncData")
                if not TempSlotSyncData then return end
                for Index, AvatarSynData in pairs(TempSlotSyncData) do
                    if AvatarSynData.SlotID == slotID and AvatarSynData.ItemID and AvatarSynData.ItemID > 0 then
                        found = AvatarSynData.ItemID
                        return
                    end
                end
            end)
            return found
        end

        local function isWearingEquip(char, slot)
            local slotID = (slot == "helmet") and 9 or (slot == "bag") and 8 or (slot == "parachute") and 11 or (slot == "glider") and 15 or nil
            if not slotID then return false end

            -- 1) تحقق من SlotSyncData بنفس طريقة pairs الشغالة
            local itemID = getCharEquipLevel(char, slotID)
            if itemID and itemID > 0 then return true end

            -- 2) تحقق من PlayerState EquipmentAvatarData
            local wearing = false
            pcall(function()
                local pc = getPlayerController()
                if not pc or not slua.isValid(pc) then return end
                if pc.PlayerState and pc.PlayerState.MetroPlayerStateAvatarFeature then
                    local psEquip = pc.PlayerState.MetroPlayerStateAvatarFeature.EquipmentAvatarData
                    if psEquip then
                        if slot == "helmet" and psEquip.HelmetAvatar and psEquip.HelmetAvatar > 0 then
                            wearing = true
                        elseif slot == "bag" and psEquip.BagAvatar and psEquip.BagAvatar > 0 then
                            wearing = true
                        end
                    end
                end
            end)
            return wearing
        end

        local _lastMatchApplyEquip = 0
        local function matchApplyEquipSkins(char)
            local now = 0
            pcall(function() now = os.clock() end)
            if (now - _lastMatchApplyEquip) < 0.5 then return false end  -- throttle: max 2x/sec
            _lastMatchApplyEquip = now
            local cch = cache()
            if not cch.equip.bag and not cch.equip.helmet and not cch.equip.parachute and not cch.equip.glider then return false end
            local comp = char and char.CharacterAvatarComp2_BP
            if not slua.isValid(comp) then return false end
            local ok = false

            if cch.equip.helmet and cch.equip.helmet > 0 then
                if isWearingEquip(char, "helmet") then
                    local catalogHelm = normalizeEquipCatalogRes(cch.equip.helmet)
                    local realHelmId = getCharEquipLevel(char, 9) or 0
                    local helmLevel
                    if realHelmId > 0 and isBaseEquipItemId(realHelmId) then
                        helmLevel = detectEquipLevelFromBaseId(realHelmId, catalogHelm)
                    elseif realHelmId > 0 then
                        helmLevel = detectLevelFromEquipRes(realHelmId)
                    end
                    helmLevel = helmLevel or getEquipDisplayLevel(cch.equip.helmet, "helmet")
                    if applyMatchEquipSkinAtLevel(comp, catalogHelm, helmLevel) then
                        ok = true
                        notify("خوذة ماتش OK " .. mapEquipSkinRes(catalogHelm, helmLevel))
                    end
                end
            end

            if cch.equip.bag and cch.equip.bag > 0 then
                if isWearingEquip(char, "bag") then
                    local catalogBag = normalizeEquipCatalogRes(cch.equip.bag)
                    local realBagId = getCharEquipLevel(char, 8) or 0
                    local bagLevel
                    if realBagId > 0 and isBaseEquipItemId(realBagId) then
                        bagLevel = detectEquipLevelFromBaseId(realBagId, catalogBag)
                    elseif realBagId > 0 then
                        bagLevel = detectLevelFromEquipRes(realBagId)
                    end
                    bagLevel = bagLevel or getEquipDisplayLevel(cch.equip.bag, "bag")
                    if applyMatchEquipSkinAtLevel(comp, catalogBag, bagLevel) then
                        ok = true
                        notify("شنطة ماتش OK " .. mapEquipSkinRes(catalogBag, bagLevel))
                    end
                end
            end

            if cch.equip.parachute and cch.equip.parachute > 0 then
                if isWearingEquip(char, "parachute") then
                    local paraResID = cch.equip.parachute
                    pcall(function()
                        if comp.PutOnCustomEquipmentByID then
                            local r = comp:PutOnCustomEquipmentByID(paraResID)
                            if isApplySuccess(r) then
                                ok = true
                                notify("براشوت ماتش OK " .. tostring(paraResID))
                            end
                        end
                    end)
                    if not ok then
                        pcall(function()
                            local r = comp:HandleEquipItem(FItemDefineID(4, paraResID), FAvatarCustomDefault())
                            if isApplySuccess(r) then
                                ok = true
                                notify("براشوت ماتش OK " .. tostring(paraResID))
                            end
                        end)
                    end
                end
            end

            if cch.equip.glider and cch.equip.glider > 0 then
                local gliderResID = cch.equip.glider
                pcall(function()
                    if comp.PutOnCustomEquipmentByID then
                        local r = comp:PutOnCustomEquipmentByID(gliderResID)
                        if isApplySuccess(r) then
                            ok = true
                            notify("جلايدر ماتش OK " .. tostring(gliderResID))
                        end
                    end
                end)
                if not ok then
                    pcall(function()
                        local r = comp:HandleEquipItem(FItemDefineID(4, gliderResID), FAvatarCustomDefault())
                        if isApplySuccess(r) then
                            ok = true
                            notify("جلايدر ماتش OK " .. tostring(gliderResID))
                        end
                    end)
                end
            end

            -- حدّث PlayerController بعد تطبيق السكنات (مش قبل، عشان نتجنب circular dependency)
            applyMatchEquipAvatarToController()

            -- باقي كود SlotSyncData بدون تغيير...
            pcall(function()
                local NetAvatarData = slua.IndexReference(comp, "NetAvatarData")
                if not NetAvatarData then return end
                local TempSlotSyncData = slua.IndexReference(NetAvatarData, "SlotSyncData")
                if not TempSlotSyncData then return end

                for Index, AvatarSynData in pairs(TempSlotSyncData) do
                    local slotID = AvatarSynData.SlotID
                    local NDRid = AvatarSynData.ItemID

                    if slotID == 8 and NDRid ~= 0 and cch.equip.bag and cch.equip.bag > 0 then
                        local catalogBag = normalizeEquipCatalogRes(cch.equip.bag)
                        local bagLevel
                        if isBaseEquipItemId(NDRid) then
                            bagLevel = detectEquipLevelFromBaseId(NDRid, catalogBag)
                        else
                            bagLevel = detectLevelFromEquipRes(NDRid)
                        end
                        bagLevel = bagLevel or getEquipDisplayLevel(cch.equip.bag, "bag")
                        local skinId = mapEquipSkinRes(catalogBag, bagLevel)
                        if skinId <= 0 then skinId = mapEquipSkinRes(catalogBag, 3) end
                        if skinId > 0 and NDRid ~= skinId then
                            AvatarSynData.ItemID = skinId
                            slua.IndexReference(NetAvatarData, "SlotSyncData"):Set(Index, AvatarSynData)
                            ok = true
                        end
                    end

                    if slotID == 9 and NDRid ~= 0 and cch.equip.helmet and cch.equip.helmet > 0 then
                        local catalogHelm = normalizeEquipCatalogRes(cch.equip.helmet)
                        local helmLevel
                        if isBaseEquipItemId(NDRid) then
                            helmLevel = detectEquipLevelFromBaseId(NDRid, catalogHelm)
                        else
                            helmLevel = detectLevelFromEquipRes(NDRid)
                        end
                        helmLevel = helmLevel or getEquipDisplayLevel(cch.equip.helmet, "helmet")
                        local skinId = mapEquipSkinRes(catalogHelm, helmLevel)
                        if skinId <= 0 then skinId = mapEquipSkinRes(catalogHelm, 3) end
                        if skinId > 0 and NDRid ~= skinId then
                            AvatarSynData.ItemID = skinId
                            slua.IndexReference(NetAvatarData, "SlotSyncData"):Set(Index, AvatarSynData)
                            ok = true
                        end
                    end

                    -- براشوت - SlotID 11 (ParachuteEquipemtSlot)
                    if slotID == 11 and NDRid ~= 0 and cch.equip.parachute and cch.equip.parachute > 0 then
                        local paraResID = cch.equip.parachute
                        if NDRid ~= paraResID then
                            AvatarSynData.ItemID = paraResID
                            slua.IndexReference(NetAvatarData, "SlotSyncData"):Set(Index, AvatarSynData)
                            ok = true
                        end
                    end

                    -- جلايدر - SlotID 15 (GlideEquipmtSlot)
                    if slotID == 15 and NDRid ~= 0 and cch.equip.glider and cch.equip.glider > 0 then
                        local gliderResID = cch.equip.glider
                        if NDRid ~= gliderResID then
                            AvatarSynData.ItemID = gliderResID
                            slua.IndexReference(NetAvatarData, "SlotSyncData"):Set(Index, AvatarSynData)
                            ok = true
                        end
                    end
                end

                if ok and comp.OnRep_BodySlotStateChanged then
                    comp:OnRep_BodySlotStateChanged()
                end
            end)
            return ok
        end

        local function hookPlayerWearingDone()
            pcall(function()
                local pc = getPlayerController()
                if not pc or not slua.isValid(pc) or pc._lava_wear_done_hooked then return end
                pc._lava_wear_done_hooked = true
                if pc.OnPlayerChangeWearingDone and pc.OnPlayerChangeWearingDone.Add then
                    pc.OnPlayerChangeWearingDone:Add(function()
                        applyMatchEquipAvatarToController()
                        local char = getLocalChar()
                        if char then
                            char:AddGameTimer(0.2, false, function()
                                if slua.isValid(char) then matchApplyEquipSkins(char) end
                            end)
                        end
                    end)
                end
            end)
        end

        local function hookCommerAvatarData()
            pcall(function()
                local CommerAvatarDataUtil = require("GameLua.Activity.Commercialize.GamePlay.CommerAvatarDataUtil")
                if CommerAvatarDataUtil._lava_hooked_equip then return end
                CommerAvatarDataUtil._lava_hooked_equip = true
                local orig = CommerAvatarDataUtil.GeneratePlayerAvatarData
                CommerAvatarDataUtil.GeneratePlayerAvatarData = function(self, PlayerInfo, uPlayerController, ...)
                    -- Skip expensive operations for non-local players
                    local localPC = getPlayerController()
                    if uPlayerController and slua.isValid(uPlayerController) and uPlayerController == localPC then
                        pcall(function() patchPlayerInfoForMatch(PlayerInfo) end)
                    end
                    orig(self, PlayerInfo, uPlayerController, ...)
                    if uPlayerController and slua.isValid(uPlayerController) and uPlayerController == localPC then
                        applyMatchEquipAvatarToController()
                    end
                end
            end)
        end

        local function hookMatchAvatarData()
            hookCommerAvatarData()
            pcall(function()
                local AvatarDataUtil = require("GameLua.Mod.Library.GamePlay.Avatar.AvatarDataUtil")
                if AvatarDataUtil._lava_hooked_gen then return end
                AvatarDataUtil._lava_hooked_gen = true
                local origGet = AvatarDataUtil.GetPlayerInfo
                AvatarDataUtil.GetPlayerInfo = function(uPlayerController)
                    local pi = origGet(uPlayerController)
                    -- Only patch for local player to avoid lag when enemies appear
                    local localPC = getPlayerController()
                    if pi and uPlayerController and slua.isValid(uPlayerController) and uPlayerController == localPC then
                        patchPlayerInfoForMatch(pi)
                    end
                    return pi
                end
                local origGen = AvatarDataUtil.GeneratePlayerAvatarData
                AvatarDataUtil.GeneratePlayerAvatarData = function(uPlayerController)
                    -- Only patch for local player to avoid lag when enemies appear
                    local localPC = getPlayerController()
                    if uPlayerController and slua.isValid(uPlayerController) and uPlayerController == localPC then
                        pcall(function()
                            local PlayerInfo = AvatarDataUtil.GetPlayerInfo(uPlayerController)
                            if PlayerInfo then patchPlayerInfoForMatch(PlayerInfo) end
                        end)
                    end
                    origGen(uPlayerController)
                    if uPlayerController and slua.isValid(uPlayerController) and uPlayerController == localPC then
                        applyMatchEquipAvatarToController()
                    end
                    return
                end
                local origInit = AvatarDataUtil.InitialEquipmentAvatar
                AvatarDataUtil.InitialEquipmentAvatar = function(PlayerInfo, uPlayerController)
                    -- Only patch for local player to avoid lag when enemies appear
                    local localPC = getPlayerController()
                    if uPlayerController and slua.isValid(uPlayerController) and uPlayerController == localPC then
                        pcall(function() patchPlayerInfoForMatch(PlayerInfo) end)
                    end
                    origInit(PlayerInfo, uPlayerController)
                    if uPlayerController and slua.isValid(uPlayerController) and uPlayerController == localPC then
                        applyMatchEquipAvatarToController()
                    end
                end
            end)
        end

        local function hookClassMethod(classModule, methodName, hookTag, newFunc)
            if not classModule then log("hookClassMethod: nil classModule for", methodName) return false end
            local impl = classModule.__inner_impl
            if not impl then log("hookClassMethod: no __inner_impl for", methodName) return false end
            if impl[hookTag] then log("hookClassMethod: already hooked", methodName) return false end
            local orig = impl[methodName]
            if not orig then log("hookClassMethod: no orig method", methodName) return false end
            impl[hookTag] = true
            impl[methodName] = function(...)
                return newFunc(orig, ...)
            end
            pcall(function() rawset(classModule, methodName, nil) end)
            -- log("hookClassMethod: hooked", methodName)
            return true
        end

        local function hookGrenadeAvatarInit()
            pcall(function()
                local PCB = require("GameLua.GameCore.Framework.PlayerControllerBase")
                -- log suppressed
                hookClassMethod(PCB, "InitGrenadeAvatarList", "_lava_hooked_grenade_init", function(orig, self, ReInitial)
                    orig(self, ReInitial)
                    -- Only inject for local player to avoid lag when enemies appear
                    local localPC = getPlayerController()
                    if not localPC or self ~= localPC then return end
                    if ReInitial then
                        pcall(function()
                            local cch = cache()
                            if cch.throwObjects and self.AddToGrenadeAvatarItemList then
                                for st, info in pairs(cch.throwObjects) do
                                    if info.resID and info.resID > 0 and _K.THROW_SUB[st] then
                                        self:AddToGrenadeAvatarItemList(info.resID)
                                    end
                                end
                            end
                        end)
                    end
                end)
            end)
        end

        local function applyGrenadeSkinsToController()
            local pc = getPlayerController()
            if not pc or not slua.isValid(pc) then return false end
            local cch = cache()
            if not cch.throwObjects then return false end
            local hasThrow = false
            for _, info in pairs(cch.throwObjects) do
                if info.resID and info.resID > 0 then hasThrow = true break end
            end
            if not hasThrow then return false end
            pcall(function()
                if pc.AddToGrenadeAvatarItemList then
                    for st, info in pairs(cch.throwObjects) do
                        if info.resID and info.resID > 0 and _K.THROW_SUB[st] then
                            pc:AddToGrenadeAvatarItemList(info.resID)
                        end
                    end
                end
                if pc.OnWeaponAvatarUpdate then
                    pc:OnWeaponAvatarUpdate()
                end
                local char = getLocalChar()
                if char and slua.isValid(char) then
                    local curWeapon = char.GetCurrentWeapon and char:GetCurrentWeapon()
                    if slua.isValid(curWeapon) then
                        local wid = 0
                        pcall(function() wid = curWeapon:GetWeaponID() end)
                        if wid >= 602001 and wid <= 602004 then
                            log("applyGrenadeSkinsToController: held grenade wid=", wid)
                            if curWeapon.DelayHandleAvatarMeshChanged then
                                curWeapon:DelayHandleAvatarMeshChanged()
                            end
                            if curWeapon.HandleAvatarMeshChanged then
                                curWeapon:HandleAvatarMeshChanged()
                            end
                            local GRENADE_WID_TO_SUB = {
                                [602001] = 614, [602002] = 613,
                                [602003] = 615, [602004] = 612,
                            }
                            local sub = GRENADE_WID_TO_SUB[wid]
                            local info = sub and cch.throwObjects[sub]
                            if info and info.resID and info.resID > 0 then
                                if slua.isValid(curWeapon.GrenadeAvatarComponent_BP) then
                                    curWeapon.GrenadeAvatarComponent_BP:ChangeItemAvatar(info.resID, false)
                                    log("applyGrenadeSkinsToController: ChangeItemAvatar on held weapon", info.resID)
                                end
                                if curWeapon.AddGameTimer then
                                    curWeapon:AddGameTimer(0.1, false, function()
                                        pcall(function()
                                            if slua.isValid(curWeapon) and slua.isValid(curWeapon.GrenadeAvatarComponent_BP) then
                                                curWeapon.GrenadeAvatarComponent_BP:ChangeItemAvatar(info.resID, false)
                                            end
                                        end)
                                    end)
                                end
                            end
                        end
                    end
                end
            end)
            return true
        end

        -- Simplified: only hook TryGetGrenadeAvatarID (lightweight), 
        -- skip per-grenade-class GetAvatarID hooks (heavy, fire for all players)
        local function hookGrenadeAvatarLookup()
            pcall(function()
                local AvatarDataUtil = require("GameLua.Mod.Library.GamePlay.Avatar.AvatarDataUtil")
                if AvatarDataUtil and not AvatarDataUtil._lava_hooked_try_get then
                    AvatarDataUtil._lava_hooked_try_get = true
                    local origTry = AvatarDataUtil.TryGetGrenadeAvatarID
                    if origTry then
                        AvatarDataUtil.TryGetGrenadeAvatarID = function(uPlayerController, ItemID)
                            local cch = cache()
                            if cch.throwObjects then
                                if ItemID == 602001 and cch.throwObjects[614] and cch.throwObjects[614].resID and cch.throwObjects[614].resID > 0 then
                                    return cch.throwObjects[614].resID
                                elseif ItemID == 602002 and cch.throwObjects[613] and cch.throwObjects[613].resID and cch.throwObjects[613].resID > 0 then
                                    return cch.throwObjects[613].resID
                                elseif ItemID == 602003 and cch.throwObjects[615] and cch.throwObjects[615].resID and cch.throwObjects[615].resID > 0 then
                                    return cch.throwObjects[615].resID
                                elseif ItemID == 602004 and cch.throwObjects[612] and cch.throwObjects[612].resID and cch.throwObjects[612].resID > 0 then
                                    return cch.throwObjects[612].resID
                                end
                            end
                            return origTry(uPlayerController, ItemID)
                        end
                    end
                end
            end)
            -- Per-class GetAvatarID hooks removed (heavy, fire for all player grenades)
            -- Timer-based applyGrenadeSkinsToController handles periodic application
        end

        local GRENADE_ITEMID_TO_SUB = {
            [602001] = 614,
            [602002] = 613,
            [602003] = 615,
            [602004] = 612,
        }

        -- Lightweight version: only hooks UpdateGrenadeAvatar for local grenades
        -- Timer-based applyGrenadeSkinsToController handles periodic application
        local function hookProjectileGrenadeAvatar()
            pcall(function()
                local ProjectileBase = require("GameLua.Mod.BaseMod.GamePlay.Actor.Projectile.ProjectileBase")
                local impl = ProjectileBase and ProjectileBase.__inner_impl
                if not impl or impl._lava_hooked_proj then return end
                impl._lava_hooked_proj = true
                local origUpdate = impl.UpdateGrenadeAvatar
                if origUpdate then
                    impl.UpdateGrenadeAvatar = function(self)
                        -- Only process local player grenades
                        if self.bAuthority then return origUpdate(self) end
                        local cch = cache()
                        if cch.throwObjects and slua.isValid(self.GrenadeAvatarComponent_BP) then
                            local itemID
                            if self.GetItemTypeID then
                                itemID = tonumber(self:GetItemTypeID())
                            elseif self.ItemDefineID then
                                itemID = tonumber(self.ItemDefineID.TypeSpecificID)
                            end
                            local sub = itemID and GRENADE_ITEMID_TO_SUB[itemID]
                            local info = sub and cch.throwObjects[sub]
                            if info and info.resID and info.resID > 0 then
                                pcall(function()
                                    self.GrenadeAvatarComponent_BP:ChangeItemAvatar(info.resID, false)
                                end)
                                return
                            end
                        end
                        return origUpdate(self)
                    end
                end
                -- Skip BeginInitialize and ResetGrenadeAvatar hooks (they fire for every player's grenades)
                -- Timer-based applyGrenadeSkinsToController will re-apply periodically
            end)
        end

        local function applyMatchWeaponSkinsToController()
            local pc = getPlayerController()
            if not pc or not slua.isValid(pc) then return false end
            local skinList = {}
            for _, w in pairs(cache().weapons) do
                if w.resID and w.resID > 0 then skinList[#skinList + 1] = w.resID end
            end
            if #skinList == 0 then return false end
            local ok = false
            pcall(function()
                local CommerAvatarDataUtil = require("GameLua.Activity.Commercialize.GamePlay.CommerAvatarDataUtil")
                CommerAvatarDataUtil:InitWeaponSkinList(pc, skinList, nil, nil)
                if pc.InitWeaponAvatarItems then pc:InitWeaponAvatarItems() end
                if pc.OnWeaponAvatarUpdate then pc:OnWeaponAvatarUpdate() end
                ok = true
            end)
            if ok then notify("سلاح PC: " .. table.concat(skinList, ",")) end
            return ok
        end

        local _weaponTypeIDCache = {}
        local function resolveWeaponTypeID(weaponResID)
            weaponResID = tonumber(weaponResID) or 0
            if weaponResID <= 0 then return 0 end
            if _weaponTypeIDCache[weaponResID] ~= nil then return _weaponTypeIDCache[weaponResID] end
            local found = 0
            pcall(function()
                local wc = CDataTable.GetTableData("WeaponConfig", weaponResID)
                if wc then found = tonumber(wc.WeaponID or wc.WeaponId or wc.weaponID or 0) end
            end)
            if found > 0 then _weaponTypeIDCache[weaponResID] = found; return found end
            pcall(function()
                local ic = CDataTable.GetTableData("Item", weaponResID)
                if ic then found = tonumber(ic.WeaponID or ic.weaponId or 0) end
            end)
            local result = found > 0 and found or weaponResID
            _weaponTypeIDCache[weaponResID] = result
            return result
        end

        local _lastBuildSkinMappings = 0
        local function buildSkinMappings()
            local now = 0
            pcall(function() now = os.clock() end)
            if (now - _lastBuildSkinMappings) < 0.5 then return end  -- throttle: max twice per second
            _lastBuildSkinMappings = now
            syncWeaponCacheFromLobby()
            local m = _G.AddOutfitSkinIdMappings
            for k in pairs(m) do m[k] = nil end
            for wid, w in pairs(cache().weapons) do
                wid = tonumber(wid)
                if wid and w.resID and w.resID > 0 then m[wid] = { tonumber(w.resID) } end
            end
            if MATCH_CONFIG.weaponSkins then
                for weaponKey, skinRes in pairs(MATCH_CONFIG.weaponSkins) do
                    weaponKey, skinRes = tonumber(weaponKey), tonumber(skinRes)
                    if weaponKey and skinRes and skinRes > 0 and not m[weaponKey] then
                        m[weaponKey] = { skinRes }
                    end
                end
            end
        end

        local _skinIdCache = {}
        local _skinIdCacheTick = 0
        local function get_skin_id(currentGunId, maxIt)
            currentGunId, maxIt = tonumber(currentGunId) or 0, tonumber(maxIt) or 0
            if currentGunId <= 0 and maxIt <= 0 then return 0 end
            -- Fast path: prefer using weapon cache directly
            local cch = cache()
            local wid = maxIt > 0 and maxIt or currentGunId
            local w = cch.weapons[wid]
            if w and w.resID and w.resID > 0 then return w.resID end
            -- Try type ID lookup
            local typeId = resolveWeaponTypeID(wid)
            if typeId ~= wid then
                local w2 = cch.weapons[typeId]
                if w2 and w2.resID and w2.resID > 0 then return w2.resID end
            end
            -- Cache with short TTL
            local nowTick = _S.globalFrame or 0
            if (nowTick - _skinIdCacheTick) < 60 then
                local cached = _skinIdCache[wid]
                if cached then return cached end
            end
            buildSkinMappings()
            local m = _G.AddOutfitSkinIdMappings
            local result = nil
            if m[wid] and m[wid][1] then result = tonumber(m[wid][1])
            elseif typeId ~= wid and m[typeId] and m[typeId][1] then result = tonumber(m[typeId][1])
            end
            if result then
                _skinIdCache[wid] = result
                _skinIdCacheTick = nowTick
                return result
            end
            return wid
        end
        _G.get_skin_id = get_skin_id
        _G.skinIdMappings = _G.AddOutfitSkinIdMappings

        -- ========== Attachment Skin System (ported from C++ DumpSkin) ==========
        -- Builds weapon-skin -> attachment-skin maps from ItemUpgradeConfig and
        -- ItemUpgradeUnLockConfig, then applies the correct attachment skins
        -- (scopes, compensators, magazines, grips, stocks) when a weapon skin
        -- is active, so each skin carries its own dedicated attachments.

        local _attachMaps = nil

        local function _nameToString(name)
            if name == nil then return "" end
            if type(name) == "string" then return name end
            if type(name) == "userdata" then
                local s = nil
                pcall(function() if name.ToString then s = name:ToString() end end)
                if s and type(s) == "string" then return s end
                pcall(function() if name.ToWString then s = name:ToWString() end end)
                if s and type(s) == "string" then return s end
            end
            if type(name) == "table" and name.SourceString then
                return name.SourceString
            end
            return tostring(name)
        end

        local _WEAPON_CLASS_SUFFIXES = {
            { keywords = { "kar98", "awm", "m24", "amr", "mosin", "win94", "mk14" },
            suffixes = { "(Snipers)", "(Sniper Rifles)" } },
            { keywords = { "m249", "mg3", "dp-28", "dp28" },
            suffixes = { "(Machine Guns)" } },
            { keywords = { "ump", "p90", "vector", "bizon", "uzi", "thompson",
                        "mp5", "mp5k", "tommy" },
            suffixes = { "(SMG)", "(SMG, Pistols)", "(Rifles, SMG)" } },
            { keywords = { "p1911", "p92", "p18c", "deagle", "r1895", "r45",
                        "skorpion", "g18" },
            suffixes = { "(Pistols)", "(SMG, Pistols)" } },
            { keywords = { "akm", "m762", "scar", "famas", "m16a4", "aug",
                        "groza", "qbz", "m416", "mk47", "g36c", "ace32",
                        "k2", "m4" },
            suffixes = { "(AR)", "(Rifles, SMG)" } },
        }

        local function _classSuffixesFromSkinName(skinName)
            if type(skinName) ~= "string" or skinName == "" then return {} end
            local low = string.lower(skinName)
            for _, entry in ipairs(_WEAPON_CLASS_SUFFIXES) do
                for _, kw in ipairs(entry.keywords) do
                    if string.find(low, kw, 1, true) then return entry.suffixes end
                end
            end
            return {}
        end

        local function buildAttachmentMaps()
            if _attachMaps then return _attachMaps end
            _attachMaps = {
                skinAttachments  = {},  -- weaponSkinId -> { partSkinId1, partSkinId2, ... }
                skinBases        = {},  -- weaponSkinId -> { baseId1, baseId2, ... }
                attachToSkin     = {},  -- partSkinId   -> { weaponSkinId, baseId }
                skinToBaseWeapon = {},  -- weaponSkinId -> baseWeaponID
            }
            if not CDataTable or not CDataTable.GetTable then return _attachMaps end

            -- 1) GroupID -> [PartIds] from ItemUpgradeUnLockConfig
            local groupToParts = {}
            pcall(function()
                local unlockTbl = CDataTable.GetTable("ItemUpgradeUnLockConfig")
                if not unlockTbl then return end
                for _, row in pairs(unlockTbl) do
                    local gid  = tonumber(row.GroupID)
                    local part = tonumber(row.PartId or row.PartID)
                    if gid and part then
                        if not groupToParts[gid] then groupToParts[gid] = {} end
                        groupToParts[gid][#groupToParts[gid] + 1] = part
                    end
                end
            end)

            -- 2) weaponSkinId -> GroupID + skinToBaseWeapon from ItemUpgradeConfig
            local skinToGroup = {}
            pcall(function()
                local upTbl = CDataTable.GetTable("ItemUpgradeConfig")
                if not upTbl then return end
                for _, row in pairs(upTbl) do
                    local gid = tonumber(row.GroupID)
                    local itm = tonumber(row.ItemID)
                    if gid and itm and itm >= 1000000000 then
                        skinToGroup[itm] = gid
                        local baseWeaponID = math.floor(itm / 1000) % 1000000
                        if baseWeaponID >= 100000 and baseWeaponID <= 999999 then
                            _attachMaps.skinToBaseWeapon[itm] = baseWeaponID
                        end
                    end
                end
            end)

            -- 3) Base name -> [ids] index from Item table (vanilla attachments only)
            local baseNameToIds = {}
            local itemTbl = CDataTable.GetTable("Item")
            if itemTbl then
                for k, row in pairs(itemTbl) do
                    local id = tonumber(k) or tonumber(row and row.ItemID)
                    if id and id >= 1000 and id < 10000000 then
                        local nm = row and row.ItemName
                        if type(nm) ~= "string" then nm = _nameToString(nm) end
                        if type(nm) == "string" and nm ~= "" then
                            if not baseNameToIds[nm] then baseNameToIds[nm] = {} end
                            baseNameToIds[nm][#baseNameToIds[nm] + 1] = id
                        end
                    end
                end
            end

            -- 4) For each weapon skin, resolve its attachments' base IDs
            for weaponSkinId, gid in pairs(skinToGroup) do
                local parts = groupToParts[gid]
                if parts and #parts > 0 then
                    local bases = {}
                    local wc = cfg(weaponSkinId)
                    local weaponSkinName = ""
                    if wc then
                        local nm = wc.ItemName
                        if type(nm) ~= "string" then nm = _nameToString(nm) end
                        weaponSkinName = nm or ""
                    end
                    local suffixes = _classSuffixesFromSkinName(weaponSkinName)

                    for _, partId in ipairs(parts) do
                        local baseId = 0
                        local partRow = nil
                        if itemTbl then
                            partRow = itemTbl[partId] or itemTbl[tostring(partId)]
                        end
                        if not partRow and CDataTable.GetTableData then
                            partRow = CDataTable.GetTableData("Item", partId)
                        end
                        if partRow then
                            local nm = partRow.ItemName
                            if type(nm) ~= "string" then nm = _nameToString(nm) end
                            if type(nm) == "string" and nm ~= "" then
                                local list = baseNameToIds[nm]
                                if type(list) == "table" and #list >= 1 then
                                    baseId = list[1]
                                    for _, v in ipairs(list) do
                                        if v < baseId then baseId = v end
                                    end
                                end
                                if baseId == 0 then
                                    for _, suf in ipairs(suffixes) do
                                        local trial = nm .. " " .. suf
                                        local lst = baseNameToIds[trial]
                                        if type(lst) == "table" and #lst >= 1 then
                                            baseId = lst[1]
                                            for _, v in ipairs(lst) do
                                                if v < baseId then baseId = v end
                                            end
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        bases[#bases + 1] = baseId
                        _attachMaps.attachToSkin[partId] = { weaponSkinId, baseId }
                    end
                    _attachMaps.skinAttachments[weaponSkinId] = parts
                    _attachMaps.skinBases[weaponSkinId] = bases
                end
            end

            local nSkins, nAttach = 0, 0
            for _ in pairs(_attachMaps.skinAttachments) do nSkins = nSkins + 1 end
            for _ in pairs(_attachMaps.attachToSkin) do nAttach = nAttach + 1 end
            log("Attachment maps: " .. nSkins .. " skins, " .. nAttach .. " attachments")

            return _attachMaps
        end

        local function applyAttachmentSkins(AttachmentArray, selectedSkinID)
            if not AttachmentArray or not slua.isValid(AttachmentArray) then return false end
            selectedSkinID = tonumber(selectedSkinID) or 0
            if selectedSkinID == 0 then return false end

            local maps = buildAttachmentMaps()
            local attachments = maps.skinAttachments[selectedSkinID]
            local bases = maps.skinBases[selectedSkinID]

            local numSlots = 0
            pcall(function() numSlots = AttachmentArray:Num() end)
            if numSlots <= 0 then return false end

            local changed = false

            -- If selected skin has no attachments in the map, revert any
            -- part-skins found on attachment slots back to their base IDs.
            if not attachments or #attachments == 0 then
                for slotIdx = 0, numSlots - 1 do
                    if slotIdx ~= _K.GUN_MASTER_SYN_SLOT then
                        local slotData = AttachmentArray:Get(slotIdx)
                        if slotData then
                            local curID = 0
                            pcall(function()
                                curID = slua.IndexReference(slotData, "defineID").TypeSpecificID or 0
                            end)
                            curID = tonumber(curID) or 0
                            if curID > 0 then
                                local rIt = maps.attachToSkin[curID]
                                if rIt then
                                    local baseId = rIt[2]
                                    if baseId ~= 0 and baseId ~= curID then
                                        pcall(function()
                                            local defRef = slua.IndexReference(slotData, "defineID")
                                            defRef.TypeSpecificID = baseId
                                            slotData.operationType = 0
                                            AttachmentArray:Set(slotIdx, slotData)
                                        end)
                                        changed = true
                                    end
                                end
                            end
                        end
                    end
                end
                return changed
            end

            -- Build a set of valid attachment skin IDs for this weapon skin
            local validSkinIds = {}
            for _, id in ipairs(attachments) do
                validSkinIds[tonumber(id) or 0] = true
            end

            -- Normal case: for each attachment slot, find the matching
            -- attachment skin by baseId and swap to the selected skin's version.
            for slotIdx = 0, numSlots - 1 do
                if slotIdx ~= _K.GUN_MASTER_SYN_SLOT then
                    local slotData = AttachmentArray:Get(slotIdx)
                    if slotData then
                        local curID = 0
                        pcall(function()
                            curID = slua.IndexReference(slotData, "defineID").TypeSpecificID or 0
                        end)
                        curID = tonumber(curID) or 0
                        if curID > 0 then
                            -- Protection: if current attachment is already the correct skin, skip
                            if validSkinIds[curID] then
                                -- Already the correct skinned attachment, don't change
                            else
                                local baseId = 0
                                local rIt = maps.attachToSkin[curID]
                                if rIt then
                                    baseId = rIt[2]
                                elseif curID < 10000000 then
                                    baseId = curID
                                else
                                    -- Unknown skinned attachment from different skin, skip
                                    baseId = 0
                                end
                                if baseId ~= 0 then
                                    local srcIdx = 0
                                    for k, b in ipairs(bases) do
                                        if b ~= 0 and b == baseId then
                                            local candidate = tonumber(attachments[k]) or 0
                                            if candidate ~= 0 and candidate ~= curID then
                                                srcIdx = k
                                                break
                                            end
                                        end
                                    end
                                    if srcIdx > 0 and srcIdx <= #attachments then
                                        local newID = tonumber(attachments[srcIdx]) or 0
                                        if newID ~= 0 and newID ~= curID then
                                            pcall(function()
                                                local defRef = slua.IndexReference(slotData, "defineID")
                                                defRef.TypeSpecificID = newID
                                                slotData.operationType = 0
                                                AttachmentArray:Set(slotIdx, slotData)
                                            end)
                                            changed = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            return changed
        end

        local function applySkinToWeaponRef(CurWeapon)
            if not slua.isValid(CurWeapon) then return false end
            local AttachmentArray = CurWeapon.synData
            if not AttachmentArray or not slua.isValid(AttachmentArray) then return false end

            -- slot 7 فقط = بتاع السكن. باقي الـ slots فيها القطع (attachments)
            -- تعديل أي slot تاني بيخلي السلاح يعمل reload وتختفي القطع
            local AttachmentData = AttachmentArray:Get(_K.GUN_MASTER_SYN_SLOT)
            if not AttachmentData then return false end

            local current_gunid = 0
            pcall(function()
                current_gunid = slua.IndexReference(AttachmentData, "defineID").TypeSpecificID or 0
            end)
            current_gunid = tonumber(current_gunid) or 0
            if current_gunid <= 0 then return false end

            local MaxIt = 0
            pcall(function()
                if CurWeapon.GetWeaponID then MaxIt = CurWeapon:GetWeaponID() end
                if MaxIt <= 0 then MaxIt = CurWeapon:GetItemDefineID().TypeSpecificID end
            end)
            MaxIt = tonumber(MaxIt) or 0
            if MaxIt <= 0 then return false end

            local tmp_id = get_skin_id(current_gunid, MaxIt)
            tmp_id = tonumber(tmp_id) or 0
            if tmp_id <= 0 then return false end

            -- فحص الحالة الفعلية: لو السكن الحالي مطابق للمطلوب، لا شيء
            -- هذا يمنع التكرار بدون استخدام guard معتمد على حالة مخزنة
            if tmp_id == current_gunid and not isInjectedRes(tmp_id) then
                local ok, attChanged = pcall(applyAttachmentSkins, AttachmentArray, tmp_id)
                if ok and attChanged then
                    pcall(function()
                        local char = getLocalChar()
                        if char and char.AddGameTimer then
                            for _, delay in ipairs({0.3, 0.6, 1.0}) do
                                char:AddGameTimer(delay, false, function()
                                    if slua.isValid(CurWeapon) then
                                        local aa = CurWeapon.synData
                                        if aa and slua.isValid(aa) then
                                            pcall(applyAttachmentSkins, aa, tmp_id)
                                        end
                                    end
                                end)
                            end
                        end
                    end)
                end
                return false
            end
            if tmp_id == _S.lastAppliedSkinID and MaxIt == _S.lastAppliedWeaponID then
                local ok, attChanged = pcall(applyAttachmentSkins, AttachmentArray, tmp_id)
                if ok and attChanged then
                    pcall(function()
                        local char = getLocalChar()
                        if char and char.AddGameTimer then
                            for _, delay in ipairs({0.3, 0.6, 1.0}) do
                                char:AddGameTimer(delay, false, function()
                                    if slua.isValid(CurWeapon) then
                                        local aa = CurWeapon.synData
                                        if aa and slua.isValid(aa) then
                                            pcall(applyAttachmentSkins, aa, tmp_id)
                                        end
                                    end
                                end)
                            end
                        end
                    end)
                end
                return true
            end

            _G.AddOutfitLastAppliedSkin[current_gunid] = tmp_id
            pcall(function()
                local defRef = slua.IndexReference(AttachmentData, "defineID")
                defRef.TypeSpecificID = tmp_id
                local c0 = cfg(tmp_id)
                if c0 and c0.ItemType and defRef.Type ~= nil then defRef.Type = c0.ItemType end
                AttachmentData.operationType = 0
                AttachmentArray:Set(_K.GUN_MASTER_SYN_SLOT, AttachmentData)
            end)
            pcall(applyAttachmentSkins, AttachmentArray, tmp_id)
            if CurWeapon.DelayHandleAvatarMeshChanged then CurWeapon:DelayHandleAvatarMeshChanged() end
            -- Delayed re-application of attachment skins to ensure attachments
            -- are updated after the weapon finishes loading its default attachments.
            -- This fixes the issue where attachments don't update until you swap them.
            -- ★ SINGLE DEFERRED APPLY WITH GUARD
if not _G._weaponSkinPending then
    _G._weaponSkinPending = true
    local char = getLocalChar()
    if char and char.AddGameTimer then
        char:AddGameTimer(0.5, false, function() -- Just one wait
            _G._weaponSkinPending = false
            if slua.isValid(CurWeapon) then
                local aa = CurWeapon.synData
                if aa and slua.isValid(aa) then
                    -- Check if already applied to avoid redundant work
                    if not aa._trx_skin_applied_flag then
                         pcall(applyAttachmentSkins, aa, tmp_id)
                         aa._trx_skin_applied_flag = true
                         -- Reset flag next frame via quick timer
                         char:AddGameTimer(0.1, false, function()
                             if slua.isValid(aa) then aa._trx_skin_applied_flag = nil end
                         end)
                    end
                end
            end
        end)
    end
end
            _S.weaponHookGuardUntil = _S.globalFrame + 45
            _G.AddOutfitLastAppliedSkin[MaxIt] = tmp_id
            _S.lastAppliedWeaponID = MaxIt
            _S.lastAppliedSkinID = tmp_id
            return true
        end

        function _G.equip_weapon_avatar(uCharacter)
            if not uCharacter or not slua.isValid(uCharacter) then return false end
            buildSkinMappings()
            local WeaponManager = uCharacter:GetWeaponManager()
            if not WeaponManager or not slua.isValid(WeaponManager) then return false end
            local uWeaponList = WeaponManager:GetAllInventoryWeaponList(false)
            if not uWeaponList or not slua.isValid(uWeaponList) then return false end
            local appliedAny = false
            for i = 0, uWeaponList:Num() - 1 do
                local CurWeapon = uWeaponList:Get(i)
                if slua.isValid(CurWeapon) and applySkinToWeaponRef(CurWeapon) then
                    appliedAny = true
                end
            end
            return appliedAny
        end

        local function getDesiredWeaponSkins()
            syncWeaponCacheFromLobby()
            local out, seen = {}, {}
            local function add(res)
                res = tonumber(res)
                if res and res > 0 and not seen[res] then seen[res] = true; out[#out + 1] = res end
            end
            for _, w in pairs(cache().weapons) do add(w.resID) end
            if MATCH_CONFIG.weaponSkins then
                for _, res in pairs(MATCH_CONFIG.weaponSkins) do add(res) end
            end
            return out
        end

        local function registerWeaponAvatarItems(char)
            local pc = char.GetPlayerControllerSafety and char:GetPlayerControllerSafety()
            if not slua.isValid(pc) then return false end
            local BU = import("BackpackUtils")
            local AU = import("AvatarUtils")
            local addedCount = 0
            for _, resID in ipairs(getDesiredWeaponSkins()) do
                local doneDirect = false
                pcall(function()
                    if pc.AddWeaponAvatarItem then
                        pc:AddWeaponAvatarItem(tonumber(resID))
                        doneDirect = true
                        addedCount = addedCount + 1
                    end
                end)
                if not doneDirect then
                    pcall(function()
                        local skinBPID = BU.GetBPIDByResID(tonumber(resID))
                        local arr = slua.Array(UEnums.EPropertyClass.Int)
                        local parents = AU.GetWeaponAvatarParentIDList(skinBPID, arr, false)
                        if parents and parents.Num and parents:Num() > 0 and pc.WeaponAvatarItemList then
                            for _, parentID in pairs(parents) do
                                pc.WeaponAvatarItemList:Add(parentID, skinBPID)
                            end
                            addedCount = addedCount + 1
                        end
                    end)
                end
            end
            if addedCount == 0 then return false end
            pcall(function() if pc.InitWeaponAvatarItems then pc:InitWeaponAvatarItems() end end)
            pcall(function() if pc.OnWeaponAvatarUpdate then pc:OnWeaponAvatarUpdate() end end)
            notify("سجّلت " .. addedCount .. " سكن سلاح")
            return true
        end

        local _lastMatchApplyWeapon = 0
        local function matchApplyWeaponSkin(char)
            local now = 0
            pcall(function() now = os.clock() end)
            if (now - _lastMatchApplyWeapon) < 0.4 then return false end  -- throttle: max 2.5x/sec
            _lastMatchApplyWeapon = now
            buildSkinMappings()
            applyMatchWeaponSkinsToController()
            if not _S.avatarItemsRegistered then
                _S.avatarItemsRegistered = registerWeaponAvatarItems(char)
            end
            local curWeapon = char.GetCurrentWeapon and char:GetCurrentWeapon()
            if not slua.isValid(curWeapon) then
                return _G.equip_weapon_avatar(char)
            end

            local curWeaponResID = 0
            pcall(function() curWeaponResID = curWeapon:GetItemDefineID().TypeSpecificID end)
            local desiredSkin = get_skin_id(curWeaponResID, curWeaponResID)
            if curWeaponResID == _S.lastAppliedWeaponID and desiredSkin == _S.lastAppliedSkinID then
                pcall(_G.equip_weapon_avatar, char)
                return true
            end

            local ok = applySkinToWeaponRef(curWeapon)
            ok = _G.equip_weapon_avatar(char) or ok
            if ok then
                _S.lastAppliedWeaponID = curWeaponResID
                _S.lastAppliedSkinID = desiredSkin
                _S.weaponApplied = true
                _S.weaponDiagDone = true
                notify("سكن سلاح مطبق: " .. tostring(desiredSkin))
            end
            return ok
        end

        local function applyMatchThrowObjects()
            local pc = getPlayerController()
            if not pc or not slua.isValid(pc) then return false end
            local cch = cache()
            if not cch.throwObjects then
                log("applyMatchThrowObjects: no throwObjects in cache")
                return false
            end
            local hasThrow = false
            for st, info in pairs(cch.throwObjects) do
                if info.resID and info.resID > 0 then hasThrow = true end
            end
            if not hasThrow then
                log("applyMatchThrowObjects: throwObjects cache empty")
                return false
            end
            local applied = false
            pcall(function()
                -- Try setting InitialConsumableAvatar fields (works if Lua table reference)
                if pc.InitialConsumableAvatar then
                    for st, info in pairs(cch.throwObjects) do
                        local key = _K.THROW_AVATAR_KEY[_K.THROW_SUB[st]]
                        if key and info.resID and info.resID > 0 then
                            pc.InitialConsumableAvatar[key] = info.resID
                            -- log suppressed
                        end
                    end
                end
                -- Rebuild grenade avatar list from InitialConsumableAvatar
                if pc.InitGrenadeAvatarList then
                    pc:InitGrenadeAvatarList(false)
                end
                -- Fallback: directly add to GrenadeAvatarItemList (overwrites server entries)
                if pc.AddToGrenadeAvatarItemList then
                    for st, info in pairs(cch.throwObjects) do
                        if info.resID and info.resID > 0 and _K.THROW_SUB[st] then
                            pc:AddToGrenadeAvatarItemList(info.resID)
                            applied = true
                        end
                    end
                end
            end)
            return applied
        end

        local function matchApplyAll(char)
            local ok = false
            if not _S.matchOutfitDone then
                _S.matchOutfitDone = matchApplyOutfit(char)
                ok = _S.matchOutfitDone or ok
            end
            if applyMatchEquipAvatarToController() then ok = true end
            if matchApplyEquipSkins(char) then ok = true; _S.matchApplied = true end
            if matchApplyWeaponSkin(char) then ok = true end
            if applyMatchThrowObjects() then ok = true end
            return ok
        end

        -- تعديل startMatchWatcher لاستخدام محاولات محدودة
        local function startMatchWatcher(char)
            if _S.matchTimer then return end
            _S.matchOutfitDone = false
            _S.avatarItemsRegistered = false
            _S.weaponApplied = false
            _S.weaponDiagDone = false
            _S.lastAppliedWeaponID = 0
            _S.lastAppliedSkinID = 0

            local attempts = 0
            notify("بدأ المراقب في الماتش")

-- ★ ONE-TIME APPLY WITH SINGLE RETRY (No Repeating Timer)
pcall(function()
    local ok, err = pcall(matchApplyAll, char)
    if not ok then
        log("Initial Match Apply Failed: " .. tostring(err))
        -- Retry ONLY once after 2 seconds
        char:AddGameTimer(2.0, false, function()
             if slua.isValid(char) then 
                 pcall(matchApplyAll, char) 
             end
        end)
    end
end)
-- Ensure _S.matchTimer is cleared so no old loops run
_S.matchTimer = nil 
end

        -- ========== حقن سكنات الأسلحة في واجهة الشنطة داخل الجيم ==========
        -- بدل تعديل AdditionalData (اللي مش بيتعدل من Lua)، بنعمل hook على
        -- GetWeaponAvatarRes اللي بترجع السكن للـ backpack UI
        local _hookedGetWeaponAvatarRes = false

        local function hookBackpackWeaponAvatarRes()
            if _hookedGetWeaponAvatarRes then return end
            _hookedGetWeaponAvatarRes = true
            pcall(function()
                local BPL = require("GameLua.Mod.BaseMod.Client.Backpack.BackPackFunctionLibrary")
                if BPL and BPL.GetWeaponAvatarRes and not BPL._lava_hooked_avatar_res then
                    BPL._lava_hooked_avatar_res = true
                    local _bpAvatarResCache = {}
                    local _bpAvatarResTicks = {}
                    local _bpResCacheAge = 0
                    local origGetRes = BPL.GetWeaponAvatarRes
                    BPL.GetWeaponAvatarRes = function(WeaponID, AdditionalDataArray)
                        WeaponID = tonumber(WeaponID) or 0
                        if WeaponID <= 0 then return origGetRes(WeaponID, AdditionalDataArray) end
                        -- Cache with invalidation every ~5 seconds via frame count
                        local cached = _bpAvatarResCache[WeaponID]
                        local age = _bpResCacheAge
                        local nowTick = _S.globalFrame or 0
                        if cached and (nowTick - (_bpAvatarResTicks[WeaponID] or 0)) < 150 then
                            return cached, ""
                        end
                        local targetSkinID = 0
                        -- 1) map directly from cache weapons
                        local cch = cache()
                        local typeId = resolveWeaponTypeID(WeaponID)
                        local w = cch.weapons[typeId] or cch.weapons[WeaponID]
                        if w and w.resID and w.resID > 0 then
                            targetSkinID = w.resID
                        end
                        -- 2) fallback to get_skin_id
                        if targetSkinID <= 0 or targetSkinID == WeaponID then
                            local sid = get_skin_id(WeaponID, WeaponID)
                            targetSkinID = tonumber(sid) or 0
                        end
                        -- Cache result
                        if targetSkinID > 0 and targetSkinID ~= WeaponID then
                            _bpAvatarResCache[WeaponID] = targetSkinID
                            _bpAvatarResTicks[WeaponID] = nowTick
                            local skinCfg = cfg(targetSkinID)
                            if skinCfg then
                                return targetSkinID, ""
                            end
                        end
                        _bpAvatarResCache[WeaponID] = WeaponID
                        _bpAvatarResTicks[WeaponID] = nowTick
                        return origGetRes(WeaponID, AdditionalDataArray)
                    end
                    log("[AddOutfit] hookBackpackWeaponAvatarRes: تم")
                end
            end)
        end

        -- ========== تطبيق سكن السيارة داخل الجيم ==========
        -- مكافئ Lua لكود C++ الذي يطبق سكن السيارة عند ركوب نوع السيارة المطابق
        local _lastVehicleSkinKey = ""

        local function applyVehicleSkinInGame()
            local char = getLocalChar()
            if not char or not slua.isValid(char) then return end

            local vehicle = char.GetCurrentVehicle and char:GetCurrentVehicle()
            if not vehicle or not slua.isValid(vehicle) then
                _lastVehicleSkinKey = ""
                return
            end
            pcall(syncVehicleAvatarSkinList)

            local avatarComp = vehicle.GetAvatarComponent and vehicle:GetAvatarComponent()
            if not avatarComp or not slua.isValid(avatarComp) then return end

            local defaultAvatarID = avatarComp.GetDefaultAvatarID and avatarComp:GetDefaultAvatarID()
            if not defaultAvatarID or defaultAvatarID == 0 then return end

            local currentAvatarID = avatarComp.GetCurrentAvatarID and avatarComp:GetCurrentAvatarID()

            -- تجنب إعادة التطبيق على نفس السيارة بنفس السكن
            local cacheKey = tostring(vehicle) .. "_" .. tostring(defaultAvatarID) .. "_" .. tostring(currentAvatarID)
            if cacheKey == _lastVehicleSkinKey then return end

            -- الحصول على itemSubType للسيارة الحالية من جدول Item
            local vehicleSubType = 0
            local defaultItemCfg = cfg(defaultAvatarID)
            if defaultItemCfg then
                vehicleSubType = tonumber(defaultItemCfg.ItemSubType or defaultItemCfg.itemSubType) or 0
            end

            -- جمع السكنات المطلوبة من VehicleSlotList
            local desiredSkins = {}
            local firstSkinResID = 0
            if vehicleSubType > 0 and DataMgr and DataMgr.VehicleSlotList then
                local slotList = DataMgr.VehicleSlotList[vehicleSubType]
                if slotList then
                    for i = 1, #slotList do
                        local skinInsID = tonumber(slotList[i])
                        if skinInsID and skinInsID > 0 then
                            local skinResID = 0
                            if isInjectedIns(skinInsID) then
                                skinResID = R.insToRes[skinInsID] or 0
                            else
                                pcall(function()
                                    local wd = require("client.slua.logic.wardrobe.wardrobe_data")
                                    local d = wd:GetHallDepotItemDataByInsID(skinInsID)
                                    skinResID = d and tonumber(d.resID) or 0
                                end)
                            end
                            if skinResID > 0 then
                                desiredSkins[skinResID] = true
                                if firstSkinResID == 0 then
                                    firstSkinResID = skinResID
                                end
                            end
                        end
                    end
                end
            end

            -- Fallback: إضافة السكنات من vst_in_battle من PlayerState
            if vehicleSubType > 0 then
                pcall(function()
                    local pc = getPlayerController()
                    if pc and pc.PlayerState then
                        local vst = pc.PlayerState.vst_in_battle
                        if vst and vst[vehicleSubType] then
                            local resList = vst[vehicleSubType]
                            if resList and type(resList) == "table" then
                                for _, resID in ipairs(resList) do
                                    resID = tonumber(resID)
                                    if resID and resID > 0 then
                                        if not desiredSkins[resID] then
                                            desiredSkins[resID] = true
                                            if firstSkinResID == 0 then
                                                firstSkinResID = resID
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            end

            -- Fallback: مطابقة بناءً على بادئة الـ ID
            if firstSkinResID == 0 and DataMgr and DataMgr.VehicleSlotList then
                local defStr = tostring(defaultAvatarID)
                for subType, insList in pairs(DataMgr.VehicleSlotList) do
                    if insList and type(insList) == "table" then
                        for i = 1, #insList do
                            local skinInsID = tonumber(insList[i])
                            if skinInsID and skinInsID > 0 then
                                local rid = 0
                                if isInjectedIns(skinInsID) then
                                    rid = R.insToRes[skinInsID] or 0
                                else
                                    pcall(function()
                                        local wd = require("client.slua.logic.wardrobe.wardrobe_data")
                                        local d = wd:GetHallDepotItemDataByInsID(skinInsID)
                                        rid = d and tonumber(d.resID) or 0
                                    end)
                                end
                                if rid > 0 then
                                    local skinCfg = cfg(rid)
                                    if skinCfg then
                                        local skinDefault = skinCfg.DefaultAvatarID or skinCfg.defaultAvatarID
                                        if skinDefault and tostring(skinDefault):find(defStr, 1, true) then
                                            if not desiredSkins[rid] then
                                                desiredSkins[rid] = true
                                                firstSkinResID = rid
                                            end
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        if firstSkinResID > 0 then break end
                    end
                end
            end

            -- إذا السكن الحالي من السكنات المختارة في السلوتات، لا نفرض تغييره
            if currentAvatarID and desiredSkins[currentAvatarID] then
                _lastVehicleSkinKey = cacheKey
                return
            end

            local skinResID = firstSkinResID

            if skinResID == 0 then
                _lastVehicleSkinKey = cacheKey
                return
            end


            -- تطبيق السكن على السيارة
            pcall(function()
                local pc = getPlayerController()
                if pc and avatarComp.SetVehicleNetAvatarData then
                    avatarComp:SetVehicleNetAvatarData(pc)
                end
                -- تعيين إفكت التبديل (مثل SwitchEffectId = 7303001 في C++)
                if avatarComp.VehicleNetAvatarData then
                    avatarComp.VehicleNetAvatarData.SwitchEffectId = 7303001
                    avatarComp.VehicleNetAvatarData.UpdateFlag = 1
                end
                avatarComp:ChangeItemAvatar(skinResID, true)
                avatarComp.CanChangeAvatar = true
            end)

            -- تشغيل إضاءة LED تحت السيارة (Chassis Light) عند تطبيق السكن
            pcall(applyVehicleChassisLight)

            _lastVehicleSkinKey = cacheKey
        end

        -- ========== إضاءة تحت السيارة (Chassis Light) في الجيم ==========
        local _LAVA_CHASSIS_LIGHT_ID = 7302002

        local function isLocalPlayerVehicle(vehicle)
            if not vehicle or not slua.isValid(vehicle) then return false end
            local char = getLocalChar()
            if not char or not slua.isValid(char) then return false end
            local currentVehicle = char.GetCurrentVehicle and char:GetCurrentVehicle()
            if currentVehicle and currentVehicle == vehicle then return true end
            local driver = nil
            pcall(function() driver = vehicle.GetDriver and vehicle:GetDriver() end)
            if driver and driver == char then return true end
            return false
        end

        local function getVehicleSkinID(vehicle)
            if not vehicle or not slua.isValid(vehicle) then return 0 end
            local skinID = 0
            pcall(function()
                if vehicle.GetVehicleSkinItemID then
                    skinID = vehicle:GetVehicleSkinItemID() or 0
                end
            end)
            if skinID and skinID > 0 then return skinID end
            pcall(function()
                if vehicle.ClientUsedAvatarID then
                    skinID = vehicle.ClientUsedAvatarID
                end
            end)
            if skinID and skinID > 0 then return skinID end
            pcall(function()
                local avatarComp = vehicle.GetAvatarComponent and vehicle:GetAvatarComponent()
                if avatarComp and slua.isValid(avatarComp) and avatarComp.GetCurrentAvatarID then
                    skinID = avatarComp:GetCurrentAvatarID() or 0
                end
            end)
            return skinID or 0
        end

        local function vehicleHasSkinApplied(vehicle)
            if not vehicle or not slua.isValid(vehicle) then return false end
            local skinID = getVehicleSkinID(vehicle)
            if skinID <= 0 then return false end
            local defaultID = 0
            pcall(function()
                local avatarComp = vehicle.GetAvatarComponent and vehicle:GetAvatarComponent()
                if avatarComp and slua.isValid(avatarComp) and avatarComp.GetDefaultAvatarID then
                    defaultID = avatarComp:GetDefaultAvatarID() or 0
                end
            end)
            return skinID ~= defaultID
        end

        local function forceVehicleChassisLight(vehicle)
            if not vehicle or not slua.isValid(vehicle) then return end
            local licenseComp = vehicle.GetLicenseComponent and vehicle:GetLicenseComponent()
            if not licenseComp or not slua.isValid(licenseComp) then
                print("[AddOutfit] forceVehicleChassisLight: no licenseComp")
                return
            end
            if not licenseComp.LicensePlate then
                print("[AddOutfit] forceVehicleChassisLight: no LicensePlate")
                return
            end
            if licenseComp.LicensePlate.ChassisLightId == _LAVA_CHASSIS_LIGHT_ID and slua.isValid(licenseComp.ChassisLightMesh) then
                return
            end
            local skinID = getVehicleSkinID(vehicle)
            if skinID > 0 then
                licenseComp.LicensePlate.ItemID = skinID
            end
            licenseComp.LicensePlate.ChassisLightId = _LAVA_CHASSIS_LIGHT_ID
            if licenseComp.curVehicleAvatarId == nil or licenseComp.curVehicleAvatarId == 0 then
                licenseComp.curVehicleAvatarId = skinID
            end
            print("[AddOutfit] forceVehicleChassisLight: skinID=" .. tostring(skinID) .. " ChassisLightId=" .. tostring(_LAVA_CHASSIS_LIGHT_ID) .. " ItemID=" .. tostring(licenseComp.LicensePlate.ItemID))
            if licenseComp.PreChangeChassisLight then
                pcall(function() licenseComp:PreChangeChassisLight() end)
            end
        end

        local function applyVehicleChassisLight()
            local char = getLocalChar()
            if not char or not slua.isValid(char) then return end
            local vehicle = char.GetCurrentVehicle and char:GetCurrentVehicle()
            if not vehicle or not slua.isValid(vehicle) then return end
            if not isLocalPlayerVehicle(vehicle) then return end
            if not vehicleHasSkinApplied(vehicle) then return end
            forceVehicleChassisLight(vehicle)
        end

        local function hookVehicleLicenseComponentBase()
            local ok, VLB = pcall(require, "GameLua.Activity.Commercialize.Actor.ActorComponent.BP_VehicleLicenseComponentBase")
            if not ok or not VLB then return end
            local impl = VLB.__inner_impl
            if not impl or type(impl) ~= "table" then return end
            if impl._lava_hooked_chassis then return end
            impl._lava_hooked_chassis = true

            local origCheckDownloaded = impl.CheckHasVehicleDownloaded
            impl.CheckHasVehicleDownloaded = function(self, ItemID)
                local vehicle = self:GetOwner()
                if isLocalPlayerVehicle(vehicle) and vehicleHasSkinApplied(vehicle) then
                    return true
                end
                return origCheckDownloaded(self, ItemID)
            end

            local origPreChange = impl.PreChangeChassisLight
            impl.PreChangeChassisLight = function(self)
                pcall(function()
                    local vehicle = self:GetOwner()
                    if isLocalPlayerVehicle(vehicle) and vehicleHasSkinApplied(vehicle) then
                        if self.LicensePlate then
                            local skinID = getVehicleSkinID(vehicle)
                            if skinID > 0 then
                                self.LicensePlate.ItemID = skinID
                            end
                            self.LicensePlate.ChassisLightId = _LAVA_CHASSIS_LIGHT_ID
                        end
                    end
                end)
                return origPreChange(self)
            end

            local origAsyncLoad = impl.AsyncLoadAccessoryItemHandle
            if origAsyncLoad then
                impl.AsyncLoadAccessoryItemHandle = function(self, itemId, bCheckDownload)
                    if itemId == _LAVA_CHASSIS_LIGHT_ID then
                        bCheckDownload = false
                    end
                    return origAsyncLoad(self, itemId, bCheckDownload)
                end
            end

            local origAsyncLoadHandle = impl._AsyncLoadHandle
            if origAsyncLoadHandle then
                impl._AsyncLoadHandle = function(self, ItemID)
                    if ItemID == _LAVA_CHASSIS_LIGHT_ID then
                        pcall(function()
                            local UBackpackUtils = import("BackpackUtils")
                            local handlePath = self:GetAccessoryAvatarHandlePath(ItemID)
                            local itemCfg = CDataTable.GetTableData("Item", ItemID)
                            if handlePath and itemCfg and itemCfg.BPID then
                                local bpCfg = CDataTable.GetTableData("AvatarBPTable", itemCfg.BPID)
                                if bpCfg and bpCfg.AvatarBPPath and bpCfg.AvatarBPPath ~= "" then
                                    self:AsyncLoadAsset(handlePath, self.OnAccHandleLoaded, self, ItemID, itemCfg.BPID)
                                    return
                                end
                            end
                            print("[AddOutfit] _AsyncLoadHandle bypass failed for chassis light, trying direct load")
                        end)
                    end
                    return origAsyncLoadHandle(self, ItemID)
                end
            end

            local origOnRep = impl.OnRep_LicensePlate
            if origOnRep then
                impl.OnRep_LicensePlate = function(self)
                    local bReapply = false
                    pcall(function()
                        local vehicle = self:GetOwner()
                        if isLocalPlayerVehicle(vehicle) and vehicleHasSkinApplied(vehicle) then
                            bReapply = true
                            if self.LicensePlate then
                                local skinID = getVehicleSkinID(vehicle)
                                if skinID > 0 then
                                    self.LicensePlate.ItemID = skinID
                                end
                                self.LicensePlate.ChassisLightId = _LAVA_CHASSIS_LIGHT_ID
                            end
                        end
                    end)
                    local result = origOnRep(self)
                    if bReapply then
                        pcall(function()
                            if self.LicensePlate then
                                local skinID = getVehicleSkinID(self:GetOwner())
                                if skinID > 0 then
                                    self.LicensePlate.ItemID = skinID
                                end
                                self.LicensePlate.ChassisLightId = _LAVA_CHASSIS_LIGHT_ID
                            end
                            if self.PreChangeChassisLight then
                                self:PreChangeChassisLight()
                            end
                        end)
                    end
                    return result
                end
            end

            local origOnVehicleMesh = impl.OnVehicleMeshAvatarEquiped
            if origOnVehicleMesh then
                impl.OnVehicleMeshAvatarEquiped = function(self, expectItemId)
                    local result = origOnVehicleMesh(self, expectItemId)
                    pcall(function()
                        local vehicle = self:GetOwner()
                        if isLocalPlayerVehicle(vehicle) and vehicleHasSkinApplied(vehicle) then
                            if self.LicensePlate then
                                local skinID = getVehicleSkinID(vehicle)
                                if skinID > 0 then
                                    self.LicensePlate.ItemID = skinID
                                end
                                self.LicensePlate.ChassisLightId = _LAVA_CHASSIS_LIGHT_ID
                            end
                            if self.PreChangeChassisLight then
                                self:PreChangeChassisLight()
                            end
                        end
                    end)
                    return result
                end
            end

            print("[AddOutfit] VehicleLicenseComponentBase chassis hook installed")
        end

        local function hookVehiclePlateLicenseUtil()
            local ok, VPLU = pcall(require, "GameLua.Activity.Commercialize.GamePlay.Vehicle.VehiclePlateLicenseUtil")
            if not ok or not VPLU then return end
            if VPLU._lava_hooked_chassis then return end
            VPLU._lava_hooked_chassis = true
            local origGetLoc = VPLU.GetChassisLightLocAndScale
            VPLU.GetChassisLightLocAndScale = function(vehicleId, bIsLobbyVehicle)
                local loc, scale = origGetLoc(vehicleId, bIsLobbyVehicle)
                if loc and scale then
                    return loc, scale
                end
                local defaultLoc = FVector(0, -20, 10)
                local defaultScale = FVector(6.5, 7, 1)
                print("[AddOutfit] GetChassisLightLocAndScale fallback defaults for vehicleId:" .. tostring(vehicleId))
                return defaultLoc, defaultScale
            end
            print("[AddOutfit] VehiclePlateLicenseUtil chassis hook installed")
        end

        local function hookServerChangeVehicleAvatar(pc)
            if not pc or not slua.isValid(pc) then return end
            if pc._lava_hooked_server_vehicle_skin then return end
            if not pc.ServerChangeVehicleAvatar then return end
            pc._lava_hooked_server_vehicle_skin = true
            local orig = pc.ServerChangeVehicleAvatar
            local hooked = function(self, resID)
                pcall(function()
                    local char = self:GetPlayerCharacterSafety()
                    if char and slua.isValid(char) then
                        local vehicle = char.GetCurrentVehicle and char:GetCurrentVehicle()
                        if vehicle and slua.isValid(vehicle) then
                            local avatarComp = vehicle.GetAvatarComponent and vehicle:GetAvatarComponent()
                            if avatarComp and slua.isValid(avatarComp) then
                                if avatarComp.SetVehicleNetAvatarData then
                                    avatarComp:SetVehicleNetAvatarData(self)
                                end
                                if avatarComp.VehicleNetAvatarData then
                                    avatarComp.VehicleNetAvatarData.SwitchEffectId = 7303001
                                    avatarComp.VehicleNetAvatarData.UpdateFlag = 1
                                end
                                avatarComp:ChangeItemAvatar(resID, true)
                                avatarComp.CanChangeAvatar = true
                                _lastVehicleSkinKey = ""
                                print("[AddOutfit] Vehicle skin changed locally to " .. tostring(resID))
                                pcall(applyVehicleChassisLight)
                            end
                        end
                    end
                end)
            end
            pcall(function() rawset(pc, "ServerChangeVehicleAvatar", hooked) end)
        end

        local _lava_skin_click_handler
        local function getSkinClickHandler()
            if _lava_skin_click_handler then return _lava_skin_click_handler end
            _lava_skin_click_handler = function(self)
                if self.resID > 0 then
                    local UsingID = self:GetLoopScrollBoxParentUI():GetCurUsingSkinID()
                    if self.resID ~= UsingID then
                        pcall(function()
                            local GameplayData = require("GameLua.GameCore.Data.GameplayData")
                            local PlayerController = GameplayData.GetPlayerController()
                            if not slua.isValid(PlayerController) then return end
                            local char = PlayerController:GetPlayerCharacterSafety()
                            if not char or not slua.isValid(char) then return end
                            local vehicle = char.GetCurrentVehicle and char:GetCurrentVehicle()
                            if not vehicle or not slua.isValid(vehicle) then return end
                            local avatarComp = vehicle.GetAvatarComponent and vehicle:GetAvatarComponent()
                            if not avatarComp or not slua.isValid(avatarComp) then return end
                            if avatarComp.SetVehicleNetAvatarData then
                                avatarComp:SetVehicleNetAvatarData(PlayerController)
                            end
                            if avatarComp.VehicleNetAvatarData then
                                avatarComp.VehicleNetAvatarData.SwitchEffectId = 7303001
                                avatarComp.VehicleNetAvatarData.UpdateFlag = 1
                            end
                            avatarComp:ChangeItemAvatar(self.resID, true)
                            avatarComp.CanChangeAvatar = true
                            _lastVehicleSkinKey = ""
                            print("[AddOutfit] VehicleSkinItem applied skin locally " .. tostring(self.resID))
                            pcall(applyVehicleChassisLight)
                        end)
                    end
                end
                if EventSystem and EVENTYPE_INGAME_VEHICLE_CONTROL_PANEL and EVENTID_CHANGE_VEHICLESKIN_BUTTON_CLICK then
                    EventSystem:postEvent(EVENTYPE_INGAME_VEHICLE_CONTROL_PANEL, EVENTID_CHANGE_VEHICLESKIN_BUTTON_CLICK)
                end
            end
            return _lava_skin_click_handler
        end

        local function hookVehicleSkinItem()
            local ok, VSI = pcall(require, "GameLua.Mod.BaseMod.Client.InGameUI.VehicleControl.VehicleSkinItem")
            if not ok or not VSI then return end
            -- VSI هو class table اللي ليه __newindex = error، لازم نعدل على __inner_impl
            local impl = VSI.__inner_impl
            if not impl or type(impl) ~= "table" then return end
            if impl._lava_hooked_skin_item then return end
            impl._lava_hooked_skin_item = true
            local handler = getSkinClickHandler()
            local origRegist = impl.RegistEvents
            impl.RegistEvents = function(self)
                rawset(self, "OnClickSkinButton", handler)
                return origRegist(self)
            end
            local origOnRefresh = impl.OnRefresh
            impl.OnRefresh = function(self, resID, selectIndex)
                local cur = rawget(self, "OnClickSkinButton")
                if cur ~= handler then
                    rawset(self, "OnClickSkinButton", handler)
                    pcall(function()
                        if self.UnRegistEvents and self.RegistEvents then
                            self:UnRegistEvents()
                            self:RegistEvents()
                        end
                    end)
                end
                return origOnRefresh(self, resID, selectIndex)
            end
            impl.OnClickSkinButton = handler
        end

        local function hookVehicleSkinAndMusicPanel()
            local ok, VSP = pcall(require, "GameLua.Mod.BaseMod.Client.InGameUI.VehicleControl.VehicleSkinAndMusicPanel")
            if not ok or not VSP then return end
            local impl = VSP.__inner_impl
            if not impl or type(impl) ~= "table" then return end
            if impl._lava_hooked_panel then return end
            impl._lava_hooked_panel = true
            local orig = impl.InitSkinList
            impl.InitSkinList = function(self)
                hookVehicleSkinItem()
                return orig(self)
            end
        end

        local function syncVehicleAvatarSkinList()
            local pc = getPlayerController()
            if not pc or not slua.isValid(pc) then return end
            hookServerChangeVehicleAvatar(pc)
            hookVehicleSkinItem()
            hookVehicleSkinAndMusicPanel()
            hookVehicleLicenseComponentBase()
            hookVehiclePlateLicenseUtil()
            if pc.bEnableFuzzyAvatarOnClient then
                pc.bEnableFuzzyAvatarOnClient = false
            end
            if not DataMgr or not DataMgr.VehicleSlotList then return end
            if not pc.InitVehicleAvatarSkinList then return end
            local vehicleSkinData = {}
            for subType, insList in pairs(DataMgr.VehicleSlotList) do
                if insList and type(insList) == "table" then
                    local itemArray = {}
                    for _, insID in ipairs(insList) do
                        insID = tonumber(insID)
                        if insID and insID > 0 then
                            local skinResID = 0
                            if isInjectedIns(insID) then
                                skinResID = R.insToRes[insID] or 0
                            else
                                pcall(function()
                                    local wd = require("client.slua.logic.wardrobe.wardrobe_data")
                                    local d = wd:GetHallDepotItemDataByInsID(insID)
                                    skinResID = d and tonumber(d.resID) or 0
                                end)
                            end
                            if skinResID and skinResID > 0 then
                                table.insert(itemArray, {ItemTableID = skinResID, Count = 1})
                            end
                        end
                    end
                    if #itemArray > 0 then
                        table.insert(vehicleSkinData, {Items = itemArray})
                    end
                end
            end
            if #vehicleSkinData > 0 then
                pc.InitialVehicleAvatarSkinList = vehicleSkinData
                pc:InitVehicleAvatarSkinList()
            end
        end

        local function stopMatchWatcher()
            if _S.matchTimer then
                pcall(function()
                    local char = getLocalChar()
                    if char and char.RemoveGameTimer then char:RemoveGameTimer(_S.matchTimer) end
                end)
                _S.matchTimer = nil
            end
            _S.matchOutfitDone = false
            _S.avatarItemsRegistered = false
            _S.weaponApplied = false
            _S.weaponDiagDone = false
            _S.lastAppliedWeaponID = 0
            _S.lastAppliedSkinID = 0
            _S.matchApplied = false
            _S.bootstrapped = false   -- إعادة ضبط bootstrap
        end

        local function bootstrapMatch(char)
            if _S.bootstrapped then return true end
            char = char or getLocalChar()
            if not char or not slua.isValid(char) then return false end
            snapshotLobbyWear()
            _S.weaponApplied = false
            _S.weaponDiagDone = false
            _S.matchOutfitDone = false
            if not _S.bootstrapNotified then
                _S.bootstrapNotified = true
                notify("اكتشفت شخصيتك في الماتش")
            end
            startMatchWatcher(char)
            hookPlayerWearingDone()
            matchApplyAll(char)
            _S.bootstrapped = true
            return true
        end

        local function isSelfAvatarComp(self)
            if not self or not self.IsSelf then return true end
            local ok, r = pcall(function() return self:IsSelf() end)
            return ok and r == true
        end

        local function hookMatchAvatar()
            pcall(function()
                if EventSystem and EventSystem.registEvent
                    and EVENTTYPE_PLAYEREVENT_AVATAR and EVENTID_LOCAL_PLAYEREVENT_AVATAR_ALL_MESH_LOADED then
                    EventSystem:registEvent(EVENTTYPE_PLAYEREVENT_AVATAR, EVENTID_LOCAL_PLAYEREVENT_AVATAR_ALL_MESH_LOADED, function()
                        if isInLobby() then return end
                        local char = getLocalChar()
                        if char then
                            hookPlayerWearingDone()
                            applyMatchEquipAvatarToController()
                            matchApplyEquipSkins(char)
                        end
                    end)
                end
            end)
            pcall(function()
                local CAC = require("GameLua.Mod.Library.GamePlay.Avatar.Component.CharacterAvatarComponent")
                if not CAC._lava_hooked_mesh then
                    CAC._lava_hooked_mesh = true
                    local o = CAC.OnAvatarAllMeshLoadedLua
                    CAC.OnAvatarAllMeshLoadedLua = function(self)
                        o(self)
                        pcall(function()
                            if self.IsLobbyActor and self:IsLobbyActor() then return end
                            if not (self.IsSelf and self:IsSelf()) then return end
                            local char = getLocalChar()
                            if char and char.AddGameTimer then
                                char:AddGameTimer(0.5, false, function() bootstrapMatch(char) end)
                            end
                        end)
                    end
                end
            end)
            pcall(function()
                local WAC = require("GameLua.Mod.Library.GamePlay.Avatar.Component.WeaponAvatarComponent")
                local oLoad = WAC.OnWeaponAvatarLoadedLua
                WAC.OnWeaponAvatarLoadedLua = function(self, slotID, definedID)
                    oLoad(self, slotID, definedID)
                    pcall(function()
                        if self.IsLobbyActor and self:IsLobbyActor() then return end
                        if not isSelfAvatarComp(self) then return end
                        if _S.globalFrame < _S.weaponHookGuardUntil then return end
                        local char = getLocalChar()
                        if not char then return end
                        bootstrapMatch(char)
                        _S.weaponApplied = false
                        if char.AddGameTimer then
                            char:AddGameTimer(0.2, false, function()
                                local c = getLocalChar()
                                if c then matchApplyWeaponSkin(c) end
                            end)
                            -- Extra delayed pass for attachment skins
                            char:AddGameTimer(0.5, false, function()
                                local c = getLocalChar()
                                if c then matchApplyWeaponSkin(c) end
                            end)
                        end
                    end)
                end
            end)
        end

        local function onWeaponLuaInit(_, _, weapon)
            if not weapon or not slua.isValid(weapon) then return end
            local char = getLocalChar()
            if not char then return end
            local owner = nil
            pcall(function() if weapon.GetOwnerPawn then owner = weapon:GetOwnerPawn() end end)
            if not slua.isValid(owner) or owner ~= char then return end
            if _S.globalFrame < _S.weaponHookGuardUntil then return end
            pcall(function()
                char:AddGameTimer(0.15, false, function()
                    if slua.isValid(weapon) then
                        applySkinToWeaponRef(weapon)
                        _S.weaponApplied = false
                    end
                end)
                -- Extra delayed pass for attachment skins
                char:AddGameTimer(0.5, false, function()
                    if slua.isValid(weapon) then
                        applySkinToWeaponRef(weapon)
                    end
                end)
            end)
        end

        local function hookWeaponSpawn()
            if _S.weaponSpawnHooked then return end
            pcall(function()
                if EventSystem and EventSystem.registEvent
                    and EVENTTYPE_PLAYEREVENT_WEAPON and EVENTID_PLAYEREVENT_WEAPON_LUA_INIT then
                    EventSystem:registEvent(EVENTTYPE_PLAYEREVENT_WEAPON, EVENTID_PLAYEREVENT_WEAPON_LUA_INIT, onWeaponLuaInit)
                    _S.weaponSpawnHooked = true
                end
            end)
        end

        local function hookLobbyWeaponCache()
            pcall(function()
                local Arm = require("client.logic.armory.logic_armory")
                local oRsp = Arm.install_weapon_skin_rsp
                Arm.install_weapon_skin_rsp = function(client_data, errorCode, weapon_id, instanceID)
                    oRsp(client_data, errorCode, weapon_id, instanceID)
                    if errorCode == 0 or errorCode == _K.NET_OK then
                        cacheWeaponSkinFromIns(weapon_id, instanceID)
                    end
                end
            end)
            pcall(function()
                local wl = require("client.slua.logic.wardrobe.logic_wardrobe_new")
                local o = wl.on_puton_rsp
                wl.on_puton_rsp = function(self, res, item, olditem, index, extra)
                    o(self, res, item, olditem, index, extra)
                    if item and item.instid and (res == 0 or res == _K.NET_OK) then
                        local resID, insID = tonumber(item.res_id), tonumber(item.instid)
                        local slot = getEquipSkinSlot(resID)
                        if isInjectedIns(insID) and slot and not _S.equipSkinApplying then
                            saveEquipSkin(resID, insID)
                            if slot ~= "parachute" and slot ~= "glider" then
                                applyEquipVisual(resID, insID, slot)
                            end
                        elseif isInjectedIns(insID) then
                            local mt = wardrobeMainTab(resID)
                            if mt ~= _K.WARDROBE_PAGE_VEHICLE then
                                if isThrowObjectRes(resID) then
                                    saveThrowObject(resID, insID)
                                else
                                    saveEquip(resID, insID)
                                end
                            end
                        end
                    end
                end
            end)
        end

        -- هوك تبويب الأسلحة المُحسَّن (يمنع الإجبار)
        local function hookGunWardrobe()
            pcall(function()
                local wgl = require("client.slua.logic.wardrobe.logic_wardrobe_gun")
                if wgl._lava_gun_hooked then return end
                wgl._lava_gun_hooked = true

                local origSetGunID = wgl.SetGunID
                wgl.SetGunID = function(self, weaponID, ...)
                    weaponID = tonumber(weaponID)
                    if not weaponID then return origSetGunID(self, weaponID, ...) end

                    local w = cache().weapons[weaponID]
                    local injected = w and w.insID and w.insID > 0 and isInjectedIns(w.insID)
                    -- تحقق مما إذا كان السكن الحالي مطابقاً للمطلوب
                    local currentSkin = wgl.GetCurrentEquippedSkinInsID and wgl:GetCurrentEquippedSkinInsID(weaponID) or 0
                    if injected and currentSkin == w.insID then
                        -- السكن مطبق بالفعل، لا تفعل شيئاً
                        return origSetGunID(self, weaponID, ...)
                    end

                    if injected then
                        pcall(function()
                            local Arm = require("client.logic.armory.logic_armory")
                            Arm.rsp_list = Arm.rsp_list or { skin_list = {}, install_list = {} }
                            Arm.rsp_list.install_list = Arm.rsp_list.install_list or {}
                            Arm.rsp_list.install_list[weaponID] = { skin_id = w.insID }
                            
                            local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                            if fbd.UpdateCurrentFashionBagWeaponSkin then
                                fbd:UpdateCurrentFashionBagWeaponSkin(weaponID, w.insID)
                            end
                            if fbd.SetFashionBagWeaponSkin then
                                fbd:SetFashionBagWeaponSkin(weaponID, w.insID)
                            end
                        end)
                    else
                        -- إذا لم يكن هناك سكن محقون، تأكد من مسح أي سكن مثبت
                        pcall(function()
                            local Arm = require("client.logic.armory.logic_armory")
                            if Arm.rsp_list and Arm.rsp_list.install_list then
                                Arm.rsp_list.install_list[weaponID] = nil
                            end
                            local fbd = require("client.slua.logic.wardrobe.fashionbag.fashionbag_data")
                            if fbd.UpdateCurrentFashionBagWeaponSkin then
                                fbd:UpdateCurrentFashionBagWeaponSkin(weaponID, 0)
                            end
                            local bag = fbd.GetCurrentFashionBag and fbd:GetCurrentFashionBag()
                            if bag and bag.weapon_skin_list then
                                bag.weapon_skin_list[weaponID] = nil
                            end
                        end)
                    end

                    local result = origSetGunID(self, weaponID, ...)

                    if injected then
                        later(0.05, function()
                            pcall(function()
                                local wgl2 = require("client.slua.logic.wardrobe.logic_wardrobe_gun")
                                wgl2:UpdateCurrentGunAvatar(weaponID, w.insID)
                                
                                if EventSystem then
                                    if EVENTTYPE_WARDROBE and EVENTID_WARDROBE_UPDATE_CURRENT_PUT_ON_GUN then
                                        EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_CURRENT_PUT_ON_GUN, w.resID)
                                    end
                                    if EVENTTYPE_WARDROBE and EVENTID_WARDROBE_UPDATE_GUN_LIST then
                                        EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_GUN_LIST, -1)
                                    end
                                    if EVENTTYPE_ARMORY and EVENTID_ARMORY_EQUIP_STAT_CHANGE then
                                        EventSystem:postEvent(EVENTTYPE_ARMORY, EVENTID_ARMORY_EQUIP_STAT_CHANGE, w.resID)
                                    end
                                end
                            end)
                        end)
                        -- log("إعادة تطبيق سكن بعد تبديل سلاح", weaponID, w.resID)
                    else
                        -- تحديث الواجهة لإزالة السكن
                        later(0.05, function()
                            pcall(function()
                                local wgl2 = require("client.slua.logic.wardrobe.logic_wardrobe_gun")
                                wgl2:UpdateCurrentGunAvatar(weaponID, 0)
                                if EventSystem and EVENTTYPE_WARDROBE and EVENTID_WARDROBE_UPDATE_CURRENT_PUT_ON_GUN then
                                    EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_CURRENT_PUT_ON_GUN, 0)
                                end
                                if EventSystem and EVENTID_WARDROBE_UPDATE_GUN_LIST then
                                    EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_UPDATE_GUN_LIST, weaponID)
                                end
                            end)
                        end)
                        log("إزالة سكن السلاح", weaponID)
                    end
                    
                    return result
                end

                local origUpdateGunAvatar = wgl.UpdateCurrentGunAvatar
                wgl.UpdateCurrentGunAvatar = function(self, weaponID, insID, ...)
                    weaponID = tonumber(weaponID)
                    insID = tonumber(insID)
                    if weaponID and (not insID or insID <= 0) then
                        local w = cache().weapons[weaponID]
                        if w and w.insID and w.insID > 0 and isInjectedIns(w.insID) then
                            insID = w.insID
                            log("UpdateCurrentGunAvatar: استخدام سكن محفوظ", weaponID, insID)
                        else
                            insID = 0
                        end
                    end
                    return origUpdateGunAvatar(self, weaponID, insID, ...)
                end

                if wgl.GetCurrentEquippedSkinInsID then
                    local origGetCurSkin = wgl.GetCurrentEquippedSkinInsID
                    wgl.GetCurrentEquippedSkinInsID = function(self, weaponID, ...)
                        weaponID = tonumber(weaponID)
                        if weaponID then
                            local w = cache().weapons[weaponID]
                            if w and w.insID and w.insID > 0 and isInjectedIns(w.insID) then
                                return w.insID
                            end
                        end
                        return origGetCurSkin(self, weaponID, ...)
                    end
                end

                if wgl.GetGunSkinInsID then
                    local origGetGunSkin = wgl.GetGunSkinInsID
                    wgl.GetGunSkinInsID = function(self, weaponID, ...)
                        weaponID = tonumber(weaponID)
                        if weaponID then
                            local w = cache().weapons[weaponID]
                            if w and w.insID and w.insID > 0 and isInjectedIns(w.insID) then
                                return w.insID
                            end
                        end
                        return origGetGunSkin(self, weaponID, ...)
                    end
                end

                log("hookGunWardrobe: تم")
            end)
        end

        -- ========== Collection Ace Eliminator Broadcast (619150001) ==========
        local ELIMINATION_KING_EFFECT_ID = 619150001

        -- ========== Last Strike Champion Final Kill Effect (61950002) ==========
        local FINAL_KILL_EFFECT_ID = 61950002

        local function getLocalPlayerKey()
            local ok, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
            if ok and GD and GD.GetPlayerState then
                local ps = GD.GetPlayerState()
                if ps and slua.isValid(ps) and ps.PlayerKey then
                    return tonumber(ps.PlayerKey)
                end
            end
            return nil
        end

        local function getLocalUID()
            local uid
            pcall(function()
                local Subsystem = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
                local AccountSubsystem = Subsystem:Get("AccountSubsystem")
                if AccountSubsystem and AccountSubsystem.GetAccountUID then
                    uid = AccountSubsystem:GetAccountUID()
                end
            end)
            if not uid then
                pcall(function()
                    local GD = require("GameLua.GameCore.Data.GameplayData")
                    local ps = GD.GetPlayerState()
                    if ps and slua.isValid(ps) and ps.UID then
                        uid = tonumber(ps.UID)
                    end
                end)
            end
            return uid
        end

        local function hookEliminationKingEffect()
            if _G._lava_hooked_elim_king then return end
            _G._lava_hooked_elim_king = true

            pcall(function()
                local CommerAvatarDataUtil = require("GameLua.Activity.Commercialize.GamePlay.CommerAvatarDataUtil")
                if CommerAvatarDataUtil._lava_hooked_ext_attr then return end
                CommerAvatarDataUtil._lava_hooked_ext_attr = true

                local ExtendAttribute = require("Server.config.ExtendAttribute")
                local origGetAttr = CommerAvatarDataUtil.GetPlayerExtendAttributeAndTest
                CommerAvatarDataUtil.GetPlayerExtendAttributeAndTest = function(self, UID, attr)
                    if attr == ExtendAttribute.EliminationKingEffect then
                        local localUID = getLocalUID()
                        if localUID and tonumber(UID) == tonumber(localUID) then
                            return ELIMINATION_KING_EFFECT_ID
                        end
                    end
                    return origGetAttr(self, UID, attr)
                end
                log("hookEliminationKingEffect: CommerAvatarDataUtil hooked")
            end)

            pcall(function()
                local KillInfoClass = require("GameLua.Mod.BaseMod.Client.KillInfoTips.KillInfo")
                local impl = KillInfoClass.__inner_impl
                if not impl or impl._lava_hooked_show_king then return end
                impl._lava_hooked_show_king = true

                local origShow = impl.ShowKingEliminationInfo
                impl.ShowKingEliminationInfo = function(self, DamageRecordData)
                    local localKey = getLocalPlayerKey()
                    if localKey and DamageRecordData and DamageRecordData.ExpandDataContent then
                        pcall(function()
                            local FatalDamageInfo = slua.LuaArchiverDecode(LuaStateWrapper, DamageRecordData.ExpandDataContent)
                            if FatalDamageInfo and FatalDamageInfo.KingEliminationInfo then
                                local KingEliminationInfo = FatalDamageInfo.KingEliminationInfo
                                if KingEliminationInfo.NewKingEliminationInfo then
                                    local info = KingEliminationInfo.NewKingEliminationInfo
                                    if tonumber(info.PlayerKey) == localKey then
                                        info.EffectID = ELIMINATION_KING_EFFECT_ID
                                        log("hookEliminationKingEffect: injected EffectID into NewKingEliminationInfo")
                                    end
                                end
                                if KingEliminationInfo.DeadKingEliminationInfo then
                                    local info = KingEliminationInfo.DeadKingEliminationInfo
                                    if tonumber(info.KillerPlayerKey) == localKey then
                                        info.EffectID = ELIMINATION_KING_EFFECT_ID
                                        log("hookEliminationKingEffect: injected EffectID into DeadKingEliminationInfo")
                                    end
                                end
                            end
                        end)
                    end
                    return origShow(self, DamageRecordData)
                end
                log("hookEliminationKingEffect: KillInfo.ShowKingEliminationInfo hooked")
            end)

            pcall(function()
                local KingEliminationInfoItemClass = require("GameLua.Mod.BaseMod.Client.KillInfoTips.KingEliminationInfoItem")
                local impl = KingEliminationInfoItemClass.__inner_impl
                if not impl or impl._lava_hooked_update then return end
                impl._lava_hooked_update = true

                local origUpdate = impl.UpdateKingEliminationInfo
                impl.UpdateKingEliminationInfo = function(self, DamageRecordData, KingEliminationInfo)
                    local localKey = getLocalPlayerKey()
                    if localKey and KingEliminationInfo then
                        if KingEliminationInfo.NewKingEliminationInfo then
                            local info = KingEliminationInfo.NewKingEliminationInfo
                            if tonumber(info.PlayerKey) == localKey then
                                info.EffectID = ELIMINATION_KING_EFFECT_ID
                            end
                        end
                        if KingEliminationInfo.DeadKingEliminationInfo then
                            local info = KingEliminationInfo.DeadKingEliminationInfo
                            if tonumber(info.KillerPlayerKey) == localKey then
                                info.EffectID = ELIMINATION_KING_EFFECT_ID
                            end
                        end
                    end
                    return origUpdate(self, DamageRecordData, KingEliminationInfo)
                end
                log("hookEliminationKingEffect: KingEliminationInfoItem hooked")
            end)

            pcall(function()
                local PlayerStateBaseClass = require("GameLua.GameCore.Framework.PlayerStateBase")
                local impl = PlayerStateBaseClass.__inner_impl
                if not impl or impl._lava_hooked_init_team then return end
                impl._lava_hooked_init_team = true

                local origInit = impl.InitTeamShowData
                impl.InitTeamShowData = function(self, ...)
                    origInit(self, ...)
                    pcall(function()
                        local localUID = getLocalUID()
                        if localUID and self.UID and tonumber(self.UID) == tonumber(localUID) then
                            self.EliminationKingEffectID = ELIMINATION_KING_EFFECT_ID
                        end
                    end)
                end
                log("hookEliminationKingEffect: PlayerStateBase hooked")
            end)
        end

        local function tickEliminationKingEffect()
            pcall(function()
                local ok, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
                if ok and GD and GD.GetPlayerState then
                    local ps = GD.GetPlayerState()
                    if ps and slua.isValid(ps) then
                        if not ps.EliminationKingEffectID or ps.EliminationKingEffectID == 0 then
                            ps.EliminationKingEffectID = ELIMINATION_KING_EFFECT_ID
                        end
                    end
                end
            end)
        end

        -- ========== Last Strike Champion Final Kill Effect (61950002) ==========
        local function hookFinalKillEffect()
            if _G._lava_hooked_final_kill then return end
            _G._lava_hooked_final_kill = true

            -- 1. Hook FinalKillEffectLevelSequenceActor to handle missing config for 61950002
            -- If config doesn't exist or Sequence is empty, directly call OnPlay callback
            pcall(function()
                local LSActor = require("GameLua.Mod.Library.GamePlay.Actor.FinalKillEffectLevelSequenceActor")
                if LSActor._lava_hooked then return end
                LSActor._lava_hooked = true

                local origBeginPlay = LSActor.ReceiveBeginPlay
                if origBeginPlay then
                    LSActor.ReceiveBeginPlay = function(self)
                        if self.ItemId == FINAL_KILL_EFFECT_ID then
                            local Config = CDataTable.GetTableData("FinalKillEffectCfg", self.ItemId)
                            if not Config or not Config.Sequence or Config.Sequence == "" then
                                log("hookFinalKillEffect: no sequence for 61950002, calling OnPlay directly")
                                if self.Callback and self.Callback.OnPlay then
                                    self.Callback.OnPlay()
                                end
                                return
                            end
                        end
                        return origBeginPlay(self)
                    end
                    log("hookFinalKillEffect: FinalKillEffectLevelSequenceActor hooked")
                end
            end)

            -- 2. Hook TriggerParticleEffect to force ItemId = 61950002
            pcall(function()
                local Feature = require("GameLua.Mod.BaseMod.GamePlay.Feature.Player.PlayerCharacterFinalKillEffectFeature")
                if Feature._lava_hooked_fke then return end
                Feature._lava_hooked_fke = true

                local origTriggerParticle = Feature.TriggerParticleEffect
                if origTriggerParticle then
                    Feature.TriggerParticleEffect = function(self, ItemId, Location, Rotator, TeamMemberNames)
                        log("hookFinalKillEffect: TriggerParticleEffect called, ItemId=" .. tostring(ItemId) .. " forcing to " .. tostring(FINAL_KILL_EFFECT_ID))
                        return origTriggerParticle(self, FINAL_KILL_EFFECT_ID, Location, Rotator, TeamMemberNames)
                    end
                end

                local origPrepareItem = Feature.PrepareItem
                if origPrepareItem then
                    Feature.PrepareItem = function(self, ItemId)
                        log("hookFinalKillEffect: PrepareItem called, ItemId=" .. tostring(ItemId) .. " forcing to " .. tostring(FINAL_KILL_EFFECT_ID))
                        return origPrepareItem(self, FINAL_KILL_EFFECT_ID)
                    end
                end
                log("hookFinalKillEffect: PlayerCharacterFinalKillEffectFeature hooked")
            end)

            -- 3. Direct client-side trigger when game ends
            local function triggerFinalKillEffect()
                pcall(function()
                    local char = getLocalChar()
                    if not char or not slua.isValid(char) then
                        log("hookFinalKillEffect: char not valid")
                        return
                    end

                    if _G._lava_fke_triggered then return end
                    _G._lava_fke_triggered = true

                    char:EnsureDynamicFeature("FinalKillEffect")
                    if not char.FinalKillEffect then
                        log("hookFinalKillEffect: FinalKillEffect feature not available")
                        return
                    end

                    local Location = char:K2_GetActorLocation()
                    local Rotator = FRotator(0, 0, 0)
                    local Names = char.PlayerName or ""

                    log("hookFinalKillEffect: triggering effect 61950002")
                    char.FinalKillEffect:TriggerParticleEffect(FINAL_KILL_EFFECT_ID, Location, Rotator, Names)
                end)
            end

            -- 3a. Hook BattleResult.on_game_result (global function, client-side)
            pcall(function()
                if BattleResult and BattleResult.on_game_result and not BattleResult._lava_hooked_fke then
                    BattleResult._lava_hooked_fke = true
                    local origOnGameResult = BattleResult.on_game_result
                    BattleResult.on_game_result = function(battle_result, result)
                        log("hookFinalKillEffect: BattleResult.on_game_result triggered")
                        triggerFinalKillEffect()
                        return origOnGameResult(battle_result, result)
                    end
                    log("hookFinalKillEffect: BattleResult.on_game_result hooked")
                end
            end)

            -- 3b. Hook BattleResult.on_game_over (global function, client-side)
            pcall(function()
                if BattleResult and BattleResult.on_game_over and not BattleResult._lava_hooked_fke_over then
                    BattleResult._lava_hooked_fke_over = true
                    local origOnGameOver = BattleResult.on_game_over
                    BattleResult.on_game_over = function(game_id)
                        log("hookFinalKillEffect: BattleResult.on_game_over triggered")
                        triggerFinalKillEffect()
                        return origOnGameOver(game_id)
                    end
                    log("hookFinalKillEffect: BattleResult.on_game_over hooked")
                end
            end)

            -- 3c. Also register for the event as backup (with nil checks)
            pcall(function()
                if EventSystem and EventSystem.registEvent
                    and EVENTTYPE_STATE and EVENTID_GAMESTATE_ON_PRE_BATTLE_RESULT
                    and not _G._lava_fke_event_registered then
                    _G._lava_fke_event_registered = true
                    EventSystem:registEvent(EVENTTYPE_STATE, EVENTID_GAMESTATE_ON_PRE_BATTLE_RESULT, triggerFinalKillEffect)
                    log("hookFinalKillEffect: registered for EVENTID_GAMESTATE_ON_PRE_BATTLE_RESULT")
                end
            end)

            log("hookFinalKillEffect: done")
        end

        -- ========== تشغيل ==========
        -- ===================================================================
        -- SECURITY: ANTI-CHEAT BYPASS (from 2.lua Section 19)
        -- ===================================================================
        local function hookSecurityBypass()
            -- 1. Disable puffer download reporting
            pcall(function()
                local pufferTlog = package.loaded["client.slua.logic.download.report.puffer_tlog"]
                if pufferTlog then
                    pufferTlog.ReportEvent = function() end
                    pufferTlog.ReportDownloadResult = function() end
                    pufferTlog.ReportODPAKError = function() end
                end
            end)

            -- 2. Bypass AvatarUtils weapon blacklist
            pcall(function()
                local AvatarUtils = package.loaded["AvatarUtils"]
                if AvatarUtils then
                    AvatarUtils.CheckIsWeaponInBlackList = function() return false end
                    AvatarUtils.IsValidAvatar = function() return true end
                end
            end)

            -- 3. Disable file integrity checking
            pcall(function()
                local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
                if SubsystemMgr then
                    local FileCheckSubsystem = SubsystemMgr:Get("FileCheckSubsystem")
                    if FileCheckSubsystem then
                        FileCheckSubsystem.StartCheck = function() end
                        FileCheckSubsystem.ReportAbnormalFile = function() end
                    end
                end
            end)

            -- 4. Disable equipment exception reporting
            pcall(function()
                local equipReport = package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
                if equipReport then
                    equipReport.Report = function() end
                end
            end)

            -- 5. Disable puffer download validation
            pcall(function()
                local pufferManager = require("client.slua.logic.download.puffer.puffer_manager")
                local pufferConst = require("client.slua.logic.download.puffer_const")
                if pufferManager and pufferConst then
                    local origCheck = pufferManager.CheckResourceValid
                    if origCheck then
                        pufferManager.CheckResourceValid = function(...) return true end
                    end
                end
            end)

            -- 6. Bypass avatar hash verification
            pcall(function()
                local AvatarUtils = package.loaded["AvatarUtils"]
                if AvatarUtils then
                    local origVerify = AvatarUtils.VerifyAvatarData
                    if origVerify then
                        AvatarUtils.VerifyAvatarData = function(...) return true end
                    end
                end
            end)

            print("[AddOutfit] Security bypass installed")
        end

        -- ===================================================================
        -- KILL MESSAGE SYSTEM (from 2.lua Section 17)
        -- Injects weapon skin + outfit skin + golden color into kill feed
        -- ===================================================================
        local _killCounterHooked = false
        local _safeRequireCache = {}
        local function safeRequire(name)
            if _safeRequireCache[name] then return _safeRequireCache[name] end
            local loaded = package.loaded[name]
            if loaded then _safeRequireCache[name] = loaded; return loaded end
            local ok, mod = pcall(require, name)
            if ok and mod then _safeRequireCache[name] = mod; return mod end
            return nil
        end

        _G.AKFakeKillCounts = _G.AKFakeKillCounts or setmetatable({}, { __index = function() return 0 end })

        local function pushKillCounterUpdate(weaponID, skinID, killCount)
            pcall(function()
                local UIManager = safeRequire("client.slua_ui_framework.manager")
                if not UIManager then return end
                local killCounterUI = UIManager.GetUI(UIManager.UI_Config_InGame.MainKillCounter)
                if not killCounterUI or not killCounterUI.UpdateWeaponID then return end
                local avatarSkinID = skinID or weaponID
                killCounterUI:UpdateWeaponID(weaponID, avatarSkinID)
                local ModuleManager = safeRequire("client.module_framework.ModuleManager")
                if ModuleManager then
                    local kcLogic = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
                    if kcLogic and kcLogic.GetEquipedKillCounterId then
                        local equippedKCId = kcLogic:GetEquipedKillCounterId(0, avatarSkinID)
                        if killCounterUI.SetKillCounterItemShowWithNum then
                            killCounterUI:SetKillCounterItemShowWithNum(equippedKCId, killCount, avatarSkinID)
                        end
                    end
                end
            end)
        end

        local function hookKillMessages()
            if _killCounterHooked then return end
            local anyHooked = false

            -- 1. Kill Counter UI hooks
            pcall(function()
                local KillCounterUI = safeRequire("GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem")
                if KillCounterUI and KillCounterUI.__inner_impl then
                    local impl = KillCounterUI.__inner_impl
                    impl.CheckSupportKCUI = function() return true end
                    impl.CheckNeedMainKillCounterUI = function(self, weapon, PlayerID)
                        if slua.isValid(weapon) then
                            local weaponID = weapon:GetWeaponID()
                            local skinID = _G.get_skin_id and _G.get_skin_id(weaponID) or weaponID
                            self:UpdateMainKillCounterUI(true, weaponID, skinID)
                            pushKillCounterUpdate(weaponID, skinID, _G.AKFakeKillCounts[weaponID] or 0)
                        else
                            self:UpdateMainKillCounterUI(false)
                        end
                    end
                    local origUpdate = impl.UpdateMainKillCounterUI
                    impl.UpdateMainKillCounterUI = function(self, bShow, weaponID, AvatarID)
                        if bShow then
                            AvatarID = _G.get_skin_id and _G.get_skin_id(weaponID) or AvatarID
                        end
                        if origUpdate then origUpdate(self, bShow, weaponID, AvatarID) end
                        if bShow then
                            pushKillCounterUpdate(weaponID, AvatarID, _G.AKFakeKillCounts[weaponID] or 0)
                        end
                    end
                    anyHooked = true
                end
            end)

            -- 2. Kill Counter Logic hooks
            pcall(function()
                local ModuleManager = safeRequire("client.module_framework.ModuleManager")
                if ModuleManager then
                    local kcLogic = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
                    if kcLogic then
                        kcLogic.CheckSupportKC = function() return true end
                        kcLogic.CheckSupportKillCounterAvatar = function() return true end
                        kcLogic.CheckHasWeaponKillCounter = function() return true end
                        kcLogic.GetBaseKillCounterIdByWeaponId = function() return 2100004 end
                        kcLogic.GetEquipedKillCounterId = function() return 2100004 end
                        kcLogic.GetMyEquipedKillCounterId = function() return 2100004 end
                        kcLogic.GetOneWeaponKillCountInBattle = function(self, uid, weaponId)
                            return _G.AKFakeKillCounts[weaponId] or 0
                        end
                        kcLogic.GetWeaponKillCountByUid = function(self, uid, weaponId)
                            return _G.AKFakeKillCounts[weaponId] or 0
                        end
                        anyHooked = true
                    end
                end
            end)

            -- 3. Kill Info Message hook (inject skin + color into kill feed)
            pcall(function()
                local KillInfo = safeRequire("GameLua.Mod.BaseMod.Client.KillInfoTips.KillInfo")
                if KillInfo and KillInfo.__inner_impl then
                    local origFileItem = KillInfo.__inner_impl.FileItem
                    KillInfo.__inner_impl.FileItem = function(self, DamageRecordData)
                        pcall(function()
                            local GD = safeRequire("GameLua.GameCore.Data.GameplayData")
                            if not GD then return end
                            local playerChar = GD.GetPlayerCharacter()
                            if not playerChar or not slua.isValid(playerChar) then return end
                            -- Only modify YOUR kill messages
                            if DamageRecordData.Causer ~= playerChar:GetPlayerNameSafety() then return end
                            local currentWeapon = playerChar:GetCurrentWeapon()
                            if not slua.isValid(currentWeapon) then return end
                            local weaponID = currentWeapon:GetWeaponID()
                            local skinID = _G.get_skin_id and _G.get_skin_id(weaponID) or weaponID
                            -- Inject weapon skin into kill message
                            if skinID then
                                DamageRecordData.CauserWeaponAvatarID = skinID
                            end
                            -- Inject outfit skin into kill message
                            if _G.SuitSkin and _G.SuitSkin ~= 0 then
                                DamageRecordData.CauserClothAvatarID = _G.SuitSkin
                            end
                            -- Golden name color
                            DamageRecordData.IsUseColor = true
                            DamageRecordData.UseColor = import("LinearColor")(1.0, 0.8, 0.0, 1.0)
                            -- Track kill count
                            if DamageRecordData.ResultHealthStatus == 2 then
                                _G.AKFakeKillCounts[weaponID] = (_G.AKFakeKillCounts[weaponID] or 0) + 1
                                pushKillCounterUpdate(weaponID, skinID, _G.AKFakeKillCounts[weaponID])
                            end
                        end)
                        if origFileItem then return origFileItem(self, DamageRecordData) end
                    end
                    anyHooked = true
                end
            end)

            -- 4. Weapon Slot Mode 2 - Kill Counter Icon
            pcall(function()
                local SlotMode2 = safeRequire("GameLua.Mod.BaseMod.Client.MainControlUI.SwitchWeaponSlotMode2")
                if SlotMode2 and SlotMode2.__inner_impl then
                    local origCheck = SlotMode2.__inner_impl.CheckShowKCIcon
                    SlotMode2.__inner_impl.CheckShowKCIcon = function(self)
                        if self.KillCounterImg and slua.isValid(self.KillCounterImg) then
                            self.KillCounterImg:SetVisibility(import("ESlateVisibility").SelfHitTestInvisible)
                        end
                        if origCheck then return origCheck(self) end
                    end
                    local origShow = SlotMode2.__inner_impl.ShowKCIcon
                    if origShow then
                        SlotMode2.__inner_impl.ShowKCIcon = function(self, weaponID, skinID)
                            local cnt = _G.AKFakeKillCounts[weaponID] or 0
                            if origShow then origShow(self, weaponID, skinID) end
                            if cnt > 0 then
                                pcall(function()
                                    if self.KillCounterImg and self.KillCounterImg.SetKillCount then
                                        self.KillCounterImg:SetKillCount(cnt)
                                    end
                                end)
                            end
                        end
                    end
                    anyHooked = true
                end
            end)

            if anyHooked then _killCounterHooked = true end
        end

        -- 5. Refresh kill counter for current weapon
        _G.RefreshKillCounterUI = function()
            pcall(function()
                local GD = safeRequire("GameLua.GameCore.Data.GameplayData")
                if not GD then return end
                local pc = GD.GetPlayerController()
                if not pc or not slua.isValid(pc) then return end
                local lp = pc:GetPlayerCharacterSafety()
                if not lp or not slua.isValid(lp) then return end
                local cw = lp:GetCurrentWeapon()
                if not slua.isValid(cw) then return end
                local wID = cw:GetWeaponID()
                if not wID or wID == 0 then return end
                local sid = _G.get_skin_id and _G.get_skin_id(wID)
                if not sid then
                    local KCUI = package.loaded["GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem"]
                    if KCUI and KCUI.__inner_impl then
                        KCUI.__inner_impl:UpdateMainKillCounterUI(false)
                    end
                    return
                end
                local KCUI = package.loaded["GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem"]
                if KCUI and KCUI.__inner_impl then
                    KCUI.__inner_impl:UpdateMainKillCounterUI(true, wID, sid)
                end
                pushKillCounterUpdate(wID, sid, _G.AKFakeKillCounts[wID] or 0)
            end)
        end

        _G.ForceEnableKillCounterUI = function()
            hookKillMessages()
            _G.RefreshKillCounterUI()
        end

        -- ===================================================================
        -- TEAM BROADCAST KILL MESSAGES (v1.1)
        -- Shows weapon skin / vehicle skin in team kill notifications
        -- ===================================================================
        local _teamBroadcastHooked = false
        local function hookTeamBroadcast()
            if _teamBroadcastHooked then return end
            pcall(function()
                local BattleKillBroadcastSubSystem = require("GameLua.Mod.BaseMod.Client.BattleKillBroadcast.BattleKillBroadcastSubSystem")
                if not BattleKillBroadcastSubSystem then return end
                local O_CopyKillOrPutDownMessageDataUserDataToLuaTable = BattleKillBroadcastSubSystem.CopyKillOrPutDownMessageDataUserDataToLuaTable
                if not O_CopyKillOrPutDownMessageDataUserDataToLuaTable then return end
                BattleKillBroadcastSubSystem.CopyKillOrPutDownMessageDataUserDataToLuaTable = function(self, messageData)
                    local msgData = O_CopyKillOrPutDownMessageDataUserDataToLuaTable(self, messageData)
                    if not msgData or not msgData.bIamCauser then return msgData end
                    pcall(function()
                        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                        if not pc then return end
                        local uCharacter = pc:GetPlayerCharacterSafety()
                        if not uCharacter or not slua.isValid(uCharacter) then return end
                        if msgData.DamageType == UEnums.DamageType.VehicleDamage then
                            -- Vehicle kill: inject vehicle skin
                            local carSkinID = _G.CurrentEquipVehicleID
                            if carSkinID and carSkinID ~= 0 then
                                local ExpandData = slua.LuaArchiverDecode(LuaStateWrapper, msgData.ExpandDataContent) or {}
                                ExpandData.CauserVehicleSkinID = carSkinID
                                ExpandData.CauserWeaponAvatarID = carSkinID
                                msgData.ExpandDataContent = slua.LuaArchiverEncode(LuaStateWrapper, ExpandData)
                            end
                        else
                            -- Weapon kill: inject weapon skin
                            local currWeapon = uCharacter:GetCurrentWeapon()
                            if currWeapon and slua.isValid(currWeapon) then
                                local synData = currWeapon.synData
                                if synData and slua.isValid(synData) then
                                    local weaponDefineID = slua.IndexReference(synData:Get(7), "defineID")
                                    if weaponDefineID and slua.isValid(weaponDefineID) then
                                        local ExpandData = slua.LuaArchiverDecode(LuaStateWrapper, msgData.ExpandDataContent) or {}
                                        ExpandData.CauserWeaponAvatarID = weaponDefineID.TypeSpecificID
                                        msgData.ExpandDataContent = slua.LuaArchiverEncode(LuaStateWrapper, ExpandData)
                                    end
                                end
                            end
                        end
                    end)
                    return msgData
                end
                _teamBroadcastHooked = true
                print("[AddOutfit] Team broadcast kill messages hooked")
            end)
        end

        

                local function start()
            log("AddOutfit Merged start")
            -- Security bypass first
            pcall(hookSecurityBypass)
            -- Kill message system
            pcall(hookKillMessages)
            -- Team broadcast kill messages (v1.1)
            pcall(hookTeamBroadcast)
            buildSkinMappings()
            pcall(restorePersistedVehicles)
            pcall(restorePersistedMotions)
            pcall(restorePersistedEquipIns)
            pcall(restorePersistedThrowObjects)
            pcall(restorePersistedHallTheme)
            pcall(syncMatchConfigFromCache)
            hookCDataTableCache()
            hookDepotInit()
            hookWardrobeData()
            hookPageFilter()
            hookArmory()
            hookPutOn()
            hookLobbyTheme()
            hookMotionEquip()
            hookIngameEmote()
            hookFashionBag()
            hookBackpackValid()
            hookAvatarValid()
            hookEquipMapping()
            hookLobbyWeaponCache()
            hookGunWardrobe()
            hookLobbySwipePersistence()
            hookMatchAvatar()
            hookMatchAvatarData()
            hookGrenadeAvatarInit()
            hookGrenadeAvatarLookup()
            hookProjectileGrenadeAvatar()
            hookWeaponSpawn()
            hookVehicleLicenseComponentBase()
            hookVehiclePlateLicenseUtil()
            hookBackpackWeaponAvatarRes()
            hookEliminationKingEffect()
            hookFinalKillEffect()

            if injectAllSources() then
                refreshWardrobe()
                later(1.0, reapplyLobbyEquipped)
            else
                local tries = 0
                local function retry()
                    tries = tries + 1
                    if injectAllSources() then
                        refreshWardrobe()
                        later(1.0, reapplyLobbyEquipped)
                        return
                    end
                    if tries < 40 then later(1.5, retry) end
                end
                later(1.5, retry)
            end

            pcall(function()
                if isInGamePlay() then
                    local char = getLocalChar()
                    if char then bootstrapMatch(char) end
                elseif isInLobby() then
                    snapshotLobbyWear()
                end
            end)
        end

        hookBackpackValid()
        hookEquipMapping()
        hookMatchAvatar()
        hookMatchAvatarData()
        hookGrenadeAvatarInit()
        hookGrenadeAvatarLookup()
        hookProjectileGrenadeAvatar()
        hookWeaponSpawn()
        hookBackpackWeaponAvatarRes()
        hookEliminationKingEffect()
        hookFinalKillEffect()
        pcall(_loadEquippedCache)
        start()
        pcall(hookVehicleSkinAndMusicPanel)

        -- Time-based application loop (replaces frame-based tick listener)
        -- Uses os.clock() for time tracking instead of frame counting
        local _lastTickTime = os.clock()
        local _timeCount = 0
        
        -- Periodic application functions with different rates
        local _lastAppliedHash = ""
local function fastApplyLoop()
    pcall(function()
        _timeCount = _timeCount + 1
        _S.globalFrame = _timeCount

        -- Kill counter UI refresh
        if _timeCount % 10 == 0 and _killCounterHooked then
            pcall(function()
                if _G.RefreshKillCounterUI then _G.RefreshKillCounterUI() end
            end)
        end

        if isInLobby() then
            if _timeCount % 30 == 0 then
                pcall(snapshotLobbyWear)
            end
            if _timeCount % 15 == 0 then
                pcall(_G.AddOutfitTryFlushSave)
            end
        end

        if isInGamePlay() then
            local char = getLocalChar()
            local charValid = char and slua.isValid(char)

            if not _S.matchTimer and charValid then
                bootstrapMatch(char)
            end

            if charValid then
                local cch = _G.AddOutfitEquippedCache or {}

                local sig = (cch.outfitRes or 0) * 100000 +
                            ((cch.equip and cch.equip.bag or 0) % 1000) * 100 +
                            ((cch.equip and cch.equip.helmet or 0) % 100)

                if sig ~= _lastAppliedSig then
                    _lastAppliedSig = sig
                    if char and char.AddGameTimer then
                        char:AddGameTimer(0.5, false, function()
                            if slua.isValid(char) and not _S.matchOutfitDone then
                                _S.matchOutfitDone = matchApplyOutfit(char)
                            end
                        end)
                    end
                end

                matchApplyEquipSkins(char)
                applyGrenadeSkinsToController()

                -- Weapon skin loop (5s cadence)
                if _timeCount % 5 == 0 then
                    pcall(function()
                        local curWeapon = char.GetCurrentWeapon and char:GetCurrentWeapon()
                        if slua.isValid(curWeapon) then
                            applySkinToWeaponRef(curWeapon)
                        end
                        equip_weapon_avatar(char)
                    end)
                end
            end

            -- Vehicle skin loop (15s cadence)
            if _timeCount % 15 == 0 then
                pcall(applyVehicleSkinInGame)
            end
        end
    end)                                    -- ← closes pcall(function()
    if _ticker and _ticker.AddTimerOnce then
        _ticker.AddTimerOnce(1.0, fastApplyLoop)
    end
end                                         -- ← closes fastApplyLoop
        
        local function mediumLoop()
    pcall(function()
        if isInGamePlay() then
            local char = getLocalChar()
            if char and not _S.matchTimer then
                bootstrapMatch(char)
            end
            
            -- ★ THROTTLE HEAVY OPS
            local now = os.clock()
            if (now - (_G._lastMediumTick or 0)) > 2.0 then -- Max once every 2s
                _G._lastMediumTick = now
                pcall(tickEliminationKingEffect)
                pcall(applyVehicleChassisLight)
            end
        end
    end)
    if _ticker and _ticker.AddTimerOnce then
        _ticker.AddTimerOnce(2.5, mediumLoop)
    end
end
        
        local function slowLoop()
            pcall(function()
                if isInGamePlay() then
                    pcall(syncVehicleAvatarSkinList)
                end
                pcall(_G.AddOutfitTryFlushSave)
            end)
            if _ticker and _ticker.AddTimerOnce then
                _ticker.AddTimerOnce(5.0, slowLoop)
            end
        end
        
        -- Start all loops
        if _ticker and _ticker.AddTimerOnce then
            _ticker.AddTimerOnce(0.5, fastApplyLoop)
            _ticker.AddTimerOnce(1.0, mediumLoop)
            _ticker.AddTimerOnce(2.0, slowLoop)
        end

        -- Game status change detection via polling (cheaper than hooking events)
        local _lastGameStatus = ""
        local function statusPollLoop()
            local currentStatus = ""
            if isInLobby() then currentStatus = "lobby"
            elseif isInGamePlay() then currentStatus = "gameplay"
            else currentStatus = "other" end
            
            if currentStatus ~= _lastGameStatus then
                _lastGameStatus = currentStatus
                -- Status changed, run post-switch logic
                stopMatchWatcher()
                _S.bootstrapNotified = false
                _S.matchOutfitDone = false
                _S.lobbyApplied = false
                _G._lava_fke_triggered = nil
                pcall(function()
                    if isInLobby() then 
                        snapshotLobbyWear()
                        later(2.0, reapplyLobbyEquipped)
                    end
                end)
                pcall(function()
                    if isInGamePlay() then
                        local char = getLocalChar()
                        if char then bootstrapMatch(char) end
                    end
                end)
                pcall(_AutoSaveOutfit, true)
            end
            
            if _ticker and _ticker.AddTimerOnce then
                _ticker.AddTimerOnce(3.0, statusPollLoop)
            end
        end
        
        if _ticker and _ticker.AddTimerOnce then
            _ticker.AddTimerOnce(1.0, statusPollLoop)
        end


        end -- initHooks

        local function prewarmModules()
            local mods = {
                "client.logic.armory.logic_armory",
                "client.slua.logic.wardrobe.fashionbag.fashionbag_data",
                "client.logic.lobby.hall_theme_utils",
                "client.slua.logic.wardrobe.logic_wardrobe_gun",
                "client.slua.logic.wardrobe.wardrobe_data",
                "client.network.Protocol.WardRobeHandler",
                "client.slua.logic.wardrobe.logic_wardrobe_avatar",
                "client.slua.logic.wardrobe.fashionbag.wardrobe_fashion_utils",
                "client.logic.data.AvatarData",
                "client.slua.logic.XSuit.logic_xsuit",
                "client.slua.logic.wardrobe.logic_wardrobe_new",
                "client.slua.logic.wardrobe.logic_display_setting",
                "client.logic.avatar.logic_team_avatar_manager",
                "client.slua.logic.wardrobe.logic_wardrobe_data_center",
                "client.slua.logic.wardrobe.WardrobeDataEntity",
                "client.slua.umg.Wardrobe.subtab_item_list_base",
                "client.slua.logic.wardrobe.tab_surveillance",
                "client.network.comm.NetManager",
                "client.slua.umg.Wardrobe.wardrobe_macro",
                "client.slua.logic.avatar.avatar_common",
                "client.slua.logic.lobby.Main.Lobby_Main_Control",
                "common.time_ticker",
                "GameLua.GameCore.Module.Subsystem.SubsystemMgr",
                "GameLua.Mod.BaseMod.GamePlay.Backpack.BackpackUtils",
                "GameLua.Mod.Library.GamePlay.Avatar.AvatarDataUtil",
                "GameLua.Activity.Commercialize.GamePlay.CommerAvatarDataUtil",
            }
            for _, m in ipairs(mods) do
                pcall(require, m)
            end
        end

        prewarmModules()
        initHooks()

            log("AddOutfit Merged loaded")
    notify("السكربت جاهز")
_G.matchApplyOutfit      = matchApplyOutfit
_G.matchApplyEquipSkins  = matchApplyEquipSkins
_G.matchApplyWeaponSkin  = matchApplyWeaponSkin
_G.applySkinToWeaponRef  = applySkinToWeaponRef
_G._S                    = _S                              -- ← YE LINE ADD KARO
end)
if not _ao_ok then
    print("[AddOutfit] LOAD ERROR:", tostring(_ao_err))
end
    
    


---- ═══════════════════════════════════════════════════════════════════════════
-- PROFILE CUSTOMIZATION UNLOCK — STANDALONE DROP-IN
-- Paste at END of any Lua file. Auto-boots. Self-contained.
-- Unlocks: Avatar, AvatarBox, Nickname, Chat, TeamSkin, CarteFrame,
--          Alias, NameFrame(Brand), RoleInfoBG, Opening, SocialCardBG
-- ═══════════════════════════════════════════════════════════════════════════
-- SAFE: Uses pcall everywhere. Missing modules = no crash, feature skips.
-- CONFIG: _G.DX_Settings.UnlockProfileCustom = true  (auto-created)
-- ═══════════════════════════════════════════════════════════════════════════

_G.DX_Settings = _G.DX_Settings or {}
if _G.DX_Settings.UnlockProfileCustom == nil then
    _G.DX_Settings.UnlockProfileCustom = true
end

_G.DX_TimerGuards = _G.DX_TimerGuards or {}

-- ───────────────────────────────────────────────────────────────────────────
-- TICKER BRIDGE (fallback if game has no common.time_ticker)
-- ───────────────────────────────────────────────────────────────────────────
if not _G.Mytimer_ticker then
    pcall(function()
        local tt = require("common.time_ticker")
        if tt and tt.AddTimerOnce then
            _G.Mytimer_ticker = {
                AddTimer     = function(d, fn) return tt.AddTimerOnce(d, fn) end,
                AddTimerOnce = function(d, fn) return tt.AddTimerOnce(d, fn) end,
                AddTimerLoop = function(d, fn, n, p)
                    if tt.AddTimerLoop then return tt.AddTimerLoop(d, fn, n, p) end
                    return nil
                end,
            }
        end
    end)
end

-- ───────────────────────────────────────────────────────────────────────────
-- MAIN INSTALLER
-- ───────────────────────────────────────────────────────────────────────────
_G.NTHUY2004_InstallProfileCustomUnlock = function()

    if not (_G.DX_Settings and _G.DX_Settings.UnlockProfileCustom == true) then
        return false
    end
    if _G.NTHUY2004_ProfileCustomUnlockVer and _G.NTHUY2004_ProfileCustomUnlockVer >= 9 then
        return true
    end

    local F = _G.AddOutfit
    _G.NTHUY2004_ProfileCustomEquip = _G.NTHUY2004_ProfileCustomEquip or {}

    pcall(function()
        if type(F) == "table" then
            if F.persistLoadFromDisk            then F.persistLoadFromDisk() end
            if F.applyProfileCustomFromPersist  then F.applyProfileCustomFromPersist() end
        end
    end)

    local PCU_PFX = "__nth_pc9_"
    local _nthBrandApplying = false

    -- ────────────────────────────────────────────────────────────────────────
    -- HELPERS
    -- ────────────────────────────────────────────────────────────────────────
    local function wrapStatic(tbl, name, wrapper)
        if not tbl or type(tbl[name]) ~= "function" then return false end
        if not tbl[PCU_PFX .. name] then
            tbl[PCU_PFX .. name] = tbl[name]
        end
        tbl[name] = wrapper(tbl[PCU_PFX .. name])
        return true
    end
    local function wrapMod(mod, name, wrapper)
        return wrapStatic(mod, name, wrapper)
    end

    local function unlockShowList(list)
        if not list then return end
        for _, data in ipairs(list) do
            data.bIsLock = false
            data.bLock = false
            if data.SubList then
                for _, v in pairs(data.SubList) do
                    v.bIsLock = false
                    v.bLock = false
                end
            end
        end
    end

    local function getLobbyMod(key)
        local mod = nil
        pcall(function()
            if ModuleManager and ModuleManager.GetModule and ModuleManager.LobbyModuleConfig then
                mod = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig[key])
            end
        end)
        return mod
    end

    -- ────────────────────────────────────────────────────────────────────────
    -- FILL LIST UNLOCK DATA
    -- ────────────────────────────────────────────────────────────────────────
    local function fillUnlockHeadList(list)
        list = list or {}
        pcall(function()
            local cfg = CDataTable.GetTable("Headportrait")
            if not cfg then return end
            for k, row in pairs(cfg) do
                local id = tostring(row.ID or k)
                if CDataTable.GetTableData("Headportrait", tonumber(id)) then
                    list[id] = 1
                end
            end
        end)
        return list
    end

    local function fillUnlockFrameList(list)
        list = list or {}
        pcall(function()
            local cfg = CDataTable.GetTable("AvatarFrame")
            if not cfg then return end
            for k, row in pairs(cfg) do
                local id = tonumber(row.ID or k)
                if id and CDataTable.GetTableData("AvatarFrame", id) then
                    list[id] = { expire_time = 0 }
                end
            end
        end)
        return list
    end

    local NAME_FRAME_SUBTYPE = 2901

    local function unlockAllNameFrames()
        if not DataMgr or not DataMgr.roleData then return end
        DataMgr.roleData.nameFrameData = DataMgr.roleData.nameFrameData or {}
        pcall(function()
            local ok, itemMacros = pcall(require, "common.macros.item_macros")
            if ok and itemMacros and itemMacros.ENUM_ITEM_SUBTYPE and itemMacros.ENUM_ITEM_SUBTYPE.Name_Tag_Frame then
                NAME_FRAME_SUBTYPE = itemMacros.ENUM_ITEM_SUBTYPE.Name_Tag_Frame
            end
        end)
        pcall(function()
            local cfg = CDataTable.GetTable("Item")
            if not cfg then return end
            for id, row in pairs(cfg) do
                local sub = row.itemSubType or row.ItemSubType or row.SubType
                if tonumber(sub) == NAME_FRAME_SUBTYPE then
                    local numId = tonumber(id)
                    if numId then
                        DataMgr.roleData.nameFrameData[numId] = { is_used = 0, expire_ts = 0 }
                    end
                end
            end
        end)
    end

    local function fillUnlockTeamSkinList(skin_list)
        skin_list = skin_list or {}
        pcall(function()
            local cfg = CDataTable.GetTable("TeamUpPopFrame")
            for id, _ in pairs(cfg or {}) do
                local numId = tonumber(id)
                if numId then
                    skin_list[numId] = skin_list[numId] or { expire_time = 0 }
                end
            end
        end)
        return skin_list
    end

    local function fillUnlockCarteActiveList(active_list)
        active_list = active_list or {}
        pcall(function()
            local cfg = CDataTable.GetTable("CarteFrameConfig")
            for _, row in pairs(cfg or {}) do
                local id = tonumber(row.SkinID or row.ID)
                if id then
                    active_list[id] = active_list[id] or { expire_ts = 0 }
                end
            end
        end)
        return active_list
    end

    local function fillUnlockAliasList(list)
        list = list or {}
        local ENUM = { notHave = 0, have = 1, use = 2 }
        pcall(function()
            local AliasSys = require("client.slua.logic.roleInfo.logic_roleinfo_title")
            if AliasSys and AliasSys.enum_Alias_State_Type then
                ENUM = AliasSys.enum_Alias_State_Type
            end
            local TimeUtil = require("client.common.time_util")
            local now = (TimeUtil.GetServerTimeInSec and TimeUtil.GetServerTimeInSec()) or 0
            local cfg = CDataTable.GetTable("AliasCfg")
            for id, row in pairs(cfg or {}) do
                local numId = tonumber(id) or tonumber(row and row.ID)
                if numId then
                    if not list[numId] then
                        list[numId] = {
                            state        = ENUM.have,
                            receive_time = now,
                            expire_ts    = 0,
                            rank         = 0,
                            ext_info     = "",
                            rank_id      = 0,
                            title        = (row and row.AliasName) or "",
                            nation       = "",
                            have_used    = 0,
                        }
                    elseif list[numId].state == ENUM.notHave then
                        list[numId].state = ENUM.have
                    end
                end
            end
        end)
        local saved = _G.NTHUY2004_ProfileCustomEquip and tonumber(_G.NTHUY2004_ProfileCustomEquip.alias)
        if saved and saved > 0 then
            pcall(function()
                local AliasSys = require("client.slua.logic.roleInfo.logic_roleinfo_title")
                local ENUM = AliasSys.enum_Alias_State_Type
                for _, v in pairs(list) do
                    if type(v) == "table" and v.state == ENUM.use then
                        v.state = ENUM.have
                    end
                end
                if list[saved] then list[saved].state = ENUM.use end
            end)
        end
        return list
    end

    -- ────────────────────────────────────────────────────────────────────────
    -- APPLY SAVED EQUIP HELPERS
    -- ────────────────────────────────────────────────────────────────────────
    local function applySavedAlias(id)
        id = tonumber(id)
        if not id or id <= 0 then return end
        if not DataMgr or not DataMgr.roleData then return end
        DataMgr.roleData.alias = DataMgr.roleData.alias or {}
        DataMgr.roleData.alias.id = id
        pcall(function()
            if FuncUtil and FuncUtil.Gen_title then
                DataMgr.roleData.alias.title = FuncUtil.Gen_title(id, 0, "", 0)
            else
                local cfg = CDataTable.GetTableData("AliasCfg", id)
                DataMgr.roleData.alias.title = cfg and cfg.AliasName or ""
            end
        end)
    end

    local function markAliasUsedInList(id)
        id = tonumber(id)
        if not id or id <= 0 then return end
        pcall(function()
            local AliasSys = require("client.slua.logic.roleInfo.logic_roleinfo_title")
            local ENUM = AliasSys.enum_Alias_State_Type
            local alist = AliasSys.alias_list_info
            if type(alist) ~= "table" then return end
            for _, v in pairs(alist) do
                if type(v) == "table" and v.state == ENUM.use then
                    v.state = ENUM.have
                end
            end
            if alist[id] then alist[id].state = ENUM.use end
        end)
    end

    local function applySavedRoleInfoBg(id)
        id = tonumber(id)
        if not id or id <= 0 then return end
        pcall(function()
            local bg = getLobbyMod("logic_roleInfo_background")
            if bg then
                if bg.SetCurrentRoleInfoBGID then bg:SetCurrentRoleInfoBGID(id)
                elseif bg.on_notify_social_info_bg then bg:on_notify_social_info_bg(id) end
            end
        end)
    end

    local function applySavedOpening(id)
        id = tonumber(id)
        if not id or id <= 0 then return end
        pcall(function()
            local op = getLobbyMod("logic_roleInfo_opening")
            if op then
                if op.SetCurrentOpeningItemID then op:SetCurrentOpeningItemID(id) end
                if op.on_notify_social_info_bg then op:on_notify_social_info_bg(id) end
            end
        end)
    end

    local function applySavedSocialCardBg(id)
        id = tonumber(id)
        if not id or id <= 0 then return end
        pcall(function()
            local sc = getLobbyMod("logic_social_card_bg")
            if sc then
                sc.CurrentSocialCardBGID = id
                if sc.on_notify_social_card_floor then sc:on_notify_social_card_floor(id) end
            end
            local scStatic = require("client.slua.logic.lobby.Left.logic_social_card_bg")
            if scStatic then scStatic.CurrentSocialCardBGID = id end
        end)
    end

    local function applyRoleDataEquip()
        local E = _G.NTHUY2004_ProfileCustomEquip
        if not E or not DataMgr or not DataMgr.roleData then return end
        if E.avatar       then DataMgr.roleData.headIconUrl             = tostring(E.avatar) end
        if E.avatarBox    then DataMgr.roleData.cur_avatar_box_id       = tonumber(E.avatarBox) end
        if E.nickname     then DataMgr.roleData.friend_nickname_skin    = E.nickname end
        if E.chat         then DataMgr.roleData.chat_bubble             = E.chat end
        if E.teamSkin     then DataMgr.roleData.cur_team_notify_skin_id = E.teamSkin end
        if E.alias        then applySavedAlias(E.alias) end
        if E.roleInfoBg   then applySavedRoleInfoBg(E.roleInfoBg) end
        if E.opening      then applySavedOpening(E.opening) end
        if E.socialCardBg then applySavedSocialCardBg(E.socialCardBg) end
    end

    local function syncLocalProfileEquip()
        local E = _G.NTHUY2004_ProfileCustomEquip
        if not E or not DataMgr or not DataMgr.roleData or not DataMgr.roleData.uid then return end
        local uid = tonumber(DataMgr.roleData.uid)
        pcall(function()
            local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
            if logic_profile then
                local profile = logic_profile:GetLocalProfile(uid) or logic_profile:GetLocalProfile(uid, true)
                if not profile then
                    profile = logic_profile.dicFriend and logic_profile.dicFriend[uid]
                end
                if profile then
                    if E.avatar then
                        profile.picUrl      = tostring(E.avatar)
                        profile.headIconUrl = tostring(E.avatar)
                    end
                    if E.avatarBox then profile.cur_avatar_box_id       = tonumber(E.avatarBox) end
                    if E.nickname  then profile.friend_nickname_skin    = E.nickname end
                    if E.chat      then profile.chat_bubble             = E.chat end
                    if E.teamSkin  then profile.cur_team_notify_skin_id = E.teamSkin end
                    if E.brand and tonumber(E.brand) > 0 then profile.brand_id = E.brand end
                    if E.alias and tonumber(E.alias) > 0 then
                        profile.alias    = profile.alias or {}
                        profile.alias.id = tonumber(E.alias)
                        profile.alias_id = tonumber(E.alias)
                        if DataMgr.roleData.alias and DataMgr.roleData.alias.title then
                            profile.alias.title = DataMgr.roleData.alias.title
                            profile.alias_title = DataMgr.roleData.alias.title
                        end
                    end
                    if E.roleInfoBg and tonumber(E.roleInfoBg) > 0 then
                        profile.social_card = profile.social_card or {}
                        profile.social_card.social_info_bg = profile.social_card.social_info_bg or {}
                        pcall(function()
                            if ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.RoleInfoBG then
                                profile.social_card.social_info_bg[ENUM_ITEM_SUBTYPE.RoleInfoBG] = tonumber(E.roleInfoBg)
                            end
                        end)
                    end
                end
            end
            local TeamUpNewSystem = require("client.slua.logic.teamup.logic_team_up")
            if TeamUpNewSystem and TeamUpNewSystem.GetMemberInfo then
                local memberInfo = TeamUpNewSystem.GetMemberInfo(uid)
                if memberInfo and E.brand and tonumber(E.brand) > 0 then
                    memberInfo.brand_id = E.brand
                end
            end
            local SocialCardSystem = require("client.slua.logic.lobby.Left.logic_social_card")
            if SocialCardSystem and SocialCardSystem.SocialCard and E.carteFrame then
                SocialCardSystem.SocialCard.carte_frame_equip_id = E.carteFrame
            end
        end)
    end

    local function postEquipRefreshEvents()
        local E = _G.NTHUY2004_ProfileCustomEquip
        pcall(function()
            if not EventSystem then return end
            if EVENTTYPE_LOBBY and EVENTID_UPDATE_LOBBY_AVATAR then
                EventSystem:postEvent(EVENTTYPE_LOBBY, EVENTID_UPDATE_LOBBY_AVATAR)
            end
            if EVENTTYPE_ROLEINFO then
                if EVENTID_ROLEINFO_UPDATE_HEAD_INFO then
                    local url = DataMgr and DataMgr.roleData and DataMgr.roleData.headIconUrl
                    EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_HEAD_INFO, url)
                end
                if EVENTID_ROLEINFO_UPDATE_AVATAR_FRAME_INFO then
                    EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_AVATAR_FRAME_INFO)
                end
                if EVENTID_ROLEINFO_NICKNAME_FRAME_UPDATE then
                    EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_NICKNAME_FRAME_UPDATE)
                end
                if EVENTID_ROLEINFO_CHAT_FRAME_UPDATE then
                    EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_CHAT_FRAME_UPDATE)
                end
                if EVENTID_ROLEINFO_UPDATE_TEAMUPFRAME then
                    EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_TEAMUPFRAME)
                end
                if EVENTID_ROLEINFO_CARTE_FRAME_UPDATE then
                    EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_CARTE_FRAME_UPDATE)
                end
                if EVENTID_ROLEINFO_USE_NAME_FRAME and E and E.brand then
                    EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_USE_NAME_FRAME, E.brand)
                end
                if EVENTID_ROLEINFO_UPDATE_ROLEINFO then
                    EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_ROLEINFO)
                end
                if EVENTID_ROLEINFO_BACKGROUND_UPDATE and E and E.roleInfoBg then
                    EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_BACKGROUND_UPDATE)
                end
                if EVENTID_ROLEINFO_OPENING_UPDATE and E and E.opening then
                    EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_OPENING_UPDATE)
                end
                if EVENTID_ROLEINFO_SOCIAL_CARD_UPDATE and E and E.socialCardBg then
                    EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_SOCIAL_CARD_UPDATE)
                end
            end
        end)
    end

    -- ────────────────────────────────────────────────────────────────────────
    -- BRAND (NAME FRAME) REAPPLY
    -- ────────────────────────────────────────────────────────────────────────
    local function reapplySavedBrand()
        local E = _G.NTHUY2004_ProfileCustomEquip
        if not E or not DataMgr or not DataMgr.roleData then return end
        local id = tonumber(E.brand)
        if not id or id <= 0 then return end
        _nthBrandApplying = true
        pcall(function()
            unlockAllNameFrames()
            DataMgr.roleData.nameFrameData = DataMgr.roleData.nameFrameData or {}
            DataMgr.roleData.nameFrameData[id] = { is_used = 0, expire_ts = 0 }
            if DataMgr.ResetNameFrame then DataMgr.ResetNameFrame() end
            if DataMgr.UseNameFrame   then DataMgr.UseNameFrame(id) end
            for k, v in pairs(DataMgr.roleData.nameFrameData) do
                if type(v) == "table" then
                    v.is_used = (tonumber(k) == id) and 1 or 0
                end
            end
            local RNFS = require("client.slua.logic.person_space.logic_roleinfo_nameframe")
            RNFS.nUsedID = id
            local TeamUpNewSystem = require("client.slua.logic.teamup.logic_team_up")
            if TeamUpNewSystem and TeamUpNewSystem.GetMemberInfo then
                local memberInfo = TeamUpNewSystem.GetMemberInfo(DataMgr.roleData.uid)
                if memberInfo then memberInfo.brand_id = id end
            end
            if EventSystem and EVENTTYPE_ROLEINFO and EVENTID_ROLEINFO_USE_NAME_FRAME then
                EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_USE_NAME_FRAME, id)
            end
        end)
        _nthBrandApplying = false
    end

    local function reapplySavedAlias()
        local E = _G.NTHUY2004_ProfileCustomEquip
        if not E or not E.alias then return end
        applySavedAlias(E.alias)
        markAliasUsedInList(E.alias)
    end

    -- ────────────────────────────────────────────────────────────────────────
    -- FORCE REAPPLY
    -- ────────────────────────────────────────────────────────────────────────
    local _nthReapplying = false

    local function shouldReapplyProfileCustom()
        if not (_G.DX_Settings and _G.DX_Settings.UnlockProfileCustom == true) then
            return false
        end
        local ok = true
        pcall(function()
            if GameStatus and GameStatus.IsInFightingStatus then
                if GameStatus.IsInFightingStatus() then ok = false end
            end
        end)
        return ok
    end

    local function forceReapplyAll(force)
        if not force and not shouldReapplyProfileCustom() then return end
        if _nthReapplying then return end
        _nthReapplying = true
        pcall(function()
            applyRoleDataEquip()
            syncLocalProfileEquip()
            reapplySavedEquip()
            reapplySavedBrand()
            reapplySavedAlias()
            postEquipRefreshEvents()
            pcall(function()
                if type(F) == "table" then
                    if F.invalidateLobbyResolved then F.invalidateLobbyResolved() end
                    if F.patchSelfWearCache      then F.patchSelfWearCache(true) end
                end
            end)
        end)
        _nthReapplying = false
    end

    local function patchProfilePayload(data)
        local E = _G.NTHUY2004_ProfileCustomEquip
        if not E or not data or type(data) ~= "table" then return data end
        if E.avatar    then data.picUrl                 = tostring(E.avatar) end
        if E.avatarBox then data.cur_avatar_box_id      = tonumber(E.avatarBox) end
        if E.nickname  then data.friend_nickname_skin   = E.nickname end
        if E.chat      then data.chat_bubble            = E.chat end
        if E.brand and tonumber(E.brand) > 0 then data.brand_id = E.brand end
        if E.alias and tonumber(E.alias) > 0 then
            data.alias    = data.alias or {}
            data.alias.id = tonumber(E.alias)
            data.alias_id = tonumber(E.alias)
            if DataMgr and DataMgr.roleData and DataMgr.roleData.alias then
                data.alias.title = DataMgr.roleData.alias.title
                data.alias_title = DataMgr.roleData.alias.title
            end
        end
        if E.roleInfoBg and tonumber(E.roleInfoBg) > 0 then
            data.social_card = data.social_card or {}
            data.social_card.social_info_bg = data.social_card.social_info_bg or {}
            pcall(function()
                if ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.RoleInfoBG then
                    data.social_card.social_info_bg[ENUM_ITEM_SUBTYPE.RoleInfoBG] = tonumber(E.roleInfoBg)
                end
            end)
        end
        return data
    end

    local function saveEquip(key, val)
        if val == nil then return end
        _G.NTHUY2004_ProfileCustomEquip[key] = val
        applyRoleDataEquip()
        syncLocalProfileEquip()
        postEquipRefreshEvents()
        pcall(function()
            if type(F) == "table" and F.persistProfileCustomSave then
                F.persistProfileCustomSave()
            end
        end)
    end

    -- ────────────────────────────────────────────────────────────────────────
    -- REAPPLY SAVED EQUIP (ALL CATEGORIES)
    -- ────────────────────────────────────────────────────────────────────────
    local function reapplySavedEquip()
        local E = _G.NTHUY2004_ProfileCustomEquip
        if not E then return end
        applyRoleDataEquip()
        pcall(function()
            if E.avatar then
                local RAS = require("client.slua.logic.roleInfo.logic_roleInfo_Avatar")
                RAS.HeadportraitList = RAS.HeadportraitList or {}
                RAS.HeadportraitList[tostring(E.avatar)] = 1
                if DataMgr and DataMgr.UpdateHeadIconUrl then
                    DataMgr.UpdateHeadIconUrl(E.avatar)
                end
            end
            if E.avatarBox then
                local RAF = require("client.slua.logic.roleInfo.logic_RoleInfoAvatarFrame")
                RAF.AvatarFrameList = RAF.AvatarFrameList or {}
                RAF.AvatarFrameList[tonumber(E.avatarBox)] = { expire_time = 0 }
                if RAF.UpdateCurAvatarBoxID then
                    RAF.UpdateCurAvatarBoxID(E.avatarBox)
                end
            end
            if E.nickname and DataMgr and DataMgr.roleData then
                DataMgr.roleData.friend_nickname_skin = E.nickname
                local nick = getLobbyMod("logic_roleInfo_nicknameframe")
                if nick then
                    nick.unlockData = nick.unlockData or {}
                    nick.unlockData[E.nickname] = { expire_ts = 0 }
                    if nick.ProcChangeRsp then nick:ProcChangeRsp(E.nickname) end
                end
            end
            if E.chat and DataMgr and DataMgr.roleData then
                DataMgr.roleData.chat_bubble = E.chat
                local chat = getLobbyMod("logic_roleInfo_chatframe")
                if chat then
                    chat.unlockData = chat.unlockData or {}
                    chat.unlockData[E.chat] = { expire_ts = 0 }
                    if chat.ProcChangeRsp then chat:ProcChangeRsp(E.chat) end
                end
            end
            if E.teamSkin and DataMgr and DataMgr.roleData then
                DataMgr.roleData.cur_team_notify_skin_id = E.teamSkin
                local team = getLobbyMod("logic_roleInfo_TeamUpFrame")
                if team and team.on_change_team_notify_skin_rsp then
                    team:on_change_team_notify_skin_rsp(0, E.teamSkin)
                end
            end
            if E.carteFrame then
                local carte = getLobbyMod("logic_roleinfo_carte_frame")
                if carte and carte.equip_carte_frame_rsp then
                    carte:equip_carte_frame_rsp(0, E.carteFrame, true)
                end
            end
            if E.alias then
                applySavedAlias(E.alias)
                markAliasUsedInList(E.alias)
            end
            if E.roleInfoBg   then applySavedRoleInfoBg(E.roleInfoBg) end
            if E.opening      then applySavedOpening(E.opening) end
            if E.socialCardBg then applySavedSocialCardBg(E.socialCardBg) end
            reapplySavedBrand()
        end)
        syncLocalProfileEquip()
    end

    local function injectPersonalDepot(resID)
        resID = tonumber(resID)
        if not resID or resID <= 0 then return end
        pcall(function()
            if _G.NTHUY2004_AddDumpSkinToDepot then
                _G.NTHUY2004_AddDumpSkinToDepot(resID)
            elseif type(F) == "table" and F.injectDumpItem then
                F.injectDumpItem(resID)
            end
        end)
    end

    local function isProfilePersonalResID(resID)
        resID = tonumber(resID)
        if not resID then return false end
        local ok = false
        pcall(function()
            if CDataTable.GetTableData("RoleInfoBackgroundCfg", resID) then ok = true end
            if CDataTable.GetTableData("PersonalOpeningCfg",    resID) then ok = true end
            if CDataTable.GetTableData("SocialCardBGInfo",      resID) then ok = true end
        end)
        return ok
    end

    local function afterUnlockProc(orig)
        return function(self, ...)
            local ret = orig(self, ...)
            unlockShowList(self.showDataList)
            if self.CarteFrameMap then
                for _, v in pairs(self.CarteFrameMap) do
                    v.bLock     = false
                    v.expire_ts = 0
                end
            end
            return ret
        end
    end

    -- ════════════════════════════════════════════════════════════════════════
    -- PATCH: AVATAR + FRAME
    -- ════════════════════════════════════════════════════════════════════════
    pcall(function()
        local RAS = require("client.slua.logic.roleInfo.logic_roleInfo_Avatar")
        local RAF = require("client.slua.logic.roleInfo.logic_RoleInfoAvatarFrame")

        wrapStatic(RAS, "HasAvatar",          function(old) return function() return true end end)
        wrapStatic(RAS, "HasOwnHeadPortrait", function(old) return function() return true end end)
        wrapStatic(RAS, "get_user_avatar_list_rsp", function(orig)
            return function(ok, list, headportraiturl)
                if ok ~= 0 then ok = 0 end
                list = fillUnlockHeadList(list or {})
                local saved = _G.NTHUY2004_ProfileCustomEquip.avatar
                if saved then headportraiturl = saved end
                local ret = orig(ok, list, headportraiturl)
                RAS.HeadportraitList = fillUnlockHeadList(RAS.HeadportraitList or {})
                if saved and DataMgr and DataMgr.UpdateHeadIconUrl then
                    DataMgr.UpdateHeadIconUrl(saved)
                end
                reapplySavedEquip()
                return ret
            end
        end)
        wrapStatic(RAS, "change_user_avatar_rsp", function(orig)
            return function(err_code, item_url, endtime)
                if err_code ~= 0 then err_code = 0; endtime = 1 end
                saveEquip("avatar", item_url)
                return orig(err_code, item_url, endtime)
            end
        end)

        wrapStatic(RAF, "HasAvatarFrame",     function(old) return function() return true end end)
        wrapStatic(RAF, "HasAvatarFrameCond", function(old) return function() return true end end)
        wrapStatic(RAF, "get_avatar_box_list_rsp", function(orig)
            return function(ok, list, cur_avatar_box_id)
                if ok ~= 0 then ok = 0 end
                list = fillUnlockFrameList(list or {})
                local saved = _G.NTHUY2004_ProfileCustomEquip.avatarBox
                if saved then cur_avatar_box_id = saved end
                local ret = orig(ok, list, cur_avatar_box_id)
                RAF.AvatarFrameList = fillUnlockFrameList(RAF.AvatarFrameList or {})
                if saved and RAF.UpdateCurAvatarBoxID then
                    RAF.UpdateCurAvatarBoxID(saved)
                end
                reapplySavedEquip()
                return ret
            end
        end)
        wrapStatic(RAF, "change_avatar_box_rsp", function(orig)
            return function(ok, item_id)
                if ok ~= 0 then ok = 0 end
                saveEquip("avatarBox", item_id)
                return orig(ok, item_id)
            end
        end)
    end)

    -- ════════════════════════════════════════════════════════════════════════
    -- PATCH: NICKNAME EFFECT
    -- ════════════════════════════════════════════════════════════════════════
    pcall(function()
        local nick = getLobbyMod("logic_roleInfo_nicknameframe")
        if nick then
            wrapMod(nick, "HasFrame",       function() return function() return true  end end)
            wrapMod(nick, "IsLocked",       function() return function() return false end end)
            wrapMod(nick, "ProcUnlockData", afterUnlockProc)
            wrapMod(nick, "ProcNicknameListRsp", function(orig)
                return function(self, friend_nickname_skin_data, friend_nickname_skin_cfg)
                    friend_nickname_skin_data = friend_nickname_skin_data or {}
                    friend_nickname_skin_data.skins = friend_nickname_skin_data.skins or {}
                    pcall(function()
                        for id, _ in pairs(friend_nickname_skin_cfg or {}) do
                            friend_nickname_skin_data.skins[id] = { expire_ts = 0 }
                        end
                        local cfg = CDataTable.GetTable("NicknameEffectCfg")
                        for id, _ in pairs(cfg or {}) do
                            friend_nickname_skin_data.skins[id] = { expire_ts = 0 }
                        end
                    end)
                    local saved = _G.NTHUY2004_ProfileCustomEquip.nickname
                    if saved then friend_nickname_skin_data.equip = saved end
                    local ret = orig(self, friend_nickname_skin_data, friend_nickname_skin_cfg)
                    if saved then reapplySavedEquip() end
                    return ret
                end
            end)
            wrapMod(nick, "ProcChangeRsp", function(orig)
                return function(self, skin_id)
                    saveEquip("nickname", skin_id)
                    if self.unlockData then self.unlockData[skin_id] = { expire_ts = 0 } end
                    return orig(self, skin_id)
                end
            end)
        end
    end)

    -- ════════════════════════════════════════════════════════════════════════
    -- PATCH: CHAT BUBBLE
    -- ════════════════════════════════════════════════════════════════════════
    pcall(function()
        local chat = getLobbyMod("logic_roleInfo_chatframe")
        if chat then
            wrapMod(chat, "HasChatBubble",  function() return function() return true  end end)
            wrapMod(chat, "IsLocked",       function() return function() return false end end)
            wrapMod(chat, "ProcUnlockData", afterUnlockProc)
            wrapMod(chat, "ProcChatListRsp", function(orig)
                return function(self, chat_bubble_data, chat_bubble_cfg)
                    chat_bubble_data = chat_bubble_data or {}
                    chat_bubble_data.bubbles = chat_bubble_data.bubbles or {}
                    pcall(function()
                        for id, _ in pairs(chat_bubble_cfg or {}) do
                            chat_bubble_data.bubbles[id] = { expire_ts = 0 }
                        end
                        local cfg = CDataTable.GetTable("ChatEffectCfg")
                        for id, _ in pairs(cfg or {}) do
                            chat_bubble_data.bubbles[id] = { expire_ts = 0 }
                        end
                    end)
                    local saved = _G.NTHUY2004_ProfileCustomEquip.chat
                    if saved then chat_bubble_data.equip = saved end
                    local ret = orig(self, chat_bubble_data, chat_bubble_cfg)
                    if saved then reapplySavedEquip() end
                    return ret
                end
            end)
            wrapMod(chat, "ProcChangeRsp", function(orig)
                return function(self, bubble_id)
                    saveEquip("chat", bubble_id)
                    if self.unlockData then self.unlockData[bubble_id] = { expire_ts = 0 } end
                    return orig(self, bubble_id)
                end
            end)
        end
    end)

    -- ════════════════════════════════════════════════════════════════════════
    -- PATCH: TEAM NOTIFY SKIN
    -- ════════════════════════════════════════════════════════════════════════
    pcall(function()
        local team = getLobbyMod("logic_roleInfo_TeamUpFrame")
        if team then
            wrapMod(team, "HasSkin",   function() return function() return true  end end)
            wrapMod(team, "IsLocked",  function() return function() return false end end)
            wrapMod(team, "GetSkinList", function(orig)
                return function(self)
                    local list = orig(self)
                    unlockShowList(list)
                    for _, v in ipairs(list) do
                        v.bIsLock    = false
                        v.expireTime = 1
                        if v.SubList then
                            for _, sub in pairs(v.SubList) do
                                sub.bIsLock    = false
                                sub.expireTime = 1
                            end
                        end
                    end
                    return list
                end
            end)
            wrapMod(team, "on_get_team_notify_skin_list_rsp", function(orig)
                return function(self, err_code, skin_list, cur_skin_id)
                    if err_code ~= 0 then err_code = 0 end
                    skin_list = fillUnlockTeamSkinList(skin_list)
                    local saved = _G.NTHUY2004_ProfileCustomEquip.teamSkin
                    if saved then cur_skin_id = saved end
                    local ret = orig(self, err_code, skin_list, cur_skin_id)
                    unlockShowList(self:GetSkinList())
                    if saved then reapplySavedEquip() end
                    return ret
                end
            end)
            wrapMod(team, "on_change_team_notify_skin_rsp", function(orig)
                return function(self, err_code, cur_skin_id)
                    if err_code ~= 0 then err_code = 0 end
                    saveEquip("teamSkin", cur_skin_id)
                    return orig(self, err_code, cur_skin_id)
                end
            end)
        end
    end)

    -- ════════════════════════════════════════════════════════════════════════
    -- PATCH: CARTE FRAME
    -- ════════════════════════════════════════════════════════════════════════
    pcall(function()
        local carte = getLobbyMod("logic_roleinfo_carte_frame")
        if carte then
            wrapMod(carte, "HasCarteFrame",       function() return function() return true end end)
            wrapMod(carte, "IsHaveCarteFrame",    function() return function() return true end end)
            wrapMod(carte, "CheckFrameTimeValid", function() return function() return true end end)
            wrapMod(carte, "get_carte_frame_list_rsp", function(orig)
                return function(self, err_code, active_frame_list, equip_frame_id)
                    if err_code ~= 0 then err_code = 0 end
                    if self.InitCarteFrameMap then self:InitCarteFrameMap() end
                    active_frame_list = fillUnlockCarteActiveList(active_frame_list)
                    if self.CarteFrameMap then
                        for id, _ in pairs(self.CarteFrameMap) do
                            self.CarteFrameMap[id].bLock     = false
                            self.CarteFrameMap[id].expire_ts = 0
                        end
                    end
                    local saved = _G.NTHUY2004_ProfileCustomEquip.carteFrame
                    if saved then equip_frame_id = saved end
                    local ret = orig(self, err_code, active_frame_list, equip_frame_id)
                    if saved then reapplySavedEquip() end
                    return ret
                end
            end)
            wrapMod(carte, "equip_carte_frame_rsp", function(orig)
                return function(self, err_code, frame_id, bEquip)
                    if err_code ~= 0 then err_code = 0 end
                    if bEquip then saveEquip("carteFrame", frame_id) end
                    return orig(self, err_code, frame_id, bEquip)
                end
            end)
        end
    end)

    -- ════════════════════════════════════════════════════════════════════════
    -- PATCH: ALIAS / TITLE
    -- ════════════════════════════════════════════════════════════════════════
    pcall(function()
        local AliasSys    = require("client.slua.logic.roleInfo.logic_roleinfo_title")
        local CharHandler = require("client.network.Protocol.CharacterHandler")
        local NetErrorCode_NONE = NetErrorCode_NONE or 0

        wrapStatic(AliasSys, "alias_list_res", function(orig)
            return function(res, list, red_point, alias)
                if res ~= NetErrorCode_NONE then res = NetErrorCode_NONE end
                list = fillUnlockAliasList(list)
                local saved = _G.NTHUY2004_ProfileCustomEquip and tonumber(_G.NTHUY2004_ProfileCustomEquip.alias)
                if saved and saved > 0 then
                    alias = alias or {}
                    alias.id = saved
                end
                local ret = orig(res, list, red_point, alias)
                if saved then applySavedAlias(saved) end
                return ret
            end
        end)
        wrapStatic(AliasSys, "change_alias_req", function(orig)
            return function(id, state)
                id = tonumber(id)
                if id and id > 0 then
                    saveEquip("alias", id)
                    applySavedAlias(id)
                    markAliasUsedInList(id)
                    pcall(function() AliasSys.change_alias_rsp(0, id, 0) end)
                    return
                end
                return orig(id, state)
            end
        end)
        wrapStatic(CharHandler, "send_change_alias_req", function(orig)
            return function(id, state)
                id = tonumber(id)
                if id and id > 0 then
                    saveEquip("alias", id)
                    applySavedAlias(id)
                    markAliasUsedInList(id)
                    pcall(function() AliasSys.change_alias_rsp(0, id, 0) end)
                    return
                end
                return orig(id, state)
            end
        end)
        wrapStatic(CharHandler, "on_alias_list_res", function(orig)
            return function(res, list, red_point, alias)
                if res ~= NetErrorCode_NONE then res = NetErrorCode_NONE end
                list = fillUnlockAliasList(list)
                local saved = _G.NTHUY2004_ProfileCustomEquip and tonumber(_G.NTHUY2004_ProfileCustomEquip.alias)
                if saved and saved > 0 then
                    alias = alias or {}
                    alias.id = saved
                end
                return orig(res, list, red_point, alias)
            end
        end)
        wrapStatic(CharHandler, "on_change_alias_rsp", function(orig)
            return function(res, id, rank_id)
                id = tonumber(id)
                if id and id > 0 then
                    if res ~= 0 then res = 0 end
                    saveEquip("alias", id)
                    applySavedAlias(id)
                    markAliasUsedInList(id)
                end
                return orig(res, id, rank_id)
            end
        end)
    end)

    -- ════════════════════════════════════════════════════════════════════════
    -- PATCH: ROLE INFO BG + OPENING + SOCIAL CARD BG
    -- ════════════════════════════════════════════════════════════════════════
    pcall(function()
        local RGBHandler  = require("client.network.Protocol.RoleInfoBGHandler")
        local SCBGHandler = require("client.network.Protocol.SocialCardBGHandler")
        local bg          = getLobbyMod("logic_roleInfo_background")
        local opening     = getLobbyMod("logic_roleInfo_opening")
        local socialBg    = getLobbyMod("logic_social_card_bg")

        if bg then
            wrapMod(bg, "IsHaveRoleInfoBG", function() return function() return true end end)
            wrapMod(bg, "send_set_social_info_bg_req", function(orig)
                return function(self, roleInfoBGID)
                    roleInfoBGID = tonumber(roleInfoBGID)
                    if roleInfoBGID and roleInfoBGID > 0 then
                        saveEquip("roleInfoBg", roleInfoBGID)
                        injectPersonalDepot(roleInfoBGID)
                        pcall(function() self:on_set_social_info_bg_rsp(0, roleInfoBGID) end)
                        return
                    end
                    return orig(self, roleInfoBGID)
                end
            end)
            wrapMod(bg, "on_set_social_info_bg_rsp", function(orig)
                return function(self, res, bg_id)
                    if res ~= 0 then res = 0 end
                    if bg_id and tonumber(bg_id) > 0 then saveEquip("roleInfoBg", bg_id) end
                    return orig(self, res, bg_id)
                end
            end)
        end

        if opening then
            wrapMod(opening, "IsHaveOpeningItem", function() return function() return true end end)
            wrapMod(opening, "send_set_social_info_bg_req", function(orig)
                return function(self, openingItemID)
                    openingItemID = tonumber(openingItemID)
                    if openingItemID and openingItemID > 0 then
                        saveEquip("opening", openingItemID)
                        injectPersonalDepot(openingItemID)
                        pcall(function() self:on_set_social_info_bg_rsp(0, openingItemID) end)
                        return
                    end
                    return orig(self, openingItemID)
                end
            end)
            wrapMod(opening, "on_set_social_info_bg_rsp", function(orig)
                return function(self, res, bg_id)
                    if res ~= 0 then res = 0 end
                    if bg_id and tonumber(bg_id) > 0 then saveEquip("opening", bg_id) end
                    return orig(self, res, bg_id)
                end
            end)
        end

        if socialBg then
            wrapMod(socialBg, "IsHaveCardSkin", function() return function() return true end end)
            wrapMod(socialBg, "send_set_social_card_floor_req", function(orig)
                return function(self, social_card_bg_id)
                    social_card_bg_id = tonumber(social_card_bg_id)
                    if social_card_bg_id and social_card_bg_id > 0 then
                        saveEquip("socialCardBg", social_card_bg_id)
                        injectPersonalDepot(social_card_bg_id)
                        pcall(function()
                            self.CurrentSocialCardBGID = social_card_bg_id
                            self:on_notify_social_card_floor(social_card_bg_id)
                            self:on_set_social_card_floor_rsp(0)
                        end)
                        return
                    end
                    return orig(self, social_card_bg_id)
                end
            end)
            wrapMod(socialBg, "on_set_social_card_floor_rsp", function(orig)
                return function(self, ret)
                    if ret ~= 0 then ret = 0 end
                    local id = self.CurrentSocialCardBGID
                        or (_G.NTHUY2004_ProfileCustomEquip and _G.NTHUY2004_ProfileCustomEquip.socialCardBg)
                    if id and tonumber(id) > 0 then saveEquip("socialCardBg", id) end
                    return orig(self, ret)
                end
            end)
        end

        wrapStatic(RGBHandler, "on_notify_social_info_bg", function(orig)
            return function(bg_ids)
                local E = _G.NTHUY2004_ProfileCustomEquip
                if E and type(bg_ids) == "table" then
                    pcall(function()
                        if E.roleInfoBg and ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.RoleInfoBG then
                            bg_ids[ENUM_ITEM_SUBTYPE.RoleInfoBG] = tonumber(E.roleInfoBg)
                        end
                        if E.opening and ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.PersonalOpening then
                            bg_ids[ENUM_ITEM_SUBTYPE.PersonalOpening] = tonumber(E.opening)
                        end
                    end)
                end
                local ret = orig(bg_ids)
                pcall(function()
                    if E then
                        if E.roleInfoBg then applySavedRoleInfoBg(E.roleInfoBg) end
                        if E.opening    then applySavedOpening(E.opening) end
                    end
                end)
                return ret
            end
        end)
        wrapStatic(RGBHandler, "on_set_social_info_bg_rsp", function(orig)
            return function(res, subtype, bg_id)
                if res ~= 0 then res = 0 end
                bg_id = tonumber(bg_id)
                if bg_id and bg_id > 0 then
                    if subtype == ENUM_ITEM_SUBTYPE.RoleInfoBG then
                        saveEquip("roleInfoBg", bg_id)
                    elseif subtype == ENUM_ITEM_SUBTYPE.PersonalOpening then
                        saveEquip("opening", bg_id)
                    end
                end
                return orig(res, subtype, bg_id)
            end
        end)
        wrapStatic(SCBGHandler, "on_notify_social_card_floor", function(orig)
            return function(social_card_floor_id)
                local saved = _G.NTHUY2004_ProfileCustomEquip and tonumber(_G.NTHUY2004_ProfileCustomEquip.socialCardBg)
                if saved and saved > 0 then social_card_floor_id = saved end
                local ret = orig(social_card_floor_id)
                if saved then applySavedSocialCardBg(saved) end
                return ret
            end
        end)
        wrapStatic(SCBGHandler, "on_set_social_card_floor_rsp", function(orig)
            return function(ret)
                if ret ~= 0 then ret = 0 end
                local saved = _G.NTHUY2004_ProfileCustomEquip and tonumber(_G.NTHUY2004_ProfileCustomEquip.socialCardBg)
                if saved then saveEquip("socialCardBg", saved) end
                return orig(ret)
            end
        end)
    end)

    -- ════════════════════════════════════════════════════════════════════════
    -- PATCH: NAMEFRAME / BRAND + DataMgr deep
    -- ════════════════════════════════════════════════════════════════════════
    pcall(function()
        local RNFS = require("client.slua.logic.person_space.logic_roleinfo_nameframe")
        unlockAllNameFrames()
        wrapStatic(RNFS, "IsValidNameFrame", function(old)
            return function(id) return true end
        end)
        wrapStatic(RNFS, "Enter", function(orig)
            return function()
                unlockAllNameFrames()
                local ret = orig()
                reapplySavedEquip()
                return ret
            end
        end)
        wrapStatic(RNFS, "use_brand", function(orig)
            return function(id)
                id = tonumber(id)
                if id and id > 0 then
                    saveEquip("brand", id)
                    pcall(function()
                        unlockAllNameFrames()
                        reapplySavedBrand()
                    end)
                    return
                end
                if orig then return orig(id) end
            end
        end)
        wrapStatic(RNFS, "use_brand_rsp", function(orig)
            return function(res, id)
                id = tonumber(id)
                if id and id > 0 then
                    unlockAllNameFrames()
                    if DataMgr and DataMgr.roleData then
                        DataMgr.roleData.nameFrameData = DataMgr.roleData.nameFrameData or {}
                        DataMgr.roleData.nameFrameData[id] = { is_used = 0, expire_ts = 0 }
                    end
                    if res ~= 0 then res = 0 end
                    saveEquip("brand", id)
                end
                return orig(res, id)
            end
        end)

        if DataMgr then
            wrapStatic(DataMgr, "GetNameFrame", function(orig)
                return function(id)
                    local r = orig(id)
                    if r then return r end
                    if DataMgr.roleData then
                        DataMgr.roleData.nameFrameData = DataMgr.roleData.nameFrameData or {}
                        if not DataMgr.roleData.nameFrameData[id] then
                            DataMgr.roleData.nameFrameData[id] = { is_used = 0, expire_ts = 0 }
                        end
                        return DataMgr.roleData.nameFrameData[id]
                    end
                end
            end)
            wrapStatic(DataMgr, "InitRoleData", function(orig)
                return function(roleDataTb)
                    local savedBrand = _G.NTHUY2004_ProfileCustomEquip and tonumber(_G.NTHUY2004_ProfileCustomEquip.brand)
                    if savedBrand and savedBrand > 0 and roleDataTb then
                        roleDataTb.brand = roleDataTb.brand or {}
                        for k, v in pairs(roleDataTb.brand) do
                            if type(v) == "table" then v.is_used = 0 end
                        end
                        roleDataTb.brand[savedBrand] = { is_used = 1, expire_ts = 0 }
                    end
                    local E = _G.NTHUY2004_ProfileCustomEquip
                    if E and roleDataTb and E.roleInfoBg and tonumber(E.roleInfoBg) > 0 then
                        roleDataTb.social_card = roleDataTb.social_card or {}
                        roleDataTb.social_card.social_info_bg = roleDataTb.social_card.social_info_bg or {}
                        pcall(function()
                            if ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.RoleInfoBG then
                                roleDataTb.social_card.social_info_bg[ENUM_ITEM_SUBTYPE.RoleInfoBG] = tonumber(E.roleInfoBg)
                            end
                        end)
                    end
                    local ret = orig(roleDataTb)
                    unlockAllNameFrames()
                    reapplySavedBrand()
                    forceReapplyAll()
                    return ret
                end
            end)
            wrapStatic(DataMgr, "ResetNameFrame", function(orig)
                return function()
                    local ret = orig()
                    if not _nthBrandApplying then
                        pcall(reapplySavedBrand)
                    end
                    return ret
                end
            end)
            wrapStatic(DataMgr, "UpdateMyRoleProfileData", function(orig)
                return function(data, myRankData, myPassData, myAliasData, corps_alias_info)
                    patchProfilePayload(data)
                    local ret = orig(data, myRankData, myPassData, myAliasData, corps_alias_info)
                    forceReapplyAll()
                    return ret
                end
            end)
            wrapStatic(DataMgr, "UpdateHeadIconUrl", function(orig)
                return function(headIconUrl)
                    local saved = _G.NTHUY2004_ProfileCustomEquip and _G.NTHUY2004_ProfileCustomEquip.avatar
                    if saved then headIconUrl = saved end
                    local ret = orig(headIconUrl)
                    syncLocalProfileEquip()
                    return ret
                end
            end)
            wrapStatic(DataMgr, "UpdateAvatarBoxId", function(orig)
                return function(avatar_box_id)
                    local saved = _G.NTHUY2004_ProfileCustomEquip and _G.NTHUY2004_ProfileCustomEquip.avatarBox
                    if saved then avatar_box_id = saved end
                    local ret = orig(avatar_box_id)
                    syncLocalProfileEquip()
                    return ret
                end
            end)
        end

        pcall(function()
            local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
            if logic_profile then
                wrapMod(logic_profile, "proc_batch_get_bin_profile_rsp", function(orig)
                    return function(self, sendSeq, profileList, hasRankData)
                        if DataMgr and DataMgr.roleData and DataMgr.roleData.uid then
                            local myUid = tostring(DataMgr.roleData.uid)
                            for k, v in pairs(profileList or {}) do
                                if tostring(k) == myUid and type(v) == "table" then
                                    patchProfilePayload(v)
                                end
                            end
                        end
                        local ret = orig(self, sendSeq, profileList, hasRankData)
                        forceReapplyAll()
                        return ret
                    end
                end)
            end
        end)
    end)

    -- ════════════════════════════════════════════════════════════════════════
    -- PATCH: WARDROBE ITEM (Nền hồ sơ / Animation / Social BG)
    -- ════════════════════════════════════════════════════════════════════════
    pcall(function()
        local wd = require("client.slua.logic.wardrobe.wardrobe_data")
        wrapStatic(wd, "GetHallDepotItemDataByResID", function(orig)
            return function(self, resID)
                local r = orig(self, resID)
                if r then return r end
                if isProfilePersonalResID(resID) then
                    return { resID = resID, res_id = resID, expireTS = 0, count = 1, isNew = false }
                end
                return r
            end
        end)
        wrapStatic(wd, "HasItem", function(orig)
            return function(self, resID, forever)
                if orig(self, resID, forever) then return true end
                return isProfilePersonalResID(resID)
            end
        end)
    end)

    -- ════════════════════════════════════════════════════════════════════════
    -- PATCH: EQUIP CLIENT-SIDE (BLOCK SERVER SEND + FAKE RSP)
    -- ════════════════════════════════════════════════════════════════════════
    pcall(function()
        local RAS         = require("client.slua.logic.roleInfo.logic_roleInfo_Avatar")
        local RAF         = require("client.slua.logic.roleInfo.logic_RoleInfoAvatarFrame")
        local RIHandler   = require("client.network.Protocol.RoleInfoHandler")
        local CharHandler = require("client.network.Protocol.CharacterHandler")
        local RGBHandler  = require("client.network.Protocol.RoleInfoBGHandler")
        local SCBGHandler = require("client.network.Protocol.SocialCardBGHandler")

        wrapStatic(CharHandler, "send_change_user_avatar", function()
            return function(item_url)
                saveEquip("avatar", item_url)
                pcall(function()
                    RAS.HeadportraitList = RAS.HeadportraitList or {}
                    RAS.HeadportraitList[tostring(item_url)] = 1
                    RAS.change_user_avatar_rsp(0, item_url, 1)
                end)
            end
        end)
        wrapStatic(CharHandler, "send_change_avatar_box", function()
            return function(item_id)
                item_id = tonumber(item_id)
                saveEquip("avatarBox", item_id)
                pcall(function()
                    RAF.AvatarFrameList = RAF.AvatarFrameList or {}
                    RAF.AvatarFrameList[item_id] = { expire_time = 0 }
                    RAF.change_avatar_box_rsp(0, item_id)
                end)
            end
        end)
        wrapStatic(RIHandler, "send_set_friend_nickname_skin_req", function()
            return function(skin_id)
                saveEquip("nickname", skin_id)
                pcall(function()
                    local nick = getLobbyMod("logic_roleInfo_nicknameframe")
                    if nick then
                        nick.unlockData = nick.unlockData or {}
                        nick.unlockData[skin_id] = { expire_ts = 0 }
                        nick:ProcChangeRsp(skin_id)
                    end
                end)
            end
        end)
        wrapStatic(RIHandler, "send_set_chat_bubble_req", function()
            return function(bubble_id)
                saveEquip("chat", bubble_id)
                pcall(function()
                    local chat = getLobbyMod("logic_roleInfo_chatframe")
                    if chat then
                        chat.unlockData = chat.unlockData or {}
                        chat.unlockData[bubble_id] = { expire_ts = 0 }
                        chat:ProcChangeRsp(bubble_id)
                    end
                end)
            end
        end)
        wrapStatic(RIHandler, "send_change_team_notify_skin", function()
            return function(item_id)
                saveEquip("teamSkin", item_id)
                pcall(function()
                    local team = getLobbyMod("logic_roleInfo_TeamUpFrame")
                    if team then team:on_change_team_notify_skin_rsp(0, item_id) end
                end)
            end
        end)
        wrapStatic(RIHandler, "send_equip_carte_frame_req", function()
            return function(frame_id, bEquip)
                if bEquip then saveEquip("carteFrame", frame_id) end
                pcall(function()
                    local carte = getLobbyMod("logic_roleinfo_carte_frame")
                    if carte then carte:equip_carte_frame_rsp(0, frame_id, bEquip) end
                end)
            end
        end)
        wrapStatic(RIHandler, "send_use_brand", function()
            return function(id)
                id = tonumber(id)
                if not id or id <= 0 then return end
                saveEquip("brand", id)
                pcall(reapplySavedBrand)
            end
        end)
        wrapStatic(RGBHandler, "send_set_social_info_bg_req", function()
            return function(subtype, bg_id)
                bg_id = tonumber(bg_id)
                if not bg_id or bg_id <= 0 then return end
                injectPersonalDepot(bg_id)
                if subtype == ENUM_ITEM_SUBTYPE.RoleInfoBG then
                    saveEquip("roleInfoBg", bg_id)
                    pcall(function()
                        local m = getLobbyMod("logic_roleInfo_background")
                        if m then m:on_set_social_info_bg_rsp(0, bg_id) end
                    end)
                elseif subtype == ENUM_ITEM_SUBTYPE.PersonalOpening then
                    saveEquip("opening", bg_id)
                    pcall(function()
                        local m = getLobbyMod("logic_roleInfo_opening")
                        if m then m:on_set_social_info_bg_rsp(0, bg_id) end
                    end)
                end
            end
        end)
        wrapStatic(SCBGHandler, "send_set_social_card_floor_req", function()
            return function(social_card_floor_id)
                social_card_floor_id = tonumber(social_card_floor_id)
                if not social_card_floor_id or social_card_floor_id <= 0 then return end
                saveEquip("socialCardBg", social_card_floor_id)
                injectPersonalDepot(social_card_floor_id)
                pcall(function()
                    local sc = getLobbyMod("logic_social_card_bg")
                    if sc then
                        sc.CurrentSocialCardBGID = social_card_floor_id
                        sc:on_notify_social_card_floor(social_card_floor_id)
                        sc:on_set_social_card_floor_rsp(0)
                    end
                end)
            end
        end)

        wrapStatic(RIHandler, "on_set_friend_nickname_skin_rsp", function(orig)
            return function(err_code, skin_id)
                if err_code ~= 0 then err_code = 0 end
                saveEquip("nickname", skin_id)
                return orig(err_code, skin_id)
            end
        end)
        wrapStatic(RIHandler, "on_set_chat_bubble_rsp", function(orig)
            return function(err_code, bubble_id)
                if err_code ~= 0 then err_code = 0 end
                saveEquip("chat", bubble_id)
                return orig(err_code, bubble_id)
            end
        end)
        wrapStatic(RIHandler, "on_change_team_notify_skin_rsp", function(orig)
            return function(err_code, cur_skin_id)
                if err_code ~= 0 then err_code = 0 end
                saveEquip("teamSkin", cur_skin_id)
                return orig(err_code, cur_skin_id)
            end
        end)
        wrapStatic(RIHandler, "on_equip_carte_frame_rsp", function(orig)
            return function(err_code, frame_id, bEquip)
                if err_code ~= 0 then err_code = 0 end
                if bEquip then saveEquip("carteFrame", frame_id) end
                return orig(err_code, frame_id, bEquip)
            end
        end)
        wrapStatic(RIHandler, "on_get_user_avatar_list_rsp", function(orig)
            return function(ok, list, headportraiturl)
                if ok ~= 0 then ok = 0 end
                list = fillUnlockHeadList(list or {})
                local saved = _G.NTHUY2004_ProfileCustomEquip.avatar
                if saved then headportraiturl = saved end
                return orig(ok, list, headportraiturl)
            end
        end)
        wrapStatic(RIHandler, "on_get_friend_nickname_skin_rsp", function(orig)
            return function(err_code, friend_nickname_skin_data, friend_nickname_skin_cfg)
                if err_code ~= 0 then err_code = 0 end
                friend_nickname_skin_data = friend_nickname_skin_data or {}
                friend_nickname_skin_data.skins = friend_nickname_skin_data.skins or {}
                pcall(function()
                    for id, _ in pairs(friend_nickname_skin_cfg or {}) do
                        friend_nickname_skin_data.skins[id] = { expire_ts = 0 }
                    end
                    for id, _ in pairs(CDataTable.GetTable("NicknameEffectCfg") or {}) do
                        friend_nickname_skin_data.skins[id] = { expire_ts = 0 }
                    end
                end)
                local saved = _G.NTHUY2004_ProfileCustomEquip.nickname
                if saved then friend_nickname_skin_data.equip = saved end
                return orig(err_code, friend_nickname_skin_data, friend_nickname_skin_cfg)
            end
        end)
        wrapStatic(RIHandler, "on_get_chat_bubble_rsp", function(orig)
            return function(err_code, chat_bubble_data, chat_bubble_cfg)
                if err_code ~= 0 then err_code = 0 end
                chat_bubble_data = chat_bubble_data or {}
                chat_bubble_data.bubbles = chat_bubble_data.bubbles or {}
                pcall(function()
                    for id, _ in pairs(chat_bubble_cfg or {}) do
                        chat_bubble_data.bubbles[id] = { expire_ts = 0 }
                    end
                    for id, _ in pairs(CDataTable.GetTable("ChatEffectCfg") or {}) do
                        chat_bubble_data.bubbles[id] = { expire_ts = 0 }
                    end
                end)
                local saved = _G.NTHUY2004_ProfileCustomEquip.chat
                if saved then chat_bubble_data.equip = saved end
                return orig(err_code, chat_bubble_data, chat_bubble_cfg)
            end
        end)
        wrapStatic(RIHandler, "on_get_team_notify_skin_list_rsp", function(orig)
            return function(err_code, skin_list, cur_skin_id)
                if err_code ~= 0 then err_code = 0 end
                skin_list = fillUnlockTeamSkinList(skin_list)
                local saved = _G.NTHUY2004_ProfileCustomEquip.teamSkin
                if saved then cur_skin_id = saved end
                return orig(err_code, skin_list, cur_skin_id)
            end
        end)
        wrapStatic(RIHandler, "on_get_carte_frame_list_rsp", function(orig)
            return function(err_code, active_frame_list, equip_frame_id)
                if err_code ~= 0 then err_code = 0 end
                active_frame_list = fillUnlockCarteActiveList(active_frame_list)
                local saved = _G.NTHUY2004_ProfileCustomEquip.carteFrame
                if saved then equip_frame_id = saved end
                return orig(err_code, active_frame_list, equip_frame_id)
            end
        end)
        wrapStatic(RIHandler, "on_use_brand_rsp", function(orig)
            return function(res, id)
                id = tonumber(id)
                if id and id > 0 then
                    if res ~= 0 then res = 0 end
                    saveEquip("brand", id)
                end
                return orig(res, id)
            end
        end)

        local WardRobeHandler = require("client.network.Protocol.WardRobeHandler")
        wrapStatic(WardRobeHandler, "on_get_avatar_box_list_rsp", function(orig)
            return function(ok, list, cur_avatar_box_id)
                if ok ~= 0 then ok = 0 end
                list = fillUnlockFrameList(list or {})
                local saved = _G.NTHUY2004_ProfileCustomEquip.avatarBox
                if saved then cur_avatar_box_id = saved end
                return orig(ok, list, cur_avatar_box_id)
            end
        end)
        wrapStatic(RGBHandler, "on_set_social_info_bg_rsp", function(orig)
            return function(res, subtype, bg_id)
                if res ~= 0 then res = 0 end
                bg_id = tonumber(bg_id)
                if bg_id and bg_id > 0 then
                    if subtype == ENUM_ITEM_SUBTYPE.RoleInfoBG then
                        saveEquip("roleInfoBg", bg_id)
                    elseif subtype == ENUM_ITEM_SUBTYPE.PersonalOpening then
                        saveEquip("opening", bg_id)
                    end
                end
                return orig(res, subtype, bg_id)
            end
        end)
        wrapStatic(SCBGHandler, "on_set_social_card_floor_rsp", function(orig)
            return function(ret)
                if ret ~= 0 then ret = 0 end
                local saved = _G.NTHUY2004_ProfileCustomEquip and tonumber(_G.NTHUY2004_ProfileCustomEquip.socialCardBg)
                if saved then saveEquip("socialCardBg", saved) end
                return orig(ret)
            end
        end)
        wrapStatic(CharHandler, "on_change_user_avatar_rsp", function(orig)
            return function(ok, item_url, endtime)
                if ok ~= 0 then ok = 0; endtime = 1 end
                return orig(ok, item_url, endtime)
            end
        end)
        wrapStatic(CharHandler, "on_change_avatar_box_rsp", function(orig)
            return function(ok, item_id)
                if ok ~= 0 then ok = 0 end
                return orig(ok, item_id)
            end
        end)
    end)

    -- ════════════════════════════════════════════════════════════════════════
    -- FINALIZE
    -- ════════════════════════════════════════════════════════════════════════
    _G.NTHUY2004_ProfileCustomUnlockVer       = 9
    _G.NTHUY2004_ProfileCustomUnlockInstalled = true

    pcall(function()
        local RAS = require("client.slua.logic.roleInfo.logic_roleInfo_Avatar")
        local RAF = require("client.slua.logic.roleInfo.logic_RoleInfoAvatarFrame")
        RAS.HeadportraitList = fillUnlockHeadList(RAS.HeadportraitList or {})
        RAF.AvatarFrameList  = fillUnlockFrameList(RAF.AvatarFrameList or {})
    end)

    pcall(function() forceReapplyAll(true) end)
    pcall(unlockAllNameFrames)

    pcall(function()
        if EventSystem and not _G.NTHUY2004_ProfileCustomEventsHooked then
            _G.NTHUY2004_ProfileCustomEventsHooked = true
            local function onScreenChange()
                pcall(function() forceReapplyAll(true) end)
            end
            if EVENTTYPE_LOBBY and EVENTID_SHOW_LOBBY then
                EventSystem:registEvent(EVENTTYPE_LOBBY, EVENTID_SHOW_LOBBY, onScreenChange)
            end
            if EVENTTYPE_PROFILE and EVENTID_PROFILE_LIST_UPDATE then
                EventSystem:registEvent(EVENTTYPE_PROFILE, EVENTID_PROFILE_LIST_UPDATE, onScreenChange)
            end
            if EVENTTYPE_ROLEINFO then
                if EVENTID_ROLEINFO_UPDATE_ROLEINFO then
                    EventSystem:registEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_ROLEINFO, onScreenChange)
                end
                if EVENTID_ROLEINFO_CARTE_FRAME_CHANGE then
                    EventSystem:registEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_CARTE_FRAME_CHANGE, onScreenChange)
                end
            end
            if EVENTTYPE_LOGIN_ROLEDATA and EVENTID_LOGIN_ROLEDATA_SYNC then
                EventSystem:registEvent(EVENTTYPE_LOGIN_ROLEDATA, EVENTID_LOGIN_ROLEDATA_SYNC, onScreenChange)
            end
        end

        if _G.Mytimer_ticker and not _G.NTHUY2004_ProfileCustomReapplyLoop then
            _G.NTHUY2004_ProfileCustomReapplyLoop = true
            _G.Mytimer_ticker.AddTimerLoop(1, function()
    if not shouldReapplyProfileCustom() then return end
    -- ★ Sirf lobby mein
    if not (GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity()) then
        return
    end
    if DataMgr and DataMgr.roleData and DataMgr.roleData.uid then
        if _G.NTHUY2004_ProfileCustomEquip and next(_G.NTHUY2004_ProfileCustomEquip) then
            forceReapplyAll(true)
        end
    end
end, -1, 5)  -- 1s → 5s
        end
    end)

    return true
end

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


-- ════════
--══════════════════════════════════════════════════════════════════
_G.NTHUY2004_EnsurePersonalInfoMod = function()
    if not (_G.DX_Settings and _G.DX_Settings.UnlockProfileCustom == true) then
        return false
    end
    pcall(_G.NTHUY2004_InstallProfileCustomUnlock)
    return true
end

pcall(function()
    local ok, ticker = pcall(require, "common.time_ticker")
    local function bootCustomUnlock()
        if not (_G.DX_Settings and _G.DX_Settings.UnlockProfileCustom == true) then
            return
        end
        pcall(_G.NTHUY2004_InstallProfileCustomUnlock)
    end

    if ok and ticker and ticker.AddTimerOnce then
        -- Retry ở nhiều thời điểm để chắc chắn các module đã load
        for _, d in ipairs({ 1, 3, 8, 15, 25, 40, 60 }) do
            ticker.AddTimerOnce(d, bootCustomUnlock)
        end
    else
        -- Fallback: gọi ngay
        bootCustomUnlock()
    end
end)



-- ═══════════════════════════════════════════════════════════════════
-- pet_v14_SKIN_FIX.lua — 100% Working Skin System Added
-- Based on pet_v14.lua with enhanced Dress Application Logic
-- ═══════════════════════════════════════════════════════════════════

_G.PetUnlock = (function()
if _G._PetV14_Loaded then return _G.PetUnlock end
_G._PetV14_Loaded = true

local _unpack = unpack or table.unpack
if not _unpack then
    _unpack = function(t, i, j)
        i = i or 1; j = j or #t
        if i > j then return end
        return t[i], _unpack(t, i + 1, j)
    end
end

_G.PetUnlock = _G.PetUnlock or {
    equippedPetID    = nil,
    carryList        = {},
    petColors        = {},
    petDresses       = {}, -- Stores selected dress ID per Pet ID
    autoDefaultEquip = 50047,
    autoCarryFirst   = { 50047, 50008, 50033, 50018, 50017, 50016 },
}

local FAKE_PET_IDS = {}
do
    local i
    for i = 50000, 50050 do FAKE_PET_IDS[i] = true end
end

local INS_BASE = 3000000000
local resToIns, insToRes = {}, {}
do
    local n = 0
    local id
    for id in pairs(FAKE_PET_IDS) do
        n = n + 1
        local ins = INS_BASE + n
        resToIns[id] = ins
        insToRes[ins] = id
    end
end

local function isFakePet(id)
    id = tonumber(id)
    return id ~= nil and FAKE_PET_IDS[id] == true
end
local function isFakeIns(ins)
    ins = tonumber(ins)
    return ins ~= nil and insToRes[ins] ~= nil
end
local function resolvePetID(id)
    id = tonumber(id)
    if not id then return nil end
    if FAKE_PET_IDS[id] then return id end
    if insToRes[id] then return insToRes[id] end
    return nil
end
local function insForPet(petID)
    petID = tonumber(petID) or 50047
    if not FAKE_PET_IDS[petID] then return 0 end
    return resToIns[petID] or 0
end
local function getEquippedPet()
    local pu = _G.PetUnlock
    if pu and pu.equippedPetID and FAKE_PET_IDS[tonumber(pu.equippedPetID)] then
        return tonumber(pu.equippedPetID)
    end
    return 50047
end
local function isPetActionID(id)
    id = tonumber(id); if not id then return false end
    return id >= 50000000 and id < 50100000
end
local function isPetDressID(id)
    id = tonumber(id); if not id then return false end
    return id >= 1601000 and id <= 1602000
end

-- ─── DIRS ──────────────────────────────────────────────────────────
local SAVE_DIRS = {
    "/storage/emulated/0/Android/data/com.pubg.imobile/files/",
    "/storage/emulated/0/Android/data/com.pubg.krmobile/files/",
    "/storage/emulated/0/Android/data/com.vng.pubgmobile/files/",
    "/storage/emulated/0/Android/data/com.rekoo.pubgm/files/",
}
local _saveDir
local function getSaveDir()
    if _saveDir then return _saveDir end
    local i
    for i = 1, #SAVE_DIRS do
        local f = io.open(SAVE_DIRS[i] .. "config.ini", "r")
        if f then f:close(); _saveDir = SAVE_DIRS[i]; return _saveDir end
    end
    _saveDir = SAVE_DIRS[1]; return _saveDir
end

local function getSaveFile()
    local uid = "default"
    pcall(function()
        if _G.DataMgr and _G.DataMgr.roleData and _G.DataMgr.roleData.uid then
            uid = tostring(_G.DataMgr.roleData.uid)
        end
    end)
    return getSaveDir() .. "PetUnlock_" .. uid .. ".txt"
end

local function saveState()
    pcall(function()
        local f = io.open(getSaveFile(), "w+")
        if not f then return end
        local lines = {}
        if _G.PetUnlock.equippedPetID then
            lines[#lines + 1] = "equipped=" .. tostring(_G.PetUnlock.equippedPetID)
        end
        local pid, c
        for pid, c in pairs(_G.PetUnlock.petColors or {}) do
            lines[#lines + 1] = "color_" .. tostring(pid) .. "=" .. tostring(c)
        end
        for pid, d in pairs(_G.PetUnlock.petDresses or {}) do
            lines[#lines + 1] = "dress_" .. tostring(pid) .. "=" .. tostring(d)
        end
        f:write(table.concat(lines, "\n")); f:close()
    end)
end

local function loadState()
    pcall(function()
        local f = io.open(getSaveFile(), "r"); if not f then return end
        local content = f:read("*a"); f:close()
        if not content or content == "" then return end
        _G.PetUnlock.petDresses = _G.PetUnlock.petDresses or {}
        for line in content:gmatch("[^\n]+") do
            local k, v = line:match("^(.-)=(.+)$")
            if k == "equipped" then
                _G.PetUnlock.equippedPetID = tonumber(v)
            elseif k then
                local cpid = k:match("^color_(%d+)$")
                if cpid then
                    cpid = tonumber(cpid)
                    if cpid and FAKE_PET_IDS[cpid] then
                        _G.PetUnlock.petColors[cpid] = tonumber(v) or 1
                    end
                end
                local dpid = k:match("^dress_(%d+)$")
                if dpid then
                    dpid = tonumber(dpid)
                    if dpid and FAKE_PET_IDS[dpid] then
                        _G.PetUnlock.petDresses[dpid] = tonumber(v) or 0
                    end
                end
            end
        end
    end)
end

local function seedDefaults()
    if not _G.PetUnlock.equippedPetID then
        local def = tonumber(_G.PetUnlock.autoDefaultEquip)
        if def and FAKE_PET_IDS[def] then _G.PetUnlock.equippedPetID = def end
    end
    _G.PetUnlock.petColors = _G.PetUnlock.petColors or {}
    _G.PetUnlock.petDresses = _G.PetUnlock.petDresses or {}
    saveState()
end

local function makeFakePetData(petID)
    petID = tonumber(petID)
    if not petID or not FAKE_PET_IDS[petID] then return nil end
    local ins = resToIns[petID] or 0
    return {
        petID = petID, petItemID = petID, pet_id = petID, PetID = petID,
        id = petID, item_id = petID, itemId = petID, ItemID = petID,
        insID = ins, ins_id = ins, insId = ins, inst_id = ins, instId = ins, InsID = ins,
        level = 1, exp = 0, name = "",
        isPermanent = true, is_permanent = true, bPermanent = true,
        isFrozen = false, is_frozen = 0, bFrozen = false,
        expireTime = 0, expire_time = 0, expireTS = 0, ExpireTs = 0, expire_ts = 0,
        color = (_G.PetUnlock.petColors and _G.PetUnlock.petColors[petID]) or 1,
        Color = (_G.PetUnlock.petColors and _G.PetUnlock.petColors[petID]) or 1,
        dressResID = (_G.PetUnlock.petDresses and _G.PetUnlock.petDresses[petID]) or 0,
        dressList = {}, dress_list = {}, DressList = {}, dresses = {},
        isInherit = false, isShared = false,
        isLock = false, bIsLock = false, bLock = false,
        bOwn = true, isOwn = true, isOwned = true, bOwned = true,
        unlock_state = 2, state = 2, is_used = 1, have_used = 1,
    }
end

local _orig = {}
local _activeLobbyPetActor = nil -- ★ Global Actor Ref for Skins/Emotes
local _capturedContainer = nil   -- ★ Global Container Ref for Skins

-- ═══════════════════════════════════════════════════════════════════
-- TLogicPetData — ownership
-- ═══════════════════════════════════════════════════════════════════
local function hookTPD()
    local ok, TPD = pcall(require, "client.slua.logic.pet.traits.TLogicPetData")
    if not ok or not TPD or not TPD.__inner_impl then return false end
    local ii = TPD.__inner_impl

    local function wrap(name, fn)
        if type(ii[name]) ~= "function" then return end
        if not _orig["TPD_" .. name] then _orig["TPD_" .. name] = ii[name] end
        ii[name] = fn(_orig["TPD_" .. name])
    end

    local positive = {
        "HasPet", "HasPetIncludeInherit", "HavePermanentPet",
        "HasPetPermanently", "HasPetDress", "HasValidPetDress",
        "HasPetDressPermanently", "IsPetEquip", "HasPetActionDress",
        "IsInDress", "IsActionUnLock", "HasEquipedPet",
    }
    local i
    for i = 1, #positive do
        wrap(positive[i], function(o)
            return function(self, id, ...)
                if not id or isFakePet(id) or isFakeIns(id) or isPetDressID(id) then return true end
                return o(self, id, ...)
            end
        end)
    end

    local negative = {
        "IsPetFrozen", "IsPetDressFrozen",
        "IsPetTimeLimitedOwning", "IsDressTimeLimitedOwning",
    }
    for i = 1, #negative do
        wrap(negative[i], function(o)
            return function(self, id, ...)
                if not id or isFakePet(id) or isFakeIns(id) or isPetDressID(id) then return false end
                return o(self, id, ...)
            end
        end)
    end

    wrap("GetOwnedPetList", function(o)
        return function(self, ...)
            local list = o(self, ...) or {}
            local seen = {}
            local k, v
            for k, v in ipairs(list) do
                local id = tonumber(v and (v.petID or v.petItemID or v) or v)
                if id then seen[id] = true end
            end
            local id
            for id in pairs(FAKE_PET_IDS) do
                if not seen[id] then list[#list + 1] = makeFakePetData(id) or id end
            end
            return list
        end
    end)

    wrap("GetOwnedPetItemIDByPetID", function(o)
        return function(self, id, ...)
            if isFakePet(id) then return insForPet(id) end
            return o(self, id, ...)
        end
    end)
    wrap("GetPetDataByPetItemID", function(o)
        return function(self, id, ...)
            if isFakePet(id) then return makeFakePetData(id) end
            return o(self, id, ...)
        end
    end)
    wrap("GetPetDataByInsID", function(o)
        return function(self, ins, ...)
            if isFakeIns(ins) then return makeFakePetData(insToRes[ins]) end
            return o(self, ins, ...)
        end
    end)
    wrap("GetPetDataIncludeInherit", function(o)
        return function(self, id, ...)
            if isFakePet(id) then return makeFakePetData(id) end
            return o(self, id, ...)
        end
    end)
    wrap("GetPetInfo", function(o)
        return function(self, id, ...)
            local pid = resolvePetID(id)
            if pid then return makeFakePetData(pid) end
            return o(self, id, ...)
        end
    end)

    wrap("GetEquipedPetItemID", function(o)
        return function(self, ...)
            if _G.PetUnlock.equippedPetID then return _G.PetUnlock.equippedPetID end
            return o(self, ...)
        end
    end)
    wrap("GetEquipedPetInsID", function(o)
        return function(self, ...)
            if _G.PetUnlock.equippedPetID then return insForPet(_G.PetUnlock.equippedPetID) end
            return o(self, ...)
        end
    end)

    wrap("GetCurrentCarryPets", function(o)
        return function(self, ...)
            local list = {}
            local e = makeFakePetData(getEquippedPet())
            if e then list[1] = e end
            return list
        end
    end)
    wrap("GetCurrentCarryCount", function(o) return function() return 1 end end)
    wrap("GetMaxCarryPetCount", function(o) return function() return 6 end end)
    wrap("HasExpandSlotPriv", function(o) return function() return true end end)

    wrap("GetPetExpireTime", function(o)
        return function(self, id, ...)
            if isFakePet(id) or isPetDressID(id) then return 0 end
            return o(self, id, ...)
        end
    end)
    wrap("GetPetExpirationStateByPetItemID", function(o)
        return function(self, id, ...)
            if isFakePet(id) or isPetDressID(id) then return 3 end
            return o(self, id, ...)
        end
    end)
    wrap("GetPetNameLocal", function(o)
        return function(self, id, ...)
            if isFakePet(id) then
                local cfg = CDataTable and CDataTable.GetTableData and CDataTable.GetTableData("Item", id)
                return (cfg and cfg.ItemName) or ("Pet_" .. tostring(id))
            end
            return o(self, id, ...)
        end
    end)

    wrap("GetCurDressItems", function(o)
        return function(self, petID, ...)
            local pid = resolvePetID(petID) or getEquippedPet()
            local dress = _G.PetUnlock.petDresses and _G.PetUnlock.petDresses[pid]
            if dress and dress > 0 then return { dress } end
            return o(self, petID, ...) or {}
        end
    end)
    wrap("GetCurDressItemsByInsID", function(o)
        return function(self, ins, ...)
            local pid = isFakeIns(ins) and insToRes[ins] or resolvePetID(ins)
            if pid then
                local dress = _G.PetUnlock.petDresses and _G.PetUnlock.petDresses[pid]
                if dress and dress > 0 then return { dress } end
            end
            return o(self, ins, ...) or {}
        end
    end)

    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- TLogicPetCfg
-- ═══════════════════════════════════════════════════════════════════
local function hookTPC()
    local ok, TPC = pcall(require, "client.slua.logic.pet.traits.TLogicPetCfg")
    if not ok or not TPC or not TPC.__inner_impl then return false end
    local ii = TPC.__inner_impl
    local function wrap(name, fn)
        if type(ii[name]) ~= "function" then return end
        if not _orig["TPC_" .. name] then _orig["TPC_" .. name] = ii[name] end
        ii[name] = fn(_orig["TPC_" .. name])
    end
    wrap("IsPetItemValid", function(o)
        return function(self, id, ...)
            if isFakePet(id) or isPetDressID(id) then return true end
            return o(self, id, ...)
        end
    end)
    wrap("IsPetIDBlocked", function(o)
        return function(self, id, ...)
            if isFakePet(id) then return false end
            return o(self, id, ...)
        end
    end)
    wrap("IsPetOrDress", function(o)
        return function(self, id, ...)
            if isFakePet(id) or isPetDressID(id) then return true end
            return o(self, id, ...)
        end
    end)
    wrap("IsActionUnLock", function() return function() return true end end)
    wrap("GetUnlockActionNeedLevel", function() return function() return 1 end end)
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- PetHandler
-- ═══════════════════════════════════════════════════════════════════
local function hookPetHandler()
    local ok, PH = pcall(require, "client.network.Protocol.PetHandler")
    if not ok or not PH then return false end

    local function blockSend(name, localFn)
        if type(PH[name]) ~= "function" then return end
        if not _orig["PH_" .. name] then _orig["PH_" .. name] = PH[name] end
        PH[name] = function(...)
            local args = { n = select("#", ...), ... }
            local a1 = args[1]
            if isFakePet(a1) or isFakeIns(a1) or a1 == nil or a1 == 0 then
                pcall(localFn, _unpack(args, 1, args.n))
                return
            end
            return _orig["PH_" .. name](_unpack(args, 1, args.n))
        end
    end

    blockSend("send_equip_pet_req", function(petID)
        petID = resolvePetID(petID) or getEquippedPet()
        _G.PetUnlock.equippedPetID = petID
        saveState()
        pcall(function() PH.on_equip_pet_rsp(0, petID) end)
        pcall(function()
            local TNU = require("client.slua.logic.pet.traits.TLogicPetNetUtil")
            if TNU.equip_pet_rsp then TNU.equip_pet_rsp(TNU, 0, petID) end
            if TNU.notice_pet_change then TNU.notice_pet_change(TNU) end
        end)
        -- ★ Trigger Dress Apply after Equip
        pcall(function()
            local t = require("common.time_ticker")
            if t and t.AddTimerOnce then
                t.AddTimerOnce(0.5, function() 
                    _G.PetDressApply(petID, _G.PetUnlock.petDresses[petID] or 0) 
                end)
            end
        end)
    end)

    blockSend("send_unequip_pet_req", function()
        _G.PetUnlock.equippedPetID = nil
        saveState()
        pcall(function() PH.on_unequip_pet_rsp(0) end)
    end)

    blockSend("send_carry_pet_req", function(petID)
        petID = resolvePetID(petID)
        if not petID then return end
        pcall(function() PH.on_carry_pet_rsp(0, petID) end)
    end)

    blockSend("send_change_pet_model_req", function(petID, color)
        petID = resolvePetID(petID)
        if not petID then return end
        _G.PetUnlock.petColors[petID] = tonumber(color) or 1
        saveState()
        pcall(function() PH.on_change_pet_model_rsp(0, petID, color) end)
    end)

    blockSend("send_set_pet_color_req", function(petID, color)
        petID = resolvePetID(petID)
        if not petID then return end
        _G.PetUnlock.petColors[petID] = tonumber(color) or 1
        saveState()
        pcall(function() PH.on_set_pet_color_rsp(0, petID, color) end)
    end)

    blockSend("send_pet_action_req", function(petID, actionID)
        petID = resolvePetID(petID) or getEquippedPet()
        actionID = tonumber(actionID) or 0
        pcall(function() PH.on_pet_action_rsp(0, petID, actionID) end)
        pcall(function()
            local TNU = require("client.slua.logic.pet.traits.TLogicPetNetUtil")
            if TNU.pet_action_rsp then TNU.pet_action_rsp(TNU, 0, petID, actionID) end
        end)
        -- Force play on active actor
        pcall(function()
            local t = require("common.time_ticker")
            if t and t.AddTimerOnce then
                t.AddTimerOnce(0.05, function() _G.PetEmotePlay(actionID) end)
            end
        end)
    end)

    blockSend("send_pet_used_dress_req", function(petID, dressID)
        petID = resolvePetID(petID) or getEquippedPet()
        dressID = tonumber(dressID) or 0
        _G.PetUnlock.petDresses[petID] = dressID
        saveState()
        pcall(function() PH.on_pet_used_dress_rsp(0, petID, dressID) end)
        pcall(function()
            local TNU = require("client.slua.logic.pet.traits.TLogicPetNetUtil")
            if TNU.pet_used_dress_rsp then TNU.pet_used_dress_rsp(TNU, 0, petID, dressID) end
            if TNU.notice_dress_change then TNU.notice_dress_change(TNU, petID, dressID) end
        end)
        pcall(function()
            if EventSystem and EVENTTYPE_PET and EVENTID_PET_DRESS_CHANGE then
                EventSystem:postEvent(EVENTTYPE_PET, EVENTID_PET_DRESS_CHANGE, petID, dressID)
            end
        end)
        -- ★ Immediate Visual Update
        pcall(function()
            local t = require("common.time_ticker")
            if t and t.AddTimerOnce then
                t.AddTimerOnce(0.05, function() _G.PetDressApply(petID, dressID) end)
                t.AddTimerOnce(0.5, function() _G.PetDressApply(petID, dressID) end) -- Retry
            end
        end)
    end)

    blockSend("send_pet_unload_dress_req", function(petID)
        petID = resolvePetID(petID) or getEquippedPet()
        _G.PetUnlock.petDresses[petID] = 0
        saveState()
        pcall(function() PH.on_pet_unload_dress_rsp(0, petID, 0) end)
         -- Remove visual dress
        pcall(function()
            local t = require("common.time_ticker")
            if t and t.AddTimerOnce then
                t.AddTimerOnce(0.05, function() _G.PetDressApply(petID, 0) end)
            end
        end)
    end)

    local rspFns = {
        "on_equip_pet_rsp", "on_unequip_pet_rsp", "on_carry_pet_rsp",
        "on_pet_used_dress_rsp", "on_pet_unload_dress_rsp", "on_pet_show_rsp",
        "on_change_pet_model_rsp", "on_set_pet_color_rsp",
        "on_pet_action_rsp", "on_pet_add_exp_rsp",
    }
    local j
    for j = 1, #rspFns do
        local fn = rspFns[j]
        if type(PH[fn]) == "function" then
            local key = "PHrsp_" .. fn
            if not _orig[key] then
                _orig[key] = PH[fn]
                PH[fn] = function(err, ...)
                    if type(err) == "number" and err ~= 0 then err = 0 end
                    return _orig[key](err, ...)
                end
            end
        end
    end
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- pet_pawn_pool — CRITICAL: force ConfigID POST-SPAWN
-- ═══════════════════════════════════════════════════════════════════
local function hookPool()
    local ok, PPP = pcall(require, "client.slua.logic.pet.pet_pawn_pool")
    if not ok or not PPP or not PPP.__inner_impl then return false end
    local ii = PPP.__inner_impl
    local names = { "_CreatePetPawn", "_GetOneFromPool" }
    local i
    for i = 1, #names do
        local n = names[i]
        if type(ii[n]) == "function" and not _orig["PPP_" .. n] then
            _orig["PPP_" .. n] = ii[n]
            ii[n] = function(self, ...)
                local args = { n = select("#", ...), ... }
                local j
                for j = 1, args.n do
                    if isFakeIns(args[j]) then args[j] = insToRes[args[j]] end
                end
                if isFakePet(args[1]) and type(args[2]) == "table" and not args[2].insID then
                    args[2].insID = insForPet(args[1])
                end
                local r = _orig["PPP_" .. n](self, _unpack(args, 1, args.n))
                if r and type(r) == "userdata" then
                    _activeLobbyPetActor = r -- ★ CAPTURE ACTOR
                    pcall(function()
                        local petID = getEquippedPet()
                        r.ConfigID = petID
                    end)
                end
                return r
            end
        end
    end
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- LobbyPetBase
-- ═══════════════════════════════════════════════════════════════════
local function hookLPB()
    local ok, LPB = pcall(require, "client.lobby_ue_object.Actor.LobbyPetBase")
    if not ok or not LPB or not LPB.__inner_impl then return false end
    local ii = LPB.__inner_impl

    local function wrap(name, fn)
        if type(ii[name]) ~= "function" then return end
        if _orig["LPB_" .. name] then return end
        _orig["LPB_" .. name] = ii[name]
        ii[name] = fn(_orig["LPB_" .. name])
    end

    local function forceCfg(self)
        if not self then return end
        local cfg = tonumber(self.ConfigID)
        if not cfg or cfg == 0 then
            pcall(function() self.ConfigID = getEquippedPet() end)
        end
    end

    local forceNames = {
        "SetConfigID", "SetupLobbyPetParams", "InitializePet",
        "InitAvatar", "InitBaseScale", "SetUid", "SetParent", "SetMaster",
    }
    local i
    for i = 1, #forceNames do
        local fname = forceNames[i]
        wrap(fname, function(o)
            return function(self, ...)
                local args = { n = select("#", ...), ... }
                pcall(forceCfg, self)
                return o(self, _unpack(args, 1, args.n))
            end
        end)
    end

    wrap("SetBPPath", function(o)
        return function(self, path, ...)
            local args = { n = select("#", ...), ... }
            pcall(forceCfg, self)
            return o(self, path, _unpack(args, 1, args.n))
        end
    end)

    wrap("ReceiveBeginPlay", function(o)
        return function(self, ...)
            local args = { n = select("#", ...), ... }
            pcall(function()
                if self then self.ConfigID = getEquippedPet() end
            end)
            local r = o(self, _unpack(args, 1, args.n))
            pcall(function()
                if self and type(self.InitializePet) == "function" then
                    pcall(function() self:InitializePet() end)
                end
                if self and type(self.SetupLobbyPetParams) == "function" then
                    pcall(function() self:SetupLobbyPetParams() end)
                end
                _activeLobbyPetActor = self -- ★ UPDATE REF
                
                -- ★ AUTO APPLY DRESS ON SPAWN
                local pid = self.ConfigID
                local savedDress = _G.PetUnlock.petDresses[pid]
                if savedDress and savedDress > 0 then
                     local t = require("common.time_ticker")
                     if t and t.AddTimerOnce then
                         t.AddTimerOnce(0.2, function() _G.PetDressApply(pid, savedDress) end)
                     end
                end
            end)
            return r
        end
    end)

    -- ★ NEW HOOK: OnAvatarAllMeshLoaded - Best time to apply skin
    wrap("OnAvatarAllMeshLoaded", function(o)
        return function(self, ...)
            local args = { n = select("#", ...), ... }
            local r = o(self, _unpack(args, 1, args.n))
            pcall(function()
                _activeLobbyPetActor = self -- ★ ENSURE REF IS FRESH
                local pid = self.ConfigID
                local savedDress = _G.PetUnlock.petDresses[pid]
                if savedDress and savedDress > 0 then
                    _G.PetDressApply(pid, savedDress)
                end
            end)
            return r
        end
    end)

    wrap("SetDress", function(o)
        return function(self, dressID, ...)
            local args = { n = select("#", ...), ... }
            local pid = getEquippedPet()
            if (not dressID or dressID == 0) and pid then
                local saved = _G.PetUnlock.petDresses and _G.PetUnlock.petDresses[pid]
                if saved and saved > 0 then dressID = saved end
            end
            pcall(forceCfg, self)
            return o(self, dressID, _unpack(args, 1, args.n))
        end
    end)
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- logic_emote — emote click filters
-- ═══════════════════════════════════════════════════════════════════
local function hookLogicEmote()
    local ok, LE = pcall(require, "GameLua.Mod.Library.GamePlay.Avatar.Emote.logic_emote")
    if not ok or not LE then return false end

    if type(LE.GetPetExhibitRemainCD) == "function" then
        LE.GetPetExhibitRemainCD = function() return 0 end
    end
    if type(LE.CheckCanUsePetExhibitionEmote) == "function" then
        LE.CheckCanUsePetExhibitionEmote = function() return true end
    end
    if type(LE.CheckIsPetExhibitionEmote) == "function" then
        LE.CheckIsPetExhibitionEmote = function(actionID, ...)
            if isPetActionID(actionID) then return true end
            return true
        end
    end
    if type(LE.CheckEmoteDownloaded) == "function" then
        LE.CheckEmoteDownloaded = function(actionID, ...)
            if isPetActionID(actionID) then return true end
            return true
        end
    end
    if type(LE.IsEmoteExist) == "function" then
        LE.IsEmoteExist = function(actionID, ...)
            if isPetActionID(actionID) then return true end
            local t = CDataTable and CDataTable.GetTable and CDataTable.GetTable("EmoteBPTable")
            if t and t[actionID] then return true end
            return true
        end
    end
    if type(LE.CheckEmoteIsBan) == "function" then
        LE.CheckEmoteIsBan = function() return false end
    end
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- QuickExpression
-- ═══════════════════════════════════════════════════════════════════
local function hookQuickExpression()
    local ok, QE = pcall(require, "GameLua.Mod.BaseMod.Client.Emote.QuickExpression")
    if not ok or not QE or not QE.__inner_impl then return false end
    local ii = QE.__inner_impl

    local function wrap(name, fn)
        if type(ii[name]) ~= "function" then return end
        if _orig["QE_" .. name] then return end
        _orig["QE_" .. name] = ii[name]
        ii[name] = fn(_orig["QE_" .. name])
    end

    wrap("NeedHidePetExpression", function(o)
        return function(self, ...) return false end
    end)
    wrap("GetShowMyPet", function(o)
        return function(self, ...) return true end
    end)
    wrap("CheckIsSpecialPet", function(o)
        return function(self, ...) return false end
    end)
    wrap("TryToPlayPetExpression", function(o)
        return function(self, ...)
            local args = { n = select("#", ...), ... }
            local okr, r = pcall(o, self, _unpack(args, 1, args.n))
            if not okr then return true end
            return r
        end
    end)
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- PetContainerAvatar
-- ═══════════════════════════════════════════════════════════════════
local function hookPCAvatar()
    local ok, PCA = pcall(require, "client.slua.logic.pet.ContainerTraits.PetContainerAvatar")
    if not ok or not PCA or not PCA.__inner_impl then return false end
    local ii = PCA.__inner_impl

    -- ★ CAPTURE CONTAINER FOR SKINS
    local captureNames = { "_CreatePetActor", "SetMaster", "AttachToPawn", "_AttachToPawnImp", "OnPetMeshLoaded" }
    local i
    for i = 1, #captureNames do
        local fn = captureNames[i]
        if type(ii[fn]) == "function" and not _orig["PCAcap_" .. fn] then
            _orig["PCAcap_" .. fn] = ii[fn]
            ii[fn] = function(self, ...)
                _capturedContainer = self -- ★ STORE CONTAINER
                local args = { n = select("#", ...), ... }
                local r = _orig["PCAcap_" .. fn](self, _unpack(args, 1, args.n))
                
                -- If mesh loaded, try applying dress via container
                if fn == "OnPetMeshLoaded" then
                     local pid = getEquippedPet()
                     local savedDress = _G.PetUnlock.petDresses[pid]
                     if savedDress and savedDress > 0 then
                         pcall(function()
                             if type(self.PutOnEquipment) == "function" then
                                 self:PutOnEquipment(savedDress)
                             end
                         end)
                     end
                end
                return r
            end
        end
    end

    local names = { "SpawnPet", "CreatePet", "ShowPet", "RefreshPet", "RefreshAvatar", "UpdateAvatar", "UpdatePet", "SetPetData", "SetCurrentPet", "ApplyPet", "InitPet", "LoadPet", "ShowAvatar" }
    for i = 1, #names do
        local n = names[i]
        if type(ii[n]) == "function" and not _orig["PCA_" .. n] then
            _orig["PCA_" .. n] = ii[n]
            ii[n] = function(self, ...)
                local args = { n = select("#", ...), ... }
                pcall(function()
                    if args.n == 0 or args[1] == nil or args[1] == 0 then
                        args[1] = getEquippedPet(); args.n = math.max(args.n, 1)
                    end
                end)
                return _orig["PCA_" .. n](self, _unpack(args, 1, args.n))
            end
        end
    end

    local dressFns = { "PutOnEquipment", "PutOnWithCheck", "PutOnOrPutOff" }
    for i = 1, #dressFns do
        local fn = dressFns[i]
        if type(ii[fn]) == "function" and not _orig["PCA_" .. fn] then
            _orig["PCA_" .. fn] = ii[fn]
            ii[fn] = function(self, dressID, ...)
                local args = { n = select("#", ...), ... }
                local pid = getEquippedPet()
                if (not dressID or dressID == 0) and pid then
                    local saved = _G.PetUnlock.petDresses and _G.PetUnlock.petDresses[pid]
                    if saved and saved > 0 then dressID = saved end
                end
                return _orig["PCA_" .. fn](self, dressID, _unpack(args, 1, args.n))
            end
        end
    end
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- PM — force internal state
-- ═══════════════════════════════════════════════════════════════════
local _pmChosenPetID = nil

local function hookPetMain()
    local ok, PM = pcall(require, "client.slua.umg.pet.pet_main")
    if not ok or not PM or not PM.__inner_impl then return false end
    local ii = PM.__inner_impl

    local function wrap(name, fn)
        if type(ii[name]) ~= "function" then return end
        if _orig["PM_" .. name] then return end
        _orig["PM_" .. name] = ii[name]
        ii[name] = fn(_orig["PM_" .. name])
    end

    wrap("GetCurPetInsID", function(o)
        return function(self, ...)
            local r = o(self, ...)
            if not r or r == 0 then
                local pid = _pmChosenPetID or getEquippedPet()
                local ins = insForPet(pid)
                if ins > 0 then return ins end
            end
            return r
        end
    end)

    wrap("ChoosePet", function(o)
        return function(self, a, b, petID)
            petID = tonumber(petID)
            if petID and FAKE_PET_IDS[petID] then _pmChosenPetID = petID end
            return o(self, a, b, petID)
        end
    end)

    wrap("RefreshDressAccessButton", function(o)
        return function(self, ...) return o(self, 1) end
    end)
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- Executors (THE CORE SKIN LOGIC)
-- ═══════════════════════════════════════════════════════════════════
_G.PetEmotePlay = function(actionID)
    pcall(function()
        local actor = _activeLobbyPetActor
        actionID = tonumber(actionID) or 0
        if not actor or actionID <= 0 then return end
        if type(actor.PlayAction) == "function" then
            pcall(function() actor:PlayAction(actionID) end)
        end
        if type(actor.DownloadMontageAndPlay) == "function" then
            pcall(function() actor:DownloadMontageAndPlay(actionID) end)
        end
    end)
end

-- ★ ROBUST DRESS APPLIER WITH RETRY
_G.PetDressApply = function(petID, dressID)
    pcall(function()
        petID = tonumber(petID) or getEquippedPet()
        dressID = tonumber(dressID) or 0
        
        -- Save state regardless of success so it persists
        if dressID > 0 then
             _G.PetUnlock.petDresses[petID] = dressID
        else
             _G.PetUnlock.petDresses[petID] = 0
        end

        local applied = false

        -- Method 1: Container (Best for attachments)
        if _capturedContainer and not applied then
            pcall(function()
                if type(_capturedContainer.PutOnEquipment) == "function" then
                    _capturedContainer:PutOnEquipment(dressID)
                    applied = true
                end
            end)
        end

        -- Method 2: Direct Actor SetDress
        if not applied and _activeLobbyPetActor then
            pcall(function()
                if type(_activeLobbyPetActor.SetDress) == "function" then
                    _activeLobbyPetActor:SetDress(dressID)
                    applied = true
                end
            end)
            
            -- Force Avatar Init to refresh mesh
            pcall(function()
                if type(_activeLobbyPetActor.InitAvatar) == "function" then
                    _activeLobbyPetActor:InitAvatar()
                end
            end)
        end
        
        -- Retry if failed (Mesh might not be ready yet)
        if not applied then
            local t = require("common.time_ticker")
            if t and t.AddTimerOnce then
                t.AddTimerOnce(0.2, function()
                    if _activeLobbyPetActor then
                         pcall(function() _activeLobbyPetActor:SetDress(dressID) end)
                         pcall(function() _activeLobbyPetActor:InitAvatar() end)
                    end
                end)
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- Event patch — CRITICAL: 2028 (expired), 2033, 2016
-- ═══════════════════════════════════════════════════════════════════
local _last2017 = 0
local function allow2017()
    local now = 0
    pcall(function() now = os.clock() end)
    if (now - _last2017) < 0.15 then return false end
    _last2017 = now
    return true
end

local function patch2028(data)
    if type(data) ~= "table" then return end
    local k
    for k in pairs(data) do data[k] = false end
end

local function patch2033(data)
    if type(data) ~= "table" then return end
    local petID = _pmChosenPetID or getEquippedPet()
    local insID = insForPet(petID)
    local e = makeFakePetData(petID)
    local list = e and { e } or {}
    data.equip_pet_id = petID
    data.equip_pet_ins_id = insID
    data.equipPetId = petID
    data.equipPetInsId = insID
    data.equipPetItemID = petID
    data.pet_cnt = #list
    data.petCnt = #list
    data.carry_flag = true
    data.pets = list
    data.pet_list = list
    data.petList = list
    data.pet_infos = list
    data.petInfos = list
    data.dresses = data.dresses or {}
    data.pet_switch_effect = data.pet_switch_effect or { all_effect = {}, equiped_effect = {} }
end

local function patch2016(data)
    if type(data) ~= "table" then return end
    local petID = _pmChosenPetID or getEquippedPet()
    local insID = insForPet(petID)
    if type(data.ServerInfo) == "table" then
        data.ServerInfo.id = petID
        data.ServerInfo.ins_id = insID
        data.ServerInfo.color = data.ServerInfo.color or 1
    else
        data.ServerInfo = { id = petID, ins_id = insID, color = 1, change = 0, exp = 0 }
    end
end

local function installEventPatch()
    if not EventSystem then return false end
    if EventSystem._pv14_hooked then return true end
    EventSystem._pv14_hooked = true
    local orig = EventSystem.postEvent
    if type(orig) ~= "function" then return false end

    EventSystem.postEvent = function(self, evtType, evtId, ...)
        local args = { n = select("#", ...), ... }
        if evtType == EVENTTYPE_PET then
            if evtId == 2028 then
                pcall(patch2028, args[1])
            elseif evtId == 2033 then
                pcall(patch2033, args[1])
            elseif evtId == 2016 then
                pcall(patch2016, args[1])
            elseif evtId == 2017 then
                if not allow2017() then return end
            end
        end
        return orig(self, evtType, evtId, _unpack(args, 1, args.n))
    end
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- State force loop — every 0.5s force actor ConfigID + PM state
-- ═══════════════════════════════════════════════════════════════════
local function forceStateLoop()
    pcall(function()
        local petID = getEquippedPet()
        local insID = insForPet(petID)

        local actor = _activeLobbyPetActor
        if actor then
            pcall(function()
                local cfg = tonumber(actor.ConfigID)
                if not cfg or cfg == 0 or cfg ~= petID then
                    actor.ConfigID = petID
                end
            end)
        end

        local PM = package.loaded["client.slua.umg.pet.pet_main"]
        if PM and PM.__inner_impl then
            pcall(function()
                PM.__inner_impl.curPetInsID = insID
                PM.__inner_impl.curPetID = petID
            end)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- Re-emit
-- ═══════════════════════════════════════════════════════════════════
local function reemit()
    pcall(function()
        if not EventSystem or not EVENTTYPE_PET then return end
        local petID = _pmChosenPetID or getEquippedPet()
        local insID = insForPet(petID)
        local e = makeFakePetData(petID)
        if not e then return end
        local list = { e }
        local payload = {
            equip_pet_id = petID, equip_pet_ins_id = insID,
            equipPetId = petID, equipPetInsId = insID,
            carry_flag = true, pet_cnt = 1,
            pets = list, pet_list = list, petList = list,
            dresses = {},
            pet_switch_effect = { all_effect = {}, equiped_effect = {} },
        }
        EventSystem:postEvent(EVENTTYPE_PET, 2033, payload)
        EventSystem:postEvent(EVENTTYPE_PET, 2013, petID)
        EventSystem:postEvent(EVENTTYPE_PET, 2016, {
            ServerInfo = { id = petID, ins_id = insID, color = 1, change = 0, exp = 0 },
            UID = "0",
        })
    end)
end

local function applyAutoEquip()
    local eq = getEquippedPet()
    if not eq then return end
    pcall(function()
        local PH = require("client.network.Protocol.PetHandler")
        if PH.send_equip_pet_req then PH.send_equip_pet_req(eq) end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- BOOT
-- ═══════════════════════════════════════════════════════════════════
local booted = false
local function boot()
    if booted then return end
    loadState()
    seedDefaults()
    local ok1 = hookTPD()
    if not ok1 then return end
    booted = true
    local ok2 = hookTPC()
    local ok3 = hookPetHandler()
    local ok4 = hookPool()
    local ok5 = hookLPB()
    local ok6 = hookPCAvatar()
    local ok7 = hookLogicEmote()
    local ok8 = hookQuickExpression()
    local ok9 = hookPetMain()
    local ok10 = installEventPatch()

    print("[pet_v14_skinfix] TPD=" .. tostring(ok1) .. " TPC=" .. tostring(ok2)
        .. " PH=" .. tostring(ok3) .. " pool=" .. tostring(ok4)
        .. " LPB=" .. tostring(ok5) .. " PCA=" .. tostring(ok6)
        .. " LE=" .. tostring(ok7) .. " QE=" .. tostring(ok8)
        .. " PM=" .. tostring(ok9) .. " evt=" .. tostring(ok10))

    pcall(function()
        local t = require("common.time_ticker")
        if not t then return end
        if t.AddTimerOnce then
            t.AddTimerOnce(1.0, applyAutoEquip)
            t.AddTimerOnce(2.0, reemit)
            t.AddTimerOnce(4.0, reemit)
        end
        if t.AddTimerLoop then
            t.AddTimerLoop(0, function() pcall(reemit) end, -1, 12)
            t.AddTimerLoop(0, function() pcall(forceStateLoop) end, -1, 3.0)
        end
    end)

    pcall(function()
        if not EventSystem then return end
        local t = require("common.time_ticker")
        if EVENTTYPE_LOBBY and EVENTID_SHOW_LOBBY then
            EventSystem:registEvent(EVENTTYPE_LOBBY, EVENTID_SHOW_LOBBY, function()
                t.AddTimerOnce(1.0, applyAutoEquip)
                t.AddTimerOnce(2.0, reemit)
                t.AddTimerOnce(4.0, reemit)
            end)
        end
    end)
end

local tries = 0
local function tryBoot()
    tries = tries + 1
    boot()
    if booted then return end
    if tries >= 60 then return end
    pcall(function()
        local t = require("common.time_ticker")
        t.AddTimerOnce(1.0, tryBoot)
    end)
end

pcall(function()
    local t = require("common.time_ticker")
    if t and t.AddTimerOnce then
        t.AddTimerOnce(0.5, tryBoot)
    else
        tryBoot()
    end
end)

_G.PetUnlock.Equip = function(petID)
    petID = resolvePetID(petID)
    if not petID then return false end
    _G.PetUnlock.equippedPetID = petID
    _pmChosenPetID = petID
    saveState()
    applyAutoEquip()
    reemit()
    return true
end

_G.PetUnlock.SetDress = function(petID, dressID)
    petID, dressID = resolvePetID(petID) or getEquippedPet(), tonumber(dressID) or 0
    if not petID then return false end
    pcall(function()
        local PH = require("client.network.Protocol.PetHandler")
        PH.send_pet_used_dress_req(petID, dressID)
    end)
    return true
end

_G.PetUnlock.PlayEmote = function(actionID) _G.PetEmotePlay(actionID) end
_G.PetUnlock.ApplyDress = function(dressID) _G.PetDressApply(getEquippedPet(), dressID) end
_G.PetUnlock.Refresh = function() applyAutoEquip(); reemit() end

print("[pet_v14_skinfix] loaded")
return _G.PetUnlock
end)()


-- ═══════════════════════════════════════════════════════════════════
-- pop_only.lua — 10M Popularity (single function)
-- ═══════════════════════════════════════════════════════════════════
_G.PopOnly = (function()
if _G._POPONLY then return _G.PopOnly end
_G._POPONLY = true

local function applyPopularity(POP_VAL)
    POP_VAL = tonumber(POP_VAL) or 10000000

    -- 1) Patch roleData directly
    pcall(function()
        if _G.DataMgr and _G.DataMgr.roleData then
            _G.DataMgr.roleData.total_devote = POP_VAL
            _G.DataMgr.roleData.upvote      = POP_VAL
        end
    end)

    -- 2) Hook popularity response
    pcall(function()
        local PH = require("client.network.Protocol.PopularityGiftHandler")
        if PH and type(PH.on_get_popularity_rsp) == "function"
           and not PH.__popHooked then
            PH.__popHooked = true
            local orig = PH.on_get_popularity_rsp
            PH.on_get_popularity_rsp = function(err, uid, total, ...)
                return orig(err, uid, POP_VAL, ...)
            end
        end
    end)

    -- 3) Keep patching via ticker loop
    pcall(function()
        local t = require("common.time_ticker")
        if t and t.AddTimerLoop and not _G.__popLoop then
            _G.__popLoop = true
            t.AddTimerLoop(0, function()
                pcall(function()
                    if _G.DataMgr and _G.DataMgr.roleData then
                        _G.DataMgr.roleData.total_devote = POP_VAL
                        _G.DataMgr.roleData.upvote      = POP_VAL
                    end
                end)
            end, -1, 3.0)
        end
    end)

    return POP_VAL
end

-- Run it
applyPopularity(10000000)

return applyPopularity
end)()


-- ═══════════════════════════════════════════════════════════════════
-- PROFILE SCENE PET — hook three-layer spawner
-- ═══════════════════════════════════════════════════════════════════
_G.ProfilePetHook = (function()
if _G._PPH_LOADED then return _G.ProfilePetHook end
_G._PPH_LOADED = true

local _unpack = unpack or table.unpack
local _orig = {}

local function getMyPetID()
    local pu = _G.PetUnlock
    if pu and pu.equippedPetID then
        local id = tonumber(pu.equippedPetID)
        if id and id >= 50000 and id <= 50099 then return id end
    end
    return 50047
end

local function isFakePetIns(ins)
    ins = tonumber(ins)
    if not ins then return false end
    return ins >= 3000000000 and ins <= 3000000100
end

local function fakeInsFor(petID)
    petID = tonumber(petID) or 50047
    return 3000000000 + (petID - 50000)
end

-- ═══════════════════════════════════════════════════════════════════
-- LAYER 1: SocialLobby_PetSlot_UIBP — profile scene slot UI
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local M = require("client.slua.umg.lobby.Left.3DUIOverride.SocialLobby_PetSlot_UIBP")
    if not M or not M.__inner_impl then return end
    local ii = M.__inner_impl

    local function wrap(name, fn)
        if type(ii[name]) ~= "function" then return end
        if _orig["PSPU_" .. name] then return end
        _orig["PSPU_" .. name] = ii[name]
        ii[name] = fn(_orig["PSPU_" .. name])
    end

    -- RefreshModelShow — force pet data before refresh
    wrap("RefreshModelShow", function(o)
        return function(self, ...)
            local args = {n = select("#", ...), ...}
            pcall(function()
                local pid = getMyPetID()
                -- Force pet slot data on the widget
                self.PetID = pid
                self.petID = pid
                self.PetInsID = fakeInsFor(pid)
                self.petInsID = fakeInsFor(pid)
                self.skinID = pid
                self.resID = pid
                if self.petData then
                    self.petData.petID = pid
                    self.petData.resID = pid
                end
            end)
            return o(self, _unpack(args, 1, args.n))
        end
    end)

    -- RefreshPetModelShow — refresh pet model with our ID
    wrap("RefreshPetModelShow", function(o)
        return function(self, ...)
            local args = {n = select("#", ...), ...}
            pcall(function()
                local pid = getMyPetID()
                if not args[1] or args[1] == 0 then
                    args[1] = pid
                    args.n = math.max(args.n, 1)
                end
            end)
            return o(self, _unpack(args, 1, args.n))
        end
    end)

    -- CheckRefreshModelShow — force true so it refreshes
    wrap("CheckRefreshModelShow", function(o)
        return function(self, ...)
            pcall(function()
                local pid = getMyPetID()
                self.PetID = pid
                self.petID = pid
            end)
            return o(self, ...)
        end
    end)

    -- _ResetModelShowState — after reset, re-force
    wrap("_ResetModelShowState", function(o)
        return function(self, ...)
            local r = o(self, ...)
            pcall(function()
                local pid = getMyPetID()
                self.PetID = pid
                self.petID = pid
            end)
            return r
        end
    end)

    -- ShowEditDressUI — after dress UI shown, re-apply
    wrap("ShowEditDressUI", function(o)
        return function(self, ...)
            local r = o(self, ...)
            pcall(function()
                if _G.PetDressApply then
                    local pu = _G.PetUnlock
                    local pid = getMyPetID()
                    local dress = pu and pu.petDresses and pu.petDresses[pid]
                    if dress and dress > 0 then
                        _G.PetDressApply(pid, dress)
                    end
                end
            end)
            return r
        end
    end)

    print("[PPH] Layer 1 hooked: SocialLobby_PetSlot_UIBP")
end)

-- ═══════════════════════════════════════════════════════════════════
-- LAYER 2: MultipleAvatar — profile pet creation
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local M = require("client.logic.avatar.MultipleAvatar")
    if not M or not M.__inner_impl then return end
    local ii = M.__inner_impl

    local function wrap(name, fn)
        if type(ii[name]) ~= "function" then return end
        if _orig["MA_" .. name] then return end
        _orig["MA_" .. name] = ii[name]
        ii[name] = fn(_orig["MA_" .. name])
    end

    wrap("RefreshOrCreatePet", function(o)
        return function(self, ...)
            local args = {n = select("#", ...), ...}
            pcall(function()
                local pid = getMyPetID()
                if not args[1] or args[1] == 0 or isFakePetIns(args[1]) then
                    args[1] = pid
                    args.n = math.max(args.n, 1)
                end
            end)
            return o(self, _unpack(args, 1, args.n))
        end
    end)

    wrap("SetPet", function(o)
        return function(self, petID, ...)
            local args = {n = select("#", ...), ...}
            if not petID or petID == 0 or isFakePetIns(petID) then
                petID = getMyPetID()
            end
            return o(self, petID, _unpack(args, 1, args.n))
        end
    end)

    wrap("GetPet", function(o)
        return function(self, ...)
            local r = o(self, ...)
            if not r then
                pcall(function()
                    local pid = getMyPetID()
                    if _G.PetUnlock then
                        return { petID = pid, resID = pid, insID = fakeInsFor(pid) }
                    end
                end)
            end
            return r
        end
    end)

    wrap("UpdateLobbyCharacterPetState", function(o)
        return function(self, ...)
            local args = {n = select("#", ...), ...}
            pcall(function()
                if args[1] == nil or args[1] == 0 then
                    args[1] = getMyPetID()
                    args.n = math.max(args.n, 1)
                end
            end)
            return o(self, _unpack(args, 1, args.n))
        end
    end)

    print("[PPH] Layer 2 hooked: MultipleAvatar")
end)

-- ═══════════════════════════════════════════════════════════════════
-- LAYER 3: pet_manager — global pet spawner
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local M = require("client.slua.logic.pet.pet_manager")
    if not M or not M.__inner_impl then return end
    local ii = M.__inner_impl

    local function wrap(name, fn)
        if type(ii[name]) ~= "function" then return end
        if _orig["PM_" .. name] then return end
        _orig["PM_" .. name] = ii[name]
        ii[name] = fn(_orig["PM_" .. name])
    end

    wrap("RefreshOrCreatePet", function(o)
        return function(self, petData, ...)
            local args = {n = select("#", ...), ...}
            -- petData is first arg
            if type(petData) == "table" then
                pcall(function()
                    local pid = getMyPetID()
                    petData.petID = pid
                    petData.resID = pid
                    petData.insID = fakeInsFor(pid)
                    petData.uid = petData.uid or (_G.DataMgr and _G.DataMgr.roleData and _G.DataMgr.roleData.uid)
                    petData.isSelf = true
                    petData.showInProfile = true
                end)
            elseif not petData or petData == 0 or isFakePetIns(petData) then
                petData = getMyPetID()
            end
            return o(self, petData, _unpack(args, 1, args.n))
        end
    end)

    wrap("GetPet", function(o)
        return function(self, ...)
            local r = o(self, ...)
            if not r then
                pcall(function()
                    local pid = getMyPetID()
                    return { petID = pid, resID = pid, insID = fakeInsFor(pid) }
                end)
            end
            return r
        end
    end)

    wrap("RegisterPet", function(o)
        return function(self, petID, ...)
            local args = {n = select("#", ...), ...}
            if not petID or petID == 0 or isFakePetIns(petID) then
                petID = getMyPetID()
            end
            return o(self, petID, _unpack(args, 1, args.n))
        end
    end)

    print("[PPH] Layer 3 hooked: pet_manager")
end)

-- ═══════════════════════════════════════════════════════════════════
-- LAYER 4: pet_pawn_pool — actual spawn actor
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local M = require("client.slua.logic.pet.pet_pawn_pool")
    if not M or not M.__inner_impl then return end
    local ii = M.__inner_impl

    local function wrap(name, fn)
        if type(ii[name]) ~= "function" then return end
        if _orig["PPP_" .. name] then return end
        _orig["PPP_" .. name] = ii[name]
        ii[name] = fn(_orig["PPP_" .. name])
    end

    wrap("_CreatePetPawn", function(o)
        return function(self, ...)
            local args = {n = select("#", ...), ...}
            local j
            for j = 1, args.n do
                if isFakePetIns(args[j]) then
                    args[j] = getMyPetID()
                end
            end
            if not args[1] or args[1] == 0 then
                args[1] = getMyPetID()
                args.n = math.max(args.n, 1)
            end
            local r = o(self, _unpack(args, 1, args.n))
            if r and type(r) == "userdata" then
                pcall(function() r.ConfigID = getMyPetID() end)
            end
            return r
        end
    end)

    wrap("SetPetPawnEnabled", function(o)
        return function(self, ...)
            local args = {n = select("#", ...), ...}
            pcall(function()
                if args[1] == nil or args[1] == 0 then
                    args[1] = getMyPetID()
                    args.n = math.max(args.n, 1)
                end
                -- Force enabled true
                args[2] = true
            end)
            return o(self, _unpack(args, 1, args.n))
        end
    end)

    print("[PPH] Layer 4 hooked: pet_pawn_pool")
end)

-- ═══════════════════════════════════════════════════════════════════
-- LAYER 5: LobbyAvatar.CreateMyPetIfNot — top-level pet creation
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local M = require("client.logic.avatar.LobbyAvatar")
    if not M or not M.__inner_impl then return end
    local ii = M.__inner_impl

    if type(ii.CreateMyPetIfNot) == "function" and not _orig["LA_CreateMyPetIfNot"] then
        _orig["LA_CreateMyPetIfNot"] = ii.CreateMyPetIfNot
        ii.CreateMyPetIfNot = function(self, ...)
            local r = _orig["LA_CreateMyPetIfNot"](self, ...)
            pcall(function()
                if _G.PetUnlock and _G.PetUnlock.equippedPetID then
                    local pid = getMyPetID()
                    if self and self.petID ~= pid then
                        self.petID = pid
                    end
                end
            end)
            return r
        end
    end
    print("[PPH] Layer 5 hooked: LobbyAvatar.CreateMyPetIfNot")
end)

print("[PPH] Profile Scene Pet Hooks — ALL LAYERS INSTALLED")

-- ═══════════════════════════════════════════════════════════════════
-- AUTO-TICK — force re-refresh on profile open
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local ticker = require("common.time_ticker")
    if not ticker or not ticker.AddTimerLoop then return end

    local _profileOpen = false
    ticker.AddTimerLoop(0, function()
        pcall(function()
            -- Detect if profile/person space is open
            local isOpen = false
            pcall(function()
                local M = package.loaded["client.slua.umg.lobby.Left.Lobby_SocialLobby_UIBP"]
                if M and M.__inner_impl then
                    -- profile scene active if this UI is loaded
                    isOpen = true
                end
            end)

            if isOpen then
                -- Force pet refresh
                pcall(function()
                    local MA = package.loaded["client.logic.avatar.MultipleAvatar"]
                    if MA and MA.__inner_impl and MA.__inner_impl.RefreshOrCreatePet then
                        MA.__inner_impl.RefreshOrCreatePet(MA.__inner_impl)
                    end
                end)
            end
        end)
    end, -1, 2.0)
end)

return _G.ProfilePetHook
end)()

pcall(function()
    local ticker = require("common.time_ticker")
    if not ticker or not ticker.AddTimerLoop then return end

    local _wCount = 0
    local _lastHash = ""

    ticker.AddTimerLoop(0, function()
        pcall(function()
            _wCount = _wCount + 1

            if not (GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus()) then
                return
            end

            local GD = require("GameLua.GameCore.Data.GameplayData")
            if not GD or not GD.GetPlayerCharacter then return end
            local char = GD.GetPlayerCharacter()
            if not char or not slua.isValid(char) then return end
            local comp = char.CharacterAvatarComp2_BP
            if not slua.isValid(comp) then return end

            local cch = _G.AddOutfitEquippedCache
            if not cch then return end

            -- ★ FIX: wid hash se hata diya — weapon change pe trigger band
            local hash = tostring(cch.outfitRes or 0) .. "|" ..
                         tostring(cch.equip and cch.equip.bag or 0) .. "|" ..
                         tostring(cch.equip and cch.equip.helmet or 0) .. "|" ..
                         tostring(cch.equip and cch.equip.armor or 0)

            -- ★ FIX: force tick 9s → 45s
            local forceTick = (_wCount % 15 == 0)

            if hash == _lastHash and not forceTick then return end
            _lastHash = hash

            local didSomething = false

            if cch.outfitRes and tonumber(cch.outfitRes) > 0 then
                pcall(function()
                    if comp.PutOnCustomEquipmentByID then
                        comp:PutOnCustomEquipmentByID(cch.outfitRes)
                        didSomething = true
                    end
                end)
            end

            if cch.clothes then
                for resID in pairs(cch.clothes) do
                    resID = tonumber(resID)
                    if resID and resID > 0 then
                        pcall(function()
                            if comp.PutOnCustomEquipmentByID then
                                comp:PutOnCustomEquipmentByID(resID)
                                didSomething = true
                            end
                        end)
                    end
                end
            end

            if cch.equip then
                for _, slot in ipairs({ "bag", "helmet", "armor", "parachute", "glider" }) do
                    local rid = cch.equip[slot]
                    if rid and tonumber(rid) > 0 then
                        pcall(function()
                            if comp.PutOnCustomEquipmentByID then
                                comp:PutOnCustomEquipmentByID(rid)
                                didSomething = true
                            end
                        end)
                    end
                end
            end

            -- ★ FIX: equip_weapon_avatar HATA diya — 1s stutter ka source
            -- (fastApplyLoop 5s pe alag se karta hai)

            if didSomething then
                pcall(function()
                    if comp.ProcessAvatarRectify then comp:ProcessAvatarRectify() end
                end)
            end
        end)
    end, -1, 3.0)   -- ★ 1.5s → 3.0s
end)                                                          -- [CLOSE E] outer pcall



-- ═══════════════════════════════════════════════════════════════════════════
-- CRATE / SHOP / GACHA BYPASS — Complete Working Module
-- Standalone. Includes glue + chunk. No external deps needed.
-- ═══════════════════════════════════════════════════════════════════════════
pcall(function()

    -- ─────────────────────────────────────────────────────────────────────
    -- GLUE — Missing dependencies
    -- ─────────────────────────────────────────────────────────────────────
    local SafeRequire = _G.SafeRequire
if not SafeRequire then
    local _cache = {}
    SafeRequire = function(path)
        if _cache[path] ~= nil then return _cache[path] end
        local loaded = package.loaded[path]
        if loaded then _cache[path] = loaded; return loaded end
        local ok, mod = pcall(require, path)
        if ok and mod then _cache[path] = mod; return mod end
        _cache[path] = false
        return nil
    end
    _G.SafeRequire = SafeRequire
end
local safeReq = SafeRequire

local SafePostEvent = _G.SafePostEvent or function(evtType, evtId, ...)
    local args = { n = select("#", ...), ... }
    pcall(function()
        if EventSystem and EventSystem.postEvent then
            EventSystem:postEvent(evtType, evtId, table.unpack(args, 1, args.n))
        end
    end)
end
_G.SafePostEvent = SafePostEvent

    local NowSec = _G.NowSec or function()
        local t = 0
        pcall(function() t = os.time() end)
        if t == 0 then pcall(function() t = os.clock() end) end
        return t
    end
    _G.NowSec = NowSec

    local FAKE_UC = 999999999
    local GetFakeUC = _G.GetFakeUC or function() return FAKE_UC end
    local HasEnoughUC = _G.HasEnoughUC or function(...) return true end
    local TrySpendUC = _G.TrySpendUC or function(...) return true end
    _G.GetFakeUC = GetFakeUC
    _G.HasEnoughUC = HasEnoughUC
    _G.TrySpendUC = TrySpendUC

    _G._lastUCCheckPrice = _G._lastUCCheckPrice or 0
    local CaptureUCPrice = _G.CaptureUCPrice or function(a, b, ...)
        local n = tonumber(b) or tonumber(a) or 0
        if n > 0 then _G._lastUCCheckPrice = n end
        return _G._lastUCCheckPrice
    end
    _G.CaptureUCPrice = CaptureUCPrice

    local GetBuyUCCost = _G.GetBuyUCCost or function(params)
        if type(params) == "table" then
            local n = tonumber(params[2]) or tonumber(params.price) or tonumber(params[8])
            if n and n > 0 then return n end
        end
        return CaptureUCPrice(params)
    end
    _G.GetBuyUCCost = GetBuyUCCost

    local ResolveDrawUCCost = _G.ResolveDrawUCCost or function() return 0 end
    _G.ResolveDrawUCCost = ResolveDrawUCCost

    local _lastBuyAction = {}
    local BeginBuyAction = _G.BeginBuyAction or function(key)
        local now = NowSec()
        local last = _lastBuyAction[key] or 0
        if now - last < 0.5 then return false end
        _lastBuyAction[key] = now
        return true
    end
    _G.BeginBuyAction = BeginBuyAction

    local ExtractRewardList = _G.ExtractRewardList or function(activityData)
        local out = {}
        if not activityData then return out end
        local list = nil
        if activityData.poolItemConfig and #activityData.poolItemConfig > 0 then list = activityData.poolItemConfig
        elseif activityData.CurBigAwardPoolConfig then list = activityData.CurBigAwardPoolConfig
        elseif activityData.CurSmallAwardPoolConfig then list = activityData.CurSmallAwardPoolConfig
        elseif activityData.dropList then list = activityData.dropList
        elseif activityData.pool_info then list = activityData.pool_info
        elseif activityData.Items then list = activityData.Items end
        if list then
            for _, row in ipairs(list) do
                local rid = tonumber(row.resid or row.res_id or row.item_id or row.itemid or row.id or 0)
                local cnt = tonumber(row.count or row.item_count or row.num or 1) or 1
                if rid and rid > 0 then
                    out[#out + 1] = { resid = rid, count = cnt, valid_hours = tonumber(row.valid_hours or 0) or 0 }
                end
            end
        end
        return out
    end
    _G.ExtractRewardList = ExtractRewardList

    local ExtractPackageRewards = _G.ExtractPackageRewards or function(packageId, fallbackId, count)
        count = tonumber(count) or 1
        local out = {}
        local fallback = tonumber(fallbackId or packageId) or 403003
        pcall(function()
            local cfg = CDataTable and CDataTable.GetTableData and CDataTable.GetTableData("StoreItem", tonumber(packageId))
            if cfg and cfg.item_list then
                for _, row in ipairs(cfg.item_list) do
                    local rid = tonumber(row.item_id or row.itemid or row.resid)
                    if rid then
                        out[#out + 1] = { resid = rid, count = tonumber(row.count or 1), valid_hours = 0 }
                    end
                end
            end
        end)
        if #out == 0 then
            for i = 1, math.min(count, 10) do
                out[#out + 1] = { resid = fallback, count = 1, valid_hours = 0 }
            end
        end
        return out
    end
    _G.ExtractPackageRewards = ExtractPackageRewards

    local AutoAddToInventory = _G.AutoAddToInventory or function(rewards) end
    local addItemToInventory = AutoAddToInventory
    _G.AutoAddToInventory = AutoAddToInventory
    _G.addItemToInventory = AutoAddToInventory

    local ShowRewardPanel = _G.ShowRewardPanel or function(rewards)
        pcall(function()
            if not rewards then return end
            local Logic_CommonItemGet = SafeRequire("client.slua.logic.common.CommonItemGet.Logic_CommonItemGet")
            if Logic_CommonItemGet and Logic_CommonItemGet.ShowPanel_DefaultStyle then
                local list = {}
                for _, r in ipairs(rewards) do
                    list[#list + 1] = {
                        res_id = r.resid or r.res_id,
                        count = r.count or 1,
                        valid_hours = r.valid_hours or 0,
                    }
                end
                Logic_CommonItemGet.ShowPanel_DefaultStyle(list, false, true)
                return
            end
            if UIManager and UIManager.UI_Config and UIManager.UI_Config.new_supply_get_panel then
                local list = {}
                for _, r in ipairs(rewards) do
                    list[#list + 1] = {
                        res_id = r.resid or r.res_id,
                        count = r.count or 1,
                        valid_hours = r.valid_hours or 0,
                    }
                end
                UIManager.ShowUI(UIManager.UI_Config.new_supply_get_panel, list, #list >= 10, {needShowMovie = true})
            end
        end)
    end
    local EndRewardPanel = _G.EndRewardPanel or function() end
    _G.ShowRewardPanel = ShowRewardPanel
    _G.EndRewardPanel = EndRewardPanel

    local StoreConst = _G.StoreConst or { label_item_index_id = "itemid" }
    _G.StoreConst = StoreConst

    -- ITEMS access — AddOutfit exposes this via _G.AddOutfitAllItems
    local ITEMS = _G.AddOutfitAllItems or {}

    -- ═════════════════════════════════════════════════════════════════════
    -- CHUNK BODY — Item pool + fake generator helpers
    -- ═════════════════════════════════════════════════════════════════════
    local _validItemPool = nil
    local function getValidItemPool()
        if _validItemPool then return _validItemPool end
        _validItemPool = {}
        for _, id in ipairs(ITEMS) do
            local n = tonumber(id)
            if n and n > 0 then
                local cfg = nil
                pcall(function()
                    if CDataTable and CDataTable.GetTableData then
                        cfg = CDataTable.GetTableData("Item", n)
                    end
                end)
                if cfg then
                    table.insert(_validItemPool, n)
                end
            end
        end
        if #_validItemPool == 0 then
            for _, id in ipairs(ITEMS) do
                local n = tonumber(id)
                if n and n > 0 then table.insert(_validItemPool, n) end
            end
        end
        return _validItemPool
    end

    local function getCrateItemsFromUI()
        local result = {}
        pcall(function()
            if UIManager and UIManager.UI_Config then
                local store_supply_switcher = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.store_supply_switcher)
                if store_supply_switcher then
                    local supplySystem = store_supply_switcher:GetSupplySystem()
                    if supplySystem and supplySystem.PageListPanel and supplySystem.PageListPanel.itemDataList then
                        for _, v in pairs(supplySystem.PageListPanel.itemDataList) do
                            if v.itemId and tonumber(v.itemId) and tonumber(v.itemId) > 0 then
                                table.insert(result, tonumber(v.itemId))
                            end
                        end
                    end
                    if #result == 0 then
                        local storeSystem = store_supply_switcher:GetStoreSystem()
                        if storeSystem and storeSystem.PageListPanel and storeSystem.PageListPanel.itemDataList then
                            for _, v in pairs(storeSystem.PageListPanel.itemDataList) do
                                if v.itemId and tonumber(v.itemId) and tonumber(v.itemId) > 0 then
                                    table.insert(result, tonumber(v.itemId))
                                end
                            end
                        end
                    end
                end
            end
        end)
        return result
    end

    local function makeFakeItemList(count)
        count = count or 1
        local list = {}
        local pool = getCrateItemsFromUI()
        if #pool == 0 then
            pool = getValidItemPool()
        end
        if #pool == 0 then return list end
        for i = 1, count do
            local resId = pool[math.random(#pool)]
            table.insert(list, {
                resid = resId,
                res_id = resId,
                count = 1,
                valid_hours = 0,
                is_luck = (i == 1),
                order = i,
                drop_fun = 0,
                must_reward = (i == 1) and 1 or 0,
                to_res_id = 0,
                to_res_cnt = 0,
                ShowUseTime = true,
                getTags = 0,
            })
            pcall(addItemToInventory, resId)
        end
        return list
    end

    local function makeDecomposeList(itemList)
        local dec = {}
        for i, v in pairs(itemList) do
            dec[i] = { resid = 0, count = 0 }
        end
        return dec
    end

    local function makeExtraInfo()
        return {
            cur_chest_progress = 0,
            cur_draw_voucher_num = 0,
            uc_cost = 0,
            uc_ten_cost = 0,
            can_dis_draw = false,
            dis_draw_price = 0,
            return_uc_count = 0,
        }
    end

    local function showGetPanel(itemList, isTen)
        pcall(function()
            local rewardList = {}
            for _, v in pairs(itemList) do
                table.insert(rewardList, {
                    res_id = v.res_id or v.resid,
                    count = v.count or 1,
                    valid_hours = v.valid_hours or 0,
                    getTags = v.drop_fun or 0,
                    to_res_id = v.to_res_id or 0,
                    to_res_cnt = v.to_res_cnt or 0,
                    ShowUseTime = true,
                })
            end
            if UIManager and UIManager.UI_Config and UIManager.UI_Config.new_supply_get_panel then
                if UIManager.IsUIShow and UIManager.IsUIShow(UIManager.UI_Config.new_supply_get_panel) then
                    local boxUI = UIManager.GetUI(UIManager.UI_Config.new_supply_get_panel)
                    if boxUI and boxUI.TryShowSupplyGetPanel then
                        boxUI:TryShowSupplyGetPanel(rewardList, isTen, {needShowMovie = true})
                    end
                else
                    UIManager.ShowUI(UIManager.UI_Config.new_supply_get_panel, rewardList, isTen, {needShowMovie = true})
                end
            end
        end)
    end

    -- ═════════════════════════════════════════════════════════════════════
    -- SECTION A — Direct handler hooks (crate/supply/payment)
    -- ═════════════════════════════════════════════════════════════════════

    -- 4a. LogicSupply bypass
    local LogicSupply = safeReq("client.slua.logic.supply.logic_supply")
    if LogicSupply and not LogicSupply._supplyHooked then
        LogicSupply._supplyHooked = true
        LogicSupply.IsCanBuySupplyBox = function(item_id) return true end
        LogicSupply.CheckHasSelectWish = function(tabId, boxItemId) return true end
        LogicSupply.CheckCrateLimitTime = function(boxEndTime) return false end
        LogicSupply.ShowTipsWhenHaveFreeBan = function(itemId, isOne) return false end
    end

    -- 4b. StoreHandler
    local StoreHandlerA = safeReq("client.network.Protocol.StoreHandler")
    if StoreHandlerA and not StoreHandlerA._crateHooked then
        StoreHandlerA._crateHooked = true

        StoreHandlerA.send_buy_shop_by_id_req = function(params)
            local isTen = false
            local shopId = 0
            if type(params) == "table" then
                shopId = tonumber(params[1]) or 0
                local buyCount = tonumber(params[8]) or 1
                if buyCount == 10 then isTen = true end
            end
            local itemList = makeFakeItemList(isTen and 10 or 1)
            showGetPanel(itemList, isTen)
            local info = { draw_flag = 0 }
            pcall(StoreHandlerA.on_buy_shop_by_id_rsp, 0, shopId, info, nil)
        end

        StoreHandlerA.send_buy_market_by_id_req = function(params)
            local marketId = (type(params) == "table" and tonumber(params[1])) or 0
            local count = (type(params) == "table" and tonumber(params[8])) or 1
            local isTen = count == 10
            local itemList = makeFakeItemList(isTen and 10 or 1)
            showGetPanel(itemList, isTen)
            pcall(StoreHandlerA.on_buy_market_by_id_rsp, 0, marketId, itemList)
        end

        StoreHandlerA.send_get_market_chest_info_req = function(market_id)
            local data = { box_id = market_id, drop_items = makeFakeItemList(10) }
            pcall(StoreHandlerA.on_get_market_chest_info_rsp, 0, market_id, data, makeFakeItemList(5))
        end

        StoreHandlerA.send_receive_guarantee_reward_req = function(reward_items, is_ams_chest)
            pcall(StoreHandlerA.on_receive_guarantee_reward_rsp, 0, reward_items, "")
        end

        StoreHandlerA.send_do_one_draw_by_activity_req = function(activityId, roundCount, hadDrawCount, curVoucherId)
            local itemList = makeFakeItemList(1)
            showGetPanel(itemList, false)
            pcall(StoreHandlerA.on_buy_shop_by_id_rsp, 0, activityId, { draw_flag = 0 }, nil)
        end

        StoreHandlerA.send_do_biochemical_activity_one_draw_req = function(round_count, draw_count, voucherId)
            local count = tonumber(draw_count) or 1
            local itemList = makeFakeItemList(count)
            showGetPanel(itemList, count >= 10)
        end

        StoreHandlerA.send_buy_stage_chest = function(activity_id)
            local itemList = makeFakeItemList(10)
            showGetPanel(itemList, true)
        end

        StoreHandlerA.send_newbie_chest_buy = function(activity_id)
            local itemList = makeFakeItemList(1)
            showGetPanel(itemList, false)
        end

        StoreHandlerA.send_limited_discount_buy = function(activityId, index, num)
            local count = tonumber(num) or 1
            local itemList = makeFakeItemList(count)
            showGetPanel(itemList, count >= 10)
        end

        StoreHandlerA.send_activity_market_buy_req = function(activityId)
            local itemList = makeFakeItemList(1)
            showGetPanel(itemList, false)
        end

        StoreHandlerA.send_chest_collect_req = function(chest_id, source_type, collected_state)
            pcall(StoreHandlerA.on_add_market_collect_by_item_rsp, 0, {}, source_type, chest_id, 1)
        end
    end

    -- 4c. SupplyOptionalHandler
    local SupplyOptionalHandler = safeReq("client.network.Protocol.SupplyOptionalHandler")
    if SupplyOptionalHandler and not SupplyOptionalHandler._hooked then
        SupplyOptionalHandler._hooked = true
        SupplyOptionalHandler.send_get_role_custom_chest_info_req = function()
            local retInfo = { must_reward_id = 0, free_draw_flag = 1, draw_count = 0 }
            pcall(SupplyOptionalHandler.on_get_role_custom_chest_info_rsp, 0, retInfo)
        end
        SupplyOptionalHandler.send_role_chest_custom_buy_req = function(priceData)
            local drawType = (type(priceData) == "table" and tonumber(priceData.draw_type)) or 1
            local isTen = drawType == 10
            local itemList = makeFakeItemList(isTen and 10 or 1)
            local decList = makeDecomposeList(itemList)
            local otherInfo = { must_reward = 0 }
            pcall(SupplyOptionalHandler.on_role_chest_custom_buy_rsp, 0, itemList, decList, otherInfo)
        end
        SupplyOptionalHandler.send_role_chest_exchange_temp_item_req = function(operation_type, temp_list)
            local retInfo = { item_info = makeFakeItemList(1), decompose_list = {}, waiting_decompose_list = {} }
            pcall(SupplyOptionalHandler.on_role_chest_exchange_temp_item_rsp, 0, retInfo)
        end
        SupplyOptionalHandler.send_get_role_exchange_history_info_req = function()
            pcall(SupplyOptionalHandler.on_get_role_exchange_history_info_rsp, 0, {}, {})
        end
    end

    -- 4d. CustomCrateHandler
    local CustomCrateHandler = safeReq("client.network.Protocol.CustomCrateHandler")
    if CustomCrateHandler and not CustomCrateHandler._hooked then
        CustomCrateHandler._hooked = true
        CustomCrateHandler.send_custom_chest_get_data_req = function(chest_id)
            pcall(CustomCrateHandler.on_custom_chest_get_data_rsp, chest_id, {}, 1, 0, {})
        end
        CustomCrateHandler.send_custom_chest_get_credit_req = function()
            pcall(CustomCrateHandler.on_custom_chest_get_credit_rsp, 99999, 0, {})
        end
        CustomCrateHandler.send_custom_chest_credit_exchange_req = function()
            pcall(CustomCrateHandler.on_custom_chest_credit_exchange_rsp, 0, makeFakeItemList(1))
        end
        CustomCrateHandler.send_custom_chest_credit_exchange_req_v1 = function()
            pcall(CustomCrateHandler.on_custom_chest_credit_exchange_rsp, 0, makeFakeItemList(1))
        end
        CustomCrateHandler.send_custom_chest_ban_item_req = function(chest_id, items, cost, pay_method)
            pcall(CustomCrateHandler.on_custom_chest_ban_item_rsp, chest_id, items, 0, 0, {})
        end
    end

    -- 4e. CommonChestModeHandler
    local CommonChestModeHandler = safeReq("client.network.Protocol.CommonChestModeHandler")
    if CommonChestModeHandler and not CommonChestModeHandler._hooked then
        CommonChestModeHandler._hooked = true
        CommonChestModeHandler.send_custom_chest_get_items_req = function(chest_id)
            pcall(CommonChestModeHandler.on_custom_chest_get_items_rsp, 0, chest_id, makeFakeItemList(10))
        end
    end

    -- 4f. TarotCardHandler
    local TarotCardHandler = safeReq("client.network.Protocol.TarotCardHandler")
    if TarotCardHandler and not TarotCardHandler._hooked then
        TarotCardHandler._hooked = true
        TarotCardHandler.send_get_tarot_draw_activity_req = function()
            local retTable = { draw_count = 0, free_draw_flag = 1 }
            local poolInfo = { one_draw_cost = 0, ten_draw_cost = 0 }
            pcall(TarotCardHandler.on_get_tarot_draw_activity_rsp, 0, retTable, poolInfo, {}, 0)
        end
        TarotCardHandler.send_draw_tarot_req = function(cost_times, draw_type, voucher_id)
            local count = (tonumber(cost_times) or 1) >= 10 and 10 or 1
            local itemList = makeFakeItemList(count)
            for i, v in pairs(itemList) do
                v.rankTitleType = 0
                v.chief_event_share_count_bak = 0
                v.king_event_share_count_bak = 0
            end
            pcall(TarotCardHandler.on_draw_tarot_rsp, 0, itemList, makeDecomposeList(itemList), makeExtraInfo())
        end
        TarotCardHandler.send_get_progress_reward_req = function(consume_all)
            pcall(TarotCardHandler.on_get_progress_reward_rsp, 0, 0, makeFakeItemList(1), {}, 0)
        end
        TarotCardHandler.send_get_taluo_attract_reward_req = function()
            pcall(TarotCardHandler.on_get_taluo_attract_reward_rsp, 0, makeFakeItemList(1), 1)
        end
    end

    -- 4g. TeddyBearMonsterHandler
    local TeddyBearMonsterHandler = safeReq("client.network.Protocol.TeddyBearMonsterHandler")
    if TeddyBearMonsterHandler and not TeddyBearMonsterHandler._hooked then
        TeddyBearMonsterHandler._hooked = true
        TeddyBearMonsterHandler.send_get_multi_pool_draw_info_req = function()
            local drawInfo = {
                award_pool_info = {}, acc_list_info = {},
                cost_info = { one_draw_cost = 0, ten_draw_cost = 0 }, ext_info = {},
            }
            pcall(TeddyBearMonsterHandler.on_get_multi_pool_draw_info_rsp, 0, drawInfo)
        end
        TeddyBearMonsterHandler.send_multi_pool_draw_req = function(cost_times, currency_id, pool_id, voucher_id)
            local count = (tonumber(cost_times) or 1) >= 10 and 10 or 1
            local itemList = makeFakeItemList(count)
            showGetPanel(itemList, count >= 10)
            pcall(TeddyBearMonsterHandler.on_multi_pool_draw_rsp, 0, itemList, makeDecomposeList(itemList), {}, {})
        end
        TeddyBearMonsterHandler.send_get_multi_pool_acc_reward_req = function(times)
            pcall(TeddyBearMonsterHandler.on_get_multi_pool_acc_reward_rsp, 0, makeFakeItemList(1), {})
        end
    end

    -- 4h. XSuitHandler (gold dress)
    local XSuitHandlerA = safeReq("client.network.Protocol.XSuitHandler")
    if XSuitHandlerA and not XSuitHandlerA._goldHooked then
        XSuitHandlerA._goldHooked = true
        XSuitHandlerA.send_draw_gold_dress_req = function(cost_times, currency_id, voucher_id, pool_id)
            local count = (tonumber(cost_times) or 1) >= 10 and 10 or 1
            local itemList = makeFakeItemList(count)
            pcall(XSuitHandlerA.on_draw_gold_dress_rsp, 0, itemList, makeDecomposeList(itemList), {}, 0, false, 0)
        end
    end

    -- 4i. UpassCustomChestHandler
    local UpassCustomChestHandler = safeReq("client.network.Protocol.UpassCustomChestHandler")
    if UpassCustomChestHandler and not UpassCustomChestHandler._hooked then
        UpassCustomChestHandler._hooked = true
        UpassCustomChestHandler.send_get_rp_custom_extra_chest_req = function(open_all)
            pcall(UpassCustomChestHandler.on_get_rp_custom_extra_chest_rsp, 0, makeFakeItemList(1), 0, {})
        end
        UpassCustomChestHandler.send_open_rp_custom_chest_req = function(num, cost_type, voucher_list)
            local count = tonumber(num) or 1
            local itemList = makeFakeItemList(count)
            pcall(UpassCustomChestHandler.on_open_rp_custom_chest_rsp, 0, itemList, {}, {}, makeDecomposeList(itemList))
        end
    end

    -- 4j. DropBoxHandler
    local DropBoxHandler = safeReq("client.network.Protocol.DropBoxHandler")
    if DropBoxHandler and not DropBoxHandler._hooked then
        DropBoxHandler._hooked = true
        for k, v in pairs(DropBoxHandler) do
            if type(k) == "string" and k:find("^send_") and type(v) == "function" then
                local rspName = k:gsub("^send_", "on_") .. "_rsp"
                DropBoxHandler[k] = function(...)
                    if DropBoxHandler[rspName] then
                        pcall(DropBoxHandler[rspName], 0, makeFakeItemList(1))
                    end
                end
            end
        end
    end

    -- 4k. BonusHandler
    local BonusHandler = safeReq("client.network.Protocol.BonusHandler")
    if BonusHandler and not BonusHandler._hooked then
        BonusHandler._hooked = true
        for k, v in pairs(BonusHandler) do
            if type(k) == "string" and k:find("^send_") and type(v) == "function" then
                local rspName = k:gsub("^send_", "on_") .. "_rsp"
                BonusHandler[k] = function(...)
                    if BonusHandler[rspName] then
                        pcall(BonusHandler[rspName], 0, makeFakeItemList(1))
                    end
                end
            end
        end
    end

    -- 4l. ExploreHandler
    local ExploreHandler = safeReq("client.network.Protocol.ExploreHandler")
    if ExploreHandler and not ExploreHandler._hooked then
        ExploreHandler._hooked = true
        for k, v in pairs(ExploreHandler) do
            if type(k) == "string" and k:find("^send_") and type(v) == "function" then
                local rspName = k:gsub("^send_", "on_") .. "_rsp"
                ExploreHandler[k] = function(...)
                    if ExploreHandler[rspName] then
                        pcall(ExploreHandler[rspName], 0, makeFakeItemList(1))
                    end
                end
            end
        end
    end

    -- 4m. EveryDayPackHandler / EverydayV2PackHandler
    local EveryDayPackHandler = safeReq("client.network.Protocol.EveryDayPackHandler")
    if EveryDayPackHandler and not EveryDayPackHandler._hooked then
        EveryDayPackHandler._hooked = true
        for k, v in pairs(EveryDayPackHandler) do
            if type(k) == "string" and k:find("^send_") and type(v) == "function" then
                local rspName = k:gsub("^send_", "on_") .. "_rsp"
                EveryDayPackHandler[k] = function(...)
                    if EveryDayPackHandler[rspName] then
                        pcall(EveryDayPackHandler[rspName], 0, makeFakeItemList(1))
                    end
                end
            end
        end
    end

    local EverydayV2PackHandler = safeReq("client.network.Protocol.EverydayV2PackHandler")
    if EverydayV2PackHandler and not EverydayV2PackHandler._hooked then
        EverydayV2PackHandler._hooked = true
        for k, v in pairs(EverydayV2PackHandler) do
            if type(k) == "string" and k:find("^send_") and type(v) == "function" then
                local rspName = k:gsub("^send_", "on_") .. "_rsp"
                EverydayV2PackHandler[k] = function(...)
                    if EverydayV2PackHandler[rspName] then
                        pcall(EverydayV2PackHandler[rspName], 0, makeFakeItemList(1))
                    end
                end
            end
        end
    end

    -- 4n. Generic handlers
    local function hookGenericHandler(handlerName, path)
        local H = safeReq(path)
        if H and not H._hooked then
            H._hooked = true
            for k, v in pairs(H) do
                if type(k) == "string" and k:find("^send_") and type(v) == "function" then
                    local rspName = k:gsub("^send_", "on_") .. "_rsp"
                    H[k] = function(...)
                        if H[rspName] then
                            pcall(H[rspName], 0, makeFakeItemList(1))
                        end
                    end
                end
            end
        end
    end
    hookGenericHandler("ConditionGiftHandler", "client.network.Protocol.ConditionGiftHandler")
    hookGenericHandler("GiftExchangeHandler", "client.network.Protocol.GiftExchangeHandler")
    hookGenericHandler("CorpsGiftExchangeHandler", "client.network.Protocol.CorpsGiftExchangeHandler")
    hookGenericHandler("LadderDrawHandler", "client.network.Protocol.LadderDrawHandler")
    hookGenericHandler("PHomeDrawRewardHandler", "client.network.Protocol.PHomeDrawRewardHandler")
    hookGenericHandler("ThemeSystemHandler", "client.network.Protocol.ThemeSystemHandler")
    hookGenericHandler("TxMissionHandler", "client.network.Protocol.TxMissionHandler")

    -- 4o. supply_payment bypass
    local supply_payment_manager = safeReq("client.slua.logic.supply.supply_payment.supply_payment_manager")
    if supply_payment_manager and not supply_payment_manager._hooked then
        supply_payment_manager._hooked = true
        if supply_payment_manager.CheckCanPay then supply_payment_manager.CheckCanPay = function(...) return true end end
        if supply_payment_manager.CanPay then supply_payment_manager.CanPay = function(...) return true end end
        if supply_payment_manager.CheckBeforeBuy then supply_payment_manager.CheckBeforeBuy = function(...) return true end end
    end

    -- 4p. Payment types bypass
    local function bypassCheckEnough(path)
        local P = safeReq(path)
        if P and not P._checkHooked then
            P._checkHooked = true
            if P.CheckEnough then
                P.CheckEnough = function(...) return true end
            end
        end
    end
    bypassCheckEnough("client.slua.logic.supply.supply_payment.playment_type.payment_uc")
    bypassCheckEnough("client.slua.logic.supply.supply_payment.playment_type.payment_bp")
    bypassCheckEnough("client.slua.logic.supply.supply_payment.playment_type.payment_ag")
    bypassCheckEnough("client.slua.logic.supply.supply_payment.playment_type.payment_token")
    bypassCheckEnough("client.slua.logic.supply.supply_payment.playment_type.payment_exchange")
    bypassCheckEnough("client.slua.logic.supply.supply_payment.playment_type.payment_act_coin")
    bypassCheckEnough("client.slua.logic.supply.supply_payment.playment_type.payment_free")
    bypassCheckEnough("client.slua.logic.supply.supply_payment.playment_type.payment_advertisement")
    bypassCheckEnough("client.slua.logic.supply.supply_payment.playment_type.payment_other")

    -- 4q. supply_ban_manager
    local supply_ban_manager_A = safeReq("client.slua.logic.supply.supply_ban_manager")
    if supply_ban_manager_A and not supply_ban_manager_A._hooked then
        supply_ban_manager_A._hooked = true
        if supply_ban_manager_A.NotFreeToUseBanByCrateId then
            supply_ban_manager_A.NotFreeToUseBanByCrateId = function(...) return false end
        end
    end

    -- ═════════════════════════════════════════════════════════════════════
    -- SECTION B — Core draw engine
    -- ═════════════════════════════════════════════════════════════════════

    local function UpdatePlayerData(activityData, addTimes, isTenDraw)
        if not activityData then return end
        if activityData.playerData then
            local pData = activityData.playerData
            pData.totalDrawTime = (pData.totalDrawTime or 0) + addTimes
            if pData.one_draw_times ~= nil then
                pData.one_draw_times = (pData.one_draw_times or 0) + (isTenDraw and 0 or 1)
            end
            if pData.duo_draw_times ~= nil then
                pData.duo_draw_times = (pData.duo_draw_times or 0) + (isTenDraw and 1 or 0)
            end
            if pData.curLuckyValue ~= nil then
                local addLucky = isTenDraw and 10 or 1
                local maxLucky = 100
                if activityData.globalConfig and activityData.globalConfig.maxLuckyValue then
                    maxLucky = activityData.globalConfig.maxLuckyValue
                end
                pData.curLuckyValue = math.min((pData.curLuckyValue or 0) + addLucky, maxLucky)
            end
            if pData.draw_times_week ~= nil then
                pData.draw_times_week = (pData.draw_times_week or 0) + addTimes
            end
            if pData.debrisItemCount ~= nil then
                pData.debrisItemCount = (pData.debrisItemCount or 0) + addTimes
            end
        end
        if activityData.TotalSnatchTimes then
            local actId = activityData.ActivityId or 0
            activityData.TotalSnatchTimes[actId] = (activityData.TotalSnatchTimes[actId] or 0) + addTimes
        end
        if activityData.acc_list_info and activityData.acc_list_info.cur_times ~= nil then
            activityData.acc_list_info.cur_times = (activityData.acc_list_info.cur_times or 0) + addTimes
        end
        if activityData.DrawLogConfig then
            for _, logConfig in pairs(activityData.DrawLogConfig) do
                if logConfig.had_draw_count ~= nil then
                    logConfig.had_draw_count = (logConfig.had_draw_count or 0) + addTimes
                end
            end
        end
        if activityData.curLuckyValue ~= nil then
            local addLucky = isTenDraw and 10 or 1
            local maxLucky = 100
            if activityData.globalConfig and activityData.globalConfig.maxLuckyValue then
                maxLucky = activityData.globalConfig.maxLuckyValue
            end
            activityData.curLuckyValue = math.min((activityData.curLuckyValue or 0) + addLucky, maxLucky)
        end
        if activityData.CurRoundDrawTimes ~= nil then
            activityData.CurRoundDrawTimes = (activityData.CurRoundDrawTimes or 0) + addTimes
        end
        if activityData.pool_draw_times then
            activityData.pool_draw_times = (activityData.pool_draw_times or 0) + addTimes
        end
        if activityData.totalDrawAwardConfig then
            for _, config in pairs(activityData.totalDrawAwardConfig) do
                if config.timesCount and ((activityData.totalDrawTime or 0) + addTimes) >= config.timesCount then
                    config.hasGet = true
                end
            end
        end
        if activityData.DrawActivityInfo and activityData.DrawActivityInfo.accumulate_info then
            local poolId = 10000
            activityData.pool_draw_times = (activityData.pool_draw_times or 0) + addTimes
            local accInfo = activityData.DrawActivityInfo.accumulate_info[poolId]
            if accInfo then
                for reqTimes, info in pairs(accInfo) do
                    if reqTimes <= activityData.pool_draw_times then
                        activityData.DrawActivityInfo.accumulate_info[poolId][reqTimes].state = 2
                    end
                end
            end
        end
        SafePostEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKYBACK_LUCKY_VALUE_UP)
        SafePostEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKYBACK_STATUS_CHANGE)
    end

    local lastDrawTimestamp = 0
    local isDrawBusy = false

    local function ProcessDraw(activityData, isTenDraw)
        if not activityData then return end
        local now = NowSec()
        if isDrawBusy or (now - lastDrawTimestamp < 0.9) then return end
        if not TrySpendUC(ResolveDrawUCCost(activityData, isTenDraw, isTenDraw and 10 or 1)) then
            lastDrawTimestamp = 0
            return
        end
        lastDrawTimestamp = now
        isDrawBusy = true

        local availableRewards = ExtractRewardList(activityData)
        if not availableRewards or #availableRewards == 0 then
            availableRewards = {
                {resid = 403003, count = 1, pos_id = 1, valid_hours = 0},
                {resid = 1101004046, count = 1, pos_id = 2, valid_hours = 0},
                {resid = 1101004062, count = 1, pos_id = 3, valid_hours = 0},
                {resid = 1400101, count = 1, pos_id = 4, valid_hours = 0},
                {resid = 1903193, count = 1, pos_id = 5, valid_hours = 0},
            }
        end

        local drawCount = isTenDraw and 10 or 1
        local selectedRewards = {}
        for i = 1, drawCount do
            local pickIdx = math.random(1, #availableRewards)
            local item = availableRewards[pickIdx] or availableRewards[1]
            table.insert(selectedRewards, {
                resid = item.resid,
                res_id = item.resid,
                count = item.count or 1,
                pos_id = item.pos_id or i,
                valid_hours = item.valid_hours or 0,
            })
        end

        UpdatePlayerData(activityData, drawCount, isTenDraw)

        if activityData.dropList ~= nil then
            activityData.dropList = {}
            for i, item in pairs(selectedRewards) do
                table.insert(activityData.dropList, {
                    res_id = item.resid, count = item.count,
                    valid_hours = item.valid_hours or 0, pos_id = item.pos_id or i,
                })
            end
        end
        if activityData.DropItem ~= nil then activityData.DropItem = selectedRewards end
        if activityData.pet_awards ~= nil then activityData.pet_awards = selectedRewards end
        if activityData.award_info ~= nil then activityData.award_info = selectedRewards end

        if isTenDraw then
            SafePostEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKYBACK_DARW_TEN_ANIMATION, 10)
            SafePostEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKYMULTI_LOTTERY, selectedRewards)
            SafePostEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKYBASE_ALL_DRAW_ANIM_START, 1, {1,2,3,4,5,6,7,8,9,10})
        else
            local posId = selectedRewards[1] and selectedRewards[1].pos_id or 1
            SafePostEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKYBACK_DARW_ONE_ANIMATION, posId)
            SafePostEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKYBASE_ONE_DRAW_ANIM_START, 1, posId)
            SafePostEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKYUNBACK_DARW_ANIMATION, posId)
        end
        SafePostEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKYBACK_STATUS_CHANGE)
        SafePostEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKUNYBACK_STATUS_CHANGE)
        SafePostEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKYBACK_REFRESH)
        SafePostEvent(EVENTTYPE_SPIN_START_COIN_UPDATE)
        SafePostEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKYMULTI_REFRESH_WINDOW)

        if _G.AddTimerOnce then
            _G.AddTimerOnce(_G, 1.2, function()
                ShowRewardPanel(selectedRewards)
                isDrawBusy = false
            end)
        else
            ShowRewardPanel(selectedRewards)
            isDrawBusy = false
        end
    end

    local lastCrateTimestamp = 0
    local isCrateBusy = false

    local function ProcessCrateDrawInternal(sourceModule, boxId, times, skipSpend)
        local now = NowSec()
        if isCrateBusy or (now - lastCrateTimestamp < 0.9) then return nil, nil, nil, false end
        lastCrateTimestamp = now
        isCrateBusy = true

        local drawTimes = (type(times) == "number" and times > 0) and times or (type(boxId) == "number" and (boxId == 10 or boxId == 2) and 10) or 1
        local actualBoxId = (type(boxId) == "number" and boxId > 10) and boxId or 1
        if not skipSpend and not TrySpendUC(ResolveDrawUCCost(sourceModule, drawTimes >= 10, drawTimes)) then
            isCrateBusy = false
            lastCrateTimestamp = 0
            return nil, nil, nil, false
        end

        local rewards = {}
        if sourceModule then rewards = ExtractRewardList(sourceModule) end
        if not rewards or #rewards == 0 then
            local logic_box_draw_x = SafeRequire("client.slua.logic.store.logic_box_draw")
            if logic_box_draw_x then rewards = ExtractRewardList(logic_box_draw_x) end
        end
        if not rewards or #rewards == 0 then
            local logic_crate_x = SafeRequire("client.slua.logic.store.logic_crate") or SafeRequire("client.slua.logic.store.logic_crate_manager") or SafeRequire("client.slua.logic.store.supply_crate_manager")
            if logic_crate_x then rewards = ExtractRewardList(logic_crate_x) end
        end
        if not rewards or #rewards == 0 then
            rewards = ExtractPackageRewards(actualBoxId, 403003, drawTimes)
        end

        local selectedRewards = {}
        if rewards and #rewards > 0 then
            for i = 1, drawTimes do
                local pickIdx = math.random(1, #rewards)
                local item = rewards[pickIdx] or rewards[1]
                table.insert(selectedRewards, {
                    resid = item.resid or item.res_id or 403003,
                    res_id = item.resid or item.res_id or 403003,
                    count = item.count or item.item_count or 1,
                    item_count = item.count or item.item_count or 1,
                    valid_hours = item.valid_hours or 0,
                })
            end
        else
            for i = 1, drawTimes do
                table.insert(selectedRewards, { resid = 403003, res_id = 403003, count = 1, item_count = 1, valid_hours = 0 })
            end
        end

        local logic_box_draw_x = SafeRequire("client.slua.logic.store.logic_box_draw")
        if logic_box_draw_x then
            if logic_box_draw_x.cur_box_info then
                local bInfo = logic_box_draw_x.cur_box_info
                bInfo.draw_times = (bInfo.draw_times or 0) + drawTimes
                bInfo.lucky_value = math.min((bInfo.lucky_value or 0) + drawTimes, 100)
                bInfo.had_draw_count = (bInfo.had_draw_count or 0) + drawTimes
            end
            if logic_box_draw_x.box_lucky_value then logic_box_draw_x.box_lucky_value = math.min((logic_box_draw_x.box_lucky_value or 0) + drawTimes, 100) end
            if logic_box_draw_x.cur_luck_value then logic_box_draw_x.cur_luck_value = math.min((logic_box_draw_x.cur_luck_value or 0) + drawTimes, 100) end
        end

        ShowRewardPanel(selectedRewards)
        isCrateBusy = false
        return selectedRewards, actualBoxId, drawTimes, true
    end

    -- ═════════════════════════════════════════════════════════════════════
    -- SECTION C — Fake currency injection
    -- ═════════════════════════════════════════════════════════════════════

    _G.ApplyAllFakeCurrencies = function(target)
        local uc = GetFakeUC()
        local function enough(a, b, ...)
            local price = tonumber(b)
            if not price or price <= 0 then
                price = CaptureUCPrice(a, b, ...)
            else
                _G._lastUCCheckPrice = price
            end
            return HasEnoughUC(price)
        end
        local dMgr = target or DataMgr or _G.DataMgr or SafeRequire("client.slua.logic.common.DataMgr") or SafeRequire("client.data.DataMgr")
        if dMgr then
            dMgr.ticket = uc; dMgr.eternal_diamond = uc; dMgr.home_coin = uc
            dMgr.gold = uc; dMgr.diamond = uc; dMgr.pp = uc; dMgr.bp = uc
            dMgr.coupon = uc; dMgr.voucher = uc; dMgr.fp_token = uc
            dMgr.gold_chip = uc; dMgr.gen_ticket = uc; dMgr.corps_money = uc
            dMgr.smelt = uc; dMgr.battle_coin = uc; dMgr.wow_creation_score = uc
            dMgr.ugc_advanced_crystal = uc; dMgr.carteam_coin_count = uc
            dMgr.anchor = uc; dMgr.anchor_origin = uc; dMgr.uc = uc; dMgr.UC = uc
            dMgr.money = uc; dMgr.currency = uc; dMgr.ag = uc; dMgr.silver = uc

            if dMgr.roleData then
                dMgr.roleData.bgbg_vip = 1
                dMgr.roleData.level = 100
                dMgr.roleData.ticket = uc
                dMgr.roleData.gold = uc
                dMgr.roleData.diamond = uc
                dMgr.roleData.uc = uc
            end

            dMgr.GetCurrency = function(...) return GetFakeUC() end
            dMgr.GetMoney = function(...) return GetFakeUC() end
            dMgr.GetTicket = function(...) return GetFakeUC() end
            dMgr.GetUC = function(...) return GetFakeUC() end
            dMgr.GetGold = function(...) return GetFakeUC() end
            dMgr.GetDiamond = function(...) return GetFakeUC() end
            dMgr.GetMoneyByType = function(...) return GetFakeUC() end
            dMgr.CheckMoney = enough
            dMgr.CheckCurrency = enough
            dMgr.CheckTicket = enough
            dMgr.CheckUC = enough
            dMgr.CheckIsEnough = enough
            dMgr.IsMoneyEnough = enough
            dMgr.IsCurrencyEnough = enough

            if EventSystem and EVENTTYPE_DATA_MGR then
                if EVENTID_DATAMGR_GOLD_CHANGE then SafePostEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_GOLD_CHANGE, uc) end
                if EVENTID_DATAMGR_TICKET_CHANGE then SafePostEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_TICKET_CHANGE, uc) end
                if EVENTID_DATAMGR_DIAMOND_CHANGE then SafePostEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_DIAMOND_CHANGE, uc) end
                if EVENTID_DATAMGR_FP_TOKEN_CHANGE then SafePostEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_FP_TOKEN_CHANGE, uc) end
                if EVENTID_DATAMGR_GOLD_CHIP_CHANGE then SafePostEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_GOLD_CHIP_CHANGE, uc) end
                if EVENTID_DATAMGR_ROLE_LEVEL_CHANGE and dMgr.roleData then SafePostEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_ROLE_LEVEL_CHANGE, dMgr.roleData.level) end
            end
        end

        local role_data = SafeRequire("client.slua.logic.role.role_data") or SafeRequire("client.slua.logic.role.logic_role") or SafeRequire("client.slua.logic.role.RoleData")
        if role_data then
            role_data.ticket = uc; role_data.uc = uc; role_data.gold = uc
            role_data.diamond = uc; role_data.money = uc; role_data.currency = uc
            role_data.ag = uc; role_data.silver = uc
            role_data.GetTicket = function(...) return GetFakeUC() end
            role_data.GetUC = function(...) return GetFakeUC() end
            role_data.GetGold = function(...) return GetFakeUC() end
            role_data.GetMoney = function(...) return GetFakeUC() end
            role_data.GetDiamond = function(...) return GetFakeUC() end
            role_data.GetCurrency = function(...) return GetFakeUC() end
            role_data.GetCurrencyCount = function(...) return GetFakeUC() end
        end

        pcall(function()
            local StoreUtils = SafeRequire("client.slua.logic.store.utils.store_utils")
            if StoreUtils and StoreUtils.GetMoneyInfo then
                StoreUtils.GetMoneyInfo = function()
                    local n = GetFakeUC()
                    return { nDiamond = n, nUC = n, nSilver = n, nGold = n, nTicket = n }
                end
            end
        end)
    end

    local dMgr = DataMgr or _G.DataMgr or SafeRequire("client.slua.logic.common.DataMgr") or SafeRequire("client.data.DataMgr")
    if dMgr then
        if dMgr.InitRoleData then
            local oldInitRoleData = dMgr.InitRoleData
            dMgr.InitRoleData = function(roleDataTb, ...)
                if oldInitRoleData then pcall(oldInitRoleData, roleDataTb, ...) end
                _G.ApplyAllFakeCurrencies(dMgr)
            end
        end
        _G.ApplyAllFakeCurrencies(dMgr)
    end

    local logic_common_pay_box = SafeRequire("client.slua.logic.common.Payclass.logic_common_pay_box")
    if logic_common_pay_box then
        logic_common_pay_box.ShowUcRechargeMsg = function() return true end
        logic_common_pay_box.ShowRechargeMsg = function() return true end
        logic_common_pay_box.ShowPayBox = function() return true end
        logic_common_pay_box.OpenPayBox = function() return true end
    end

    local QRcodeRestrictManager = SafeRequire("client.module_framework.CommonModuleConfig.QRcodeRestrictManager")
    if QRcodeRestrictManager then
        QRcodeRestrictManager.CheckUCRestrict = function() return false end
        QRcodeRestrictManager.IsRestrictUC = function() return false end
        QRcodeRestrictManager.ShowRestrictTips = function() end
    end

    -- ═════════════════════════════════════════════════════════════════════
    -- SECTION D — Lucky activity hooks
    -- ═════════════════════════════════════════════════════════════════════

    local luckyback_activity = SafeRequire("client.slua.logic.lobby_activity.logic_luckyback_activity")
    if luckyback_activity then
        if luckyback_activity.do_one_draw_back_by_activity_req then
            luckyback_activity.do_one_draw_back_by_activity_req = function(a1) ProcessDraw(luckyback_activity, a1 == 2) end
        end
        if luckyback_activity.do_one_draw_by_tick then
            luckyback_activity.do_one_draw_by_tick = function(a1) ProcessDraw(luckyback_activity, false) end
        end
        if luckyback_activity.get_sum_draw_award_by_activity_req then
            luckyback_activity.get_sum_draw_award_by_activity_req = function(a1)
                local rewardList = ExtractRewardList(luckyback_activity)
                if rewardList and #rewardList > 0 then
                    local pickIdx = math.random(1, #rewardList)
                    ShowRewardPanel({ {resid = rewardList[pickIdx].resid, count = 1, valid_hours = 0} })
                end
            end
        end
    end

    local luckydouble_activity = SafeRequire("client.slua.logic.lobby_activity.logic_luckydouble_activity")
    if luckydouble_activity then
        if luckydouble_activity.send_do_one_lucky_double_draw_by_activity_req then
            luckydouble_activity.send_do_one_lucky_double_draw_by_activity_req = function() ProcessDraw(luckydouble_activity, false) end
        end
        if luckydouble_activity.send_double_draw_on_shot_req then
            luckydouble_activity.send_double_draw_on_shot_req = function() ProcessDraw(luckydouble_activity, true) end
        end
    end

    local luckyunback_activity = SafeRequire("client.slua.logic.lobby_activity.logic_luckyunback_activity")
    if luckyunback_activity then
        if luckyunback_activity.send_do_draw_discount_by_activity_req then
            luckyunback_activity.send_do_draw_discount_by_activity_req = function() ProcessDraw(luckyunback_activity, false) end
        end
    end

    local luckmix_activity = SafeRequire("client.slua.logic.lobby_activity.logic_luckmix_activity")
    if luckmix_activity and luckmix_activity.DoDraw then
        luckmix_activity.DoDraw = function(a1) ProcessDraw(luckmix_activity, a1 == 2) end
    end

    local luckymulti_activity = SafeRequire("client.slua.logic.lobby_activity.logic_luckymulti_activity")
    if luckymulti_activity and luckymulti_activity.Lottery then
        luckymulti_activity.Lottery = function(a1) ProcessDraw(luckymulti_activity, a1 == 10) end
    end

    local scrapgold_draw = SafeRequire("client.slua.logic.lobby_activity.logic_scrapgold_draw")
    if scrapgold_draw and scrapgold_draw.DoDraw then
        scrapgold_draw.DoDraw = function(a1) ProcessDraw(scrapgold_draw, a1 == 2) end
    end

    local godzilla_ban = SafeRequire("client.slua.logic.lobby_activity.logic_godzilla_ban")
    if godzilla_ban then
        if godzilla_ban.OneDraw then godzilla_ban.OneDraw = function() ProcessDraw(godzilla_ban, false) end end
        if godzilla_ban.TenDraw then godzilla_ban.TenDraw = function() ProcessDraw(godzilla_ban, true) end end
    end

    local crazy_weekend = SafeRequire("client.slua.logic.lobby_activity.crazy_weekend.logic_crazy_weekend_luckydraw")
    if crazy_weekend and crazy_weekend.send_get_happy_weekend_ticket_req then
        crazy_weekend.send_get_happy_weekend_ticket_req = function()
            local tickets = {}
            for i = 1, 3 do tickets[i] = {get_time = os.time(), register_week = 1} end
            crazy_weekend.MyLuckyDraw = {}
            for key, val in pairs(tickets) do table.insert(crazy_weekend.MyLuckyDraw, {[key] = val}) end
            crazy_weekend.ticket_active = true
            SafePostEvent(EVENTTYPE_CRAZYWEEKEND, EVENTID_CRAZYWEEKEND_TICKET_UPDATE)
        end
    end

    local LukcyOptionalTurntable = SafeRequire("client.slua.logic.lobby_activity.LukcyOptionalTurntable.Logic_LukcyOptionalTurntable")
    if LukcyOptionalTurntable and LukcyOptionalTurntable.SendDrawActReq then
        LukcyOptionalTurntable.SendDrawActReq = function(a1) ProcessDraw(LukcyOptionalTurntable, a1 == 10) end
    end

    local tarotcard_drawcard = SafeRequire("client.slua.logic.tarot_card.logic_tarotcard_drawcard")
    if tarotcard_drawcard and tarotcard_drawcard.DoDraw then
        tarotcard_drawcard.DoDraw = function(a1) ProcessDraw(tarotcard_drawcard, a1 == 2) end
    end

    local super_airdrop = SafeRequire("client.slua.logic.lobby_activity.logic_super_airdrop")
    if super_airdrop and super_airdrop.send_choose_and_get_super_airdrop_reward_req then
        super_airdrop.send_choose_and_get_super_airdrop_reward_req = function()
            local rewardList = ExtractRewardList(super_airdrop)
            if rewardList and #rewardList > 0 then
                local pickIdx = math.random(1, #rewardList)
                ShowRewardPanel({ {resid = rewardList[pickIdx].resid, count = 1, valid_hours = 0} })
            end
            super_airdrop.have_take_award = true
        end
    end

    local xsuit_activity = SafeRequire("client.slua.logic.XSuit.logic_xsuit_activity")
    if xsuit_activity then
        if xsuit_activity.send_do_draw_act_req then
            xsuit_activity.send_do_draw_act_req = function(a1, a2, a3, a4) ProcessDraw(xsuit_activity, a4 == 10) end
        end
        if xsuit_activity.OnGetDrawActivityInfo then
            local old_OnGetDrawActivityInfo = xsuit_activity.OnGetDrawActivityInfo
            xsuit_activity.OnGetDrawActivityInfo = function(a1, a2, a3)
                if a2 ~= 0 then
                    a1.DrawActivityInfo = {
                        activity_id = 999999, exchange_activity_id = 999999,
                        ex_item_id = 403003,
                        pool_info = { [1001] = { {itemid = 403003, cli_tag = 1} } },
                        draw_currency = { [1006] = {one_cost = 1, ten_cost = 10} },
                        gold_dress_one_level_id = 403003, is_first_dis = true,
                        discount_uc_cost = 1, accumulate_coin_count = 9999,
                        accumulate_info = { [10000] = { {} } },
                        branch_box_item_id = 403003,
                    }
                    SafePostEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_DRAW_ACTIVITY_UPDATE)
                    return
                end
                old_OnGetDrawActivityInfo(a1, a2, a3)
            end
        end
        if xsuit_activity.send_get_accumulate_pool_reward_req then
            xsuit_activity.send_get_accumulate_pool_reward_req = function(a1, a2)
                ShowRewardPanel({ {resid = 403003, count = a2 or 1, valid_hours = 0} })
                local stateInfo = { [a1] = { [a2] = { state = 2 } } }
                if xsuit_activity.SetAccumulateStateInfo then xsuit_activity.SetAccumulateStateInfo(xsuit_activity, stateInfo) end
                SafePostEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_ACCUMULATE_POOL_REWARD)
            end
        end
    end

    -- ActivityHandler
    local ActivityHandler = SafeRequire("client.network.Protocol.ActivityHandler")
    if ActivityHandler then
        local function MockActivityDraw(actId, times, ...)
            if not TrySpendUC(ResolveDrawUCCost(nil, tonumber(times) == 10, times)) then return end
            local rewards = ExtractPackageRewards(actId, 403003, times or 1)
            ShowRewardPanel(rewards)
            if ActivityHandler.on_get_activity_award_rsp then ActivityHandler.on_get_activity_award_rsp(0, actId, rewards) end
            if ActivityHandler.on_common_lottery_rsp then ActivityHandler.on_common_lottery_rsp(0, actId, rewards) end
            if ActivityHandler.on_luckydraw_rsp then ActivityHandler.on_luckydraw_rsp(0, actId, rewards) end
            SafePostEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKYBACK_STATUS_CHANGE)
        end
        ActivityHandler.send_get_activity_award_req = MockActivityDraw
        ActivityHandler.send_common_lottery_req = MockActivityDraw
        ActivityHandler.send_luckydraw_req = MockActivityDraw
        ActivityHandler.send_draw_req = MockActivityDraw
        ActivityHandler.send_open_box_req = MockActivityDraw
        ActivityHandler.send_exchange_award_req = function(actId, exchangeId, count, ...)
            ShowRewardPanel({ {resid = exchangeId, count = count or 1, valid_hours = 0} })
            if ActivityHandler.on_exchange_award_rsp then ActivityHandler.on_exchange_award_rsp(0, actId, exchangeId, count or 1) end
        end
    end

    -- XSuitHandler (upgrade)
    local XSuitHandlerB = SafeRequire("client.network.Protocol.XSuitHandler")
    if XSuitHandlerB then
        XSuitHandlerB.send_do_draw_act_req = function(actId, subPool, useItem, count, ...)
            ProcessDraw(xsuit_activity or {}, count == 10)
        end
        XSuitHandlerB.send_xsuit_upgrade_req = function(xsuitId, level, ...)
            if XSuitHandlerB.on_xsuit_upgrade_rsp then XSuitHandlerB.on_xsuit_upgrade_rsp(0, xsuitId, level or 7) end
            SafePostEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_UPGRADE_SUCCESS, xsuitId, level or 7)
        end
        XSuitHandlerB.send_xsuit_star_upgrade_req = function(xsuitId, star, ...)
            if XSuitHandlerB.on_xsuit_star_upgrade_rsp then XSuitHandlerB.on_xsuit_star_upgrade_rsp(0, xsuitId, star or 7) end
            SafePostEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_STAR_UPGRADE_SUCCESS, xsuitId, star or 7)
        end
    end

    -- logic_activity
    local logic_activity = SafeRequire("client.slua.logic.lobby_activity.logic_activity")
    if logic_activity then
        logic_activity.IsActivityOpen = function(...) return true end
        logic_activity.CheckActivityCondition = function(...) return true end
        logic_activity.CheckActivityTime = function(...) return true end
    end

    -- XSuit_Get_UIBP
    local XSuit_Get_UIBP = SafeRequire("client.slua.umg.XSuit.XSuit_Get_UIBP")
    if XSuit_Get_UIBP and XSuit_Get_UIBP.OnClickedButtonOK then
        XSuit_Get_UIBP.OnClickedButtonOK = function(arg1)
            if arg1.cfg and arg1.cfg.EndFunc then arg1.cfg.EndFunc() end
            if arg1.CloseSelf then arg1.CloseSelf(arg1) end
        end
    end

    -- AsyncXSuitSpinBase
    local AsyncXSuitSpinBase = SafeRequire("client.slua.umg.lobby_activity.xsuit_spin.MainScene.AsyncXSuitSpinBase")
    if AsyncXSuitSpinBase and AsyncXSuitSpinBase.OnSpinDrawRsp then
        local old_OnSpinDrawRsp = AsyncXSuitSpinBase.OnSpinDrawRsp
        AsyncXSuitSpinBase.OnSpinDrawRsp = function(arg1, arg2, arg3, arg4, arg5)
            if not arg4 or #arg4 == 0 then
                local rewards = ExtractRewardList(arg1)
                if rewards and #rewards > 0 then
                    arg4 = {}
                    local drawCount = math.min(10, #rewards)
                    for i = 1, drawCount do
                        local pickIdx = math.random(1, #rewards)
                        table.insert(arg4, {itemid = rewards[pickIdx].resid, count = 1, valid_hours = 0})
                    end
                else
                    arg4 = { {itemid = 403003, count = 1, valid_hours = 0} }
                end
            end
            arg5 = {}
            old_OnSpinDrawRsp(arg1, arg2, arg3, arg4, arg5)
        end
    end

    -- logic_ladder_draw
    local logic_ladder_draw = SafeRequire("client.slua.logic.lobby_activity.logic_ladder_draw")
    if logic_ladder_draw then
        if logic_ladder_draw.OnRotateRsp then
            local old_OnRotateRsp = logic_ladder_draw.OnRotateRsp
            logic_ladder_draw.OnRotateRsp = function(arg1)
                if not arg1 or not arg1.reward_info then
                    local rewards = ExtractRewardList(logic_ladder_draw)
                    local pickIdx = (rewards and #rewards > 0) and math.random(1, #rewards) or 1
                    local resId = (rewards and rewards[pickIdx] and rewards[pickIdx].resid) or 403003
                    arg1 = { pos = 1, last_opt_rest = 1, reward_info = { {item_id = resId, item_num = 1, valid_hours = 0} } }
                end
                old_OnRotateRsp(arg1)
                SafePostEvent(EVENTTYPE_LADDER_DRAW, EVENTID_LADDER_DRAW_ROTATE)
            end
        end
        if logic_ladder_draw.OnRandomAwardRsp then
            local old_OnRandomAwardRsp = logic_ladder_draw.OnRandomAwardRsp
            logic_ladder_draw.OnRandomAwardRsp = function(arg1)
                if not arg1 or not arg1.real_list then
                    local rewards = ExtractRewardList(logic_ladder_draw)
                    local pickIdx = (rewards and #rewards > 0) and math.random(1, #rewards) or 1
                    local resId = (rewards and rewards[pickIdx] and rewards[pickIdx].resid) or 403003
                    local mockItem = {resid = resId, count = 1, valid_hours = 0}
                    arg1 = { real_list = {mockItem}, reward_list = {mockItem}, decompose_list = {} }
                end
                old_OnRandomAwardRsp(arg1)
                SafePostEvent(EVENTTYPE_LADDER_DRAW, EVENTID_LADDER_DRAW_RANDOM_AWARD)
            end
        end
        if logic_ladder_draw.OnRecvAwardRsp then
            local old_OnRecvAwardRsp = logic_ladder_draw.OnRecvAwardRsp
            logic_ladder_draw.OnRecvAwardRsp = function(arg1)
                if not arg1 or not arg1.real_list then
                    local rewards = ExtractRewardList(logic_ladder_draw)
                    local pickIdx = (rewards and #rewards > 0) and math.random(1, #rewards) or 1
                    local resId = (rewards and rewards[pickIdx] and rewards[pickIdx].resid) or 403003
                    local mockItem = {resid = resId, count = 1, valid_hours = 0}
                    arg1 = { real_list = {mockItem}, reward_list = {mockItem}, decompose_list = {} }
                end
                old_OnRecvAwardRsp(arg1)
                ShowRewardPanel(arg1.real_list)
                SafePostEvent(EVENTTYPE_LADDER_DRAW, EVENTID_LADDER_DRAW_RECV_AWARD)
            end
        end
    end

    -- SportsCarSpinMainBase
    local SportsCarSpinMainBase = SafeRequire("client.slua.umg.lobby_activity.SportsCarSpin.SportsCarSpinMainBase")
    if SportsCarSpinMainBase then
        if SportsCarSpinMainBase.OnBeginLottery then
            local oldOnBeginLottery = SportsCarSpinMainBase.OnBeginLottery
            SportsCarSpinMainBase.OnBeginLottery = function(arg1)
                local rewards = ExtractRewardList(logic_ladder_draw)
                if rewards and #rewards > 0 then
                    local pickIdx = math.random(1, #rewards)
                    local mockInfo = { pos = 1, last_opt_rest = 1, reward_info = { {item_id = rewards[pickIdx].resid, item_num = 1, valid_hours = 0} } }
                    if logic_ladder_draw and logic_ladder_draw.svrDrawData then logic_ladder_draw.svrDrawData[arg1.nActID] = mockInfo end
                    SafePostEvent(EVENTTYPE_LADDER_DRAW, EVENTID_LADDER_DRAW_ROTATE)
                    if arg1.fsm and arg1.fsm.ConvertResult then arg1.fsm.ConvertResult(arg1.fsm) end
                else
                    oldOnBeginLottery(arg1)
                end
            end
        end
        if SportsCarSpinMainBase.ReceiveAward then
            local oldReceiveAward = SportsCarSpinMainBase.ReceiveAward
            SportsCarSpinMainBase.ReceiveAward = function(arg1)
                local rewards = ExtractRewardList(logic_ladder_draw)
                if rewards and #rewards > 0 then
                    local pickIdx = math.random(1, #rewards)
                    ShowRewardPanel({ {resid = rewards[pickIdx].resid, count = 1, valid_hours = 0} })
                    if arg1.fsm and arg1.fsm.ConvertIdle then arg1.fsm.ConvertIdle(arg1.fsm) end
                else
                    oldReceiveAward(arg1)
                end
            end
        end
    end

    -- SportsCarExchangeComponentItem
    local SportsCarExchangeComponentItem = SafeRequire("client.slua.umg.lobby_activity.SportsCarSpin.Exchange.SportsCarExchangeComponentItem")
    if SportsCarExchangeComponentItem and SportsCarExchangeComponentItem.OnClick_Exchange then
        SportsCarExchangeComponentItem.OnClick_Exchange = function(arg1)
            local itemData = arg1.itemWidgetList and arg1.itemWidgetList.GetSubItemData and arg1.itemWidgetList.GetSubItemData(arg1.itemWidgetList, arg1._curSelectItemIndex, arg1._curSelectSubItemIndex)
            if itemData then
                local resId = itemData[StoreConst and StoreConst.label_item_index_id or "id"] or 403003
                ShowRewardPanel({ {resid = resId, count = 1, valid_hours = 0} })
                if arg1.UpdateCurrency then arg1.UpdateCurrency(arg1) end
                if arg1.itemWidgetList and arg1.itemWidgetList.RefreshAllSubItems then arg1.itemWidgetList.RefreshAllSubItems(arg1.itemWidgetList) end
            end
        end
    end

    -- logic_spin_preorder
    local logic_spin_preorder = SafeRequire("client.module_framework.JumpModuleConfig.logic_spin_preorder")
    if logic_spin_preorder and logic_spin_preorder.SendBuyItem then
        logic_spin_preorder.SendBuyItem = function(arg1, arg2)
            if not TrySpendUC(CaptureUCPrice(arg1, arg2)) then return end
            ShowRewardPanel({ {resid = arg1.itemId, count = arg2 or 1, valid_hours = 0} })
            SafePostEvent(EVENTTYPE_SPIN_PREORDER, EVENTID_SPIN_PREORDER_UPDATE)
        end
    end

    -- ═════════════════════════════════════════════════════════════════════
    -- SECTION E — Store, crate, box draw hooks
    -- ═════════════════════════════════════════════════════════════════════

    local logic_box_draw = SafeRequire("client.slua.logic.store.logic_box_draw")
    if logic_box_draw then
        logic_box_draw.CheckCanDraw = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_box_draw.CheckCanBuy = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_box_draw.CheckMoney = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_box_draw.CheckCurrency = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_box_draw.CheckIsEnough = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_box_draw.IsMoneyEnough = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_box_draw.IsCurrencyEnough = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_box_draw.IsTicketEnough = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_box_draw.IsUCEnough = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_box_draw.CheckCanDrawBox = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_box_draw.CheckDrawCondition = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_box_draw.GetCurrencyNum = function(...) return GetFakeUC() end
        logic_box_draw.GetMoneyNum = function(...) return GetFakeUC() end
        logic_box_draw.GetTicketNum = function(...) return GetFakeUC() end
        logic_box_draw.GetUCNum = function(...) return GetFakeUC() end

        local function MockLogicBoxDraw(boxId, times, ...)
            local rewards, actBoxId, drawTimes, ok = ProcessCrateDrawInternal(logic_box_draw, boxId, times)
            if not ok then return false end
            if logic_box_draw.OnBoxDrawRsp then
                logic_box_draw.OnBoxDrawRsp(0, rewards, actBoxId, drawTimes)
            elseif logic_box_draw.OnDrawRsp then
                logic_box_draw.OnDrawRsp(0, rewards, actBoxId, drawTimes)
            end
            SafePostEvent(EVENTTYPE_STORE, EVENTID_BOX_DRAW_RSP, rewards)
            SafePostEvent(EVENTTYPE_STORE, EVENTID_STORE_BOX_UPDATE)
            return true
        end
        logic_box_draw.DoDraw = MockLogicBoxDraw
        logic_box_draw.ReqDraw = MockLogicBoxDraw
        logic_box_draw.OpenBox = MockLogicBoxDraw
        logic_box_draw.SendBoxDrawReq = MockLogicBoxDraw
        logic_box_draw.DoBoxDraw = MockLogicBoxDraw
    end

    local logic_crate = SafeRequire("client.slua.logic.store.logic_crate") or SafeRequire("client.slua.logic.store.logic_crate_manager") or SafeRequire("client.slua.logic.store.supply_crate_manager")
    if logic_crate then
        local function MockLogicCrate(crateId, times, ...)
            local rewards, actCrateId, drawTimes, ok = ProcessCrateDrawInternal(logic_crate, crateId, times)
            if not ok then return false end
            if logic_crate.OnOpenCrateRsp then
                logic_crate.OnOpenCrateRsp(0, rewards, actCrateId, drawTimes)
            elseif logic_crate.OnDrawCrateRsp then
                logic_crate.OnDrawCrateRsp(0, rewards, actCrateId, drawTimes)
            end
            return true
        end
        if logic_crate.OpenCrate then logic_crate.OpenCrate = MockLogicCrate end
        if logic_crate.DrawCrate then logic_crate.DrawCrate = MockLogicCrate end
        if logic_crate.SendOpenCrateReq then logic_crate.SendOpenCrateReq = MockLogicCrate end
        if logic_crate.OpenBox then logic_crate.OpenBox = MockLogicCrate end
        if logic_crate.DrawBox then logic_crate.DrawBox = MockLogicCrate end
        if logic_crate.CheckCanOpen then logic_crate.CheckCanOpen = function(...) return true end end
    end

    local logic_store = SafeRequire("client.slua.logic.store.logic_store")
    if logic_store then
        logic_store.CheckCurrency = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_store.CheckMoney = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_store.IsMoneyEnough = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_store.IsCurrencyEnough = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_store.CheckIsEnough = function(...) return HasEnoughUC(CaptureUCPrice(...)) end
        logic_store.CheckBuyLimit = function(...) return true end
        logic_store.DoBuy = function(self, goodsId, count, ...)
            if not BeginBuyAction("store:" .. tostring(goodsId)) then return false end
            if not TrySpendUC(CaptureUCPrice(goodsId, count, ...)) then return false end
            local rewards = ExtractPackageRewards(goodsId, goodsId, count or 1)
            ShowRewardPanel(rewards)
            if logic_store.OnBuyRsp then logic_store.OnBuyRsp(0, rewards, goodsId, count or 1) end
            return true
        end
    end

    local BoxDrawHandler = SafeRequire("client.network.Protocol.BoxDrawHandler")
    if BoxDrawHandler then
        local function MockBoxDrawHandler(arg1, arg2, ...)
            local rewards, boxId, drawTimes, ok = ProcessCrateDrawInternal(BoxDrawHandler, arg1, arg2)
            if not ok then return end
            if BoxDrawHandler.on_box_draw_rsp then
                BoxDrawHandler.on_box_draw_rsp(0, rewards, boxId, drawTimes)
            elseif BoxDrawHandler.on_draw_rsp then
                BoxDrawHandler.on_draw_rsp(0, rewards, boxId, drawTimes)
            elseif BoxDrawHandler.on_open_box_rsp then
                BoxDrawHandler.on_open_box_rsp(0, rewards, boxId, drawTimes)
            elseif BoxDrawHandler.on_lottery_rsp then
                BoxDrawHandler.on_lottery_rsp(0, rewards, boxId, drawTimes)
            end
            SafePostEvent(EVENTTYPE_STORE, EVENTID_BOX_DRAW_RSP, rewards)
            SafePostEvent(EVENTTYPE_STORE, EVENTID_STORE_BOX_UPDATE)
        end
        BoxDrawHandler.send_box_draw_req = MockBoxDrawHandler
        BoxDrawHandler.send_draw_req = MockBoxDrawHandler
        BoxDrawHandler.send_open_box_req = MockBoxDrawHandler
        BoxDrawHandler.send_lottery_req = MockBoxDrawHandler
        BoxDrawHandler.send_crate_draw_req = MockBoxDrawHandler
        BoxDrawHandler.send_open_crate_req = MockBoxDrawHandler
    end

    -- ═════════════════════════════════════════════════════════════════════
    -- SECTION F — Supply ban + credit managers
    -- ═════════════════════════════════════════════════════════════════════

    local supply_ban_manager = SafeRequire("client.slua.logic.supply.supply_ban_manager")
    if supply_ban_manager then
        if supply_ban_manager.RequestCustomCrateInfo then
            local oldReq = supply_ban_manager.RequestCustomCrateInfo
            supply_ban_manager.RequestCustomCrateInfo = function(self, crateId, ...)
                if self and self.SupplyBanInfo then
                    self.SupplyBanInfo[crateId] = {}
                    self.SupplyBanFree[crateId] = false
                    self.SupplyBanProbability[crateId] = {}
                    local param = { crateId = crateId, data = { usedFree = false, banItems = {}, probability = {} } }
                    SafePostEvent(EVENTTYPE_STORE_DATA, EVENTID_CRATE_BAN_DATA, param)
                else
                    oldReq(self, crateId, ...)
                end
            end
        end
        if supply_ban_manager.RequestCustomBanCrateItems then
            supply_ban_manager.RequestCustomBanCrateItems = function(self, crateId, items, cost, pay_method)
                if self and self.RespondCustomBanCrateItems then
                    self:RespondCustomBanCrateItems(crateId, items, cost, 0)
                end
            end
        end
        if supply_ban_manager.NotFreeToUseBanByCrateId then
            supply_ban_manager.NotFreeToUseBanByCrateId = function(self, crateId) return false end
        end
    end

    local supply_credit_manager = SafeRequire("client.slua.logic.supply.supply_credit_manager")
    if supply_credit_manager then
        if supply_credit_manager.RequestJPKRCreditInfo then
            supply_credit_manager.RequestJPKRCreditInfo = function(self, ...)
                if self then
                    self.SupplyCreditInfo = self.SupplyCreditInfo or {}
                    self.SupplyCreditInfo.haveData = true
                    self.SupplyCreditInfo.credit = 99999
                    self.SupplyCreditInfo.state_data = {}
                end
                SafePostEvent(EVENTTYPE_STORE_DATA, EVENTID_CRATE_JPKR_CREDIT, {haveData = true, credit = 99999, state_data = {}})
            end
        end
        if supply_credit_manager.RespondJPKRCreditInfo then
            supply_credit_manager.RespondJPKRCreditInfo = function(self, credit, change_credit, state_data)
                if self then
                    self.SupplyCreditInfo = self.SupplyCreditInfo or {}
                    self.SupplyCreditInfo.haveData = true
                    self.SupplyCreditInfo.credit = credit or 99999
                    self.SupplyCreditInfo.state_data = state_data or {}
                end
                SafePostEvent(EVENTTYPE_STORE_DATA, EVENTID_CRATE_JPKR_CREDIT, self.SupplyCreditInfo)
            end
        end
        if supply_credit_manager.RequestCrateCreditExchangeTicket then
            supply_credit_manager.RequestCrateCreditExchangeTicket = function(self, ...)
                if self and self.RespondCrateCreditExchangeTicket then
                    self:RespondCrateCreditExchangeTicket(0, { {resid = 403003, count = 1, valid_hours = 0} })
                end
            end
        end
        if supply_credit_manager.RespondCrateCreditExchangeTicket then
            supply_credit_manager.RespondCrateCreditExchangeTicket = function(self, err_code, itemList)
                if err_code ~= 0 then
                    ShowRewardPanel({ {resid = 403003, count = 1, valid_hours = 0} })
                    return
                end
                if itemList and next(itemList) then
                    ShowRewardPanel(itemList)
                else
                    ShowRewardPanel({ {resid = 403003, count = 1, valid_hours = 0} })
                end
                SafePostEvent(EVENTTYPE_STORE_DATA, EVENTID_CRATE_JPKR_CREDIT_EXCHANGE)
            end
        end
    end

    print("[CRATE_BYPASS] All supply/crate/shop hooks installed ✓")

end)

-- ═══════════════════════════════════════════════════════════════════════════
-- TRNDRAVIX MERGED — Missing Systems for active.lua
-- Standalone. Paste at end. No conflicts. Fixed & clean.
-- Includes: Random Values + SetRoleInfo + CollectFake + Fake Spin + UC Guard
-- ═══════════════════════════════════════════════════════════════════════════
pcall(function()
    if _G._TRX_LOADED then return end
    _G._TRX_LOADED = true

    -- ═════════════════════════════════════════════════════════════════════
    -- PART A — FEATURE TOGGLES + RANDOM VALUE ENGINE
    -- ═════════════════════════════════════════════════════════════════════
    _G.TRX_Features = _G.TRX_Features or {}

    local function AddFeature(id, name, defaultVal)
        for _, f in ipairs(_G.TRX_Features) do
            if f.id == id then return end
        end
        table.insert(_G.TRX_Features, {
            id = id, name = name, val = defaultVal or 1, type = "toggle"
        })
    end

    AddFeature("FAKE_VIP",              "Fake VIP Status",            1)
    AddFeature("FAKE_FRAME",            "Fake Avatar Frame",          1)
    AddFeature("FAKE_ALL_VEHICLES",     "Unlock All Vehicle Skins",   1)
    AddFeature("FAKE_MAX_RANK",         "Fake Max Rank Conqueror",    1)
    AddFeature("FAKE_CREDIT",           "Fake Credit 100",            1)
    AddFeature("FAKE_CORPS_MONEY",      "Fake Corps Money",           1)
    AddFeature("FAKE_ITEM_COUNT",       "Fake Item Count 999",        1)
    AddFeature("CLIENT_FAKE_CURRENCY",  "Client Fake Currency",       1)
    AddFeature("CLIENT_FAKE_INVENTORY", "Client Fake Inventory",      1)
    AddFeature("CLIENT_FAKE_SKINS",     "Client Fake Skins",          1)
    AddFeature("CLIENT_FAKE_SPINS",     "Client Fake Spins",          1)
    AddFeature("CLIENT_FAKE_LOOTBOX",   "Client Fake Loot Box",       1)
    AddFeature("CLIENT_FAKE_LEVEL",     "Client Fake Level",          1)
    AddFeature("CLIENT_FAKE_RANK",      "Client Fake Rank",           1)

    function _G.TRX_GetVal(id)
        for _, f in ipairs(_G.TRX_Features or {}) do
            if f.id == id then return f.val end
        end
        return 0
    end

    -- Random engine — per-session
    math.randomseed(os.time() + (os.clock() * 1000000) % 1000000)

    local function RandomBig(minVal, maxVal)
        minVal = minVal or 10000000
        maxVal = maxVal or 900000000
        local v = minVal + math.random(0, maxVal - minVal)
        local tail = math.random(1, 99) * 7 + math.random(1, 9)
        return math.floor(v / 100) * 100 + tail
    end

    local function RandomMed(minVal, maxVal)
        minVal = minVal or 10000
        maxVal = maxVal or 500000
        local v = minVal + math.random(0, maxVal - minVal)
        local tail = math.random(1, 97)
        return math.floor(v / 10) * 10 + (tail % 10)
    end

    _G._FakeVals = _G._FakeVals or {
        gold            = RandomBig(45000000, 890000000),
        ticket          = RandomBig(5000000, 8000000),
        diamond         = RandomMed(60000, 480000),
        fp_token        = RandomMed(40000, 300000),
        gen_ticket      = RandomMed(20000, 180000),
        gold_chip       = RandomMed(50000, 400000),
        smelt           = RandomMed(15000, 220000),
        battle_coin     = RandomMed(80000, 550000),
        eternal_diamond = RandomMed(5000, 85000),
        corps_money     = RandomBig(500000, 8000000),
        carteam_coin    = RandomMed(3000, 45000),
        credit          = math.random(85, 100),
        merit           = math.random(85, 100),
        level           = math.random(85, 89),
        pve_level       = math.random(85, 89),
        roleExp         = RandomMed(50000, 900000),
        vip_exp         = RandomMed(60000, 900000),
    }

    local function GetLevel()
        return (_G._FakeVals and _G._FakeVals.level) or 87
    end
    _G.TRX_GetLevel = GetLevel

    print(string.format("[TRX] Random values: L%d | Gold %d | UC %d | Silver %d",
        _G._FakeVals.level, _G._FakeVals.gold, _G._FakeVals.ticket, _G._FakeVals.diamond))

    -- ═════════════════════════════════════════════════════════════════════
    -- PART B — APPLY FAKE DATA
    -- ═════════════════════════════════════════════════════════════════════
    local function setIfExists(tbl, key, val)
        if tbl and tbl[key] ~= nil then
            pcall(function() tbl[key] = val end)
        end
    end

    local function fireEvent(et, eid, ...)
        if not EventSystem or not EventSystem.postEvent then return end
        if not et or not eid then return end
        pcall(EventSystem.postEvent, EventSystem, et, eid, ...)
    end

    local function ApplyAllFakeData()
        pcall(function()
            local DM = _G.DataMgr
                or (package.loaded and package.loaded.DataMgr)
                or (package.loaded and package.loaded["client.logic.data.data_mgr"])
            if not DM then return end
            local V = _G._FakeVals
            if not V then return end

            if _G.TRX_GetVal("CLIENT_FAKE_CURRENCY") == 1 then
                setIfExists(DM, "gold",              V.gold)
                setIfExists(DM, "diamond",           V.diamond)
                setIfExists(DM, "ticket",            V.ticket)
                setIfExists(DM, "fp_token",          V.fp_token)
                setIfExists(DM, "gen_ticket",        V.gen_ticket)
                setIfExists(DM, "gold_chip",         V.gold_chip)
                setIfExists(DM, "smelt",             V.smelt)
                setIfExists(DM, "battle_coin",       V.battle_coin)
                setIfExists(DM, "eternal_diamond",   V.eternal_diamond)
                setIfExists(DM, "corps_money",       V.corps_money)
                setIfExists(DM, "carteam_coin_count",V.carteam_coin)
                setIfExists(DM, "uc",                V.ticket)
                setIfExists(DM, "UC",                V.ticket)
            end

            if _G.TRX_GetVal("FAKE_VIP") == 1 and DM.roleData then
                DM.roleData.bgbg_vip = 1
                DM.roleData.vip_level = 10
                DM.roleData.vip_exp = V.vip_exp
            end

            if _G.TRX_GetVal("FAKE_FRAME") == 1 and DM.roleData then
                DM.roleData.cur_avatar_box_id = 1001
                if DM.roleData.nameFrameData then
                    DM.roleData.nameFrameData[1001] = { is_used = 1 }
                end
            end

            if _G.TRX_GetVal("FAKE_CREDIT") == 1 and DM.roleData then
                DM.roleData.credit = V.credit
                DM.roleData.merit = V.merit
            end

            if _G.TRX_GetVal("CLIENT_FAKE_LEVEL") == 1 and DM.roleData then
                DM.roleData.level = GetLevel()
                DM.roleData.pve_level = V.pve_level
                DM.roleData.roleExp = V.roleExp
            end

            if _G.TRX_GetVal("FAKE_MAX_RANK") == 1 or _G.TRX_GetVal("CLIENT_FAKE_RANK") == 1 then
                if DM.roleData then
                    DM.roleData.segment = DM.roleData.segment or {}
                    DM.roleData.segment.solo = 801
                    DM.roleData.segment.double = 801
                    DM.roleData.segment.team = 801
                    DM.roleData.segment.fpp_solo = 801
                    DM.roleData.segment.fpp_double = 801
                    DM.roleData.segment.fpp_team = 801
                    DM.roleData.allzoneSegment = DM.roleData.allzoneSegment or {}
                    for z = 1, 10 do
                        DM.roleData.allzoneSegment[z] = {
                            [1] = 801, [2] = 801, [3] = 801,
                            [4] = 801, [5] = 801, [6] = 801
                        }
                    end
                    DM.maxSegment = { zoneid = 1, segmentType = 3, SegmentLevel = 801 }
                end
            end

            if _G.TRX_GetVal("FAKE_CORPS_MONEY") == 1 then
                DM.corps_money = V.corps_money
                if DM.corpsInfo then DM.corpsInfo.fund = V.corps_money end
            end

            fireEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_GOLD_CHANGE,        V.gold)
            fireEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_TICKET_CHANGE,      V.ticket)
            fireEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_DIAMOND_CHANGE,     V.diamond)
            fireEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_ROLE_LEVEL_CHANGE,  GetLevel())
        end)
    end
    _G.TRX_ApplyAllFakeData = ApplyAllFakeData

    -- ═════════════════════════════════════════════════════════════════════
    -- PART C — FAKE SPIN + LOOTBOX
    -- ═════════════════════════════════════════════════════════════════════
    local SPIN_RESULTS = {
        {item = 201001, name = "M416 Glacier",  rarity = "Legendary"},
        {item = 201002, name = "AKM Glacier",   rarity = "Legendary"},
        {item = 301001, name = "Godzilla Suit", rarity = "Mythic"},
        {item = 301002, name = "Pharaoh Suit",  rarity = "Mythic"},
        {item = 401001, name = "Gold Car",      rarity = "Legendary"},
        {item = 701001, name = "Dance Emote",   rarity = "Epic"},
    }

    _G.TRX_ClientSpin = function()
        if _G.TRX_GetVal("CLIENT_FAKE_SPINS") ~= 1 then return end
        pcall(function()
            local r = SPIN_RESULTS[math.random(#SPIN_RESULTS)]
            print("[TRX] SPIN: " .. r.name .. " (" .. r.rarity .. ")")
            if _G.DataMgr and _G.DataMgr.item_store then
                _G.DataMgr.item_store[r.item] = (_G.DataMgr.item_store[r.item] or 0) + 1
            end
            fireEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_HALL_DEPOT_DATA_CHANGE, {})
        end)
    end

    local LOOT_BOX_ITEMS = {
        {item = 201001, name = "M416 Glacier",  rarity = "Legendary"},
        {item = 301001, name = "Godzilla Suit", rarity = "Mythic"},
        {item = 401001, name = "Gold Car",      rarity = "Legendary"},
        {item = 101001, name = "10,000 Gold",   rarity = "Common"},
        {item = 701001, name = "Dance Emote",   rarity = "Epic"},
    }

    _G.TRX_ClientOpenBox = function()
        if _G.TRX_GetVal("CLIENT_FAKE_LOOTBOX") ~= 1 then return end
        pcall(function()
            local n = math.random(1, 3)
            print("[TRX] LOOTBOX: " .. n .. " items")
            for i = 1, n do
                local it = LOOT_BOX_ITEMS[math.random(#LOOT_BOX_ITEMS)]
                print("[TRX]   " .. i .. ". " .. it.name)
                if _G.DataMgr and _G.DataMgr.item_store then
                    _G.DataMgr.item_store[it.item] = (_G.DataMgr.item_store[it.item] or 0) + 1
                end
            end
            fireEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_HALL_DEPOT_DATA_CHANGE, {})
        end)
    end

    -- ═════════════════════════════════════════════════════════════════════
    -- PART D — SET ROLE INFO (Conqueror + Badge)
    -- ═════════════════════════════════════════════════════════════════════
    pcall(function()
        local CURRENT_SEGMENT              = 801
        local CONQUEROR_STARS              = 91
        local CURRENT_RATING               = 4200 + (CONQUEROR_STARS - 1) * 100
        local HISTORY_SEGMENT              = 801
        local PEAK_CURRENT_SEGMENT         = 1541
        local PEAK_HISTORY_SEGMENT         = 1301
        local PEAK_RATING                  = 8000
        local JOURNEY_BADGE_LEVEL          = 17
        local JOURNEY_BADGE_VISUAL_LEVEL   = 3
        local JOURNEY_BADGE_GLOW_TASKS     = 3
        local JOURNEY_GLOW_RANKS           = { 701, 702, 703, 801 }
        local ENABLE_SEASON_YEAR_BADGE     = true
        local SHOW_SEASON_SERIES_MEDAL     = true
        local SEASON_SERIES_SEGMENT        = 0
        local SEASON_RATING                = 8500
        local SEASON_RANK                  = "44"
        local ACHIEVEMENT_POINTS           = 9500
        local PLAYED_YEARS                 = 10
        local CONQUEROR_TITLE_ID           = 0
        local AVATAR_ID                    = 30396
        local AVATAR_BOX_ID                = 2002901

        local function get_star_rating()
            if tonumber(CURRENT_SEGMENT) ~= 801 then return tonumber(CURRENT_RATING) or 0 end
            local stars = tonumber(CONQUEROR_STARS) or 0
            if stars > 0 then return 4200 + (stars - 1) * 100 end
            return tonumber(CURRENT_RATING) or 0
        end

        local function is_self_uid(uid)
            if not _G.DataMgr or not _G.DataMgr.roleData or not _G.DataMgr.roleData.uid then
                return false
            end
            return tonumber(uid) == tonumber(_G.DataMgr.roleData.uid)
        end

        local function get_fake_registertime()
            local ok, TU = pcall(require, "client.common.time_util")
            local now = (ok and TU and TU.GetServerTimeInSec and TU.GetServerTimeInSec()) or os.time()
            return now - (PLAYED_YEARS * 365 * 86400)
        end

        local SEGMENT_TYPE = {
            solo = 1, double = 2, team = 3,
            fpp_solo = 4, fpp_double = 5, fpp_team = 6,
        }
        local ZONE_COUNT = 6

        local function resolve_conqueror_title_id()
            if CONQUEROR_TITLE_ID and CONQUEROR_TITLE_ID > 0 then return CONQUEROR_TITLE_ID end
            local bestId, bestPri = nil, -1
            pcall(function()
                local tbl = CDataTable and CDataTable.GetTable and CDataTable.GetTable("SegmentTitleConfig")
                if not tbl then return end
                for id, cfg in pairs(tbl) do
                    if cfg and not cfg.IfDefaultTitle then
                        local pri = tonumber(cfg.Priority) or 0
                        local tid = tonumber(cfg.ID) or tonumber(id)
                        if tid and pri > bestPri then
                            bestPri = pri
                            bestId = tid
                        end
                    end
                end
            end)
            return bestId or 0
        end

        local function build_zone_segments(seg)
            return {
                [SEGMENT_TYPE.solo] = seg, [SEGMENT_TYPE.double] = seg, [SEGMENT_TYPE.team] = seg,
                [SEGMENT_TYPE.fpp_solo] = seg, [SEGMENT_TYPE.fpp_double] = seg, [SEGMENT_TYPE.fpp_team] = seg,
            }
        end

        local function build_allzone_segment(seg)
            local t = {}
            for z = 1, ZONE_COUNT do t[z] = build_zone_segments(seg) end
            return t
        end

        local function build_hsegment_title(titleId)
            if not titleId or titleId <= 0 then return nil end
            local det = {}
            for z = 1, ZONE_COUNT do
                det[z] = {}
                for modeId = 1, 6 do det[z][modeId] = { id = titleId } end
            end
            return det
        end

        local function apply_data_mgr_ranks()
            if not _G.DataMgr or not _G.DataMgr.roleData then return end
            local rd = _G.DataMgr.roleData
            local cur = CURRENT_SEGMENT
            local rating = get_star_rating()
            rd.segment = rd.segment or {}
            rd.segment.solo = cur
            rd.segment.double = cur
            rd.segment.team = cur
            rd.segment.fpp_solo = cur
            rd.segment.fpp_double = cur
            rd.segment.fpp_team = cur
            rd.allzoneSegment = build_allzone_segment(cur)
            local tid = resolve_conqueror_title_id()
            if tid > 0 then rd.allzoneSegmentTitle = build_hsegment_title(tid) end
            _G.DataMgr.isSeasonStarOpen = true
            rd.is_season_star_open = true
            _G.DataMgr.maxSegmentSquad = _G.DataMgr.maxSegmentSquad or { zoneid = 1, SegmentLevel = 0 }
            _G.DataMgr.maxSegmentSquad.SegmentLevel = cur
            _G.DataMgr.maxSegmentSquad.zoneid = 1
            rd.casual_segment_id = SEASON_SERIES_SEGMENT > 0 and SEASON_SERIES_SEGMENT or 101
            _G.DataMgr.registertime = get_fake_registertime()
        end

        local function apply_personal_basic()
            pcall(function()
                local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
                if not RoleInfoSystem then return end
                local pbi = RoleInfoSystem.PersonalBasicInfo
                if not pbi or type(pbi) ~= "table" then return end
                pbi.all_segment_info = build_allzone_segment(CURRENT_SEGMENT)
                local tid = resolve_conqueror_title_id()
                if tid > 0 then pbi.hsegment_title_det = build_hsegment_title(tid) end
                pbi.role_all_zone_segment_max = CURRENT_SEGMENT
            end)
        end

        local function apply_bottom_profile_stats()
            pcall(function()
                local RoleInfoSystem = require("client/logic/roleinfo/logic_roleinfo") or
                                       require("client.logic.roleinfo.logic_roleinfo")
                if not RoleInfoSystem then return end
                local uid = _G.DataMgr and _G.DataMgr.roleData and tonumber(_G.DataMgr.roleData.uid)
                if not uid then return end
                if RoleInfoSystem.CurrSeasonTPPTotalScore then
                    for zid = 1, ZONE_COUNT do
                        RoleInfoSystem.CurrSeasonTPPTotalScore[zid] = SEASON_RATING
                        RoleInfoSystem.CurrSeasonFPPTotalScore[zid] = SEASON_RATING
                        RoleInfoSystem.CurrSeasonTPPTotalRank[zid] = SEASON_RANK
                        RoleInfoSystem.CurrSeasonFPPTotalRank[zid] = SEASON_RANK
                    end
                end
                local ok, AH = pcall(require, "client.network.Protocol.AchieveHandler")
                if ok and AH and AH.resSummaryTb then
                    AH.resSummaryTb[uid] = AH.resSummaryTb[uid] or {}
                    AH.resSummaryTb[uid].achieve_score = ACHIEVEMENT_POINTS
                    AH.resSummaryTb[uid].uid = uid
                end
            end)
        end

        local function apply_extra_settings()
            if _G.DataMgr and _G.DataMgr.roleData then
                _G.DataMgr.roleData.level = GetLevel()
                _G.DataMgr.roleData.pic_url = AVATAR_ID
                _G.DataMgr.roleData.headIconUrl = AVATAR_ID
                _G.DataMgr.roleData.pic_url_check_open = true
                _G.DataMgr.roleData.cur_avatar_box_id = AVATAR_BOX_ID
            end
        end

        local function apply_all_roleinfo()
            pcall(apply_data_mgr_ranks)
            pcall(apply_personal_basic)
            pcall(apply_bottom_profile_stats)
            pcall(apply_extra_settings)
        end

        local function patch_conqueror_star_ui()
            if _G._TRX_star_ui_patched then return end
            _G._TRX_star_ui_patched = true
            pcall(function()
                local RIC = require("client.slua.umg.rankIntegral.RankIntegralIconSmall")
                if RIC and RIC.SetRankInteralWithSegmentTitle and not RIC._TRX_orig_RII then
                    RIC._TRX_orig_RII = RIC.SetRankInteralWithSegmentTitle
                    RIC.SetRankInteralWithSegmentTitle = function(self, seg, tn, sid, tid, rating)
                        if tonumber(seg) == 801 and (not rating or tonumber(rating) == 0) then
                            rating = get_star_rating()
                        end
                        return RIC._TRX_orig_RII(self, seg, tn, sid, tid, rating)
                    end
                end
            end)
            pcall(function()
                local SH = require("client.network.Protocol.SeasonHandler")
                if SH and tonumber(CURRENT_SEGMENT) == 801 then
                    SH.rank_rating = get_star_rating()
                end
            end)
        end

        local function install_roleinfo_refresh_hooks()
            patch_conqueror_star_ui()
            pcall(function()
                local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
                if RoleInfoSystem and RoleInfoSystem.get_role_basic_info_rsp
                    and not RoleInfoSystem._TRX_wrapped then
                    RoleInfoSystem._TRX_wrapped = true
                    local o = RoleInfoSystem.get_role_basic_info_rsp
                    RoleInfoSystem.get_role_basic_info_rsp = function(list)
                        o(list)
                        apply_all_roleinfo()
                    end
                end
            end)
        end

        apply_all_roleinfo()
        install_roleinfo_refresh_hooks()

        print(string.format("[TRX] SetRoleInfo loaded | Conqueror=%d | Stars=%d | Rating=%d | Journey=%d",
            CURRENT_SEGMENT, CONQUEROR_STARS, get_star_rating(), JOURNEY_BADGE_LEVEL))
    end)

    -- ═════════════════════════════════════════════════════════════════════
    -- PART E — COLLECT FAKE
    -- ═════════════════════════════════════════════════════════════════════
    pcall(function()
        _G.FAKE_LEVEL      = _G.FAKE_LEVEL      or 100
        _G.FAKE_DAN        = _G.FAKE_DAN        or 100
        _G.FAKE_LEVEL_NAME = _G.FAKE_LEVEL_NAME or "Collection Champion"
        _G.FAKE_SCORE      = _G.FAKE_SCORE      or 99999

        local function patch_collect_module(mod)
            if not mod or rawget(mod, "_TRX_collect_patched") then return false end
            rawset(mod, "_TRX_collect_patched", true)

            if mod.GetLevelDataByScore then
                rawset(mod, "GetLevelDataByScore", function(self, score, isSeason)
                    return _G.FAKE_LEVEL, _G.FAKE_LEVEL_NAME, _G.FAKE_DAN
                end)
            end
            if mod.GetSeasonLevelByScore then
                rawset(mod, "GetSeasonLevelByScore", function(self, score, seasonId)
                    return _G.FAKE_LEVEL, true, _G.FAKE_LEVEL_NAME
                end)
            end
            if mod.GetCollectScoreByCollectData then
                rawset(mod, "GetCollectScoreByCollectData", function(self, cd)
                    return _G.FAKE_SCORE, _G.FAKE_SCORE
                end)
            end

            local cd = rawget(mod, "collect_data")
            if cd and type(cd) == "table" then
                rawset(cd, "total_score", _G.FAKE_SCORE)
                if not rawget(cd, "season_score") then rawset(cd, "season_score", {}) end
                local s = (rawget(mod, "GetSeasonId") and mod:GetSeasonId()) or 1
                cd.season_score[s] = _G.FAKE_SCORE
                rawset(cd, "cur_season_collect_score", _G.FAKE_SCORE)
            end

            if rawget(mod, "OnGetMainData") or mod.OnGetMainData then
                local og = rawget(mod, "OnGetMainData") or mod.OnGetMainData
                rawset(mod, "OnGetMainData", function(self, ec, data, param)
                    if data and type(data) == "table" then
                        rawset(data, "total_score", _G.FAKE_SCORE)
                        if not rawget(data, "season_score") then rawset(data, "season_score", {}) end
                        local s = (rawget(self, "GetSeasonId") and self:GetSeasonId()) or 1
                        if type(data.season_score) == "table" then data.season_score[s] = _G.FAKE_SCORE end
                        rawset(data, "cur_season_collect_score", _G.FAKE_SCORE)
                    end
                    og(self, ec, data, param)
                end)
            end
            return true
        end

        local function get_collect_module()
            local MM = _G.ModuleManager
            if MM and MM.GetModule and MM.LobbyModuleConfig then
                local ok, cm = pcall(MM.GetModule, MM, MM.LobbyModuleConfig.collect_module)
                if ok and cm then return cm end
            end
            for _, mod in pairs(package.loaded or {}) do
                if type(mod) == "table" and mod.GetLevelDataByScore and mod.GetSeasonLevelByScore then
                    return mod
                end
            end
            return nil
        end

        local function inject_collect_data()
            pcall(function()
                local cm = get_collect_module()
                if cm then
                    local cd = rawget(cm, "collect_data")
                    if cd and type(cd) == "table" then
                        rawset(cd, "total_score", _G.FAKE_SCORE)
                        if not rawget(cd, "season_score") then rawset(cd, "season_score", {}) end
                        local s = (rawget(cm, "GetSeasonId") and cm:GetSeasonId()) or 1
                        if type(cd.season_score) == "table" then cd.season_score[s] = _G.FAKE_SCORE end
                        rawset(cd, "cur_season_collect_score", _G.FAKE_SCORE)
                    end
                end
            end)
            pcall(function()
                if _G.DataMgr and _G.DataMgr.roleData then
                    if not _G.DataMgr.roleData.brief_collect_data then
                        _G.DataMgr.roleData.brief_collect_data = {}
                    end
                    _G.DataMgr.roleData.brief_collect_data.total_score = _G.FAKE_SCORE
                    _G.DataMgr.roleData.brief_collect_data.cur_season_collect_score = _G.FAKE_SCORE
                end
            end)
        end

        local function hook_collect_handler()
            for path, mod in pairs(package.loaded or {}) do
                if type(mod) == "table" and mod.on_get_collect_sys_main_data_rsp
                    and not rawget(mod, "_TRX_collect_handler_hooked") then
                    rawset(mod, "_TRX_collect_handler_hooked", true)
                    local o = mod.on_get_collect_sys_main_data_rsp
                    mod.on_get_collect_sys_main_data_rsp = function(ec, cd, param)
                        if cd and type(cd) == "table" then
                            rawset(cd, "total_score", _G.FAKE_SCORE)
                            rawset(cd, "cur_season_collect_score", _G.FAKE_SCORE)
                            local ss = rawget(cd, "season_score")
                            if type(ss) == "table" then
                                for k in pairs(ss) do ss[k] = _G.FAKE_SCORE end
                            else
                                rawset(cd, "season_score", { [1] = _G.FAKE_SCORE, [2] = _G.FAKE_SCORE })
                            end
                        end
                        return o(ec, cd, param)
                    end
                end
            end
        end

        local function install_collect_hooks()
            hook_collect_handler()
            for _, mod in pairs(package.loaded or {}) do
                if type(mod) == "table" and mod.GetLevelDataByScore and mod.GetSeasonLevelByScore
                    and not rawget(mod, "_TRX_collect_patched") then
                    patch_collect_module(mod)
                end
            end
            local cm = get_collect_module()
            if cm then patch_collect_module(cm) end
            inject_collect_data()
        end

        install_collect_hooks()

        _G.CollectFake = {
            Apply = function() install_collect_hooks() end,
            SetLevel = function(n)
                _G.FAKE_LEVEL = tonumber(n) or _G.FAKE_LEVEL
                install_collect_hooks()
                return _G.FAKE_LEVEL
            end,
            SetName = function(name) _G.FAKE_LEVEL_NAME = tostring(name) or _G.FAKE_LEVEL_NAME end,
            SetScore = function(n)
                _G.FAKE_SCORE = tonumber(n) or _G.FAKE_SCORE
                install_collect_hooks()
                return _G.FAKE_SCORE
            end,
            SetDan = function(n) _G.FAKE_DAN = tonumber(n) or _G.FAKE_DAN end,
        }

        print("[TRX] CollectFake loaded")
    end)

    -- ═════════════════════════════════════════════════════════════════════
    -- PART F — UC GUARD (4-LAYER PROTECTION) — CRITICAL
    -- ═════════════════════════════════════════════════════════════════════
    do
        local CURRENCY_MAP = {
            ticket             = "ticket",
            gold               = "gold",
            diamond            = "diamond",
            fp_token           = "fp_token",
            gen_ticket         = "gen_ticket",
            gold_chip          = "gold_chip",
            smelt              = "smelt",
            battle_coin        = "battle_coin",
            eternal_diamond    = "eternal_diamond",
            corps_money        = "corps_money",
            carteam_coin_count = "carteam_coin",
            uc                 = "ticket",
            UC                 = "ticket",
        }
        local EVENT_MAP = {
            ticket      = "EVENTID_DATAMGR_TICKET_CHANGE",
            gold        = "EVENTID_DATAMGR_GOLD_CHANGE",
            diamond     = "EVENTID_DATAMGR_DIAMOND_CHANGE",
            corps_money = "EVNETID_DATAMGR_CORPS_MONEY_CHANGE",
        }

        local _evIdToKey, _keyToEvId = {}, {}
        local function rebuildEventMaps()
            _evIdToKey, _keyToEvId = {}, {}
            for dmKey, evName in pairs(EVENT_MAP) do
                local ev = _G[evName]
                if ev then
                    _evIdToKey[ev] = dmKey
                    _keyToEvId[dmKey] = ev
                end
            end
        end
        rebuildEventMaps()

        local function getFake(dmKey)
            local fk = CURRENCY_MAP[dmKey]
            if not fk then return nil end
            local V = _G._FakeVals
            return V and V[fk] or nil
        end

        local function forceAll(DM)
            if not DM or type(DM) ~= "table" then return end
            local V = _G._FakeVals
            if not V then return end
            for dmKey, fk in pairs(CURRENCY_MAP) do
                local fake = V[fk]
                if fake ~= nil then pcall(rawset, DM, dmKey, fake) end
            end
        end

        local function collectDataMgrs()
            local list, seen = {}, {}
            local function add(t)
                if t and type(t) == "table" and not seen[t] then
                    seen[t] = true
                    list[#list + 1] = t
                end
            end
            add(_G.DataMgr)
            pcall(function() add(package.loaded["client.logic.data.data_mgr"]) end)
            pcall(function() add(package.loaded["DataMgr"]) end)
            pcall(function() add(rawget(_G, "DataMgr")) end)
            pcall(function()
                local m = package.loaded["client.logic.data.data_mgr"]
                if m and m.__inner_impl then add(m.__inner_impl) end
            end)
            return list
        end

        -- L1: metatable guard
        local _guarded = setmetatable({}, {__mode = "k"})
        local function guardTable(DM)
            if not DM or type(DM) ~= "table" then return false end
            if _guarded[DM] then
                forceAll(DM)
                return true
            end
            _guarded[DM] = true
            local mt = getmetatable(DM) or {}
            local origNew = mt.__newindex
            mt.__newindex = function(t, k, v)
    -- 1. Validate Table State First
    if not t or type(t) ~= "table" then 
        return 
    end

    if type(k) == "string" and CURRENCY_MAP[k] then
        local fake = getFake(k)
        if fake ~= nil then
            -- 2. Safe Write with PCALL protection against GC locks
            pcall(rawset, t, k, fake) 
            
            -- 3. Fire Event only if write succeeded (implicit via pcall scope, but safe to assume)
            local evId = _keyToEvId[k]
            if evId and EventSystem and EventSystem.postEvent then
                pcall(function()
                    EventSystem:postEvent(EVENTTYPE_DATA_MGR, evId, fake)
                end)
            end
            return
        end
    end
    
    -- Fallback to original logic safely
    if origNew then 
        pcall(origNew, t, k, v) 
    else 
        pcall(rawset, t, k, v) 
    end
end
            setmetatable(DM, mt)
            forceAll(DM)
            return true
        end

        -- L2: EventSystem interceptor
        local function hookEventSystem()
            if _G._TRX_EventHook then return true end
            if not EventSystem or not EventSystem.postEvent then return false end
            _G._TRX_EventHook = true
            local orig = EventSystem.postEvent
            EventSystem.postEvent = function(self, et, eid, val, ...)
                if et == EVENTTYPE_DATA_MGR and eid and _evIdToKey[eid] then
                    local dmKey = _evIdToKey[eid]
                    local fake = getFake(dmKey)
                    if fake ~= nil then
                        for _, DM in ipairs(collectDataMgrs()) do
                            pcall(rawset, DM, dmKey, fake)
                        end
                        return orig(self, et, eid, fake, ...)
                    end
                end
                return orig(self, et, eid, val, ...)
            end
            return true
        end

        -- L3: watchdog + L4: reference detection
        local _lastDMRefs = {}
        local function watchTick()
            pcall(function()
                local dms = collectDataMgrs()
                local changed = (#dms ~= #_lastDMRefs)
                if not changed then
                    for i = 1, #dms do
                        if dms[i] ~= _lastDMRefs[i] then changed = true; break end
                    end
                end
                if changed then
                    _lastDMRefs = dms
                    for _, DM in ipairs(dms) do guardTable(DM) end
                else
                    for _, DM in ipairs(dms) do
                        if not _guarded[DM] then guardTable(DM) end
                        forceAll(DM)
                    end
                end
                local V = _G._FakeVals
                local tEv = _keyToEvId.ticket
                if tEv and V and V.ticket and EventSystem and EventSystem.postEvent then
                    pcall(function()
                        EventSystem:postEvent(EVENTTYPE_DATA_MGR, tEv, V.ticket)
                    end)
                end
            end)
        end

        local function startWatchdog()
            if _G._TRX_Watchdog then return true end
            _G._TRX_Watchdog = true
            local used = false
            pcall(function()
                local ticker = require("common.time_ticker")
                if ticker and ticker.AddTimerLoop then
                    ticker.AddTimerLoop(0, watchTick, -1, 0.5)
                    used = true
                    print("[TRX] UC watchdog via time_ticker (0.5s)")
                end
            end)
            if not used then
                local function attach()
                    pcall(function()
                        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                        if pc and slua.isValid(pc) and pc.AddGameTimer and pc ~= _G._TRX_PC then
                            _G._TRX_PC = pc
                            pc:AddGameTimer(0.5, true, watchTick)
                        end
                    end)
                end
                attach()
                pcall(function()
                    local ticker = require("common.time_ticker")
                    if ticker and ticker.AddTimerLoop then
                        ticker.AddTimerLoop(0, attach, -1, 5.0)
                    end
                end)
            end
            return true
        end

        local function installUCGuard()
            rebuildEventMaps()
            local dms = collectDataMgrs()
            local n = 0
            for _, DM in ipairs(dms) do
                if guardTable(DM) then n = n + 1 end
            end
            hookEventSystem()
            startWatchdog()
            return n
        end

        local n = installUCGuard()
        print(string.format("[TRX] UC Guard installed: %d tables guarded", n))

        for _, d in ipairs({2, 5, 10, 20, 45}) do
            pcall(function()
                local ticker = require("common.time_ticker")
                if ticker and ticker.AddTimerOnce then
                    ticker.AddTimerOnce(d, installUCGuard)
                end
            end)
        end

        _G.TRX_FinalFixUC = installUCGuard
    end

    -- ═════════════════════════════════════════════════════════════════════
    -- PART G — APPLY + STATUS + TIMER
    -- ═════════════════════════════════════════════════════════════════════
    local FAKE_TIMER = nil

    local function StartFakeTimer()
        if FAKE_TIMER then
            pcall(function()
                if _G.Game then _G.Game:RemoveGameTimer(FAKE_TIMER) end
            end)
            FAKE_TIMER = nil
        end
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if pc and slua.isValid(pc) and pc.AddGameTimer then
            ApplyAllFakeData()
            FAKE_TIMER = pc:AddGameTimer(3.0, true, ApplyAllFakeData)
            return true
        end
        return false
    end

    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerLoop then
            ticker.AddTimerLoop(0, function()
                pcall(ApplyAllFakeData)
            end, -1, 5.0)
        end
    end)

    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(3.0, StartFakeTimer)
        end
    end)

    _G.TRX_Status = function()
        local V = _G._FakeVals or {}
        print("[TRX] ═══════════════════════════════")
        print(string.format("  Level: %d | Gold: %d | UC: %d | Silver: %d",
            V.level or 0, V.gold or 0, V.ticket or 0, V.diamond or 0))
        for _, f in ipairs(_G.TRX_Features or {}) do
            print(string.format("  %-25s = %s", f.name, f.val == 1 and "ON" or "OFF"))
        end
        print("[TRX] ═══════════════════════════════")
    end

    _G.TRX_ToggleAll = function()
        for _, f in ipairs(_G.TRX_Features or {}) do
            f.val = (f.val == 1 and 0 or 1)
        end
        print("[TRX] ALL toggled")
        ApplyAllFakeData()
    end

    _G.TRX_RefreshValues = function()
        _G._FakeVals = {
            gold            = RandomBig(45000000, 890000000),
            ticket          = RandomBig(5000000, 8000000),
            diamond         = RandomMed(60000, 480000),
            fp_token        = RandomMed(40000, 300000),
            gen_ticket      = RandomMed(20000, 180000),
            gold_chip       = RandomMed(50000, 400000),
            smelt           = RandomMed(15000, 220000),
            battle_coin     = RandomMed(80000, 550000),
            eternal_diamond = RandomMed(5000, 85000),
            corps_money     = RandomBig(500000, 8000000),
            carteam_coin    = RandomMed(3000, 45000),
            credit          = math.random(85, 100),
            merit           = math.random(85, 100),
            level           = math.random(85, 89),
            pve_level       = math.random(85, 89),
            roleExp         = RandomMed(50000, 900000),
            vip_exp         = RandomMed(60000, 900000),
        }
        print("[TRX] Values re-rolled")
        ApplyAllFakeData()
    end

    print("[TRX] ═══════════════════════════════")
    print("[TRX] ✅ TRNDRAVIX MERGED LOADED")
    print(string.format("[TRX] Level: %d | UC: %d | Gold: %d",
        _G._FakeVals.level, _G._FakeVals.ticket, _G._FakeVals.gold))
    print("[TRX] Commands: TRX_Status() | TRX_RefreshValues() | TRX_ToggleAll()")
    print("[TRX]           CollectFake.SetLevel(N) | TRX_FinalFixUC()")
    print("[TRX] ═══════════════════════════════")
end)


-- ═══ ROXZ SKIN FIX v1 ═══
pcall(function()
    if _G._ROXZ_SKIN_FIX then return end
    _G._ROXZ_SKIN_FIX = true
    local function log(...) print("[ROXZ_FIX]", ...) end
    local _roxz_guard = 0

    if EventSystem and EventSystem.registEvent then
        local function forceReapply(tag)
            pcall(function()
                local GD = package.loaded["GameLua.GameCore.Data.GameplayData"]
                    or require("GameLua.GameCore.Data.GameplayData")
                local char = GD and GD.GetPlayerCharacter and GD.GetPlayerCharacter()
                if not char or not slua.isValid(char) then return end
                if _G._S then
                    _G._S.matchOutfitDone, _G._S.weaponApplied = false, false
                    _G._S.weaponDiagDone, _G._S.avatarItemsRegistered = false, false
                    _G._S.lastAppliedWeaponID, _G._S.lastAppliedSkinID = 0, 0
                end
                _roxz_guard = 0
                if char.AddGameTimer then
                    char:AddGameTimer(0.15, false, function()
                        if slua.isValid(char) then
                            if _G.matchApplyOutfit     then _G.matchApplyOutfit(char)     end
                            if _G.matchApplyEquipSkins then _G.matchApplyEquipSkins(char) end
                        end
                    end)
                    char:AddGameTimer(0.5, false, function()
                        if slua.isValid(char) then
                            if _G.matchApplyEquipSkins then _G.matchApplyEquipSkins(char) end
                            local W = char.GetCurrentWeapon and char:GetCurrentWeapon()
                            if slua.isValid(W) and _G.applySkinToWeaponRef then
                                _G.applySkinToWeaponRef(W)
                            end
                        end
                    end)
                end
                log("Reapply: " .. tostring(tag))
            end)
        end
        pcall(function() EventSystem:registEvent(EVENTTYPE_PLAYEREVENT, 1024, function() forceReapply("respawn") end) end)
        pcall(function() EventSystem:registEvent(EVENTTYPE_PLAYEREVENT, 1025, function() forceReapply("revive") end) end)
        pcall(function() EventSystem:registEvent(EVENTTYPE_PLAYEREVENT, 1013, function() forceReapply("recycle") end) end)
        pcall(function() EventSystem:registEvent(EVENTTYPE_VEHICLE, 1001, function() forceReapply("veh_leave") end) end)
        pcall(function() EventSystem:registEvent(EVENTTYPE_VEHICLE, 1002, function() forceReapply("veh_enter") end) end)
        pcall(function() EventSystem:registEvent(EVENTTYPE_PLAYEREVENT_AVATAR, EVENTID_LOCAL_PLAYEREVENT_AVATAR_ALL_MESH_LOADED,
            function() forceReapply("mesh") end) end)
    end

    pcall(function()
        if not _G.applySkinToWeaponRef then return end
        local orig = _G.applySkinToWeaponRef
        _G.applySkinToWeaponRef = function(W)
            if os.time() < _roxz_guard then
                local mismatch = false
                pcall(function()
                    if slua.isValid(W) and W.synData then
                        local s = W.synData:Get(7)
                        if s then
                            local cur = tonumber(slua.IndexReference(s, "defineID").TypeSpecificID) or 0
                            local want = _G.get_skin_id and _G.get_skin_id(cur, cur) or cur
                            if want > 0 and want ~= cur then mismatch = true end
                        end
                    end
                end)
                if not mismatch then return false end
                _roxz_guard = 0
            end
            local ok = orig(W)
            _roxz_guard = os.time() + 1
            return ok
        end
    end)

    pcall(function()
        local t = require("common.time_ticker")
        if not t or not t.AddTimerLoop then return end
        t.AddTimerLoop(0, function()
            pcall(function()
                if not (GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus()) then return end
                local GD = package.loaded["GameLua.GameCore.Data.GameplayData"]
                    or require("GameLua.GameCore.Data.GameplayData")
                local char = GD and GD.GetPlayerCharacter and GD.GetPlayerCharacter()
                if not char or not slua.isValid(char) then return end
                if _G._S then _G._S.matchOutfitDone = false end
                if _G.matchApplyOutfit     then _G.matchApplyOutfit(char)     end
                if _G.matchApplyEquipSkins then _G.matchApplyEquipSkins(char) end
            end)
        end, -1, 3.0)
        t.AddTimerLoop(0, function()
            pcall(function()
                if not (GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus()) then return end
                local GD = package.loaded["GameLua.GameCore.Data.GameplayData"]
                    or require("GameLua.GameCore.Data.GameplayData")
                local char = GD and GD.GetPlayerCharacter and GD.GetPlayerCharacter()
                if not char or not slua.isValid(char) then return end
                if _G._S then _G._S.lastAppliedWeaponID, _G._S.lastAppliedSkinID = 0, 0 end
                _roxz_guard = 0
                local W = char.GetCurrentWeapon and char:GetCurrentWeapon()
                if slua.isValid(W) and _G.applySkinToWeaponRef then _G.applySkinToWeaponRef(W) end
                if _G.equip_weapon_avatar then _G.equip_weapon_avatar(char) end
            end)
        end, -1, 2.0)
    end)

    _G.ROXZ_ForceSkinReapply = function()
        local GD = package.loaded["GameLua.GameCore.Data.GameplayData"]
            or require("GameLua.GameCore.Data.GameplayData")
        local char = GD and GD.GetPlayerCharacter and GD.GetPlayerCharacter()
        if not char or not slua.isValid(char) then return end
        if _G._S then
            _G._S.matchOutfitDone, _G._S.weaponApplied = false, false
            _G._S.weaponDiagDone, _G._S.avatarItemsRegistered = false, false
            _G._S.lastAppliedWeaponID, _G._S.lastAppliedSkinID = 0, 0
        end
        _roxz_guard = 0
        if _G.matchApplyOutfit     then _G.matchApplyOutfit(char)     end
        if _G.matchApplyEquipSkins then _G.matchApplyEquipSkins(char) end
        if _G.equip_weapon_avatar  then _G.equip_weapon_avatar(char)  end
    end

    log("SKIN FIX v1 LOADED")
end)

