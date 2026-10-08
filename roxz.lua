-- ============================================================
-- ur_dumper.lua v1 — Ultimate Royale Security Check Dumper
-- Path: /storage/emulated/0/Android/data/com.pubg.imobile/files/
-- Purpose: dump Ultimate Royale preflight security flow so the
--   inspection gate can be neutralized at Lua layer.
-- Entry: watchdog waits for local char → boot → probe → live trace
-- ============================================================

_G._URD = _G._URD or { booted = false, phase = "unknown", t0 = os.time() }

-- ============================================================
-- [1] CONFIG
-- ============================================================
local CONFIG = {
    file_name          = "ur_dump.txt",
    write_test_key     = "config.ini",     -- existing file to test dir writability
    poll_interval      = 1.0,
    watchdog_interval  = 0.5,
    probe_on_boot      = true,
    probe_on_phase     = true,
    probe_fixed_delay  = 4.0,              -- sec after entering match
    dump_heartbeat     = true,
    dump_sec_flow      = true,
    dump_sec_deep      = true,
    dump_rank_flow     = true,
    dump_extattr       = true,
    flush_every        = 25,
    max_lines          = 300000,
    show_popups        = true,
    enable_probe_only  = true,             -- READ-ONLY, no patches
}

-- Same dump dir as reference #1
local DUMP_DIR = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"

-- Fallbacks in case that path is locked (Android 11+ scoped storage)
local POSSIBLE_DIRS = {
    DUMP_DIR,
    "/sdcard/Android/data/com.pubg.imobile/files/",
    "/storage/emulated/0/Android/data/com.pubg.krmobile/files/",
    "/sdcard/",
}

-- ============================================================
-- [2] POPUP (game's own message box)
-- ============================================================
local function POPUP(title, msg)
    if not CONFIG.show_popups then return end
    pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
                    or require("client.slua.logic.common.logic_common_msg_box")
        if Msg and Msg.Show then Msg.Show(4, tostring(title), tostring(msg)) end
    end)
end

-- ============================================================
-- [3] PATH + BUFFERED WRITER
-- ============================================================
local _PATH, _buf, _buf_n, _lines, _locked = nil, {}, 0, 0, false

local function _resolvePath()
    for _, d in ipairs(POSSIBLE_DIRS) do
        -- Prefer the dir that already has files (i.e. where the game writes)
        local f = io.open(d .. CONFIG.write_test_key, "r")
        if f then
            f:close()
            local w = io.open(d .. CONFIG.file_name, "a")
            if w then w:close(); return d .. CONFIG.file_name end
        end
    end
    -- Fallback: any writable dir
    for _, d in ipairs(POSSIBLE_DIRS) do
        local w = io.open(d .. CONFIG.file_name, "a")
        if w then w:close(); return d .. CONFIG.file_name end
    end
    return nil
end

local function _flush()
    if _buf_n == 0 or _locked or not _PATH then return end
    _locked = true
    local ok = pcall(function()
        local f = io.open(_PATH, "a")
        if f then
            local c = {}
            for i = 1, _buf_n do c[i] = _buf[i] end
            f:write(table.concat(c, "\n")); f:write("\n"); f:close()
            _lines = _lines + _buf_n
        end
    end)
    _buf, _buf_n, _locked = {}, 0, false
    return ok
end

local function _w(line)
    if not _PATH or _lines >= CONFIG.max_lines then return end
    _buf_n = _buf_n + 1
    _buf[_buf_n] = tostring(line)
    if _buf_n >= CONFIG.flush_every then _flush() end
end

local function _wsec(t)
    _w("")
    _w("═════════════════════════════════════════════════════════")
    _w("  " .. tostring(t))
    _w("═════════════════════════════════════════════════════════")
end

-- ============================================================
-- [4] UTILS
-- ============================================================
local function _typeName(v)
    local t = type(v)
    if t == "table" then
        local n = 0
        for _ in pairs(v) do n = n + 1; if n > 500 then break end end
        return "tbl:" .. n
    end
    if t == "userdata" then return "ud" end
    if t == "function" then return "fn" end
    return t
