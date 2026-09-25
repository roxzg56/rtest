-- ═══════════════════════════════════════════════════════════════════
-- sd_v12.lua — CONSOLIDATED WORKING
--   UC spoof (from v8 - WORKED)
--   Level force (from v8 - WORKED)
--   Draw hook (from v8 - WORKED) + v11 deep pool
--   Showroom padlock visual hide (light - no X marks)
-- ═══════════════════════════════════════════════════════════════════

_G._SD = _G._SD or { booted = false, log = {} }

local CFG = {
    BRAND = "SD v12",
    DUMP_FILE = "sd_v12_log_",
    SAVE_DIRS = {
        "/storage/emulated/0/Android/data/com.pubg.imobile/files/",
        "/storage/emulated/0/Android/data/com.pubg.krmobile/files/",
        "/storage/emulated/0/Android/data/com.pubg.vng.pubgmobile/files/",
        "/storage/emulated/0/Android/data/com.vng.pubgmobile/files/",
        "/storage/emulated/0/Android/data/com.rekoo.pubgm/files/",
        "/sdcard/",
    },
    SAVE_KEY = "config.ini",
    TICK = 2.0,
    UC = 999999999,
}

local function POPUP(t, m)
    pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
                    or require("client.slua.logic.common.logic_common_msg_box")
        if Msg and Msg.Show then Msg.Show(4, tostring(t), tostring(m)) end
    end)
end

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
    if _PATH then pcall(function()
        local f = io.open(_PATH, "a"); if f then f:write(full .. "\n"); f:close() end
    end) end
    print("[SD] " .. full)
end

local function GM(p)
    local m = package.loaded[p]; if m then return m end
    local ok, r = pcall(require, p); if ok then return r end
    return nil
end
local function UNWRAP(m)
    if not m then return nil end
    if type(m) == "table" and type(m.__inner_impl) == "table" then return m.__inner_impl end
    return m
end
local function HK(owner, name, tag, cb)
    if not owner then return false end
    local ok, tv = pcall(function() return owner[tag] end)
    if ok and tv then return true end
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
-- 1. UC SPOOF — WORKING VERSION FROM V8 (this is critical — restores draw)
-- ═══════════════════════════════════════════════════════════════════

local CURRENCY_KEYS = {
    "ticket","uc","gold","diamond","eternal_diamond","home_coin","bp","coupon","voucher",
    "UC","Gold","Diamond","silver","coin","key","epic","elite",
}

local function SPOOF_CURRENCY()
    local dm = _G.DataMgr
    if not dm then W("[CURR] DataMgr nil"); return end

    -- Direct field set
    pcall(function()
        for _, k in ipairs(CURRENCY_KEYS) do
            dm[k] = CFG.UC
        end
    end)

    -- Metatable fallback
    pcall(function()
        local mt = getmetatable(dm) or {}
        local oldIdx = mt.__index
        mt.__index = function(t, k)
            for _, key in ipairs(CURRENCY_KEYS) do
                if k == key then return CFG.UC end
            end
            if type(oldIdx) == "function" then return oldIdx(t, k) end
            if type(oldIdx) == "table" then return oldIdx[k] end
            return rawget(t, k)
        end
        setmetatable(dm, mt)
    end)

    -- GetUserData hook (this is the one that actually matters)
    pcall(function()
        if dm.GetUserData and not dm._sd12_gu then
            dm._sd12_gu = true
            local orig = dm.GetUserData
            dm.GetUserData = function(arg1)
                local d = orig(arg1)
                if d then
                    for _, k in ipairs(CURRENCY_KEYS) do
                        pcall(function() d[k] = CFG.UC end)
                    end
                end
                return d
            end
        end
    end)

    -- Also hook GetUserData on other likely entry points
    pcall(function()
        local dmMod = GM("client.slua.logic.data.DataMgr") or GM("client.logic.data.DataMgr")
        if dmMod and type(dmMod) == "table" then
            for k, v in pairs(dmMod) do
                if type(k) == "string" and string.find(string.lower(k), "getuserdata", 1, true) then
                    -- already hooked
                end
            end
        end
    end)

    W("[CURR] spoofed → " .. CFG.UC)
end

-- ═══════════════════════════════════════════════════════════════════
-- 2. LEVEL FORCE
-- ═══════════════════════════════════════════════════════════════════

