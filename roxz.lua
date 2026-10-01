-- ===============================================================
-- gacha_v7.1.lua — silent (no popup)
-- Log: /storage/emulated/0/Android/data/com.pubg.imobile/files/gacha.log
-- ===============================================================

local V = "GACHA_V7.1"
local LOG_PATH = "/storage/emulated/0/Android/data/com.pubg.imobile/files/gacha.log"
local SHOW_POPUP = false   -- <<<<< YAHAN TOGGLE — false = silent

local function W(m)
    pcall(function()
        local f = io.open(LOG_PATH, "a")
        if f then f:write(os.date("%H:%M:%S") .. " [" .. V .. "] " .. tostring(m) .. "\n"); f:close() end
    end)
end

local function pop(t, m)
    if not SHOW_POPUP then return end   -- silent gate
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

W("=== BOOT " .. os.date() .. " (silent) ===")

-- ===============================================================
-- UC LAYER
-- ===============================================================
local dMgr = _G.DataMgr or safeReq("client.slua.logic.common.DataMgr") or safeReq("client.data.DataMgr")

local function randBigUC() return math.random(50000000, 80000000) end
local function randBonus() return math.random(5000, 500000) end
local function randDebit() return math.random(1000, 50000) end

local function getUC()
    if not dMgr then return 0 end
    local ok, v = pcall(function() return dMgr.uc end)
    return (ok and tonumber(v)) or 0
end

local function setUC(n)
    if not dMgr then return end
    n = math.max(0, math.floor(n))
    pcall(function() dMgr.uc = n end)
    pcall(function() dMgr.UC = n end)
    pcall(function() dMgr.ticket = n end)
    if dMgr.roleData then pcall(function() dMgr.roleData.uc = n end) end
    local ES = _G.EventSystem
    local ET = _G.EVENTTYPE_DATA_MGR
    if ES and ET and ES.postEvent then
        for _, evName in ipairs({ "EVENTID_DATAMGR_GOLD_CHANGE", "EVENTID_DATAMGR_TICKET_CHANGE", "EVENTID_DATAMGR_DIAMOND_CHANGE" }) do
            local ev = _G[evName]
            if ev then pcall(function() ES:postEvent(ET, ev, n) end) end
        end
    end
    pcall(function()
        if _G.SafePostEvent and _G.EVENTTYPE_ROLE and _G.EVENTID_ROLE_DATA_UPDATE then
            _G.SafePostEvent(_G.EVENTTYPE_ROLE, _G.EVENTID_ROLE_DATA_UPDATE)
        end
    end)
end

local bootUC = randBigUC()
setUC(bootUC)
W("UC boot = " .. bootUC .. " (random 50M-80M)")

local function applyRandomMovement()
    if math.random() < 0.40 then
        local b = randBonus()
        setUC(getUC() + b)
        W("UC +" .. b .. " -> " .. getUC())
    end
    if math.random() < 0.20 then
        local d = randDebit()
        setUC(getUC() - d)
        W("UC -" .. d .. " -> " .. getUC())
    end
end

local lastRefill = 0
local function refillUC()
    local r = randBigUC()
    local tries = 0
    while math.abs(r - lastRefill) < 1000000 and tries < 10 do
        r = randBigUC(); tries = tries + 1
    end
    lastRefill = r
    setUC(r)
    W("UC refill -> " .. r)
    return r
end

-- ===============================================================
-- PER-ACTIVITY POOL CACHE
-- ===============================================================
local rspPools = {}
local currentRspActivityId = 0

local function extractPoolFromTable(t, depth)
    depth = depth or 0
    if depth > 3 or type(t) ~= "table" then return nil end
    for _, k in ipairs({ "item_table", "poolItemConfig", "pool_info", "reward_list", "award_list", "items" }) do
        local v = t[k]
        if type(v) == "table" then
            local n = 0; for _ in pairs(v) do n = n + 1 end
            if n >= 3 then return v, k end
        end
    end
    for k, v in pairs(t) do
        if type(v) == "table" then
            local found, key = extractPoolFromTable(v, depth + 1)
            if found then return found, key end
        end
    end
    return nil
