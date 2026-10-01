-- ===============================================================
-- fake_gacha.lua v2 — correct path + RSP intercept
-- Strategy:
--   1. Let original send fire (server error 6494 comes back)
--   2. Intercept on_do_one_draw_back_by_activity_rsp
--   3. If errCode != 0, replace with fake success + real pool rewards
--   4. UI's own handler opens the reward panel
-- Log path: GAME'S OWN FOLDER (scoped storage safe)
-- ===============================================================

local VERSION = "FAKE_GACHA_V2"

-- ============ PATH (game's own folder — PROVEN to work) ============
local PATHS = {
    "/storage/emulated/0/Android/data/com.pubg.imobile/files/fake_gacha.log",
    "/storage/emulated/0/Android/data/com.pubg.imobile/files/mods/fake_gacha.log",
}
local LOG_PATH = nil
for _, p in ipairs(PATHS) do
    local ok = pcall(function()
        local f = io.open(p, "a")
        if f then f:close() end
    end)
    if ok then LOG_PATH = p; break end
end
if not LOG_PATH then return end

local function W(m)
    pcall(function()
        local f = io.open(LOG_PATH, "a")
        if f then
            f:write(os.date("%H:%M:%S") .. " [" .. VERSION .. "] " .. tostring(m) .. "\n")
            f:close()
        end
    end)
end

W("=== BOOT " .. os.date() .. " ===")

-- ============ POPUP (prove it loaded) ============
local function pop(t, m)
    pcall(function()
        local M = package.loaded["client.slua.logic.common.logic_common_msg_box"]
                    or require("client.slua.logic.common.logic_common_msg_box")
        if M and M.Show then M.Show(4, tostring(t), tostring(m)) end
    end)
end

-- ============ SAFE REQUIRE ============
local function safeReq(...)
    for _, p in ipairs({...}) do
        local ok, m = pcall(require, p)
        if ok and m then return m end
    end
    return nil
end

-- ============ UC BYPASS (still needed for UI buttons) ============
local FAKE = 999999999
pcall(function()
    local d = _G.DataMgr
    if d then
        d.uc = FAKE; d.UC = FAKE; d.ticket = FAKE; d.gold = FAKE; d.diamond = FAKE
        d.GetUC = function() return FAKE end
        d.GetCurrency = function() return FAKE end
        d.GetMoney = function() return FAKE end
        d.CheckUC = function() return true end
        d.CheckIsEnough = function() return true end
        d.CheckMoney = function() return true end
        d.CheckCurrency = function() return true end
    end
end)
W("UC patched")

-- ============ ACTIVITY ID CACHE ============
-- Capture activityId from send hook so RSP hook knows what to reply with
local lastActivityId = 0
local lastDrawCount = 1

-- ============ POOL LOADER ============
local cachedPool = nil
local cachedPoolTime = 0
local function getPool(activityId)
    local now = os.time()
    if cachedPool and (now - cachedPoolTime) < 30 then return cachedPool end
    local mods = {
        safeReq("client.slua.logic.lobby_activity.logic_luckyback_activity"),
        safeReq("client.slua.logic.lobby_activity.logic_luckyunback_activity"),
    }
    for _, m in ipairs(mods) do
        if m then
            for _, k in ipairs({ "poolItemConfig", "item_table", "pool_info", "reward_list" }) do
                local p = m[k]
                if type(p) == "table" then
                    local n = 0
                    for _ in pairs(p) do n = n + 1 end
                    if n > 0 then
                        cachedPool = p
                        cachedPoolTime = now
                        W("pool from " .. tostring(k) .. " size=" .. n)
                        return p
                    end
                end
            end
        end
    end
    W("no pool found")
    return nil
end

-- ============ WEIGHTED PICK ============
local function pickItems(pool, count)
    local arr = {}
    for _, v in pairs(pool) do
        if type(v) == "table" then arr[#arr+1] = v end
    end
    if #arr == 0 then return {} end

    -- total weight
    local total = 0
    for _, item in ipairs(arr) do
        local w = tonumber(item.award_weight) or tonumber(item.weight) or 1
        if w > 0 then total = total + w end
    end
    if total <= 0 then total = #arr end

    local picks = {}
    for i = 1, count do
        local r = math.random() * total
        local acc = 0
        local chosen = arr[1]
        for _, item in ipairs(arr) do
            local w = tonumber(item.award_weight) or tonumber(item.weight) or 1
            if w <= 0 then w = 1 end
            acc = acc + w
            if r <= acc then chosen = item; break end
        end
        picks[#picks+1] = chosen
    end
    return picks
end

-- ============ REWARD LIST BUILDER ============
local function buildRewardList(picks)
    local out = {}
    for i, item in ipairs(picks) do
        local resid = item.award_item_id or item.resid or item.itemid or item.id or item.res_id or 403003
        local cnt = item.award_item_num or item.count or 1
        out[#out+1] = {
            resid = resid,
            res_id = resid,
            count = cnt,
            index = i,
            display_sort = i,
            close_time = 0,
            show_new = false,
            is_show_up = false,
            valid_hours = item.award_item_valid_time or 0,
        }
    end
    return out
end

local function buildDecompose(rewardList)
    local d = {}
    for i = 1, #rewardList do
        d[i] = { resid = 0, count = 0 }
    end
    return d
end

local function buildExtra()
    return {
        cur_chest_progress = 0,
        cur_draw_voucher_num = 0,
        uc_cost = 0,
        uc_ten_cost = 0,
        can_dis_draw = false,
        dis_draw_price = 0,
        return_uc_count = 0,
    }
end

-- ============ CORE: FAKE DRAW ============
local function fireFakeDraw(activityId, drawCount, originalRspFunc)
    local pool = getPool(activityId)
    local picks = {}
    if pool then
        picks = pickItems(pool, drawCount)
    end
    if #picks == 0 then
        for i = 1, drawCount do
            picks[i] = { award_item_id = 403003, award_item_num = 1 }
        end
    end

    local rewardList = buildRewardList(picks)
    local decomposeList = buildDecompose(rewardList)
    local extraInfo = buildExtra()

    W("faking success: act=" .. activityId .. " count=" .. drawCount .. " items=" .. #rewardList)

    -- Try multiple RSP shapes (we don't know exact one)
    local shapes = {
        { 0, activityId, rewardList, decomposeList, extraInfo },   -- 5-arg (most likely)
        { 0, rewardList },                                          -- 2-arg
        { 0, activityId, rewardList },                             -- 3-arg
        { 0, activityId, rewardList, decomposeList },              -- 4-arg
    }

    for i, args in ipairs(shapes) do
        local ok, err = pcall(originalRspFunc, unpack(args))
        W("try shape " .. i .. " args=" .. #args .. " ok=" .. tostring(ok) .. " err=" .. tostring(err))
        if ok then
            -- First successful call — assume this is the correct shape
            break
        end
    end
end

-- ============ HOOK: LuckybackHandler ============
local LB = safeReq("client.network.Protocol.LuckybackHandler")
if LB then
    -- 1. Hook send — capture activityId, DON'T call original (block network error)
    if type(LB.send_do_one_draw_back_by_activity_req) == "function" then
        local origSend = LB.send_do_one_draw_back_by_activity_req
        LB.send_do_one_draw_back_by_activity_req = function(activityId, drawCount, arg3, voucherId)
            lastActivityId = tonumber(activityId) or 0
            lastDrawCount = (tonumber(drawCount) == 2) and 10 or 1
            W("SEND captured: act=" .. lastActivityId .. " cnt=" .. lastDrawCount)

            -- DON'T call server. Instead, immediately fake the RSP.
            if type(LB.on_do_one_draw_back_by_activity_rsp) == "function" then
                fireFakeDraw(lastActivityId, lastDrawCount, LB.on_do_one_draw_back_by_activity_rsp)
            end
            return nil
        end
        W("hooked send_do_one_draw_back_by_activity_req")
    else
        W("NO send_do_one_draw_back_by_activity_req")
    end

    -- 2. Also hook RSP as safety net — if server error comes through somehow, replace
    if type(LB.on_do_one_draw_back_by_activity_rsp) == "function" then
        local origRsp = LB.on_do_one_draw_back_by_activity_rsp
        LB.on_do_one_draw_back_by_activity_rsp = function(errCode, ...)
            W("RSP hit: errCode=" .. tostring(errCode))
            if errCode ~= 0 then
                -- server error — replace with fake success
                W("caught error " .. tostring(errCode) .. " — faking success")
                fireFakeDraw(lastActivityId, lastDrawCount, origRsp)
                return
            end
            return origRsp(errCode, ...)
        end
        W("hooked rsp as safety net")
    end
else
    W("LuckybackHandler NOT LOADED")
end

-- ============ HOOK: StoreHandler (secondary path) ============
local SH = safeReq("client.network.Protocol.StoreHandler")
if SH then
    if type(SH.send_do_one_draw_by_activity_req) == "function" then
        SH.send_do_one_draw_back_by_activity_req = nil  -- clear if exists
        local orig = SH.send_do_one_draw_by_activity_req
        SH.send_do_one_draw_by_activity_req = function(activityId, roundCount, hadDrawCount, voucherId)
            lastActivityId = tonumber(activityId) or 0
            lastDrawCount = (tonumber(roundCount) == 2 or tonumber(roundCount) == 10) and 10 or 1
            W("SH SEND: act=" .. lastActivityId .. " cnt=" .. lastDrawCount)
            if type(SH.on_do_one_draw_by_activity_rsp) == "function" then
                local pool = getPool(lastActivityId)
                local picks = pool and pickItems(pool, lastDrawCount) or {}
                if #picks == 0 then for i = 1, lastDrawCount do picks[i] = { award_item_id = 403003 } end end
                local rl = buildRewardList(picks)
                pcall(SH.on_do_one_draw_by_activity_rsp, 0, lastActivityId, rl, buildDecompose(rl))
            end
            return nil
        end
        W("hooked StoreHandler.send_do_one_draw_by_activity_req")
    end
end

-- ============ POPUP ON BOOT ============
local poolTest = getPool(lastActivityId)
local poolSize = 0
if poolTest then
    for _ in pairs(poolTest) do poolSize = poolSize + 1 end
end

pop(VERSION, "Loaded.\nLog: files/fake_gacha.log\nPool size: " .. poolSize .. "\nDaba 10 Draw now.")

W("=== READY ===")
print("[fake_gacha v2] ready")
