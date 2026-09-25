-- ═══════════════════════════════════════════════════════════════════
-- sd_v7.lua — SHOWROOM FIXED + FAKE DRAW REWRITTEN
--   FIX 1: Aggressive auto-hook removed (caused X marks + lock spam)
--   FIX 2: Force player level + manor_switch (unlock home gate)
--   FIX 3: Fake draw — skip server, fabricate local response
--   FIX 4: Read-only observation first, targeted override only
-- ═══════════════════════════════════════════════════════════════════

_G._SD = _G._SD or { booted = false, phase = "unknown", log = {} }

local CFG = {
    BRAND = "SD v7",
    DUMP_FILE = "sd_v7_log_",
    SAVE_DIRS = {
        "/storage/emulated/0/Android/data/com.pubg.imobile/files/",
        "/storage/emulated/0/Android/data/com.pubg.krmobile/files/",
        "/storage/emulated/0/Android/data/com.pubg.vng.pubgmobile/files/",
        "/storage/emulated/0/Android/data/com.vng.pubgmobile/files/",
        "/storage/emulated/0/Android/data/com.rekoo.pubgm/files/",
        "/sdcard/",
    },
    SAVE_KEY = "config.ini",
    SHOW_POPUPS = true,
    TICK = 2.0,
    UC_AMOUNT = 999999999,
    FORCE_LEVEL = 99,
}

-- ═══ POPUP ═══
local function POPUP(t, m)
    if not CFG.SHOW_POPUPS then return end
    pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
                    or require("client.slua.logic.common.logic_common_msg_box")
        if Msg and Msg.Show then Msg.Show(4, tostring(t), tostring(m)) end
    end)
end

-- ═══ LOG ═══
local _PATH = nil
local function RESOLVE()
    local ts = os.date("%Y%m%d_%H%M%S")
    local name = CFG.DUMP_FILE .. ts .. ".txt"
    for _, d in ipairs(CFG.SAVE_DIRS) do
        local f = io.open(d .. CFG.SAVE_KEY, "r")
        if f then f:close()
            local w = io.open(d .. name, "a"); if w then w:close(); return d .. name end
        end
    end
    for _, d in ipairs(CFG.SAVE_DIRS) do
        local w = io.open(d .. name, "a"); if w then w:close(); return d .. name end
    end
    return nil
