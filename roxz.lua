-- ===============================================================
-- gdump_live.lua — lobby click-capture dumper
-- Flow: match -> lobby -> auto-hook every draw method -> user clicks
--       -> capture module state + args + rsp (real reward pool)
-- Output: /storage/emulated/0/Android/data/com.pubg.imobile/files/gdump_live.jsonl
-- Drop in mods/ — hotload picks it up. No restart after first load.
-- ===============================================================

local CFG = {
    OUT = "/storage/emulated/0/Android/data/com.pubg.imobile/files/gdump_live.jsonl",
    OUT_FALLBACK = "/sdcard/gdump_live.jsonl",
    POPUP = true,
    LOBBY_POLL = 2.0,       -- check lobby state every 2s
    MAX_STR = 400,
    MAX_KEYS = 80,
    MAX_DEPTH = 5,
    -- module path fragments to hook (auto-discovered by scan)
    PATTERNS = {
        "lobby_activity",
        "XSuit",
        "tarot_card",
        "scrap_gold",
        "logic_luck",
        "logic_draw",
        "Godzilla",
        "super_airdrop",
        "luck_util",
        "LuckcyOptionalTurntable",
        "LukcyOptionalTurntable",
    },
    -- method name fragments that mean "draw/click"
    DRAW_HINTS = {
        "draw", "Draw", "DRAW",
        "spin", "Spin",
        "lottery", "Lottery",
        "lotter", "Lotter",
        "rotate", "Rotate",
        "OnRotate", "OnRandom", "OnRecv", "OnBegin",
        "DoDraw", "OneDraw", "TenDraw",
        "SendDraw", "ReqDraw", "DoLottery",
    },
}

