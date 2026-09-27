-- ═══════════════════════════════════════════════════════════════════
-- v39 — BORNISLAND CLIENT ACTOR SPAWN (Server-Independent)
-- Target: BornIslandTeamShowSubSystem.CreateCarObject + LobbyVehicle
-- Server ko kuch nahi bhejta. Pure client-side UE actor spawn.
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
-- CONFIG
-- ═══════════════════════════════════════════════════════════════════
local CFG = {
    vehicleID  = 902,
    skinResID  = 1961014,
    insID      = 7247538342442672640,
    dropHeight = 100,
    offsetX    = 5,
    offsetY    = 5,
}

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
    if t == "string" then return string.format("%q", v) end
    if t == "function" then return "<fn>" end
    if t == "userdata" then return "<ud>" end
    if t == "table" then
        if seen[v] then return "<cycle>" end
        seen[v] = true
        local p = {}; local n = 0
        for i = 1, math.min(#v, 20) do
            p[#p+1] = ser(v[i], d+1, seen); n = n + 1
        end
        for k, val in pairs(v) do
            if n >= 40 then p[#p+1] = "..." break end
            if type(k) ~= "number" or k > #v then
                p[#p+1] = tostring(k) .. "=" .. ser(val, d+1, seen); n = n + 1
            end
        end
        return "{" .. table.concat(p, ", ") .. "}"
    end
    return "<" .. t .. ">"
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 1 — PLAYER POSITION
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
                    if loc then pos.X = loc.X + CFG.offsetX; pos.Y = loc.Y + CFG.offsetY; pos.Z = loc.Z + CFG.dropHeight end
                end
            end
        end
    end)
    return pos
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 2 — SUBSYSTEM INSTANCE DHUNDHO
-- ═══════════════════════════════════════════════════════════════════
local function findSubsystemInstance(names)
    local inst = nil
    pcall(function()
        local SM = forceLoad("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SM and type(SM.Get) == "function" then
            for _, n in ipairs(names) do
                local r = SM.Get(n)
                if r then inst = r; return end
            end
        end
        -- Alternative: SubSystemMgr
        local SSM = forceLoad("GameLua.GameCore.Framework.SubsystemMgr")
        if not inst and SSM then
            for _, n in ipairs(names) do
                if type(SSM.GetSubsystem) == "function" then
                    local r = SSM.GetSubsystem(n)
                    if r then inst = r; return end
                end
            end
        end
    end)
    return inst
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 3 — TEAM SHOW SUBSYSTEM SE CAR SPAWN
-- ═══════════════════════════════════════════════════════════════════
local function pathTeamShow(log)
    log("── [3] BornIslandTeamShowSubSystem ──")

    local M = forceLoad("GameLua.Mod.BaseMod.Client.BornIslandTeamShow.BornIslandTeamShowSubSystem")
    if not M then
        log("  ✗ module NOT loaded even after force")
        return false
    end
    log("  ✓ module loaded")

    local impl = M.__inner_impl or M
    local inst = findSubsystemInstance({
        "BornIslandTeamShowSubSystem",
        "BornIslandTeamShow",
    })

    if inst then
        log("  ✓ live instance from SubsystemMgr")
    else
        inst = impl
        log("  ⚠ using module impl as instance (may fail on state-dependent calls)")
    end

    -- List functions
    local fns = {}
    for k, v in pairs(inst) do
        if type(v) == "function" then fns[#fns+1] = k end
    end
    log("  available fns: " .. table.concat(fns, ", "):sub(1, 300))

    -- Build fake car data
    local pos = getPlayerPos()
    local fakeData = {
        vehicleID = CFG.vehicleID,
        VehicleID = CFG.vehicleID,
        skinResID = CFG.skinResID,
        SkinResID = CFG.skinResID,
        insID     = CFG.insID,
        InsID     = CFG.insID,
        itemID    = CFG.skinResID,
        ItemID    = CFG.skinResID,
        posX = pos.X, posY = pos.Y, posZ = pos.Z,
        X = pos.X, Y = pos.Y, Z = pos.Z,
        SlotID = 1,
        PlayerID = 0,
        bIsSelf = true,
    }

    -- Try InitConfig first if state not ready
    pcall(function()
        if type(inst.InitConfig) == "function" then
            inst:InitConfig()
            log("  ✓ InitConfig called")
        end
    end)

    -- Try CreateCarObject
    if type(inst.CreateCarObject) == "function" then
        local ok, err = pcall(inst.CreateCarObject, inst, fakeData)
        log("  CreateCarObject(fakeData) = " .. (ok and "OK" or ("ERR: " .. tostring(err):sub(1,150))))
    end

    -- Try CreateDataForShow
    if type(inst.CreateDataForShow) == "function" then
        local ok, err = pcall(inst.CreateDataForShow, inst, fakeData)
        log("  CreateDataForShow = " .. (ok and "OK" or ("ERR: " .. tostring(err):sub(1,150))))
    end

    -- Try BeginShow
    if type(inst.BeginShow) == "function" then
        local ok, err = pcall(inst.BeginShow, inst)
        log("  BeginShow = " .. (ok and "OK" or ("ERR: " .. tostring(err):sub(1,150))))
    end

    -- Try ReadyToShow
    if type(inst.ReadyToShow) == "function" then
        local ok, err = pcall(inst.ReadyToShow, inst)
        log("  ReadyToShow = " .. (ok and "OK" or ("ERR: " .. tostring(err):sub(1,150))))
    end

    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 4 — LOBBY VEHICLE ACTOR DIRECT SPAWN
-- ═══════════════════════════════════════════════════════════════════
local function pathLobbyVehicle(log)
    log("── [4] LobbyVehicle actor ──")

    local M = forceLoad("client.lobby_ue_object.Actor.LobbyVehicle")
    if not M then
        log("  ✗ LobbyVehicle NOT loaded")
        return false
    end
    log("  ✓ LobbyVehicle loaded")

    local inst = M.__inner_impl or M

    -- Check for UE class path
    local classPath = nil
    pcall(function()
        if inst.ClassPath then classPath = inst.ClassPath end
        if inst.StaticClass then classPath = "StaticClass available" end
        if inst.GetClass and type(inst.GetClass) == "function" then
            classPath = "GetClass available"
        end
    end)
    log("  class path info: " .. tostring(classPath))

    -- Try UE world SpawnActor via slua
    local pos = getPlayerPos()
    log(string.format("  spawn pos: (%.1f, %.1f, %.1f)", pos.X, pos.Y, pos.Z))

    -- Try multiple UE access methods
    local spawned = false
    pcall(function()
        if _G.UE and UE.GameplayStatics then
            log("  UE.GameplayStatics available")
        end
        if slua and slua.NewObject then
            log("  slua.NewObject available")
        end
    end)

    -- Try SetVehicleAccessoryList + trigger
    if type(inst.SetVehicleAccessoryList) == "function" then
        pcall(function()
            inst:SetVehicleAccessoryList({})
            log("  SetVehicleAccessoryList called")
        end)
    end

    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 5 — THEME VEHICLE MANAGER (BornIsland ke andar bhi try)
-- ═══════════════════════════════════════════════════════════════════
local function pathThemeVehicle(log)
    log("── [5] ThemeVehicleManager ──")

    local M = forceLoad("client.logic.lobby.ThemeVehicleManager")
    if not M then
        log("  ✗ not loaded")
        return false
    end
    log("  ✓ loaded")

    M.RepeatTags = M.RepeatTags or {}
    M.Vehicles = M.Vehicles or {}
    M.SkinCache = M.SkinCache or {}
    M.ModelActorCache = M.ModelActorCache or {}

    -- Data injection
    local DM = forceLoad("client.logic.data.DataMgr")
    if DM then
        DM.VehicleSlotList = DM.VehicleSlotList or {}
        DM.VehicleSlotList[CFG.vehicleID] = { [1] = CFG.insID }
        DM.vehicleSkinInsIDTable = DM.vehicleSkinInsIDTable or {}
        DM.vehicleSkinInsIDTable[CFG.vehicleID] = CFG.insID
        DM.defaultVehicleSkinResIDTable = DM.defaultVehicleSkinResIDTable or {}
        DM.defaultVehicleSkinResIDTable[CFG.vehicleID] = CFG.skinResID
        log("  DataMgr injected")
    end

    pcall(function() M:ShowThemeVehicle(CFG.vehicleID) end)
    pcall(function() M:_ShowSelfVehicle(CFG.vehicleID, CFG.insID) end)
    pcall(function() M:_ReinitShowModelActor() end)
    log("  spawn chain called")

    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- MAIN — FIRE ALL PATHS
-- ═══════════════════════════════════════════════════════════════════
_G.V39_Fire = function()
    local log = {}
    local function L(s) log[#log+1] = s end

    L("═══ v39 CLIENT ACTOR SPAWN ═══")
    L("Time: " .. os.date("%Y-%m-%d %H:%M:%S"))
    L(string.format("Vehicle: %d | Skin: %d | InsID: %d", CFG.vehicleID, CFG.skinResID, CFG.insID))
    L("")

    -- Phase check
    pcall(function()
        local GS = _G.GameStatus or forceLoad("GameLua.GameCore.Framework.GameStatus")
        if GS then
            if GS.IsInFightingStatus then
                L("GameStatus.IsInFightingStatus = " .. tostring(select(2, pcall(GS.IsInFightingStatus))))
            end
            if GS.IsSocialIslandMode then
                L("GameStatus.IsSocialIslandMode = " .. tostring(select(2, pcall(GS.IsSocialIslandMode))))
            end
            if GS.GetGameStatus then
                L("GameStatus.GetGameStatus = " .. tostring(select(2, pcall(GS.GetGameStatus))))
            end
        end
    end)
    L("")

    -- Path 3: Team show
    pcall(pathTeamShow, L)
    L("")

    -- Path 4: LobbyVehicle
    pcall(pathLobbyVehicle, L)
    L("")

    -- Path 5: ThemeVehicleManager
    pcall(pathThemeVehicle, L)
    L("")

    L("═══ END ═══")
    local txt = table.concat(log, "\n")
    S("v39_trigger.txt", txt)
    P("v39 CLIENT SPAWN", txt)
    return txt
end

-- ═══════════════════════════════════════════════════════════════════
-- FORCE DUMP — sab kuch load karo aur functions list bhejo
-- ═══════════════════════════════════════════════════════════════════
_G.V39_DumpAll = function()
    local log = {}
    local function L(s) log[#log+1] = s end

    L("═══ v39 FORCE DUMP ═══")
    L("Time: " .. os.date("%Y-%m-%d %H:%M:%S"))
    L("")

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
    }

    for _, path in ipairs(paths) do
        L("── " .. path .. " ──")
        local M = forceLoad(path)
        if M then
            L("  STATUS: LOADED")
            local impl = M.__inner_impl or M
            local funcs, tables = {}, {}
            for k, v in pairs(impl) do
                if type(v) == "function" then funcs[#funcs+1] = k
                elseif type(v) == "table" then tables[#tables+1] = k end
            end
            L("  FUNCTIONS (" .. #funcs .. "):")
            for i = 1, math.min(#funcs, 80) do
                L("    fn " .. funcs[i])
            end
            if #tables > 0 then
                L("  TABLES (" .. #tables .. "): " .. table.concat(tables, ", "))
            end
        else
            L("  STATUS: NOT LOADED")
        end
        L("")
    end

    -- SubsystemMgr check
    L("── SubsystemMgr scan ──")
    local SM = forceLoad("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
    if SM then
        for k, v in pairs(SM) do
            if type(v) == "function" then L("  SM." .. k) end
        end
        if SM.AllSubsystems then
            for k, v in pairs(SM.AllSubsystems) do
                L("  subsystem: " .. tostring(k))
            end
        end
    else
        L("  SubsystemMgr NOT loaded")
    end

    L("═══ END ═══")
    local txt = table.concat(log, "\n")
    S("v39_dump.txt", txt)
    P("v39 DUMP", "Saved: v39_dump.txt\nLines: " .. #log)
    return txt
end

-- ═══════════════════════════════════════════════════════════════════
-- REPORT
-- ═══════════════════════════════════════════════════════════════════
S("v39_report.txt",
    "v39 REPORT\n" ..
    "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n" ..
    "Purpose: client-side UE actor spawn (server bypass)\n\n" ..
    "Commands:\n" ..
    "  V39_DumpAll()  -- pehle ye chalao\n" ..
    "  V39_Fire()     -- spawn attempt\n")

print("[v39] Loaded. Run V39_DumpAll() FIRST, then V39_Fire()")

P("v39 LOADED",
    "Client Actor Spawn v39\n\n" ..
    "STEP 1:\n" ..
    "  V39_DumpAll()\n" ..
    "  → bhejo v39_dump.txt\n\n" ..
    "STEP 2:\n" ..
    "  V39_Fire()\n" ..
    "  → bhejo v39_trigger.txt")

return true
