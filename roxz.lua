-- ===============================================================
-- gdump_live.lua v2 — direct install, no lobby detection
-- Boot pe turant hook. Har 5 sec rescan. User clicks -> capture.
-- Output: /storage/emulated/0/Android/data/com.pubg.imobile/files/gdump_live.jsonl
-- ===============================================================

local CFG = {
    OUT = "/storage/emulated/0/Android/data/com.pubg.imobile/files/gdump_live.jsonl",
    OUT_FALLBACK = "/sdcard/gdump_live.jsonl",
    POPUP = true,
    RESCAN_INTERVAL = 5,      -- seconds between rescans
    MAX_STR = 400,
    MAX_KEYS = 80,
    MAX_DEPTH = 5,
    -- Broad scan: hook ANY module path containing one of these
    PATH_HINTS = {
        "lobby_activity", "XSuit", "xsuit", "tarot_card", "scrap_gold",
        "logic_luck", "logic_draw", "godzilla", "Godzilla", "super_airdrop",
        "luck_util", "Turntable", "turn_table", "draw", "Draw",
        "lottery", "Lottery", "spin", "Spin",
        "store", "Store", "supply", "Supply",
        "activity", "Activity",
    },
    -- Hook method names containing any of these
    DRAW_HINTS = {
        "draw", "Draw", "DRAW",
        "spin", "Spin", "SPIN",
        "lottery", "Lottery", "LotteryDraw",
        "rotate", "Rotate", "RotateRsp", "RotateReq",
        "OnRandom", "OnRecv", "OnBegin", "OnOpen",
        "OneDraw", "TenDraw", "DoDraw", "DoLottery",
        "SendDraw", "ReqDraw", "SendOpen", "SendBuy",
        "OpenBox", "OpenCrate", "OpenChest",
        "Click", "OnClick",
    },
    -- RSP hooks per protocol handler
    RSP_TARGETS = {
        { "client.network.Protocol.StoreHandler", {
            "on_buy_shop_by_id_rsp","on_buy_market_by_id_rsp","on_do_one_draw_by_activity_rsp",
            "on_do_draw_discount_by_activity_rsp","on_do_biochemical_activity_one_draw_rsp",
            "on_limited_discount_buy_rsp","on_newbie_chest_buy_rsp","on_buy_stage_chest_rsp",
            "on_receive_guarantee_reward_rsp","on_get_market_chest_info_rsp",
            "on_fetch_chest_result_rsp","on_get_market_buy_info_rsp_v3",
            "on_get_shop_info_rsp","on_get_shop_tab_list_rsp",
            "on_market_buy_chest_item_notify","on_please_direct_buy",
            "on_notice_shop_guarantee_reward","on_buy_shop_by_id_ntf",
            "on_get_all_cond_gift_rsp","on_get_stage_chest_cfg_rsp",
            "on_direct_buy_result_rsp","on_get_reopen_box_full_rsp",
            "on_new_props_list_rsp",
        }},
        { "client.network.Protocol.LuckybackHandler", {
            "on_do_one_draw_back_by_activity_rsp","on_get_lucky_draw_back_activity_rsp",
            "on_get_lucky_draw_back_voucher_rsp","on_get_lucky_draw_collect_award_rsp",
            "on_get_sum_draw_award_by_activity_rsp","on_do_exchange_by_activity_id_rsp",
            "on_get_lucky_draw_back_redpoint_rsp",
        }},
        { "client.network.Protocol.LuckySpecialHandler", {
            "on_do_draw_act_rsp","on_do_draw_discount_rsp","on_get_draw_act_info_rsp",
            "on_get_draw_sum_reward_rsp","on_get_collected_reward_rsp","on_get_extra_reward_rsp",
        }},
        { "client.network.Protocol.XSuitHandler", {
            "on_draw_gold_dress_rsp","on_get_accumulate_pool_reward_rsp",
            "on_get_wish_pool_rsp","on_get_gold_dress_activity_rsp",
            "on_gold_dress_get_collect_reward_rsp","on_open_gold_dress_branch_box_rsp",
            "on_set_wish_pool_id_rsp","on_do_onshot_exchange_by_activity_id_rsp",
        }},
        { "client.network.Protocol.SupplyOptionalHandler", {
            "on_get_role_custom_chest_info_rsp","on_role_chest_custom_buy_rsp",
            "on_role_chest_exchange_temp_item_rsp","on_get_role_exchange_history_info_rsp",
        }},
        { "client.network.Protocol.ActivityHandler", {
            "on_take_activity_award_rsp","on_batch_take_activity_award_rsp",
            "on_get_activity_reward_rsp","on_get_activity_one_rsp",
            "on_get_activity_list_rsp","on_get_activity_map_by_id_rsp",
            "on_get_ams_lucky_draw_unback_rsp",
        }},
        { "client.network.Protocol.DropBoxHandler", {
            "on_get_content_by_chestids_rsp","on_get_content_by_dropids_rsp",
            "on_get_realtime_probability_rsp",
        }},
        { "client.network.Protocol.MarketHandler", {
            "on_open_chest_rsp","on_open_chest_ten_times_nofity",
            "on_shop_buy_rsp","on_shop_itemlist_rsp",
        }},
        { "client.network.Protocol.LuckAirDropHandler", {
            "on_buy_luck_airdrop_rsp","on_get_luck_airdrop_info_after_ad_rsp",
            "on_set_luck_airdrop_item_score_rsp","on_target_airdrop_buy_rsp",
        }},
    },
}