end

local function _arity(fn)
    if type(fn) ~= "function" or not debug or not debug.getinfo then return -1 end
    local ok, info = pcall(debug.getinfo, fn)
    if ok and info and info.nparams then return info.nparams end
    return -1
end

local function _getMod(path)
    local m = package.loaded[path]
    if m then return m, "cached" end
    local ok, r = pcall(require, path)
    if ok and r then return r, "required" end
    return nil, "missing"
end

local function _getClassImpl(p)
    local ok, cls = pcall(require, p)
    if ok and cls and type(cls) == "table" then
        if type(cls.__inner_impl) == "table" then return cls.__inner_impl end
        return cls
    end
    local ok2, cls2 = pcall(import, p)
    if ok2 and cls2 and type(cls2) == "table" then
        if type(cls2.__inner_impl) == "table" then return cls2.__inner_impl end
        return cls2
    end
    return nil
end

local function _getSubsystem(name)
    local ok, SM = pcall(require, "GameLua.GameCore.Module.Subsystem.SubsystemMgr")
    if not ok or not SM or not SM.Get then return nil end
    local ok2, s = pcall(function() return SM:Get(name) end)
    if ok2 and s then return s end
    return nil
end

local function _getModuleManager(name)
    local ok, MM = pcall(require, "client.module_framework.ModuleManager")
    if not ok or not MM then return nil end
    local ok2, m = pcall(function() return MM.GetModule(name) end)
    if ok2 and m then return m end
    return nil
end