local function FORCE_LEVEL()
    local dm = _G.DataMgr
    if not dm or not dm.roleData then return end
    pcall(function()
        dm.roleData.level = 99
        if dm.roleData.manor_switch then dm.roleData.manor_switch.open_level = 1 end
        if dm.roleData.brief_collect_hall_data then
            dm.roleData.brief_collect_hall_data.hall_level = 100
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- 3. PAY BYPASS
-- ═══════════════════════════════════════════════════════════════════

local function BYPASS_PAY()
    local pb = GM("client.slua.logic.common.Payclass.logic_common_pay_box")
    if pb then
        pcall(function() pb.ShowUcRechargeMsg = function() return true end end)
        pcall(function() pb.ShowRechargeMsg = function() return true end end)
    end
    local qr = GM("client.module_framework.CommonModuleConfig.QRcodeRestrictManager")
    if qr then
        pcall(function() qr.CheckUCRestrict = function() return false end end)
        pcall(function() qr.IsRestrictUC = function() return false end end)
        pcall(function() qr.ShowRestrictTips = function() end end)
    end
    W("[PAY] bypass")
end

-- ═══════════════════════════════════════════════════════════════════
-- 4. DEEP POOL EXTRACTOR (from v11)
-- ═══════════════════════════════════════════════════════════════════

local RES_KEYS = { "resid","resID","res_id","itemid","itemID","item_id","ItemID","ItemId","award_item_id","awardItemId","reward_id","id" }
local CNT_KEYS = { "count","item_count","item_num","itemCount","num","award_item_num" }

local function RID(t)
    if type(t) ~= "table" then return nil end
    for _, k in ipairs(RES_KEYS) do
        if t[k] then local n = tonumber(t[k]); if n and n > 0 then return n end end
    end
    return nil
end
local function RCNT(t)
    if type(t) ~= "table" then return 1 end
    for _, k in ipairs(CNT_KEYS) do
        if t[k] then local n = tonumber(t[k]); if n and n > 0 then return n end end
    end
    return 1
end

local function DEEP(t, out, depth, seen)
    depth = depth or 0; seen = seen or {}
    if depth > 6 or type(t) ~= "table" or seen[t] then return end
    seen[t] = true
    local id = RID(t)
    if id then out[#out+1] = { resid = id, count = RCNT(t) } end
    for _, v in pairs(t) do
        if type(v) == "table" then DEEP(v, out, depth + 1, seen) end
    end
end

local PRIORITY_KEYS = {
    "poolItemConfig","CurAwardPoolConfig","CurSmallAwardPoolConfig","CurBigAwardPoolConfig",
    "AwardPoolConfig","totalDrawAwardConfig","dropList","pool_info","items","Items",
    "itemList","awardItemList","rewardList","poolList","draw_info","drawInfo","poolInfo",
    "prizeList","awardList","showList","itemInfos","itemInfoList"
}

local function EXTRACT_POOL(mod)
    if not mod then return {} end
    local found = {}
    for _, key in ipairs(PRIORITY_KEYS) do
        if type(mod[key]) == "table" then DEEP(mod[key], found) end
    end
    if #found == 0 then
        for k, v in pairs(mod) do
            if type(v) == "table" and not string.find(tostring(k), "__") then
                DEEP(v, found, 0, nil)
            end
        end
    end
    return found
end

local function IS_OWNED(resid)
    resid = tonumber(resid); if not resid then return false end
    local owned = false
    pcall(function()
        local dc = GM("client.slua.logic.wardrobe.logic_wardrobe_data_center")
        if dc and dc.GetWardrobeData then
            local e = dc.GetWardrobeData()
            if e and e.ResIDToIndexArrayMap and e.ResIDToIndexArrayMap[resid] then owned = true end
        end
    end)
    return owned
end

-- ═══════════════════════════════════════════════════════════════════
-- 5. SHOW REWARD
-- ═══════════════════════════════════════════════════════════════════

local function SHOW_REWARD(list)
    if #list == 0 then W("[DRAW] empty"); return end
    pcall(function()
        local LG = GM("client.slua.logic.common.CommonItemGet.Logic_CommonItemGet")
        if not LG or not LG.ShowPanel_DefaultStyle then W("[DRAW] no Logic_CommonItemGet"); return end
        local fmt = {}
        for _, it in ipairs(list) do
            fmt[#fmt+1] = { res_id = tonumber(it.resid) or 0, count = tonumber(it.count or 1) or 1, valid_hours = 0 }
        end
        LG.ShowPanel_DefaultStyle(fmt, false, true)
        W("[DRAW] ✓ panel shown: " .. #fmt)
    end)
end

local function PROCESS_DRAW(mod, tag, cnt)
    cnt = cnt or 1
    local pool = EXTRACT_POOL(mod)
    local seen, uniq = {}, {}
    for _, p in ipairs(pool) do
        if not seen[p.resid] then seen[p.resid] = true; uniq[#uniq+1] = p end
    end
    local unowned, owned = {}, {}
    for _, p in ipairs(uniq) do
        if IS_OWNED(p.resid) then owned[#owned+1] = p else unowned[#unowned+1] = p end
    end
    W("[POOL:" .. tag .. "] pool=" .. #pool .. " uniq=" .. #uniq .. " unowned=" .. #unowned .. " owned=" .. #owned)
    local src = (#unowned > 0) and unowned or uniq
    if #src == 0 then W("[DRAW:" .. tag .. "] empty pool"); return end
    local picked, used = {}, {}
    for i = 1, cnt do
        local idx = math.random(1, #src)
        local g = 0
        while used[idx] and g < 20 do idx = math.random(1, #src); g = g + 1 end
        used[idx] = true
        picked[#picked+1] = { resid = src[idx].resid, count = src[idx].count or 1 }
    end
    for _, p in ipairs(picked) do W("  → " .. tostring(p.resid)) end
    SHOW_REWARD(picked)
end

-- ═══════════════════════════════════════════════════════════════════
-- 6. DRAW TARGETS (WORKING V8 hook pattern)
-- ═══════════════════════════════════════════════════════════════════

local DRAW_TARGETS = {
    { tag="luckyback",  p="client.slua.logic.lobby_activity.logic_luckyback_activity",  fns={ "do_one_draw_back_by_activity_req","do_one_draw_by_tick","get_sum_draw_award_by_activity_req" } },
    { tag="luckydouble",p="client.slua.logic.lobby_activity.logic_luckydouble_activity",fns={ "send_do_one_lucky_double_draw_by_activity_req","send_double_draw_on_shot_req" } },
    { tag="luckyunback",p="client.slua.logic.lobby_activity.logic_luckyunback_activity",fns={ "send_do_draw_discount_by_activity_req" } },
    { tag="luckmix",    p="client.slua.logic.lobby_activity.logic_luckmix_activity",    fns={ "DoDraw" } },
    { tag="luckymulti", p="client.slua.logic.lobby_activity.logic_luckymulti_activity", fns={ "Lottery" } },
    { tag="scrapgold",  p="client.slua.logic.lobby_activity.logic_scrapgold_draw",      fns={ "DoDraw" } },
    { tag="godzilla",   p="client.slua.logic.lobby_activity.logic_godzilla_ban",        fns={ "OneDraw","TenDraw" } },
    { tag="optional",   p="client.slua.logic.lobby_activity.LukcyOptionalTurntable.Logic_LukcyOptionalTurntable", fns={ "SendDrawActReq" } },
    { tag="tarot",      p="client.slua.logic.tarot_card.logic_tarotcard_drawcard",      fns={ "DoDraw" } },
    { tag="airdrop",    p="client.slua.logic.lobby_activity.logic_super_airdrop",       fns={ "send_choose_and_get_super_airdrop_reward_req" } },
    { tag="xsuit_act",  p="client.slua.logic.XSuit.logic_xsuit_activity",               fns={ "send_do_draw_act_req","send_get_accumulate_pool_reward_req" } },
    { tag="ladder",     p="client.slua.logic.lobby_activity.logic_ladder_draw",         fns={ "OnRotateRsp","OnRandomAwardRsp","OnRecvAwardRsp" } },
    { tag="supply",     p="client.slua.logic.supply.supply_collect_chest_manager",      fns={ "OpenCollectChest" } },
    { tag="treasure",   p="client.slua.logic.store.treasure_chest_manager",             fns={ "OpenTreasureChest" } },
    { tag="supply_opt", p="client.slua.logic.store.supply_optional_chest_manager",      fns={ "OpenOptionalChest" } },
}

local function HOOK_DRAW()
    local m_ok, h = 0, 0
    for _, e in ipairs(DRAW_TARGETS) do
        local m = GM(e.p)
        if m then
            m_ok = m_ok + 1
            for _, fn in ipairs(e.fns) do
                local tag = "_sd12_" .. e.tag .. "_" .. fn
                if type(m[fn]) == "function" and not m[tag] then
                    if pcall(function()
                        m[tag] = true
                        m[fn] = function(self, ...)
                            W("[DRAW] " .. e.tag .. "." .. fn .. " HIT")
                            local cnt = string.find(string.lower(fn), "ten") and 10 or 1
                            pcall(PROCESS_DRAW, m, e.tag, cnt)
                        end
                    end) then h = h + 1 end
                end
            end
        end
    end
    W("[DRAW] mods=" .. m_ok .. " new_hooks=" .. h)
end

-- ═══════════════════════════════════════════════════════════════════
-- 7. SHOWROOM — padlock visual hide (light approach)
-- ═══════════════════════════════════════════════════════════════════

local function HIDE_LOCKS(uibp)
    if not uibp then return 0 end
    local n = 0
    pcall(function()
        local ESV = import("ESlateVisibility")
        for k, v in pairs(uibp) do
            if type(k) == "string" then
                local lower = string.lower(k)
                if string.find(lower, "lock", 1, true) or string.find(lower, "padlock", 1, true) then
                    if v and slua.isValid(v) then
                        pcall(function()
                            if v.SetVisibility then
                                v:SetVisibility(ESV and ESV.Collapsed or 2)
                            end
                        end)
                        n = n + 1
                    end
                end
            end
        end
    end)
    return n
end

local function HOOK_SHOWROOM_HIDE()
    local SLOT_KEYS = {
        "SocialLobby_AvatarShowSlot_UIBP","SocialLobby_VehicleSlot_UIBP",
        "SocialLobby_WeaponSlot_UIBP","SocialLobby_PetSlot_UIBP","SocialLobby_BGWallSlot_UIBP",
    }
    for _, key in ipairs(SLOT_KEYS) do
        local impl = UNWRAP(GM("client.slua.umg.lobby.Left.3DUIOverride." .. key))
        if impl then
            for _, fn in ipairs({ "OnPostInitialize","Initialize","OnShow" }) do
                if type(impl[fn]) == "function" then
                    HK(impl, fn, "_sd12_hide_" .. key .. "_" .. fn, function(self)
                        pcall(function()
                            local c = GETCHAR()
                            if c and c.AddGameTimer then
                                c:AddGameTimer(0.2, false, function()
                                    local cnt = HIDE_LOCKS(self)
                                    if cnt > 0 then W("[HIDE] " .. key .. " → " .. cnt) end
                                end)
                            else HIDE_LOCKS(self) end
                        end)
                    end)
                end
            end
        end
    end
end

local function KILL_LOCK_POPUP()
    local popup = UNWRAP(GM("GameLua.Mod.PlanCH.Client.UI.Popup.PlanCH_Hall_Slot_Locked_UIBP"))
    if not popup then return end
    for _, fn in ipairs({ "OnShow","UpdateUI","UpdateSlotInfo","OnHallSlotUnlock","AdjustUIPosition" }) do
        if type(popup[fn]) == "function" then
            pcall(function() popup[fn] = function() end end)
        end
    end
    W("[POPUP] locked popup silenced")
end

-- ═══════════════════════════════════════════════════════════════════
-- MASTER
-- ═══════════════════════════════════════════════════════════════════

function HOOK_ALL()
    W("═══ SD v12 ALL ═══")
    pcall(SPOOF_CURRENCY)     -- CRITICAL — restore UC first
    pcall(FORCE_LEVEL)
    pcall(BYPASS_PAY)
    pcall(HOOK_DRAW)
    pcall(KILL_LOCK_POPUP)
    pcall(HOOK_SHOWROOM_HIDE)
    W("═══ DONE ═══")
end

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
    W("  SD v12 — ALL FIXES")
    W("  Log: " .. tostring(_PATH))
    W("═══════════════════════════")
    pcall(HOOK_ALL)
    POPUP("★ SD v12 ★", "UC=" .. CFG.UC .. "\nDraw + Showroom active")
end

local function PHASE()
    local p = "unknown"
    pcall(function()
        if GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity() then p = "lobby" end
        if GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus() then p = "match" end
    end)
    return p
end

local _last = "unknown"
local function WATCH()
    if not _G._SD.booted then
        if GETCHAR() then pcall(BOOT) end
        return
    end
    -- Re-apply UC every tick (in case something resets it)
    pcall(SPOOF_CURRENCY)

    local p = PHASE()
    if p ~= _last then
        _last = p
        W("[PHASE] → " .. p)
        if p == "lobby" then
            pcall(FORCE_LEVEL)
            pcall(HOOK_DRAW)
            pcall(KILL_LOCK_POPUP)
            pcall(HOOK_SHOWROOM_HIDE)
        end
    end
end

_G.SD_Status = function()
    W("── STATUS ──")
    W("booted=" .. tostring(_G._SD.booted) .. " phase=" .. PHASE())
    print("[SD] status dumped")
end
_G.SD_HookNow = function() HOOK_ALL(); W("[MANUAL] re-arm") end
_G.SD_UC      = function() SPOOF_CURRENCY(); W("[MANUAL] UC spoof") end

do
    local ok, tk = pcall(require, "common.time_ticker")
    if ok and tk and tk.AddTimerLoop then
        tk.AddTimerLoop(0, WATCH, -1, CFG.TICK)
    else
        pcall(WATCH)
    end
end

print("[sd_v12.lua] loaded")