end
local function W(line)
    local full = "[" .. os.date("%H:%M:%S") .. "] " .. tostring(line)
    _G._SD.log[#_G._SD.log+1] = full
    if _PATH then
        pcall(function()
            local f = io.open(_PATH, "a"); if f then f:write(full .. "\n"); f:close() end
        end)
    end
    print("[SD] " .. full)
end

-- ═══ UTILS ═══
local function GM(p)
    local m = package.loaded[p]; if m then return m end
    local ok, r = pcall(require, p); if ok then return r end
    return nil
end
local function UNWRAP(m)
    if not m then return nil, false end
    if type(m) == "table" and type(m.__inner_impl) == "table" then return m.__inner_impl, true end
    return m, false
end
local function FIND(path, subsys)
    local m = GM(path)
    if m then local u, was = UNWRAP(m); W("[FIND] " .. path .. (was and " (unwrapped)" or "")); return u end
    local ok, cls = pcall(import, path)
    if ok and cls then local u, was = UNWRAP(cls); W("[FIND] " .. path .. " via import" .. (was and " (unwrapped)" or "")); return u end
    if subsys then
        local ok2, SM = pcall(require, "GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if ok2 and SM and SM.Get then
            local ok3, s = pcall(function() return SM:Get(subsys) end)
            if ok3 and s then W("[FIND] " .. path .. " via Subsys:" .. subsys); return (UNWRAP(s)) end
        end
    end
    W("[FIND] " .. path .. " ✗")
    return nil
end
local function OV(owner, name, newfn)
    if not owner then return false end
    local ok, t = pcall(function() return type(owner[name]) end)
    if not ok or t ~= "function" then return false end
    return pcall(function() owner[name] = newfn end)
end
local function HK(owner, name, tag, cb)
    if not owner then return false end
    local ok, tagv = pcall(function() return owner[tag] end)
    if ok and tagv then return true end
    local ok2, t = pcall(function() return type(owner[name]) end)
    if not ok2 or t ~= "function" then return false end
    local ok3, orig = pcall(function() return owner[name] end)
    if not ok3 then return false end
    return pcall(function()
        owner[tag] = true
        owner[name] = function(self, ...) pcall(cb, self, ...); return orig(self, ...) end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- FIX 1 — PLAYER LEVEL + MANOR UNLOCK (removes "Home not unlocked")
-- ═══════════════════════════════════════════════════════════════════

local function FORCE_PLAYER_LEVEL()
    local dm = _G.DataMgr
    if not dm or not dm.roleData then W("[LVL] roleData nil"); return end
    local rd = dm.roleData
    pcall(function()
        local old = rd.level
        rd.level = CFG.FORCE_LEVEL
        W("[LVL] player level: " .. tostring(old) .. " → " .. CFG.FORCE_LEVEL)
    end)
    pcall(function()
        if rd.manor_switch then
            local oldLvl = rd.manor_switch.open_level
            rd.manor_switch.open_level = 1
            W("[LVL] manor_switch.open_level: " .. tostring(oldLvl) .. " → 1")
        end
    end)
    pcall(function()
        if rd.brief_collect_hall_data then
            local old = rd.brief_collect_hall_data.hall_level
            rd.brief_collect_hall_data.hall_level = 999
            W("[LVL] hall_level: " .. tostring(old) .. " → 999")
        end
    end)
    pcall(function()
        rd.pve_level = 999
        rd.roleExp = 999999
        rd.newbie_points = 99999
    end)
end

-- Hook roleData.level getter via metatable fallback
local function HOOK_ROLEDATA_LEVEL()
    local dm = _G.DataMgr
    if not dm then return end
    pcall(function()
        local mt = getmetatable(dm) or {}
        local oldIdx = mt.__index
        mt.__index = function(t, k)
            if k == "level" then return CFG.FORCE_LEVEL end
            if type(oldIdx) == "function" then return oldIdx(t, k) end
            if type(oldIdx) == "table" then return oldIdx[k] end
            return rawget(t, k)
        end
        setmetatable(dm, mt)
    end)
    -- Also hook roleData itself
    pcall(function()
        if dm.roleData then
            local mt = getmetatable(dm.roleData) or {}
            local oldIdx = mt.__index
            mt.__index = function(t, k)
                if k == "level" then return CFG.FORCE_LEVEL end
                if type(oldIdx) == "function" then return oldIdx(t, k) end
                if type(oldIdx) == "table" then return oldIdx[k] end
                return rawget(t, k)
            end
            setmetatable(dm.roleData, mt)
        end
    end)
    W("[LVL] roleData.level metatable hooked")
end

-- ═══════════════════════════════════════════════════════════════════
-- FIX 2 — SHOWROOM SLOTS (TARGETED — no aggressive override)
-- Only hook genuine "should I unlock" checks, NOT count/list/valid
-- ═══════════════════════════════════════════════════════════════════

local function HOOK_SHOWROOM_TARGETED()
    W("═══ SHOWROOM TARGETED ═══")

    -- SkinSlotUnlock — the specific unlock flag
    local ssc = FIND("GameLua.Mod.PlanCH.Client.SubSystem.HallData.PlanCH_SkinSlotUnlock_Config",
                     "PlanCH_SkinSlotUnlock_Config")
    if ssc then
        local n = 0
        -- ONLY these are safe to override:
        if OV(ssc, "IsSlotUnlock", function() return true end) then n = n + 1 end
        if OV(ssc, "IsPaySlot", function() return false end) then n = n + 1 end
        if OV(ssc, "GetUnlockNextSlotCost", function() return 0 end) then n = n + 1 end
        if OV(ssc, "ShowPayToUnlockSlotUI", function() end) then n = n + 1 end
        -- Do NOT hook GetAllSlotCount/GetAllSlotList/GetUnlockSlotCount — that broke rendering
        W("[SLOT] targeted: " .. n .. " overrides")
    end

    -- SkinHallPart — DO NOT override slot counts. Only log.
    local shpc = FIND("GameLua.Mod.PlanCH.Client.SubSystem.HallData.PlanCH_SkinHallPart_Config")
    if shpc then
        HK(shpc, "GetHallPartSlotList", "_sd_sr_hpsl", function(self, ...)
            W("[HALLPART] GetHallPartSlotList called")
        end)
        W("[HALLPART] observed")
    end

    -- Force hall data to be "opened"
    local hd = FIND("GameLua.Mod.PlanCH.Client.SubSystem.HallData.PlanCH_HallData_Client")
    if hd then
        HK(hd, "OnHallLevelChanged", "_sd_sr_lvlchg", function(self, ...)
            W("[HALLDATA] level changed → forcing")
            pcall(FORCE_PLAYER_LEVEL)
        end)
        W("[HALLDATA] hooked")
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- FIX 3 — FAKE DRAW v2 — skip server, fabricate local response
-- Approach: hook the request, call the response with fake success
-- ═══════════════════════════════════════════════════════════════════

-- Generic reward list (these are common test IDs, will show popup)
local FALLBACK_REWARDS = {
    { resid = 403003,  count = 1 },  -- silver fragment
    { resid = 101001,  count = 1 },  -- clothing
    { resid = 401001,  count = 1 },
}

local function SHOW_REWARD(list)
    pcall(function()
        local LG = GM("client.slua.logic.common.CommonItemGet.Logic_CommonItemGet")
        if not LG or not LG.ShowPanel_DefaultStyle then
            W("[DRAW] Logic_CommonItemGet missing")
            return false
        end
        local formatted = {}
        for _, it in ipairs(list or {}) do
            formatted[#formatted+1] = {
                res_id = tonumber(it.resid or it.resID or it.itemid or it.res_id or 0) or 0,
                count  = tonumber(it.count or 1) or 1,
                valid_hours = tonumber(it.valid_hours or 0) or 0,
            }
        end
        LG.ShowPanel_DefaultStyle(formatted, false, true)
        W("[DRAW] ✓ panel shown (" .. #formatted .. " items)")
        return true
    end)
    return false
end

local function PICK_REWARD(mod)
    if not mod then return nil end
    local pool = {}
    for _, key in ipairs({ "poolItemConfig","dropList","pool_info","AwardPoolConfig",
                           "CurSmallAwardPoolConfig","CurBigAwardPoolConfig",
                           "totalDrawAwardConfig","items","Items","itemList",
                           "awardItemList","rewardList","poolList" }) do
        local t = mod[key]
        if type(t) == "table" then
            for _, v in ipairs(t) do pool[#pool+1] = v end
        end
    end
    if #pool == 0 then return nil end
    return pool[math.random(1, #pool)]
end

local function BUILD_REWARD_LIST(mod, count)
    local out = {}
    for i = 1, count do
        local pick = PICK_REWARD(mod)
        if pick then
            local res = pick.resid or pick.resID or pick.itemid or pick.res_id or pick.ItemID or pick.item_id
            if res then
                out[#out+1] = { resid = tonumber(res), count = tonumber(pick.count or 1) or 1 }
            end
        end
        if #out < i then
            out[#out+1] = FALLBACK_REWARDS[math.random(1, #FALLBACK_REWARDS)]
        end
    end
    return out
end

-- Fake draw runner — call this when user clicks draw
local function RUN_FAKE_DRAW(mod, tag, is_ten)
    local count = is_ten and 10 or 1
    local rewards = BUILD_REWARD_LIST(mod, count)
    W("[DRAW:" .. tag .. "] fake " .. count .. " rewards — showing panel")
    SHOW_REWARD(rewards)
end

-- List of draw modules with request→response handler pairs
-- If we can find on_xxx_rsp, we call it directly after fabricating
local DRAW_TARGETS = {
    { tag="luckyback",   p="client.slua.logic.lobby_activity.logic_luckyback_activity",
      req={"do_one_draw_back_by_activity_req","do_one_draw_by_tick","get_sum_draw_award_by_activity_req"} },
    { tag="luckydouble", p="client.slua.logic.lobby_activity.logic_luckydouble_activity",
      req={"send_do_one_lucky_double_draw_by_activity_req","send_double_draw_on_shot_req"} },
    { tag="luckyunback", p="client.slua.logic.lobby_activity.logic_luckyunback_activity",
      req={"send_do_draw_discount_by_activity_req"} },
    { tag="luckmix",     p="client.slua.logic.lobby_activity.logic_luckmix_activity",
      req={"DoDraw"} },
    { tag="luckymulti",  p="client.slua.logic.lobby_activity.logic_luckymulti_activity",
      req={"Lottery"} },
    { tag="scrapgold",   p="client.slua.logic.lobby_activity.logic_scrapgold_draw",
      req={"DoDraw"} },
    { tag="godzilla",    p="client.slua.logic.lobby_activity.logic_godzilla_ban",
      req={"OneDraw","TenDraw"} },
    { tag="optional",    p="client.slua.logic.lobby_activity.LukcyOptionalTurntable.Logic_LukcyOptionalTurntable",
      req={"SendDrawActReq"} },
    { tag="tarot",       p="client.slua.logic.tarot_card.logic_tarotcard_drawcard",
      req={"DoDraw"} },
    { tag="airdrop",     p="client.slua.logic.lobby_activity.logic_super_airdrop",
      req={"send_choose_and_get_super_airdrop_reward_req"} },
    { tag="xsuit_act",   p="client.slua.logic.XSuit.logic_xsuit_activity",
      req={"send_do_draw_act_req","send_get_accumulate_pool_reward_req"} },
    { tag="ladder",      p="client.slua.logic.lobby_activity.logic_ladder_draw",
      req={"OnRotateRsp","OnRandomAwardRsp","OnRecvAwardRsp"} },
    { tag="supply_chst", p="client.slua.logic.supply.supply_collect_chest_manager",
      req={"OpenCollectChest"} },
    { tag="treasure",    p="client.slua.logic.store.treasure_chest_manager",
      req={"OpenTreasureChest"} },
    { tag="supply_opt",  p="client.slua.logic.store.supply_optional_chest_manager",
      req={"OpenOptionalChest"} },
}

local function HOOK_FAKE_DRAW()
    W("═══ FAKE DRAW v2 ═══")
    local mods_ok, hooks = 0, 0
    for _, entry in ipairs(DRAW_TARGETS) do
        local mod = GM(entry.p)
        if mod then
            mods_ok = mods_ok + 1
            for _, fn in ipairs(entry.req) do
                local tag = "_sd_v7_" .. entry.tag .. "_" .. fn
                if type(mod[fn]) == "function" and not mod[tag] then
                    if pcall(function()
                        mod[tag] = true
                        -- DO NOT call orig — skip server, show panel
                        mod[fn] = function(self, ...)
                            W("[DRAW] " .. entry.tag .. "." .. fn .. " INTERCEPTED")
                            local is_ten = string.lower(fn):find("ten") ~= nil
                            pcall(RUN_FAKE_DRAW, mod, entry.tag, is_ten)
                            -- Try calling corresponding rsp for UI update
                            pcall(function()
                                local rsp_names = { "on_" .. fn:gsub("^send_",""):gsub("_req$","_rsp"),
                                                    "on_" .. fn:gsub("_req$","_rsp") }
                                for _, rn in ipairs(rsp_names) do
                                    if type(mod[rn]) == "function" then
                                        pcall(mod[rn], self, 0, {})
                                        break
                                    end
                                end
                            end)
                        end
                    end) then
                        hooks = hooks + 1
                    end
                end
            end
        else
            W("[DRAW] " .. entry.tag .. " ✗ not loaded")
        end
    end
    W("DRAW: " .. mods_ok .. " modules, " .. hooks .. " hooks")
    _G._SD.draw_mods = mods_ok
    _G._SD.draw_hooks = hooks
end

-- ═══════════════════════════════════════════════════════════════════
-- CURRENCY SPOOF (already worked — keep)
-- ═══════════════════════════════════════════════════════════════════

local CURRENCY_KEYS = { "ticket","uc","gold","diamond","eternal_diamond","home_coin","bp","coupon","voucher","UC","Gold","Diamond" }

local function SPOOF_CURRENCY()
    local dm = _G.DataMgr
    if not dm then return end
    pcall(function()
        for _, k in ipairs(CURRENCY_KEYS) do dm[k] = CFG.UC_AMOUNT end
    end)
    pcall(function()
        local mt = getmetatable(dm) or {}
        local oldIdx = mt.__index
        mt.__index = function(t, k)
            for _, key in ipairs(CURRENCY_KEYS) do if k == key then return CFG.UC_AMOUNT end end
            if type(oldIdx) == "function" then return oldIdx(t, k) end
            if type(oldIdx) == "table" then return oldIdx[k] end
            return rawget(t, k)
        end
        setmetatable(dm, mt)
    end)
    W("[CURR] spoofed")
end

local function BYPASS_PAY()
    local pb = GM("client.slua.logic.common.Payclass.logic_common_pay_box")
    if pb then
        OV(pb, "ShowUcRechargeMsg", function() return true end)
        OV(pb, "ShowRechargeMsg", function() return true end)
    end
    local qr = GM("client.module_framework.CommonModuleConfig.QRcodeRestrictManager")
    if qr then
        OV(qr, "CheckUCRestrict", function() return false end)
        OV(qr, "IsRestrictUC", function() return false end)
        OV(qr, "ShowRestrictTips", function() end)
    end
    W("[PAY] bypass")
end

-- ═══════════════════════════════════════════════════════════════════
-- NET — skip edit reqs, apply local
-- ═══════════════════════════════════════════════════════════════════

local function HOOK_NET()
    local h = GM("client.network.Protocol.CollectionHallEditHandler")
    if h then
        if type(h.send_edit_collect_hall_req) == "function" then
            h.send_edit_collect_hall_req = function(self, ...)
                local a = { ... }
                W("[NET] edit SKIP")
                pcall(function()
                    if h.on_edit_collect_hall_rsp then h.on_edit_collect_hall_rsp(0, a[1] or {}, a[2] or 0) end
                end)
            end
        end
        if type(h.send_set_collect_hall_common_equipment_req) == "function" then
            h.send_set_collect_hall_common_equipment_req = function(self, ...)
                pcall(function()
                    if h.on_set_collect_hall_common_equipment_rsp then h.on_set_collect_hall_common_equipment_rsp(0, {}, {}, 0) end
                end)
            end
        end
        W("[NET] wired")
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- MASTER
-- ═══════════════════════════════════════════════════════════════════

function HOOK_ALL()
    W("═══ RE-ARM ═══")
    pcall(FORCE_PLAYER_LEVEL)
    pcall(HOOK_ROLEDATA_LEVEL)
    pcall(HOOK_SHOWROOM_TARGETED)
    pcall(HOOK_FAKE_DRAW)
    pcall(SPOOF_CURRENCY)
    pcall(BYPASS_PAY)
    pcall(HOOK_NET)
    W("═══ DONE ═══")
end

-- ═══════════════════════════════════════════════════════════════════
-- BOOT
-- ═══════════════════════════════════════════════════════════════════

local function GETCHAR()
    local ok, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if ok and GD and GD.GetPlayerCharacter then
        local c = GD.GetPlayerCharacter()
        if c and slua.isValid(c) then return c end
    end
    return nil
end

local function BOOT()
    if _G._SD.booted then return end
    _G._SD.booted = true
    _PATH = RESOLVE()
    W("═══════════════════════════")
    W("  SD v7 — session")
    W("  Log: " .. tostring(_PATH))
    W("═══════════════════════════")
    pcall(HOOK_ALL)
    POPUP("★ SD v7 ★", "Level force + draw fix.\nTest showroom + draw + UC.")
    W("Boot complete")
end

local function PHASE()
    local p = "unknown"
    pcall(function()
        if GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity() then p = "lobby" end
        if GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus() then p = "match" end
    end)
    return p
end

local _last_phase = "unknown"
local function WATCH()
    if not _G._SD.booted then
        if GETCHAR() then pcall(BOOT) end
        return
    end
    local p = PHASE()
    if p ~= _last_phase then
        _last_phase = p
        _G._SD.phase = p
        W("[PHASE] → " .. p)
        if p == "lobby" then pcall(HOOK_ALL) end
    end
end

-- ═══ MANUAL ═══
_G.SD_Status     = function() W("── STATUS ──"); W("booted=" .. tostring(_G._SD.booted) .. " phase=" .. PHASE()); W("draw_mods=" .. tostring(_G._SD.draw_mods or 0) .. " hooks=" .. tostring(_G._SD.draw_hooks or 0)); print("[SD] dumped") end
_G.SD_HookNow    = function() pcall(HOOK_ALL); W("[MANUAL] re-arm") end
_G.SD_ForceLevel = function() FORCE_PLAYER_LEVEL(); W("[MANUAL] level") end
_G.SD_TestDraw   = function() SHOW_REWARD({ { resid = 403003, count = 1 } }); W("[MANUAL] test draw") end

do
    local ok, tk = pcall(require, "common.time_ticker")
    if ok and tk and tk.AddTimerLoop then
        tk.AddTimerLoop(0, WATCH, -1, CFG.TICK)
        W("[WATCHDOG] armed")
    else
        pcall(WATCH)
    end
end

print("[sd_v7.lua] loaded")
