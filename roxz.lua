-- ===============================================================
-- gacha_v5.lua — real pool from RSP, real UC cost
-- Log: /storage/emulated/0/Android/data/com.pubg.imobile/files/gacha.log
-- ===============================================================

local V = "GACHA_V5"
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

setUC(5000)
W("UC=5000")

-- ============ HUNT POOL FROM RSP ============
-- The response on_get_lucky_draw_back_activity_rsp has the real pool
local rspPool = nil
local rspPoolTime = 0
local rspActivityId = 0

local function extractPoolFromTable(t, depth)
    depth = depth or 0
    if depth > 3 or type(t) ~= "table" then return nil end
    -- Look for known pool key names
    for _, k in ipairs({ "item_table", "poolItemConfig", "pool_info", "reward_list", "award_list", "items" }) do
        local v = t[k]
        if type(v) == "table" then
            local n = 0; for _ in pairs(v) do n = n + 1 end
            if n >= 3 then
                return v, k
            end
        end
    end
    -- recurse into nested tables
    for k, v in pairs(t) do
        if type(v) == "table" then
            local found, key = extractPoolFromTable(v, depth + 1)
            if found then return found, key end
        end
    end
    return nil
end

-- ============ FIELD AUTO-DETECT ============
local idFields = { "award_item_id", "item_id", "itemId", "resid", "res_id", "id" }
local cntFields = { "award_item_num", "item_num", "item_count", "count", "num" }
local weightFields = { "award_weight", "weight", "rate", "probability", "prob" }
local qualityFields = { "show_quality", "quality", "rare" }

local function detectField(sample, candidates)
    for _, name in ipairs(candidates) do
        local v = sample[name]
        if v ~= nil then return name end
    end
    -- scan all keys for match
    for k, v in pairs(sample) do
        for _, name in ipairs(candidates) do
            if k == name then return name end
        end
    end
    return nil
end

