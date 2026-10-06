-- ═══════════════════════════════════════════════════════════════════
-- RoxzProfile Full Unlock v1.0
-- Auto-boots. No console commands. Self-contained.
-- Unlocks: Avatar, Frame, Nickname, Chat, TeamSkin, CarteFrame,
--          Alias(Title), NameFrame(Brand), RoleInfoBG, Opening,
--          SocialCardBG + Rank(Conqueror 801 + 91 stars) +
--          Journey Badge 17 + Season Year Badge + Collection Max
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    if _G._ROXZ_PROFILE_V1 then return end
    _G._ROXZ_PROFILE_V1 = true

    -- ═════════ CONFIG ═════════
    local CFG = {
        -- Cosmetics
        AVATAR              = 30396,
        AVATAR_BOX          = 2002901,
        NICKNAME_SKIN       = 61910001,
        CHAT_BUBBLE         = 61100036,
        TEAM_SKIN           = 61300005,
        CARTE_FRAME         = 61100036,
        ALIAS_ID            = 2494116,     -- 珍藏王者
        NAME_FRAME_ID       = 1511250117,  -- brand/nameframe
        ROLE_INFO_BG        = 61510001,
        OPENING             = 61520001,
        SOCIAL_CARD_BG      = 61520001,

        -- Rank
        RANK_SEGMENT        = 801,         -- Conqueror
        RANK_STARS          = 91,          -- 91 stars for star rating
        HISTORY_SEGMENT     = 801,
        PEAK_CURRENT_SEG    = 1541,
        PEAK_HISTORY_SEG    = 1301,
        PEAK_RATING         = 8000,

        -- Badges
        JOURNEY_BADGE_LEVEL = 17,
        JOURNEY_VISUAL_LV   = 3,
        JOURNEY_GLOW_TASKS  = 3,
        JOURNEY_GLOW_RANKS  = {701, 702, 703, 801},

        -- Collection
        COLLECT_SCORE       = 999999999,
        COLLECT_LEVEL       = 100,
        SEASON_LEVEL        = 100,

        -- Extra
        PLAYED_YEARS        = 10,
        SEASON_RATING       = 8500,
        SEASON_RANK         = "44",
        ACHIEVE_POINTS      = 9500,
    }

    -- ═════════ HELPERS ═════════
    local function safeReq(path)
        local m = package.loaded and package.loaded[path]
        if m then return m end
        local ok, r = pcall(require, path)
        return (ok and r) or nil
    end

    local function safeMod(key)
        local ok, m = pcall(function()
            if ModuleManager and ModuleManager.GetModule and ModuleManager.LobbyModuleConfig then
                return ModuleManager.GetModule(ModuleManager.LobbyModuleConfig[key])
            end
        end)
        return (ok and m) or nil
    end

    local function fireEvent(...)
    local args = { n = select("#", ...), ... }
    if not (EventSystem and EventSystem.postEvent) then return end
    pcall(function()
        EventSystem:postEvent(table.unpack(args, 1, args.n))
    end)
