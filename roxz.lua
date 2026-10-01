-- ===============================================================
-- roxs.lua — ALL IN ONE
--   1. UC / currency client-side bypass
--   2. Deduped click + rsp dumper (delta only, no repeats)
--   3. Smart extractor: pulls ONLY what's needed to build fake gacha
--      (activity IDs, pools, send/rsp shapes, player state)
-- Drop in mods/ next to hotload.lua. Nothing else needed.
-- Output:
--   /sdcard/roxs_all.jsonl        (raw deduped events, small)
--   /sdcard/roxs_extract.jsonl    (smart extract: ONLY the useful bits)
-- ===============================================================

local CFG = {
    RAW_OUT     = "/storage/emulated/0/Android/data/com.pubg.imobile/files/roxs_all.jsonl",
    EXTRACT_OUT = "/storage/emulated/0/Android/data/com.pubg.imobile/files/roxs_extract.jsonl",
    FALLBACK    = "/sdcard/",
    POPUP       = true,
    RESCAN      = 5,
    MAX_STR     = 200,
    MAX_KEYS    = 30,
    MAX_DEPTH   = 4,
    DEDUPE      = true,
    DELTA_ONLY  = true,
    -- Only extract pools/state from these module paths (fragments)
    ACTIVITY_PATHS = {
        "logic_luckyback_activity",
        "logic_luckyunback_activity",
        "logic_luckydouble_activity",
        "logic_scrapgold_draw",
        "logic_ladder_draw",
        "logic_godzilla_ban",
        "logic_super_airdrop",
        "Logic_LukcyOptionalTurntable",
        "logic_tarotcard_drawcard",
        "logic_xsuit_activity",
        "special_luck_network",
        "logic_luckymulti_activity",
        "logic_luckmix_activity",
    },
    -- Fields we want from each activity module (only these, nothing else)
    ACTIVITY_FIELDS = {
        "ActivityId", "activityId", "ModuleId", "moduleId",
        "curLuckyValue", "MainAwardWeight", "ResourceType",
        "AwardPoolCount", "CurAwardPoolIndex",
        "oneDrawOriginalPrice", "tenDrawOriginalPrice",
        "oneDrawFinalPrice", "tenDrawFinalPrice",
        "IsDailyDiscount", "entranceType",
        "exchange_act_id", "ten_draw_market_id", "tenDrawID", "tenDrawTabID",
        "is_first_buy_voucher_for_version", "TimePeriodStr",
    },
    -- Table fields we want SIZE + first-N preview
    ACTIVITY_TABLES = {
        "item_table",       -- real reward pool
        "poolItemConfig",   -- pool items
        "pool_info",        -- pool entries
        "reward_list",      -- rewards
        "totalDrawAwardConfig",
        "newtotalDrawAwardConfig",
        "playerData",       -- player state
        "globalConfig",     -- config
    },
    PATH_HINTS = {
        "lobby_activity","XSuit","xsuit","tarot_card","scrap_gold",
        "logic_luck","logic_draw","godzilla","Godzilla","super_airdrop",
        "luck_util","Turntable","turn_table","draw","Draw",
        "lottery","Lottery","spin","Spin",
        "store","Store","supply","Supply",
        "activity","Activity",
    },
    DRAW_HINTS = {
        "draw","Draw","spin","Spin","lottery","Lottery","rotate","Rotate",
        "OnRandom","OnRecv","OnBegin","OnOpen",
        "OneDraw","TenDraw","DoDraw","DoLottery","SendDraw","ReqDraw",
        "SendBuy","OpenBox","OpenCrate","OpenChest","OnClick","RegistDrawBtn",
        "OnClickedBannerTab","OnClickTab","GetTotalDrawAwardConfig",
    },
    RSP_TARGETS = {
        { "client.network.Protocol.StoreHandler", {
            "on_do_one_draw_by_activity_rsp","on_do_draw_discount_by_activity_rsp",
            "on_do_biochemical_activity_one_draw_rsp","on_buy_shop_by_id_rsp",
            "on_buy_market_by_id_rsp","on_limited_discount_buy_rsp",
            "on_receive_guarantee_reward_rsp","on_get_market_chest_info_rsp",
            "on_get_market_buy_info_rsp_v3","on_get_shop_info_rsp",
            "on_get_lucky_draw_unback_activity_rsp","on_market_buy_chest_item_notify",
            "on_please_direct_buy","on_notice_shop_guarantee_reward",
            "on_buy_shop_by_id_ntf",
        }},
        { "client.network.Protocol.LuckybackHandler", {
            "on_do_one_draw_back_by_activity_rsp","on_get_lucky_draw_back_activity_rsp",
            "on_get_lucky_draw_back_voucher_rsp","on_get_lucky_draw_collect_award_rsp",
            "on_get_sum_draw_award_by_activity_rsp","on_do_exchange_by_activity_id_rsp",
        }},
        { "client.network.Protocol.LuckySpecialHandler", {
            "on_do_draw_act_rsp","on_get_draw_act_info_rsp","on_get_extra_reward_rsp",
        }},
        { "client.network.Protocol.XSuitHandler", {
            "on_draw_gold_dress_rsp","on_get_wish_pool_rsp","on_get_gold_dress_activity_rsp",
        }},
        { "client.network.Protocol.SupplyOptionalHandler", {
            "on_get_role_custom_chest_info_rsp","on_role_chest_custom_buy_rsp",
        }},
        { "client.network.Protocol.ActivityHandler", {
            "on_get_activity_reward_rsp","on_get_activity_one_rsp","on_get_activity_list_rsp",
        }},
        { "client.network.Protocol.DropBoxHandler", {
            "on_get_content_by_chestids_rsp","on_get_content_by_dropids_rsp",
        }},
    },
}

