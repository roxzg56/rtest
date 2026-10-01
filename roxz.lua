-- ===============================================================
-- gacha_v4.lua — hook MODULE method (not handler) + force-enable button
-- Log: /storage/emulated/0/Android/data/com.pubg.imobile/files/gacha.log
-- ===============================================================

local V = "GACHA_V4"
local LOG_PATH = "/storage/emulated/0/Android/data/com.pubg.imobile/files/gacha.log"

local function W(m)
    pcall(function()
        local f = io.open(LOG_PATH, "a")
        if f then f:write(os.date("%H:%M:%S") .. " [" .. V .. "] " .. tostring(m) .. "\n"); f:close() end
    end)
end

local function pop(t, m)
    pcall(function()
        local M = package.loaded["client.slua.logic.common.logic_common_msg_box"]
                    or require("client.slua.logic.common.logic_common_msg_box")
        if M and M.Show then M.Show(4, tostring(t), tostring(m)) end
    end)
end

local function safeReq(...)
    for _, p in ipairs({...}) do
        local ok, m = pcall(require, p)
        if ok and m then return m end
    end
    return nil
end

W("=== BOOT " .. os.date() .. " ===")

-- ============ UC ============
local dMgr = _G.DataMgr or safeReq("client.slua.logic.common.DataMgr") or safeReq("client.data.DataMgr")

local function getUC()
    if not dMgr then return 0 end
    local ok, v = pcall(function() return dMgr.uc end)
    return (ok and tonumber(v)) or 0
end

local function setUC(n)
    if not dMgr then return end
    pcall(function() dMgr.uc = n end)
    pcall(function() dMgr.UC = n end)
    pcall(function() dMgr.ticket = n end)
    if dMgr.roleData then
        pcall(function() dMgr.roleData.uc = n end)
    end
    -- Fire UI refresh events
    local ES = _G.EventSystem
    local ET = _G.EVENTTYPE_DATA_MGR
    if ES and ET and ES.postEvent then
        if _G.EVENTID_DATAMGR_GOLD_CHANGE then
            pcall(function() ES:postEvent(ET, _G.EVENTID_DATAMGR_GOLD_CHANGE, n) end)
        end
        if _G.EVENTID_DATAMGR_TICKET_CHANGE then
            pcall(function() ES:postEvent(ET, _G.EVENTID_DATAMGR_TICKET_CHANGE, n) end)
        end
        if _G.EVENTID_DATAMGR_DIAMOND_CHANGE then
            pcall(function() ES:postEvent(ET, _G.EVENTID_DATAMGR_DIAMOND_CHANGE, n) end)
        end
    end
    -- Also try SafePostEvent
    pcall(function()
        if _G.SafePostEvent and _G.EVENTTYPE_ROLE and _G.EVENTID_ROLE_DATA_UPDATE then
            _G.SafePostEvent(_G.EVENTTYPE_ROLE, _G.EVENTID_ROLE_DATA_UPDATE)
        end
    end)
end

-- Pad and refresh
setUC(5000)
W("UC set to 5000 + events fired")

-- Keep checkers true
if dMgr then
    pcall(function() dMgr.CheckUC = function() return true end end)
    pcall(function() dMgr.CheckIsEnough = function() return true end end)
    pcall(function() dMgr.CheckMoney = function() return true end end)
    pcall(function() dMgr.CheckCurrency = function() return true end end)
    pcall(function() dMgr.GetUC = function() return getUC() end end)
end

-- ============ RESET isWaitingForRes on all activity modules ============
local function resetFlags()
    local paths = {
        "client.slua.logic.lobby_activity.logic_luckyback_activity",
        "client.slua.logic.lobby_activity.logic_luckyunback_activity",
        "client.slua.logic.lobby_activity.logic_luckydouble_activity",
        "client.slua.logic.lobby_activity.logic_scrapgold_draw",
    }
    for _, p in ipairs(paths) do
        local m = safeReq(p)
        if m then
            pcall(function() m.isWaitingForRes = false end)
            pcall(function() m.bIsDrawRsp = false end)
            pcall(function() m.bIsDrawing = false end)
            pcall(function() m.bIsRandowAwardRsp = false end)
            pcall(function() m.isClicked = false end)
            pcall(function() m.bIsReq = false end)
        end
    end
