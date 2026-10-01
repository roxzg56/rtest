-- ===============================================================
-- gdump.lua v2 — real gacha event recon dumper
-- Output: /storage/emulated/0/Android/data/com.pubg.imobile/files/gdump.jsonl
-- Dumps: protocol handlers, activity modules, live IDs, reward pools, configs
-- ===============================================================

local CFG = {
    OUT = "/storage/emulated/0/Android/data/com.pubg.imobile/files/gdump.jsonl",
    OUT_FALLBACK = "/sdcard/gdump.jsonl",
    POPUP = true,
    MAX_STR = 300,
    MAX_KEYS = 60,
    MAX_DEPTH = 4,
    DUMP_ITEM_TABLE = true,
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
    if bufN >= 20 then flush() end
end

-- ============ HELPERS ============
local function safeReq(...)
    for _, p in ipairs({...}) do
        local ok, m = pcall(require, p)
        if ok and m then return m end
    end
    return nil
end

-- ============ PASS 1: PROTOCOL HANDLERS ============
local function dumpProtocol()
    emit("scan", "protocol_start", {})
    local seen = {}
    local count = 0
    for path, mod in pairs(package.loaded) do
        if type(path) == "string" and path:find("client.network.Protocol.", 1, true) then
            if not seen[path] then
                seen[path] = true
                count = count + 1
                local sends, rsps, other = {}, {}, {}
                if type(mod) == "table" then
                    for k, v in pairs(mod) do
                        if type(k) == "string" and type(v) == "function" then
                            if k:find("^send_") then sends[#sends+1] = k
                            elseif k:find("^on_") and k:find("_rsp") then rsps[#rsps+1] = k
                            elseif not k:find("^_") then other[#other+1] = k end
                        end
                    end
                end
                table.sort(sends); table.sort(rsps); table.sort(other)
                emit("protocol", "module", {
                    path = path,
                    sends = sends,
                    rsps = rsps,
                    other = other,
                })
            end
        end
    end
    emit("scan", "protocol_done", { count = count })
end

-- ============ PASS 2: ACTIVITY MODULES ============
local function dumpActivities()
    emit("scan", "activity_start", {})
    local seen = {}
    local count = 0
    for path, mod in pairs(package.loaded) do
        if type(path) == "string" and path:find("client.slua.logic.", 1, true) then
            if not seen[path] and (path:find("activity") or path:find("lucky") 
                or path:find("XSuit") or path:find("tarot") or path:find("supply")) then
                seen[path] = true
                count = count + 1
                local scalars = {}
                local hasDraw, hasCost, hasID = false, false, false
                local activityId = nil
                if type(mod) == "table" then
                    for k, v in pairs(mod) do
                        local tv = type(v)
                        if tv == "number" or tv == "string" or tv == "boolean" then
                            if k:find("^[a-z]") or k:find("^[A-Z]") then
                                scalars[k] = v
                            end
                        end
                        if tv == "function" then
                            if k:find("[Dd]raw") or k:find("[Ss]pin") or k:find("[Ll]ottery") then hasDraw = true end
                            if k:find("[Cc]ost") or k:find("[Pp]rice") then hasCost = true end
                        end
                        if k == "ActivityId" or k == "activity_id" or k == "actId" or k == "ActivityID" then
                            hasID = true
                            activityId = v
                        end
                    end
                end
                emit("activity", "module", {
                    path = path,
                    activity_id = activityId,
                    has_draw_fn = hasDraw,
                    has_cost_fn = hasCost,
                    scalars = scalars,
                })
            end
        end
    end
    emit("scan", "activity_done", { count = count })
end

-- ============ PASS 3: LIVE ACTIVITY IDS + MODULE MANAGER ============
local function dumpLive()
    emit("scan", "live_start", {})

    if ModuleManager and ModuleManager.LobbyModuleConfig then
        local count = 0
        for k, v in pairs(ModuleManager.LobbyModuleConfig) do
            if type(k) == "string" then
                count = count + 1
                local loaded = nil
                pcall(function() loaded = ModuleManager.GetModule(v) end)
                emit("live", "lobby_module", {
                    key = k,
                    module_id = tostring(v),
                    loaded = loaded ~= nil,
                })
            end
        end
        emit("live", "lobby_module_count", { n = count })
    end

    emit("scan", "live_done", {})
end

-- ============ PASS 4: SUPPLY/STORE PAGE DATA ============
local function dumpSupplyStore()
    emit("scan", "supply_start", {})
    pcall(function()
        if not (ModuleManager and ModuleManager.GetModule and ModuleManager.LobbyModuleConfig) then return end
        local sss = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.store_supply_switcher)
        if not sss then return end

        local supply = sss.GetSupplySystem and sss:GetSupplySystem()
        if supply and supply.PageListPanel and supply.PageListPanel.itemDataList then
            for i, v in pairs(supply.PageListPanel.itemDataList) do
                emit("supply", "item", {
                    idx = i,
                    itemId = v.itemId,
                    name = v.name or v.itemName,
                    price = v.price,
                    currency = v.currency,
                    limit = v.limit or v.buyLimit,
                })
            end
        end

        local store = sss.GetStoreSystem and sss:GetStoreSystem()
        if store and store.PageListPanel and store.PageListPanel.itemDataList then
            for i, v in pairs(store.PageListPanel.itemDataList) do
                emit("store", "item", {
                    idx = i,
                    itemId = v.itemId,
                    name = v.name or v.itemName,
                    price = v.price,
                    currency = v.currency,
                    limit = v.limit or v.buyLimit,
                })
            end
        end
    end)
    emit("scan", "supply_done", {})
end

-- ============ PASS 5: REWARD POOLS ============
local function dumpPools()
    emit("scan", "pool_start", {})
    local candidates = {
        "client.slua.logic.lobby_activity.logic_luckyback_activity",
        "client.slua.logic.lobby_activity.logic_luckyunback_activity",
        "client.slua.logic.lobby_activity.logic_luckymulti_activity",
        "client.slua.logic.lobby_activity.logic_luckmix_activity",
        "client.slua.logic.XSuit.logic_xsuit_activity",
        "client.slua.logic.tarot_card.logic_tarotcard_drawcard",
        "client.slua.logic.store.logic_box_draw",
        "client.slua.logic.store.logic_crate",
        "client.slua.logic.supply.logic_supply",
    }
    for _, p in ipairs(candidates) do
        local m = safeReq(p)
        if m and type(m) == "table" then
            for k, v in pairs(m) do
                if type(v) == "table" and (k:find("reward") or k:find("drop") 
                    or k:find("pool") or k:find("award") or k:find("draw_list")) then
                    local preview = {}
                    local n = 0
                    for i, item in pairs(v) do
                        n = n + 1
                        if n > 30 then break end
                        if type(item) == "table" then
                            preview[#preview+1] = {
                                id = item.resid or item.res_id or item.itemid or item.id,
                                count = item.count or item.item_count or item.num,
                                weight = item.weight or item.rate or item.prob,
                            }
                        end
                    end
                    if #preview > 0 then
                        emit("pool", p, { field = k, items = preview, total = #v })
                    end
                end
            end
        end
    end
    emit("scan", "pool_done", {})
end

-- ============ PASS 6: CDataTable CONFIGS ============
local function dumpConfigs()
    if not CFG.DUMP_ITEM_TABLE then return end
    emit("scan", "cfg_start", {})
    local CD = _G.CDataTable or safeReq("common.CDataTable")
    if not CD or not CD.GetTableData then
        emit("scan", "cfg_skip", { msg = "no CDataTable" })
        return
    end

    -- Item table: probe range
    local itemCount = 0
    for i = 1, 500 do
        local cfg = nil
        pcall(function() cfg = CD.GetTableData("Item", i) end)
        if cfg then
            itemCount = itemCount + 1
            emit("cfg", "item", {
                id = i,
                name = cfg.Name or cfg.name,
                type = cfg.Type or cfg.type,
                quality = cfg.Quality or cfg.quality,
                icon = cfg.Icon or cfg.icon,
            })
        end
    end
    emit("scan", "cfg_item_count", { n = itemCount })

    -- try common crate tables
    local tables = { "SupplyBox", "Crate", "Chest", "DrawPool", "LotteryPool", "ActivityConfig", "Goods" }
    for _, tbl in ipairs(tables) do
        pcall(function()
            if CD.GetTable then
                local data = CD.GetTable(tbl)
                if data and type(data) == "table" then
                    local n = 0
                    for id, cfg in pairs(data) do
                        n = n + 1
                        if n > 40 then break end
                        emit("cfg", tbl, { id = id, cfg = cfg })
                    end
                end
            end
        end)
    end
    emit("scan", "cfg_done", {})
end

-- ============ BOOT ============
flush()
emit("boot", "start", { out = CFG.OUT, ts = os.date("%Y-%m-%d %H:%M:%S"), v = "gdump v2" })
flush()

if CFG.POPUP then POPUP("GDUMP", "Recon running...\n" .. CFG.OUT) end

pcall(dumpProtocol)
pcall(dumpActivities)
pcall(dumpLive)
pcall(dumpSupplyStore)
pcall(dumpPools)
pcall(dumpConfigs)

emit("boot", "done", { ok = stats.ok, fail = stats.fail, ts = os.date("%Y-%m-%d %H:%M:%S") })
flush()

-- ============ PUBLIC API ============
_G.GDRescan = function()
    emit("manual", "rescan", { ts = os.date("%Y-%m-%d %H:%M:%S") })
    pcall(dumpProtocol)
    pcall(dumpActivities)
    pcall(dumpLive)
    pcall(dumpSupplyStore)
    pcall(dumpPools)
    pcall(dumpConfigs)
    flush()
    POPUP("GDUMP", "Rescan done. ok=" .. stats.ok .. " fail=" .. stats.fail)
end

_G.GDStatus = function()
    emit("manual", "status", { ok = stats.ok, fail = stats.fail })
    flush()
    POPUP("GDUMP", "ok=" .. stats.ok .. " fail=" .. stats.fail .. "\n" .. CFG.OUT)
end

print("[GD2] done — file=" .. CFG.OUT)
if CFG.POPUP then
    POPUP("GDUMP OK", "Done!\nok=" .. stats.ok .. " fail=" .. stats.fail .. "\n\n" .. CFG.OUT)
end