-- ============ POPUP ============
local function pop(t,m)
    pcall(function()
        local M = package.loaded["client.slua.logic.common.logic_common_msg_box"]
                    or require("client.slua.logic.common.logic_common_msg_box")
        if M and M.Show then M.Show(4, tostring(t), tostring(m)) end
    end)
end

-- ============ JSON ============
local function esc(s)
    s = tostring(s)
    return (s:gsub("\\","\\\\"):gsub("\"","\\\""):gsub("\n","\\n"):gsub("\r","\\r"):gsub("\t","\\t"))
end

local function toJSON(v, d)
    d = d or 0
    if d > CFG.MAX_DEPTH then return "\"<d>\"" end
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
    if t == "userdata" then return "\"<u>\"" end
    if t == "function" then return "\"<f>\"" end
    if t == "table" then
        local n, isArr = 0, true
        for k in pairs(v) do
            n = n + 1
            if type(k) ~= "number" then isArr = false; break end
        end
        if isArr and n > 0 then
            local p = {}
            for i = 1, math.min(#v, CFG.MAX_KEYS) do p[#p+1] = toJSON(v[i], d+1) end
            if #v > CFG.MAX_KEYS then p[#p+1] = "\"<..>\"" end
            return "[" .. table.concat(p, ",") .. "]"
        end
        local p = {}
        for k, vv in pairs(v) do
            p[#p+1] = "\"" .. esc(k) .. "\":" .. toJSON(vv, d+1)
            if #p >= CFG.MAX_KEYS then p[#p+1] = "\"__t\":true"; break end
        end
        return "{" .. table.concat(p, ",") .. "}"
    end
    return "\"<?>\""
end

-- ============ WRITER (multi-file) ============
local files = {
    raw     = { path = CFG.RAW_OUT,     buf = {}, n = 0, ok = 0, fail = 0 },
    extract = { path = CFG.EXTRACT_OUT, buf = {}, n = 0, ok = 0, fail = 0 },
}

local function fileRawWrite(f, payload)
    local wrote = false
    pcall(function()
        local h = io.open(f.path, "a")
        if h then h:write(payload); h:close(); wrote = true end
    end)
    if not wrote then
        pcall(function()
            local name = f.path:match("([^/]+)$")
            local h = io.open(CFG.FALLBACK .. name, "a")
            if h then h:write(payload); h:close(); wrote = true end
        end)
    end
    if wrote then f.ok = f.ok + 1 else f.fail = f.fail + 1 end
end

local function flushFile(f)
    if f.n == 0 then return end
    fileRawWrite(f, table.concat(f.buf, "\n") .. "\n")
    f.buf, f.n = {}, 0
end

local function flushAll()
    flushFile(files.raw)
    flushFile(files.extract)
end

local function writeLine(f, obj)
    f.buf[#f.buf+1] = toJSON(obj)
    f.n = f.n + 1
    if f.n >= 12 then flushFile(f) end
end

local function raw(tag, evt, data)
    writeLine(files.raw, {
        t = os.date("%Y-%m-%dT%H:%M:%S"),
        tag = tag, evt = evt, data = data or {},
    })
end

local function extract(tag, data)
    writeLine(files.extract, {
        t = os.date("%Y-%m-%dT%H:%M:%S"),
        tag = tag, data = data or {},
    })
end

-- ============ SIGNATURE ============
local function sig(s)
    s = tostring(s or "")
    if #s > 240 then s = s:sub(1,120) .. "|" .. s:sub(-120) end
    local sum = 0
    for i = 1, #s do sum = (sum + s:byte(i)) % 1000000007 end
    return string.format("%d:%d", #s, sum)
end

-- ============ SAFE REQUIRE ============
local function safeReq(...)
    for _, p in ipairs({...}) do
        local ok, m = pcall(require, p)
        if ok and m then return m end
    end
    return nil
end

-- =================================================================
-- PART 1: UC / CURRENCY BYPASS
-- =================================================================
local FAKE = 999999999

local function applyUCBypass()
    local patched = {}

    -- DataMgr
    local dMgr = _G.DataMgr
        or safeReq("client.slua.logic.common.DataMgr")
        or safeReq("client.data.DataMgr")
    if dMgr then
        dMgr.uc = FAKE; dMgr.UC = FAKE
        dMgr.ticket = FAKE; dMgr.gold = FAKE; dMgr.diamond = FAKE
        dMgr.money = FAKE; dMgr.currency = FAKE
        dMgr.ag = FAKE; dMgr.bp = FAKE; dMgr.silver = FAKE
        dMgr.coupon = FAKE; dMgr.voucher = FAKE
        dMgr.fp_token = FAKE; dMgr.gold_chip = FAKE
        if dMgr.roleData then
            dMgr.roleData.uc = FAKE
            dMgr.roleData.ticket = FAKE
            dMgr.roleData.gold = FAKE
            dMgr.roleData.diamond = FAKE
            dMgr.roleData.bgbg_vip = 1
        end
        dMgr.GetUC = function() return FAKE end
        dMgr.GetCurrency = function() return FAKE end
        dMgr.GetMoney = function() return FAKE end
        dMgr.GetTicket = function() return FAKE end
        dMgr.GetGold = function() return FAKE end
        dMgr.GetDiamond = function() return FAKE end
        dMgr.GetMoneyByType = function() return FAKE end
        dMgr.CheckIsEnough = function() return true end
        dMgr.CheckUC = function() return true end
        dMgr.CheckMoney = function() return true end
        dMgr.CheckCurrency = function() return true end
        dMgr.CheckTicket = function() return true end
        dMgr.IsMoneyEnough = function() return true end
        dMgr.IsCurrencyEnough = function() return true end
        patched[#patched+1] = "DataMgr"
    end

    -- supply_payment_manager
    local spm = safeReq("client.slua.logic.supply.supply_payment.supply_payment_manager")
    if spm then
        spm.CheckCanPay = function() return true end
        spm.CanPay = function() return true end
        spm.CheckBeforeBuy = function() return true end
        if spm.GetCurrencyCount then spm.GetCurrencyCount = function() return FAKE end end
        patched[#patched+1] = "supply_payment_manager"
    end

    -- payment types
    local pays = {
        "client.slua.logic.supply.supply_payment.playment_type.payment_uc",
        "client.slua.logic.supply.supply_payment.playment_type.payment_bp",
        "client.slua.logic.supply.supply_payment.playment_type.payment_ag",
        "client.slua.logic.supply.supply_payment.playment_type.payment_token",
        "client.slua.logic.supply.supply_payment.playment_type.payment_exchange",
        "client.slua.logic.supply.supply_payment.playment_type.payment_act_coin",
        "client.slua.logic.supply.supply_payment.playment_type.payment_free",
        "client.slua.logic.supply.supply_payment.playment_type.payment_advertisement",
        "client.slua.logic.supply.supply_payment.playment_type.payment_other",
        "client.slua.logic.supply.supply_payment.playment_type.payment_base",
    }
    for _, p in ipairs(pays) do
        local P = safeReq(p)
        if P then
            if P.CheckEnough then P.CheckEnough = function() return true end end
            if P.CanPay then P.CanPay = function() return true end end
            if P.GetCurrencyNum then P.GetCurrencyNum = function() return FAKE end end
            if P.GetCount then P.GetCount = function() return FAKE end end
        end
    end
    patched[#patched+1] = "payment_*"

    -- pay box
    local payBox = safeReq("client.slua.logic.common.Payclass.logic_common_pay_box")
    if payBox then
        payBox.CheckIsEnoughUC = function() return true end
        payBox.ShowUcRechargeMsg = function() return true end
        payBox.ShowRechargeMsg = function() return true end
        payBox.OpenPayBox = function() return true end
        payBox.ShowPayBox = function() return true end
        patched[#patched+1] = "pay_box"
    end

    -- luckyback / luckyunback module prices -> 0
    local lb = safeReq("client.slua.logic.lobby_activity.logic_luckyback_activity")
    if lb then
        lb.GetOneDrawDiscountPrice = function() return 0 end
        if lb.GetTenDrawDiscountPrice then lb.GetTenDrawDiscountPrice = function() return 0 end end
        if lb.GetOneDrawOriginalPrice then lb.GetOneDrawOriginalPrice = function() return 0 end end
        if lb.HasEnoughUC then lb.HasEnoughUC = function() return true end end
        patched[#patched+1] = "logic_luckyback_activity"
    end

    local lu = safeReq("client.slua.logic.lobby_activity.logic_luckyunback_activity")
    if lu then
        if lu.GetNextDrawCost then lu.GetNextDrawCost = function() return 0 end end
        if lu.HasEnoughUC then lu.HasEnoughUC = function() return true end end
        patched[#patched+1] = "logic_luckyunback_activity"
    end

    -- QR restrict
    local QR = safeReq("client.module_framework.CommonModuleConfig.QRcodeRestrictManager")
    if QR then
        QR.CheckUCRestrict = function() return false end
        QR.IsRestrictUC = function() return false end
        QR.ShowRestrictTips = function() end
        patched[#patched+1] = "QRRestrict"
    end

    return patched
end

-- =================================================================
-- PART 2: SNAPSHOT + DELTA
-- =================================================================
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
            out[k] = "<t:" .. cnt .. ">"
        end
    end
    return out
end

local function delta(pre, post)
    local d = { c = {}, a = {}, r = {} }
    local seen = {}
    for k, v in pairs(post or {}) do
        seen[k] = true
        if pre[k] == nil then d.a[k] = v
        elseif tostring(pre[k]) ~= tostring(v) then d.c[k] = { from = pre[k], to = v } end
    end
    for k, v in pairs(pre or {}) do
        if not seen[k] then d.r[k] = v end
    end
    local n = 0
    for _ in pairs(d.c) do n = n + 1 end
    for _ in pairs(d.a) do n = n + 1 end
    for _ in pairs(d.r) do n = n + 1 end
    if n == 0 then return nil end
    return d
end

-- =================================================================
-- PART 3: SMART EXTRACTOR
-- =================================================================
-- Track what we've already extracted to avoid dupes in extract file
local extractedActivities = {}   -- [path] = true
local extractedRspShape  = {}    -- [handler::rsp] = true
local extractedSendShape = {}    -- [path::method] = true

local function tablePreview(t, maxN)
    if type(t) ~= "table" then return nil end
    maxN = maxN or 8
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    local arr = {}
    local i = 0
    -- try numeric first
    for idx = 1, math.min(#t, maxN) do
        i = i + 1
        arr[i] = t[idx]
    end
    if i == 0 then
        -- non-array, show key list
        local k = 0
        local keys = {}
        for kk in pairs(t) do
            k = k + 1
            if k > maxN then keys[#keys+1] = "<..>"; break end
            keys[#keys+1] = tostring(kk)
        end
        return { count = n, keys = keys }
    end
    return { count = n, sample = arr }
end

-- Extract activity module state + pools
local function extractActivity(path, mod)
    if type(mod) ~= "table" then return end
    local isActivity = false
    for _, frag in ipairs(CFG.ACTIVITY_PATHS) do
        if path:find(frag, 1, true) then isActivity = true; break end
    end
    if not isActivity then return end
    if extractedActivities[path] then return end
    extractedActivities[path] = true

    local out = { path = path }

    -- scalars
    local scalars = {}
    for _, key in ipairs(CFG.ACTIVITY_FIELDS) do
        local v = mod[key]
        if v ~= nil and (type(v) == "number" or type(v) == "string" or type(v) == "boolean") then
            scalars[key] = v
        end
    end
    out.fields = scalars

    -- tables (size + preview)
    local tbls = {}
    for _, key in ipairs(CFG.ACTIVITY_TABLES) do
        local v = mod[key]
        if type(v) == "table" then
            tbls[key] = tablePreview(v, 6)
        end
    end
    out.tables = tbls

    extract("activity", out)
end

-- Extract first-seen send method shape
local function extractSendShape(path, method, argsJson, retVal)
    local key = path .. "::" .. method
    if extractedSendShape[key] then return end
    -- Skip noise: only keep meaningful send/draw calls
    local interesting = false
    for _, hint in ipairs(CFG.DRAW_HINTS) do
        if method:find(hint, 1, true) then interesting = true; break end
    end
    if not interesting then return end
    extractedSendShape[key] = true
    extract("send_shape", {
        path = path,
        method = method,
        args = argsJson,
        ret = retVal,
    })
end

-- Extract first-seen rsp shape
local function extractRspShape(handler, rspName, argsJson)
    local key = handler .. "::" .. rspName
    if extractedRspShape[key] then return end
    extractedRspShape[key] = true
    extract("rsp_shape", {
        handler = handler,
        rsp = rspName,
        args = argsJson,
    })
end

-- =================================================================
-- PART 4: HOOKS
-- =================================================================
local seenClick, seenRsp = {}, {}
local hooked, rspHooked, installedMods = {}, {}, {}
local stats = { dups = 0, ok = 0, fail = 0 }
local rspCount = 0

local function matchesAny(s, list)
    if type(s) ~= "string" then return false end
    for _, pat in ipairs(list) do
        if s:find(pat, 1, true) then return true end
    end
    return false
end

local function isDrawMethod(name)
    if type(name) ~= "string" then return false end
    if name:sub(1,1) == "_" then return false end
    return matchesAny(name, CFG.DRAW_HINTS)
end

local function hookModule(path, mod)
    if type(mod) ~= "table" then return end

    -- extract activity state once
    pcall(extractActivity, path, mod)

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

                    local dupKey = key .. "::" .. sig(argsJson)
                    local entry = seenClick[dupKey]

                    if CFG.DEDUPE and entry then
                        entry.count = entry.count + 1
                        stats.dups = stats.dups + 1
                    else
                        seenClick[dupKey] = { count = 1 }
                        local rec = {
                            path = path,
                            method = name,
                            args = argsJson,
                            ok = ok,
                        }
                        if r1 ~= nil then
                            rec.ret = r1
                            if r2 ~= nil then rec.ret2 = r2 end
                            if r3 ~= nil then rec.ret3 = r3 end
                        end
                        if CFG.DELTA_ONLY then
                            local d = delta(pre, post)
                            if d then rec.delta = d end
                        else
                            rec.pre = pre
                            rec.post = post
                        end
                        raw("click", "draw", rec)
                        flushFile(files.raw)
                        -- also extract shape (first time only)
                        extractSendShape(path, name, argsJson, r1)
                    end

                    if ok then return r1, r2, r3, r4 end
                    return r1
                end
            end
        end
    end
    if not installedMods[path] then installedMods[path] = true end
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
        local argsJson = toJSON(args, 2)
        local dupKey = key .. "::" .. sig(argsJson)
        local entry = seenRsp[dupKey]
        if CFG.DEDUPE and entry then
            entry.count = entry.count + 1
            stats.dups = stats.dups + 1
        else
            seenRsp[dupKey] = { count = 1 }
            raw("rsp", rspName, {
                handler = handlerPath,
                args = argsJson,
            })
            flushFile(files.raw)
            -- extract shape
            extractRspShape(handlerPath, rspName, argsJson)
        end
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

local function discover()
    local matched = 0
    for path, mod in pairs(package.loaded) do
        if type(path) == "string" and type(mod) == "table" then
            if matchesAny(path, CFG.PATH_HINTS) then
                hookModule(path, mod)
                matched = matched + 1
            end
        end
    end
    return matched
end

-- =================================================================
-- BOOT
-- =================================================================
flushAll()
raw("boot", "start", { v = "roxs v1", ts = os.date("%Y-%m-%d %H:%M:%S") })
extract("boot", { v = "roxs v1", ts = os.date("%Y-%m-%d %H:%M:%S") })
flushAll()

-- UC bypass
local ucp = applyUCBypass()
raw("boot", "uc_bypass", { patched = ucp })
extract("uc_bypass", { patched = ucp })
flushAll()

-- Hooks
local modCount = discover()
installRspHooks()
local hookCount = 0
for _ in pairs(hooked) do hookCount = hookCount + 1 end
raw("boot", "install", { modules = modCount, draw_hooks = hookCount, rsp_hooks = rspCount })
extract("install", { modules = modCount, draw_hooks = hookCount, rsp_hooks = rspCount })
flushAll()

if CFG.POPUP then
    pop("ROXS", "All-in-one ready.\nUC patched: " .. #ucp .. "\nmods=" .. modCount ..
        " hooks=" .. hookCount)
end
print("[ROXS] ready mods=" .. modCount .. " hooks=" .. hookCount .. " uc_patched=" .. #ucp)

-- =================================================================
-- LOOP
-- =================================================================
local ticker = safeReq("common.time_ticker")
if not ticker or not ticker.AddTimerLoop then
    raw("boot", "err", { msg = "no time_ticker" })
    flushAll()
    pop("ROXS", "No time_ticker")
    return
end

local tick = 0
ticker.AddTimerLoop(0, function()
    pcall(function()
        tick = tick + 1
        local per = math.max(1, math.floor(CFG.RESCAN / 0.5))
        if tick % per == 0 then
            local mc = discover()
            installRspHooks()
            if mc > 0 then
                raw("state", "rescan", { tick = tick, modules = mc })
            end
            -- also re-extract activity state (it changes as user navigates)
            extractedActivities = {}  -- force re-extract on next discover
            discover()
            flushAll()
        end
    end)
end, -1, 0.5)

-- =================================================================
-- PUBLIC API
-- =================================================================
_G.ROXS = {
    status = function()
        local hc = 0; for _ in pairs(hooked) do hc = hc + 1 end
        local ue = 0; for _ in pairs(seenClick) do ue = ue + 1 end
        local ur = 0; for _ in pairs(seenRsp) do ur = ur + 1 end
        pop("ROXS", string.format(
            "hooks=%d uniq_click=%d uniq_rsp=%d\ndups_skipped=%d\nraw_ok=%d raw_fail=%d\nxt_ok=%d xt_fail=%d",
            hc, ue, ur, stats.dups,
            files.raw.ok, files.raw.fail,
            files.extract.ok, files.extract.fail))
    end,
    flush = function() flushAll() pop("ROXS", "flushed") end,
    -- Force re-extract of all activity modules (call after opening activity)
    rescan = function()
        extractedActivities = {}
        extractedSendShape = {}
        extractedRspShape = {}
        discover()
        installRspHooks()
        flushAll()
        pop("ROXS", "rescanned")
    end,
    paths = function()
        pop("ROXS", "raw: " .. CFG.RAW_OUT .. "\nextract: " .. CFG.EXTRACT_OUT)
    end,
}

print("[ROXS] api: _G.ROXS.status() / .flush() / .rescan() / .paths()")