end
resetFlags()
W("flags reset")

-- ============ UC check bypass on LuckySpin module ============
local function patchUCModule()
    local m = safeReq("client.slua.logic.lobby_activity.logic_luckyback_activity")
    if m then
        pcall(function() m.GetOneDrawDiscountPrice = function() return 0 end end)
        pcall(function() m.GetTenDrawDiscountPrice = function() return 0 end end)
        pcall(function() m.GetOneDrawOriginalPrice = function() return 20 end end)
        pcall(function() m.GetTenDrawOriginalPrice = function() return 200 end end)
        pcall(function() m.HasEnoughUC = function() return true end end)
        pcall(function() m.CheckCanDraw = function() return true end end)
        pcall(function() m.CheckMoneyEnough = function() return true end end)
    end
    local u = safeReq("client.slua.logic.lobby_activity.logic_luckyunback_activity")
    if u then
        pcall(function() u.GetNextDrawCost = function() return 0 end end)
        pcall(function() u.HasEnoughUC = function() return true end end)
        pcall(function() u.CheckCanDraw = function() return true end end)
    end
end
patchUCModule()
W("UC module methods patched")

-- ============ POOL ============
local poolCache, poolTime = nil, 0
local function getPool()
    local now = os.time()
    if poolCache and (now - poolTime) < 20 then return poolCache end
    local m = safeReq("client.slua.logic.lobby_activity.logic_luckyback_activity")
    if m then
        for _, k in ipairs({ "poolItemConfig", "item_table", "pool_info", "reward_list" }) do
            local p = m[k]
            if type(p) == "table" then
                local n = 0; for _ in pairs(p) do n = n + 1 end
                if n > 0 then
                    poolCache = p; poolTime = now
                    W("pool " .. k .. " n=" .. n)
                    return p
                end
            end
        end
    end
    return nil
end

