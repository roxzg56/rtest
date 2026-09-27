-- ═══════════════════════════════════════════════════════════════════
-- v36 — BORNISLAND FAKE VEHICLE DROP (Client Visual Only)
-- Target: MiniTVActor + ThemeVehicleManager (lobby-render layer)
-- Own nahi vehicle bhi show hogi — pure client memory injection
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

local CFG = {
    vehicleID = 902,
    skinResID = 1961014,
    insID     = 7247538342442672640,
    dropDelay = 3.0,
    dropHeight = 100,
    autoRevert = 12.0,
}

S("v36_config.txt",
    "v36 BornIsland Fake Drop\n" ..
    "vehicleID = " .. CFG.vehicleID .. "\n" ..
    "skinResID = " .. CFG.skinResID .. "\n" ..
    "insID = " .. CFG.insID .. "\n")

-- ═══════════════════════════════════════════════════════════════════
-- STEP 1: DataMgr fake injection (own nahi vehicle)
-- ═══════════════════════════════════════════════════════════════════
local _original = {}

local function injectFakeVehicleData()
    local DataMgr = package.loaded["client.logic.data.DataMgr"]
        or (pcall(require, "client.logic.data.DataMgr") and require("client.logic.data.DataMgr"))
    if not DataMgr then return false end

    _original.VehicleSlotList = DataMgr.VehicleSlotList
    _original.vehicleSkinInsIDTable = DataMgr.vehicleSkinInsIDTable
    _original.defaultVehicleSkinResIDTable = DataMgr.defaultVehicleSkinResIDTable

    DataMgr.VehicleSlotList = DataMgr.VehicleSlotList or {}
    DataMgr.VehicleSlotList[CFG.vehicleID] = { [1] = CFG.insID }

    DataMgr.vehicleSkinInsIDTable = DataMgr.vehicleSkinInsIDTable or {}
    DataMgr.vehicleSkinInsIDTable[CFG.vehicleID] = CFG.insID

    DataMgr.defaultVehicleSkinResIDTable = DataMgr.defaultVehicleSkinResIDTable or {}
    DataMgr.defaultVehicleSkinResIDTable[CFG.vehicleID] = CFG.skinResID

    if DataMgr.roleData then
        DataMgr.roleData.vst_skin = CFG.insID
    end
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 2: ThemeVehicleManager — RepeatTags/Vehicles/SkinCache init
--         (yeh v29 ka miss tha, SkinCache missing tha)
-- ═══════════════════════════════════════════════════════════════════
local function patchThemeVehicleManager()
    local M = package.loaded["client.logic.lobby.ThemeVehicleManager"]
        or (pcall(require, "client.logic.lobby.ThemeVehicleManager")
            and require("client.logic.lobby.ThemeVehicleManager"))
    if not M then return false end

    M.RepeatTags = M.RepeatTags or {}
    M.Vehicles = M.Vehicles or {}
    M.SkinCache = M.SkinCache or {}     -- ← v29 me yeh missing tha
    M.ModelActorCache = M.ModelActorCache or {}

    -- GetSelfVehicleInfo — fake slot 1 return
    if not _original.GetSelfVehicleInfo and M.GetSelfVehicleInfo then
        _original.GetSelfVehicleInfo = M.GetSelfVehicleInfo
    end
    if _original.GetSelfVehicleInfo then
        M.GetSelfVehicleInfo = function(self)
            return {
                [1] = { ItemID = CFG.skinResID, Source = 0, InsID = CFG.insID },
                [2] = {}, [3] = {}, [4] = {},
                [5] = {}, [6] = {}, [7] = {},
            }
        end
    end
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 3: Spawn fake vehicle model (lobby-render layer works even
--         in BornIsland match — same UE actor pool)
-- ═══════════════════════════════════════════════════════════════════
local function spawnFakeVehicle()
    local M = package.loaded["client.logic.lobby.ThemeVehicleManager"]
    if not M then return false end

    pcall(function() M:ShowThemeVehicle(CFG.vehicleID) end)
    pcall(function() M:_ShowSelfVehicle(CFG.vehicleID, CFG.insID) end)
    pcall(function() M:_ReinitShowModelActor() end)
    pcall(function() M:RefreshSpecialEffect() end)
    pcall(function() M:SetVehicleTick(true) end)
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 4: Fake drop visual — MiniTVActor se airdrop sequence
--         (asli drop isi actor se render hota hai)
-- ═══════════════════════════════════════════════════════════════════
local function fireDropVisual()
    local results = {}

    local MT = package.loaded["client.lobby_ue_object.Actor.MiniTV.MiniTVActor"]
        or (pcall(require, "client.lobby_ue_object.Actor.MiniTV.MiniTVActor")
            and require("client.lobby_ue_object.Actor.MiniTV.MiniTVActor"))

    if not MT then
        results[#results+1] = "MiniTVActor not loaded"
        return results
    end

    local inst = MT
    -- Try to find live instance via package table
    pcall(function()
        if MT.__inner_impl then inst = MT.__inner_impl end
    end)

    local function try(name, ...)
        if type(inst[name]) ~= "function" then
            results[#results+1] = name .. " = missing"
            return
        end
        local ok, err = pcall(inst[name], inst, ...)
        results[#results+1] = name .. " = " .. (ok and "OK" or ("ERR: " .. tostring(err):sub(1,60)))
    end

    -- Actual drop animation path (order matters, v31 confirmed):
    try("SetDropHigh", CFG.dropHeight)
    try("PlayAirDropAnimEvent")
    try("DropEvent")
    try("TryFloatOrDrop")

    return results
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 5: UI airdrop mesh (container + smoke visual)
-- ═══════════════════════════════════════════════════════════════════
local function fireAirdropMesh()
    local results = {}
    local UM = package.loaded["client.slua.umg.LuckyAirDrop.ui_airdrop_mesh"]
        or (pcall(require, "client.slua.umg.LuckyAirDrop.ui_airdrop_mesh")
            and require("client.slua.umg.LuckyAirDrop.ui_airdrop_mesh"))
    if not UM then
        results[#results+1] = "ui_airdrop_mesh not loaded"
        return results
    end

    pcall(function() UM.Create() end)
    pcall(function() UM.CreateBox() end)
    pcall(function() UM.ShowBox() end)
    pcall(function() UM.ChangeSkin(CFG.skinResID) end)
    results[#results+1] = "mesh visual fired"
    return results
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 6: Revert (detection-safe cleanup)
-- ═══════════════════════════════════════════════════════════════════
local function revertAll()
    local DataMgr = package.loaded["client.logic.data.DataMgr"]
    if DataMgr then
        if _original.VehicleSlotList then DataMgr.VehicleSlotList = _original.VehicleSlotList end
        if _original.vehicleSkinInsIDTable then DataMgr.vehicleSkinInsIDTable = _original.vehicleSkinInsIDTable end
        if _original.defaultVehicleSkinResIDTable then DataMgr.defaultVehicleSkinResIDTable = _original.defaultVehicleSkinResIDTable end
    end
    local M = package.loaded["client.logic.lobby.ThemeVehicleManager"]
    if M and _original.GetSelfVehicleInfo then
        M.GetSelfVehicleInfo = _original.GetSelfVehicleInfo
    end
    S("v36_revert.txt", "Reverted at " .. os.date("%H:%M:%S"))
end

-- ═══════════════════════════════════════════════════════════════════
-- MAIN: Fake Drop Trigger
-- ═══════════════════════════════════════════════════════════════════
_G.V36_FireDrop = function()
    local log = {}
    log[#log+1] = "=== v36 FIRE DROP START ==="
    log[#log+1] = "Vehicle: " .. CFG.vehicleID .. " | Skin: " .. CFG.skinResID

    -- 1. Inject fake data
    if injectFakeVehicleData() then log[#log+1] = "DataMgr injected" 
    else log[#log+1] = "DataMgr FAIL" end

    -- 2. Patch ThemeVehicleManager (with SkinCache)
    if patchThemeVehicleManager() then log[#log+1] = "ThemeVehicleManager patched"
    else log[#log+1] = "ThemeVehicleManager FAIL" end

    -- 3. Spawn model
    if spawnFakeVehicle() then log[#log+1] = "Model spawn called" end

    -- 4. Drop animation
    for _, r in ipairs(fireDropVisual()) do log[#log+1] = "  " .. r end

    -- 5. Container visual
    for _, r in ipairs(fireAirdropMesh()) do log[#log+1] = "  " .. r end

    -- 6. Auto-revert
    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(CFG.autoRevert, revertAll)
            log[#log+1] = "Revert scheduled +" .. CFG.autoRevert .. "s"
        end
    end)

    log[#log+1] = "=== END ==="
    local txt = table.concat(log, "\n")
    S("v36_trigger.txt", txt)
    P("v36 FAKE DROP", txt)
    return txt
end

-- Manual revert
_G.V36_Revert = revertAll

-- ═══════════════════════════════════════════════════════════════════
-- TRACE (capture asli drop sequence for reference)
-- ═══════════════════════════════════════════════════════════════════
_G._V36_TraceLog = {}
_G._V36_TraceActive = false

_G.V36_TraceStart = function()
    _G._V36_TraceActive = true
    _G._V36_TraceLog = {}
    local function log(s)
        _G._V36_TraceLog[#_G._V36_TraceLog+1] = string.format("[%s] %s", os.date("%H:%M:%S"), s)
    end
    log("=== TRACE START ===")

    -- Hook MiniTVActor + ui_airdrop_mesh
    for _, path in ipairs({
        "client.lobby_ue_object.Actor.MiniTV.MiniTVActor",
        "client.slua.umg.LuckyAirDrop.ui_airdrop_mesh",
        "client.slua.logic.luck_airdrop.logic_luck_air_drop",
        "GameLua.Mod.Library.GamePlay.Subsystem.BornIslandAirDropSystem",
    }) do
        pcall(function()
            local M = package.loaded[path]
            if type(M) ~= "table" then return end
            local impl = M.__inner_impl or M
            for name, fn in pairs(impl) do
                if type(fn) == "function" and type(name) == "string" then
                    local orig = fn
                    impl[name] = function(self, ...)
                        log("CALL " .. name .. "(" .. tostring(select("#", ...)) .. " args)")
                        local ok, r = pcall(orig, self, ...)
                        if not ok then log("  ✗ " .. tostring(r):sub(1,120)) end
                        return r
                    end
                end
            end
            log("Hooked " .. path)
        end)
    end

    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerLoop then
            ticker.AddTimerLoop(0, function()
                if _G._V36_TraceActive and #_G._V36_TraceLog > 0 then
                    S("v36_trace.txt", table.concat(_G._V36_TraceLog, "\n"))
                end
            end, -1, 8.0)
        end
    end)

    P("v36 TRACE", "Trace ON.\nBornIsland match kholo.\nDrop aane tak wait.\nV36_TraceStop()")
end

_G.V36_TraceStop = function()
    _G._V36_TraceActive = false
    S("v36_trace.txt", table.concat(_G._V36_TraceLog or {}, "\n"))
    P("v36 STOP", "Saved: v36_trace.txt\nLines: " .. #(_G._V36_TraceLog or {}))
end

-- ═══════════════════════════════════════════════════════════════════
-- AUTO-BOOT
-- ═══════════════════════════════════════════════════════════════════
S("v36_report.txt",
    "v36 REPORT\n" ..
    "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n" ..
    "Target: MiniTVActor + ThemeVehicleManager (client visual)\n" ..
    "Vehicle: " .. CFG.vehicleID .. " | Skin: " .. CFG.skinResID .. "\n\n" ..
    "Commands:\n" ..
    "  V36_FireDrop()    -- fire fake drop\n" ..
    "  V36_Revert()      -- manual revert\n" ..
    "  V36_TraceStart()  -- start trace\n" ..
    "  V36_TraceStop()   -- save trace\n")

print("[v36] Loaded. V36_FireDrop() to fire.")

P("v36 LOADED",
    "BornIsland Fake Drop Ready\n\n" ..
    "Vehicle: " .. CFG.vehicleID .. "\n" ..
    "Skin: " .. CFG.skinResID .. "\n\n" ..
    "BornIsland match me:\n" ..
    "  V36_FireDrop()\n\n" ..
    "Aur drop aane pe:\n" ..
    "  V36_TraceStart() pehle\n" ..
    "  Drop dekho, phir\n" ..
    "  V36_TraceStop()")

return true
