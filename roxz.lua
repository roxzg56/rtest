-- ═══════════════════════════════════════════════════════════════════
-- v40 — FULLY AUTONOMOUS BORNISLAND VEHICLE SPAWN
-- Koi command nahi. Load hote hi sab kuch auto chalega.
-- BornIsland phase detect → force dump → spawn fire → save files
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

local function appendLine(file, line)
    local f = io.open(DIR .. file, "a")
    if not f then return false end
    f:write(line .. "\n"); f:close()
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════════════════════════
local CFG = {
    vehicleID  = 902,
    skinResID  = 1961014,
    insID      = 7247538342442672640,
    dropHeight = 100,
    offsetX    = 5,
    offsetY    = 5,
    autoDelay  = 8.0,       -- script load ke baad itne sec wait
    loopEvery  = 4.0,       -- har 4 sec check phase
    fireOnce   = true,      -- ek baar fire karega
}

-- Session log
local LOG_LINES = {}
local function LOG(s)
    local line = "[" .. os.date("%H:%M:%S") .. "] " .. tostring(s)
    LOG_LINES[#LOG_LINES+1] = line
    appendLine("v40_session.txt", line)
end

LOG("═══ v40 SESSION START ═══")
LOG("Vehicle: " .. CFG.vehicleID .. " | Skin: " .. CFG.skinResID .. " | InsID: " .. CFG.insID)

-- ═══════════════════════════════════════════════════════════════════
-- FORCE LOADER
-- ═══════════════════════════════════════════════════════════════════
local function forceLoad(path)
    local M = package.loaded[path]
    if M and type(M) == "table" then return M end
    local ok, mod = pcall(require, path)
    if ok and type(mod) == "table" then return mod end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════
-- DEEP SERIALIZER
-- ═══════════════════════════════════════════════════════════════════
local function ser(v, d, seen)
    d = d or 0; seen = seen or {}
    if d > 4 then return "..." end
    local t = type(v)
    if t == "nil" or t == "boolean" or t == "number" then return tostring(v) end
    if t == "string" then
        if #v > 80 then return string.format("%q...", v:sub(1, 77)) end
        return string.format("%q", v)
    end
    if t == "function" then return "<fn>" end
    if t == "userdata" then return "<ud>" end
    if t == "table" then
        if seen[v] then return "<cycle>" end
        seen[v] = true
        local p = {}; local n = 0
        for i = 1, math.min(#v, 15) do
            p[#p+1] = ser(v[i], d+1, seen); n = n + 1
        end
        for k, val in pairs(v) do
            if n >= 30 then p[#p+1] = "..." break end
            if type(k) ~= "number" or k > #v then
                p[#p+1] = tostring(k) .. "=" .. ser(val, d+1, seen); n = n + 1
            end
        end
        return "{" .. table.concat(p, ", ") .. "}"
    end
    return "<" .. t .. ">"
end

-- ═══════════════════════════════════════════════════════════════════
-- GAME STATUS CHECK
-- ═══════════════════════════════════════════════════════════════════
local function getPhase()
    local info = { fighting = false, social = false, status = "unknown" }
    local GS = _G.GameStatus or forceLoad("GameLua.GameCore.Framework.GameStatus")
    if GS then
        pcall(function()
            if GS.IsInFightingStatus then
                info.fighting = GS.IsInFightingStatus() or false
            end
            if GS.IsSocialIslandMode then
                info.social = GS.IsSocialIslandMode() or false
            end
            if GS.GetGameStatus then
                local s = GS.GetGameStatus()
                info.status = tostring(s)
            end
        end)
    end
    return info
end

-- ═══════════════════════════════════════════════════════════════════
-- PLAYER POSITION
-- ═══════════════════════════════════════════════════════════════════
local function getPlayerPos()
    local pos = { X = 0, Y = 0, Z = CFG.dropHeight }
    pcall(function()
        local GD = forceLoad("GameLua.GameCore.Data.GameplayData")
        if GD and GD.GetPlayerCharacter then
            local ch = GD.GetPlayerCharacter()
            if ch and slua and slua.isValid and slua.isValid(ch) then
                if ch.K2_GetActorLocation then
                    local loc = ch:K2_GetActorLocation()
                    if loc then
                        pos.X = loc.X + CFG.offsetX
                        pos.Y = loc.Y + CFG.offsetY
                        pos.Z = loc.Z + CFG.dropHeight
                    end
                end
            end
        end
    end)
    return pos
end

-- ═══════════════════════════════════════════════════════════════════
-- SUBSYSTEM FINDER
-- ═══════════════════════════════════════════════════════════════════
local function findInstance(names)
    local inst = nil
    pcall(function()
        local SM = forceLoad("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SM then
            if type(SM.Get) == "function" then
                for _, n in ipairs(names) do
                    local r = SM.Get(n)
                    if r then inst = r; return end
                end
            end
            if type(SM.GetSubsystem) == "function" then
                for _, n in ipairs(names) do
                    local r = SM.GetSubsystem(n)
                    if r then inst = r; return end
                end
            end
        end
        local SSM = forceLoad("GameLua.GameCore.Framework.SubsystemMgr")
        if SSM and type(SSM.Get) == "function" then
            for _, n in ipairs(names) do
                local r = SSM.Get(n)
                if r then inst = r; return end
            end
        end
    end)
    return inst
end

-- ═══════════════════════════════════════════════════════════════════
-- AUTO DUMP — jab bhi phase BornIsland ho, structure dump kare
-- ═══════════════════════════════════════════════════════════════════
local DUMP_DONE = false
local function autoDump()
    if DUMP_DONE then return end
    DUMP_DONE = true

    LOG("── AUTO DUMP START ──")
    local out = {}
    out[#out+1] = "═══ v40 AUTO DUMP ═══"
    out[#out+1] = "Time: " .. os.date("%Y-%m-%d %H:%M:%S")

    local phase = getPhase()
    out[#out+1] = string.format("Phase: fighting=%s social=%s status=%s",
        tostring(phase.fighting), tostring(phase.social), tostring(phase.status))
    out[#out+1] = ""

    local paths = {
        "GameLua.Mod.BaseMod.Client.BornIslandTeamShow.BornIslandTeamShowSubSystem",
        "client.lobby_ue_object.Actor.LobbyVehicle",
        "client.lobby_ue_object.Actor.LobbyPawn",
        "client.logic.lobby.ThemeVehicleManager",
        "client.logic.vehicle.VehicleCollectSystem",
        "GameLua.Mod.Library.GamePlay.Subsystem.BornIslandAirDropSystem",
        "client.logic.data.DataMgr",
        "GameLua.GameCore.Module.Subsystem.SubsystemMgr",
        "GameLua.GameCore.Module.Vehicle.ALuaVehicleBase",
        "client.network.Protocol.LuckAirDropHandler",
        "client.slua.logic.luck_airdrop.logic_luck_air_drop",
        "client.slua.umg.LuckyAirDrop.ui_airdrop_mesh",
        "GameLua.Mod.BaseMod.Client.Tips.BirthIslandTips",
    }

    for _, path in ipairs(paths) do
        out[#out+1] = "── " .. path .. " ──"
        local M = forceLoad(path)
        if M then
            out[#out+1] = "  STATUS: LOADED"
            local impl = M.__inner_impl or M
            local funcs, tables = {}, {}
            for k, v in pairs(impl) do
                if type(v) == "function" then funcs[#funcs+1] = k
                elseif type(v) == "table" then tables[#tables+1] = k end
            end
            out[#out+1] = "  FUNCTIONS (" .. #funcs .. "):"
            for i = 1, math.min(#funcs, 100) do
                out[#out+1] = "    " .. funcs[i]
            end
            if #tables > 0 then
                out[#out+1] = "  TABLES: " .. table.concat(tables, ", ")
            end
        else
            out[#out+1] = "  STATUS: NOT LOADED"
        end
        out[#out+1] = ""
    end

    -- SubsystemMgr all
    out[#out+1] = "── SubsystemMgr instance scan ──"
    local SM = forceLoad("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
    if SM then
        for k, v in pairs(SM) do
            if type(v) == "function" then out[#out+1] = "  fn " .. k end
        end
        for k, v in pairs(SM) do
            if type(v) == "table" then
                out[#out+1] = "  table " .. tostring(k) .. " keys=" .. tostring(#v)
            end
        end
    end

    -- DataMgr snapshot
    out[#out+1] = ""
    out[#out+1] = "── DataMgr.VehicleSlotList[902] ──"
    local DM = forceLoad("client.logic.data.DataMgr")
    if DM then
        if DM.VehicleSlotList then
            for k, v in pairs(DM.VehicleSlotList) do
                out[#out+1] = "  [" .. tostring(k) .. "] = " .. ser(v, 0, {})
            end
        end
        if DM.vehicleSkinInsIDTable then
            out[#out+1] = "── vehicleSkinInsIDTable[902] ──"
            out[#out+1] = "  " .. ser(DM.vehicleSkinInsIDTable[902], 0, {})
        end
        if DM.defaultVehicleSkinResIDTable then
            out[#out+1] = "── defaultVehicleSkinResIDTable[902] ──"
            out[#out+1] = "  " .. ser(DM.defaultVehicleSkinResIDTable[902], 0, {})
        end
    end

    S("v40_dump.txt", table.concat(out, "\n"))
    LOG("AUTO DUMP saved: v40_dump.txt lines=" .. #out)
end

-- ═══════════════════════════════════════════════════════════════════
-- SPAWN PATHS
-- ═══════════════════════════════════════════════════════════════════
local function tryPathTeamShow()
    local rlog = {}
    local function R(s) rlog[#rlog+1] = s; LOG("  [TeamShow] " .. s) end

    local M = forceLoad("GameLua.Mod.BaseMod.Client.BornIslandTeamShow.BornIslandTeamShowSubSystem")
    if not M then R("module NOT loaded"); return rlog end
    R("module loaded")

    local impl = M.__inner_impl or M
    local inst = findInstance({"BornIslandTeamShowSubSystem", "BornIslandTeamShow"})
    if inst then R("live instance found")
    else inst = impl; R("using impl as instance") end

    local pos = getPlayerPos()
    local fakeData = {
        vehicleID = CFG.vehicleID, VehicleID = CFG.vehicleID,
        skinResID = CFG.skinResID, SkinResID = CFG.skinResID,
        insID = CFG.insID, InsID = CFG.insID,
        itemID = CFG.skinResID, ItemID = CFG.skinResID,
        posX = pos.X, posY = pos.Y, posZ = pos.Z,
        X = pos.X, Y = pos.Y, Z = pos.Z,
        SlotID = 1, PlayerID = 0, bIsSelf = true,
    }

    pcall(function()
        if type(inst.InitConfig) == "function" then
            inst:InitConfig(); R("InitConfig OK")
        end
    end)

    if type(inst.CreateDataForShow) == "function" then
        local ok, err = pcall(inst.CreateDataForShow, inst, fakeData)
        R("CreateDataForShow = " .. (ok and "OK" or ("ERR: " .. tostring(err):sub(1,100))))
    end

    if type(inst.CreateCarObject) == "function" then
        local ok, err = pcall(inst.CreateCarObject, inst, fakeData)
        R("CreateCarObject = " .. (ok and "OK" or ("ERR: " .. tostring(err):sub(1,150))))
    end

    if type(inst.BeginShow) == "function" then
        local ok, err = pcall(inst.BeginShow, inst)
        R("BeginShow = " .. (ok and "OK" or ("ERR: " .. tostring(err):sub(1,100))))
    end
    if type(inst.ReadyToShow) == "function" then
        local ok = pcall(inst.ReadyToShow, inst)
        R("ReadyToShow = " .. (ok and "OK" or "ERR"))
    end
    return rlog
end

local function tryPathThemeVehicle()
    local rlog = {}
    local function R(s) rlog[#rlog+1] = s; LOG("  [ThemeVM] " .. s) end

    local M = forceLoad("client.logic.lobby.ThemeVehicleManager")
    if not M then R("not loaded"); return rlog end
    R("loaded")

    M.RepeatTags = M.RepeatTags or {}
    M.Vehicles = M.Vehicles or {}
    M.SkinCache = M.SkinCache or {}
    M.ModelActorCache = M.ModelActorCache or {}
    R("tables initialized")

    local DM = forceLoad("client.logic.data.DataMgr")
    if DM then
        DM.VehicleSlotList = DM.VehicleSlotList or {}
        DM.VehicleSlotList[CFG.vehicleID] = { [1] = CFG.insID }
        DM.vehicleSkinInsIDTable = DM.vehicleSkinInsIDTable or {}
        DM.vehicleSkinInsIDTable[CFG.vehicleID] = CFG.insID
        DM.defaultVehicleSkinResIDTable = DM.defaultVehicleSkinResIDTable or {}
        DM.defaultVehicleSkinResIDTable[CFG.vehicleID] = CFG.skinResID
        if DM.roleData then DM.roleData.vst_skin = CFG.insID end
        R("DataMgr injected")
    end

    local tries = {
        { "ShowThemeVehicle", { CFG.vehicleID } },
        { "_ShowSelfVehicle", { CFG.vehicleID, CFG.insID } },
        { "_ReinitShowModelActor", {} },
        { "RefreshSpecialEffect", {} },
        { "SetVehicleTick", { true } },
    }
    for _, t in ipairs(tries) do
        if type(M[t[1]]) == "function" then
            local ok, err = pcall(M[t[1]], M, table.unpack(t[2]))
            R(t[1] .. " = " .. (ok and "OK" or ("ERR: " .. tostring(err):sub(1,80))))
        end
    end
    return rlog
end

local function tryPathLobbyVehicle()
    local rlog = {}
    local function R(s) rlog[#rlog+1] = s; LOG("  [LobbyVeh] " .. s) end

    local M = forceLoad("client.lobby_ue_object.Actor.LobbyVehicle")
    if not M then R("not loaded"); return rlog end
    R("loaded")

    local impl = M.__inner_impl or M
    local pos = getPlayerPos()
    R(string.format("pos (%.1f,%.1f,%.1f)", pos.X, pos.Y, pos.Z))

    -- Try slua spawn
    local spawned = false
    pcall(function()
        if slua and slua.NewObject and impl.StaticClass then
            local obj = slua.NewObject(impl.StaticClass)
            if obj then
                spawned = true
                R("slua.NewObject(StaticClass) succeeded")
            end
        end
    end)
    if not spawned then R("slua spawn not possible — class path unknown") end
    return rlog
end

-- ═══════════════════════════════════════════════════════════════════
-- FIRE — sab paths try kare
-- ═══════════════════════════════════════════════════════════════════
local FIRED = false
local function fireAll()
    if FIRED and CFG.fireOnce then
        LOG("Already fired, skipping")
        return
    end
    FIRED = true

    LOG("═══ FIRE START ═══")
    local out = {}
    out[#out+1] = "═══ v40 FIRE ═══"
    out[#out+1] = "Time: " .. os.date("%Y-%m-%d %H:%M:%S")

    local phase = getPhase()
    out[#out+1] = string.format("Phase: fighting=%s social=%s status=%s",
        tostring(phase.fighting), tostring(phase.social), tostring(phase.status))
    out[#out+1] = ""

    out[#out+1] = "── Path 1: TeamShow ──"
    for _, l in ipairs(tryPathTeamShow()) do out[#out+1] = l end
    out[#out+1] = ""

    out[#out+1] = "── Path 2: ThemeVehicleManager ──"
    for _, l in ipairs(tryPathThemeVehicle()) do out[#out+1] = l end
    out[#out+1] = ""

    out[#out+1] = "── Path 3: LobbyVehicle ──"
    for _, l in ipairs(tryPathLobbyVehicle()) do out[#out+1] = l end

    S("v40_fire.txt", table.concat(out, "\n"))
    LOG("FIRE END saved: v40_fire.txt")
end

-- ═══════════════════════════════════════════════════════════════════
-- PHASE WATCHER — har loop pe check
-- ═══════════════════════════════════════════════════════════════════
local tickCount = 0
local function tick()
    tickCount = tickCount + 1
    local phase = getPhase()

    if tickCount % 5 == 0 then
        LOG(string.format("tick %d phase status=%s fighting=%s social=%s",
            tickCount, tostring(phase.status), tostring(phase.fighting), tostring(phase.social)))
    end

    -- Auto dump jab match me ho
    if not DUMP_DONE and (phase.fighting or phase.status == "Fighting") then
        pcall(autoDump)
    end

    -- Fire once after dump
    if DUMP_DONE and not FIRED then
        pcall(fireAll)
        -- Popup result
        pcall(function()
            local fireTxt = "Spawn attempt fired.\nCheck v40_fire.txt"
            P("v40 RESULT", fireTxt)
        end)
    end

    -- Re-try fire every 8 ticks if not fired
    if not FIRED and tickCount > 15 then
        LOG("Force fire after timeout")
        pcall(fireAll)
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- TIMER SETUP
-- ═══════════════════════════════════════════════════════════════════
local timerStarted = false
local function startTimer()
    if timerStarted then return end
    timerStarted = true
    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerLoop then
            ticker.AddTimerLoop(0, tick, -1, CFG.loopEvery)
            LOG("Timer started, loop every " .. CFG.loopEvery .. "s")
        else
            LOG("time_ticker not available — trying fallback")
            -- Fallback: use _G.SetTimer if available
            if _G.SetTimer then
                _G.SetTimer(CFG.loopEvery, tick, -1)
                LOG("Using _G.SetTimer fallback")
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- BOOT — delayed start
-- ═══════════════════════════════════════════════════════════════════
S("v40_report.txt",
    "v40 AUTONOMOUS REPORT\n" ..
    "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n" ..
    "Vehicle: " .. CFG.vehicleID .. " | Skin: " .. CFG.skinResID .. "\n\n" ..
    "AUTO-LOADED. No commands needed.\n" ..
    "Files written automatically:\n" ..
    "  v40_session.txt  (live log)\n" ..
    "  v40_dump.txt     (module structure)\n" ..
    "  v40_fire.txt     (spawn attempts)\n")

LOG("Config saved. Waiting " .. CFG.autoDelay .. "s before timer start.")

-- Delayed timer start
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(CFG.autoDelay, function()
            LOG("Delay over, starting timer")
            startTimer()
        end)
    else
        -- Immediate start fallback
        startTimer()
    end
end)

-- Immediate first probe (before timer)
pcall(function()
    local phase = getPhase()
    LOG("Initial phase: fighting=" .. tostring(phase.fighting) ..
        " social=" .. tostring(phase.social) ..
        " status=" .. tostring(phase.status))
end)

P("v40 AUTO-LOADED",
    "Autonomous spawn engine running.\n\n" ..
    "Kuch nahi karna.\n\n" ..
    "BornIsland match kholo.\n" ..
    "Files khud banengi:\n" ..
    "  v40_dump.txt\n" ..
    "  v40_fire.txt\n" ..
    "  v40_session.txt\n\n" ..
    "12-15 sec me match me aao.")

print("[v40] Auto-loaded. Timer will start in " .. CFG.autoDelay .. "s.")

return true