end

local function extractActivityIdFromArgs(args)
    for _, a in ipairs(args) do
        if type(a) == "number" and a > 100000 then return a end
        if type(a) == "table" then
            for _, k in ipairs({ "ActivityId", "activityId", "activity_id", "actId" }) do
                local v = a[k]
                if tonumber(v) and tonumber(v) > 100000 then return tonumber(v) end
            end
        end
    end
    return 0
end

local idCandidates = { "award_item_id", "item_id", "itemId", "resid", "res_id", "id" }
local cntCandidates = { "award_item_num", "item_num", "item_count", "itemCount", "count", "num" }
local weightCandidates = { "award_weight", "weight", "rate", "probability", "prob" }
local posCandidates = { "pos_id", "posId", "position", "index" }
local vhCandidates = { "award_item_valid_time", "vaild_time", "valid_hours", "validHours" }

local function detectField(sample, candidates)
    for _, name in ipairs(candidates) do
        if sample[name] ~= nil then return name end
    end
    return nil
end

local function pickRewards(pool, count)
    if not pool then return {} end
    local arr = {}
    for _, v in pairs(pool) do
        if type(v) == "table" then arr[#arr+1] = v end
    end
    if #arr == 0 then return {} end
    local sample = arr[1]
    local idF = detectField(sample, idCandidates)
    local cntF = detectField(sample, cntCandidates)
    local weightF = detectField(sample, weightCandidates)
    local posF = detectField(sample, posCandidates)
    local vhF = detectField(sample, vhCandidates)
    if not idF then W("no id field"); return {} end

    local total = 0
    for _, it in ipairs(arr) do
        local w = weightF and tonumber(it[weightF]) or 1
        if not w or w <= 0 then w = 1 end
        total = total + w
    end
    if total <= 0 then total = #arr end

    local used, out, attempts = {}, {}, 0
    local maxAttempts = count * 30
    while #out < count and attempts < maxAttempts do
        attempts = attempts + 1
        local r = math.random() * total
        local acc = 0
        local chosen = arr[1]
        for _, it in ipairs(arr) do
            local w = weightF and tonumber(it[weightF]) or 1
            if not w or w <= 0 then w = 1 end
            acc = acc + w
            if r <= acc then chosen = it; break end
        end
        local rid = tonumber(chosen[idF]) or chosen[idF]
        if rid and not used[rid] then
            used[rid] = true
            local idx = #out + 1
            out[#out+1] = {
                resid = rid,
                count = cntF and tonumber(chosen[cntF]) or 1,
                valid_hours = vhF and tonumber(chosen[vhF]) or 0,
                pos_id = posF and tonumber(chosen[posF]) or idx,
            }
        end
    end
    if #out < count then
        for i = #out + 1, count do
            local chosen = arr[math.random(#arr)]
            local rid = tonumber(chosen[idF]) or chosen[idF]
            out[#out+1] = {
                resid = rid,
                count = cntF and tonumber(chosen[cntF]) or 1,
                valid_hours = vhF and tonumber(chosen[vhF]) or 0,
                pos_id = posF and tonumber(chosen[posF]) or i,
            }
        end
    end
    local uniq = 0
    do local u = {}; for _, r in ipairs(out) do u[r.resid] = true end
       for _ in pairs(u) do uniq = uniq + 1 end end
    W("picked " .. #out .. " unique=" .. uniq)
    return out
end

local function getPool(activityId)
    if activityId and activityId > 0 then
        local e = rspPools[activityId]
        if e and e.pool and (os.time() - e.time) < 300 then
            local n = 0; for _ in pairs(e.pool) do n = n + 1 end
            W("pool act=" .. activityId .. " n=" .. n)
            return e.pool, "cache"
        end
    end
    local latest, lt = nil, 0
    for _, e in pairs(rspPools) do
        if e.pool and e.time > lt then latest = e.pool; lt = e.time end
    end
    if latest then
        local n = 0; for _ in pairs(latest) do n = n + 1 end
        W("pool latest n=" .. n); return latest, "latest"
    end
    local m = safeReq("client.slua.logic.lobby_activity.logic_luckyback_activity")
    if m then
        for _, k in ipairs({ "item_table", "poolItemConfig", "pool_info", "reward_list" }) do
            local p = m[k]
            if type(p) == "table" then
                local n = 0; for _ in pairs(p) do n = n + 1 end
                if n >= 3 then return p, "module:" .. k end
            end
        end
    end
    return nil, "none"
end

local function getCost(activityId, drawCount)
    local m = safeReq("client.slua.logic.lobby_activity.logic_luckyback_activity")
    if m then
        if drawCount >= 10 then
            if m.GetTenDrawOriginalPrice then
                local ok, v = pcall(m.GetTenDrawOriginalPrice)
                if ok and tonumber(v) and tonumber(v) > 0 then return tonumber(v) end
            end
            if tonumber(m.tenDrawFinalPrice) and tonumber(m.tenDrawFinalPrice) > 0 then return tonumber(m.tenDrawFinalPrice) end
            if tonumber(m.tenDrawOriginalPrice) and tonumber(m.tenDrawOriginalPrice) > 0 then return tonumber(m.tenDrawOriginalPrice) end
        else
            if m.GetOneDrawDiscountPrice then
                local ok, v = pcall(m.GetOneDrawDiscountPrice)
                if ok and tonumber(v) and tonumber(v) > 0 then return tonumber(v) end
            end
            if tonumber(m.oneDrawFinalPrice) and tonumber(m.oneDrawFinalPrice) > 0 then return tonumber(m.oneDrawFinalPrice) end
            if tonumber(m.oneDrawOriginalPrice) and tonumber(m.oneDrawOriginalPrice) > 0 then return tonumber(m.oneDrawOriginalPrice) end
        end
        local gc = m.globalConfig
        if type(gc) == "table" then
            if drawCount >= 10 and tonumber(gc.tenDrawOriginalPrice) then return tonumber(gc.tenDrawOriginalPrice) end
            if drawCount < 10 and tonumber(gc.oneDrawOriginalPrice) then return tonumber(gc.oneDrawOriginalPrice) end
        end
    end
    return drawCount >= 10 and 200 or 20
end

local function getCurrentActivityId()
    local m = safeReq("client.slua.logic.lobby_activity.logic_luckyback_activity")
    if not m then return currentRspActivityId end
    for _, k in ipairs({ "activityId", "ActivityId", "activity_id", "actId" }) do
        local v = m[k]
        if tonumber(v) and tonumber(v) > 100000 then return tonumber(v) end
    end
    return currentRspActivityId
end

local function buildServerShape(rewards)
    local out = {}
    for i, r in ipairs(rewards) do
        out[i] = {
            resid = r.resid, res_id = r.resid,
            count = r.count or 1, index = i,
            display_sort = r.pos_id or i, close_time = 0,
            show_new = false, is_show_up = false,
            valid_hours = r.valid_hours or 0,
            getTags = 0, to_res_id = 0, to_res_cnt = 0, ShowUseTime = true,
        }
    end
    return out
end

-- ===============================================================
-- CORE DRAW
-- ===============================================================
local lastCall = 0

local function doFakeDraw(drawCount)
    local now = os.time()
    if now - lastCall < 1 then W("debounced"); return end
    lastCall = now

    local activityId = getCurrentActivityId()
    local cost = getCost(activityId, drawCount)

    local cur = getUC()
    if cur < cost then W("UC low"); cur = refillUC() end
    setUC(cur - cost)
    W("draw cnt=" .. drawCount .. " act=" .. activityId .. " cost=" .. cost .. " UC " .. cur .. "->" .. (cur - cost))

    local pool, src = getPool(activityId)
    local pn = 0
    if pool then for _ in pairs(pool) do pn = pn + 1 end end
    W("pool src=" .. src .. " n=" .. pn)

    local rewards = pickRewards(pool, drawCount)
    if #rewards == 0 then
        for i = 1, drawCount do rewards[i] = { resid = 403003, count = 1, valid_hours = 0 } end
    end

    local rewardList = buildServerShape(rewards)

    local UM = _G.UIManager
    local shown = false
    if UM and UM.UI_Config and UM.UI_Config.new_supply_get_panel then
        local cfg = UM.UI_Config.new_supply_get_panel
        pcall(function()
            if UM.IsUIShow and UM.IsUIShow(cfg) then
                local boxUI = UM.GetUI(cfg)
                if boxUI and boxUI.TryShowSupplyGetPanel then
                    boxUI:TryShowSupplyGetPanel(rewardList, drawCount >= 10, {needShowMovie = true})
                    shown = true
                end
            else
                UM.ShowUI(cfg, rewardList, drawCount >= 10, {needShowMovie = true})
                shown = true
            end
        end)
        W("panel shown=" .. tostring(shown))
    end

    applyRandomMovement()

    pcall(function()
        if _G.SafePostEvent and _G.EVENTTYPE_ACTIVITY then
            for _, evName in ipairs({ "EVENTID_LUCKYBACK_STATUS_CHANGE", "EVENTID_LUCKYBACK_REFRESH" }) do
                local ev = _G[evName]
                if ev then _G.SafePostEvent(_G.EVENTTYPE_ACTIVITY, ev) end
            end
        end
    end)
end

-- ===============================================================
-- HOOKS
-- ===============================================================
local LB_h = safeReq("client.network.Protocol.LuckybackHandler")
if LB_h and type(LB_h.on_get_lucky_draw_back_activity_rsp) == "function" then
    local orig = LB_h.on_get_lucky_draw_back_activity_rsp
    LB_h.on_get_lucky_draw_back_activity_rsp = function(...)
        local args = { ... }
        local actId = extractActivityIdFromArgs(args)
        if actId == 0 then actId = getCurrentActivityId() end
        local found, key
        for _, a in ipairs(args) do
            if type(a) == "table" then
                local p, k = extractPoolFromTable(a)
                if p then found = p; key = k; break end
            end
        end
        if found then
            local n = 0; for _ in pairs(found) do n = n + 1 end
            rspPools[actId] = { pool = found, time = os.time(), src = "rsp:" .. tostring(key) }
            currentRspActivityId = actId
            W("CACHED pool act=" .. actId .. " n=" .. n)
        end
        return orig(...)
    end
end

local LB_mod = safeReq("client.slua.logic.lobby_activity.logic_luckyback_activity")
if LB_mod and type(LB_mod.do_one_draw_back_by_activity_req) == "function" then
    LB_mod.do_one_draw_back_by_activity_req = function(arg1, arg2)
        W(">>> MODULE do arg1=" .. tostring(arg1))
        doFakeDraw((arg1 == 2) and 10 or 1)
        return nil
    end
end

if LB_h and type(LB_h.send_do_one_draw_back_by_activity_req) == "function" then
    LB_h.send_do_one_draw_back_by_activity_req = function(activityId, dc, _, _)
        W(">>> HANDLER act=" .. tostring(activityId))
        if tonumber(activityId) and tonumber(activityId) > 100000 then
            currentRspActivityId = tonumber(activityId)
        end
        doFakeDraw((tonumber(dc) == 2) or (tonumber(dc) == 10) and 10 or 1)
        return nil
    end
end

-- ===============================================================
-- BOOT POPUP
-- ===============================================================
pop(V, "Loaded.\nUC=" .. getUC() .. " (random)\nLog: files/gacha.log")
W("=== READY ===")
print("[gacha_v7] ready")
