-- ═══════════════════════════════════════════════════════════════════
-- v25 — VEHICLE SPAWN (Focused) + FILE FIX
-- Path: /storage/emulated/0/Android/data/com.pubg.imobile/files/
-- ═══════════════════════════════════════════════════════════════════

local DIR = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"

local function P(t, m)
    pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
        if not Msg then
            local ok, r = pcall(require, "client.slua.logic.common.logic_common_msg_box")
            if ok then Msg = r end
        end
        if Msg and Msg.Show then
            Msg.Show(1, tostring(t), tostring(m), function() end, function() end, "OK", "CLOSE")
        end
    end)
end

-- ─── SAVE with verify ─────────────────────────────────────────────
local function SAVE(name, content)
    content = content or ""
    local fullPath = DIR .. name
    
    local f, err = io.open(fullPath, "w")
    if not f then
        return false, "OPEN FAIL: " .. tostring(err)
    end
    f:write(content)
    f:close()
    
    -- Verify
    local vf = io.open(fullPath, "r")
    if not vf then return false, "READ FAIL" end
    local readBack = vf:read("*a") or ""
    vf:close()
    
    return true, fullPath .. " (" .. #readBack .. " bytes)"
end

-- ─── Immediate test ───────────────────────────────────────────────
local testOK, testInfo = SAVE("v25_test.txt", 
    "v25 loaded at " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n" ..
    "DIR: " .. DIR .. "\n" ..
    "Test: 1234567890\n")

print("[V25] File test: " .. (testOK and "OK" or "FAIL") .. " | " .. tostring(testInfo))

-- ═══════════════════════════════════════════════════════════════════
-- USER'S OWNED VEHICLES (from your DataMgr dump)
-- ═══════════════════════════════════════════════════════════════════
local USER_OWNED = {
    {vehicleID = 901, insID = 7373942577173899842},
    {vehicleID = 908, insID = 7385485150086259305},
    {vehicleID = 984, insID = 7377277283722326217},
    {vehicleID = 985, insID = 7377277283722326218},
}

-- All known insIDs from vehicleSkinInsIDTable (for any vehicle spawn)
local ALL_INSIDS = {
    [960] = 7247538342442672648,
    [961] = 7247538342442672628,
    [963] = 7247538342442672644,
    [901] = 7373942577173899842,
    [966] = 7247538342442672636,
    [903] = 7247538342442672621,
    [904] = 7247538342442672609,
    [905] = 7247538342442672649,
    [906] = 7247538342442672645,
    [907] = 7247538342442672629,
    [908] = 7247538342442672634,
    [910] = 7247538342442672623,
    [911] = 7247538342442672624,
    [912] = 7247538342442672650,
    [913] = 7247538342442672627,
    [915] = 7247538342442672631,
    [916] = 7247538342442672620,
    [917] = 7247538342442672611,
    [918] = 7247538342442672632,
    [919] = 7247538342442672635,
    [920] = 7247538342442672625,
    [930] = 7247538342442672615,
    [953] = 7247538342442672647,
    [902] = 7247538342442672640,
    [967] = 7359790739373563215,
    [968] = 7392449663798971986,
    [984] = 7377277283722326217,
    [985] = 7377277283722326218,
}

