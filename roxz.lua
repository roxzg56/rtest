-- ===============================================================
-- gacha_v3.lua — Old working approach, new events, real UC deduct
-- No RSP games. Direct ShowRewardPanel call (like old code).
-- UC: pads to 5000 if below, deducts real price each draw.
-- ===============================================================

local V = "GACHA_V3"
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

-- ============ FIND ShowRewardPanel ============
local function findShowRewardPanel()
    -- 1. Global
    if type(_G.ShowRewardPanel) == "function" then return _G.ShowRewardPanel, "global" end
    -- 2. Common module paths
    local candidates = {
        "client.slua.logic.lobby_activity.logic_luckyback_activity",
        "client.slua.logic.lobby_activity.logic_luckyunback_activity",
        "client.slua.logic.store.logic_box_draw",
        "client.slua.logic.store.logic_crate",
        "client.slua.umg.lobby_activity.LuckySpin.LuckySpinMainBase",
        "client.slua.logic.common.logic_common_msg_box",
    }
    for _, path in ipairs(candidates) do
        local m = safeReq(path)
        if m and type(m.ShowRewardPanel) == "function" then return m.ShowRewardPanel, path end
    end
    -- 3. Scan package.loaded
    for path, mod in pairs(package.loaded) do
        if type(mod) == "table" and type(mod.ShowRewardPanel) == "function" then
            return mod.ShowRewardPanel, path
        end
    end
    return nil, nil
end

local ShowRewardPanel, SRP_source = findShowRewardPanel()
W("ShowRewardPanel found=" .. tostring(ShowRewardPanel ~= nil) .. " src=" .. tostring(SRP_source))

-- ============ UC SETUP ============
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
    if dMgr.roleData then
        pcall(function() dMgr.roleData.uc = n end)
    end
end

local function padUC(minVal)
    local cur = getUC()
    if cur < minVal then
        setUC(5000)
        W("UC padded from " .. cur .. " to 5000")
    end
end

-- Deduct UC (returns actual deducted amount)
local function spendUC(cost)
    local cur = getUC()
    local newVal = math.max(0, cur - cost)
    setUC(newVal)
    W("UC " .. cur .. " -> " .. newVal .. " (cost=" .. cost .. ")")
    return cost
end

-- Set up: pad on boot, hook checkers
padUC(1000)
if dMgr then
    pcall(function() dMgr.CheckUC = function() return true end end)
    pcall(function() dMgr.CheckIsEnough = function() return true end end)
    pcall(function() dMgr.CheckMoney = function() return true end end)
    pcall(function() dMgr.CheckCurrency = function() return true end end)
end

-- ============ POOL ============
local poolCache = nil
local poolTime = 0
local function getPool(actId)
    local now = os.time()
    if poolCache and (now - poolTime) < 20 then return poolCache end
    local mods = {
        safeReq("client.slua.logic.lobby_activity.logic_luckyback_activity"),
        safeReq("client.slua.logic.lobby_activity.logic_luckyunback_activity"),
    }
    for _, m in ipairs(mods) do
        if m then
            for _, k in ipairs({ "poolItemConfig", "item_table", "pool_info", "reward_list" }) do
                local p = m[k]
                if type(p) == "table" then
                    local n = 0; for _ in pairs(p) do n = n + 1 end
                    if n > 0 then
                        poolCache = p; poolTime = now
                        W("pool from " .. k .. " size=" .. n)
                        return p
                    end
                end
            end
        end
    end
    return nil
end