-- ============ POPUP ============
local function POPUP(title, msg)
    pcall(function()
        local M = package.loaded["client.slua.logic.common.logic_common_msg_box"]
                    or require("client.slua.logic.common.logic_common_msg_box")
        if M and M.Show then M.Show(4, tostring(title), tostring(msg)) end
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

local function getStatus()
    local GS = safeReq("GameStatus", "GameLua.GameStatus")
    if not GS then return "unknown" end
    local s = "unknown"
    pcall(function()
        if GS.IsInLobbyOrMainCity and GS.IsInLobbyOrMainCity() then s = "lobby"
        elseif GS.IsInFightingStatus and GS.IsInFightingStatus() then s = "match" end
    end)
    return s
end

-- deep snapshot of a table (one level of safe traversal)
local function snapshot(mod)
    if type(mod) ~= "table" then return {} end
    local out = {}
    for k, v in pairs(mod) do
        local tv = type(v)
        if tv == "number" or tv == "string" or tv == "boolean" then
            out[k] = v
        elseif tv == "table" then
            -- shallow: count + preview
            local cnt, preview = 0, {}
            for kk, vv in pairs(v) do
                cnt = cnt + 1
                if cnt <= 12 then
                    if type(vv) == "table" then
                        preview[tostring(kk)] = toJSON(vv, 3)
                    else
                        preview[tostring(kk)] = vv
                    end
                else break end
            end
            out[k] = { __count = cnt, __preview = preview }
        end
    end
    return out
end

-- ============ HOOK REGISTRY ============
local hooked = {}   -- [path .. "::" .. method] = true
local installedMods = {}
local installCount = 0

local function isDrawMethod(name)
    if type(name) ~= "string" then return false end
    if name:find("^_") then return false end
    if name == "ActivityId" or name == "ModuleId" then return false end
    for _, hint in ipairs(CFG.DRAW_HINTS) do
        if name:find(hint, 1, true) then return true end
    end
    return false
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
                    -- PRE snapshot
                    local pre = snapshot(mod)
                    local args = { ... }
                    local argsJson = toJSON(args, 1)

                    -- call original
                    local ok, r1, r2, r3 = pcall(orig, ...)

                    -- POST snapshot
                    local post = snapshot(mod)

                    -- emit record
                    emit("click", "draw", {
                        path = path,
                        method = name,
                        args = argsJson,
                        ok = ok,
                        ret1 = r1,
                        ret2 = r2,
                        pre = pre,
                        post = post,
                    })
                    flush()
                    -- return original results
                    if ok then return r1, r2, r3 end
                    return r1
                end
            end
        end
    end
    installedMods[path] = true
    installCount = installCount + 1
end

-- ============ RSP HOOKS (capture server response = real pool) ============
local rspHooked = {}
local function hookRsp(handlerPath, rspName)
    local H = safeReq(handlerPath)
    if not H or type(H) ~= "table" then return end
    if rspHooked[handlerPath .. "::" .. rspName] then return end
    local orig = H[rspName]
    if type(orig) ~= "function" then return end
    rspHooked[handlerPath .. "::" .. rspName] = true
    H[rspName] = function(...)
        local args = { ... }
        emit("rsp", rspName, {
            handler = handlerPath,
            args = toJSON(args, 1),
        })
        flush()
        return orig(...)
    end
end

local function installRspHooks()
    local rspTargets = {
        { "client.network.Protocol.StoreHandler", {
            "on_buy_shop_by_id_rsp",
            "on_buy_market_by_id_rsp",
            "on_do_one_draw_by_activity_rsp",
            "on_do_draw_discount_by_activity_rsp",
            "on_do_biochemical_activity_one_draw_rsp",
            "on_limited_discount_buy_rsp",
            "on_newbie_chest_buy_rsp",
            "on_buy_stage_chest_rsp",
            "on_receive_guarantee_reward_rsp",
            "on_get_market_chest_info_rsp",
            "on_fetch_chest_result_rsp",
            "on_get_market_buy_info_rsp_v3",
            "on_get_shop_info_rsp",
            "on_market_buy_chest_item_notify",
            "on_please_direct_buy",
            "on_notice_shop_guarantee_reward",
            "on_buy_shop_by_id_ntf",
        }},
        { "client.network.Protocol.LuckybackHandler", {
            "on_do_one_draw_back_by_activity_rsp",
            "on_get_lucky_draw_back_activity_rsp",
            "on_get_lucky_draw_back_voucher_rsp",
            "on_get_lucky_draw_collect_award_rsp",
            "on_get_sum_draw_award_by_activity_rsp",
            "on_do_exchange_by_activity_id_rsp",
            "on_get_lucky_draw_back_redpoint_rsp",
        }},
        { "client.network.Protocol.LuckySpecialHandler", {
            "on_do_draw_act_rsp",
            "on_do_draw_discount_rsp",
            "on_get_draw_act_info_rsp",
            "on_get_draw_sum_reward_rsp",
            "on_get_collected_reward_rsp",
            "on_get_extra_reward_rsp",
        }},
        { "client.network.Protocol.XSuitHandler", {
            "on_draw_gold_dress_rsp",
            "on_get_accumulate_pool_reward_rsp",
            "on_get_wish_pool_rsp",
            "on_get_gold_dress_activity_rsp",
            "on_gold_dress_get_collect_reward_rsp",
            "on_open_gold_dress_branch_box_rsp",
            "on_set_wish_pool_id_rsp",
        }},
        { "client.network.Protocol.SupplyOptionalHandler", {
            "on_get_role_custom_chest_info_rsp",
            "on_role_chest_custom_buy_rsp",
            "on_role_chest_exchange_temp_item_rsp",
            "on_get_role_exchange_history_info_rsp",
        }},
        { "client.network.Protocol.ActivityHandler", {
            "on_take_activity_award_rsp",
            "on_batch_take_activity_award_rsp",
            "on_get_activity_reward_rsp",
            "on_get_activity_one_rsp",
            "on_get_activity_list_rsp",
            "on_get_activity_map_by_id_rsp",
            "on_get_ams_lucky_draw_unback_rsp",
        }},
        { "client.network.Protocol.DropBoxHandler", {
            "on_get_content_by_chestids_rsp",
            "on_get_content_by_dropids_rsp",
            "on_get_realtime_probability_rsp",
        }},
    }
    for _, entry in ipairs(rspTargets) do
        for _, name in ipairs(entry[2]) do
            pcall(hookRsp, entry[1], name)
        end
    end
end

-- ============ AUTO-DISCOVER ACTIVITY MODULES ============
local function discoverAndHook()
    local found = 0
    for path, mod in pairs(package.loaded) do
        if type(path) == "string" then
            local matched = false
            for _, pat in ipairs(CFG.PATTERNS) do
                if path:find(pat, 1, true) then matched = true; break end
            end
            if matched and type(mod) == "table" then
                hookModule(path, mod)
                found = found + 1
            end
        end
    end
    return found
end

-- ============ LOBBY STATE MACHINE ============
local S = {
    lastStatus = "",
    lobbyDetected = false,
    hooksInstalled = false,
    installTick = 0,
}

local function onLobbyEnter()
    if S.hooksInstalled then return end
    emit("state", "lobby_enter", { ts = os.date("%Y-%m-%d %H:%M:%S") })
    local n = discoverAndHook()
    installRspHooks()
    S.hooksInstalled = true
    emit("state", "hooks_installed", { modules = n, rspCount = (function() local c=0 for _ in pairs(rspHooked) do c=c+1 end return c end)() })
    flush()
    if CFG.POPUP then
        POPUP("GDUMP LIVE", "Hooks installed.\nModules: " .. n .. "\nNow click every spin/draw.")
    end
end

local function onMatchEnter()
    if S.hooksInstalled then
        emit("state", "match_enter", { note = "hooks stay installed" })
        flush()
    end
end

-- ============ BOOT ============
flush()
emit("boot", "start", {
    out = CFG.OUT,
    ts = os.date("%Y-%m-%d %H:%M:%S"),
    v = "gdump_live v1",
})
flush()

if CFG.POPUP then
    POPUP("GDUMP LIVE", "Waiting for lobby...\nClick each spin/draw.")
end

-- ============ LOOP ============
local ticker = safeReq("common.time_ticker")
if not ticker or not ticker.AddTimerLoop then
    emit("boot", "err", { msg = "no time_ticker" })
    flush()
    POPUP("GDUMP LIVE", "No time_ticker")
    return
end

ticker.AddTimerLoop(0, function()
    pcall(function()
        local st = getStatus()
        if st ~= S.lastStatus then
            emit("state", "change", { from = S.lastStatus, to = st })
            S.lastStatus = st
            if st == "lobby" then
                S.lobbyDetected = true
                onLobbyEnter()
            elseif st == "match" then
                onMatchEnter()
            end
        end
        -- Re-scan every 10 ticks (catch late-loaded modules)
        if S.lobbyDetected then
            S.installTick = S.installTick + 1
            if S.installTick % 10 == 0 then
                local n = discoverAndHook()
                if n > 0 then
                    emit("state", "rescan", { modules = n })
                    flush()
                end
            end
        end
    end)
end, -1, CFG.LOBBY_POLL)

emit("boot", "ready", { poll = CFG.LOBBY_POLL })
flush()

-- ============ PUBLIC API ============
_G.GDLive = {
    forceInstall = function()
        local n = discoverAndHook()
        installRspHooks()
        POPUP("GDLIVE", "Force install: " .. n .. " modules")
    end,
    status = function()
        local c = 0
        for _ in pairs(hooked) do c = c + 1 end
        local rc = 0
        for _ in pairs(rspHooked) do rc = rc + 1 end
        POPUP("GDLIVE", string.format("hooks=%d rsp=%d\nmods=%d ok=%d fail=%d",
            c, rc, installCount, stats.ok, stats.fail))
    end,
    dumpSnapshot = function(path)
        local m = safeReq(path)
        if m then
            emit("manual", "snapshot", { path = path, data = snapshot(m) })
            flush()
        end
    end,
}

print("[GDLIVE] ready — out=" .. CFG.OUT)