local function dumpItem(item, tag)
    local parts = {}
    local count = 0
    for k, v in pairs(item) do
        count = count + 1
        if count > 25 then parts[#parts+1] = "<trunc>"; break end
        local tv = type(v)
        if tv == "table" then
            local n = 0; for _ in pairs(v) do n = n + 1 end
            parts[#parts+1] = k .. "=<tbl:" .. n .. ">"
        elseif tv == "string" then
            local vs = tostring(v)
            if #vs > 40 then vs = vs:sub(1, 40) .. ".." end
            parts[#parts+1] = k .. "=" .. vs
        else
            parts[#parts+1] = k .. "=" .. tostring(v)
        end
    end
    W(tag .. " keys: " .. table.concat(parts, " | "))
end

-- ============ WEIGHTED PICK WITH AUTO-DETECT ============
local lastDetect = {}

local function pickRewards(pool, count)
    if not pool then return {} end
    local arr = {}
    for _, v in pairs(pool) do
        if type(v) == "table" then arr[#arr+1] = v end
    end
    if #arr == 0 then return {} end

    -- detect field names from first item
    local sample = arr[1]
    local idF = detectField(sample, idFields)
    local cntF = detectField(sample, cntFields)
    local weightF = detectField(sample, weightFields)

    -- dump once per activity
    local sig = tostring(idF) .. "|" .. tostring(cntF) .. "|" .. tostring(weightF) .. "|" .. #arr
    if lastDetect.sig ~= sig then
        lastDetect.sig = sig
        W("DETECT id=" .. tostring(idF) .. " cnt=" .. tostring(cntF) .. " weight=" .. tostring(weightF) .. " pool=" .. #arr)
        dumpItem(sample, "SAMPLE[1]")
        if arr[2] then dumpItem(arr[2], "SAMPLE[2]") end
        if arr[3] then dumpItem(arr[3], "SAMPLE[3]") end
    end

    if not idF then
        W("no id field found — dumping all pool keys")
        for k in pairs(sample) do W("  key: " .. tostring(k)) end
        return {}
    end

    local function getId(it) return tonumber(it[idF]) or it[idF] end
    local function getCnt(it) return tonumber(it[cntF]) or 1 end
    local function getW(it)
        if weightF then
            local w = tonumber(it[weightF]) or 1
            return w > 0 and w or 1
        end
        return 1
    end

    -- total weight
    local total = 0
    for _, it in ipairs(arr) do total = total + getW(it) end
    if total <= 0 then total = #arr end

    local out = {}
    for i = 1, count do
        local r = math.random() * total
        local acc = 0
        local chosen = arr[1]
        for _, it in ipairs(arr) do
            acc = acc + getW(it)
            if r <= acc then chosen = it; break end
        end
        local resid = getId(chosen)
        if resid then
            out[#out+1] = { resid = resid, count = getCnt(chosen), valid_hours = 0 }
        end
    end
    return out
end

-- ============ FIND POOL: prefer rsp-captured, fallback module ============
local function getCurrentPool(activityId)
    -- prefer recently captured RSP pool for this activity
    if rspPool and (os.time() - rspPoolTime) < 60 then
        return rspPool, "rsp"
    end
    -- fallback to module's poolItemConfig
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

-- ============ REAL COST FROM MODULE ============
local function getCost(drawCount)
    local m = safeReq("client.slua.logic.lobby_activity.logic_luckyback_activity")
    if m then
        -- try getters first
        if drawCount >= 10 then
            if m.GetTenDrawOriginalPrice then
                local ok, v = pcall(m.GetTenDrawOriginalPrice)
                if ok and tonumber(v) and tonumber(v) > 0 then return tonumber(v) end
            end
            if m.tenDrawFinalPrice and tonumber(m.tenDrawFinalPrice) > 0 then return tonumber(m.tenDrawFinalPrice) end
            if m.tenDrawOriginalPrice and tonumber(m.tenDrawOriginalPrice) > 0 then return tonumber(m.tenDrawOriginalPrice) end
        else
            if m.GetOneDrawDiscountPrice then
                local ok, v = pcall(m.GetOneDrawDiscountPrice)
                if ok and tonumber(v) and tonumber(v) > 0 then return tonumber(v) end
            end
            if m.oneDrawFinalPrice and tonumber(m.oneDrawFinalPrice) > 0 then return tonumber(m.oneDrawFinalPrice) end
            if m.oneDrawOriginalPrice and tonumber(m.oneDrawOriginalPrice) > 0 then return tonumber(m.oneDrawOriginalPrice) end
        end
        -- globalConfig
        local gc = m.globalConfig
        if type(gc) == "table" then
            if drawCount >= 10 and tonumber(gc.tenDrawOriginalPrice) then
                return tonumber(gc.tenDrawOriginalPrice)
            end
            if drawCount < 10 and tonumber(gc.oneDrawOriginalPrice) then
                return tonumber(gc.oneDrawOriginalPrice)
            end
        end
    end
    return drawCount >= 10 and 200 or 20
end

-- ============ ACTIVITY ID FROM MODULE ============
local function getCurrentActivityId()
    local m = safeReq("client.slua.logic.lobby_activity.logic_luckyback_activity")
    if not m then return 0 end
    -- try multiple field names
    for _, k in ipairs({ "activityId", "ActivityId", "activity_id", "actId" }) do
        local v = m[k]
        if v and tonumber(v) and tonumber(v) > 0 then return tonumber(v) end
    end
    return 0
end

-- ============ CORE DRAW ============
local lastCall = 0

local function doFakeDraw(drawCount)
    local now = os.time()
    if now - lastCall < 1 then W("debounced"); return end
    lastCall = now

    local activityId = getCurrentActivityId()
    local cost = getCost(drawCount)

    -- spend UC (pad if below cost)
    local cur = getUC()
    if cur < cost then
        W("UC low (" .. cur .. ") — padding to 5000")
        setUC(5000)
        cur = 5000
    end
    setUC(cur - cost)
    W("draw cnt=" .. drawCount .. " act=" .. activityId .. " cost=" .. cost .. " UC " .. cur .. "->" .. (cur - cost))

    -- pick rewards
    local pool, src = getCurrentPool(activityId)
    W("pool src=" .. src .. " size=" .. (pool and (function() local n=0 for _ in pairs(pool) do n=n+1 end return n end)() or 0))

    local rewards = pickRewards(pool, drawCount)
    W("picked " .. #rewards .. " rewards")

    if #rewards == 0 then
        for i = 1, drawCount do
            rewards[i] = { resid = 403003, count = 1, valid_hours = 0 }
        end
        W("fallback to 403003 x" .. drawCount)
    end

    -- Show panel
    local UM = _G.UIManager
    local shown = false
    if UM and UM.UI_Config and UM.UI_Config.new_supply_get_panel then
        local cfg = UM.UI_Config.new_supply_get_panel
        local ok, err = pcall(function()
            local rewardList = {}
            for i, r in ipairs(rewards) do
                rewardList[i] = {
                    res_id = r.resid, count = r.count,
                    valid_hours = r.valid_hours or 0, getTags = 0,
                    to_res_id = 0, to_res_cnt = 0, ShowUseTime = true,
                }
            end
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
        W("panel shown=" .. tostring(shown) .. " err=" .. tostring(err))
    end

    -- Refresh events
    pcall(function()
        if _G.SafePostEvent and _G.EVENTTYPE_ACTIVITY then
            for _, evName in ipairs({ "EVENTID_LUCKYBACK_STATUS_CHANGE", "EVENTID_LUCKYBACK_REFRESH", "EVENTID_LUCKUNYBACK_STATUS_CHANGE" }) do
                local ev = _G[evName]
                if ev then _G.SafePostEvent(_G.EVENTTYPE_ACTIVITY, ev) end
            end
        end
    end)
end

-- ============ HOOK: RSP to capture pool ============
local LB_h = safeReq("client.network.Protocol.LuckybackHandler")
if LB_h and type(LB_h.on_get_lucky_draw_back_activity_rsp) == "function" then
    local orig = LB_h.on_get_lucky_draw_back_activity_rsp
    LB_h.on_get_lucky_draw_back_activity_rsp = function(...)
        local args = { ... }
        -- try to find pool in args
        for i, a in ipairs(args) do
            if type(a) == "table" then
                local found, key = extractPoolFromTable(a)
                if found then
                    rspPool = found
                    rspPoolTime = os.time()
                    local n = 0; for _ in pairs(found) do n = n + 1 end
                    W("CAPTURED pool from rsp arg[" .. i .. "]: " .. key .. " n=" .. n)
                    -- dump first item keys
                    local first
                    for _, v in pairs(found) do if type(v) == "table" then first = v; break end end
                    if first then dumpItem(first, "RSP[1]") end
                    break
                end
            end
        end
        return orig(...)
    end
    W("hooked rsp to capture pool")
end

-- ============ HOOK: MODULE draw methods ============
local LB_mod = safeReq("client.slua.logic.lobby_activity.logic_luckyback_activity")
if LB_mod then
    if type(LB_mod.do_one_draw_back_by_activity_req) == "function" then
        LB_mod.do_one_draw_back_by_activity_req = function(arg1, arg2)
            W(">>> MODULE do_one_draw_back_by_activity_req arg1=" .. tostring(arg1) .. " arg2=" .. tostring(arg2))
            doFakeDraw((arg1 == 2) and 10 or 1)
            return nil
        end
        W("hooked module draw")
    end
end

-- hook handler as fallback
if LB_h and type(LB_h.send_do_one_draw_back_by_activity_req) == "function" then
    LB_h.send_do_one_draw_back_by_activity_req = function(activityId, dc, _, _)
        W(">>> HANDLER send act=" .. tostring(activityId) .. " dc=" .. tostring(dc))
        doFakeDraw((tonumber(dc) == 2) or (tonumber(dc) == 10) and 10 or 1)
        return nil
    end
end

-- ============ boot popup ============
pop(V, "Loaded.\nUC=" .. getUC() .. "\nLog: files/gacha.log")

-- public helper
_G.GachaDumpPool = function()
    local pool, src = getCurrentPool(0)
    if pool then
        local n = 0; for _ in pairs(pool) do n = n + 1 end
        W("MANUAL DUMP src=" .. src .. " n=" .. n)
        local i = 0
        for _, v in pairs(pool) do
            i = i + 1
            if i > 5 then break end
            dumpItem(v, "DUMP[" .. i .. "]")
        end
        pop(V, "Dumped " .. n .. " items to log")
    else
        pop(V, "No pool")
    end
end

W("=== READY ===")
print("[gacha_v5] ready")
