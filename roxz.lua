-- ═══════════════════════════════════════════════════════════════════
-- sd_v8.lua — SURGICAL SHOWROOM UNLOCK
--   Approach: real value change + CDataTable inject + selective hook
--   No auto-hook. No aggressive override. No rendering break.
-- ═══════════════════════════════════════════════════════════════════

_G._SD = _G._SD or { booted = false, log = {} }

local CFG = {
    BRAND = "SD v8 SURGICAL",
    DUMP_FILE = "sd_v8_log_",
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
    HALL_LEVEL = 100,
    SLOT_MAX = 99,
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

-- ═══════════════════════════════════════════════════════════════════
-- STEP 1 — FORCE HALL LEVEL (real value write, no hook)
-- ═══════════════════════════════════════════════════════════════════

local function FORCE_HALL_LEVEL()
    local dm = _G.DataMgr
    if not dm or not dm.roleData then W("[LVL] roleData nil"); return false end
    local rd = dm.roleData
    local changed = false

    -- brief_collect_hall_data.hall_level
    pcall(function()
        if not rd.brief_collect_hall_data then
            rd.brief_collect_hall_data = {}
        end
        local old = rd.brief_collect_hall_data.hall_level
        rd.brief_collect_hall_data.hall_level = CFG.HALL_LEVEL
        W("[LVL] brief_collect_hall_data.hall_level: " .. tostring(old) .. " → " .. CFG.HALL_LEVEL)
        changed = true
    end)

    -- Top-level hall_level (some paths read from here)
    pcall(function()
        local old = rd.hall_level
        rd.hall_level = CFG.HALL_LEVEL
        W("[LVL] roleData.hall_level: " .. tostring(old) .. " → " .. CFG.HALL_LEVEL)
        changed = true
    end)

    -- Player level (for "Home not unlocked" gate)
    pcall(function()
        local old = rd.level
        rd.level = 99
        W("[LVL] player level: " .. tostring(old) .. " → 99")
        changed = true
    end)

    -- Manor open_level
    pcall(function()
        if rd.manor_switch then
            local old = rd.manor_switch.open_level
            rd.manor_switch.open_level = 1
            W("[LVL] manor_switch.open_level: " .. tostring(old) .. " → 1")
        end
    end)

    return changed
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 2 — CDATATABLE INJECT
-- Override CDataTable.GetTableData/GetTableDataByFilter so config
-- lookups for the unlock-slot keys return max values.
-- ═══════════════════════════════════════════════════════════════════

local UNLOCK_KEYS = {
    -- Enum_LevelUnlockSlotCfgKey
    AchievementMedalFreeSlotCount = CFG.SLOT_MAX,
    MixHallFreeAvatarSlotCount    = CFG.SLOT_MAX,
    MixHallFreeVehicleSlotCount   = CFG.SLOT_MAX,
    MixHallFreeWeaponSlotCount    = CFG.SLOT_MAX,
    MixHallFreePetSlotCount       = CFG.SLOT_MAX,
    -- Enum_SkinUnlockSlotCfgKey
    MixHallExtraAvatarSlotCount   = CFG.SLOT_MAX,
    MixHallExtraVehicleSlotCount  = CFG.SLOT_MAX,
    MixHallExtraWeaponSlotCount   = CFG.SLOT_MAX,
    MixHallExtraPetSlotCount      = CFG.SLOT_MAX,
}

local function INJECT_CDATATABLE()
    local CDT = _G.CDataTable
    if not CDT then W("[CDT] CDataTable nil"); return end

    -- Patch GetTableDataByFilter (usually used for config by column)
    if type(CDT.GetTableDataByFilter) == "function" and not CDT._sd_v8_filter then
        CDT._sd_v8_filter = true
        local orig = CDT.GetTableDataByFilter
        CDT.GetTableDataByFilter = function(tbl_name, col, val, ...)
            local r = orig(tbl_name, col, val, ...)
            if type(r) == "table" then
                for k, v in pairs(UNLOCK_KEYS) do
                    if r[k] ~= nil and type(r[k]) == "number" and r[k] < v then
                        r[k] = v
                    end
                end
            end
            return r
        end
        W("[CDT] GetTableDataByFilter hooked")
    end

    -- Patch GetTableData (single row lookup)
    if type(CDT.GetTableData) == "function" and not CDT._sd_v8_td then
        CDT._sd_v8_td = true
        local orig = CDT.GetTableData
        CDT.GetTableData = function(tbl_name, key, ...)
            local r = orig(tbl_name, key, ...)
            if type(r) == "table" then
                for k, v in pairs(UNLOCK_KEYS) do
                    if r[k] ~= nil and type(r[k]) == "number" and r[k] < v then
                        r[k] = v
                    end
                end
            end
            return r
        end
        W("[CDT] GetTableData hooked")
    end

    -- Patch GetTable (get whole table)
    if type(CDT.GetTable) == "function" and not CDT._sd_v8_gt then
        CDT._sd_v8_gt = true
        local orig = CDT.GetTable
        CDT.GetTable = function(tbl_name)
            local r = orig(tbl_name)
            if type(r) == "table" then
                -- If it's a config table with unlock keys, patch every entry
                for _, row in pairs(r) do
                    if type(row) == "table" then
                        for k, v in pairs(UNLOCK_KEYS) do
                            if row[k] ~= nil and type(row[k]) == "number" and row[k] < v then
                                row[k] = v
                            end
                        end
                    end
                end
            end
            return r
        end
        W("[CDT] GetTable hooked")
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 3 — TARGETED SLOT UNLOCK HOOKS (surgical, not aggressive)
-- ═══════════════════════════════════════════════════════════════════

local function HOOK_SLOT_UNLOCK_ONLY()
    local ssc = GM("GameLua.Mod.PlanCH.Client.SubSystem.HallData.PlanCH_SkinSlotUnlock_Config")
    local impl = UNWRAP(ssc)
    if not impl or type(impl) ~= "table" then
        W("[SLOT] SkinSlotUnlock not found"); return
    end

    local n = 0

    -- Only these — the actual unlock gate
    if type(impl.IsSlotUnlock) == "function" then
        impl.IsSlotUnlock = function(self, ...) return true end
        n = n + 1
    end
    if type(impl.IsPaySlot) == "function" then
        impl.IsPaySlot = function(self, ...) return false end
        n = n + 1
    end
    if type(impl.GetUnlockNextSlotCost) == "function" then
        impl.GetUnlockNextSlotCost = function(self, ...) return 0 end
        n = n + 1
    end
    if type(impl.ShowPayToUnlockSlotUI) == "function" then
        impl.ShowPayToUnlockSlotUI = function() end
        n = n + 1
    end

    -- IMPORTANT: Do NOT touch GetAllSlotCount, GetUnlockSlotCount, GetAllSlotList
    -- because they break the grid rendering (X marks bug).

    W("[SLOT] surgical overrides: " .. n)
    _G._SD.slot_overrides = n
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 4 — FORCE REFRESH: tell game to re-read slot state
-- ═══════════════════════════════════════════════════════════════════

local function FORCE_REFRESH()
    -- Try UpdateUnlockData first
    local ssc = GM("GameLua.Mod.PlanCH.Client.SubSystem.HallData.PlanCH_SkinSlotUnlock_Config")
    local impl = UNWRAP(ssc)
    if impl then
        pcall(function()
            if type(impl.UpdateUnlockData) == "function" then
                impl:UpdateUnlockData()
                W("[REFRESH] UpdateUnlockData called")
            end
        end)
        pcall(function()
            if type(impl.OnSlotUnlock) == "function" then
                impl:OnSlotUnlock(0, 0, 0, 0, 0, 0)
                W("[REFRESH] OnSlotUnlock called")
            end
        end)
    end

    -- Fire hall level change event
    pcall(function()
        local hd = GM("GameLua.Mod.PlanCH.Client.SubSystem.HallData.PlanCH_HallData_Client")
        local hdi = UNWRAP(hd)
        if hdi and type(hdi.OnHallLevelChanged) == "function" then
            hdi:OnHallLevelChanged(CFG.HALL_LEVEL)
            W("[REFRESH] OnHallLevelChanged(" .. CFG.HALL_LEVEL .. ")")
        end
    end)

    -- Fire slot unlock event on game event bus
    pcall(function()
        if EventSystem and EventSystem.postEvent then
            -- Try common event IDs
            for _, ev in ipairs({ "EVENTID_HALL_SLOT_UNLOCK", "EVENTID_SKIN_SLOT_UNLOCK", "EVENTID_HALL_LEVEL_CHANGED" }) do
                if _G[ev] then
                    EventSystem:postEvent(EVENTTYPE_LOBBY, _G[ev])
                    W("[REFRESH] event posted: " .. ev)
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 5 — FAKE DRAW (working version, no orig call)
-- ═══════════════════════════════════════════════════════════════════

local FALLBACK = { { resid = 403003, count = 1 } }

local function SHOW_REWARD(list)
    pcall(function()
        local LG = GM("client.slua.logic.common.CommonItemGet.Logic_CommonItemGet")
        if not LG or not LG.ShowPanel_DefaultStyle then return end
        local fmt = {}
        for _, it in ipairs(list or {}) do
            fmt[#fmt+1] = { res_id = tonumber(it.resid or 403003), count = tonumber(it.count or 1), valid_hours = 0 }
        end
        LG.ShowPanel_DefaultStyle(fmt, false, true)
        W("[DRAW] panel shown (" .. #fmt .. ")")
    end)
end

local function PICK(mod)
    if not mod then return nil end
    local pool = {}
    for _, k in ipairs({ "poolItemConfig","dropList","pool_info","AwardPoolConfig",
                         "CurSmallAwardPoolConfig","CurBigAwardPoolConfig",
                         "totalDrawAwardConfig","items","Items","itemList",
                         "awardItemList","rewardList","poolList" }) do
        if type(mod[k]) == "table" then
            for _, v in ipairs(mod[k]) do pool[#pool+1] = v end
        end
    end
    if #pool == 0 then return nil end
    return pool[math.random(1, #pool)]
end

local DRAW_TARGETS = {
    { tag="luckyback",   p="client.slua.logic.lobby_activity.logic_luckyback_activity",
      fns={ "do_one_draw_back_by_activity_req","do_one_draw_by_tick" } },
    { tag="luckydouble", p="client.slua.logic.lobby_activity.logic_luckydouble_activity",
      fns={ "send_do_one_lucky_double_draw_by_activity_req","send_double_draw_on_shot_req" } },
    { tag="luckyunback", p="client.slua.logic.lobby_activity.logic_luckyunback_activity",
      fns={ "send_do_draw_discount_by_activity_req" } },
    { tag="luckmix",     p="client.slua.logic.lobby_activity.logic_luckmix_activity", fns={ "DoDraw" } },
    { tag="luckymulti",  p="client.slua.logic.lobby_activity.logic_luckymulti_activity", fns={ "Lottery" } },
    { tag="scrapgold",   p="client.slua.logic.lobby_activity.logic_scrapgold_draw", fns={ "DoDraw" } },
    { tag="godzilla",    p="client.slua.logic.lobby_activity.logic_godzilla_ban", fns={ "OneDraw","TenDraw" } },
    { tag="optional",    p="client.slua.logic.lobby_activity.LukcyOptionalTurntable.Logic_LukcyOptionalTurntable", fns={ "SendDrawActReq" } },
    { tag="tarot",       p="client.slua.logic.tarot_card.logic_tarotcard_drawcard", fns={ "DoDraw" } },
    { tag="airdrop",     p="client.slua.logic.lobby_activity.logic_super_airdrop", fns={ "send_choose_and_get_super_airdrop_reward_req" } },
    { tag="xsuit_act",   p="client.slua.logic.XSuit.logic_xsuit_activity",
      fns={ "send_do_draw_act_req","send_get_accumulate_pool_reward_req" } },
    { tag="ladder",      p="client.slua.logic.lobby_activity.logic_ladder_draw",
      fns={ "OnRotateRsp","OnRandomAwardRsp","OnRecvAwardRsp" } },
    { tag="supply_chst", p="client.slua.logic.supply.supply_collect_chest_manager", fns={ "OpenCollectChest" } },
    { tag="treasure",    p="client.slua.logic.store.treasure_chest_manager", fns={ "OpenTreasureChest" } },
    { tag="supply_opt",  p="client.slua.logic.store.supply_optional_chest_manager", fns={ "OpenOptionalChest" } },
}

local function HOOK_DRAW()
    local mods_ok, hooks = 0, 0
    for _, entry in ipairs(DRAW_TARGETS) do
        local mod = GM(entry.p)
        if mod then
            mods_ok = mods_ok + 1
            for _, fn in ipairs(entry.fns) do
                local tag = "_sd_v8_" .. entry.tag .. "_" .. fn
                if type(mod[fn]) == "function" and not mod[tag] then
                    if pcall(function()
                        mod[tag] = true
                        mod[fn] = function(self, ...)
                            W("[DRAW] " .. entry.tag .. "." .. fn .. " INTERCEPTED")
                            local is_ten = string.find(string.lower(fn), "ten") ~= nil
                            local cnt = is_ten and 10 or 1
                            local list = {}
                            for _ = 1, cnt do
                                local p = PICK(mod) or FALLBACK[1]
                                local res = p.resid or p.resID or p.itemid or p.res_id or 403003
                                list[#list+1] = { resid = tonumber(res) or 403003, count = 1 }
                            end
                            pcall(SHOW_REWARD, list)
                        end
                    end) then hooks = hooks + 1 end
                end
            end
        end
    end
    W("[DRAW] mods=" .. mods_ok .. " hooks=" .. hooks)
    _G._SD.draw_mods = mods_ok
    _G._SD.draw_hooks = hooks
end

-- ═══════════════════════════════════════════════════════════════════
-- CURRENCY
-- ═══════════════════════════════════════════════════════════════════

local function SPOOF_CURRENCY()
    local dm = _G.DataMgr
    if not dm then return end
    local K = { "ticket","uc","gold","diamond","eternal_diamond","home_coin","bp","coupon","voucher" }
    pcall(function() for _, k in ipairs(K) do dm[k] = 999999999 end end)
    pcall(function()
        local mt = getmetatable(dm) or {}
        local oldIdx = mt.__index
        mt.__index = function(t, k)
            for _, key in ipairs(K) do if k == key then return 999999999 end end
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
-- MASTER
-- ═══════════════════════════════════════════════════════════════════

function HOOK_ALL()
    W("═══ SD v8 SURGICAL ═══")
    pcall(FORCE_HALL_LEVEL)
    pcall(INJECT_CDATATABLE)
    pcall(HOOK_SLOT_UNLOCK_ONLY)
    pcall(HOOK_DRAW)
    pcall(SPOOF_CURRENCY)
    pcall(BYPASS_PAY)
    pcall(FORCE_REFRESH)
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
    W("  SD v8 SURGICAL")
    W("  Log: " .. tostring(_PATH))
    W("═══════════════════════════")
    pcall(HOOK_ALL)
    POPUP("★ SD v8 ★", "Surgical. Hall level → " .. CFG.HALL_LEVEL .. ".\nTest showroom + draw.")
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
        if p == "lobby" then
            pcall(FORCE_HALL_LEVEL)
            pcall(FORCE_REFRESH)
        end
    end
end

-- ═══ MANUAL ═══
_G.SD_Status      = function()
    W("── STATUS ──")
    W("booted=" .. tostring(_G._SD.booted) .. " phase=" .. PHASE())
    W("slot_overrides=" .. tostring(_G._SD.slot_overrides or 0))
    W("draw_mods=" .. tostring(_G._SD.draw_mods or 0) .. " hooks=" .. tostring(_G._SD.draw_hooks or 0))
    print("[SD] status dumped")
end
_G.SD_ForceLevel  = function() FORCE_HALL_LEVEL(); FORCE_REFRESH(); W("[MANUAL] level+refresh") end
_G.SD_Refresh     = function() FORCE_REFRESH(); W("[MANUAL] refresh") end
_G.SD_HookNow     = function() HOOK_ALL(); W("[MANUAL] re-arm") end
_G.SD_TestDraw    = function() SHOW_REWARD({ { resid = 403003, count = 1 } }); W("[MANUAL] test draw") end

do
    local ok, tk = pcall(require, "common.time_ticker")
    if ok and tk and tk.AddTimerLoop then
        tk.AddTimerLoop(0, WATCH, -1, CFG.TICK)
    else
        pcall(WATCH)
    end
end

print("[sd_v8.lua] SURGICAL loaded")
