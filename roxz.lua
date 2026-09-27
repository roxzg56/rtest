-- ═══════════════════════════════════════════════════════════════════
-- v41 — FORCE INSTANCE + ALTERNATE CLIENT PATHS
-- Auto-fire. Koi command nahi.
-- 3 paths: Subsystem force-init + LuckyAirDrop fake + UI mesh
-- ═══════════════════════════════════════════════════════════════════

local DIR = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"

local function S(name, content)
    local f = io.open(DIR .. name, "w")
    if not f then return false end
    f:write(content or ""); f:close()
    return true
end

local function A(file, line)
    local f = io.open(DIR .. file, "a")
    if not f then return false end
    f:write(line .. "\n"); f:close()
end

local function P(t, m)
    pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
        if Msg and Msg.Show then
            Msg.Show(1, tostring(t), tostring(m), function() end, function() end, "OK", "CLOSE")
        end
    end)
end

local LOGF = "v41_session.txt"
local function L(s)
    local line = "[" .. os.date("%H:%M:%S") .. "] " .. tostring(s)
    A(LOGF, line)
    print("[v41] " .. line)
end

-- Fresh session file
S(LOGF, "═══ v41 SESSION " .. os.date("%Y-%m-%d %H:%M:%S") .. " ═══\n")

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
-- LOADERS
-- ═══════════════════════════════════════════════════════════════════
local function forceLoad(path)
    local M = package.loaded[path]
    if M and type(M) == "table" then return M end
    local ok, mod = pcall(require, path)
    if ok and type(mod) == "table" then return mod end
    return nil
end

-- DataMgr — global first, then multiple paths
local function getDataMgr()
    local dm = _G.DataMgr
    if dm and type(dm) == "table" then return dm end
    for _, p in ipairs({
        "client.logic.data.DataMgr",
        "client.logic.data.data_mgr",
        "client.logic.DataMgr",
        "GameLua.GameCore.Data.DataMgr",
    }) do
        local m = forceLoad(p)
        if m and type(m) == "table" then return m end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════
