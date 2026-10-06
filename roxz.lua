-- ═══════════════════════════════════════════════════════════════════
-- RoxzRankFix v3.0 — Rank Score + Journey Badge + Stars
-- Uses exact zoulobb rank display hooks from decoded_output_GAME.lua
-- Compatible with existing active1.lua (no duplicate hooks)
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    if _G._ROXZ_RANK_V3 then return end
    _G._ROXZ_RANK_V3 = true

    -- ═══════════════════════════════════════════════════════════════
    -- CONFIG — zoulobb exact values + user requested badge
    -- ═══════════════════════════════════════════════════════════════
    local CFG = {
        SEGMENT              = 801,
        STARS                = 91,
        -- rating auto: 4200 + (91-1)*100 = 13200
        HISTORY_SEGMENT      = 801,
        PEAK_CURRENT         = 1541,
        PEAK_HISTORY         = 1301,
        PEAK_RATING          = 8000,
        BADGE_FINISH         = 73,      -- Journey badge finish count (user wants 73)
        GLOW_VISUAL_LV       = 3,
        CROWN_FINISH         = 3,
        GLOW_RANKS           = { 701, 702, 703, 801 },
        SEASON_RATING        = 8500,
        SEASON_RANK          = "44",
        ACHIEVE_POINTS       = 9500,
    }

    local function getStarRating()
        local s = tonumber(CFG.STARS) or 0
        if s > 0 then return 4200 + (s - 1) * 100 end
        return 4200
    end

    local _unpack = unpack or table.unpack
    local _pfx = "__roxz_r3_"

    local function safeReq(p)
        local m = package.loaded and package.loaded[p]
        if m then return m end
        local ok, r = pcall(require, p)
        return (ok and r) or nil
    end

    local function safeMod(k)
        local ok, m = pcall(function()
            if ModuleManager and ModuleManager.GetModule and ModuleManager.LobbyModuleConfig then
                return ModuleManager.GetModule(ModuleManager.LobbyModuleConfig[k])
            end
        end)
        return (ok and m) or nil
    end

    local function fireEvent(...)
        local args = { n = select("#", ...), ... }
        if not (EventSystem and EventSystem.postEvent) then return end
        pcall(function()
            EventSystem:postEvent(_unpack(args, 1, args.n))
        end)
    end

    local function hook(tbl, name, wrapper)
        if type(tbl) ~= "table" then return false end
        if type(tbl[name]) ~= "function" then return false end
        local key = _pfx .. name
        if rawget(tbl, key) then return false end
        rawset(tbl, key, tbl[name])
        tbl[name] = wrapper(rawget(tbl, key))
        return true
    end

    local function forceReturn(tbl, name, val)
        if type(tbl) ~= "table" then return false end
        if type(tbl[name]) ~= "function" then return false end
        local key = _pfx .. name
        if not rawget(tbl, key) then rawset(tbl, key, tbl[name]) end
        local v = val
        tbl[name] = function() return v end
        return true
    end

    -- ═══════════════════════════════════════════════════════════════
    -- STEP 1: Force SKIN_MOD flags (zoulobb rank beautify gate)
    -- ═══════════════════════════════════════════════════════════════
    pcall(function()
        _G.SKIN_MOD_U43C8a8 = _G.SKIN_MOD_U43C8a8 or {}
        _G.SKIN_MOD_U43C8a8.kRankBeautify = true
        _G._SKIN_MOD_U43C8a8 = _G.SKIN_MOD_U43C8a8

        _G._ZOULE_MOD_0bQ48gt3 = _G._ZOULE_MOD_0bQ48gt3 or _G.SKIN_MOD_U43C8a8
        _G._ZOULE_MOD_0bQ48gt3.kRankBeautify = true

        _G.SKIN_MOD_IsRankBeautifyEnabled = function() return true end
        _G.ZOULE_MOD_isDeadBoxSkinEnabled = _G.ZOULE_MOD_isDeadBoxSkinEnabled or function() return true end

        print("[RoxzRankFix v3] SKIN_MOD flags forced: kRankBeautify = true")
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- STEP 2: BUILD BADGE INFO (zoulobb exact structure)
    -- ═══════════════════════════════════════════════════════════════
    local function buildBadgeInfo()
        local SYearCfg = safeReq("client.logic.season_year.config.season_year_config")
        if not SYearCfg or not SYearCfg.EBadgePartType then return nil end
        local BP = SYearCfg.EBadgePartType
        local T  = SYearCfg.ERankTaskStatus and SYearCfg.ERankTaskStatus.Completed or 1
        local B  = CFG.BADGE_FINISH
        local VL = CFG.GLOW_VISUAL_LV
        local CF = CFG.CROWN_FINISH
        local GLOW = CFG.GLOW_RANKS
        local crownMax = SYearCfg.CrownTaskMaxCount or 10

        local gem   = { { finish_count = B, status = T } }
        local base  = { { finish_count = B, status = T } }
        local glow  = {}
        for i = 1, VL do
            glow[i] = { finish_count = 1, status = T, trigger_value = GLOW[i] or 801 }
        end
        local crown = {}
        for i = 1, crownMax do
            crown[i] = { finish_count = math.min(CF, B), status = T }
        end
        return {
            [BP.Gem]   = gem,
            [BP.Base]  = base,
            [BP.Glow]  = glow,
            [BP.Crown] = crown,
        }
    end

    -- ═══════════════════════════════════════════════════════════════
    -- STEP 3: HOOK ROLEINFO (patch data on the way out)
    -- ═══════════════════════════════════════════════════════════════
    local function applyRankToTable(t)
        if type(t) ~= "table" then return end
        local seg = CFG.SEGMENT

        -- segment per mode
        local segTbl = t.segment
        if type(segTbl) ~= "table" then segTbl = {} ; t.segment = segTbl end
        segTbl.solo, segTbl.double, segTbl.team       = seg, seg, seg
        segTbl.fpp_solo, segTbl.fpp_double, segTbl.fpp_team = seg, seg, seg

        -- allzoneSegment 6x6
        local az = t.allzoneSegment
        if type(az) ~= "table" then az = {} ; t.allzoneSegment = az end
        for z = 1, 6 do
            az[z] = az[z] or {}
            for m = 1, 6 do az[z][m] = seg end
        end

        -- history_max_segment
        t.history_max_segment_level  = t.history_max_segment_level or {}
        t.history_max_segment_season_id = t.history_max_segment_season_id or {}
        for i = 1, 6 do
            t.history_max_segment_level[i]        = CFG.HISTORY_SEGMENT
            t.history_max_segment_season_id[i]    = (DataMgr and DataMgr.season_id) or 0
        end

        -- cur_max_segment_level
        t.cur_max_segment_level = seg

        -- hsegment_title_det (segment title id)
        local function resolveTitleId()
            local bestId, bestPri = 0, -1
            pcall(function()
                local cfg = CDataTable.GetTable("SegmentTitleConfig")
                for id, row in pairs(cfg or {}) do
                    if row and not row.IfDefaultTitle then
                        local pri = tonumber(row.Priority) or 0
                        local tid = tonumber(row.ID or row.Id or id)
                        if tid and pri > bestPri then bestPri = pri ; bestId = tid end
                    end
                end
            end)
            return bestId
        end
        local tid = resolveTitleId()
        if tid and tid > 0 then
            t.hsegment_title_det = t.hsegment_title_det or {}
            for z = 1, 6 do
                t.hsegment_title_det[z] = t.hsegment_title_det[z] or {}
                for m = 1, 6 do t.hsegment_title_det[z][m] = { id = tid } end
            end
        end

        -- rating (star rating)
        local rating = getStarRating()
        t.rating = rating
        t.rank_rating = rating

        -- peakgame
        pcall(function()
            local PeakCfg = safeReq("client.logic.PeakGame.PeakGameConfig")
            if PeakCfg then
                local squad = PeakCfg.BattleType and PeakCfg.BattleType.Squad
                if squad then
                    local list = {}
                    for s = 1, 6 do
                        list[s] = {
                            [squad] = {
                                rating         = CFG.PEAK_RATING,
                                segment_id     = CFG.PEAK_CURRENT,
                                max_segment_id = CFG.PEAK_CURRENT,
                            }
                        }
                    end
                    t.peakgame_segment_info = { curr_season_id = (DataMgr and DataMgr.season_id) or 1, list = list }
                    t.peakgame_history_max_segment = CFG.PEAK_HISTORY
                end
            end
        end)

        -- badge info on role info
        local bi = buildBadgeInfo()
        if bi then
            t.season_year_badge_info = t.season_year_badge_info or {}
            t.season_year_badge = t.season_year_badge or {}
            pcall(function()
                local SU = safeReq("client.logic.season_year.util.season_year_util")
                local yid = (SU and SU.GetSeasonYearId and SU.GetSeasonYearId()) or 1
                t.season_year_badge_info[yid] = bi
                t.season_year_badge[yid] = bi
                t.season_year_badge[0] = bi
            end)
        end
    end

    local function applyRankToRoleData()
        pcall(function()
            if not DataMgr or not DataMgr.roleData then return end
            applyRankToTable(DataMgr.roleData)
            local seg = CFG.SEGMENT
            local rating = getStarRating()

            DataMgr.maxSegmentSquad = { zoneid = 1, SegmentLevel = seg }
            DataMgr.isSeasonStarOpen = true
            DataMgr.roleData.is_season_star_open = true

            pcall(function()
                local TU = safeReq("client.common.time_util")
                local now = (TU and TU.GetServerTimeInSec and TU.GetServerTimeInSec()) or os.time()
                DataMgr.registertime = now - (10 * 365 * 86400)
            end)
        end)
    end

    -- ═══════════════════════════════════════════════════════════════
    -- STEP 4: HOOK RANK UI DISPLAY FUNCTIONS (zoulobb r2132_70)
    -- ═══════════════════════════════════════════════════════════════
    local function installRankUIHooks()
        -- A) RankIntegralIconSmall (main profile small icon)
        pcall(function()
            local RIC = safeReq("client.slua.umg.rankIntegral.RankIntegralIconSmall")
            if RIC and type(RIC.SetRankInteralWithSegmentTitle) == "function" then
                hook(RIC, "SetRankInteralWithSegmentTitle", function(orig)
                    return function(self, seg, titleName, seasonId, titleId, rating)
                        if tonumber(seg) == 801 and (not rating or tonumber(rating) == 0) then
                            rating = getStarRating()
                        end
                        return orig(self, seg, titleName, seasonId, titleId, rating)
                    end
                end)
            end
        end)

        -- B) RankSmall_Sub_Base_UIBP (rank detail base)
        pcall(function()
            local RSB = safeReq("client.slua.umg.rankIntegral.RankSmall_Sub_Base_UIBP")
            if RSB and type(RSB.SetRankInteralWithSegmentTitle) == "function" then
                hook(RSB, "SetRankInteralWithSegmentTitle", function(orig)
                    return function(self)
                        if tonumber(self.rankIntegral) == 801 and (not self.rating or tonumber(self.rating) == 0) then
                            self.rating = getStarRating()
                        end
                        return orig(self)
                    end
                end)
            end
        end)

        -- C) logic_segment_title.SetMaxSegmentRankInteralWithTitle
        pcall(function()
            local LST = safeMod("logic_segment_title")
            if not LST then return end
            hook(LST, "SetMaxSegmentRankInteralWithTitle", function(orig)
                return function(self, widget, modeId, titleArg, seasonArg)
                    local seg, titleId, rankId = self:GetMaxSegementLevelWithZoneAndModeId(modeId)
                    if seg and seg > 0 and widget then
                        widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                        local rating = (tonumber(seg) == 801) and getStarRating() or nil
                        local season = rating or (DataMgr and DataMgr.season_id)
                        local titleNow = self:GetSegmentTitleId(titleArg, titleId, rankId)
                        if not titleNow or tonumber(titleNow) == 0 then
                            if rating and rating > 0 then
                                widget:SetRankInteralWithSegmentTitle(seg, nil, season, 0, rating)
                                return
                            end
                            widget:SetRankInteralBySeason(seg, nil, season)
                            return
                        end
                        widget:SetRankInteralWithSegmentTitle(seg, nil, season, titleNow, rating)
                        return
                    end
                    return orig(self, widget, modeId, titleArg, seasonArg)
                end
            end)
        end)

        -- D) logic_lobby_social.GetSelfProfile — inject rankdata
        pcall(function()
            local Social = safeReq("client.slua.logic.lobby.Left.logic_lobby_social")
            if not Social then return end
            hook(Social, "GetSelfProfile", function(orig)
                return function(...)
                    local prof = orig(...)
                    if prof and tonumber(CFG.SEGMENT) == 801 then
                        -- rankdata (needed for score display)
                        local rating = getStarRating()
                        prof.rankdata = prof.rankdata or {}
                        for z = 1, 6 do
                            prof.rankdata[z] = prof.rankdata[z] or {}
                            for m = 1, 6 do prof.rankdata[z][m] = { rank_rating = rating } end
                        end
                        -- role/segment info
                        applyRankToTable(prof)
                        -- ace imprint
                        prof.ace_show_type        = 2
                        prof.ace_imprint_base_id  = 10
                        prof.ace_imprint_show_id  = 10 + 78
                        prof.ace_imprint_show_cnt = 78
                        prof.ace_imprint_history_cnt = 78
                        prof.peak_ace_imprint_show_cnt = 78
                        -- season year badge
                        local bi = buildBadgeInfo()
                        if bi then
                            pcall(function()
                                local SU = safeReq("client.logic.season_year.util.season_year_util")
                                local yid = (SU and SU.GetSeasonYearId and SU.GetSeasonYearId()) or 1
                                prof.season_year_badge = prof.season_year_badge or {}
                                prof.season_year_badge_info = prof.season_year_badge_info or {}
                                prof.season_year_badge[yid] = bi
                                prof.season_year_badge_info[yid] = bi
                            end)
                        end
                    end
                    return prof
                end
            end)
        end)

        -- E) logic_roleinfo.get_role_basic_info_rsp (main refresh)
        pcall(function()
            local RI = safeReq("client.logic.roleinfo.logic_roleinfo")
            if not RI then return end
            hook(RI, "get_role_basic_info_rsp", function(orig)
                return function(list)
                    if type(list) == "table" and list[1] then
                        applyRankToTable(list[1])
                    end
                    local r = orig(list)
                    -- Patch PersonalBasicInfo too
                    pcall(function()
                        local pbi = RI.PersonalBasicInfo
                        if type(pbi) == "table" then
                            local seg = CFG.SEGMENT
                            pbi.all_segment_info = pbi.all_segment_info or {}
                            for z = 1, 6 do
                                pbi.all_segment_info[z] = {
                                    [1]=seg, [2]=seg, [3]=seg, [4]=seg, [5]=seg, [6]=seg,
                                }
                            end
                            pbi.role_all_zone_segment_max = seg
                        end
                    end)
                    return r
                end
            end)
        end)

        -- F) SeasonHandler.rank_rating
        pcall(function()
            local SH = safeReq("client.network.Protocol.SeasonHandler")
            if SH and tonumber(CFG.SEGMENT) == 801 then
                pcall(function() SH.rank_rating = getStarRating() end)
            end
        end)

        -- G) SeasonYear badge module
        pcall(function()
            local m = safeMod("logic_season_year_badge")
            if not m then return end
            local SYearCfg = safeReq("client.logic.season_year.config.season_year_config")
            local showType = (SYearCfg and SYearCfg.EBadgeShowType and SYearCfg.EBadgeShowType.Show) or 1

            forceReturn(m, "GetBadgeShowType", showType)

            hook(m, "GetCurSeasonYearBadgeInfo", function(orig)
                return function(self, ...)
                    local r = orig(self, ...)
                    if r and next(r) then return r end
                    return buildBadgeInfo()
                end
            end)

            hook(m, "on_get_season_year_badge_info_rsp", function(orig)
                return function(self, ...)
                    -- Apply badge info anyway
                    pcall(function()
                        local bi = buildBadgeInfo()
                        if bi then
                            local SU = safeReq("client.logic.season_year.util.season_year_util")
                            local yid = (SU and SU.GetSeasonYearId and SU.GetSeasonYearId()) or 1
                            m.seasonYearBadgeInfo = m.seasonYearBadgeInfo or {}
                            m.seasonYearBadgeInfo[yid] = bi
                            m.seasonYearBadgeInfo[0] = bi
                            m.loginDays = CFG.BADGE_FINISH
                            m.badgeShowType = showType
                            m.serverBadgeCfg = m.serverBadgeCfg or {}
                            m.serverBadgeCfg[yid] = bi
                        end
                    end)
                    return orig(self, ...)
                end
            end)
        end)

        -- H) season_year_badge_util
        pcall(function()
            local BU = safeReq("client.logic.season_year.util.season_year_badge_util")
            if not BU then return end
            forceReturn(BU, "CheckGotBadge", true)

            local SYearCfg = safeReq("client.logic.season_year.config.season_year_config")
            local showType = (SYearCfg and SYearCfg.EBadgeShowType and SYearCfg.EBadgeShowType.Show) or 1
            forceReturn(BU, "GetBadgeShowType", showType)

            hook(BU, "GetCurSeasonYearBadgeInfo", function(orig)
                return function(...)
                    local r = orig(...)
                    if r and next(r) then return r end
                    return buildBadgeInfo()
                end
            end)
            hook(BU, "GetCurSeasonYearBadgePartCfgInfo", function(orig)
                return function(partType)
                    local r = orig(partType)
                    if r and next(r) then return r end
                    -- Build part cfg on demand
                    local bi = buildBadgeInfo()
                    if bi and bi[partType] then
                        local out = {}
                        for i, v in ipairs(bi[partType]) do
                            out[i] = v
                        end
                        return out
                    end
                    return r
                end
            end)
        end)

        -- I) season_year_util.CheckFunctionIsOpen
        pcall(function()
            local SU = safeReq("client.logic.season_year.util.season_year_util")
            if SU then forceReturn(SU, "CheckFunctionIsOpen", true) end
        end)
    end

    -- ═══════════════════════════════════════════════════════════════
    -- STEP 5: COMPAT WITH EXISTING active1.lua (NTHUY2004)
    -- ═══════════════════════════════════════════════════════════════
    pcall(function()
        _G.NTHUY2004_ProfileCustomEquip = _G.NTHUY2004_ProfileCustomEquip or {}
        -- If active1.lua exposes forceReapplyAll, call it
        if type(_G.NTHUY2004_InstallProfileCustomUnlock) == "function" then
            -- ensure it's already installed (it auto-installs on load)
            _G.NTHUY2004_ProfileCustomEquip._rankSegment = CFG.SEGMENT
            _G.NTHUY2004_ProfileCustomEquip._rankStars   = CFG.STARS
            _G.NTHUY2004_ProfileCustomEquip._badgeFinish = CFG.BADGE_FINISH
        end
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- STEP 6: APPLY + FIRE EVENTS
    -- ═══════════════════════════════════════════════════════════════
    local function applyAll()
        applyRankToRoleData()
        pcall(function()
            if DataMgr and DataMgr.roleData then
                local rd = DataMgr.roleData
                local bi = buildBadgeInfo()
                if bi then
                    local SU = safeReq("client.logic.season_year.util.season_year_util")
                    local yid = (SU and SU.GetSeasonYearId and SU.GetSeasonYearId()) or 1
                    rd.season_year_badge = rd.season_year_badge or {}
                    rd.season_year_badge_info = rd.season_year_badge_info or {}
                    rd.season_year_badge[yid] = bi
                    rd.season_year_badge_info[yid] = bi
                    rd.season_year_badge[0] = bi
                end
            end
        end)
    end

    local function fireRefresh()
        pcall(function()
            if not EventSystem then return end
            if EVENTTYPE_PEAKGAME and EVENTID_PEAKGAME_RATING_NOTIFY then
                fireEvent(EVENTTYPE_PEAKGAME, EVENTID_PEAKGAME_RATING_NOTIFY)
            end
            if EVENTTYPE_SEASON_YEAR and EVENTID_SEASON_YEAR_BADGE_UPDATE then
                fireEvent(EVENTTYPE_SEASON_YEAR, EVENTID_SEASON_YEAR_BADGE_UPDATE)
            end
            if EVENTTYPE_DATA_MGR and EVENTID_ACE_IMPRINT_UPDATE then
                fireEvent(EVENTTYPE_DATA_MGR, EVENTID_ACE_IMPRINT_UPDATE)
            end
            if EVENTTYPE_ROLEINFO and EVENTID_ROLEINFO_UPDATE_ROLEINFO then
                fireEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_ROLEINFO)
            end
            if EVENTTYPE_LEISURE_SEASON and EVENTID_LEISURE_SEASON_SEGMENT_NOTIFY then
                fireEvent(EVENTTYPE_LEISURE_SEASON, EVENTID_LEISURE_SEASON_SEGMENT_NOTIFY)
            end
            -- Trigger rank UI refresh
            pcall(function()
                if UIManager and UIManager.GetUI and UIManager.UI_Config then
                    for _, cfgKey in ipairs({ "roleinfo_main", "roleinfo_segment" }) do
                        local cfg = UIManager.UI_Config[cfgKey]
                        if cfg then
                            local ui = UIManager.GetUI(cfg)
                            if ui then
                                if ui.RefreshUI then pcall(function() ui:RefreshUI() end) end
                                if ui.OnRefresh then pcall(function() ui:OnRefresh() end) end
                                if ui.UpdateUI then pcall(function() ui:UpdateUI() end) end
                                if ui.RefreshAceImprint then pcall(function() ui:RefreshAceImprint() end) end
                            end
                        end
                    end
                end
            end)
        end)
    end

    -- ═══════════════════════════════════════════════════════════════
    -- STEP 7: BOOT + LOOP
    -- ═══════════════════════════════════════════════════════════════
    local installed = false
    local function install()
        if installed then return true end
        installRankUIHooks()
        installed = true
        return true
    end

    local booted = false
    local function boot()
        if booted then return true end
        if not DataMgr or not DataMgr.roleData then return false end
        install()
        applyAll()
        fireRefresh()
        booted = true
        print("[RoxzRankFix v3] Booted — Conqueror 801 / " .. CFG.STARS .. " stars / rating " .. getStarRating() .. " / badge " .. CFG.BADGE_FINISH)
        return true
    end

    local tries = 0
    local function tryBoot()
        tries = tries + 1
        if boot() then return end
        if tries >= 60 then
            print("[RoxzRankFix v3] Boot FAILED after " .. tries .. " tries")
            return
        end
        pcall(function()
            local t = require("common.time_ticker")
            if t and t.AddTimerOnce then t.AddTimerOnce(1.0, tryBoot) end
        end)
    end

    pcall(function()
        local t = require("common.time_ticker")
        if t and t.AddTimerOnce then t.AddTimerOnce(0.5, tryBoot) else tryBoot() end
    end)

    -- Silent periodic re-apply (lobby only) — does NOT spam popups
    pcall(function()
        local t = require("common.time_ticker")
        if t and t.AddTimerLoop then
            t.AddTimerLoop(0, function()
                pcall(function()
                    if not booted then return end
                    if GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus() then return end
                    applyAll()
                end)
            end, -1, 10.0)
        end
    end)

    -- Event-driven refresh (lobby entry, roleinfo open)
    pcall(function()
        if not EventSystem then return end
        local function onRefresh()
            pcall(function()
                if not booted then return end
                applyAll()
                fireRefresh()
            end)
        end
        if EVENTTYPE_LOBBY and EVENTID_SHOW_LOBBY then
            EventSystem:registEvent(EVENTTYPE_LOBBY, EVENTID_SHOW_LOBBY, onRefresh)
        end
        if EVENTTYPE_ROLEINFO and EVENTID_ROLEINFO_UPDATE_ROLEINFO then
            EventSystem:registEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_ROLEINFO, onRefresh)
        end
    end)

    _G.RoxzRankFix = {
        Apply     = applyAll,
        Refresh   = fireRefresh,
        Config    = CFG,
        GetRating = getStarRating,
    }

    print("[RoxzRankFix v3] Loaded — will show Conqueror 801 + " .. getStarRating() .. " score + Journey badge " .. CFG.BADGE_FINISH)
end)
