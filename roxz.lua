-- ═══════════════════════════════════════════════════════════════════
-- v38 — REAL DROP DUMPER
-- Purpose: server se aane wala asli airdrop data capture karo
-- Layers: Network handlers + BornIslandAirDropSystem + config tables
-- Output: 4 files — packets, system calls, configs, live summary
-- ═══════════════════════════════════════════════════════════════════

local DIR = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"

local function S(name, content)
    local f = io.open(DIR .. name, "w")
    if not f then return false end
    f:write(content or ""); f:close()
    return true
end

local function P(t, m)
    pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
        if Msg and Msg.Show then
            Msg.Show(1, tostring(t), tostring(m), function() end, function() end, "OK", "CLOSE")
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- DEEP SERIALIZER — tables ke andar tak jaayega
-- ═══════════════════════════════════════════════════════════════════
local function ser(v, depth, seen)
    depth = depth or 0
    seen = seen or {}
    if depth > 5 then return "..." end
    local t = type(v)
    if t == "nil"    then return "nil" end
    if t == "boolean" then return tostring(v) end
    if t == "number" then
        if v == math.floor(v) and math.abs(v) < 1e15 then
            return string.format("%d", v)
        end
        return tostring(v)
    end
    if t == "string" then return string.format("%q", v) end
    if t == "function" then return "<fn>" end
    if t == "userdata" then return "<userdata>" end
    if t == "table" then
        if seen[v] then return "<cycle>" end
        seen[v] = true
        local parts = {}
        local count = 0
        -- array first
        for i = 1, math.min(#v, 30) do
            parts[#parts+1] = ser(v[i], depth+1, seen)
            count = count + 1
        end
        -- then keys
        local keys = {}
        for k in pairs(v) do
            if type(k) ~= "number" or k > #v then
                keys[#keys+1] = k
            end
        end
        for _, k in ipairs(keys) do
            if count >= 50 then parts[#parts+1] = "..." break end
            parts[#parts+1] = tostring(k) .. "=" .. ser(v[k], depth+1, seen)
            count = count + 1
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    return "<" .. t .. ">"
end

local function argsPack(...)
    local n = select("#", ...)
    local parts = {}
    for i = 1, math.min(n, 8) do
        parts[#parts+1] = ser((select(i, ...)), 0, {})
    end
    if n > 8 then parts[#parts+1] = "..." end
    return "(" .. table.concat(parts, ", ") .. ")"
end

-- ═══════════════════════════════════════════════════════════════════
-- LOG BUFFERS
-- ═══════════════════════════════════════════════════════════════════
local LOG = {
    packets = {},       -- network on_* / send_* handlers
    system  = {},       -- BornIslandAirDropSystem calls
    lucky   = {},       -- logic_luck_air_drop calls
    summary = {},       -- human-readable summary
}

local ACTIVE = false
local START_TIME = os.time()

local function ts()
    return os.date("%H:%M:%S")
end

local function addTo(bucket, line)
    if not ACTIVE then return end
    bucket[#bucket+1] = "[" .. ts() .. "] " .. line
end

local function flush()
    S("v38_packets.txt", table.concat(LOG.packets, "\n"))
    S("v38_system.txt",  table.concat(LOG.system, "\n"))
    S("v38_lucky.txt",   table.concat(LOG.lucky, "\n"))
    S("v38_summary.txt", table.concat(LOG.summary, "\n"))
end

-- ═══════════════════════════════════════════════════════════════════
-- HOOK ENGINE — kisi bhi module ke saare functions ko wrap karta hai
-- ═══════════════════════════════════════════════════════════════════
local hookedModules = {}

local function hookModule(path, bucket, tag)
    local M = package.loaded[path]
    if not M then
        pcall(function() M = require(path) end)
    end
    if type(M) ~= "table" then
        addTo(bucket, tag .. " MODULE NOT LOADED: " .. path)
        return false
    end

    if hookedModules[path] then
        addTo(bucket, tag .. " already hooked: " .. path)
        return true
    end
    hookedModules[path] = true

    local targets = {}
    local impl = M.__inner_impl
    if type(impl) == "table" then targets[#targets+1] = impl end
    targets[#targets+1] = M

    local count = 0
    for _, target in ipairs(targets) do
        for name, fn in pairs(target) do
            if type(fn) == "function" and type(name) == "string" then
                local orig = fn
                target[name] = function(self, ...)
                    local beforeT = os.clock()
                    local n = select("#", ...)
                    addTo(bucket, tag .. "." .. name .. argsPack(...))
                    local ok, r = pcall(orig, self, ...)
                    local ms = (os.clock() - beforeT) * 1000
                    if not ok then
                        addTo(bucket, "  ✗ " .. tostring(r):sub(1, 300))
                    elseif n == 0 and r == nil then
                        addTo(bucket, string.format("  ↳ void (%.1fms)", ms))
                    else
                        addTo(bucket, "  ↳ RET " .. ser(r, 0, {}) .. string.format(" (%.1fms)", ms))
                    end
                    return r
                end
                count = count + 1
            end
        end
    end
    addTo(bucket, tag .. " hooked " .. count .. " fns: " .. path)
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- CONFIG DUMP — static tables padho
-- ═══════════════════════════════════════════════════════════════════
local function dumpConfigs()
    local out = {}
    out[#out+1] = "═══ v38 CONFIG DUMP ═══"
    out[#out+1] = "Time: " .. os.date("%Y-%m-%d %H:%M:%S")
    out[#out+1] = ""

    local configPaths = {
        "GameLua.Mod.BaseMod.GamePlay.Config.BornIslandAirDropConfig",
        "GameLua.Mod.BaseMod.GamePlay.Config.ModActivityAirDropManagerConfig",
        "GameLua.Mod.BaseMod.GamePlay.Config.IslandConfig",
        "GameLua.Mod.BaseMod.GamePlay.Config.ParachuteFollowBehaviorConfig",
        "GameLua.Mod.BaseMod.GamePlay.Config.BornIslandTeamShowConfig",
    }

    for _, path in ipairs(configPaths) do
        local M = package.loaded[path]
        if not M then pcall(function() M = require(path) end) end
        out[#out+1] = "── " .. path .. " ──"
        if type(M) == "table" then
            local count = 0
            for k, v in pairs(M) do
                if count >= 80 then out[#out+1] = "  ..." break end
                out[#out+1] = "  " .. tostring(k) .. " = " .. ser(v, 0, {})
                count = count + 1
            end
            out[#out+1] = "  total keys: " .. count
        else
            out[#out+1] = "  NOT LOADED"
        end
        out[#out+1] = ""
    end

    S("v38_configs.txt", table.concat(out, "\n"))
end

-- ═══════════════════════════════════════════════════════════════════
-- DATAMGR DUMP — vehicle tables snapshot
-- ═══════════════════════════════════════════════════════════════════
local function dumpDataMgr()
    local out = {}
    out[#out+1] = "═══ v38 DATAMGR DUMP ═══"
    out[#out+1] = "Time: " .. os.date("%Y-%m-%d %H:%M:%S")
    out[#out+1] = ""

    local DM = package.loaded["client.logic.data.DataMgr"]
    if not DM then pcall(function() DM = require("client.logic.data.DataMgr") end) end
    if type(DM) ~= "table" then
        out[#out+1] = "DataMgr NOT LOADED"
        S("v38_datamgr.txt", table.concat(out, "\n"))
        return
    end

    local tables = {
        "VehicleSlotList",
        "vehicleSkinInsIDTable",
        "defaultVehicleSkinResIDTable",
        "roleData",
    }

    for _, tname in ipairs(tables) do
        out[#out+1] = "── DataMgr." .. tname .. " ──"
        local t = DM[tname]
        if type(t) == "table" then
            local count = 0
            for k, v in pairs(t) do
                if count >= 40 then out[#out+1] = "  ..." break end
                out[#out+1] = "  [" .. tostring(k) .. "] = " .. ser(v, 0, {})
                count = count + 1
            end
            out[#out+1] = "  total: " .. count
        else
            out[#out+1] = "  " .. tostring(t)
        end
        out[#out+1] = ""
    end

    S("v38_datamgr.txt", table.concat(out, "\n"))
end

-- ═══════════════════════════════════════════════════════════════════
-- START — pehle configs + datamgr dump, phir hooks lagao
-- ═══════════════════════════════════════════════════════════════════
_G.V38_Start = function()
    if ACTIVE then P("v38", "Already active"); return end
    ACTIVE = true
    START_TIME = os.time()

    addTo(LOG.summary, "=== v38 DUMPER STARTED ===")
    addTo(LOG.summary, "Time: " .. os.date("%Y-%m-%d %H:%M:%S"))
    addTo(LOG.summary, "")

    -- 1. Configs
    pcall(dumpConfigs)
    addTo(LOG.summary, "[1] Configs dumped → v38_configs.txt")

    -- 2. DataMgr snapshot
    pcall(dumpDataMgr)
    addTo(LOG.summary, "[2] DataMgr dumped → v38_datamgr.txt")

    -- 3. Network layer — server ka asli data yahan se aata hai
    addTo(LOG.summary, "[3] Hooking network handlers...")
    hookModule("client.network.Protocol.LuckAirDropHandler", LOG.packets, "NET.LuckAirDrop")
    hookModule("client.network.Protocol.SocialIslandHandler",  LOG.packets, "NET.SocialIsland")
    hookModule("client.network.Protocol.VehicleCollectHandler", LOG.packets, "NET.VehicleCollect")

    -- 4. System layer — drop subsystem
    addTo(LOG.summary, "[4] Hooking BornIslandAirDropSystem...")
    hookModule("GameLua.Mod.Library.GamePlay.Subsystem.BornIslandAirDropSystem",
        LOG.system, "SYS.AirDrop")

    -- 5. Lucky air drop client logic
    addTo(LOG.summary, "[5] Hooking lucky air drop logic...")
    hookModule("client.slua.logic.luck_airdrop.logic_luck_air_drop",
        LOG.lucky, "LUCKY.logic")
    hookModule("client.slua.logic.luck_airdrop.LuckyAirDropModule",
        LOG.lucky, "LUCKY.module")
    hookModule("client.slua.umg.LuckyAirDrop.ui_airdrop_mesh",
        LOG.lucky, "LUCKY.mesh")

    -- 6. Auto-flush every 5s
    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerLoop then
            ticker.AddTimerLoop(0, function()
                if ACTIVE then pcall(flush) end
            end, -1, 5.0)
        end
    end)

    addTo(LOG.summary, "")
    addTo(LOG.summary, "═══ READY — ab BornIsland match kholo ═══")
    addTo(LOG.summary, "Real drop aane pe sab capture hoga.")
    addTo(LOG.summary, "Aakhir me V38_Stop() chalao.")

    pcall(flush)
    P("v38 DUMPER",
        "Active.\n\n" ..
        "1. BornIsland match kholo\n" ..
        "2. Real drop aane tak wait\n" ..
        "3. Drop hone do\n" ..
        "4. V38_Stop() chalao\n\n" ..
        "Files:\n" ..
        "  v38_packets.txt\n" ..
        "  v38_system.txt\n" ..
        "  v38_lucky.txt\n" ..
        "  v38_configs.txt\n" ..
        "  v38_datamgr.txt\n" ..
        "  v38_summary.txt")
end

_G.V38_Stop = function()
    ACTIVE = false
    pcall(flush)
    local elapsed = os.time() - START_TIME
    S("v38_final.txt",
        "v38 FINAL\n" ..
        "Duration: " .. elapsed .. "s\n" ..
        "Packets lines: " .. #LOG.packets .. "\n" ..
        "System lines: "  .. #LOG.system .. "\n" ..
        "Lucky lines: "   .. #LOG.lucky .. "\n" ..
        "Summary lines: " .. #LOG.summary .. "\n")
    P("v38 STOP",
        "Saved.\n\n" ..
        "Packets: " .. #LOG.packets .. "\n" ..
        "System: " .. #LOG.system .. "\n" ..
        "Lucky: " .. #LOG.lucky .. "\n\n" ..
        "File bhejo: v38_packets.txt\n" ..
        "Aur: v38_system.txt\n" ..
        "Aur: v38_summary.txt")
end

_G.V38_Flush = function() flush(); P("v38", "Flushed") end

-- ═══════════════════════════════════════════════════════════════════
-- MANUAL PROBE — instant snapshot
-- ═══════════════════════════════════════════════════════════════════
_G.V38_Probe = function()
    local out = {}
    out[#out+1] = "═══ v38 PROBE ═══"
    out[#out+1] = "Time: " .. os.date("%H:%M:%S")

    local GS = package.loaded["GameLua.GameCore.Framework.GameStatus"] or _G.GameStatus
    if GS then
        out[#out+1] = "GameStatus.IsInFightingStatus = " .. tostring(
            GS.IsInFightingStatus and select(2, pcall(GS.IsInFightingStatus)))
        out[#out+1] = "GameStatus.IsSocialIslandMode = " .. tostring(
            GS.IsSocialIslandMode and select(2, pcall(GS.IsSocialIslandMode)))
        out[#out+1] = "GameStatus.GetGameStatus = " .. tostring(
            GS.GetGameStatus and select(2, pcall(GS.GetGameStatus)))
    end

    local paths = {
        "GameLua.Mod.Library.GamePlay.Subsystem.BornIslandAirDropSystem",
        "client.network.Protocol.LuckAirDropHandler",
        "client.slua.logic.luck_airdrop.logic_luck_air_drop",
        "client.slua.umg.LuckyAirDrop.ui_airdrop_mesh",
    }
    for _, p in ipairs(paths) do
        local M = package.loaded[p]
        out[#out+1] = (M and "LOADED: " or "MISSING: ") .. p
    end

    local txt = table.concat(out, "\n")
    S("v38_probe.txt", txt)
    P("v38 PROBE", txt)
    return txt
end

-- ═══════════════════════════════════════════════════════════════════
-- REPORT
-- ═══════════════════════════════════════════════════════════════════
S("v38_report.txt",
    "v38 DUMPER REPORT\n" ..
    "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n" ..
    "Purpose: capture REAL server drop data\n\n" ..
    "Commands:\n" ..
    "  V38_Start()   -- dumper ON, hooks lagao\n" ..
    "  V38_Probe()   -- instant state check\n" ..
    "  V38_Flush()   -- force save\n" ..
    "  V38_Stop()    -- end + final save\n\n" ..
    "Files:\n" ..
    "  v38_packets.txt  (network layer)\n" ..
    "  v38_system.txt   (BornIslandAirDropSystem)\n" ..
    "  v38_lucky.txt    (lucky air drop logic)\n" ..
    "  v38_configs.txt  (static configs)\n" ..
    "  v38_datamgr.txt  (vehicle tables)\n" ..
    "  v38_summary.txt  (human summary)\n")

print("[v38] Dumper loaded. Run V38_Start() then join BornIsland match.")
P("v38 READY",
    "Real Drop Dumper loaded.\n\n" ..
    "1. V38_Start()\n" ..
    "2. BornIsland match kholo\n" ..
    "3. Real drop hone do\n" ..
    "4. V38_Stop()\n\n" ..
    "Files: /Android/data/com.pubg.imobile/files/")

return true
