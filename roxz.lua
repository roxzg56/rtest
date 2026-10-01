-- ===============================================================
-- fake_gacha.lua — REAL working gacha mod
-- Hooks LuckybackHandler.send_do_one_draw_back_by_activity_req
-- No network. No UC. Locally picks from real pool and fakes RSP.
-- Drop in mods/ next to roxs_v4.lua (or replace it entirely).
-- Log: /sdcard/fake_gacha.log
-- ===============================================================

local LOG = "/sdcard/fake_gacha.log"
local function W(m)
    pcall(function()
        local f = io.open(LOG, "a")
        if f then f:write(os.date("%H:%M:%S") .. " " .. tostring(m) .. "\n"); f:close() end
    end)
end

W("=== fake_gacha boot " .. os.date() .. " ===")

local function safeReq(...)
    for _, p in ipairs({...}) do
        local ok, m = pcall(require, p)
        if ok and m then return m end
    end
    return nil
end

-- ============ FAKE UC (still keep client happy) ============
local FAKE = 999999999
pcall(function()
    local d = _G.DataMgr
    if d then
        d.uc = FAKE; d.UC = FAKE; d.ticket = FAKE
        d.GetUC = function() return FAKE end
        d.CheckUC = function() return true end
        d.CheckIsEnough = function() return true end
    end
end)

-- ============ POOL CACHE ============
-- Read from activity module, try multiple fields
local function getPool(activityId)
    local mods = {
        safeReq("client.slua.logic.lobby_activity.logic_luckyback_activity"),
        safeReq("client.slua.logic.lobby_activity.logic_luckyunback_activity"),
        safeReq("client.slua.logic.lobby_activity.logic_luckydouble_activity"),
        safeReq("client.slua.logic.lobby_activity.logic_scrapgold_draw"),
    }
    for _, m in ipairs(mods) do
        if m then
            local pools = {
                m.poolItemConfig,   -- the big pool (34 items)
                m.item_table,       -- item table
                m.pool_info,        -- pool entries
                m.reward_list,      -- reward list
            }
            for _, p in ipairs(pools) do
                if type(p) == "table" then
                    local n = 0
                    for _ in pairs(p) do n = n + 1 end
                    if n > 0 then
                        W("pool found in " .. tostring(m) .. " size=" .. n)
                        return p
                    end
                end
            end
        end
    end
    W("NO POOL FOUND for " .. tostring(activityId))
    return nil
end

-- ============ WEIGHT-BASED PICK ============
local function pickFromPool(pool, drawCount)
    local arr = {}
    for _, v in pairs(pool) do
        if type(v) == "table" then arr[#arr+1] = v end
    end
    if #arr == 0 then return {} end

    -- weighted selection
    local picks = {}
    for i = 1, drawCount do
        local total = 0
        for _, item in ipairs(arr) do
            local w = tonumber(item.award_weight) or tonumber(item.weight) or 1
            if w > 0 then total = total + w end
        end
        local r = math.random() * total
        local acc = 0
        local chosen = arr[1]
        for _, item in ipairs(arr) do
            local w = tonumber(item.award_weight) or tonumber(item.weight) or 1
            acc = acc + w
            if r <= acc then chosen = item; break end
        end
        picks[#picks+1] = chosen
    end
    return picks
end

-- ============ BUILD FAKE RSP PAYLOAD ============
local function buildRewardList(picks)
    local out = {}
    for i, item in ipairs(picks) do
        local resid = item.award_item_id or item.resid or item.itemid or item.id or 403003
        local count = item.award_item_num or item.count or 1
        table.insert(out, {
            resid = resid,
            res_id = resid,
            count = count,
            index = i,
            display_sort = i,
            close_time = 0,
            show_new = false,
            is_show_up = false,
            valid_hours = item.award_item_valid_time or 0,
        })
    end
    return out
end

local function buildDecomposeList(rewardList)
    local out = {}
    for i, _ in ipairs(rewardList) do
        out[i] = { resid = 0, count = 0 }
    end
    return out
end

local function buildExtraInfo()
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

-- ============ HOOK: LuckybackHandler (main path) ============
local LB = safeReq("client.network.Protocol.LuckybackHandler")
if LB then
    local origSend = LB.send_do_one_draw_back_by_activity_req
    if type(origSend) == "function" then
        LB.send_do_one_draw_back_by_activity_req = function(activityId, drawCount, arg3, voucherId)
            W("DRAW activityId=" .. tostring(activityId) .. " drawCount=" .. tostring(drawCount))

            local pool = getPool(activityId)
            local count = (tonumber(drawCount) == 2) and 10 or 1
            local picks = {}

            if pool then
                picks = pickFromPool(pool, count)
            end

            -- fallback: if no pool, just pick junk IDs
            if #picks == 0 then
                for i = 1, count do
                    picks[i] = { award_item_id = 403003, award_item_num = 1 }
                end
            end

            local rewardList = buildRewardList(picks)
            local decomposeList = buildDecomposeList(rewardList)
            local extraInfo = buildExtraInfo()

            W("faking RSP: " .. count .. " items")

            -- Fire the RSP locally — this is what the client UI listens to
            local ok, err = pcall(
                LB.on_do_one_draw_back_by_activity_rsp,
                0,                    -- success errCode
                activityId,
                rewardList,
                decomposeList,
                extraInfo
            )
            W("RSP fired ok=" .. tostring(ok) .. " err=" .. tostring(err))

            -- Also try alternate shapes (in case the client expects different args)
            if not ok then
                pcall(LB.on_do_one_draw_back_by_activity_rsp, 0, activityId, rewardList)
                pcall(LB.on_do_one_draw_back_by_activity_rsp, 0, rewardList)
                pcall(LB.on_do_one_draw_back_by_activity_rsp, 0)
            end

            return nil
        end
        W("hooked LuckybackHandler.send_do_one_draw_back_by_activity_req")
    else
        W("NO send_do_one_draw_back_by_activity_req")
    end
else
    W("LuckybackHandler NOT LOADED")
end

-- ============ HOOK: StoreHandler (secondary path) ============
local SH = safeReq("client.network.Protocol.StoreHandler")
if SH then
    if type(SH.send_do_one_draw_by_activity_req) == "function" then
        local orig = SH.send_do_one_draw_by_activity_req
        SH.send_do_one_draw_by_activity_req = function(activityId, roundCount, hadDrawCount, voucherId)
            W("StoreHandler DRAW activityId=" .. tostring(activityId))
            local pool = getPool(activityId)
            local count = (tonumber(roundCount) == 2 or tonumber(roundCount) == 10) and 10 or 1
            local picks = pool and pickFromPool(pool, count) or {}
            if #picks == 0 then
                for i = 1, count do picks[i] = { award_item_id = 403003, award_item_num = 1 } end
            end
            local rewardList = buildRewardList(picks)
            pcall(SH.on_do_one_draw_by_activity_rsp, 0, activityId, rewardList, buildDecomposeList(rewardList))
            return nil
        end
        W("hooked StoreHandler.send_do_one_draw_by_activity_req")
    end
end

-- ============ LOG READY ============
W("=== READY ===")
print("[fake_gacha] ready")
