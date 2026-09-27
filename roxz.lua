-- ═══════════════════════════════════════════════════════════════════
-- v35 — FAKE DROP TRIGGER (Born Island)
-- Target: BornIslandAirDropSystem.CreateAirDrop
-- Path: /storage/emulated/0/Android/data/com.pubg.imobile/files/
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
            or (pcall(require, "client.slua.logic.common.logic_common_msg_box")
                and require("client.slua.logic.common.logic_common_msg_box"))
        if Msg and Msg.Show then
            Msg.Show(1, tostring(t), tostring(m), function() end, function() end, "OK", "CLOSE")
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════════════════════════
local CFG = {
    vehicleID = 902,           -- Coupe RB
    skinResID = 1961014,       -- McLaren 570S Royal Black
    insID = 7247538342442672640,
    dropX = 0, dropY = 0, dropZ = 100,   -- drop location (0,0 = player pos)
    dropDelay = 3.0,           -- seconds after trigger
    autoTrigger = false,       -- auto fire on born island entry
}

S("v35_config.txt",
    "v35 Fake Drop Config\n" ..
    "vehicleID = " .. CFG.vehicleID .. "\n" ..
    "skinResID = " .. CFG.skinResID .. "\n" ..
    "insID = " .. CFG.insID .. "\n" ..
    "dropX/Y/Z = " .. CFG.dropX .. "/" .. CFG.dropY .. "/" .. CFG.dropZ .. "\n"
)

-- ═══════════════════════════════════════════════════════════════════
-- BUILD DROP DATA (what CreateAirDrop expects)
-- ═══════════════════════════════════════════════════════════════════
local function buildDropData()
    -- Get player position for drop
    local px, py, pz = 0, 0, CFG.dropZ
    pcall(function()
        local GD = require("GameLua.GameCore.Data.GameplayData")
        local ch = GD.GetPlayerCharacter and GD.GetPlayerCharacter()
        if ch and slua.isValid(ch) and ch.K2_GetActorLocation then
            local loc = ch:K2_GetActorLocation()
            if loc then px, py, pz = loc.X, loc.Y, loc.Z + CFG.dropZ end
        end
    end)

    return {
        -- Common drop data fields (both naming conventions)
        itemID = CFG.skinResID,
        ItemID = CFG.skinResID,
        skinID = CFG.skinResID,
        SkinID = CFG.skinResID,
        vehicleID = CFG.vehicleID,
        VehicleID = CFG.vehicleID,
        insID = CFG.insID,
        InsID = CFG.insID,
        posX = CFG.dropX ~= 0 and CFG.dropX or px,
        posY = CFG.dropY ~= 0 and CFG.dropY or py,
        posZ = CFG.dropZ,
        x = CFG.dropX ~= 0 and CFG.dropX or px,
        y = CFG.dropY ~= 0 and CFG.dropY or py,
        z = CFG.dropZ,
        -- Meta
        dropType = 1,
        DropType = 1,
        source = "special",
        Source = "special",
        isVehicle = true,
        IsVehicle = true,
        isSpecial = true,
        IsSpecial = true,
    }
end

