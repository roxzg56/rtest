-- ═══════════════════════════════════════════════════════════════════
-- RoxzProfile v2.0 — Full Rebuild From decoded_output_GAME.lua
-- Fixes: no ResourceLoaded popup spam, real swap works, UI opens,
--        title/frame/chat/nickname/bg/opening/socialcard all swap
--        cleanly without breaking original flow
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    if _G._ROXZ_PROFILE_V2 then return end
    _G._ROXZ_PROFILE_V2 = true

    -- ═══════════════════════════════════════════════════════════════
    -- CONFIG — change these to swap what's equipped
    -- ═══════════════════════════════════════════════════════════════
    local CFG = {
        AVATAR              = 30396,
        AVATAR_BOX          = 2002901,
        NICKNAME_SKIN       = 61910001,
        CHAT_BUBBLE         = 61100036,
        TEAM_SKIN           = 61300005,
        CARTE_FRAME         = 61100036,
        ALIAS_ID            = 2494116,
        NAME_FRAME_ID       = 1511250117,
        ROLE_INFO_BG        = 61510001,
        OPENING             = 61520001,
        SOCIAL_CARD_BG      = 61520001,

        RANK_SEGMENT        = 801,
        RANK_STARS          = 91,
        PEAK_CURRENT_SEG    = 1541,
        PEAK_HISTORY_SEG    = 1301,
        PEAK_RATING         = 8000,
        JOURNEY_BADGE_LEVEL = 17,
        JOURNEY_VISUAL_LV   = 3,
        JOURNEY_GLOW_TASKS  = 3,
        COLLECT_SCORE       = 999999999,
        COLLECT_LEVEL       = 100,
    }

    -- ═══════════════════════════════════════════════════════════════
    -- HELPERS (decoded_output style: safe, rawget-safe, no vararg leaks)
    -- ═══════════════════════════════════════════════════════════════
    local _unpack = unpack or table.unpack
    local _pfx = "__roxz_v2_"

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

    -- Safe vararg event fire (captures into table first)
    local function fireEvent(...)
        local args = { n = select("#", ...), ... }
        if not (EventSystem and EventSystem.postEvent) then return end
        pcall(function()
            EventSystem:postEvent(_unpack(args, 1, args.n))
        end)
    end

    -- Idempotent hook installer
    local function hook(tbl, name, wrapper)
        if type(tbl) ~= "table" then return false end
        if type(tbl[name]) ~= "function" then return false end
        local key = _pfx .. name
        if rawget(tbl, key) then return false end
        rawset(tbl, key, tbl[name])
        tbl[name] = wrapper(rawget(tbl, key))
        return true
    end

    -- Force-override (for pure boolean gates that must ALWAYS return true)
    local function forceReturn(tbl, name, val)
        if type(tbl) ~= "table" then return false end
        if type(tbl[name]) ~= "function" then return false end
        local key = _pfx .. name
        if not rawget(tbl, key) then rawset(tbl, key, tbl[name]) end
        local v = val
        tbl[name] = function() return v end
        return true
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

    -- ═══════════════════════════════════════════════════════════════
    -- FILL HELPERS — merge into EXISTING list, never create dupes
    -- ═══════════════════════════════════════════════════════════════
    local function fillMap(map, cfgTable, idField, entryTemplate)
        if type(map) ~= "table" then return map end
        pcall(function()
            local cfg = CDataTable.GetTable(cfgTable)
            for k, row in pairs(cfg or {}) do
                local id = tonumber(row[idField] or row.ID or row.Id or k)
                if id and id > 0 and map[id] == nil then
                    map[id] = entryTemplate or { expire_ts = 0 }
                end
            end
        end)
        return map
    end

    -- ═══════════════════════════════════════════════════════════════
    -- APPLY: equip current selection into live state
    -- Runs silently, does NOT trigger popups
    -- ═══════════════════════════════════════════════════════════════
    local function applyAvatarState()
        pcall(function()
            local RAS = safeReq("client.slua.logic.roleInfo.logic_roleInfo_Avatar")
            if RAS then
                RAS.HeadportraitList = RAS.HeadportraitList or {}
                RAS.HeadportraitList[tostring(CFG.AVATAR)] = 1
            end
            if DataMgr and DataMgr.roleData then
                DataMgr.roleData.headIconUrl = tostring(CFG.AVATAR)
                DataMgr.roleData.pic_url     = tostring(CFG.AVATAR)
                DataMgr.roleData.picUrl      = tostring(CFG.AVATAR)
            end
        end)
    end

    local function applyFrameState()
        pcall(function()
            local RAF = safeReq("client.slua.logic.roleInfo.logic_RoleInfoAvatarFrame")
            if RAF then
                RAF.AvatarFrameList = RAF.AvatarFrameList or {}
                RAF.AvatarFrameList[CFG.AVATAR_BOX] = { expire_time = 0 }
            end
            if DataMgr and DataMgr.roleData then
                DataMgr.roleData.cur_avatar_box_id = CFG.AVATAR_BOX
            end
        end)
    end

    local function applyNicknameState()
        pcall(function()
            if DataMgr and DataMgr.roleData then
                DataMgr.roleData.friend_nickname_skin = CFG.NICKNAME_SKIN
            end
            local m = safeMod("logic_roleInfo_nicknameframe")
            if m then
                m.unlockData = m.unlockData or {}
                m.unlockData[CFG.NICKNAME_SKIN] = { expire_ts = 0 }
            end
        end)
    end

    local function applyChatState()
        pcall(function()
            if DataMgr and DataMgr.roleData then
                DataMgr.roleData.chat_bubble = CFG.CHAT_BUBBLE
            end
            local m = safeMod("logic_roleInfo_chatframe")
            if m then
                m.unlockData = m.unlockData or {}
                m.unlockData[CFG.CHAT_BUBBLE] = { expire_ts = 0 }
            end
        end)
    end

    local function applyTeamSkinState()
        pcall(function()
            if DataMgr and DataMgr.roleData then
                DataMgr.roleData.cur_team_notify_skin_id = CFG.TEAM_SKIN
            end
        end)
    end

    local function applyCarteFrameState()
        pcall(function()
            local m = safeMod("logic_roleinfo_carte_frame")
            if m then
                if m.InitCarteFrameMap then pcall(function() m:InitCarteFrameMap() end) end
                m.CarteFrameMap = m.CarteFrameMap or {}
                if m.CarteFrameMap[CFG.CARTE_FRAME] then
                    m.CarteFrameMap[CFG.CARTE_FRAME].bLock     = false
                    m.CarteFrameMap[CFG.CARTE_FRAME].expire_ts = 0
                end
            end
        end)
    end

    local function applyAliasState()
        pcall(function()
            if not DataMgr or not DataMgr.roleData then return end
            local rd = DataMgr.roleData
            rd.alias = rd.alias or {}
            rd.alias.id = CFG.ALIAS_ID

            local title = ""
            local ac = CDataTable.GetTableData("AliasCfg", CFG.ALIAS_ID)
            if ac and ac.AliasName then title = ac.AliasName end
            pcall(function()
                if FuncUtil and FuncUtil.Gen_title then
                    title = FuncUtil.Gen_title(CFG.ALIAS_ID, 0, {}, 0) or title
                end
            end)
            rd.alias.title = title
            rd.alias.nation = rd.alias.nation or ""
            rd.alias.rank_id = 0
            rd.alias.rank    = 0
            rd.alias.ext_info = rd.alias.ext_info or {}

            -- Sync list_info state (use/have) — no popup trigger
            local AS = safeReq("client.slua.logic.roleInfo.logic_roleinfo_title")
            if AS and type(AS.alias_list_info) == "table" then
                local ENUM = AS.enum_Alias_State_Type or { notHave = 0, have = 1, use = 2 }
                for k, v in pairs(AS.alias_list_info) do
                    if type(v) == "table" then
                        v.state = (tonumber(k) == CFG.ALIAS_ID) and ENUM.use or ENUM.have
                    end
                end
                if not AS.alias_list_info[CFG.ALIAS_ID] then
                    AS.alias_list_info[CFG.ALIAS_ID] = {
                        state = ENUM.use, receive_time = 0, expire_ts = 0,
                        rank = 0, ext_info = {}, rank_id = 0,
                        title = title, nation = "", have_used = 1,
                    }
                else
                    AS.alias_list_info[CFG.ALIAS_ID].state = ENUM.use
                    AS.alias_list_info[CFG.ALIAS_ID].title = title
                end
            end
        end)
    end

    local function applyNameFrameState()
        pcall(function()
            if not DataMgr or not DataMgr.roleData then return end
            local rd = DataMgr.roleData
            rd.nameFrameData = rd.nameFrameData or {}
            for k, v in pairs(rd.nameFrameData) do
                if type(v) == "table" then v.is_used = 0 end
            end
            rd.nameFrameData[CFG.NAME_FRAME_ID] = { is_used = 1, expire_ts = 0 }

            local m = safeReq("client.slua.logic.person_space.logic_roleinfo_nameframe")
            if m then m.nUsedID = CFG.NAME_FRAME_ID end
        end)
    end

    local function applyRoleInfoBgState()
        pcall(function()
            local m = safeMod("logic_roleInfo_background")
            if m then
                local key = (ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.RoleInfoBG) or 5
                if m.SetCurrentRoleInfoBGID then
                    pcall(function() m:SetCurrentRoleInfoBGID(CFG.ROLE_INFO_BG) end)
                else
                    m.CurrentRoleInfoBGID = CFG.ROLE_INFO_BG
                end
                if type(m.RoleInfoBGData) == "table" then
                    m.RoleInfoBGData[key] = CFG.ROLE_INFO_BG
                end
            end
        end)
    end

    local function applyOpeningState()
        pcall(function()
            local m = safeMod("logic_roleInfo_opening")
            if m then
                if m.SetCurrentOpeningItemID then
                    pcall(function() m:SetCurrentOpeningItemID(CFG.OPENING) end)
                end
                m.CurrentOpeningItemID = CFG.OPENING
            end
        end)
    end

    local function applySocialCardState()
        pcall(function()
            local m = safeMod("logic_social_card_bg")
            if m then
                m.CurrentSocialCardBGID = CFG.SOCIAL_CARD_BG
            end
        end)
    end

    -- ═══════════════════════════════════════════════════════════════
    -- RANK + BADGES (silent state write, no popup)
    -- ═══════════════════════════════════════════════════════════════
    local function getStarRating()
        local s = tonumber(CFG.RANK_STARS) or 0
        if s > 0 then return 4200 + (s - 1) * 100 end
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
                        bestId = tid
                    end
                end
            end
        end)
        return bestId
    end

    local function applyRankState()
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

            rd.allzoneSegment = rd.allzoneSegment or {}
            for z = 1, 6 do
                rd.allzoneSegment[z] = rd.allzoneSegment[z] or {}
                for m = 1, 6 do rd.allzoneSegment[z][m] = seg end
            end

            local tid = resolveConquerorTitleId()
            if tid and tid > 0 then
                rd.allzoneSegmentTitle = rd.allzoneSegmentTitle or {}
                for z = 1, 6 do
                    rd.allzoneSegmentTitle[z] = rd.allzoneSegmentTitle[z] or {}
                    for m = 1, 6 do
                        rd.allzoneSegmentTitle[z][m] = { id = tid }
                    end
                end
            end

            DataMgr.maxSegmentSquad = { zoneid = 1, SegmentLevel = seg }
            DataMgr.isSeasonStarOpen = true
            rd.is_season_star_open = true

            pcall(function()
                local TU = safeReq("client.common.time_util")
                local now = (TU and TU.GetServerTimeInSec and TU.GetServerTimeInSec()) or os.time()
                DataMgr.registertime = now - (10 * 365 * 86400)
            end)

            -- Peakgame list
            pcall(function()
                local PeakCfg = safeReq("client.logic.PeakGame.PeakGameConfig")
                if PeakCfg then
                    local squad = PeakCfg.BattleType.Squad
                    local list = {}
                    for season = 1, 6 do
                        list[season] = {
                            [squad] = {
                                rating         = CFG.PEAK_RATING,
                                segment_id     = CFG.PEAK_CURRENT_SEG,
                                max_segment_id = CFG.PEAK_CURRENT_SEG,
                            }
                        }
                    end
                    rd.peakgame_segment_info = {
                        curr_season_id = DataMgr.season_id or 1,
                        list = list,
                    }
                    rd.peakgame_history_max_segment = CFG.PEAK_HISTORY_SEG
                end
            end)

            -- SeasonHandler rating
            pcall(function()
                local SH = safeReq("client.network.Protocol.SeasonHandler")
                if SH and seg == 801 then SH.rank_rating = getStarRating() end
            end)
        end)
    end

    local function buildBadgeInfo()
        local SYearCfg = safeReq("client.logic.season_year.config.season_year_config")
        if not SYearCfg or not SYearCfg.EBadgePartType then return nil end
        local BP = SYearCfg.EBadgePartType
        local T  = SYearCfg.ERankTaskStatus and SYearCfg.ERankTaskStatus.Completed or 1
        local L  = CFG.JOURNEY_BADGE_LEVEL
        local VL = CFG.JOURNEY_VISUAL_LV
        local GT = CFG.JOURNEY_GLOW_TASKS
        local GLOW = { 701, 702, 703, 801 }
        local crownMax = SYearCfg.CrownTaskMaxCount or 10

        local gem   = { { finish_count = L, status = T } }
        local base  = { { finish_count = L, status = T } }
        local glow  = {}
        for i = 1, VL do
            glow[i] = { finish_count = 1, status = T, trigger_value = GLOW[i] or 801 }
        end
        local crown = {}
        for i = 1, crownMax do
            crown[i] = { finish_count = math.min(GT, L), status = T }
        end
        return {
            [BP.Gem]   = gem,
            [BP.Base]  = base,
            [BP.Glow]  = glow,
            [BP.Crown] = crown,
        }
    end

    local function applyBadgesState()
        pcall(function()
            local m = safeMod("logic_season_year_badge")
            if not m then return end
            local info = buildBadgeInfo()
            if not info then return end

            local SYearUtil = safeReq("client.logic.season_year.util.season_year_util")
            local yearId = (SYearUtil and SYearUtil.GetSeasonYearId and SYearUtil.GetSeasonYearId()) or 1
            local SYearCfg = safeReq("client.logic.season_year.config.season_year_config")
            local showType = (SYearCfg and SYearCfg.EBadgeShowType and SYearCfg.EBadgeShowType.Show) or 1

            m.seasonYearBadgeInfo = m.seasonYearBadgeInfo or {}
            m.seasonYearBadgeInfo[yearId] = info
            m.seasonYearBadgeInfo[0] = info
            m.loginDays = CFG.JOURNEY_BADGE_LEVEL
            m.badgeShowType = showType
            m.bShowType = showType
            m.serverBadgeCfg = m.serverBadgeCfg or {}
            m.serverBadgeCfg[yearId] = info
            m.seasonYearTaskInfo = m.seasonYearTaskInfo or {}
            m.seasonYearTaskInfo[1] = {
                task_id = 1,
                status = (SYearCfg and SYearCfg.ERankTaskStatus and SYearCfg.ERankTaskStatus.Completed) or 1,
                finish_count = CFG.JOURNEY_BADGE_LEVEL,
            }
            m.serverYearTaskCfg = m.serverYearTaskCfg or {}
            m.serverYearTaskCfg[yearId] = { task_cfgs = { { task_desc_id = 0 } } }
        end)
    end

    local function applyCollectState()
        pcall(function()
            local m = safeMod("collect_module")
            if m and type(m.collect_data) == "table" then
                m.collect_data.total_score = CFG.COLLECT_SCORE
                m.collect_data.cur_season_collect_score = CFG.COLLECT_SCORE
                m.collect_data.season_score = m.collect_data.season_score or {}
                if DataMgr and DataMgr.season_id then
                    m.collect_data.season_score[DataMgr.season_id] = CFG.COLLECT_SCORE
                end
            end
            if DataMgr and DataMgr.roleData then
                DataMgr.roleData.brief_collect_data = DataMgr.roleData.brief_collect_data or {}
                DataMgr.roleData.brief_collect_data.total_score = CFG.COLLECT_SCORE
                DataMgr.roleData.brief_collect_data.cur_season_collect_score = CFG.COLLECT_SCORE
            end
        end)
    end

    -- ═══════════════════════════════════════════════════════════════
    -- APPLY ALL (idempotent, silent)
    -- ═══════════════════════════════════════════════════════════════
    local function applyAll()
        applyAvatarState()
        applyFrameState()
        applyNicknameState()
        applyChatState()
        applyTeamSkinState()
        applyCarteFrameState()
        applyAliasState()
        applyNameFrameState()
        applyRoleInfoBgState()
        applyOpeningState()
        applySocialCardState()
        applyRankState()
        applyBadgesState()
        applyCollectState()
    end

    -- ═══════════════════════════════════════════════════════════════
    -- HOOKS — pattern: call orig FIRST, patch data in/out, return orig result
    -- This keeps original UI flow intact (no broken callbacks)
    -- ═══════════════════════════════════════════════════════════════

    -- ── AVATAR ──
    local function installAvatarHooks()
        pcall(function()
            local RAS = safeReq("client.slua.logic.roleInfo.logic_roleInfo_Avatar")
            if not RAS then return end
            forceReturn(RAS, "HasAvatar",          true)
            forceReturn(RAS, "HasOwnHeadPortrait", true)

            hook(RAS, "get_user_avatar_list_rsp", function(orig)
                return function(ok, list, url)
                    if ok ~= 0 then ok = 0 end
                    -- Fill list silently (no dupes)
                    if type(list) == "table" then
                        pcall(function()
                            local cfg = CDataTable.GetTable("Headportrait")
                            for k, row in pairs(cfg or {}) do
                                local id = tostring(row.ID or row.Id or k)
                                list[id] = 1
                            end
                        end)
                    end
                    -- Call orig with patched args — original applies UI
                    return orig(0, list or {}, CFG.AVATAR)
                end
            end)

            hook(RAS, "change_user_avatar_rsp", function(orig)
                return function(ok, url, endtime)
                    if ok ~= 0 then ok = 0 end
                    return orig(0, CFG.AVATAR, 1)
                end
            end)
        end)
        pcall(function()
            local CH = safeReq("client.network.Protocol.CharacterHandler")
            if CH then
                hook(CH, "send_change_user_avatar", function(orig)
                    return function(url)
                        -- Optimistic local response — original UI updates immediately
                        local RAS = safeReq("client.slua.logic.roleInfo.logic_roleInfo_Avatar")
                        if RAS and RAS.change_user_avatar_rsp then
                            pcall(function() RAS.change_user_avatar_rsp(0, CFG.AVATAR, 1) end)
                        end
                        applyAvatarState()
                        -- Do NOT send to server (blocked)
                    end
                end)
                hook(CH, "on_change_user_avatar_rsp", function(orig)
                    return function(ok, url, endtime)
                        if ok ~= 0 then ok = 0 end
                        return orig(0, CFG.AVATAR, 1)
                    end
                end)
            end
        end)
    end

    -- ── AVATAR FRAME ──
    local function installFrameHooks()
        pcall(function()
            local RAF = safeReq("client.slua.logic.roleInfo.logic_RoleInfoAvatarFrame")
            if not RAF then return end
            forceReturn(RAF, "HasAvatarFrame",     true)
            forceReturn(RAF, "HasAvatarFrameCond", true)

            hook(RAF, "get_avatar_box_list_rsp", function(orig)
                return function(ok, list, boxId)
                    if ok ~= 0 then ok = 0 end
                    if type(list) == "table" then
                        pcall(function()
                            local cfg = CDataTable.GetTable("AvatarFrame")
                            for k, row in pairs(cfg or {}) do
                                local id = tonumber(row.ID or row.Id or k)
                                if id and id > 0 and list[id] == nil then
                                    list[id] = { expire_time = 0 }
                                end
                            end
                        end)
                    end
                    RAF.AvatarFrameList = RAF.AvatarFrameList or {}
                    RAF.AvatarFrameList[CFG.AVATAR_BOX] = { expire_time = 0 }
                    return orig(0, list or {}, CFG.AVATAR_BOX)
                end
            end)

            hook(RAF, "change_avatar_box_rsp", function(orig)
                return function(ok, id)
                    if ok ~= 0 then ok = 0 end
                    return orig(0, CFG.AVATAR_BOX)
                end
            end)
        end)
        pcall(function()
            local WRH = safeReq("client.network.Protocol.WardRobeHandler")
            if WRH then
                hook(WRH, "on_get_avatar_box_list_rsp", function(orig)
                    return function(ok, list, boxId)
                        if ok ~= 0 then ok = 0 end
                        if type(list) == "table" then
                            pcall(function()
                                local cfg = CDataTable.GetTable("AvatarFrame")
                                for k, row in pairs(cfg or {}) do
                                    local id = tonumber(row.ID or row.Id or k)
                                    if id and id > 0 and list[id] == nil then
                                        list[id] = { expire_time = 0 }
                                    end
                                end
                            end)
                        end
                        return orig(0, list or {}, CFG.AVATAR_BOX)
                    end
                end)
            end
        end)
        pcall(function()
            local CH = safeReq("client.network.Protocol.CharacterHandler")
            if CH then
                hook(CH, "send_change_avatar_box", function(orig)
                    return function(id)
                        local RAF = safeReq("client.slua.logic.roleInfo.logic_RoleInfoAvatarFrame")
                        if RAF and RAF.change_avatar_box_rsp then
                            pcall(function() RAF.change_avatar_box_rsp(0, CFG.AVATAR_BOX) end)
                        end
                        applyFrameState()
                    end
                end)
                hook(CH, "on_change_avatar_box_rsp", function(orig)
                    return function(ok, id)
                        if ok ~= 0 then ok = 0 end
                        return orig(0, CFG.AVATAR_BOX)
                    end
                end)
            end
        end)
    end

    -- ── NICKNAME EFFECT ──
    local function installNicknameHooks()
        pcall(function()
            local m = safeMod("logic_roleInfo_nicknameframe")
            if not m then return end
            forceReturn(m, "HasFrame", true)
            forceReturn(m, "IsLocked", false)

            hook(m, "ProcNicknameListRsp", function(orig)
                return function(self, data, cfg)
                    data = data or {}
                    data.skins = data.skins or {}
                    pcall(function()
                        local c = CDataTable.GetTable("NicknameEffectCfg")
                        for k, row in pairs(c or {}) do
                            local id = tonumber(row.ID or k)
                            if id and data.skins[id] == nil then
                                data.skins[id] = { expire_ts = 0 }
                            end
                        end
                    end)
                    data.equip = CFG.NICKNAME_SKIN
                    return orig(self, data, cfg)
                end
            end)

            hook(m, "ProcChangeRsp", function(orig)
                return function(self, skinId)
                    -- Always report our chosen id
                    self.unlockData = self.unlockData or {}
                    self.unlockData[CFG.NICKNAME_SKIN] = { expire_ts = 0 }
                    if DataMgr and DataMgr.roleData then
                        DataMgr.roleData.friend_nickname_skin = CFG.NICKNAME_SKIN
                    end
                    return orig(self, CFG.NICKNAME_SKIN)
                end
            end)
        end)
        pcall(function()
            local RH = safeReq("client.network.Protocol.RoleInfoHandler")
            if RH then
                hook(RH, "send_set_friend_nickname_skin_req", function(orig)
                    return function(skinId)
                        local m = safeMod("logic_roleInfo_nicknameframe")
                        if m and m.ProcChangeRsp then
                            pcall(function() m:ProcChangeRsp(CFG.NICKNAME_SKIN) end)
                        end
                        applyNicknameState()
                    end
                end)
                hook(RH, "on_set_friend_nickname_skin_rsp", function(orig)
                    return function(ok, skinId)
                        if ok ~= 0 then ok = 0 end
                        return orig(0, CFG.NICKNAME_SKIN)
                    end
                end)
                hook(RH, "on_get_friend_nickname_skin_rsp", function(orig)
                    return function(ok, data, cfg)
                        if ok ~= 0 then ok = 0 end
                        data = data or {}
                        data.skins = data.skins or {}
                        pcall(function()
                            local c = CDataTable.GetTable("NicknameEffectCfg")
                            for k, row in pairs(c or {}) do
                                local id = tonumber(row.ID or k)
                                if id and data.skins[id] == nil then
                                    data.skins[id] = { expire_ts = 0 }
                                end
                            end
                        end)
                        data.equip = CFG.NICKNAME_SKIN
                        return orig(0, data, cfg)
                    end
                end)
            end
        end)
    end

    -- ── CHAT BUBBLE ──
    local function installChatHooks()
        pcall(function()
            local m = safeMod("logic_roleInfo_chatframe")
            if not m then return end
            forceReturn(m, "HasChatBubble", true)
            forceReturn(m, "IsLocked", false)

            hook(m, "ProcChatListRsp", function(orig)
                return function(self, data, cfg)
                    data = data or {}
                    data.bubbles = data.bubbles or {}
                    pcall(function()
                        local c = CDataTable.GetTable("ChatEffectCfg")
                        for k, row in pairs(c or {}) do
                            local id = tonumber(row.ID or k)
                            if id and data.bubbles[id] == nil then
                                data.bubbles[id] = { expire_ts = 0 }
                            end
                        end
                    end)
                    data.equip = CFG.CHAT_BUBBLE
                    return orig(self, data, cfg)
                end
            end)

            hook(m, "ProcChangeRsp", function(orig)
                return function(self, bubbleId)
                    self.unlockData = self.unlockData or {}
                    self.unlockData[CFG.CHAT_BUBBLE] = { expire_ts = 0 }
                    if DataMgr and DataMgr.roleData then
                        DataMgr.roleData.chat_bubble = CFG.CHAT_BUBBLE
                    end
                    return orig(self, CFG.CHAT_BUBBLE)
                end
            end)
        end)
        pcall(function()
            local RH = safeReq("client.network.Protocol.RoleInfoHandler")
            if RH then
                hook(RH, "send_set_chat_bubble_req", function(orig)
                    return function(bubbleId)
                        local m = safeMod("logic_roleInfo_chatframe")
                        if m and m.ProcChangeRsp then
                            pcall(function() m:ProcChangeRsp(CFG.CHAT_BUBBLE) end)
                        end
                        applyChatState()
                    end
                end)
                hook(RH, "on_set_chat_bubble_rsp", function(orig)
                    return function(ok, bubbleId)
                        if ok ~= 0 then ok = 0 end
                        return orig(0, CFG.CHAT_BUBBLE)
                    end
                end)
                hook(RH, "on_get_chat_bubble_rsp", function(orig)
                    return function(ok, data, cfg)
                        if ok ~= 0 then ok = 0 end
                        data = data or {}
                        data.bubbles = data.bubbles or {}
                        pcall(function()
                            local c = CDataTable.GetTable("ChatEffectCfg")
                            for k, row in pairs(c or {}) do
                                local id = tonumber(row.ID or k)
                                if id and data.bubbles[id] == nil then
                                    data.bubbles[id] = { expire_ts = 0 }
                                end
                            end
                        end)
                        data.equip = CFG.CHAT_BUBBLE
                        return orig(0, data, cfg)
                    end
                end)
            end
        end)
    end

    -- ── TEAM SKIN ──
    local function installTeamSkinHooks()
        pcall(function()
            local m = safeMod("logic_roleInfo_TeamUpFrame")
            if not m then return end
            forceReturn(m, "HasSkin", true)
            forceReturn(m, "IsLocked", false)

            hook(m, "on_get_team_notify_skin_list_rsp", function(orig)
                return function(self, ok, list, curSkin)
                    if ok ~= 0 then ok = 0 end
                    list = list or {}
                    pcall(function()
                        local c = CDataTable.GetTable("TeamUpPopFrame")
                        for k, row in pairs(c or {}) do
                            local id = tonumber(row.ID or k)
                            if id and list[id] == nil then
                                list[id] = { expire_time = 0 }
                            end
                        end
                    end)
                    return orig(self, 0, list, CFG.TEAM_SKIN)
                end
            end)

            hook(m, "on_change_team_notify_skin_rsp", function(orig)
                return function(self, ok, curSkin)
                    if ok ~= 0 then ok = 0 end
                    return orig(self, 0, CFG.TEAM_SKIN)
                end
            end)
        end)
        pcall(function()
            local RH = safeReq("client.network.Protocol.RoleInfoHandler")
            if RH then
                hook(RH, "send_change_team_notify_skin", function(orig)
                    return function(id)
                        local m = safeMod("logic_roleInfo_TeamUpFrame")
                        if m and m.on_change_team_notify_skin_rsp then
                            pcall(function() m:on_change_team_notify_skin_rsp(0, CFG.TEAM_SKIN) end)
                        end
                        applyTeamSkinState()
                    end
                end)
                hook(RH, "on_get_team_notify_skin_list_rsp", function(orig)
                    return function(ok, list, curSkin)
                        if ok ~= 0 then ok = 0 end
                        list = list or {}
                        pcall(function()
                            local c = CDataTable.GetTable("TeamUpPopFrame")
                            for k, row in pairs(c or {}) do
                                local id = tonumber(row.ID or k)
                                if id and list[id] == nil then
                                    list[id] = { expire_time = 0 }
                                end
                            end
                        end)
                        return orig(0, list, CFG.TEAM_SKIN)
                    end
                end)
            end
        end)
    end

    -- ── CARTE FRAME ──
    local function installCarteFrameHooks()
        pcall(function()
            local m = safeMod("logic_roleinfo_carte_frame")
            if not m then return end
            forceReturn(m, "HasCarteFrame",       true)
            forceReturn(m, "IsHaveCarteFrame",    true)
            forceReturn(m, "CheckFrameTimeValid", true)
            forceReturn(m, "GetCurrentCrateFrameBGID", CFG.CARTE_FRAME)

            hook(m, "get_carte_frame_list_rsp", function(orig)
                return function(self, ok, list, cur)
                    if ok ~= 0 then ok = 0 end
                    if self.InitCarteFrameMap then pcall(function() self:InitCarteFrameMap() end) end
                    list = list or {}
                    pcall(function()
                        local c = CDataTable.GetTable("CarteFrameConfig")
                        for k, row in pairs(c or {}) do
                            local id = tonumber(row.SkinID or row.ID or k)
                            if id and list[id] == nil then
                                list[id] = { expire_ts = 0 }
                            end
                        end
                    end)
                    self.CarteFrameMap = self.CarteFrameMap or {}
                    for k in pairs(self.CarteFrameMap) do
                        self.CarteFrameMap[k].bLock     = false
                        self.CarteFrameMap[k].expire_ts = 0
                    end
                    return orig(self, 0, list, CFG.CARTE_FRAME)
                end
            end)

            hook(m, "equip_carte_frame_rsp", function(orig)
                return function(self, ok, frameId, eq)
                    if ok ~= 0 then ok = 0 end
                    return orig(self, 0, CFG.CARTE_FRAME, eq ~= false)
                end
            end)
        end)
        pcall(function()
            local RH = safeReq("client.network.Protocol.RoleInfoHandler")
            if RH then
                hook(RH, "send_equip_carte_frame_req", function(orig)
                    return function(frameId, eq)
                        local m = safeMod("logic_roleinfo_carte_frame")
                        if m and m.equip_carte_frame_rsp then
                            pcall(function() m:equip_carte_frame_rsp(0, CFG.CARTE_FRAME, true) end)
                        end
                        applyCarteFrameState()
                    end
                end)
                hook(RH, "on_get_carte_frame_list_rsp", function(orig)
                    return function(ok, list, cur)
                        if ok ~= 0 then ok = 0 end
                        list = list or {}
                        pcall(function()
                            local c = CDataTable.GetTable("CarteFrameConfig")
                            for k, row in pairs(c or {}) do
                                local id = tonumber(row.SkinID or row.ID or k)
                                if id and list[id] == nil then
                                    list[id] = { expire_ts = 0 }
                                end
                            end
                        end)
                        return orig(0, list, CFG.CARTE_FRAME)
                    end
                end)
            end
        end)
    end

    -- ── ALIAS / TITLE ──
    local function installAliasHooks()
        pcall(function()
            local AS = safeReq("client.slua.logic.roleInfo.logic_roleinfo_title")
            if not AS then return end

            hook(AS, "alias_list_res", function(orig)
                return function(res, list, red, alias)
                    if res ~= 0 then res = 0 end
                    list = list or {}
                    pcall(function()
                        local ENUM = AS.enum_Alias_State_Type or { notHave = 0, have = 1, use = 2 }
                        local c = CDataTable.GetTable("AliasCfg")
                        for k, row in pairs(c or {}) do
                            local id = tonumber(row.ID or row.Id or k)
                            if id then
                                if not list[id] then
                                    list[id] = {
                                        state = ENUM.have, receive_time = 0, expire_ts = 0,
                                        rank = 0, ext_info = "", rank_id = 0,
                                        title = (row and row.AliasName) or "",
                                        nation = "", have_used = 0,
                                    }
                                elseif type(list[id]) == "table" and list[id].state == ENUM.notHave then
                                    list[id].state = ENUM.have
                                end
                            end
                        end
                    end)
                    alias = alias or {}
                    alias.id = CFG.ALIAS_ID
                    if not alias.title or alias.title == "" then
                        local ac = CDataTable.GetTableData("AliasCfg", CFG.ALIAS_ID)
                        alias.title = (ac and ac.AliasName) or ""
                    end
                    local r = orig(res, list, red, alias)
                    applyAliasState()
                    return r
                end
            end)

            hook(AS, "change_alias_req", function(orig)
                return function(id, state)
                    -- Silently apply locally — no server round trip
                    applyAliasState()
                    if AS.change_alias_rsp then
                        pcall(function() AS.change_alias_rsp(0, CFG.ALIAS_ID, 0) end)
                    end
                end
            end)
        end)
        pcall(function()
            local CH = safeReq("client.network.Protocol.CharacterHandler")
            if CH then
                hook(CH, "send_change_alias_req", function(orig)
                    return function(id, state)
                        applyAliasState()
                        local AS = safeReq("client.slua.logic.roleInfo.logic_roleinfo_title")
                        if AS and AS.change_alias_rsp then
                            pcall(function() AS.change_alias_rsp(0, CFG.ALIAS_ID, 0) end)
                        end
                    end
                end)
                hook(CH, "on_alias_list_res", function(orig)
                    return function(res, list, red, alias)
                        if res ~= 0 then res = 0 end
                        list = list or {}
                        pcall(function()
                            local AS = safeReq("client.slua.logic.roleInfo.logic_roleinfo_title")
                            local ENUM = (AS and AS.enum_Alias_State_Type) or { notHave = 0, have = 1, use = 2 }
                            local c = CDataTable.GetTable("AliasCfg")
                            for k, row in pairs(c or {}) do
                                local id = tonumber(row.ID or row.Id or k)
                                if id and not list[id] then
                                    list[id] = {
                                        state = ENUM.have, receive_time = 0, expire_ts = 0,
                                        rank = 0, ext_info = "", rank_id = 0,
                                        title = (row and row.AliasName) or "",
                                        nation = "", have_used = 0,
                                    }
                                end
                            end
                        end)
                        alias = alias or {}
                        alias.id = CFG.ALIAS_ID
                        return orig(res, list, red, alias)
                    end
                end)
                hook(CH, "on_change_alias_rsp", function(orig)
                    return function(res, id, rankId)
                        if res ~= 0 then res = 0 end
                        applyAliasState()
                        return orig(0, CFG.ALIAS_ID, rankId)
                    end
                end)
            end
        end)
    end

    -- ── NAME FRAME / BRAND ──
    local function installNameFrameHooks()
        pcall(function()
            -- Fill nameFrameData silently at first run
            if DataMgr and DataMgr.roleData then
                DataMgr.roleData.nameFrameData = DataMgr.roleData.nameFrameData or {}
                pcall(function()
                    local c = CDataTable.GetTable("NameFrame")
                    for k, row in pairs(c or {}) do
                        local id = tonumber(row.ID or row.Id or k)
                        if id and id > 0 and DataMgr.roleData.nameFrameData[id] == nil then
                            DataMgr.roleData.nameFrameData[id] = { expire_ts = 0, is_used = 0 }
                        end
                    end
                end)
            end

            local m = safeReq("client.slua.logic.person_space.logic_roleinfo_nameframe")
            if m then
                forceReturn(m, "IsValidNameFrame", true)

                hook(m, "use_brand", function(orig)
                    return function(id)
                        applyNameFrameState()
                        if m.use_brand_rsp then
                            pcall(function() m.use_brand_rsp(0, CFG.NAME_FRAME_ID) end)
                        end
                    end
                end)

                hook(m, "use_brand_rsp", function(orig)
                    return function(res, id)
                        if res ~= 0 then res = 0 end
                        return orig(0, CFG.NAME_FRAME_ID)
                    end
                end)
            end

            -- DataMgr.InitRoleData — patch brand selection
            if DataMgr and type(DataMgr.InitRoleData) == "function" then
                hook(DataMgr, "InitRoleData", function(orig)
                    return function(rd)
                        if type(rd) == "table" then
                            rd.brand = rd.brand or {}
                            for k, v in pairs(rd.brand) do
                                if type(v) == "table" then v.is_used = 0 end
                            end
                            rd.brand[CFG.NAME_FRAME_ID] = { is_used = 1, expire_ts = 0 }
                        end
                        local r = orig(rd)
                        pcall(applyNameFrameState)
                        return r
                    end
                end)
            end

            -- RIHandler send_use_brand
            pcall(function()
                local RH = safeReq("client.network.Protocol.RoleInfoHandler")
                if RH then
                    hook(RH, "send_use_brand", function(orig)
                        return function(id)
                            applyNameFrameState()
                            local nm = safeReq("client.slua.logic.person_space.logic_roleinfo_nameframe")
                            if nm and nm.use_brand_rsp then
                                pcall(function() nm.use_brand_rsp(0, CFG.NAME_FRAME_ID) end)
                            end
                        end
                    end)
                    hook(RH, "on_use_brand_rsp", function(orig)
                        return function(res, id)
                            if res ~= 0 then res = 0 end
                            applyNameFrameState()
                            return orig(0, CFG.NAME_FRAME_ID)
                        end
                    end)
                end
            end)
        end)
    end

    -- ── ROLE INFO BG / OPENING / SOCIAL CARD BG ──
    local function installBgOpeningSocialHooks()
        pcall(function()
            local m = safeMod("logic_roleInfo_background")
            if m then
                forceReturn(m, "IsHaveRoleInfoBG", true)
                hook(m, "send_set_social_info_bg_req", function(orig)
                    return function(self, bgId)
                        local key = (ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.RoleInfoBG) or 5
                        if m.on_set_social_info_bg_rsp then
                            pcall(function() m:on_set_social_info_bg_rsp(0, key, CFG.ROLE_INFO_BG) end)
                        end
                        applyRoleInfoBgState()
                    end
                end)
                hook(m, "on_set_social_info_bg_rsp", function(orig)
                    return function(self, res, id)
                        if res ~= 0 then res = 0 end
                        local key = (ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.RoleInfoBG) or id
                        return orig(self, 0, key, CFG.ROLE_INFO_BG)
                    end
                end)
            end
        end)
        pcall(function()
            local m = safeMod("logic_roleInfo_opening")
            if m then
                forceReturn(m, "IsHaveOpeningItem", true)
                hook(m, "send_set_social_info_bg_req", function(orig)
                    return function(self, id)
                        local key = (ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.PersonalOpening) or 6
                        if m.on_set_social_info_bg_rsp then
                            pcall(function() m:on_set_social_info_bg_rsp(0, key, CFG.OPENING) end)
                        end
                        applyOpeningState()
                    end
                end)
                hook(m, "on_set_social_info_bg_rsp", function(orig)
                    return function(self, res, id)
                        if res ~= 0 then res = 0 end
                        local key = (ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.PersonalOpening) or id
                        return orig(self, 0, key, CFG.OPENING)
                    end
                end)
            end
        end)
        pcall(function()
            local m = safeMod("logic_social_card_bg")
            if m then
                forceReturn(m, "IsHaveCardSkin", true)
                hook(m, "send_set_social_card_floor_req", function(orig)
                    return function(self, id)
                        m.CurrentSocialCardBGID = CFG.SOCIAL_CARD_BG
                        if m.on_notify_social_card_floor then
                            pcall(function() m:on_notify_social_card_floor(CFG.SOCIAL_CARD_BG) end)
                        end
                        if m.on_set_social_card_floor_rsp then
                            pcall(function() m:on_set_social_card_floor_rsp(0) end)
                        end
                        applySocialCardState()
                    end
                end)
                hook(m, "on_set_social_card_floor_rsp", function(orig)
                    return function(self, res)
                        if res ~= 0 then res = 0 end
                        return orig(self, 0)
                    end
                end)
            end
        end)

        -- Network-layer intercepts
        pcall(function()
            local RGB = safeReq("client.network.Protocol.RoleInfoBGHandler")
            if not RGB then return end
            hook(RGB, "send_set_social_info_bg_req", function(orig)
                return function(subtype, bgId)
                    local RB = ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.RoleInfoBG
                    local OP = ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.PersonalOpening
                    if RB and subtype == RB then
                        local m = safeMod("logic_roleInfo_background")
                        if m and m.on_set_social_info_bg_rsp then
                            pcall(function() m:on_set_social_info_bg_rsp(0, subtype, CFG.ROLE_INFO_BG) end)
                        end
                        applyRoleInfoBgState()
                    elseif OP and subtype == OP then
                        local m = safeMod("logic_roleInfo_opening")
                        if m and m.on_set_social_info_bg_rsp then
                            pcall(function() m:on_set_social_info_bg_rsp(0, subtype, CFG.OPENING) end)
                        end
                        applyOpeningState()
                    end
                end
            end)
            hook(RGB, "on_notify_social_info_bg", function(orig)
                return function(bgIds)
                    if type(bgIds) == "table" then
                        if ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.RoleInfoBG then
                            bgIds[ENUM_ITEM_SUBTYPE.RoleInfoBG] = CFG.ROLE_INFO_BG
                        end
                        if ENUM_ITEM_SUBTYPE and ENUM_ITEM_SUBTYPE.PersonalOpening then
                            bgIds[ENUM_ITEM_SUBTYPE.PersonalOpening] = CFG.OPENING
                        end
                    end
                    local r = orig(bgIds)
                    applyRoleInfoBgState()
                    applyOpeningState()
                    return r
                end
            end)
        end)
        pcall(function()
            local SCBG = safeReq("client.network.Protocol.SocialCardBGHandler")
            if not SCBG then return end
            hook(SCBG, "send_set_social_card_floor_req", function(orig)
                return function(id)
                    local m = safeMod("logic_social_card_bg")
                    if m then
                        m.CurrentSocialCardBGID = CFG.SOCIAL_CARD_BG
                        if m.on_notify_social_card_floor then
                            pcall(function() m:on_notify_social_card_floor(CFG.SOCIAL_CARD_BG) end)
                        end
                        if m.on_set_social_card_floor_rsp then
                            pcall(function() m:on_set_social_card_floor_rsp(0) end)
                        end
                    end
                    applySocialCardState()
                end
            end)
            hook(SCBG, "on_notify_social_card_floor", function(orig)
                return function(id)
                    local r = orig(CFG.SOCIAL_CARD_BG)
                    applySocialCardState()
                    return r
                end
            end)
            hook(SCBG, "on_set_social_card_floor_rsp", function(orig)
                return function(res)
                    if res ~= 0 then res = 0 end
                    local r = orig(0)
                    applySocialCardState()
                    return r
                end
            end)
        end)
    end

    -- ── RANK ──
    local function installRankHooks()
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
            local SH = safeReq("client.network.Protocol.SeasonHandler")
            if SH and tonumber(CFG.RANK_SEGMENT) == 801 then
                pcall(function() SH.rank_rating = getStarRating() end)
            end
        end)
    end

    -- ── BADGE ──
    local function installBadgeHooks()
        pcall(function()
            local SYearUtil = safeReq("client.logic.season_year.util.season_year_util")
            if SYearUtil then
                forceReturn(SYearUtil, "CheckFunctionIsOpen", true)
            end

            local m = safeMod("logic_season_year_badge")
            if m then
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
            end

            local BU = safeReq("client.logic.season_year.util.season_year_badge_util")
            if BU then
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
            end
        end)
    end

    -- ── COLLECT ──
    local function installCollectHooks()
        pcall(function()
            local m = safeMod("collect_module")
            if not m then return end
            hook(m, "GetLevelDataByScore", function(orig)
                return function(self, score, isSeason)
                    if score and score >= CFG.COLLECT_SCORE - 1 then
                        return CFG.COLLECT_LEVEL, "", 100
                    end
                    return orig(self, score, isSeason)
                end
            end)
            hook(m, "GetSeasonLevelByScore", function(orig)
                return function(self, score, seasonId)
                    if score and score >= CFG.COLLECT_SCORE - 1 then
                        return CFG.COLLECT_LEVEL, true, ""
                    end
                    return orig(self, score, seasonId)
                end
            end)
            hook(m, "GetCollectScoreByCollectData", function(orig)
                return function(self, cd)
                    if cd and cd.total_score and cd.total_score >= CFG.COLLECT_SCORE - 1 then
                        return CFG.COLLECT_SCORE, CFG.COLLECT_SCORE
                    end
                    return orig(self, cd)
                end
            end)
            hook(m, "GetCollectScoreByProfile", function(orig)
                return function(self, profile)
                    if profile and tonumber(profile.uid) == getUID() then
                        return CFG.COLLECT_SCORE, CFG.COLLECT_SCORE
                    end
                    return orig(self, profile)
                end
            end)
        end)
    end

    -- ═══════════════════════════════════════════════════════════════
    -- EVENT REFRESH (silent)
    -- ═══════════════════════════════════════════════════════════════
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
                if EVENTID_ROLEINFO_USE_NAME_FRAME then
                    fireEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_USE_NAME_FRAME, CFG.NAME_FRAME_ID)
                end
                if EVENTID_ROLEINFO_UPDATE_ROLEINFO then
                    fireEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_ROLEINFO)
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

    -- ═══════════════════════════════════════════════════════════════
    -- INSTALL + BOOT
    -- ═══════════════════════════════════════════════════════════════
    local installed = false
    local function installAll()
        if installed then return true end
        installAvatarHooks()
        installFrameHooks()
        installNicknameHooks()
        installChatHooks()
        installTeamSkinHooks()
        installCarteFrameHooks()
        installAliasHooks()
        installNameFrameHooks()
        installBgOpeningSocialHooks()
        installRankHooks()
        installBadgeHooks()
        installCollectHooks()
        installed = true
        return true
    end

    local booted = false
    local function boot()
        if booted then return true end
        if not DataMgr or not DataMgr.roleData then return false end
        if not DataMgr.roleData.uid then return false end
        installAll()
        applyAll()
        fireRefreshEvents()
        booted = true
        return true
    end

    local tries = 0
    local function tryBoot()
        tries = tries + 1
        if boot() then
            print("[RoxzProfile v2] Booted on try #" .. tries)
            return
        end
        if tries >= 60 then
            print("[RoxzProfile v2] Boot FAILED after " .. tries .. " tries")
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

    -- Periodic silent re-apply (lobby only, 8s) — does NOT fire events
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
                    applyAll()  -- state only, no events = no popup
                end)
            end, -1, 8.0)
        end
    end)

    -- Event-driven re-apply
    pcall(function()
        if not EventSystem then return end
        local function onRefresh()
            pcall(function()
                if not booted then return end
                applyAll()
                fireRefreshEvents()
            end)
        end
        if EVENTTYPE_LOBBY and EVENTID_SHOW_LOBBY then
            EventSystem:registEvent(EVENTTYPE_LOBBY, EVENTID_SHOW_LOBBY, onRefresh)
        end
        if EVENTTYPE_LOGIN_ROLEDATA and EVENTID_LOGIN_ROLEDATA_SYNC then
            EventSystem:registEvent(EVENTTYPE_LOGIN_ROLEDATA, EVENTID_LOGIN_ROLEDATA_SYNC, onRefresh)
        end
    end)

    _G.RoxzProfile = {
        Apply = applyAll,
        Config = CFG,
        Refresh = function()
            applyAll()
            fireRefreshEvents()
        end,
    }

    print("[RoxzProfile v2] Loaded — Conqueror " .. CFG.RANK_SEGMENT .. " / " .. CFG.RANK_STARS .. " stars / Badge " .. CFG.JOURNEY_BADGE_LEVEL)
end)
