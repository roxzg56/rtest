-- ═══════════════════════════════════════════════════════════════════
-- showroom_draw_unlock.lua v6 — SHOWROOM + FAKE DRAW/SPIN
--   Layer A: Showroom 3-layer unlock (auto-hook)
--   Layer B: Fake draw — 25+ activities
--   Layer C: Currency spoof (UC/gold/diamond = 999M)
--   Layer D: Pay/QR bypass
--   All wrapped safe. Log to file.
-- ═══════════════════════════════════════════════════════════════════

_G._SD = _G._SD or { booted = false, phase = "unknown", log = {} }

local CFG = {
    BRAND = "SHOWROOM+DRAW UNLOCK",
    DUMP_FILE = "sd_unlock_log_",
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
    LOCK_KEYWORDS = {
        "unlock","islock","canuse","canshow","isshow","isvalid","isopen",
        "checklock","checkunlock","isfree","ispaid","isunlocked",
        "getslotlockstate","getslotshowstate","canslotsbeedit","iseditable",
        "isslotunlock","checkvalid","canputon","isvalidputon","canput",
        "allowuse","allowed","isslotopen","checkunlockstate",
    },
    NEGATIVE_KEYWORDS = { "ispay","ispaid","islock","islocked","forbidden","disable","cannot" },
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
local function HAS_KW(lower, list)
    for _, kw in ipairs(list) do if string.find(lower, kw, 1, true) then return kw end end
    return nil
end
local function IS_NEG(lower) return HAS_KW(lower, CFG.NEGATIVE_KEYWORDS) end

-- ═══════════════════════════════════════════════════════════════════
-- SHOWROOM — AUTO-HOOK ENGINE
-- ═══════════════════════════════════════════════════════════════════

local function AUTO_HOOK(label, owner)
    if not owner or type(owner) ~= "table" then W("[AUTO:" .. label .. "] ✗ not table"); return 0 end
    W("─── [" .. label .. "] ───")
    local all = {}
    for k in pairs(owner) do all[#all+1] = k end
    table.sort(all, function(a,b) return tostring(a) < tostring(b) end)
    local n_h, n_d = 0, 0
    for _, k in ipairs(all) do
        if type(k) == "string" and type(owner[k]) == "function" then
            n_d = n_d + 1
            local lower = string.lower(k)
            local neg = IS_NEG(lower)
            local pos = HAS_KW(lower, CFG.LOCK_KEYWORDS)
            if (pos or neg) and lower ~= "ctor" and lower ~= "receivebeginplay" and lower ~= "_postconstruct" then
                local target = not neg
                local tag = "_sd_" .. label .. "_" .. k
                if not owner[tag] then
                    if pcall(function() owner[tag] = true; owner[k] = function() return target end end) then
                        n_h = n_h + 1
                        W(string.format("  [HOOK] %-46s → %s", k, tostring(target)))
                    end
                end
            else
                W(string.format("  [key]  %-46s", k))
            end
        end
    end
    W("[" .. label .. "] dumped=" .. n_d .. " hooked=" .. n_h)
    return n_h
end

local UIBP_PATHS = {
    { tag="SlotUI_Base",      p="client.slua.umg.lobby.Left.3DUIOverride.SocialLobby_Slot3DUI_UserInterfaceBase" },
    { tag="Slot3DUIActorBase",p="client.slua.umg.lobby.Left.3DUIOverride.SocialLobby_Slot3DUIActorBase" },
    { tag="AvatarShowSlot",   p="client.slua.umg.lobby.Left.3DUIOverride.SocialLobby_AvatarShowSlot_UIBP" },
    { tag="VehicleSlot",      p="client.slua.umg.lobby.Left.3DUIOverride.SocialLobby_VehicleSlot_UIBP" },
    { tag="WeaponSlot",       p="client.slua.umg.lobby.Left.3DUIOverride.SocialLobby_WeaponSlot_UIBP" },
    { tag="PetSlot",          p="client.slua.umg.lobby.Left.3DUIOverride.SocialLobby_PetSlot_UIBP" },
    { tag="BGWallSlot",       p="client.slua.umg.lobby.Left.3DUIOverride.SocialLobby_BGWallSlot_UIBP" },
    { tag="CollectHallEntry", p="client.slua.umg.lobby.Left.3DUIOverride.SocialLobby_CollectHallEntrance_UIBP" },
    { tag="SlotEdit_Base",    p="client.slua.umg.lobby.Left.SocialLobbySlotEdit.SocialLobby_SlotEditChildUI_Base" },
    { tag="SlotEdit_Main",    p="client.slua.umg.lobby.Left.SocialLobbySlotEdit.SocialLobby_SlotEdit_UIBP" },
    { tag="AvatarSlotEdit",   p="client.slua.umg.lobby.Left.SocialLobbySlotEdit.SocialLobby_AvatarSlotEdit_UIBP" },
    { tag="VehicleSlotEdit",  p="client.slua.umg.lobby.Left.SocialLobbySlotEdit.SocialLobby_VehicleSlotEdit_UIBP" },
    { tag="WeaponSlotEdit",   p="client.slua.umg.lobby.Left.SocialLobbySlotEdit.SocialLobby_WeaponSlotEdit_UIBP" },
    { tag="PetSlotEdit",      p="client.slua.umg.lobby.Left.SocialLobbySlotEdit.SocialLobby_PetSlotEdit_UIBP" },
    { tag="BGWallSlotEdit",   p="client.slua.umg.lobby.Left.SocialLobbySlotEdit.SocialLobby_BGWallSlotEdit_UIBP" },
    { tag="AchvSlotEdit",     p="client.slua.umg.lobby.Left.SocialLobbySlotEdit.SocialLobby_AchievementSlotEdit_UIBP" },
    { tag="SlotLockedPopup",  p="GameLua.Mod.PlanCH.Client.UI.Popup.PlanCH_Hall_Slot_Locked_UIBP" },
    { tag="EditCompBase",     p="GameLua.Mod.PlanCH.Client.UI.Edit.PlanCH_Display_Edit_Component_Base" },
    { tag="EditAvatar",       p="GameLua.Mod.PlanCH.Client.UI.Edit.PlanCH_Display_Edit_Avatar_Component" },
    { tag="EditVehicle",      p="GameLua.Mod.PlanCH.Client.UI.Edit.PlanCH_Display_Edit_Vehicle_Component" },
    { tag="EditWeapon",       p="GameLua.Mod.PlanCH.Client.UI.Edit.PlanCH_Display_Edit_Weapon_Component" },
    { tag="EditPet",          p="GameLua.Mod.PlanCH.Client.UI.Edit.PlanCH_Display_Edit_Pet_Component" },
    { tag="SkinSlotUnlock",   p="GameLua.Mod.PlanCH.Client.SubSystem.HallData.PlanCH_SkinSlotUnlock_Config" },
    { tag="SkinHallPart",     p="GameLua.Mod.PlanCH.Client.SubSystem.HallData.PlanCH_SkinHallPart_Config" },
    { tag="HallData",         p="GameLua.Mod.PlanCH.Client.SubSystem.HallData.PlanCH_HallData_Client" },
    { tag="DispAvatar",       p="GameLua.Mod.PlanCH.Client.SubSystem.Display.PlanCH_Display_Avatar_Client" },
    { tag="DispVehicle",      p="GameLua.Mod.PlanCH.Client.SubSystem.Display.PlanCH_Display_Vehicle_Client" },
    { tag="DispWeapon",       p="GameLua.Mod.PlanCH.Client.SubSystem.Display.PlanCH_Display_Weapon_Client" },
    { tag="DispPet",          p="GameLua.Mod.PlanCH.Client.SubSystem.Display.PlanCH_Display_Pet_Client" },
    { tag="DispModelMgr",     p="GameLua.Mod.PlanCH.Client.SubSystem.Display.PlanCH_Display_Model_Manager_SubSystem_Client" },
    { tag="DisplayPublic",    p="client.slua.logic.lobby.Left.SocialLobby.Logic_PlanCH_DisplayPublic" },
    { tag="HallEntry",        p="client.slua.logic.CollectionHall.LogicCollectionHallEntry" },
    { tag="SocialLobbyConst", p="client.slua.logic.lobby.Left.SocialHallConst.Logic_SocialLobbyConst" },
    { tag="DisplayConfig",    p="GameLua.Mod.PlanCH.Gameplay.Config.PlanCH_Display_Config" },
    { tag="DisplayTools",     p="GameLua.Mod.PlanCH.Tools.PlanCH_Display_Tools" },
}

local function FORCE_LEVEL()
    local dm = _G.DataMgr
    if not dm or not dm.roleData then return end
    pcall(function()
        if dm.roleData.brief_collect_hall_data then
            local old = dm.roleData.brief_collect_hall_data.hall_level
            dm.roleData.brief_collect_hall_data.hall_level = 999
            W("[LVL] hall_level: " .. tostring(old) .. " → 999")
        end
        dm.roleData.hall_level = 999
    end)
end

local function HOOK_SHOWROOM()
    W("═══ SHOWROOM LAYERS ═══")
    local total = 0
    for _, e in ipairs(UIBP_PATHS) do
        local impl = FIND(e.p, e.tag)
        if impl then total = total + AUTO_HOOK(e.tag, impl) end
    end
    W("SHOWROOM TOTAL HOOKED: " .. total)
    FORCE_LEVEL()
end

-- ═══════════════════════════════════════════════════════════════════
-- FAKE DRAW — Show reward popup
-- ═══════════════════════════════════════════════════════════════════

local function SHOW_REWARD(list)
    pcall(function()
        local LG = GM("client.slua.logic.common.CommonItemGet.Logic_CommonItemGet")
        if not LG or not LG.ShowPanel_DefaultStyle then
            W("[DRAW] Logic_CommonItemGet missing, using fallback")
            return
        end
        local formatted = {}
        for _, it in ipairs(list or {}) do
            formatted[#formatted+1] = {
                res_id = it.resid or it.resID or it.itemid or it.res_id or 0,
                count  = it.count or 1,
                valid_hours = it.valid_hours or 0,
            }
        end
        LG.ShowPanel_DefaultStyle(formatted, false, true)
        W("[DRAW] ✓ reward panel shown (" .. #formatted .. " items)")
    end)
end

local function PICK_REWARD(mod)
    if not mod then return nil end
    local pool = {}
    for _, key in ipairs({ "poolItemConfig","dropList","pool_info","AwardPoolConfig",
                           "CurSmallAwardPoolConfig","CurBigAwardPoolConfig",
                           "totalDrawAwardConfig","items","Items" }) do
        local t = mod[key]
        if type(t) == "table" then
            for _, v in ipairs(t) do pool[#pool+1] = v end
        end
    end
    if #pool == 0 then return nil end
    return pool[math.random(1, #pool)]
end

local function PROCESS_DRAW(mod, tag)
    if not mod then return end
    local pick = PICK_REWARD(mod)
    if not pick then
        W("[DRAW:" .. tag .. "] no pool — using default reward")
        -- fallback: give a common reward id
        SHOW_REWARD({ { resid = 403003, count = 1 } })
        return
    end
    local res = pick.resid or pick.resID or pick.itemid or pick.res_id or pick.ItemID or pick.item_id
    if not res then
        W("[DRAW:" .. tag .. "] pick has no res id")
        return
    end
    local cnt = pick.count or pick.item_num or pick.item_count or 1
    W("[DRAW:" .. tag .. "] → reward " .. tostring(res) .. " x" .. tostring(cnt))
    SHOW_REWARD({ { resid = tonumber(res), count = tonumber(cnt) or 1 } })
end

-- ═══════════════════════════════════════════════════════════════════
-- DRAW TARGETS — actual method names from dump
-- ═══════════════════════════════════════════════════════════════════

local DRAW_TARGETS = {
    { tag="luckyback",     p="client.slua.logic.lobby_activity.logic_luckyback_activity",
      fns={ "do_one_draw_back_by_activity_req","do_one_draw_by_tick","get_sum_draw_award_by_activity_req" } },
    { tag="luckydouble",   p="client.slua.logic.lobby_activity.logic_luckydouble_activity",
      fns={ "send_do_one_lucky_double_draw_by_activity_req","send_double_draw_on_shot_req" } },
    { tag="luckyunback",   p="client.slua.logic.lobby_activity.logic_luckyunback_activity",
      fns={ "send_do_draw_discount_by_activity_req" } },
    { tag="luckmix",       p="client.slua.logic.lobby_activity.logic_luckmix_activity",
      fns={ "DoDraw" } },
    { tag="luckymulti",    p="client.slua.logic.lobby_activity.logic_luckymulti_activity",
      fns={ "Lottery" } },
    { tag="scrapgold",     p="client.slua.logic.lobby_activity.logic_scrapgold_draw",
      fns={ "DoDraw" } },
    { tag="godzilla",      p="client.slua.logic.lobby_activity.logic_godzilla_ban",
      fns={ "OneDraw","TenDraw" } },
    { tag="crazy_weekend", p="client.slua.logic.lobby_activity.crazy_weekend.logic_crazy_weekend_luckydraw",
      fns={ "send_get_happy_weekend_ticket_req" } },
    { tag="optional_turn", p="client.slua.logic.lobby_activity.LukcyOptionalTurntable.Logic_LukcyOptionalTurntable",
      fns={ "SendDrawActReq" } },
    { tag="tarot_card",    p="client.slua.logic.tarot_card.logic_tarotcard_drawcard",
      fns={ "DoDraw" } },
    { tag="super_airdrop", p="client.slua.logic.lobby_activity.logic_super_airdrop",
      fns={ "send_choose_and_get_super_airdrop_reward_req" } },
    { tag="xsuit_act",     p="client.slua.logic.XSuit.logic_xsuit_activity",
      fns={ "send_do_draw_act_req","send_get_accumulate_pool_reward_req" } },
    { tag="ladder",        p="client.slua.logic.lobby_activity.logic_ladder_draw",
      fns={ "OnRotateRsp","OnRandomAwardRsp","OnRecvAwardRsp" } },
    -- New from v2.2 dump
    { tag="luck_airdrop",  p="client.slua.logic.luck_airdrop.LuckyAirDropModule", fns={} },
    { tag="lucky_star",    p="client.slua.logic.lucky_star.logic_luckystar", fns={} },
    { tag="lucky_exch",    p="client.slua.logic.lobby_activity.lucky_exchange.logic_lucky_exchange", fns={} },
    { tag="draw_turn",     p="client.slua.logic.draw_turn.draw_trun", fns={} },
    { tag="mix_lucky",     p="client.slua.logic.lobby_activity.logic_module_mix_lucky", fns={} },
    { tag="newbie_spin",   p="client.slua.logic.growth_project.logic_new_player_spin", fns={} },
    { tag="manor_draw",    p="client.slua.logic.home.DrawReward.logic_manor_draw_reward", fns={} },
    { tag="homestore",     p="client.slua.logic.homestore.HomeStoreChestPatial", fns={} },
    { tag="supply_chest",  p="client.slua.logic.supply.supply_collect_chest_manager", fns={ "OpenCollectChest" } },
    -- Network handlers
    { tag="store",         p="client.network.Protocol.StoreHandler",
      fns={ "send_buy_req","send_easy_buy_req" } },
    { tag="luckyback_h",   p="client.network.Protocol.LuckybackHandler",
      fns={ "send_do_exchange_by_activity_id_req","send_car_compose_req" } },
    { tag="subscribe_h",   p="client.network.Protocol.SubscribeHandler",
      fns={ "send_query_prime_info","send_take_daily_uc_priv","send_buy_discount_sale_item" } },
    { tag="lucky_special", p="client.network.Protocol.LuckySpecialHandler", fns={} },
    -- Pass / chest / special
    { tag="special_offer", p="client.slua.logic.specialoffer.special_offer_module",
      fns={ "BuySpecialOffer" } },
    { tag="pass_buy",      p="client.slua.logic.unknowpass.logic_unknowpass_buy",
      fns={ "BuyPass","BuyLevel" } },
    { tag="pass_exch",     p="client.slua.logic.unknowpass.logic_unknowpass_exchange",
      fns={ "Exchange" } },
    { tag="treasure",      p="client.slua.logic.store.treasure_chest_manager",
      fns={ "OpenTreasureChest" } },
    { tag="supply_opt",    p="client.slua.logic.store.supply_optional_chest_manager",
      fns={ "OpenOptionalChest" } },
}

local function HOOK_DRAW()
    W("═══ FAKE DRAW ═══")
    local mods_ok, hooks = 0, 0
    for _, entry in ipairs(DRAW_TARGETS) do
        local mod = GM(entry.p)
        if mod then
            mods_ok = mods_ok + 1
            for _, fn in ipairs(entry.fns) do
                local tag = "_sd_dr_" .. entry.tag .. "_" .. fn
                if type(mod[fn]) == "function" and not mod[tag] then
                    if pcall(function()
                        mod[tag] = true
                        local orig = mod[fn]
                        mod[fn] = function(self, ...)
                            W("[DRAW] " .. entry.tag .. "." .. fn .. " CALLED")
                            pcall(PROCESS_DRAW, mod, entry.tag)
                            return orig(self, ...)
                        end
                    end) then
                        hooks = hooks + 1
                    end
                end
            end
            if #entry.fns == 0 then
                W("[DRAW] " .. entry.tag .. " loaded (no fns to hook)")
            end
        else
            W("[DRAW] " .. entry.tag .. " ✗ not loaded: " .. entry.p)
        end
    end
    W("DRAW: " .. mods_ok .. " modules, " .. hooks .. " hooks")
    _G._SD.draw_mods = mods_ok
    _G._SD.draw_hooks = hooks
end

-- ═══════════════════════════════════════════════════════════════════
-- CURRENCY SPOOF + PAY BYPASS
-- ═══════════════════════════════════════════════════════════════════

local CURRENCY_KEYS = {
    "ticket","uc","gold","diamond","eternal_diamond","home_coin",
    "bp","coupon","voucher","UC","Gold","Diamond",
}

local function SPOOF_CURRENCY()
    local dm = _G.DataMgr
    if not dm then W("[CURR] DataMgr nil"); return end

    -- Direct set
    pcall(function()
        for _, k in ipairs(CURRENCY_KEYS) do
            dm[k] = CFG.UC_AMOUNT
        end
    end)

    -- Metatable fallback
    pcall(function()
        local mt = getmetatable(dm) or {}
        local oldIdx = mt.__index
        mt.__index = function(t, k)
            for _, key in ipairs(CURRENCY_KEYS) do
                if k == key then return CFG.UC_AMOUNT end
            end
            if type(oldIdx) == "function" then return oldIdx(t, k) end
            if type(oldIdx) == "table" then return oldIdx[k] end
            return rawget(t, k)
        end
        setmetatable(dm, mt)
    end)

    -- GetUserData hook
    pcall(function()
        if dm.GetUserData and not dm._sd_gu then
            dm._sd_gu = true
            local orig = dm.GetUserData
            dm.GetUserData = function(arg1)
                local d = orig(arg1)
                if d then
                    for _, k in ipairs(CURRENCY_KEYS) do d[k] = CFG.UC_AMOUNT end
                end
                return d
            end
        end
    end)
    W("[CURR] spoofed (UC=" .. CFG.UC_AMOUNT .. ")")
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
    W("[PAY] bypass armed")
end

-- ═══════════════════════════════════════════════════════════════════
-- NET — skip draw/pay server requests
-- ═══════════════════════════════════════════════════════════════════

local function HOOK_NET_DRAW()
    local h = GM("client.network.Protocol.CollectionHallEditHandler")
    if h then
        if type(h.send_edit_collect_hall_req) == "function" then
            h.send_edit_collect_hall_req = function(self, ...)
                local args = { ... }
                W("[NET] edit_collect_hall SKIP")
                pcall(function()
                    if h.on_edit_collect_hall_rsp then h.on_edit_collect_hall_rsp(0, args[1] or {}, args[2] or 0) end
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
        if type(h.send_change_collect_hall_skin_req) == "function" then
            h.send_change_collect_hall_skin_req = function(self, ...)
                local a = { ... }
                pcall(function()
                    if h.on_change_collect_hall_skin_rsp then h.on_change_collect_hall_skin_rsp(0, a[1] or 0) end
                end)
            end
        end
        if type(h.send_unlock_collect_hall_slot_req) == "function" then
            h.send_unlock_collect_hall_slot_req = function(self, ...) W("[NET] unlock_slot SKIP") end
        end
        W("[NET] CollectionHallEditHandler wired")
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- MASTER
-- ═══════════════════════════════════════════════════════════════════

function HOOK_ALL()
    W("═══ RE-ARMING ALL ═══")
    pcall(HOOK_SHOWROOM)
    pcall(HOOK_DRAW)
    pcall(SPOOF_CURRENCY)
    pcall(BYPASS_PAY)
    pcall(HOOK_NET_DRAW)
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
    W("═══════════════════════════════════════════")
    W("  SHOWROOM + FAKE DRAW — session")
    W("  Log: " .. tostring(_PATH))
    W("═══════════════════════════════════════════")
    pcall(HOOK_ALL)
    POPUP("★ " .. CFG.BRAND .. " ★",
        "Showroom + Fake Draw loaded.\n\nTest both:\n1. Collection Showroom slots\n2. Any draw/spin\n3. UC = 999M")
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

-- ═══ MANUAL API ═══
_G.SD_Status        = function()
    W("── STATUS ──")
    W("booted=" .. tostring(_G._SD.booted) .. " phase=" .. PHASE())
    W("draw_mods=" .. tostring(_G._SD.draw_mods or 0) .. " draw_hooks=" .. tostring(_G._SD.draw_hooks or 0))
    print("[SD] status dumped")
end
_G.SD_HookNow       = function() pcall(HOOK_ALL); W("[MANUAL] re-arm") end
_G.SD_ForceLevel    = function() FORCE_LEVEL(); W("[MANUAL] level forced") end
_G.SD_TestDraw      = function() SHOW_REWARD({ { resid = 403003, count = 1 } }); W("[MANUAL] test draw") end
_G.SD_TestUC        = function() SPOOF_CURRENCY(); W("[MANUAL] UC spoofed") end

-- ═══ ARM ═══
do
    local ok, tk = pcall(require, "common.time_ticker")
    if ok and tk and tk.AddTimerLoop then
        tk.AddTimerLoop(0, WATCH, -1, CFG.TICK)
        W("[WATCHDOG] armed")
    else
        pcall(WATCH)
    end
end

print("[showroom_draw_unlock.lua v6] loaded — SHOWROOM + DRAW")
