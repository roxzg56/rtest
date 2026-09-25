-- ═══════════════════════════════════════════════════════════════════
-- sd_v14.lua — LTM correct lookup + draw panel fixed
-- ═══════════════════════════════════════════════════════════════════

_G._SD = _G._SD or { booted = false, log = {} }

local CFG = {
    BRAND = "SD v14",
    DUMP_FILE = "sd_v14_log_",
    SAVE_DIRS = {
        "/storage/emulated/0/Android/data/com.pubg.imobile/files/",
        "/storage/emulated/0/Android/data/com.pubg.krmobile/files/",
        "/storage/emulated/0/Android/data/com.pubg.vng.pubgmobile/files/",
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

-- ═══════════════════════════════════════════════════════════════════
-- LTM — CORRECT LOOKUP (uses ModuleManager config table reference)
-- ═══════════════════════════════════════════════════════════════════

local LTM = { module = nil, hooked = false }

local function GET_MM()
    local ok, MM = pcall(require, "client.module_framework.ModuleManager")
    if not ok or not MM then return nil end
    return MM
end

local function FIND_LTM()
    if LTM.module then return LTM.module end
    local MM = GET_MM()
    if not MM then W("[LTM] ModuleManager not found"); return nil end

    -- Try config table path (from user's code)
    local tried = {}
    local ok1, cfg = pcall(function() return MM.LobbyModuleConfig.LobbyThemeManager end)
    if ok1 and cfg then
        tried[#tried+1] = "LobbyModuleConfig.LobbyThemeManager (config table)"
        local ok2, m = pcall(function() return MM.GetModule(cfg) end)
        if ok2 and m then LTM.module = m; W("[LTM] found via " .. tried[#tried]); return m end
    end

    -- Try string path
    local ok3, m2 = pcall(function() return MM.GetModule("LobbyThemeManager") end)
    if ok3 and m2 then LTM.module = m2; W("[LTM] found via string 'LobbyThemeManager'"); return m2 end

    -- Try ThemeVehicleManager (sibling)
    local ok4, m3 = pcall(function() return MM.GetModule(MM.LobbyModuleConfig.ThemeVehicleManager) end)
    if ok4 and m3 then LTM.module = m3; W("[LTM] found ThemeVehicleManager"); return m3 end

    -- Scan ModuleManager.LobbyModuleConfig for anything with Theme
    pcall(function()
        for k, v in pairs(MM.LobbyModuleConfig or {}) do
            if type(k) == "string" and (string.find(k, "Theme") or string.find(k, "theme")) then
                W("[LTM] LobbyModuleConfig has: " .. k)
            end
        end
    end)

    return nil
end

local function DUMP_LTM()
    local ltm = FIND_LTM()
    if not ltm then W("[LTM] ✗ not found for dump"); return end
    W("─── DUMP LTM ───")
    local keys = {}
    for k in pairs(ltm) do keys[#keys+1] = k end
    table.sort(keys, function(a,b) return tostring(a) < tostring(b) end)
    for _, k in ipairs(keys) do
        local v = ltm[k]
        if type(k) == "string" then
            if type(v) == "function" then W("  fn: " .. k)
            elseif type(v) == "table" then
                local n = 0; for _ in pairs(v) do n = n + 1 end
                W("  tbl[" .. n .. "]: " .. k)
            elseif type(v) == "boolean" then W("  bool: " .. k .. " = " .. tostring(v))
            elseif type(v) == "number" then W("  num: " .. k .. " = " .. tostring(v)) end
        end
    end
end

local function HOOK_LTM()
    if LTM.hooked then return end
    local ltm = FIND_LTM()
    if not ltm then return end

    local n = 0
    if type(ltm.ShowGarageEffect) == "function" then
        local orig = ltm.ShowGarageEffect
        ltm.ShowGarageEffect = function(self, bShow, VehicleType)
            W("[LTM] ShowGarageEffect bShow=" .. tostring(bShow) .. " veh=" .. tostring(VehicleType))
            return orig(self, true, VehicleType)
        end
        n = n + 1
    end
    if type(ltm.GetDisplayItemID) == "function" then
        local orig = ltm.GetDisplayItemID
        ltm.GetDisplayItemID = function(self, ...)
            local r = orig(self, ...)
            W("[LTM] GetDisplayItemID → " .. tostring(r))
            return r
        end
        n = n + 1
    end
    LTM.hooked = true
    W("[LTM] hooked " .. n)
end

-- ═══════════════════════════════════════════════════════════════════
-- UC SPOOF
-- ═══════════════════════════════════════════════════════════════════

local KEYS = { "ticket","uc","gold","diamond","eternal_diamond","home_coin","bp","coupon","voucher" }
local function SPOOF_CURRENCY()
    local dm = _G.DataMgr
    if not dm then return end
    pcall(function() for _, k in ipairs(KEYS) do dm[k] = CFG.UC end end)
    pcall(function()
        local mt = getmetatable(dm) or {}
        local old = mt.__index
        mt.__index = function(t, k)
            for _, key in ipairs(KEYS) do if k == key then return CFG.UC end end
            if type(old) == "function" then return old(t, k) end
            if type(old) == "table" then return old[k] end
            return rawget(t, k)
        end
        setmetatable(dm, mt)
    end)
    pcall(function()
        if dm.GetUserData and not dm._sd14_gu then
            dm._sd14_gu = true
            local orig = dm.GetUserData
            dm.GetUserData = function(a)
                local d = orig(a)
                if d then for _, k in ipairs(KEYS) do pcall(function() d[k] = CFG.UC end) end end
                return d
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- DRAW — panel with multiple fallback routes
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
local function DEEP(t, out, d, seen)
    d = d or 0; seen = seen or {}
    if d > 6 or type(t) ~= "table" or seen[t] then return end
    seen[t] = true
    local id = RID(t); if id then out[#out+1] = { resid = id, count = RCNT(t) } end
    for _, v in pairs(t) do if type(v) == "table" then DEEP(v, out, d + 1, seen) end end
end

local PRIORITY = {
    "poolItemConfig","CurAwardPoolConfig","CurSmallAwardPoolConfig","CurBigAwardPoolConfig",
    "AwardPoolConfig","totalDrawAwardConfig","dropList","pool_info","items","Items",
    "itemList","awardItemList","rewardList","poolList","draw_info","drawInfo","poolInfo",
    "prizeList","awardList","showList","itemInfos","itemInfoList"
}
local function EXTRACT_POOL(m)
    if not m then return {} end
    local found = {}
    for _, k in ipairs(PRIORITY) do if type(m[k]) == "table" then DEEP(m[k], found) end end
    if #found == 0 then
        for k, v in pairs(m) do if type(v) == "table" and not string.find(tostring(k), "__") then DEEP(v, found) end end
    end
    return found
end

-- Multiple routes to show reward panel
local function SHOW_REWARD(list)
    if #list == 0 then W("[SHOW] empty list"); return end

    -- Route 1: Logic_CommonItemGet (multiple paths)
    local LG_paths = {
        "client.slua.logic.common.CommonItemGet.Logic_CommonItemGet",
        "client.slua.logic.common.logic_common_item_get",
        "GameLua.Mod.BaseMod.Client.CommonItemGet.CommonItemGet",
        "client.slua.umg.Common.Common_Popup_Reward_Base",
    }
    local fmt = {}
    for _, it in ipairs(list) do
        fmt[#fmt+1] = { res_id = tonumber(it.resid) or 0, count = tonumber(it.count or 1) or 1, valid_hours = 0 }
    end

    for _, path in ipairs(LG_paths) do
        local LG = GM(path)
        if LG then
            W("[SHOW] tried " .. path .. " has ShowPanel_DefaultStyle=" .. tostring(type(LG.ShowPanel_DefaultStyle)))
            if type(LG.ShowPanel_DefaultStyle) == "function" then
                local ok, err = pcall(function() LG.ShowPanel_DefaultStyle(fmt, false, true) end)
                if ok then W("[SHOW] ✓ panel via " .. path); return end
                W("[SHOW] ✗ " .. path .. " error: " .. tostring(err))
            end
        end
    end

    -- Route 2: UIManager open Common popup
    pcall(function()
        local UM = _G.UIManager
        if UM and UM.OpenUI and UM.UI_Config_Common and UM.UI_Config_Common.Common_Popup_Reward_Base then
            UM:OpenUI(UM.UI_Config_Common.Common_Popup_Reward_Base, fmt)
            W("[SHOW] ✓ via UIManager OpenUI")
            return
        end
    end)

    -- Route 3: Generic show message fallback
    pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
                    or require("client.slua.logic.common.logic_common_msg_box")
        if Msg and Msg.Show then
            local t = ""
            for i, it in ipairs(fmt) do
                if i <= 3 then t = t .. "ID:" .. it.res_id .. " x" .. it.count .. "\n" end
            end
            Msg.Show(4, "★ FAKE DRAW ★", t)
            W("[SHOW] ✓ fallback msgbox")
        end
    end)
end

local function PROCESS_DRAW(m, tag, cnt)
    local pool = EXTRACT_POOL(m)
    local seen, uniq = {}, {}
    for _, p in ipairs(pool) do if not seen[p.resid] then seen[p.resid] = true; uniq[#uniq+1] = p end end
    if #uniq == 0 then W("[DRAW:" .. tag .. "] empty"); return end
    local picked = {}
    for i = 1, cnt do picked[#picked+1] = { resid = uniq[math.random(1, #uniq)].resid, count = 1 } end
    W("[DRAW:" .. tag .. "] picked " .. #picked .. " → showing panel")
    SHOW_REWARD(picked)
end

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
}

local function HOOK_DRAW()
    local m_ok, h = 0, 0
    for _, e in ipairs(DRAW_TARGETS) do
        local m = GM(e.p)
        if m then
            m_ok = m_ok + 1
            for _, fn in ipairs(e.fns) do
                local tag = "_sd14_" .. e.tag .. "_" .. fn
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
    W("[DRAW] mods=" .. m_ok .. " new=" .. h)
end

-- ═══════════════════════════════════════════════════════════════════
-- MASTER
-- ═══════════════════════════════════════════════════════════════════

function HOOK_ALL()
    W("═══ SD v14 ═══")
    pcall(SPOOF_CURRENCY)
    pcall(HOOK_LTM)
    pcall(DUMP_LTM)
    pcall(HOOK_DRAW)
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
    W("  SD v14")
    W("  Log: " .. tostring(_PATH))
    W("═══════════════════════════")
    pcall(HOOK_ALL)
    POPUP("★ SD v14 ★", "LTM fixed + draw fallback")
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
    pcall(SPOOF_CURRENCY)

    local p = PHASE()
    if p ~= _last then
        _last = p
        W("[PHASE] → " .. p)
        if p == "lobby" then
            pcall(HOOK_LTM)
            pcall(HOOK_DRAW)
        end
    end
end

_G.SD_Status  = function() W("── STATUS ──"); W("booted=" .. tostring(_G._SD.booted)); print("[SD] status") end
_G.SD_HookNow = function() HOOK_ALL(); W("[MANUAL] re-arm") end
_G.SD_DumpLTM = function() DUMP_LTM() end
_G.SD_TestDraw = function() SHOW_REWARD({ { resid = 1030060794, count = 1 } }); W("[MANUAL] test draw") end

do
    local ok, tk = pcall(require, "common.time_ticker")
    if ok and tk and tk.AddTimerLoop then
        tk.AddTimerLoop(0, WATCH, -1, CFG.TICK)
    else
        pcall(WATCH)
    end
end

print("[sd_v14.lua] loaded")