local function pickRewards(count)
    local pool = getPool()
    if not pool then return {} end
    local arr = {}
    for _, v in pairs(pool) do
        if type(v) == "table" then arr[#arr+1] = v end
    end
    if #arr == 0 then return {} end
    local total = 0
    for _, it in ipairs(arr) do
        local w = tonumber(it.award_weight) or tonumber(it.weight) or 1
        if w > 0 then total = total + w end
    end
    if total <= 0 then total = #arr end
    local out = {}
    for i = 1, count do
        local r = math.random() * total
        local acc = 0
        local chosen = arr[1]
        for _, it in ipairs(arr) do
            local w = tonumber(it.award_weight) or tonumber(it.weight) or 1
            if w <= 0 then w = 1 end
            acc = acc + w
            if r <= acc then chosen = it; break end
        end
        local resid = chosen.award_item_id or chosen.resid or chosen.res_id
            or chosen.itemid or chosen.id or 403003
        local cnt = chosen.award_item_num or chosen.count or 1
        out[#out+1] = { resid = resid, count = cnt, valid_hours = 0 }
    end
    return out
end

-- ============ HUNT ShowRewardPanel + EndRewardPanel ============
-- Look for the REAL one — search by usage pattern
local function findRealShowRewardPanel()
    -- preferred: from LuckybackHandler or StoreHandler
    local LB = safeReq("client.network.Protocol.LuckybackHandler")
    local SH = safeReq("client.network.Protocol.StoreHandler")
    local candidates = { LB, SH, _G }
    for _, mod in ipairs(candidates) do
        if mod then
            if type(mod.ShowRewardPanel) == "function" then return mod.ShowRewardPanel, "mod" end
            if type(mod.showRewardPanel) == "function" then return mod.showRewardPanel, "mod-lower" end
        end
    end
    -- search by name in package.loaded
    for path, mod in pairs(package.loaded) do
        if type(mod) == "table" then
            if type(mod.ShowRewardPanel) == "function" then
                -- skip if from unrelated namespaces
                if not path:find("return_activity") then
                    return mod.ShowRewardPanel, path
                end
            end
        end
    end
    return nil, nil
end

local ShowRewardPanel, SRP_src = findRealShowRewardPanel()
W("ShowRewardPanel=" .. tostring(ShowRewardPanel ~= nil) .. " src=" .. tostring(SRP_src))

-- ============ Find the UI panel that luckyback uses ============
local function findRewardUI()
    local UM = _G.UIManager
    if not UM or not UM.UI_Config then return nil end
    local cfg = UM.UI_Config
    -- look for panel names
    local names = {
        "new_supply_get_panel", "supply_get_panel", "supply_get",
        "luckyback_get_panel", "lucky_get_panel", "reward_panel",
        "new_reward_panel", "common_reward_panel",
        "luckyback_reward_panel", "get_item_panel",
    }
    for _, name in ipairs(names) do
        if cfg[name] then return name, cfg[name] end
    end
    return nil, nil
end

local uiPanelName, uiPanelCfg = findRewardUI()
W("uiPanelName=" .. tostring(uiPanelName))

-- ============ CORE FAKE DRAW ============
local lastCall = 0

local function doFakeDraw(activityId, drawCount)
    local now = os.time()
    if now - lastCall < 1 then W("debounced"); return end
    lastCall = now

    -- UC cost
    local cost = (drawCount == 10) and 200 or 20
    local before = getUC()
    if before < cost then setUC(5000); before = 5000 end
    setUC(before - cost)
    W("UC " .. before .. "->" .. (before-cost) .. " cost=" .. cost)

    -- Rewards
    local rewards = pickRewards(drawCount)
    W("picked " .. #rewards .. " rewards for act=" .. activityId)

    -- Show via UI panel if we found it
    local shown = false
    local UM = _G.UIManager
    if UM and uiPanelName and uiPanelCfg then
        local ok, err = pcall(function()
            local rewardList = {}
            for i, r in ipairs(rewards) do
                rewardList[i] = {
                    res_id = r.resid, count = r.count,
                    valid_hours = r.valid_hours or 0, getTags = 0,
                    to_res_id = 0, to_res_cnt = 0, ShowUseTime = true,
                }
            end
            if UM.IsUIShow and UM.IsUIShow(uiPanelCfg) then
                local boxUI = UM.GetUI(uiPanelCfg)
                if boxUI and boxUI.TryShowSupplyGetPanel then
                    boxUI:TryShowSupplyGetPanel(rewardList, drawCount >= 10, {needShowMovie = true})
                    shown = true
                end
            else
                UM.ShowUI(uiPanelCfg, rewardList, drawCount >= 10, {needShowMovie = true})
                shown = true
            end
        end)
        W("panel show ok=" .. tostring(ok) .. " shown=" .. tostring(shown) .. " err=" .. tostring(err))
    end

    if not shown and ShowRewardPanel then
        local ok, err = pcall(ShowRewardPanel, rewards)
        W("SRP call ok=" .. tostring(ok) .. " err=" .. tostring(err))
    end

    -- Refresh events
    pcall(function()
        if _G.SafePostEvent and _G.EVENTTYPE_ACTIVITY then
            if _G.EVENTID_LUCKYBACK_STATUS_CHANGE then
                _G.SafePostEvent(_G.EVENTTYPE_ACTIVITY, _G.EVENTID_LUCKYBACK_STATUS_CHANGE)
            end
            if _G.EVENTID_LUCKYBACK_REFRESH then
                _G.SafePostEvent(_G.EVENTTYPE_ACTIVITY, _G.EVENTID_LUCKYBACK_REFRESH)
            end
        end
    end)
end

-- ============ HOOK: module method (what button actually calls) ============
local function hookModuleMethod(mod, methodName, wrapper)
    if type(mod) ~= "table" then return false end
    if type(mod[methodName]) ~= "function" then return false end
    local orig = mod[methodName]
    mod[methodName] = wrapper(orig)
    return true
end

-- ============ HOOK: Luckyback activity module direct methods ============
local LB_mod = safeReq("client.slua.logic.lobby_activity.logic_luckyback_activity")
if LB_mod then
    local hooked = false
    if type(LB_mod.do_one_draw_back_by_activity_req) == "function" then
        local orig = LB_mod.do_one_draw_back_by_activity_req
        LB_mod.do_one_draw_back_by_activity_req = function(arg1, arg2, ...)
            W(">>> MODULE do_one_draw_back_by_activity_req arg1=" .. tostring(arg1) .. " arg2=" .. tostring(arg2))
            local cnt = (arg1 == 2) and 10 or 1
            doFakeDraw(LB_mod.ActivityId or 0, cnt)
            return nil
        end
        hooked = true
        W("hooked LB_mod.do_one_draw_back_by_activity_req")
    end
    if type(LB_mod.do_one_draw_by_tick) == "function" then
        LB_mod.do_one_draw_by_tick = function(...)
            W(">>> MODULE do_one_draw_by_tick")
            doFakeDraw(LB_mod.ActivityId or 0, 1)
            return nil
        end
        hooked = true
        W("hooked LB_mod.do_one_draw_by_tick")
    end
    -- also try common names
    for _, name in ipairs({ "DoDraw", "Draw", "RequestDraw", "OneDraw", "TenDraw" }) do
        if type(LB_mod[name]) == "function" and not hooked then
            local orig = LB_mod[name]
            LB_mod[name] = function(...)
                W(">>> MODULE " .. name)
                doFakeDraw(LB_mod.ActivityId or 0, 1)
                return nil
            end
            hooked = true
            W("hooked LB_mod." .. name)
        end
    end
    if not hooked then W("no module method hooked on LB_mod") end
end

-- ============ HOOK: Handler (fallback) ============
local LB_h = safeReq("client.network.Protocol.LuckybackHandler")
if LB_h and type(LB_h.send_do_one_draw_back_by_activity_req) == "function" then
    LB_h.send_do_one_draw_back_by_activity_req = function(activityId, dc, _, _)
        W(">>> HANDLER send dc=" .. tostring(dc))
        local cnt = (tonumber(dc) == 2) and 10 or 1
        doFakeDraw(tonumber(activityId) or 0, cnt)
        return nil
    end
    W("hooked handler send")
end

-- ============ FORCE ENABLE DRAW BUTTONS ============
local function forceEnableButtons()
    local paths = {
        "client.slua.umg.lobby_activity.LuckySpin.TraitClassStyle.Supply.T_BackStyleDrawTenBtn_Supply",
        "client.slua.umg.lobby_activity.LuckySpin.TraitClassStyle.Supply.T_BackStyleDrawOneBtn_Supply",
    }
    for _, p in ipairs(paths) do
        local m = safeReq(p)
        if m then
            pcall(function()
                if m.CheckIsShowReplaceDraw then m.CheckIsShowReplaceDraw = function() return true end end
                if m.CanUse then m.CanUse = function() return true end end
                if m.IsEnabled then m.IsEnabled = function() return true end end
            end)
            -- Hook click
            for _, name in ipairs({ "_OnButtonClicked_DrawTen", "_OnButtonClicked_DrawOne", "OnClick" }) do
                if type(m[name]) == "function" then
                    local orig = m[name]
                    m[name] = function(self, ...)
                        W(">>> BTN " .. p .. "::" .. name)
                        -- Try calling original; if it crashes, do fake
                        local ok, err = pcall(orig, self, ...)
                        W("btn orig ok=" .. tostring(ok))
                        -- If the original didn't reach the handler within 100ms, do fake from here
                        local t0 = os.time()
                        -- We can't easily check "did handler fire" — just trust hook chain
                        return
                    end
                    W("hooked button " .. name)
                end
            end
        end
    end
end
forceEnableButtons()

-- ============ boot popup ============
pop(V, "Loaded.\nUC=" .. getUC() .. "\nSRP: " .. tostring(SRP_src or "NO") ..
      "\nUI Panel: " .. tostring(uiPanelName or "NO") .. "\nLog: files/gacha.log")

-- Public
_G.GachaStatus = function()
    pop(V, "UC=" .. getUC() .. "\nLog: files/gacha.log")
end

W("=== READY ===")
print("[gacha_v4] ready")
