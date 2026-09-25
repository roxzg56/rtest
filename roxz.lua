-- ═══════════════════════════════════════════════════════════════════
-- sd_v11.lua — FAKE DRAW REWARD = ACTUAL SPIN POOL (unowned priority)
--   Replace generic fallback with deep pool scan + ownership check
-- ═══════════════════════════════════════════════════════════════════

_G._SD = _G._SD or { booted = false, log = {} }

local CFG = {
    BRAND = "SD v11 DRAW-FIX",
    DUMP_FILE = "sd_v11_log_",
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

-- ═══════════════════════════════════════════════════════════════════
-- DEEP POOL EXTRACTOR — recurse into tables, find all res ids
-- ═══════════════════════════════════════════════════════════════════

local RES_ID_KEYS = {
    "resid","resID","res_id","itemid","itemID","item_id","ItemID","ItemId",
    "award_item_id","awardItemId","award_id","reward_id","rewardId","id"
}
local COUNT_KEYS = { "count","item_count","item_num","itemCount","num","award_item_num" }

local function GET_RES_ID(t)
    if type(t) ~= "table" then return nil end
    for _, k in ipairs(RES_ID_KEYS) do
        local v = t[k]
        if v then
            local n = tonumber(v)
            if n and n > 0 then return n end
        end
    end
    return nil
end
local function GET_COUNT(t)
    if type(t) ~= "table" then return 1 end
    for _, k in ipairs(COUNT_KEYS) do
        local v = t[k]
        if v then
            local n = tonumber(v)
            if n and n > 0 then return n end
        end
    end
    return 1
end

-- Recursively walk any table, collect any table that has a res id
local function DEEP_COLLECT(t, out, depth, seen)
    depth = depth or 0
    seen = seen or {}
    if depth > 6 or type(t) ~= "table" or seen[t] then return end
    seen[t] = true

    local id = GET_RES_ID(t)
    if id then
        out[#out+1] = { resid = id, count = GET_COUNT(t) }
    end
    for k, v in pairs(t) do
        if type(v) == "table" then
            DEEP_COLLECT(v, out, depth + 1, seen)
        end
    end
end

-- Try to find pool in the module — check all likely keys AND their nested
local function EXTRACT_POOL(mod)
    if not mod then return {} end
    local found = {}

    -- Priority keys first
    local PRIORITY_KEYS = {
        "poolItemConfig","CurAwardPoolConfig","CurSmallAwardPoolConfig",
        "CurBigAwardPoolConfig","AwardPoolConfig","totalDrawAwardConfig",
        "dropList","pool_info","items","Items","itemList","awardItemList",
        "rewardList","poolList","draw_info","drawInfo","poolInfo","prizeList",
        "awardList","showList","itemInfos","itemInfoList"
    }
    for _, key in ipairs(PRIORITY_KEYS) do
        local t = mod[key]
        if type(t) == "table" then
            DEEP_COLLECT(t, found)
        end
    end

    -- If priority keys found nothing, scan whole module at depth 2
    if #found == 0 then
        W("[POOL] priority keys empty, deep scanning module")
        for k, v in pairs(mod) do
            if type(v) == "table" and not string.find(tostring(k), "__") then
                DEEP_COLLECT(v, found)
            end
        end
    end

    return found
end

-- ═══════════════════════════════════════════════════════════════════
-- OWNERSHIP CHECK — is this res id in inventory?
-- ═══════════════════════════════════════════════════════════════════

local function IS_OWNED(resid)
    resid = tonumber(resid)
    if not resid then return false end
    local owned = false
    pcall(function()
        local wd = GM("client.slua.logic.wardrobe.wardrobe_data")
        if wd and wd.GetHallDepotItemDataByInsID then
            -- try depot entity
            local dc = GM("client.slua.logic.wardrobe.logic_wardrobe_data_center")
            if dc and dc.GetWardrobeData then
                local e = dc.GetWardrobeData()
                if e and e.ResIDToIndexArrayMap and e.ResIDToIndexArrayMap[resid] then
                    owned = true
                end
            end
        end
    end)
    if not owned then
        pcall(function()
            local wd = GM("client.slua.logic.wardrobe.wardrobe_data")
            if wd and wd.HasItem then
                local ok, r = pcall(function() return wd:HasItem(resid) end)
                if ok and r then owned = true end
            end
        end)
    end
    return owned
end

-- ═══════════════════════════════════════════════════════════════════
-- SHOW REWARD
-- ═══════════════════════════════════════════════════════════════════

local function SHOW_REWARD(list)
    if #list == 0 then
        W("[DRAW] EMPTY list — cannot show panel")
        return false
    end
    local ok = false
    pcall(function()
        local LG = GM("client.slua.logic.common.CommonItemGet.Logic_CommonItemGet")
        if not LG or not LG.ShowPanel_DefaultStyle then
            W("[DRAW] Logic_CommonItemGet missing")
            return
        end
        local fmt = {}
        for _, it in ipairs(list) do
            fmt[#fmt+1] = {
                res_id = tonumber(it.resid) or 0,
                count  = tonumber(it.count or 1) or 1,
                valid_hours = 0,
            }
        end
        LG.ShowPanel_DefaultStyle(fmt, false, true)
        W("[DRAW] panel shown: " .. #fmt .. " items")
        ok = true
    end)
    return ok
end

-- ═══════════════════════════════════════════════════════════════════
-- PROCESS DRAW — pick unowned items from pool
-- ═══════════════════════════════════════════════════════════════════

local function PROCESS_DRAW(mod, tag, count)
    count = count or 1
    local pool = EXTRACT_POOL(mod)
    W("[POOL:" .. tag .. "] extracted " .. #pool .. " items")

    -- Dedup by resid
    local seen, unique = {}, {}
    for _, p in ipairs(pool) do
        if not seen[p.resid] then
            seen[p.resid] = true
            unique[#unique+1] = p
        end
    end
    W("[POOL:" .. tag .. "] unique " .. #unique)

    -- Prefer unowned
    local unowned, owned = {}, {}
    for _, p in ipairs(unique) do
        if IS_OWNED(p.resid) then owned[#owned+1] = p
        else unowned[#unowned+1] = p end
    end
    W("[POOL:" .. tag .. "] unowned=" .. #unowned .. " owned=" .. #owned)

    -- Pick from unowned if possible
    local src = (#unowned > 0) and unowned or unique
    if #src == 0 then
        W("[DRAW:" .. tag .. "] no items in pool — using pool-less skip")
        return
    end

    local picked = {}
    local used = {}
    for i = 1, count do
        local idx = math.random(1, #src)
        local guard = 0
        while used[idx] and guard < 20 do
            idx = math.random(1, #src)
            guard = guard + 1
        end
        used[idx] = true
        local p = src[idx]
        picked[#picked+1] = { resid = p.resid, count = p.count or 1 }
    end

    W("[DRAW:" .. tag .. "] picked " .. #picked .. " rewards")
    for _, p in ipairs(picked) do
        W("  → " .. tostring(p.resid) .. " x" .. tostring(p.count))
    end
    SHOW_REWARD(picked)
end

-- ═══════════════════════════════════════════════════════════════════
-- DRAW TARGETS — same list, hooks replaced
-- ═══════════════════════════════════════════════════════════════════

local DRAW_TARGETS = {
    { tag="luckyback",  p="client.slua.logic.lobby_activity.logic_luckyback_activity",  fns={ "do_one_draw_back_by_activity_req","do_one_draw_by_tick" } },
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
    { tag="manor_draw", p="client.slua.logic.home.DrawReward.logic_manor_draw_reward",  fns={} },
}

local function HOOK_DRAW()
    local m_ok, h = 0, 0
    for _, e in ipairs(DRAW_TARGETS) do
        local m = GM(e.p)
        if m then
            m_ok = m_ok + 1
            for _, fn in ipairs(e.fns) do
                local tag = "_sd_v11_dr_" .. e.tag .. "_" .. fn
                if type(m[fn]) == "function" and not m[tag] then
                    if pcall(function()
                        m[tag] = true
                        m[fn] = function(self, ...)
                            W("[DRAW] " .. e.tag .. "." .. fn .. " HIT")
                            local cnt = string.find(string.lower(fn), "ten") and 10 or 1
                            PROCESS_DRAW(m, e.tag, cnt)
                        end
                    end) then h = h + 1 end
                end
            end
        end
    end
    W("[DRAW] mods=" .. m_ok .. " hooks=" .. h)
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
    W("  SD v11 DRAW-FIX")
    W("  Log: " .. tostring(_PATH))
    W("═══════════════════════════")
    pcall(HOOK_DRAW)
    POPUP("★ SD v11 ★", "Draw fix: real pool + unowned priority")
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
    local p = PHASE()
    if p ~= _last then
        _last = p
        W("[PHASE] → " .. p)
        if p == "lobby" then pcall(HOOK_DRAW) end
    end
end

_G.SD_Status   = function() W("── STATUS ──"); W("booted=" .. tostring(_G._SD.booted)); print("[SD] dumped") end
_G.SD_DumpPool = function(path)
    local m = GM(path)
    if m then
        local p = EXTRACT_POOL(m)
        W("[DUMP] " .. path .. " pool=" .. #p)
        for i, x in ipairs(p) do if i <= 30 then W("  " .. i .. ": " .. x.resid) end end
    end
end

do
    local ok, tk = pcall(require, "common.time_ticker")
    if ok and tk and tk.AddTimerLoop then
        tk.AddTimerLoop(0, WATCH, -1, CFG.TICK)
    else
        pcall(WATCH)
    end
end

print("[sd_v11.lua] DRAW-FIX loaded")