-- ============ POPUP ============
local function POPUP(title, msg)
    pcall(function()
        local M = package.loaded["client.slua.logic.common.logic_common_msg_box"]
                    or require("client.slua.logic.common.logic_common_msg_box")
        if M and M.Show then M.Show(4, tostring(title), tostring(msg)) end
    end)
    pcall(function()
        if UIManager and UIManager.ShowTips then UIManager.ShowTips(tostring(msg)) end
    end)
end

-- ============ JSON ============
local function esc(s)
    s = tostring(s)
    return (s:gsub("\\","\\\\"):gsub("\"","\\\""):gsub("\n","\\n"):gsub("\r","\\r"):gsub("\t","\\t"))
end

local function toJSON(v, d)
    d = d or 0
    if d > CFG.MAX_DEPTH then return "\"<deep>\"" end
    local t = type(v)
    if t == "nil" then return "null" end
    if t == "boolean" then return v and "true" or "false" end
    if t == "number" then
        if v ~= v or v == math.huge or v == -math.huge then return "null" end
        return tostring(v)
    end
    if t == "string" then
        if #v > CFG.MAX_STR then v = v:sub(1, CFG.MAX_STR) .. "..." end
        return "\"" .. esc(v) .. "\""
    end
    if t == "userdata" then return "\"<ud>\"" end
    if t == "function" then return "\"<fn>\"" end
    if t == "table" then
        local n, isArr = 0, true
        for k in pairs(v) do
            n = n + 1
            if type(k) ~= "number" then isArr = false; break end
        end
        if isArr and n > 0 then
            local p = {}
            for i = 1, math.min(#v, CFG.MAX_KEYS) do p[#p+1] = toJSON(v[i], d+1) end
            if #v > CFG.MAX_KEYS then p[#p+1] = "\"<...>\"" end
            return "[" .. table.concat(p, ",") .. "]"
        end
        local p = {}
        for k, vv in pairs(v) do
            p[#p+1] = "\"" .. esc(k) .. "\":" .. toJSON(vv, d+1)
            if #p >= CFG.MAX_KEYS then p[#p+1] = "\"__trunc\":true"; break end
        end
        return "{" .. table.concat(p, ",") .. "}"
    end
    return "\"<?>\""
end

-- ============ WRITE ============
local buf, bufN = {}, 0
local stats = { ok = 0, fail = 0 }

local function rawWrite(payload)
    local wrote = false
    pcall(function()
        local f = io.open(CFG.OUT, "a")
        if f then f:write(payload); f:close(); wrote = true end
    end)
    if not wrote then
        pcall(function()
            local f = io.open(CFG.OUT_FALLBACK, "a")
            if f then f:write(payload); f:close(); wrote = true end
        end)
    end
    if wrote then stats.ok = stats.ok + 1 else stats.fail = stats.fail + 1 end
end

local function flush()
    if bufN == 0 then return end
    rawWrite(table.concat(buf, "\n") .. "\n")
    buf, bufN = {}, 0
end

local function emit(tag, evt, data)
    buf[#buf+1] = toJSON({
        t = os.date("%Y-%m-%dT%H:%M:%S"),
        tag = tag, evt = evt, data = data or {},
    })
    bufN = bufN + 1
    if bufN >= 12 then flush() end
end

-- ============ HELPERS ============
local function safeReq(...)
    for _, p in ipairs({...}) do
        local ok, m = pcall(require, p)
        if ok and m then return m end
    end
    return nil
end

local function matchesAny(s, list)
    if type(s) ~= "string" then return false end
    for _, pat in ipairs(list) do
        if s:find(pat, 1, true) then return true end
    end
    return false
end

-- Deep-ish snapshot: scalars + shallow table previews
local function snapshot(mod)
    if type(mod) ~= "table" then return {} end
    local out = {}
    for k, v in pairs(mod) do
        local tv = type(v)
        if tv == "number" or tv == "string" or tv == "boolean" then
            out[k] = v
        elseif tv == "table" then
            local cnt = 0
            for _ in pairs(v) do cnt = cnt + 1 end
            if cnt <= 4 then
                out[k] = toJSON(v, 4)
            else
                -- preview keys
                local keys = {}
                local i = 0
                for kk in pairs(v) do
                    i = i + 1
                    if i > 10 then keys[#keys+1] = "<...>" ; break end
                    keys[#keys+1] = tostring(kk)
                end
                out[k] = "<table:" .. cnt .. "> keys=" .. table.concat(keys, ",")
            end
        end
    end
    return out
end

-- ============ HOOK REGISTRY ============
local hooked = {}
local rspHooked = {}
local installedMods = {}
local installCount = 0
local rspCount = 0

local function isDrawMethod(name)
    if type(name) ~= "string" then return false end
    if name:sub(1,1) == "_" then return false end
    return matchesAny(name, CFG.DRAW_HINTS)
end

local function hookModule(path, mod)
    if type(mod) ~= "table" then return end
    for name, fn in pairs(mod) do
        if type(name) == "string" and type(fn) == "function" and isDrawMethod(name) then
            local key = path .. "::" .. name
            if not hooked[key] then
                hooked[key] = true
                local orig = fn
                mod[name] = function(...)
                    local pre = snapshot(mod)
                    local args = { ... }
                    local argsJson = toJSON(args, 2)
                    local ok, r1, r2, r3, r4 = pcall(orig, ...)
                    local post = snapshot(mod)
                    emit("click", "draw", {
                        path = path,
                        method = name,
                        args = argsJson,
                        ok = ok,
                        ret1 = r1, ret2 = r2, ret3 = r3, ret4 = r4,
                        pre = pre,
                        post = post,
                    })
                    flush()
                    if ok then return r1, r2, r3, r4 end
                    return r1
                end
            end
        end
    end
    if not installedMods[path] then
        installedMods[path] = true
        installCount = installCount + 1
    end
end

local function hookRsp(handlerPath, rspName)
    local H = safeReq(handlerPath)
    if not H or type(H) ~= "table" then return end
    local key = handlerPath .. "::" .. rspName
    if rspHooked[key] then return end
    local orig = H[rspName]
    if type(orig) ~= "function" then return end
    rspHooked[key] = true
    rspCount = rspCount + 1
    H[rspName] = function(...)
        local args = { ... }
        emit("rsp", rspName, {
            handler = handlerPath,
            args = toJSON(args, 2),
        })
        flush()
        return orig(...)
    end
end

local function installRspHooks()
    for _, entry in ipairs(CFG.RSP_TARGETS) do
        for _, name in ipairs(entry[2]) do
            pcall(hookRsp, entry[1], name)
        end
    end
end

-- ============ DISCOVERY ============
local function discoverAndHook()
    local matchedMods = 0
    local before = installCount
    for path, mod in pairs(package.loaded) do
        if type(path) == "string" and type(mod) == "table" then
            if matchesAny(path, CFG.PATH_HINTS) then
                hookModule(path, mod)
                matchedMods = matchedMods + 1
            end
        end
    end
    return matchedMods, (installCount - before)
end

-- ============ BOOT — DIRECT INSTALL, NO DETECTION ============
flush()
emit("boot", "start", {
    out = CFG.OUT,
    ts = os.date("%Y-%m-%d %H:%M:%S"),
    v = "gdump_live v2",
})
flush()

-- Run first install right now
local modCount, newHooks = discoverAndHook()
installRspHooks()

emit("boot", "install", {
    modules_matched = modCount,
    modules_new = newHooks,
    draw_hooks = (function() local c=0 for _ in pairs(hooked) do c=c+1 end return c end)(),
    rsp_hooks = rspCount,
})
flush()

if CFG.POPUP then
    POPUP("GDLIVE v2", "Installed on boot.\nmods=" .. modCount .. " hooks=" ..
        (function() local c=0 for _ in pairs(hooked) do c=c+1 end return c end)() ..
        "\nNow click spin/draw.")
end

print(string.format("[GDLIVE] installed modules=%d newHooks=%d rsp=%d",
    modCount, newHooks, rspCount))

-- ============ LOOP — RESCAN ONLY ============
local ticker = safeReq("common.time_ticker")
if not ticker or not ticker.AddTimerLoop then
    emit("boot", "err", { msg = "no time_ticker" })
    flush()
    POPUP("GDLIVE", "No time_ticker")
    return
end

local tick = 0
ticker.AddTimerLoop(0, function()
    pcall(function()
        tick = tick + 1
        -- rescan every N ticks (RESCAN_INTERVAL / 0.5 = ticks)
        local ticksPerRescan = math.max(1, math.floor(CFG.RESCAN_INTERVAL / 0.5))
        if tick % ticksPerRescan == 0 then
            local mc, nh = discoverAndHook()
            installRspHooks()
            if nh > 0 or mc > 0 then
                emit("state", "rescan", {
                    tick = tick,
                    modules_matched = mc,
                    new_hooks = nh,
                    total_hooks = (function() local c=0 for _ in pairs(hooked) do c=c+1 end return c end)(),
                    total_rsp = rspCount,
                })
                flush()
            end
        end
    end)
end, -1, 0.5)

emit("boot", "ready", { v = "v2", rescan = CFG.RESCAN_INTERVAL })
flush()

-- ============ PUBLIC API ============
_G.GDLive = {
    status = function()
        local hc, mc = 0, 0
        for _ in pairs(hooked) do hc = hc + 1 end
        for _ in pairs(installedMods) do mc = mc + 1 end
        POPUP("GDLIVE", string.format("mods=%d hooks=%d rsp=%d\nok=%d fail=%d",
            mc, hc, rspCount, stats.ok, stats.fail))
    end,
    install = function()
        local mc, nh = discoverAndHook()
        installRspHooks()
        POPUP("GDLIVE", "Force: mods=" .. mc .. " new=" .. nh)
    end,
    dump = function(path)
        local m = safeReq(path)
        if m then
            emit("manual", "snapshot", { path = path, data = snapshot(m) })
            flush()
        else
            POPUP("GDLIVE", "not found: " .. tostring(path))
        end
    end,
    listHooks = function()
        local list = {}
        for k in pairs(hooked) do list[#list+1] = k end
        emit("manual", "list_hooks", { hooks = list })
        flush()
        POPUP("GDLIVE", "hooks listed in jsonl")
    end,
    listMods = function()
        local list = {}
        for k in pairs(installedMods) do list[#list+1] = k end
        emit("manual", "list_mods", { mods = list })
        flush()
        POPUP("GDLIVE", "mods listed in jsonl")
    end,
}

print("[GDLIVE] v2 ready — out=" .. CFG.OUT)