end

    local _pfx = "__roxz_"
    local function wrapStatic(tbl, name, wrapper)
        if type(tbl) ~= "table" then return false end
        if type(tbl[name]) ~= "function" then return false end
        local key = _pfx .. name
        if not rawget(tbl, key) then rawset(tbl, key, tbl[name]) end
        tbl[name] = wrapper(rawget(tbl, key))
        return true
    end

    local function unlockList(list)
        if type(list) ~= "table" then return list end
        for _, d in ipairs(list) do
            if type(d) == "table" then
                d.bIsLock = false
                d.bLock   = false
                if type(d.SubList) == "table" then
                    for _, s in pairs(d.SubList) do
                        if type(s) == "table" then
                            s.bIsLock = false
                            s.bLock   = false
                        end
                    end
                end
            end
        end
        return list
    end

    local function getUID()
        local uid
        pcall(function()
            if DataMgr and DataMgr.roleData then
                uid = tonumber(DataMgr.roleData.uid)
            end
        end)
        return uid
    end

    -- ═════════ FILL LISTS ═════════
    local function fillHeadportrait(list)
        list = list or {}
        pcall(function()
            local cfg = CDataTable.GetTable("Headportrait")
            for k, row in pairs(cfg or {}) do
                local id = tostring(row.ID or row.Id or k)
                list[id] = 1
            end
        end)
        return list
    end

    local function fillAvatarFrame(list)
        list = list or {}
        pcall(function()
            local cfg = CDataTable.GetTable("AvatarFrame")
            for k, row in pairs(cfg or {}) do
                local id = tonumber(row.ID or row.Id or k)
                if id and id > 0 then list[id] = { expire_time = 0 } end
            end
        end)
        return list
    end

    local function fillNicknameSkin(skins)
        skins = skins or {}
        pcall(function()
            local cfg = CDataTable.GetTable("NicknameEffectCfg")
            for k, row in pairs(cfg or {}) do
                local id = tonumber(row.ID or k)
                if id then skins[id] = { expire_ts = 0 } end
            end
        end)
        return skins
    end

    local function fillChatBubble(bubbles)
        bubbles = bubbles or {}
        pcall(function()
            local cfg = CDataTable.GetTable("ChatEffectCfg")
            for k, row in pairs(cfg or {}) do
                local id = tonumber(row.ID or k)
                if id then bubbles[id] = { expire_ts = 0 } end
            end
        end)
        return bubbles
    end

    local function fillTeamSkin(list)
        list = list or {}
        pcall(function()
            local cfg = CDataTable.GetTable("TeamUpPopFrame")
            for k, row in pairs(cfg or {}) do
                local id = tonumber(row.ID or k)
                if id and not list[id] then list[id] = { expire_time = 0 } end
            end
        end)
        return list
    end

    local function fillCarteFrame(active)
        active = active or {}
        pcall(function()
            local cfg = CDataTable.GetTable("CarteFrameConfig")
            for k, row in pairs(cfg or {}) do
                local id = tonumber(row.SkinID or row.ID or k)
                if id then active[id] = { expire_ts = 0 } end
            end
        end)
        return active
    end

    local function fillAliasList(list)
        list = list or {}
        pcall(function()
            local AS   = safeReq("client.slua.logic.roleInfo.logic_roleinfo_title")
            local ENUM = (AS and AS.enum_Alias_State_Type) or { have = 1, use = 2 }
            local TUtil = safeReq("client.common.time_util")
            local now = (TUtil and TUtil.GetServerTimeInSec and TUtil.GetServerTimeInSec()) or 0
            local cfg = CDataTable.GetTable("AliasCfg")
            for k, row in pairs(cfg or {}) do
                local id = tonumber(row.ID or k)
                if id and not list[id] then
                    list[id] = {
                        state = ENUM.have, receive_time = now, expire_ts = 0,
                        rank = 0, ext_info = "", rank_id = 0,
                        title = (row and row.AliasName) or "",
                        nation = "", have_used = 0,
                    }
                end
            end
        end)
        return list
    end

    local function unlockNameFrameMap()
        pcall(function()
            if not DataMgr or not DataMgr.roleData then return end
            DataMgr.roleData.nameFrameData = DataMgr.roleData.nameFrameData or {}
            local cfg = CDataTable.GetTable("NameFrame")
            for k, row in pairs(cfg or {}) do
                local id = tonumber(row.ID or row.Id or k)
                if id and id > 0 then
                    DataMgr.roleData.nameFrameData[id] = { expire_ts = 0, is_used = 0 }
                end
            end
        end)
    end

    -- ═════════ APPLY FUNCTIONS ═════════
    local function applyRoleData()
        if not DataMgr or not DataMgr.roleData then return end
        local rd = DataMgr.roleData
        pcall(function()
            rd.headIconUrl = tostring(CFG.AVATAR)
            rd.pic_url     = tostring(CFG.AVATAR)
            rd.picUrl      = tostring(CFG.AVATAR)
            rd.pic_url_check_open = true
            rd.cur_avatar_box_id = CFG.AVATAR_BOX
            rd.friend_nickname_skin = CFG.NICKNAME_SKIN
            rd.chat_bubble = CFG.CHAT_BUBBLE
            rd.cur_team_notify_skin_id = CFG.TEAM_SKIN
        end)
    end

    local function applyAvatar()
        pcall(function()
            local RAS = safeReq("client.slua.logic.roleInfo.logic_roleInfo_Avatar")
            if RAS then
                RAS.HeadportraitList = fillHeadportrait(RAS.HeadportraitList or {})
                RAS.HeadportraitList[tostring(CFG.AVATAR)] = 1
            end
            if DataMgr and DataMgr.UpdateHeadIconUrl then
                pcall(function() DataMgr.UpdateHeadIconUrl(CFG.AVATAR) end)
            end
        end)
    end

    local function applyFrame()
        pcall(function()
            local RAF = safeReq("client.slua.logic.roleInfo.logic_RoleInfoAvatarFrame")
            if RAF then
                RAF.AvatarFrameList = fillAvatarFrame(RAF.AvatarFrameList or {})
                RAF.AvatarFrameList[CFG.AVATAR_BOX] = { expire_time = 0 }
                if RAF.UpdateCurAvatarBoxID then
                    pcall(function() RAF.UpdateCurAvatarBoxID(CFG.AVATAR_BOX) end)
                end
            end
            if DataMgr and DataMgr.UpdateAvatarBoxId then
                pcall(function() DataMgr.UpdateAvatarBoxId(CFG.AVATAR_BOX) end)
            end
        end)
    end

    local function applyNickname()
        pcall(function()
            local m = safeMod("logic_roleInfo_nicknameframe")
            if m then
                m.unlockData = m.unlockData or {}
                m.unlockData[CFG.NICKNAME_SKIN] = { expire_ts = 0 }
                if m.ProcChangeRsp then
                    pcall(function() m:ProcChangeRsp(CFG.NICKNAME_SKIN) end)
                end
            end
        end)
    end

    local function applyChat()
        pcall(function()
            local m = safeMod("logic_roleInfo_chatframe")
            if m then
                m.unlockData = m.unlockData or {}
                m.unlockData[CFG.CHAT_BUBBLE] = { expire_ts = 0 }
                if m.ProcChangeRsp then
                    pcall(function() m:ProcChangeRsp(CFG.CHAT_BUBBLE) end)
                end
            end
        end)
    end

    local function applyTeamSkin()
        pcall(function()
            local m = safeMod("logic_roleInfo_TeamUpFrame")
            if m and m.on_change_team_notify_skin_rsp then
                pcall(function() m:on_change_team_notify_skin_rsp(0, CFG.TEAM_SKIN) end)
            end
        end)
    end

    local function applyCarteFrame()
        pcall(function()
            local m = safeMod("logic_roleinfo_carte_frame")
            if m then
                if m.InitCarteFrameMap then pcall(function() m:InitCarteFrameMap() end) end
                m.CarteFrameMap = m.CarteFrameMap or {}
                for k in pairs(m.CarteFrameMap) do
                    m.CarteFrameMap[k].bLock = false
                    m.CarteFrameMap[k].expire_ts = 0
                end
                if m.equip_carte_frame_rsp then
                    pcall(function() m:equip_carte_frame_rsp(0, CFG.CARTE_FRAME, true) end)
                end
            end
        end)
    end

    local function applyAlias()
        pcall(function()
            if not DataMgr or not DataMgr.roleData then return end
            local rd = DataMgr.roleData
            rd.alias = rd.alias or {}
            rd.alias.id = CFG.ALIAS_ID

            local title = ""
            local cfg = CDataTable.GetTableData("AliasCfg", CFG.ALIAS_ID)
            if cfg and cfg.AliasName then title = cfg.AliasName end
            pcall(function()
                if FuncUtil and FuncUtil.Gen_title then
                    title = FuncUtil.Gen_title(CFG.ALIAS_ID, 0, {}, 0) or title
                end
            end)
            rd.alias.title = title

            local AS = safeReq("client.slua.logic.roleInfo.logic_roleinfo_title")
            if AS then
                local ENUM = AS.enum_Alias_State_Type or { have = 1, use = 2 }
                AS.alias_list_info = AS.alias_list_info or {}
                for k, v in pairs(AS.alias_list_info) do
                    if type(v) == "table" then
                        v.state = (tonumber(k) == CFG.ALIAS_ID) and ENUM.use or ENUM.have
                    end
                end
                AS.alias_list_info[CFG.ALIAS_ID] = AS.alias_list_info[CFG.ALIAS_ID] or {
                    state = ENUM.use, receive_time = 0, expire_ts = 0,
                    rank = 0, ext_info = {}, rank_id = 0,
                    title = title, nation = "", have_used = 1,
                }
                AS.alias_list_info[CFG.ALIAS_ID].state = ENUM.use
                AS.alias_list_info[CFG.ALIAS_ID].title = title
            end
        end)
    end

    local function applyNameFrame()
        pcall(function()
            unlockNameFrameMap()
            if DataMgr and DataMgr.roleData and DataMgr.roleData.nameFrameData then
                for k, v in pairs(DataMgr.roleData.nameFrameData) do
                    if type(v) == "table" then v.is_used = 0 end
                end
                DataMgr.roleData.nameFrameData[CFG.NAME_FRAME_ID] = { is_used = 1, expire_ts = 0 }
            end
            local m = safeReq("client.slua.logic.person_space.logic_roleinfo_nameframe")
            if m then m.nUsedID = CFG.NAME_FRAME_ID end
        end)
    end

    local function applyRoleInfoBg()
        pcall(function()
            local m = safeMod("logic_roleInfo_background")
            if m and m.on_notify_social_info_bg then
                local key = (ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.RoleInfoBG) or 5
                pcall(function()
                    m:on_notify_social_info_bg({ [key] = CFG.ROLE_INFO_BG })
                end)
            end
        end)
    end

    local function applyOpening()
        pcall(function()
            local m = safeMod("logic_roleInfo_opening")
            if m and m.on_notify_social_info_bg then
                local key = (ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.PersonalOpening) or 6
                pcall(function()
                    m:on_notify_social_info_bg({ [key] = CFG.OPENING })
                end)
            end
        end)
    end

    local function applySocialCardBg()
        pcall(function()
            local m = safeMod("logic_social_card_bg")
            if m then
                m.CurrentSocialCardBGID = CFG.SOCIAL_CARD_BG
                if m.on_notify_social_card_floor then
                    pcall(function() m:on_notify_social_card_floor(CFG.SOCIAL_CARD_BG) end)
                end
            end
        end)
    end

    -- ═════════ RANK ═════════
    local function getStarRating()
        local stars = tonumber(CFG.RANK_STARS) or 0
        if stars > 0 then return 4200 + (stars - 1) * 100 end
        return 4200
    end

    local function resolveConquerorTitleId()
        local bestId, bestPri = 0, -1
        pcall(function()
            local cfg = CDataTable.GetTable("SegmentTitleConfig")
            for id, row in pairs(cfg or {}) do
                if row and not row.IfDefaultTitle then
                    local pri = tonumber(row.Priority) or 0
                    local tid = tonumber(row.ID or row.Id or id)
                    if tid and pri > bestPri then
                        bestPri = pri
                        bestId  = tid
                    end
                end
            end
        end)
        return bestId
    end

    local function applyRank()
        pcall(function()
            if not DataMgr or not DataMgr.roleData then return end
            local rd = DataMgr.roleData
            local seg = CFG.RANK_SEGMENT

            rd.segment = rd.segment or {}
            rd.segment.solo       = seg
            rd.segment.double     = seg
            rd.segment.team       = seg
            rd.segment.fpp_solo   = seg
            rd.segment.fpp_double = seg
            rd.segment.fpp_team   = seg

            -- allzoneSegment for 6 zones x 6 modes
            rd.allzoneSegment = rd.allzoneSegment or {}
            for z = 1, 6 do
                rd.allzoneSegment[z] = rd.allzoneSegment[z] or {}
                for m = 1, 6 do
                    rd.allzoneSegment[z][m] = seg
                end
            end

            -- hsegment_title_det
            local titleId = resolveConquerorTitleId()
            if titleId and titleId > 0 then
                rd.allzoneSegmentTitle = rd.allzoneSegmentTitle or {}
                for z = 1, 6 do
                    rd.allzoneSegmentTitle[z] = rd.allzoneSegmentTitle[z] or {}
                    for m = 1, 6 do
                        rd.allzoneSegmentTitle[z][m] = { id = titleId }
                    end
                end
            end

            -- peak game
            pcall(function()
                local PeakCfg = safeReq("client.logic.PeakGame.PeakGameConfig")
                if PeakCfg then
                    local squad = PeakCfg.BattleType.Squad
                    local list = {}
                    for season = 1, 6 do
                        list[season] = {
                            [squad] = {
                                rating          = CFG.PEAK_RATING,
                                segment_id      = CFG.PEAK_CURRENT_SEG,
                                max_segment_id  = CFG.PEAK_CURRENT_SEG,
                            }
                        }
                    end
                    rd.peakgame_segment_info = {
                        curr_season_id = (DataMgr.season_id or 1),
                        list = list,
                    }
                    rd.peakgame_history_max_segment = CFG.PEAK_HISTORY_SEG
                end
            end)

            DataMgr.maxSegmentSquad = { zoneid = 1, SegmentLevel = seg }
            DataMgr.isSeasonStarOpen = true
            rd.is_season_star_open = true

            -- register time
            pcall(function()
                local TUtil = safeReq("client.common.time_util")
                local now = (TUtil and TUtil.GetServerTimeInSec and TUtil.GetServerTimeInSec()) or os.time()
                DataMgr.registertime = now - (CFG.PLAYED_YEARS * 365 * 86400)
            end)

            -- SeasonHandler rating
            pcall(function()
                local SH = safeReq("client.network.Protocol.SeasonHandler")
                if SH and tonumber(seg) == 801 then
                    SH.rank_rating = getStarRating()
                end
            end)

            -- RoleInfo module stats
            pcall(function()
                local RoleInfo = safeReq("client.logic.roleinfo.logic_roleinfo")
                if RoleInfo then
                    local pbi = RoleInfo.PersonalBasicInfo
                    if type(pbi) == "table" then
                        pbi.all_segment_info = pbi.all_segment_info or {}
                        for z = 1, 6 do
                            pbi.all_segment_info[z] = {
                                [1]=seg, [2]=seg, [3]=seg, [4]=seg, [5]=seg, [6]=seg,
                            }
                        end
                        pbi.role_all_zone_segment_max = seg
                        local tid = resolveConquerorTitleId()
                        if tid and tid > 0 then
                            pbi.hsegment_title_det = pbi.hsegment_title_det or {}
                            for z = 1, 6 do
                                pbi.hsegment_title_det[z] = pbi.hsegment_title_det[z] or {}
                                for m = 1, 6 do
                                    pbi.hsegment_title_det[z][m] = { id = tid }
                                end
                            end
                        end
                    end

                    -- bottom profile stats
                    local uid = getUID()
                    if uid then
                        if RoleInfo.CurrSeasonTPPTotalScore then
                            for z = 1, 6 do
                                RoleInfo.CurrSeasonTPPTotalScore[z] = CFG.SEASON_RATING
                                RoleInfo.CurrSeasonFPPTotalScore[z] = CFG.SEASON_RATING
                                RoleInfo.CurrSeasonTPPTotalRank[z]  = CFG.SEASON_RANK
                                RoleInfo.CurrSeasonFPPTotalRank[z]  = CFG.SEASON_RANK
                            end
                        end
                        local AH = safeReq("client.network.Protocol.AchieveHandler")
                        if AH and AH.resSummaryTb then
                            AH.resSummaryTb[uid] = AH.resSummaryTb[uid] or {}
                            AH.resSummaryTb[uid].achieve_score = CFG.ACHIEVE_POINTS
                            AH.resSummaryTb[uid].uid = uid
                        end
                    end
                end
            end)
        end)
    end

    -- ═════════ BADGES ═════════
    local function applyBadges()
        pcall(function()
            local m = safeMod("logic_season_year_badge")
            if not m then return end

            -- Open check always true
            if type(m.CheckFunctionIsOpen) == "function" then
                wrapStatic(m, "CheckFunctionIsOpen", function() return function() return true end end)
            end

            -- Force show type
            if type(m.GetBadgeShowType) == "function" then
                local SYearCfg = safeReq("client.logic.season_year.config.season_year_config")
                local showType = (SYearCfg and SYearCfg.EBadgeShowType and SYearCfg.EBadgeShowType.Show) or 1
                wrapStatic(m, "GetBadgeShowType", function() return function() return showType end end)
            end

            -- Force fake badge info
            if type(m.GetCurSeasonYearBadgeInfo) == "function" then
                wrapStatic(m, "GetCurSeasonYearBadgeInfo", function(orig)
                    return function(self, ...)
                        local r = orig(self, ...)
                        if r and next(r) then return r end
                        local SYearCfg = safeReq("client.logic.season_year.config.season_year_config")
                        if SYearCfg and SYearCfg.EBadgePartType then
                            local BP = SYearCfg.EBadgePartType
                            local T  = SYearCfg.ERankTaskStatus and SYearCfg.ERankTaskStatus.Completed or 1
                            local L  = CFG.JOURNEY_BADGE_LEVEL
                            local VL = CFG.JOURNEY_VISUAL_LV
                            local GLOW = CFG.JOURNEY_GLOW_TASKS
                            local ranks = CFG.JOURNEY_GLOW_RANKS
                            local crownMax = SYearCfg.CrownTaskMaxCount or 10
                            return {
                                [BP.Gem]   = { { finish_count = L, status = T } },
                                [BP.Base]  = { { finish_count = L, status = T } },
                                [BP.Glow]  = (function()
                                    local t = {}
                                    for i = 1, VL do
                                        t[i] = { finish_count = 1, status = T, trigger_value = ranks[i] or 801 }
                                    end
                                    return t
                                end)(),
                                [BP.Crown] = (function()
                                    local t = {}
                                    for i = 1, crownMax do
                                        t[i] = { finish_count = math.min(GLOW, L), status = T }
                                    end
                                    return t
                                end)(),
                            }
                        end
                    end
                end)
            end

            -- Direct assign for current season id
            pcall(function()
                local SYearUtil = safeReq("client.logic.season_year.util.season_year_util")
                local yearId = (SYearUtil and SYearUtil.GetSeasonYearId and SYearUtil.GetSeasonYearId()) or 1
                local SYearCfg = safeReq("client.logic.season_year.config.season_year_config")
                if SYearCfg and SYearCfg.EBadgePartType then
                    local BP = SYearCfg.EBadgePartType
                    local T  = SYearCfg.ERankTaskStatus and SYearCfg.ERankTaskStatus.Completed or 1
                    local L  = CFG.JOURNEY_BADGE_LEVEL
                    local crownMax = SYearCfg.CrownTaskMaxCount or 10
                    local info = {
                        [BP.Gem]   = { { finish_count = L, status = T } },
                        [BP.Base]  = { { finish_count = L, status = T } },
                        [BP.Glow]  = { { finish_count = 1, status = T, trigger_value = 801 } },
                        [BP.Crown] = (function()
                            local t = {}
                            for i = 1, crownMax do
                                t[i] = { finish_count = math.min(CFG.JOURNEY_GLOW_TASKS, L), status = T }
                            end
                            return t
                        end)(),
                    }
                    m.seasonYearBadgeInfo = m.seasonYearBadgeInfo or {}
                    m.seasonYearBadgeInfo[yearId] = info
                    m.loginDays = CFG.JOURNEY_BADGE_LEVEL
                    m.badgeShowType = SYearCfg.EBadgeShowType and SYearCfg.EBadgeShowType.Show or 1
                    m.serverBadgeCfg = m.serverBadgeCfg or {}
                    m.serverBadgeCfg[yearId] = info
                    m.seasonYearTaskInfo = m.seasonYearTaskInfo or {}
                    m.seasonYearTaskInfo[1] = {
                        task_id = 1, status = T, finish_count = L,
                    }
                    m.serverYearTaskCfg = m.serverYearTaskCfg or {}
                    m.serverYearTaskCfg[yearId] = { task_cfgs = { { task_desc_id = 0 } } }
                end
            end)

            -- Secondary: logic via util
            pcall(function()
                local BU = safeReq("client.logic.season_year.util.season_year_badge_util")
                if BU then
                    if type(BU.CheckGotBadge) == "function" then
                        wrapStatic(BU, "CheckGotBadge", function() return function() return true end end)
                    end
                    if type(BU.GetBadgeShowType) == "function" then
                        local SYearCfg = safeReq("client.logic.season_year.config.season_year_config")
                        local showType = (SYearCfg and SYearCfg.EBadgeShowType and SYearCfg.EBadgeShowType.Show) or 1
                        wrapStatic(BU, "GetBadgeShowType", function() return function() return showType end end)
                    end
                end
            end)
        end)
    end

    -- ═════════ COLLECT ═════════
    local function applyCollect()
        pcall(function()
            local m = safeMod("collect_module")
            if m then
                if type(m.GetLevelDataByScore) == "function" then
                    wrapStatic(m, "GetLevelDataByScore", function()
                        return function() return CFG.COLLECT_LEVEL, "", 100 end
                    end)
                end
                if type(m.GetSeasonLevelByScore) == "function" then
                    wrapStatic(m, "GetSeasonLevelByScore", function()
                        return function() return CFG.COLLECT_LEVEL, true, "" end
                    end)
                end
                if type(m.GetCollectScoreByCollectData) == "function" then
                    wrapStatic(m, "GetCollectScoreByCollectData", function()
                        return function() return CFG.COLLECT_SCORE, CFG.COLLECT_SCORE end
                    end)
                end
                if type(m.GetCollectScoreByProfile) == "function" then
                    wrapStatic(m, "GetCollectScoreByProfile", function()
                        return function() return CFG.COLLECT_SCORE, CFG.COLLECT_SCORE end
                    end)
                end
                if type(m.GetCollectTotalScore) == "function" then
                    wrapStatic(m, "GetCollectTotalScore", function()
                        return function() return CFG.COLLECT_SCORE, CFG.COLLECT_LEVEL end
                    end)
                end
                if type(m.GetLevelByScore) == "function" then
                    wrapStatic(m, "GetLevelByScore", function()
                        return function() return CFG.COLLECT_LEVEL, 100, CFG.COLLECT_LEVEL, 0, 0 end
                    end)
                end
                if type(m.collect_data) == "table" then
                    m.collect_data.total_score = CFG.COLLECT_SCORE
                    m.collect_data.cur_season_collect_score = CFG.COLLECT_SCORE
                    m.collect_data.season_score = m.collect_data.season_score or {}
                    if DataMgr and DataMgr.season_id then
                        m.collect_data.season_score[DataMgr.season_id] = CFG.COLLECT_SCORE
                    end
                end
            end

            if DataMgr and DataMgr.roleData then
                DataMgr.roleData.brief_collect_data = DataMgr.roleData.brief_collect_data or {}
                DataMgr.roleData.brief_collect_data.total_score = CFG.COLLECT_SCORE
                DataMgr.roleData.brief_collect_data.cur_season_collect_score = CFG.COLLECT_SCORE
            end
        end)
    end

    -- ═════════ HOOKS INSTALL ═════════
    local function installAvatarHooks()
        pcall(function()
            local RAS = safeReq("client.slua.logic.roleInfo.logic_roleInfo_Avatar")
            if not RAS then return end
            wrapStatic(RAS, "HasAvatar",          function() return function() return true end end)
            wrapStatic(RAS, "HasOwnHeadPortrait", function() return function() return true end end)
            wrapStatic(RAS, "get_user_avatar_list_rsp", function(orig)
                return function(ok, list, url)
                    if ok ~= 0 then ok = 0 end
                    list = fillHeadportrait(list or {})
                    RAS.HeadportraitList = fillHeadportrait(RAS.HeadportraitList or {})
                    return orig(ok, list, CFG.AVATAR)
                end
            end)
            wrapStatic(RAS, "change_user_avatar_rsp", function(orig)
                return function(ok, url, endtime)
                    if ok ~= 0 then ok = 0 end
                    return orig(ok, CFG.AVATAR, 1)
                end
            end)
        end)
    end

    local function installFrameHooks()
        pcall(function()
            local RAF = safeReq("client.slua.logic.roleInfo.logic_RoleInfoAvatarFrame")
            if not RAF then return end
            wrapStatic(RAF, "HasAvatarFrame",     function() return function() return true end end)
            wrapStatic(RAF, "HasAvatarFrameCond", function() return function() return true end end)
            wrapStatic(RAF, "get_avatar_box_list_rsp", function(orig)
                return function(ok, list, boxId)
                    if ok ~= 0 then ok = 0 end
                    list  = fillAvatarFrame(list or {})
                    boxId = CFG.AVATAR_BOX
                    RAF.AvatarFrameList = fillAvatarFrame(RAF.AvatarFrameList or {})
                    if RAF.UpdateCurAvatarBoxID then
                        pcall(function() RAF.UpdateCurAvatarBoxID(boxId) end)
                    end
                    return orig(ok, list, boxId)
                end
            end)
            wrapStatic(RAF, "change_avatar_box_rsp", function(orig)
                return function(ok, id)
                    if ok ~= 0 then ok = 0 end
                    if DataMgr and DataMgr.UpdateAvatarBoxId then
                        pcall(function() DataMgr.UpdateAvatarBoxId(CFG.AVATAR_BOX) end)
                    end
                    return orig(ok, CFG.AVATAR_BOX)
                end
            end)
        end)
        -- WardRobe avatar box handler
        pcall(function()
            local WRH = safeReq("client.network.Protocol.WardRobeHandler")
            if not WRH then return end
            wrapStatic(WRH, "on_get_avatar_box_list_rsp", function(orig)
                return function(ok, list, boxId)
                    if ok ~= 0 then ok = 0 end
                    return orig(ok, fillAvatarFrame(list or {}), CFG.AVATAR_BOX)
                end
            end)
        end)
    end

    local function installNicknameHooks()
        pcall(function()
            local m = safeMod("logic_roleInfo_nicknameframe")
            if not m then return end
            wrapStatic(m, "HasFrame", function() return function() return true end end)
            wrapStatic(m, "IsLocked", function() return function() return false end end)
            wrapStatic(m, "ProcNicknameListRsp", function(orig)
                return function(self, data, cfg)
                    data = data or {}
                    data.skins = fillNicknameSkin(data.skins or {})
                    data.equip = CFG.NICKNAME_SKIN
                    local r = orig(self, data, cfg)
                    applyNickname()
                    return r
                end
            end)
            wrapStatic(m, "ProcChangeRsp", function(orig)
                return function(self, id)
                    if self.unlockData then
                        self.unlockData[id] = { expire_ts = 0 }
                    end
                    return orig(self, id)
                end
            end)
        end)
    end

    local function installChatHooks()
        pcall(function()
            local m = safeMod("logic_roleInfo_chatframe")
            if not m then return end
            wrapStatic(m, "HasChatBubble", function() return function() return true end end)
            wrapStatic(m, "IsLocked",      function() return function() return false end end)
            wrapStatic(m, "ProcChatListRsp", function(orig)
                return function(self, data, cfg)
                    data = data or {}
                    data.bubbles = fillChatBubble(data.bubbles or {})
                    data.equip = CFG.CHAT_BUBBLE
                    local r = orig(self, data, cfg)
                    applyChat()
                    return r
                end
            end)
            wrapStatic(m, "ProcChangeRsp", function(orig)
                return function(self, id)
                    if self.unlockData then
                        self.unlockData[id] = { expire_ts = 0 }
                    end
                    return orig(self, id)
                end
            end)
        end)
    end

    local function installTeamSkinHooks()
        pcall(function()
            local m = safeMod("logic_roleInfo_TeamUpFrame")
            if not m then return end
            wrapStatic(m, "HasSkin",  function() return function() return true end end)
            wrapStatic(m, "IsLocked", function() return function() return false end end)
            wrapStatic(m, "on_get_team_notify_skin_list_rsp", function(orig)
                return function(self, ok, list, curSkin)
                    if ok ~= 0 then ok = 0 end
                    list    = fillTeamSkin(list)
                    curSkin = CFG.TEAM_SKIN
                    local r = orig(self, ok, list, curSkin)
                    pcall(function() unlockList(self.showDataList) end)
                    applyTeamSkin()
                    return r
                end
            end)
            wrapStatic(m, "on_change_team_notify_skin_rsp", function(orig)
                return function(self, ok, id)
                    if ok ~= 0 then ok = 0 end
                    return orig(self, ok, CFG.TEAM_SKIN)
                end
            end)
        end)
    end

    local function installCarteFrameHooks()
        pcall(function()
            local m = safeMod("logic_roleinfo_carte_frame")
            if not m then return end
            wrapStatic(m, "HasCarteFrame",       function() return function() return true  end end)
            wrapStatic(m, "IsHaveCarteFrame",    function() return function() return true  end end)
            wrapStatic(m, "CheckFrameTimeValid", function() return function() return true  end end)
            wrapStatic(m, "get_carte_frame_list_rsp", function(orig)
                return function(self, ok, list, cur)
                    if ok ~= 0 then ok = 0 end
                    if self.InitCarteFrameMap then pcall(function() self:InitCarteFrameMap() end) end
                    list = fillCarteFrame(list)
                    for k in pairs(self.CarteFrameMap or {}) do
                        self.CarteFrameMap[k].bLock     = false
                        self.CarteFrameMap[k].expire_ts = 0
                    end
                    local r = orig(self, ok, list, CFG.CARTE_FRAME)
                    applyCarteFrame()
                    return r
                end
            end)
            wrapStatic(m, "equip_carte_frame_rsp", function(orig)
                return function(self, ok, id, eq)
                    if ok ~= 0 then ok = 0 end
                    return orig(self, ok, CFG.CARTE_FRAME, eq)
                end
            end)
            wrapStatic(m, "GetCurrentCrateFrameBGID", function()
                return function() return CFG.CARTE_FRAME end
            end)
        end)
    end

    local function installAliasHooks()
        pcall(function()
            local AS = safeReq("client.slua.logic.roleInfo.logic_roleinfo_title")
            if not AS then return end
            wrapStatic(AS, "alias_list_res", function(orig)
                return function(res, list, red, alias)
                    if res ~= 0 then res = 0 end
                    list  = fillAliasList(list)
                    alias = alias or {}
                    alias.id = CFG.ALIAS_ID
                    local r = orig(res, list, red, alias)
                    applyAlias()
                    return r
                end
            end)
            wrapStatic(AS, "change_alias_req", function(orig)
                return function(id, state)
                    applyAlias()
                    pcall(function() AS.change_alias_rsp(0, CFG.ALIAS_ID, 0) end)
                end
            end)
        end)
        pcall(function()
            local CH = safeReq("client.network.Protocol.CharacterHandler")
            if not CH then return end
            wrapStatic(CH, "send_change_alias_req", function(orig)
                return function(id, state)
                    applyAlias()
                    local AS = safeReq("client.slua.logic.roleInfo.logic_roleinfo_title")
                    if AS and AS.change_alias_rsp then
                        pcall(function() AS.change_alias_rsp(0, CFG.ALIAS_ID, 0) end)
                    end
                end
            end)
        end)
    end

    local function installNameFrameHooks()
        pcall(function()
            local m = safeReq("client.slua.logic.person_space.logic_roleinfo_nameframe")
            if not m then return end
            unlockNameFrameMap()
            wrapStatic(m, "IsValidNameFrame", function() return function() return true end end)
            wrapStatic(m, "use_brand", function(orig)
                return function(id)
                    applyNameFrame()
                    if m.use_brand_rsp then
                        pcall(function() m.use_brand_rsp(0, CFG.NAME_FRAME_ID) end)
                    end
                end
            end)
            wrapStatic(m, "use_brand_rsp", function(orig)
                return function(res, id)
                    if res ~= 0 then res = 0 end
                    return orig(res, CFG.NAME_FRAME_ID)
                end
            end)
        end)
        pcall(function()
            if DataMgr then
                wrapStatic(DataMgr, "InitRoleData", function(orig)
                    return function(rd)
                        if type(rd) == "table" then
                            rd.brand = rd.brand or {}
                            for k, v in pairs(rd.brand) do
                                if type(v) == "table" then v.is_used = 0 end
                            end
                            rd.brand[CFG.NAME_FRAME_ID] = { is_used = 1, expire_ts = 0 }
                        end
                        local r = orig(rd)
                        applyNameFrame()
                        return r
                    end
                end)
                wrapStatic(DataMgr, "UpdateMyRoleProfileData", function(orig)
                    return function(...)
                        local r = orig(...)
                        pcall(applyAlias)
                        pcall(applyNameFrame)
                        return r
                    end
                end)
            end
        end)
    end

    local function installBgOpeningSocialHooks()
        -- Role Info BG module
        pcall(function()
            local m = safeMod("logic_roleInfo_background")
            if m then
                wrapStatic(m, "IsHaveRoleInfoBG", function() return function() return true end end)
                wrapStatic(m, "send_set_social_info_bg_req", function(orig)
                    return function(self, bgId)
                        applyRoleInfoBg()
                        if m.on_set_social_info_bg_rsp then
                            pcall(function() m:on_set_social_info_bg_rsp(0, CFG.ROLE_INFO_BG) end)
                        end
                    end
                end)
                wrapStatic(m, "on_set_social_info_bg_rsp", function(orig)
                    return function(self, res, id)
                        if res ~= 0 then res = 0 end
                        return orig(self, res, CFG.ROLE_INFO_BG)
                    end
                end)
            end
        end)

        -- Opening module
        pcall(function()
            local m = safeMod("logic_roleInfo_opening")
            if m then
                wrapStatic(m, "IsHaveOpeningItem", function() return function() return true end end)
                wrapStatic(m, "send_set_social_info_bg_req", function(orig)
                    return function(self, id)
                        applyOpening()
                        if m.on_set_social_info_bg_rsp then
                            pcall(function() m:on_set_social_info_bg_rsp(0, CFG.OPENING) end)
                        end
                    end
                end)
                wrapStatic(m, "on_set_social_info_bg_rsp", function(orig)
                    return function(self, res, id)
                        if res ~= 0 then res = 0 end
                        return orig(self, res, CFG.OPENING)
                    end
                end)
            end
        end)

        -- Social Card BG module
        pcall(function()
            local m = safeMod("logic_social_card_bg")
            if m then
                wrapStatic(m, "IsHaveCardSkin", function() return function() return true end end)
                wrapStatic(m, "send_set_social_card_floor_req", function(orig)
                    return function(self, id)
                        m.CurrentSocialCardBGID = CFG.SOCIAL_CARD_BG
                        applySocialCardBg()
                        if m.on_notify_social_card_floor then
                            pcall(function() m:on_notify_social_card_floor(CFG.SOCIAL_CARD_BG) end)
                        end
                        if m.on_set_social_card_floor_rsp then
                            pcall(function() m:on_set_social_card_floor_rsp(0) end)
                        end
                    end
                end)
                wrapStatic(m, "on_set_social_card_floor_rsp", function(orig)
                    return function(self, res)
                        if res ~= 0 then res = 0 end
                        return orig(self, res)
                    end
                end)
            end
        end)

        -- Network handler intercepts
        pcall(function()
            local RGB = safeReq("client.network.Protocol.RoleInfoBGHandler")
            if RGB then
                wrapStatic(RGB, "send_set_social_info_bg_req", function(orig)
                    return function(subtype, id)
                        local RB_Key = ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.RoleInfoBG
                        local OP_Key = ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.PersonalOpening
                        if RB_Key and subtype == RB_Key then
                            applyRoleInfoBg()
                            local m = safeMod("logic_roleInfo_background")
                            if m and m.on_set_social_info_bg_rsp then
                                pcall(function() m:on_set_social_info_bg_rsp(0, CFG.ROLE_INFO_BG) end)
                            end
                        elseif OP_Key and subtype == OP_Key then
                            applyOpening()
                            local m = safeMod("logic_roleInfo_opening")
                            if m and m.on_set_social_info_bg_rsp then
                                pcall(function() m:on_set_social_info_bg_rsp(0, CFG.OPENING) end)
                            end
                        end
                    end
                end)
                wrapStatic(RGB, "on_notify_social_info_bg", function(orig)
                    return function(bgIds)
                        if type(bgIds) == "table" then
                            if ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.RoleInfoBG then
                                bgIds[ENUM_ITEM_SUBTYPE.RoleInfoBG] = CFG.ROLE_INFO_BG
                            end
                            if ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.PersonalOpening then
                                bgIds[ENUM_ITEM_SUBTYPE.PersonalOpening] = CFG.OPENING
                            end
                        end
                        return orig(bgIds)
                    end
                end)
            end
        end)

        pcall(function()
            local SCBG = safeReq("client.network.Protocol.SocialCardBGHandler")
            if SCBG then
                wrapStatic(SCBG, "send_set_social_card_floor_req", function(orig)
                    return function(id)
                        applySocialCardBg()
                        local m = safeMod("logic_social_card_bg")
                        if m and m.on_set_social_card_floor_rsp then
                            pcall(function() m:on_set_social_card_floor_rsp(0) end)
                        end
                    end
                end)
                wrapStatic(SCBG, "on_notify_social_card_floor", function(orig)
                    return function(id) return orig(CFG.SOCIAL_CARD_BG) end
                end)
            end
        end)

        -- CharacterHandler
        pcall(function()
            local CH = safeReq("client.network.Protocol.CharacterHandler")
            if CH then
                wrapStatic(CH, "send_change_user_avatar", function(orig)
                    return function(url)
                        applyAvatar()
                        local RAS = safeReq("client.slua.logic.roleInfo.logic_roleInfo_Avatar")
                        if RAS and RAS.change_user_avatar_rsp then
                            pcall(function() RAS.change_user_avatar_rsp(0, CFG.AVATAR, 1) end)
                        end
                    end
                end)
                wrapStatic(CH, "send_change_avatar_box", function(orig)
                    return function(id)
                        applyFrame()
                        local RAF = safeReq("client.slua.logic.roleInfo.logic_RoleInfoAvatarFrame")
                        if RAF and RAF.change_avatar_box_rsp then
                            pcall(function() RAF.change_avatar_box_rsp(0, CFG.AVATAR_BOX) end)
                        end
                    end
                end)
            end
        end)

        -- RoleInfoHandler
        pcall(function()
            local RH = safeReq("client.network.Protocol.RoleInfoHandler")
            if not RH then return end
            wrapStatic(RH, "send_set_friend_nickname_skin_req", function(orig)
                return function(id) applyNickname() end
            end)
            wrapStatic(RH, "send_set_chat_bubble_req", function(orig)
                return function(id) applyChat() end
            end)
            wrapStatic(RH, "send_change_team_notify_skin", function(orig)
                return function(id) applyTeamSkin() end
            end)
            wrapStatic(RH, "send_equip_carte_frame_req", function(orig)
                return function(id, eq) applyCarteFrame() end
            end)
            wrapStatic(RH, "send_use_brand", function(orig)
                return function(id)
                    applyNameFrame()
                    local m = safeReq("client.slua.logic.person_space.logic_roleinfo_nameframe")
                    if m and m.use_brand_rsp then
                        pcall(function() m.use_brand_rsp(0, CFG.NAME_FRAME_ID) end)
                    end
                end
            end)
            wrapStatic(RH, "on_set_friend_nickname_skin_rsp", function(orig)
                return function(ok, id)
                    if ok ~= 0 then ok = 0 end
                    return orig(ok, CFG.NICKNAME_SKIN)
                end
            end)
            wrapStatic(RH, "on_set_chat_bubble_rsp", function(orig)
                return function(ok, id)
                    if ok ~= 0 then ok = 0 end
                    return orig(ok, CFG.CHAT_BUBBLE)
                end
            end)
            wrapStatic(RH, "on_get_friend_nickname_skin_rsp", function(orig)
                return function(ok, data, cfg)
                    if ok ~= 0 then ok = 0 end
                    data = data or {}
                    data.skins = fillNicknameSkin(data.skins or {})
                    data.equip = CFG.NICKNAME_SKIN
                    return orig(ok, data, cfg)
                end
            end)
            wrapStatic(RH, "on_get_chat_bubble_rsp", function(orig)
                return function(ok, data, cfg)
                    if ok ~= 0 then ok = 0 end
                    data = data or {}
                    data.bubbles = fillChatBubble(data.bubbles or {})
                    data.equip = CFG.CHAT_BUBBLE
                    return orig(ok, data, cfg)
                end
            end)
            wrapStatic(RH, "on_get_team_notify_skin_list_rsp", function(orig)
                return function(ok, list, cur)
                    if ok ~= 0 then ok = 0 end
                    return orig(ok, fillTeamSkin(list), CFG.TEAM_SKIN)
                end
            end)
            wrapStatic(RH, "on_get_carte_frame_list_rsp", function(orig)
                return function(ok, list, cur)
                    if ok ~= 0 then ok = 0 end
                    return orig(ok, fillCarteFrame(list), CFG.CARTE_FRAME)
                end
            end)
        end)
    end

    -- ═════════ APPLY ALL + FIRE EVENTS ═════════
    local function applyAll()
        applyRoleData()
        applyAvatar()
        applyFrame()
        applyNickname()
        applyChat()
        applyTeamSkin()
        applyCarteFrame()
        applyAlias()
        applyNameFrame()
        applyRoleInfoBg()
        applyOpening()
        applySocialCardBg()
        applyRank()
        applyBadges()
        applyCollect()
    end

    local function fireRefreshEvents()
        pcall(function()
            if not EventSystem then return end
            if EVENTTYPE_LOBBY and EVENTID_UPDATE_LOBBY_AVATAR then
                fireEvent(EVENTTYPE_LOBBY, EVENTID_UPDATE_LOBBY_AVATAR)
            end
            if EVENTTYPE_ROLEINFO then
                if EVENTID_ROLEINFO_UPDATE_HEAD_INFO then
                    fireEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_HEAD_INFO, CFG.AVATAR)
                end
                if EVENTID_ROLEINFO_UPDATE_AVATAR_FRAME_INFO then
                    fireEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_AVATAR_FRAME_INFO)
                end
                if EVENTID_ROLEINFO_NICKNAME_FRAME_UPDATE then
                    fireEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_NICKNAME_FRAME_UPDATE)
                end
                if EVENTID_ROLEINFO_CHAT_FRAME_UPDATE then
                    fireEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_CHAT_FRAME_UPDATE)
                end
                if EVENTID_ROLEINFO_UPDATE_TEAMUPFRAME then
                    fireEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_TEAMUPFRAME)
                end
                if EVENTID_ROLEINFO_CARTE_FRAME_UPDATE then
                    fireEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_CARTE_FRAME_UPDATE)
                end
                if EVENTID_ROLEINFO_UPDATE_ROLEINFO then
                    fireEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_ROLEINFO)
                end
                if EVENTID_ROLEINFO_USE_NAME_FRAME then
                    fireEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_USE_NAME_FRAME, CFG.NAME_FRAME_ID)
                end
                if EVENTID_ROLEINFO_BACKGROUND_UPDATE then
                    fireEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_BACKGROUND_UPDATE)
                end
                if EVENTID_ROLEINFO_OPENING_UPDATE then
                    fireEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_OPENING_UPDATE)
                end
                if EVENTID_ROLEINFO_SOCIAL_CARD_UPDATE then
                    fireEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_SOCIAL_CARD_UPDATE)
                end
            end
            if EVENTTYPE_COLLECT and EVENTID_COLLECT_DATA_NOTIFY then
                fireEvent(EVENTTYPE_COLLECT, EVENTID_COLLECT_DATA_NOTIFY)
            end
        end)
    end

    -- ═════════ INSTALL + BOOT ═════════
    local hooksDone = false
    local function installAllHooks()
        if hooksDone then return true end
        installAvatarHooks()
        installFrameHooks()
        installNicknameHooks()
        installChatHooks()
        installTeamSkinHooks()
        installCarteFrameHooks()
        installAliasHooks()
        installNameFrameHooks()
        installBgOpeningSocialHooks()
        hooksDone = true
        return true
    end

    local booted = false
    local function boot()
        if booted then return true end
        if not DataMgr or not DataMgr.roleData then return false end
        if not DataMgr.roleData.uid then return false end
        installAllHooks()
        applyAll()
        fireRefreshEvents()
        booted = true
        return true
    end

    local tries = 0
    local function tryBoot()
        tries = tries + 1
        if boot() then
            print("[RoxzProfile] Booted on try #" .. tries)
            return
        end
        if tries >= 60 then
            print("[RoxzProfile] Boot FAILED after " .. tries .. " tries")
            return
        end
        pcall(function()
            local t = require("common.time_ticker")
            if t and t.AddTimerOnce then
                t.AddTimerOnce(1.0, tryBoot)
            end
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

    -- Periodic re-apply (lobby only, 5s)
    pcall(function()
        local t = require("common.time_ticker")
        if t and t.AddTimerLoop then
            t.AddTimerLoop(0, function()
                pcall(function()
                    if not booted then return end
                    if GameStatus and GameStatus.IsInFightingStatus
                        and GameStatus.IsInFightingStatus() then
                        return
                    end
                    applyAll()
                end)
            end, -1, 5.0)
        end
    end)

    -- Event-driven re-apply
    pcall(function()
        if not EventSystem then return end
        local function onRefresh() pcall(applyAll) end
        if EVENTTYPE_LOBBY and EVENTID_SHOW_LOBBY then
            EventSystem:registEvent(EVENTTYPE_LOBBY, EVENTID_SHOW_LOBBY, onRefresh)
        end
        if EVENTTYPE_LOGIN_ROLEDATA and EVENTID_LOGIN_ROLEDATA_SYNC then
            EventSystem:registEvent(EVENTTYPE_LOGIN_ROLEDATA, EVENTID_LOGIN_ROLEDATA_SYNC, onRefresh)
        end
        if EVENTTYPE_ROLEINFO and EVENTID_ROLEINFO_UPDATE_ROLEINFO then
            EventSystem:registEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_ROLEINFO, onRefresh)
        end
    end)

    -- Optional manual API (not required — script auto-runs)
    _G.RoxzProfile = {
        Apply = applyAll,
        Config = CFG,
    }

    print("[RoxzProfile] v1 loaded — Conqueror 801 / " .. CFG.RANK_STARS .. " stars / Journey badge " .. CFG.JOURNEY_BADGE_LEVEL)
end)