-- ═══════════════════════════════════════════════════════════════════
-- MAIN SPAWN FUNCTION
-- ═══════════════════════════════════════════════════════════════════
_G.V25_Spawn = function(vehicleID)
    vehicleID = vehicleID or 903
    
    local insID = ALL_INSIDS[vehicleID]
    if not insID then
        P("V25 SPAWN", "No insID for vehicleID " .. tostring(vehicleID))
        return
    end
    
    local results = {}
    results[#results+1] = "Target: vID=" .. vehicleID .. " insID=" .. insID
    
    -- ═══ APPROACH 1: Set DataMgr.roleData.vst_skin ═══
    pcall(function()
        local DM = _G.DataMgr
        if DM and DM.roleData then
            DM.roleData.vst_skin = insID
            results[#results+1] = "✓ Set vst_skin = " .. insID
        end
    end)
    
    -- ═══ APPROACH 2: Direct call ThemeVehicleManager functions ═══
    local M = require("client.logic.lobby.ThemeVehicleManager")
    local i = M and M.__inner_impl
    if i then
        -- Try each spawn method with various args
        local methods = {
            { "ShowThemeVehicle", vehicleID },
            { "ShowThemeVehicle", insID },
            { "ShowThemeVehicle", vehicleID, insID },
            { "ShowThemeVehicle", {vehicleID = vehicleID, skinID = insID, InsID = insID} },
            { "_ShowSelfVehicle", vehicleID },
            { "_ShowSelfVehicle", insID },
            { "_ShowSelfVehicle", vehicleID, insID },
            { "_CreateVehicleModel", vehicleID },
            { "_CreateVehicleModel", insID },
            { "_CreateVehicleModel", vehicleID, insID },
            { "_TryCreateVehicleModel", vehicleID },
            { "PreviewGarageVehicle", vehicleID },
            { "OnVehicleChange", vehicleID },
            { "OnGarageVehicleChange", vehicleID },
        }
        
        for _, m in ipairs(methods) do
            local fnName = m[1]
            local arg1 = m[2]
            local arg2 = m[3]
            if type(i[fnName]) == "function" then
                local ok, err = pcall(i[fnName], i, arg1, arg2)
                local status = ok and "OK" or ("ERR: " .. tostring(err):sub(1, 40))
                results[#results+1] = fnName .. "(" .. tostring(arg1) .. 
                    (arg2 and (", " .. tostring(arg2)) or "") .. ") = " .. status
            end
        end
    else
        results[#results+1] = "✗ ThemeVehicleManager NOT loaded"
    end
    
    -- ═══ APPROACH 3: Trigger refresh ═══
    pcall(function()
        local M2 = require("client.logic.lobby.ThemeVehicleManager")
        local i2 = M2 and M2.__inner_impl
        if i2 then
            if type(i2.RefreshSpecialEffect) == "function" then
                pcall(i2.RefreshSpecialEffect, i2)
                results[#results+1] = "✓ RefreshSpecialEffect"
            end
            if type(i2._ReinitShowModelActor) == "function" then
                pcall(i2._ReinitShowModelActor, i2)
                results[#results+1] = "✓ _ReinitShowModelActor"
            end
            if type(i2.SetVehicleTick) == "function" then
                pcall(i2.SetVehicleTick, i2, true)
                results[#results+1] = "✓ SetVehicleTick(true)"
            end
        end
    end)
    
    -- ═══ APPROACH 4: EventSystem broadcast ═══
    pcall(function()
        if EventSystem and EventSystem.postEvent then
            -- Try common vehicle refresh events
            if EVENTTYPE_LOBBY then
                if EVENTID_UPDATE_LOBBY_VEHICLE then
                    EventSystem:postEvent(EVENTTYPE_LOBBY, EVENTID_UPDATE_LOBBY_VEHICLE)
                    results[#results+1] = "✓ Broadcast UPDATE_LOBBY_VEHICLE"
                end
            end
        end
    end)
    
    local txt = table.concat(results, "\n")
    SAVE("v25_spawn_log.txt", txt)
    P("V25 SPAWN", txt)
    return results
end

-- ═══════════════════════════════════════════════════════════════════
-- LOOP THROUGH ALL OWNED VEHICLES
-- ═══════════════════════════════════════════════════════════════════
_G.V25_TryAll = function()
    for _, v in ipairs(USER_OWNED) do
        V25_Spawn(v.vehicleID)
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- DESTROY
-- ═══════════════════════════════════════════════════════════════════
_G.V25_Destroy = function()
    pcall(function()
        local M = require("client.logic.lobby.ThemeVehicleManager")
        local i = M and M.__inner_impl
        if not i then return end
        if type(i.DestoryThemeVehicle) == "function" then i.DestoryThemeVehicle(i) end
        if type(i.DestroyAllThemeVehiclesOnly) == "function" then i.DestroyAllThemeVehiclesOnly(i) end
    end)
    P("V25", "Car destroyed")
end

-- ═══════════════════════════════════════════════════════════════════
-- PATCH: Remove vehicle ownership checks (only 5 functions)
-- ═══════════════════════════════════════════════════════════════════
local PFX = "__v25_"
local function wrap(mod, name, wrapper)
    if not mod or type(mod[name]) ~= "function" then return false end
    if not mod[PFX .. name] then mod[PFX .. name] = mod[name] end
    mod[name] = wrapper(mod[PFX .. name])
    return true
end

local patched = 0
pcall(function()
    local M = require("client.logic.lobby.ThemeVehicleManager")
    local i = M and M.__inner_impl
    if not i then return end

    -- Ownership checks — always allow
    if wrap(i, "CheckVehicleTypeHasUnlock", function(orig)
        return function(self, ...) return true end
    end) then patched = patched + 1 end

    if wrap(i, "HaveEnoughVehicleShowSpecial", function(orig)
        return function(self, ...) return true end
    end) then patched = patched + 1 end

    if wrap(i, "NeedShowSpecialThemeEffect", function(orig)
        return function(self, ...) return true end
    end) then patched = patched + 1 end

    -- Get self vehicle IDs — return user's owned
    if wrap(i, "GetSelfVehicleIDs", function(orig)
        return function(self, ...)
            local r = orig(self, ...)
            if type(r) == "table" and next(r) then return r end
            local list = {}
            for _, v in ipairs(USER_OWNED) do
                list[#list+1] = v.vehicleID
            end
            return list
        end
    end) then patched = patched + 1 end

    -- Get valid vehicle num — always enough
    if wrap(i, "GetValidVehicleNum", function(orig)
        return function(self, ...) return 999 end
    end) then patched = patched + 1 end
end)

-- ═══════════════════════════════════════════════════════════════════
-- FINAL REPORT + AUTO-TEST
-- ═══════════════════════════════════════════════════════════════════
local report = "v25 REPORT\n" ..
    "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n" ..
    "File test: " .. (testOK and "OK" or "FAIL") .. " | " .. tostring(testInfo) .. "\n" ..
    "Patched: " .. patched .. "\n" ..
    "User owns " .. #USER_OWNED .. " vehicles\n"

SAVE("v25_report.txt", report)

-- Auto-run spawn attempt in 3 sec
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(3.0, function()
            pcall(function()
                V25_Spawn(901)  -- Try user's owned vehicle first
            end)
        end)
    end
end)

-- Initial popup with file test result
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(1.0, function()
            P("v25 LOADED", 
                "File test: " .. (testOK and "✓ OK" or "✗ FAIL") .. "\n" ..
                tostring(testInfo) .. "\n\n" ..
                "Patched: " .. patched .. "\n\n" ..
                "3 sec mein auto-spawn hoga:\n" ..
                "V25_Spawn(901)")
        end)
    end
end)

print("[V25] Loaded. Patched: " .. patched .. ". File test: " .. tostring(testOK))

return true