-- ============ WEIGHTED PICK ============
local function pickRewards(pool, count)
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
        local vh = chosen.award_item_valid_time or chosen.valid_hours or 0
        out[#out+1] = { resid = resid, res_id = resid, count = cnt, valid_hours = vh }
    end
    return out
end

-- ============ DEBOUNCE ============
local lastCall = 0
local function debounce()
    local now = os.time()
    if now - lastCall < 1 then return false end
    lastCall = now
    return true
end

-- ============ CORE DRAW ============
-- Mirrors old code: spend UC, build reward list, call ShowRewardPanel directly
local function doFakeDraw(activityId, drawCount)
    if not debounce() then return end

    -- Cost lookup
    local cost1, cost10 = 20, 200
    local lb = safeReq("client.slua.logic.lobby_activity.logic_luckyback_activity")
    if lb then
        pcall(function()
            if lb.GetOneDrawOriginalPrice then cost1 = lb.GetOneDrawOriginalPrice() or 20 end
        end)
        pcall(function()
            if lb.GetTenDrawOriginalPrice then cost10 = lb.GetTenDrawOriginalPrice() or 200 end
        end)
    end
    local cost = (drawCount == 10) and cost10 or cost1

    -- UC deduct (pad first if needed)
    padUC(cost + 100)
    spendUC(cost)

    -- Build reward list
    local pool = getPool(activityId)
    local rewards = {}
    if pool then
        rewards = pickRewards(pool, drawCount)
    end
    if #rewards == 0 then
        for i = 1, drawCount do
            rewards[i] = { resid = 403003, res_id = 403003, count = 1, valid_hours = 0 }
        end
    end

    W("draw act=" .. activityId .. " cnt=" .. drawCount .. " rewards=" .. #rewards .. " cost=" .. cost)

    -- Call ShowRewardPanel directly — THIS is what makes OK work
    if ShowRewardPanel then
        local ok, err = pcall(ShowRewardPanel, rewards)
        W("ShowRewardPanel ok=" .. tostring(ok) .. " err=" .. tostring(err))
        if not ok then
            -- try alternate shapes
            pcall(ShowRewardPanel, rewards, false)
            pcall(ShowRewardPanel, rewards, true)
        end
    else
        W("ShowRewardPanel NOT FOUND — trying global event fallback")
        -- Fallback: fire SafePostEvent if available
        pcall(function()
            if _G.SafePostEvent and _G.EVENTTYPE_ACTIVITY then
                _G.SafePostEvent(_G.EVENTTYPE_ACTIVITY, _G.EVENTID_LUCKYBACK_REFRESH)
            end
        end)
    end

    -- Status refresh events (like old code)
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

-- ============ HOOKS ============
-- Luckyback path (new events)
local LB = safeReq("client.network.Protocol.LuckybackHandler")
if LB then
    local orig = LB.send_do_one_draw_back_by_activity_req
    if type(orig) == "function" then
        LB.send_do_one_draw_back_by_activity_req = function(activityId, drawCount, _, _)
            local cnt = (tonumber(drawCount) == 2) and 10 or 1
            W("LB send act=" .. tostring(activityId) .. " cnt=" .. cnt)
            doFakeDraw(tonumber(activityId) or 0, cnt)
            return nil
        end
        W("hooked LB send")
    end
end

-- Store path (old events)
local SH = safeReq("client.network.Protocol.StoreHandler")
if SH then
    local orig = SH.send_do_one_draw_by_activity_req
    if type(orig) == "function" then
        SH.send_do_one_draw_by_activity_req = function(activityId, roundCount, _, _)
            local cnt = (tonumber(roundCount) == 2 or tonumber(roundCount) == 10) and 10 or 1
            W("SH send act=" .. tostring(activityId) .. " cnt=" .. cnt)
            doFakeDraw(tonumber(activityId) or 0, cnt)
            return nil
        end
        W("hooked SH send")
    end
end

-- Public API
_G.GachaStatus = function()
    local pool = getPool(0)
    local n = 0
    if pool then for _ in pairs(pool) do n = n + 1 end end
    pop(V, "UC=" .. getUC() .. "\nPool=" .. n .. "\nSRP=" .. tostring(SRP_source))
end

_G.GachaPadUC = function()
    setUC(5000)
    pop(V, "UC set to 5000")
end

-- Boot popup
padUC(1000)
pop(V, "Loaded.\nUC=" .. getUC() .. "\nSRP found: " .. tostring(SRP_source or "NO") .. "\nLog: files/gacha.log")

W("=== READY ===")
print("[gacha_v3] ready")