-- Dump ALL method names of a table (functions + fields), up to limit
local function _dumpTableShape(owner, tag, limit)
    if not owner or type(owner) ~= "table" then
        _w("  [" .. tag .. "] not a table"); return 0
    end
    limit = limit or 200
    local fns, flds = {}, {}
    local n = 0
    for k, v in pairs(owner) do
        if type(k) == "string" and not k:find("^__") then
            n = n + 1
            if type(v) == "function" then fns[#fns+1] = k .. "(" .. _arity(v) .. ")"
            else flds[#flds+1] = k .. ":" .. _typeName(v) end
            if n >= limit then break end
        end
    end
    table.sort(fns); table.sort(flds)
    _w("  [" .. tag .. "] " .. #fns .. " fns, " .. #flds .. " fields")
    for _, s in ipairs(fns) do _w("      fn  " .. s) end
    for _, s in ipairs(flds) do _w("      fld " .. s) end
    return #fns + #flds
end

-- ============================================================
-- [5] STATE HELPERS
-- ============================================================
local function _getPC()
    local ok, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if ok and GD and GD.GetPlayerController then
        local pc = GD.GetPlayerController()
        if pc and slua.isValid(pc) then return pc end
    end
    return nil
end

local function _getChar()
    local ok, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if ok and GD and GD.GetPlayerCharacter then
        local c = GD.GetPlayerCharacter()
        if c and slua.isValid(c) then return c end
    end
    local pc = _getPC()
    if pc then
        local ok2, c = pcall(function() return pc:GetPlayerCharacterSafety() end)
        if ok2 and c and slua.isValid(c) then return c end
    end
    return nil
end

local function _getPS()
    local ok, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if ok and GD and GD.GetPlayerState then
        local ps = GD.GetPlayerState()
        if ps and slua.isValid(ps) then return ps end
    end
    local pc = _getPC()
    if pc and pc.PlayerState and slua.isValid(pc.PlayerState) then return pc.PlayerState end
    return nil
end

local function _getGS()
    local ok, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if ok and GD and GD.GetGameState then
        local gs = GD.GetGameState()
        if gs and slua.isValid(gs) then return gs end
    end
    return nil
end

local function _getPhase()
    local ok, s = pcall(function()
        if GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity() then return "lobby" end
        if GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus() then return "match" end
        return "unknown"
    end)
    return ok and s or "unknown"
end

-- Detect if we are inside Ultimate Royale (or its preflight) — heuristic
local function _isUltimateRoyale()
    local hits = 0
    pcall(function()
        local GD = require("GameLua.GameCore.Data.GameplayData")
        if GD and GD.GetGameMode then
            local gm = GD.GetGameMode()
            if gm and (tostring(gm):lower():find("ultra") or tostring(gm):lower():find("royale")) then
                hits = hits + 1
            end
        end
    end)
    pcall(function()
        local MM = require("client.module_framework.ModuleManager")
        if MM and MM.GetModule then
            local m = MM.GetModule("UltimateRoyaleModule")
            if m then hits = hits + 1 end
        end
    end)
    return hits > 0
end

-- ============================================================
-- [6] ULTIMATE ROYALE — TARGET REGISTRY
-- ============================================================
-- Every module that might touch the UR flow. Probed on boot
-- and re-probed on phase change. Missing ones get flagged so
-- we know what to patch next.
--
local UR_TARGETS = {
    -- ── Security inspection / anti-cheat (the actual gate) ──
    { kind="subsystem", path="FileCheckSubsystem",                     funcs={"StartCheck","ReportAbnormalFile","TickCheck","OnCheckResult"} },
    { kind="subsystem", path="ClientDataStatistcsSubsystem",           funcs={"StartToCheck","StopCheck","Report"} },
    { kind="subsystem", path="ShootVerifySubSystemClient",             funcs={"ReportVerifyFail","OnVerifyFailed","StartVerify","VerifyShoot"} },
    { kind="subsystem", path="AvatarExceptionSubsystem",               funcs={"ReportException","BindPlayerCharacter","CheckAvatarValid","CheckSlotMeshVisible"} },
    { kind="subsystem", path="RescueBtnReplayTraceSubsystem",          funcs={"ReportTrace","StartTickMonitor","TickMonitorCheck","ReportTickMonitorHeartbeat"} },
    { kind="subsystem", path="GameReportSubsystem",                    funcs={"ReplayReportData","CheckCanBugglyPostException","BugglyPostExceptionFull","GetClientReplayDataReporter"} },
    { kind="subsystem", path="AFKReportorSubsystem",                   funcs={"PlayerHaveAction","ReportAFK"} },

    -- ── Security modules under BaseMod.Common.Security ──
    { kind="module", path="GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent",         funcs={"StaticShowSecurityAlertInDev"}, fields={"BlackList"} },
    { kind="module", path="GameLua.Mod.BaseMod.Common.Security.ReportPlayerUtils",           funcs={"RecordFatalDamager","IsUsingHistoricalTeammateInfo","IsCharacterDeliverAI"} },
    { kind="module", path="GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils",         funcs={"ExtractPlayerBasicInfo","LogIf"} },
    { kind="module", path="GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem", funcs={"OnInit","_OnPlayerKilledOtherPlayer","_RecordFatalDamager","_OnDeathReplayDataWhenFatalDamaged","_RecordMurdererFromDeathReplayData","_RecordTeammatePlayerInfo","_OnBattleResult"} },
    { kind="module", path="GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem",         funcs={"OnInit","_OnNearDeathOrRescued","_OnCharacterDied","_OnTeammateDamage","_OnPlayerSettlementStart"} },
    { kind="module", path="GameLua.Mod.BaseMod.Client.Security.ClientQuickReportMaliciousTeammate", funcs={"OnShowMutualExclusiveUI","OnHideMutualExclusiveUI"} },

    -- ── UR / Ranked / Rating system ──
    { kind="module", path="client.slua.logic.rank.logic_rank",                     funcs={} },
    { kind="module", path="client.slua.logic.rank.logic_rank_data",                funcs={} },
    { kind="module", path="client.slua.logic.rank.logic_ranked_match",             funcs={} },
    { kind="module", path="client.slua.logic.ultimate_royale.logic_ur_entry",      funcs={} },
    { kind="module", path="client.slua.logic.ultimate_royale.logic_ur_security",   funcs={} },
    { kind="module", path="client.slua.logic.ultimate_royale.logic_ur_match",      funcs={} },
    { kind="moduleManager", path="UltimateRoyaleModule",                            funcs={} },
    { kind="moduleManager", path="UltimateRoyaleSecurityMgr",                       funcs={} },
    { kind="moduleManager", path="RankMgr",                                         funcs={} },

    -- ── Anti-debug / root / device ──
    { kind="module", path="GameLua.Mod.BaseMod.Client.AntiCheat.AntiCheatClient",   funcs={} },
    { kind="module", path="GameLua.Mod.BaseMod.Common.Security.DeviceFingerprint",  funcs={} },
    { kind="module", path="GameLua.Mod.BaseMod.Common.Security.IntegrityCheck",     funcs={} },

    -- ── TLog / report ──
    { kind="module", path="client.slua.config.tlog.tlog_report_utils",              funcs={"ReportTLogEvent"} },
    { kind="module", path="GameLua.Mod.BaseMod.Client.ClientTLog.ClientTLogUtil",   funcs={"ReportGeneralCountByBRPhase","ReportCommonTLogDataByBRPhase"} },
    { kind="module", path="client.slua.logic.report.ClientToolsReport",             funcs={"SendReport","SendException"} },
    { kind="module", path="client.slua.logic.replay.logic_report_replay",           funcs={"ReportReplay","SendReportReq"} },

    -- ── Match entry / lobby flow that triggers inspection ──
    { kind="module", path="client.logic.lobby.logic_lobby_start_match",             funcs={} },
    { kind="module", path="client.slua.logic.lobby.Main.Lobby_Main_Control",        funcs={"GetCurPage"} },
    { kind="module", path="client.network.Protocol.MatchHandler",                   funcs={} },
    { kind="module", path="client.network.Protocol.RankHandler",                    funcs={} },

    -- ── Extension attrs (UR rating, tier) ──
    { kind="module", path="Server.config.ExtendAttribute", fields={
        "EliminationKingEffect","NameTag","YMTag","NameColor","KillMessageEffect",
        "FrameEffect","AvatarFrame","ProfileFrame","URRating","URTier","URSeasonID",
    }},

    -- ── Enums we want to see ──
    { kind="global", path="ENUM_ULTIMATE_ROYALE_TIER",  fields={} },
    { kind="global", path="ENUM_UR_SECURITY_RESULT",    fields={} },
    { kind="global", path="ENUM_MATCH_MODE",            fields={} },
}

-- Free-form scan: any loaded module whose path matches these substrings
local SCAN_HINTS = {
    "ultimate", "ultra_royale", "royale", "rank", "ur_",
    "security", "anticheat", "anti_cheat", "integrity",
    "device", "fingerprint", "attest", "higs", "root",
    "verify", "report", "inspect", "check",
}

-- ============================================================
-- [7] PROBE ENGINE
-- ============================================================
local _probed = {}
local _counts = { modules=0, loaded=0, missing=0, fns_ok=0, fns_miss=0, fns_chg=0 }

local function _probeFuncs(owner, list, tag)
    if not list then return end
    for _, fn in ipairs(list) do
        local v = owner[fn]
        if v == nil then
            _w(string.format("    %-46s [✗ MISSING]", fn))
            _counts.fns_miss = _counts.fns_miss + 1
        elseif type(v) ~= "function" then
            _w(string.format("    %-46s [~ %s]", fn, type(v)))
            _counts.fns_chg = _counts.fns_chg + 1
        else
            _w(string.format("    %-46s [✓ arity=%s]", fn, tostring(_arity(v))))
            _counts.fns_ok = _counts.fns_ok + 1
        end
    end
end

local function _probeFields(owner, list)
    if not list then return end
    for _, f in ipairs(list) do
        local v = owner[f]
        if v == nil then _w(string.format("    %-46s [✗ field missing]", f))
        else _w(string.format("    %-46s [✓ %s]", f, _typeName(v))) end
    end
end

local function _probeOne(item, deep)
    if _probed[item.path] and not deep then return end
    _probed[item.path] = true
    _counts.modules = _counts.modules + 1
    _w("")

    if item.kind == "subsystem" then
        local s = _getSubsystem(item.path)
        if not s then
            _w("[SUBSYS] "..item.path.."  [✗ NOT FOUND]")
            _counts.missing = _counts.missing + 1
            return
        end
        _w("[SUBSYS] "..item.path.."  [✓ FOUND]")
        _counts.loaded = _counts.loaded + 1
        _probeFuncs(s, item.funcs)
        if deep then _dumpTableShape(s, item.path, 120) end
        return
    end

    if item.kind == "class" then
        local impl = _getClassImpl(item.path)
        if not impl then
            _w("[CLASS] "..item.path.."  [✗ NOT LOADED]")
            _counts.missing = _counts.missing + 1
            return
        end
        _w("[CLASS] "..item.path.."  [✓ LOADED]")
        _counts.loaded = _counts.loaded + 1
        if item.impl then _probeFuncs(impl, item.impl) end
        if deep then _dumpTableShape(impl, item.path, 120) end
        return
    end

    if item.kind == "moduleManager" then
        local m = _getModuleManager(item.path)
        if not m then
            _w("[MODMGR] "..item.path.."  [✗ NOT FOUND]")
            _counts.missing = _counts.missing + 1
            return
        end
        _w("[MODMGR] "..item.path.."  [✓ FOUND]")
        _counts.loaded = _counts.loaded + 1
        if item.funcs then _probeFuncs(m, item.funcs) end
        if deep then _dumpTableShape(m, item.path, 150) end
        return
    end

    if item.kind == "global" then
        local g = _G[item.path]
        if not g then
            _w("[GLOBAL] "..item.path.."  [✗ NOT FOUND]")
            _counts.missing = _counts.missing + 1
            return
        end
        _w("[GLOBAL] "..item.path.."  [✓ FOUND]")
        _counts.loaded = _counts.loaded + 1
        if item.fields and #item.fields > 0 then _probeFields(g, item.fields) end
        if type(g) == "table" then _dumpTableShape(g, item.path, 80) end
        return
    end

    -- module
    local m, how = _getMod(item.path)
    if not m then
        _w("[MOD] "..item.path.."  [✗ NOT LOADED]")
        _counts.missing = _counts.missing + 1
        return
    end
    _w("[MOD] "..item.path.."  [✓ "..how.."]")
    _counts.loaded = _counts.loaded + 1
    if item.funcs and #item.funcs > 0 then _probeFuncs(m, item.funcs) end
    if item.fields and #item.fields > 0 then _probeFields(m, item.fields) end
    if deep then _dumpTableShape(m, item.path, 150) end
end

local function _runBaselineProbe(deep)
    _wsec("BASELINE PROBE — "..os.date("%Y-%m-%d %H:%M:%S"))
    for _, item in ipairs(UR_TARGETS) do _probeOne(item, deep and CONFIG.dump_sec_deep) end
    _wsec("PROBE SUMMARY")
    _w(string.format("  Modules probed     : %d", _counts.modules))
    _w(string.format("  Loaded             : %d", _counts.loaded))
    _w(string.format("  Missing            : %d", _counts.missing))
    _w(string.format("  Functions OK       : %d", _counts.fns_ok))
    _w(string.format("  Functions missing  : %d", _counts.fns_miss))
    _w(string.format("  Functions changed  : %d", _counts.fns_chg))
    _flush()
    return _counts
end

-- Free-form package.loaded scan for anything matching SCAN_HINTS
local function _scanLoadedModules()
    _wsec("LOADED-MODULE SCAN (hint-based)")
    local hits = 0
    local known = {}
    for _, item in ipairs(UR_TARGETS) do known[item.path] = true end
    pcall(function()
        for path, mod in pairs(package.loaded) do
            if type(path) == "string" and not known[path] and type(mod) == "table" then
                local low = string.lower(path)
                for _, hint in ipairs(SCAN_HINTS) do
                    if low:find(hint, 1, true) then
                        _w("  [+] "..path)
                        hits = hits + 1
                        break
                    end
                end
                if hits > 200 then _w("  ... truncated at 200"); break end
            end
        end
    end)
    if hits == 0 then _w("  (no hint-matched modules loaded yet)") end
    _flush()
end

-- ============================================================
-- [8] DEEP SECURITY-FLOW HOOKS (read-only observation)
-- ============================================================
local _hooked = {}

local function _hookFunc(owner, name, tag, onCall)
    if not owner or type(owner[name]) ~= "function" then return false end
    if _hooked[tag] then return true end
    _hooked[tag] = true
    local orig = owner[name]
    owner[name] = function(self, ...)
        pcall(onCall, self, ...)
        return orig(self, ...)
    end
    _w("[HOOK] "..tag.." installed on "..name)
    return true
end

local function _installURHooks()
    if not CONFIG.dump_sec_flow then return end
    _wsec("ULTIMATE ROYALE SECURITY HOOKS")

    -- FileCheckSubsystem — the strongest signal
    local fc = _getSubsystem("FileCheckSubsystem")
    if fc then
        _hookFunc(fc, "StartCheck", "_ur_fc_start", function()
            _w("[SEC-CHECK] FileCheckSubsystem:StartCheck @ "..os.date("%H:%M:%S").."  phase=".._getPhase())
        end)
        _hookFunc(fc, "ReportAbnormalFile", "_ur_fc_report", function(self, path)
            _w("[SEC-CHECK] ReportAbnormalFile path="..tostring(path))
        end)
    end

    -- ClientDataStatistcsSubsystem
    local ds = _getSubsystem("ClientDataStatistcsSubsystem")
    if ds then
        _hookFunc(ds, "StartToCheck", "_ur_ds_start", function()
            _w("[SEC-CHECK] ClientDataStatistcsSubsystem:StartToCheck @ "..os.date("%H:%M:%S"))
        end)
    end

    -- ShootVerifySubSystemClient
    local sv = _getSubsystem("ShootVerifySubSystemClient")
    if sv then
        _hookFunc(sv, "StartVerify", "_ur_sv_start", function()
            _w("[SEC-CHECK] ShootVerify:StartVerify")
        end)
        _hookFunc(sv, "ReportVerifyFail", "_ur_sv_fail", function(self, a, b, c)
            _w("[SEC-CHECK] ShootVerify:ReportVerifyFail a="..tostring(a).." b="..tostring(b).." c="..tostring(c))
        end)
    end

    -- AvatarExceptionSubsystem
    local ae = _getSubsystem("AvatarExceptionSubsystem")
    if ae then
        _hookFunc(ae, "ReportException", "_ur_ae_report", function(self, code, info)
            _w("[SEC-CHECK] AvatarException:ReportException code="..tostring(code).." info="..tostring(info))
        end)
    end

    -- HiggsBosonComponent
    local hb = _getMod("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
    if hb then
        _hookFunc(hb, "StaticShowSecurityAlertInDev", "_ur_hb_alert", function(self, msg)
            _w("[SEC-CHECK] HiggsBoson:SecurityAlert msg="..tostring(msg))
        end)
    end

    -- Rank handler (UR uses rank flow)
    local rh, _ = _getMod("client.network.Protocol.RankHandler")
    if rh then
        _dumpTableShape(rh, "RankHandler", 80)
    end

    -- Match handler — catch the entry request
    local mh, _ = _getMod("client.network.Protocol.MatchHandler")
    if mh then
        _dumpTableShape(mh, "MatchHandler", 120)
        -- Hook common send methods heuristically
        for name, v in pairs(mh) do
            if type(v) == "function" and type(name) == "string"
               and (name:find("send") or name:find("req") or name:find("enter")) then
                _hookFunc(mh, name, "_ur_mh_"..name, function(_, ...)
                    local n = select("#", ...)
                    _w("[MATCH-NET] "..name.." argc="..n.." @ "..os.date("%H:%M:%S"))
                end)
            end
        end
    end

    _flush()
end

-- ============================================================
-- [9] EXT ATTR DUMP
-- ============================================================
local function _dumpExtAttr()
    if not CONFIG.dump_extattr then return end
    local m = _getMod("Server.config.ExtendAttribute")
    if not m or type(m) ~= "table" then
        _w("[EXTATTR] module not loaded")
        return
    end
    _wsec("EXTEND ATTRIBUTE DUMP")
    local ks = {}
    for k in pairs(m) do ks[#ks+1] = tostring(k) end
    table.sort(ks)
    for _, k in ipairs(ks) do _w(string.format("  ExtendAttribute.%s = %s", k, tostring(m[k]))) end
    _flush()
end

-- ============================================================
-- [10] PLAYER STATE SNAPSHOT
-- ============================================================
local _RP = {"RP","RankPoint","RankScore","SeasonRP","TotalRP","RankPoints","URRating","URPoints","Tier","TierID"}
local _NT = {"NameTagID","NameTag","YMTagID","YMTag","NameColor","KillMessageEffect"}

local function _snapPS(tag)
    local ps = _getPS()
    if not ps then _w("["..tag.."] PS nil"); return end
    local out = { "["..tag.."]" }
    pcall(function()
        if ps.UID then out[#out+1] = "uid="..tostring(ps.UID) end
        if ps.PlayerKey then out[#out+1] = "pkey="..tostring(ps.PlayerKey) end
        if ps.PlayerName then out[#out+1] = "name="..tostring(ps.PlayerName) end
        if ps.KillCount then out[#out+1] = "kills="..tostring(ps.KillCount) end
    end)
    for _, k in ipairs(_RP) do
        local ok, v = pcall(function() return ps[k] end)
        if ok and v ~= nil then out[#out+1] = k.."="..tostring(v) end
    end
    for _, k in ipairs(_NT) do
        local ok, v = pcall(function() return ps[k] end)
        if ok and v ~= nil then out[#out+1] = k.."="..tostring(v) end
    end
    _w(table.concat(out, " "))
end

-- ============================================================
-- [11] TIMERS
-- ============================================================
local function _heartbeat()
    if not CONFIG.dump_heartbeat then return end
    if not _getPC() then return end
    local ch = _getChar()
    local out = { "[HB]", os.date("%H:%M:%S"), "phase=".._getPhase() }
    if ch then
        pcall(function()
            local l = ch:K2_GetActorLocation()
            if l then out[#out+1] = string.format("pos=(%.0f,%.0f,%.0f)", l.X or 0, l.Y or 0, l.Z or 0) end
        end)
        pcall(function()
            local hp = ch:GetHealth()
            if hp then out[#out+1] = string.format("hp=%.0f", hp) end
        end)
    end
    _w(table.concat(out, " "))
    _flush()
end

local function _phaseWatch()
    local p = _getPhase()
    if p ~= _G._URD.phase then
        _w(""); _w("[PHASE] "..tostring(_G._URD.phase).." → "..tostring(p).." @ "..os.date("%H:%M:%S"))
        _G._URD.phase = p
        if CONFIG.probe_on_phase then
            _probed = {}
            _runBaselineProbe(false)
            _scanLoadedModules()
            _installURHooks()
        end
        pcall(_dumpExtAttr)
        pcall(_snapPS, "PHASE_PS")
    end
    -- Re-scan every ~15s for late-loaded modules
    local t = os.time()
    if not _G._URD._lastScan or t - _G._URD._lastScan > 15 then
        _G._URD._lastScan = t
        if CONFIG.probe_on_phase then _scanLoadedModules() end
    end
end

local function _startTimers()
    local ticker = nil
    pcall(function() ticker = require("common.time_ticker") end)
    if ticker and ticker.AddTimerLoop then
        ticker.AddTimerLoop(0, _heartbeat,  -1, CONFIG.poll_interval)
        ticker.AddTimerLoop(0, _phaseWatch, -1, 1.5)
        _w("[TIMER] time_ticker loops started")
    else
        _w("[TIMER] no time_ticker — watchdog only")
    end
end

-- ============================================================
-- [12] BOOT
-- ============================================================
local function _boot()
    if _G._URD.booted then return end
    _G._URD.booted = true

    _PATH = _resolvePath()
    if not _PATH then
        POPUP("UR-DUMPER FAIL", "No writable path found.")
        print("[URD] no writable path — abort")
        return
    end

    POPUP("UR-DUMPER STARTED",
        "Ultimate Royale security-flow probe running.\n\nPath:\n".._PATH..
        "\n\nEnter UR match → dump grows.")

    _w("═════════════════════════════════════════════════════════")
    _w("  ULTIMATE ROYALE SECURITY DUMPER v1")
    _w("  Session  : "..os.date("%Y-%m-%d %H:%M:%S"))
    _w("  Path     : ".._PATH)
    _w("  UR mode  : "..tostring(_isUltimateRoyale()))
    _w("═════════════════════════════════════════════════════════")
    _flush()

    pcall(_runBaselineProbe, CONFIG.dump_sec_deep)
    pcall(_scanLoadedModules)
    pcall(_dumpExtAttr)
    pcall(_installURHooks)
    pcall(_startTimers)
    pcall(_snapPS, "BOOT_PS")

    _w("[BOOT] dumper initialized @ "..os.date("%H:%M:%S"))
    _flush()

    POPUP("UR-DUMPER READY",
        string.format("Loaded: %d / Missing: %d\nFn OK: %d  Missing: %d\n\nEnter UR match now.",
            _counts.loaded, _counts.missing, _counts.fns_ok, _counts.fns_miss))
    print("[URD] boot complete → ".._PATH)
end

local function _watchdog()
    if _G._URD.booted then return end
    if _getChar() then _boot() end
end

-- ============================================================
-- [13] MANUAL API
-- ============================================================
_G.URDumpNow      = function() _probed = {}; pcall(_runBaselineProbe, true) end
_G.URDumpStatus   = function()
    _w("[MANUAL] status @ "..os.date("%H:%M:%S").." phase=".._getPhase().." booted="..tostring(_G._URD.booted).." lines="..tostring(_lines))
    _flush()
end
_G.URScanModules  = function() pcall(_scanLoadedModules) end
_G.URDumpExtAttr  = function() pcall(_dumpExtAttr) end
_G.URHookFlow     = function() pcall(_installURHooks) end
_G.URSelfTest = function()
    _wsec("SELF TEST @ "..os.date("%H:%M:%S"))
    _w("  _PATH  = "..tostring(_PATH))
    _w("  booted = "..tostring(_G._URD.booted))
    _w("  lines  = "..tostring(_lines))
    _w("  phase  = ".._getPhase())
    _w("  UR?    = "..tostring(_isUltimateRoyale()))
    _w("  pc     = "..tostring(_getPC() ~= nil))
    _w("  char   = "..tostring(_getChar() ~= nil))
    _w("  ps     = "..tostring(_getPS() ~= nil))
    _flush()
end
_G.URExport = function()
    _flush()
    POPUP("UR-DUMPER EXPORTED", "Flushed.\n\n"..tostring(_PATH))
    print("[URD] exported → "..tostring(_PATH))
end

-- ============================================================
-- [14] WATCHDOG ARM
-- ============================================================
do
    local ok, ticker = pcall(require, "common.time_ticker")
    if ok and ticker and ticker.AddTimerLoop then
        ticker.AddTimerLoop(0, _watchdog, -1, CONFIG.watchdog_interval)
        print("[URD] watchdog armed (0.5s)")
    else
        pcall(_watchdog)
    end
end

print("[ur_dumper.lua v1] loaded — waiting for character spawn…")