-- SERIALIZER
-- ═══════════════════════════════════════════════════════════════════
local function ser(v, d, seen)
    d = d or 0; seen = seen or {}
    if d > 3 then return "..." end
    local t = type(v)
    if t == "nil" or t == "boolean" or t == "number" then return tostring(v) end
    if t == "string" then
        if #v > 60 then return string.format("%q...", v:sub(1, 57)) end
        return string.format("%q", v)
    end
    if t == "function" then return "<fn>" end
    if t == "userdata" then return "<ud>" end
    if t == "table" then
        if seen[v] then return "<cyc>" end
        seen[v] = true
        local parts = {}; local n = 0
        for i = 1, math.min(#v, 10) do
            parts[#parts+1] = ser(v[i], d+1, seen); n = n + 1
        end
        for k, val in pairs(v) do
            if n >= 20 then parts[#parts+1] = "..." break end
            if type(k) ~= "number" or k > #v then
                parts[#parts+1] = tostring(k) .. "=" .. ser(val, d+1, seen); n = n + 1
            end
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    return "<" .. t .. ">"
end

-- ═══════════════════════════════════════════════════════════════════
-- PLAYER POS
-- ═══════════════════════════════════════════════════════════════════
local function getPos()
    local p = { X = 0, Y = 0, Z = CFG.dropHeight }
    pcall(function()
        local GD = forceLoad("GameLua.GameCore.Data.GameplayData")
        if GD and GD.GetPlayerCharacter then
            local ch = GD.GetPlayerCharacter()
            if ch and slua and slua.isValid and slua.isValid(ch) then
                if ch.K2_GetActorLocation then
                    local loc = ch:K2_GetActorLocation()
                    if loc then
                        p.X = (loc.X or 0) + CFG.offsetX
                        p.Y = (loc.Y or 0) + CFG.offsetY
                        p.Z = (loc.Z or 0) + CFG.dropHeight
                    end
                end
            end
        end
    end)
    return p
end

-- ═══════════════════════════════════════════════════════════════════
-- PATH 1 — FORCE SUBSYSTEM INSTANTIATION
-- ═══════════════════════════════════════════════════════════════════
local function pathForceSubsystem(log)
    log("═══ PATH 1: Force Subsystem ═══")

    local SM = forceLoad("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
    if not SM then log("  ✗ SubsystemMgr not loaded"); return nil end

    -- Dump current state
    log("  SubsystemOrderNames count: " ..
        (SM.SubsystemOrderNames and #SM.SubsystemOrderNames or 0))
    log("  SubsystemMap count: " ..
        (function() local c=0; if SM.SubsystemMap then for _ in pairs(SM.SubsystemMap) do c=c+1 end end; return c end)())

    -- Dump subsystem names (search for BornIsland related)
    if SM.SubsystemOrderNames then
        local found = {}
        for _, n in ipairs(SM.SubsystemOrderNames) do
            if type(n) == "string" then
                local ln = n:lower()
                if ln:find("born") or ln:find("airdrop") or ln:find("teams") or ln:find("vehicle") then
                    found[#found+1] = n
                end
            end
        end
        log("  BornIsland-related subsys names: " .. table.concat(found, ", "):sub(1, 300))
    end

    -- Try DynamicAddSubsystem
    local targetName = "BornIslandTeamShowSubSystem"
    if type(SM.DynamicAddSubsystem) == "function" then
        local ok, err = pcall(SM.DynamicAddSubsystem, targetName)
        log("  DynamicAddSubsystem(" .. targetName .. ") = " ..
            (ok and "OK" or ("ERR: " .. tostring(err):sub(1,120))))
    end

    -- Try Get after add
    if type(SM.Get) == "function" then
        local r
        local ok = pcall(function() r = SM.Get(targetName) end)
        log("  Get(" .. targetName .. ") after add = " ..
            (ok and (r and "GOT INSTANCE" or "nil") or "ERR"))
        if r then return r end
    end

    -- Try _Register
    if type(SM._Register) == "function" then
        pcall(SM._Register, targetName)
        log("  _Register called")
    end

    -- Try Init to force all
    if type(SM.Init) == "function" then
        pcall(SM.Init)
        log("  Init() called")
    end

    -- Retry Get
    if type(SM.Get) == "function" then
        local r
        pcall(function() r = SM.Get(targetName) end)
        if r then log("  ✓ INSTANCE after Init"); return r end
    end

    log("  ✗ no instance obtained")
    return nil
end

-- ═══════════════════════════════════════════════════════════════════
-- PATH 2 — LUCKY AIRDROP (FakeLuckAirData + UI push)
-- ═══════════════════════════════════════════════════════════════════
local function pathLuckyAirDrop(log)
    log("═══ PATH 2: LuckyAirDrop Client Path ═══")

    local M = forceLoad("client.slua.logic.luck_airdrop.logic_luck_air_drop")
    if not M then log("  ✗ not loaded"); return end

    -- Build fake data matching expected shape
    local pos = getPos()
    local fakeData = {
        itemID = CFG.skinResID,
        ItemID = CFG.skinResID,
        skinResID = CFG.skinResID,
        vehicleID = CFG.vehicleID,
        insID = CFG.insID,
        posX = pos.X, posY = pos.Y, posZ = pos.Z,
        X = pos.X, Y = pos.Y, Z = pos.Z,
        quality = 5,
        Quality = 5,
    }

    -- Dump current cached data for reference
    pcall(function()
        if M.LuckAirData then
            log("  LuckAirData = " .. ser(M.LuckAirData, 0, {}))
        end
        if M.target_airdrop_data then
            log("  target_airdrop_data = " .. ser(M.target_airdrop_data, 0, {}))
        end
    end)

    -- Try FakeLuckAirData
    if type(M.FakeLuckAirData) == "function" then
        local ok, err = pcall(M.FakeLuckAirData)
        log("  FakeLuckAirData() = " .. (ok and "OK" or ("ERR: " .. tostring(err):sub(1,100))))

        pcall(function()
            M.FakeLuckAirData(fakeData)
            log("  FakeLuckAirData(fakeData) OK")
        end)
    end

    -- Try SetEquipedInfo
    if type(M.SetEquipedInfo) == "function" then
        pcall(function()
            M.SetEquipedInfo(fakeData)
            log("  SetEquipedInfo OK")
        end)
    end

    -- Try HandleTargetAirdropData
    if type(M.HandleTargetAirdropData) == "function" then
        pcall(function()
            M.HandleTargetAirdropData(fakeData)
            log("  HandleTargetAirdropData OK")
        end)
    end

    -- Try RefreshLuckAirDropLoacation
    if type(M.RefreshLuckAirDropLoacation) == "function" then
        pcall(function()
            M.RefreshLuckAirDropLoacation()
            log("  RefreshLuckAirDropLoacation OK")
        end)
    end

    -- Try DataPushShowUI
    if type(M.DataPushShowUI) == "function" then
        pcall(function()
            M.DataPushShowUI()
            log("  DataPushShowUI OK")
        end)
    end

    -- Try ShowLuckShopUI (opens the shop UI which shows airdrops)
    if type(M.ShowLuckShopUI) == "function" then
        pcall(function()
            M.ShowLuckShopUI()
            log("  ShowLuckShopUI OK")
        end)
    end

    -- Query asset paths (yeh batayega konsa mesh hai)
    for _, fn in ipairs({"GetBoxMeshPath", "GetMeshAssetPath", "GetAirDropClassPath", "GetLightName", "GetUISmokeName"}) do
        if type(M[fn]) == "function" then
            local ok, r = pcall(M[fn])
            if ok then log("  " .. fn .. "() = " .. tostring(r)) end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- PATH 3 — UI AIRDROP MESH (create visual box)
-- ═══════════════════════════════════════════════════════════════════
local function pathUIMesh(log)
    log("═══ PATH 3: UI AirDrop Mesh ═══")

    local M = forceLoad("client.slua.umg.LuckyAirDrop.ui_airdrop_mesh")
    if not M then log("  ✗ not loaded"); return end

    local pos = getPos()
    local fakeTransform = {
        Location = { X = pos.X, Y = pos.Y, Z = pos.Z },
        Rotation = { Roll = 0, Pitch = 0, Yaw = 0 },
        Scale = { X = 1, Y = 1, Z = 1 },
        X = pos.X, Y = pos.Y, Z = pos.Z,
    }

    local tries = {
        { "Create", {} },
        { "CreateBox", { fakeTransform, CFG.skinResID } },
        { "CreateBox", { CFG.skinResID } },
        { "CreateBox", {} },
        { "ChangeSkin", { CFG.skinResID } },
        { "UpdateBoxMesh", { CFG.skinResID } },
        { "ShowBox", {} },
        { "ShowOrHide", { true } },
        { "DownloadResourceAndCreateBox", { CFG.skinResID } },
    }

    for _, t in ipairs(tries) do
        if type(M[t[1]]) == "function" then
            local ok, err = pcall(M[t[1]], table.unpack(t[2]))
            log("  " .. t[1] .. "(" .. #t[2] .. " args) = " ..
                (ok and "OK" or ("ERR: " .. tostring(err):sub(1,100))))
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- PATH 4 — TeamShow with FOUND instance (via path 1)
-- ═══════════════════════════════════════════════════════════════════
local function pathTeamShowWithInstance(inst, log)
    log("═══ PATH 4: TeamShow w/ instance ═══")

    if not inst then
        -- fallback to impl
        local M = forceLoad("GameLua.Mod.BaseMod.Client.BornIslandTeamShow.BornIslandTeamShowSubSystem")
        inst = M and (M.__inner_impl or M)
        log("  no live instance — using impl (may not work)")
    else
        log("  using REAL live instance")
    end

    if not inst then log("  ✗ no inst at all"); return end

    local pos = getPos()
    local fake = {
        vehicleID = CFG.vehicleID, VehicleID = CFG.vehicleID,
        skinResID = CFG.skinResID, SkinResID = CFG.skinResID,
        insID = CFG.insID, InsID = CFG.insID,
        itemID = CFG.skinResID, ItemID = CFG.skinResID,
        posX = pos.X, posY = pos.Y, posZ = pos.Z,
        X = pos.X, Y = pos.Y, Z = pos.Z,
        SlotID = 1, PlayerID = 0, bIsSelf = true,
    }

    -- InitConfig first
    pcall(function()
        if type(inst.InitConfig) == "function" then
            inst:InitConfig(); log("  InitConfig OK")
        end
    end)

    -- CreateDataForShow
    pcall(function()
        if type(inst.CreateDataForShow) == "function" then
            local ok, err = pcall(inst.CreateDataForShow, inst, fake)
            log("  CreateDataForShow = " .. (ok and "OK" or tostring(err):sub(1,100)))
        end
    end)

    -- CreateCarObject — CAR SPAWN
    pcall(function()
        if type(inst.CreateCarObject) == "function" then
            local ok, err = pcall(inst.CreateCarObject, inst, fake)
            log("  CreateCarObject = " .. (ok and "OK" or tostring(err):sub(1,150)))
        end
    end)

    -- CreateSingleRole (ye bhi actor spawn karta hai)
    pcall(function()
        if type(inst.CreateSingleRole) == "function" then
            local ok = pcall(inst.CreateSingleRole, inst, {})
            log("  CreateSingleRole = " .. (ok and "OK" or "ERR"))
        end
    end)

    -- Try BeginShow with config tbl (line 1078 needed arg)
    pcall(function()
        if type(inst.BeginShow) == "function" then
            local cfgTable = inst:GetCurrentConfig and inst:GetCurrentConfig() or {}
            local ok, err = pcall(inst.BeginShow, inst, cfgTable)
            log("  BeginShow(cfg) = " .. (ok and "OK" or tostring(err):sub(1,150)))
        end
    end)

    -- ReadyToShow with args
    pcall(function()
        if type(inst.ReadyToShow) == "function" then
            local ok, err = pcall(inst.ReadyToShow, inst, true)
            log("  ReadyToShow(true) = " .. (ok and "OK" or tostring(err):sub(1,100)))
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- PATH 5 — DataMgr + ThemeVM (sahi DataMgr)
-- ═══════════════════════════════════════════════════════════════════
local function pathThemeVM(log)
    log("═══ PATH 5: ThemeVM + real DataMgr ═══")

    local DM = getDataMgr()
    if DM then
        log("  ✓ DataMgr found")
        DM.VehicleSlotList = DM.VehicleSlotList or {}
        DM.VehicleSlotList[CFG.vehicleID] = { [1] = CFG.insID }
        DM.vehicleSkinInsIDTable = DM.vehicleSkinInsIDTable or {}
        DM.vehicleSkinInsIDTable[CFG.vehicleID] = CFG.insID
        DM.defaultVehicleSkinResIDTable = DM.defaultVehicleSkinResIDTable or {}
        DM.defaultVehicleSkinResIDTable[CFG.vehicleID] = CFG.skinResID
        if DM.roleData then DM.roleData.vst_skin = CFG.insID end
        log("  DataMgr injected")
    else
        log("  ✗ DataMgr not found in any path")
    end

    local M = forceLoad("client.logic.lobby.ThemeVehicleManager")
    if not M then log("  ✗ ThemeVM not loaded"); return end
    log("  ThemeVM loaded")

    M.RepeatTags = M.RepeatTags or {}
    M.Vehicles = M.Vehicles or {}
    M.SkinCache = M.SkinCache or {}
    M.ModelActorCache = M.ModelActorCache or {}

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
            log("  " .. t[1] .. " = " .. (ok and "OK" or tostring(err):sub(1,100)))
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- VERIFY — after fire, scan world for new actors
-- ═══════════════════════════════════════════════════════════════════
local function verify(log)
    log("═══ VERIFY ═══")
    pcall(function()
        if _G.GetWorld then
            local w = _G.GetWorld()
            log("  GetWorld() = " .. tostring(w))
        end
        if _G.UE and UE.GameplayStatics then
            log("  UE.GameplayStatics available")
            if UE.GameplayStatics.GetAllActorsOfClass then
                log("  GetAllActorsOfClass available")
            end
        end
        -- Count vehicles in world via ALuaVehicleBase
        local vb = forceLoad("GameLua.GameCore.Module.Vehicle.ALuaVehicleBase")
        if vb and vb.GetAllVehicles then
            local ok, list = pcall(vb.GetAllVehicles)
            if ok and type(list) == "table" then
                log("  vehicles in world: " .. #list)
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- FIRE ALL PATHS
-- ═══════════════════════════════════════════════════════════════════
local FIRED = false
local function fireAll()
    if FIRED then return end
    FIRED = true
    L("═══ FIRE ALL PATHS ═══")

    local inst = nil

    -- 1. Force subsystem
    pcall(function() inst = pathForceSubsystem(L) end)
    A(LOGF, "")

    -- 2. Lucky AirDrop
    pcall(pathLuckyAirDrop, L)
    A(LOGF, "")

    -- 3. UI Mesh
    pcall(pathUIMesh, L)
    A(LOGF, "")

    -- 4. TeamShow with inst
    pcall(pathTeamShowWithInstance, inst, L)
    A(LOGF, "")

    -- 5. ThemeVM
    pcall(pathThemeVM, L)
    A(LOGF, "")

    -- 6. Verify
    pcall(verify, L)

    L("═══ FIRE END ═══")
    A(LOGF, "── check v41_session.txt ──")

    pcall(function()
        P("v41 FIRED", "All paths fired. Check v41_session.txt")
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- PHASE WATCHER
-- ═══════════════════════════════════════════════════════════════════
local function phaseOK()
    local GS = _G.GameStatus or forceLoad("GameLua.GameCore.Framework.GameStatus")
    if not GS then return true end  -- fire anyway
    local f, s = false, false
    pcall(function()
        if GS.IsInFightingStatus then f = GS.IsInFightingStatus() or false end
        if GS.IsSocialIslandMode then s = GS.IsSocialIslandMode() or false end
    end)
    return f or s
end

local ticks = 0
local function tick()
    ticks = ticks + 1
    if ticks % 3 == 0 then
        L("tick " .. ticks .. " waiting...")
    end
    if phaseOK() then
        L("Phase OK — firing")
        fireAll()
    end
    if ticks > 20 and not FIRED then
        L("Timeout — firing anyway")
        fireAll()
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- BOOT
-- ═══════════════════════════════════════════════════════════════════
S("v41_report.txt",
    "v41 REPORT\n" ..
    "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n" ..
    "Vehicle: " .. CFG.vehicleID .. " | Skin: " .. CFG.skinResID .. "\n\n" ..
    "AUTO-LOADED. No commands needed.\n" ..
    "Auto-fires when BornIsland/Fighting detected.\n")

pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerLoop then
        ticker.AddTimerLoop(0, tick, -1, 3.0)
        L("Timer started (every 3s)")
    end
end)

L("v41 loaded, waiting for phase...")

P("v41 LOADED",
    "Auto-fire engine v41.\n\n" ..
    "Kuch nahi karna.\n" ..
    "Fighting/BornIsland phase milte hi:\n" ..
    "  → 5 spawn paths fire\n" ..
    "  → v41_session.txt me sab\n\n" ..
    "Match me ho toh auto-fire ho jayega.")

print("[v41] Auto-loaded. Fires when phase OK.")
return true