-- ═══════════════════════════════════════════════════════════════════
-- TRIGGER: Call CreateAirDrop directly
-- ═══════════════════════════════════════════════════════════════════
_G.V35_TriggerDrop = function()
    local results = {}

    -- 1. Get module
    local M = package.loaded["GameLua.Mod.Library.GamePlay.Subsystem.BornIslandAirDropSystem"]
    if not M then
        local ok, r = pcall(require, "GameLua.Mod.Library.GamePlay.Subsystem.BornIslandAirDropSystem")
        if ok then M = r end
    end
    if type(M) ~= "table" then
        P("V35", "BornIslandAirDropSystem not loaded")
        return
    end

    local i = M.__inner_impl
    if type(i) ~= "table" then
        P("V35", "No __inner_impl")
        return
    end

    results[#results+1] = "Module found"

    -- 2. Check if instance exists (may need SubsystemMgr)
    local inst = nil
    pcall(function()
        local SubMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr and type(SubMgr.Get) == "function" then
            inst = SubMgr:Get("BornIslandAirDropSystem")
        end
    end)

    if not inst then
        -- Try module-level i as instance
        inst = i
        results[#results+1] = "Using module class as instance"
    else
        results[#results+1] = "Got real instance from SubsystemMgr"
    end

    -- 3. Build drop data
    local dropData = buildDropData()
    results[#results+1] = "Drop data built"

    -- 4. Call CreateAirDrop
    if type(inst.CreateAirDrop) == "function" then
        -- Try multiple argument styles
        local tries = {
            { "dropData only", function() return inst:CreateAirDrop(dropData) end },
            { "no args", function() return inst:CreateAirDrop() end },
            { "self + dropData", function() return inst.CreateAirDrop(inst, dropData) end },
            { "self only", function() return inst.CreateAirDrop(inst) end },
        }

        for _, t in ipairs(tries) do
            local ok, err = pcall(t[2])
            results[#results+1] = t[1] .. " = " .. (ok and "OK" or ("ERR: " .. tostring(err):sub(1, 60)))
            if ok then break end
        end
    else
        results[#results+1] = "CreateAirDrop not a function"
    end

    -- 5. Also try InitConfig + StartFight to prep
    pcall(function()
        if type(inst.InitConfig) == "function" then
            inst:InitConfig()
            results[#results+1] = "InitConfig called"
        end
    end)

    pcall(function()
        if type(inst.StartFight) == "function" then
            inst:StartFight()
            results[#results+1] = "StartFight called"
        end
    end)

    local txt = table.concat(results, "\n")
    S("v35_trigger.txt", txt)
    P("V35 TRIGGER", txt)
    return txt
end

-- ═══════════════════════════════════════════════════════════════════
-- LIVE TRACE — capture real drop when it happens
-- ═══════════════════════════════════════════════════════════════════
_G._V35_TraceLog = {}
_G._V35_TraceActive = false

_G.V35_TraceStart = function()
    if _G._V35_TraceActive then
        P("V35", "Already tracing")
        return
    end
    _G._V35_TraceActive = true
    _G._V35_TraceLog = {}

    local function log(s)
        _G._V35_TraceLog[#_G._V35_TraceLog+1] = 
            string.format("[%s] %s", os.date("%H:%M:%S"), s)
    end

    log("=== TRACE START ===")

    -- Hook all functions of BornIslandAirDropSystem
    pcall(function()
        local M = require("GameLua.Mod.Library.GamePlay.Subsystem.BornIslandAirDropSystem")
        local i = M and M.__inner_impl
        if type(i) ~= "table" then return end

        for name, fn in pairs(i) do
            if type(fn) == "function" and type(name) == "string" then
                local orig = fn
                i[name] = function(self, ...)
                    -- Log args
                    local args = {}
                    for n = 1, math.min(5, select("#", ...)) do
                        local v = select(n, ...)
                        if type(v) == "table" then
                            local tblStr = "{"
                            local cnt = 0
                            for k, val in pairs(v) do
                                cnt = cnt + 1
                                if cnt > 8 then tblStr = tblStr .. "..." break end
                                tblStr = tblStr .. tostring(k) .. "=" .. tostring(val):sub(1, 30) .. ", "
                            end
                            args[#args+1] = tblStr .. "}"
                        else
                            args[#args+1] = tostring(v):sub(1, 40)
                        end
                    end
                    log("CALL " .. name .. "(" .. table.concat(args, ", ") .. ")")
                    local ok, r = pcall(orig, self, ...)
                    if not ok then
                        log("  ✗ ERR: " .. tostring(r):sub(1, 200))
                    elseif r ~= nil then
                        log("  ↳ RET: " .. tostring(r):sub(1, 100))
                    end
                    return r
                end
            end
        end
        log("Hooked all functions")
    end)

    -- Auto-save
    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerLoop then
            ticker.AddTimerLoop(0, function()
                if _G._V35_TraceActive and #_G._V35_TraceLog > 0 then
                    S("v35_trace.txt", table.concat(_G._V35_TraceLog, "\n"))
                end
            end, -1, 8.0)
        end
    end)

    P("V35 TRACE", "Trace ON.\n\n1. Match kholo\n2. Spawn island pe wait\n3. Drop aane tak\n4. V35_TraceStop()")
end

_G.V35_TraceStop = function()
    _G._V35_TraceActive = false
    local txt = table.concat(_G._V35_TraceLog or {}, "\n")
    S("v35_trace.txt", txt)
    P("V35 STOP", "Saved: v35_trace.txt\nLines: " .. #(_G._V35_TraceLog or {}))
end

-- ═══════════════════════════════════════════════════════════════════
-- AUTO-BOOT
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(3.0, function()
            pcall(_G.V35_TraceStart)
        end)
    end
end)

S("v35_report.txt",
    "v35 REPORT\n" ..
    "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n" ..
    "Target: BornIslandAirDropSystem.CreateAirDrop\n" ..
    "Vehicle: " .. CFG.vehicleID .. " | Skin: " .. CFG.skinResID .. "\n" ..
    "\nCommands:\n" ..
    "  V35_TriggerDrop()  -- manual trigger\n" ..
    "  V35_TraceStart()   -- start trace\n" ..
    "  V35_TraceStop()    -- save trace\n"
)

P("v35 LOADED",
    "Fake Drop Ready\n\n" ..
    "Vehicle: " .. CFG.vehicleID .. "\n" ..
    "Skin: " .. CFG.skinResID .. "\n\n" ..
    "Trace auto-start 3s baad.\n" ..
    "Match start karo, spawn island pe.\n" ..
    "15-20 sec baad V35_TraceStop()")

print("[V35] Loaded. Trace auto-start in 3s.")

return true
