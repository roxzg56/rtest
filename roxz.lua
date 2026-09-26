-- ═══════════════════════════════════════════════════════════════════
-- v28 — McLAREN DROP + DUMPER + TRACE
-- Base: 902 (Coupe RB) | Skin: 1961014 | Full diagnostic capture
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
        if not Msg then
            local ok, r = pcall(require, "client.slua.logic.common.logic_common_msg_box")
            if ok then Msg = r end
        end
        if Msg and Msg.Show then
            Msg.Show(1, tostring(t), tostring(m), function() end, function() end, "OK", "CLOSE")
        end
    end)
end

local function V(v, d, m)
    d, m = d or 0, m or 3
    if d > m then return "..." end
    local t = type(v)
    if t == "nil" or t == "boolean" or t == "number" then return tostring(v) end
    if t == "string" then return #v > 80 and ('"'..v:sub(1,77)..'..."') or ('"'..v..'"') end
    if t == "function" then return "<fn>" end
    if t == "userdata" then return "<ud>" end
    if t == "table" then
        local p, i, n = {}, 0, 0
        for _ in pairs(v) do n = n + 1 end
        for k, val in pairs(v) do
            i = i + 1
            if i > 15 then p[#p+1] = "...(+"..(n-15)..")"; break end
            p[#p+1] = tostring(k).."="..V(val,d+1,m)
        end
        return "{"..table.concat(p,",").."}"
    end
    return "<"..t..">"
end

-- ═══════════════════════════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════════════════════════
local CFG = {
    baseVehicleID = 902,               -- Coupe RB (CORRECT)
    skinResID = 1961014,               -- McLaren 570S Royal Black
    insID = 7247538342442672640,       -- from user dump [902]
    skinInsID = 7247538342442672654,
}

S("v28_config.txt",
    "v28 McLaren Config\n" ..
    "baseVehicleID = " .. CFG.baseVehicleID .. " (Coupe RB)\n" ..
    "skinResID = " .. CFG.skinResID .. " (McLaren Royal Black)\n" ..
    "insID = " .. CFG.insID .. "\n" ..
    "skinInsID = " .. CFG.skinInsID .. "\n"
)

-- ═══════════════════════════════════════════════════════════════════
-- REVERT
-- ═══════════════════════════════════════════════════════════════════
local PREFIXES = {
    "__mini11_", "__v12_", "__v13_", "__v14_", "__v15_", "__v16_",
    "__v17_", "__v18_", "__v19_", "__v20_", "__v21_", "__v22_",
    "__v23_", "__v25_", "__v26_", "__v27_",
    "__slotv10_", "__pet11_", "__pslotv2_", "__pslot11_",
}
local reverted = 0
local function revertModule(mod)
    if type(mod) ~= "table" then return 0 end
    local cnt = 0
    local backups = {}
    for k in pairs(mod) do
        if type(k) == "string" then
            for _, pfx in ipairs(PREFIXES) do
                if k:sub(1, #pfx) == pfx then
                    backups[#backups+1] = {bk = k, orig = k:sub(#pfx+1)}
                    break
                end
            end
        end
    end
    for _, item in ipairs(backups) do
        if type(mod[item.bk]) == "function" then
            mod[item.orig] = mod[item.bk]
            cnt = cnt + 1
        end
        mod[item.bk] = nil
    end
    return cnt
end

for _, path in ipairs({
    "client.logic.lobby.ThemeVehicleManager",
    "client.logic.vehicle.VehicleCollectSystem",
    "client.logic.vehicle.LogicVehicleExtendedFeature",
    "client.logic.vehicle.LogicVehicleAccessory",
}) do
    pcall(function()
        local M = require(path)
        if M and M.__inner_impl and M.__inner_impl ~= M then
            reverted = reverted + revertModule(M.__inner_impl)
        end
        if M and M ~= M.__inner_impl then
            reverted = reverted + revertModule(M)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- ⭐ DUMPER 1: Vehicle Mod System — find Grand Debut module
-- ═══════════════════════════════════════════════════════════════════
_G.V28_DumpVehicleMod = function()
    local out = {}
    local function w(s) out[#out+1] = tostring(s) end
    w("╔═══════════════════════════════════════════════════════════╗")
    w("║  VEHICLE MOD / GRAND DEBUT DUMP")
    w("║  Time: " .. os.date("%Y-%m-%d %H:%M:%S"))
    w("╚═══════════════════════════════════════════════════════════╝")
    w("")

    -- 1) Search package.loaded
    w("═══ package.loaded MODULES (mod/vehicle/debut/collect) ═══")
    for path, mod in pairs(package.loaded) do
        if type(path) == "string" and type(mod) == "table" then
            local lk = path:lower()
            if lk:find("vehiclemod") or lk:find("granddebut") 
               or lk:find("collectionreward") or lk:find("vehicledebut")
               or lk:find("vehiclemode") or lk:find("carmod")
               or lk:find("modsystem") then
                w("")
                w("▶ " .. path)
                
                -- Inner impl
                local inner = mod.__inner_impl
                if type(inner) == "table" then
                    local fns, tbls, scals = {}, {}, {}
                    for k, v in pairs(inner) do
                        local vt = type(v)
                        if vt == "function" then 
                            local info = debug.getinfo(v, "S")
                            local line = info and info.linedefined or 0
                            local src = info and (info.short_src or "?") or "?"
                            fns[#fns+1] = tostring(k) .. " (" .. tostring(line) .. ")"
                        elseif vt == "table" then
                            local n = 0; for _ in pairs(v) do n = n + 1 end
                            tbls[#tbls+1] = tostring(k) .. "(" .. n .. ")"
                        else
                            scals[#scals+1] = tostring(k) .. "=" .. V(v, 0, 1)
                        end
                    end
                    table.sort(fns)
                    table.sort(tbls)
                    table.sort(scals)
                    
                    w("  __inner_impl fns (" .. #fns .. "):")
                    for _, fn in ipairs(fns) do w("    " .. fn) end
                    if #tbls > 0 then
                        w("  __inner_impl tbls (" .. #tbls .. "):")
                        for _, t in ipairs(tbls) do w("    " .. t) end
                    end
                    if #scals > 0 then
                        w("  __inner_impl scalars:")
                        for _, s in ipairs(scals) do w("    " .. s) end
                    end
                end
                
                -- Top-level
                local topFns = {}
                for k, v in pairs(mod) do
                    if type(v) == "function" and type(k) == "string" and not k:match("^__") then
                        topFns[#topFns+1] = k
                    end
                end
                table.sort(topFns)
                if #topFns > 0 then
                    w("  Top fns: " .. table.concat(topFns, ", "))
                end
            end
        end
    end

    -- 2) LobbyModuleConfig search
    w("")
    w("═══ ModuleManager.LobbyModuleConfig (mod/vehicle/debut) ═══")
    pcall(function()
        local MM = _G.ModuleManager
        if MM and MM.LobbyModuleConfig then
            for key, cfg in pairs(MM.LobbyModuleConfig) do
                if type(cfg) == "table" and type(cfg.ModuleName) == "string" then
                    local lk = cfg.ModuleName:lower()
                    if lk:find("vehiclemod") or lk:find("granddebut")
                       or lk:find("collection") or lk:find("debut")
                       or lk:find("carmod") then
                        w("  " .. tostring(key) .. " = " .. cfg.ModuleName)
                        -- Try get instance
                        if type(MM.GetModule) == "function" then
                            local ok, inst = pcall(MM.GetModule, MM, cfg)
                            if ok and type(inst) == "table" then
                                local n = 0; for _ in pairs(inst) do n = n + 1 end
                                w("    → instance keys: " .. n)
                                for k, v in pairs(inst) do
                                    if type(v) == "function" and type(k) == "string" then
                                        local lk2 = k:lower()
                                        if lk2:find("debut") or lk2:find("spawn") 
                                           or lk2:find("drop") or lk2:find("trigger")
                                           or lk2:find("show") or lk2:find("reward") then
                                            w("      ⭐ " .. k)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    -- 3) Search all modules for "GrandDebut" string
    w("")
    w("═══ Modules with 'Debut' / 'Grand' / 'Drop' in function names ═══")
    local hits = {}
    for path, mod in pairs(package.loaded) do
        if type(path) == "string" and type(mod) == "table" then
            local inner = mod.__inner_impl or mod
            if type(inner) == "table" then
                for k in pairs(inner) do
                    if type(k) == "string" then
                        local lk = k:lower()
                        if lk:find("debut") or lk:find("granddebut") 
                           or lk:find("dropvehicle") then
                            hits[#hits+1] = path .. "." .. k
                        end
                    end
                end
            end
        end
    end
    table.sort(hits)
    for _, h in ipairs(hits) do
        w("  ⭐ " .. h)
    end

    -- 4) Vehicle skin table from CDataTable
    w("")
    w("═══ CDataTable.VehicleSkin ═══")
    pcall(function()
        local t = CDataTable.GetTable("VehicleSkin")
        if t then
            local n = 0; for _ in pairs(t) do n = n + 1 end
            w("  VehicleSkin count: " .. n)
            -- Show around 1961014
            for id, row in pairs(t) do
                local nid = tonumber(id)
                if nid and nid >= 1961000 and nid <= 1961030 then
                    w("  [" .. nid .. "] = " .. V(row, 0, 2))
                end
            end
        else
            w("  VehicleSkin NOT FOUND")
        end
    end)

    -- 5) Vehicle table
    w("")
    w("═══ CDataTable.Vehicle (around 902) ═══")
    pcall(function()
        local t = CDataTable.GetTable("Vehicle")
        if t then
            local n = 0; for _ in pairs(t) do n = n + 1 end
            w("  Vehicle count: " .. n)
            for id, row in pairs(t) do
                local nid = tonumber(id)
                if nid == 902 or nid == 961 then
                    w("  [" .. nid .. "] = " .. V(row, 0, 3))
                end
            end
        else
            w("  Vehicle NOT FOUND")
        end
    end)

    -- 6) VehicleMod related tables
    w("")
    w("═══ CDataTable vehicle mod tables ═══")
    pcall(function()
        for _, tn in ipairs({ "VehicleMod", "VehicleModify", "VehicleModSystem", 
                              "VehicleCollect", "VehicleDebut", "GrandDebut",
                              "VehicleRim", "VehicleLicense" }) do
            local t = CDataTable.GetTable(tn)
            if t then
                local n = 0; for _ in pairs(t) do n = n + 1 end
                w("  " .. tn .. " = " .. n .. " entries")
            end
        end
    end)

    local txt = table.concat(out, "\n")
    S("v28_mod_dump.txt", txt)
    print(txt)
    P("V28 MOD DUMP", "Saved: v28_mod_dump.txt\nLines: " .. #out)
    return txt
end

-- ═══════════════════════════════════════════════════════════════════
-- ⭐ DUMPER 2: Vehicle Data — full state
-- ═══════════════════════════════════════════════════════════════════
_G.V28_DumpVehicleData = function()
    local out = {}
    local function w(s) out[#out+1] = tostring(s) end
    w("═══ VEHICLE DATA DUMP ═══")
    w("Time: " .. os.date("%Y-%m-%d %H:%M:%S"))
    w("")

    pcall(function()
        local DM = _G.DataMgr
        if not DM then w("DataMgr NOT loaded") return end

        w("── DataMgr.roleData.vst_skin ──")
        w("  = " .. tostring(DM.roleData and DM.roleData.vst_skin))
        w("")

        w("── DataMgr.VehicleSlotList ──")
        if type(DM.VehicleSlotList) == "table" then
            for k, v in pairs(DM.VehicleSlotList) do
                local cnt = 0
                if type(v) == "table" then for _ in pairs(v) do cnt = cnt + 1 end end
                w("  [" .. tostring(k) .. "] = {" .. cnt .. " items} " .. V(v, 0, 3))
            end
        end
        w("")

        w("── DataMgr.vehicleSkinInsIDTable ──")
        if type(DM.vehicleSkinInsIDTable) == "table" then
            for k, v in pairs(DM.vehicleSkinInsIDTable) do
                w("  [" .. tostring(k) .. "] = " .. tostring(v))
            end
        end
        w("")

        w("── DataMgr.defaultVehicleSkinResIDTable ──")
        if type(DM.defaultVehicleSkinResIDTable) == "table" then
            for k, v in pairs(DM.defaultVehicleSkinResIDTable) do
                w("  [" .. tostring(k) .. "] = " .. tostring(v))
            end
        end
    end)

    local txt = table.concat(out, "\n")
    S("v28_vehicle_data.txt", txt)
    print(txt)
    P("V28 VEHICLE DUMP", "Saved: v28_vehicle_data.txt")
    return txt
end

-- ═══════════════════════════════════════════════════════════════════
-- ⭐ DUMPER 3: RUNTIME TRACE — hook everything relevant
-- ═══════════════════════════════════════════════════════════════════
_G._V28_TraceLog = {}
_G._V28_TraceActive = false

_G.V28_TraceStart = function()
    if _G._V28_TraceActive then 
        P("V28", "Trace already active")
        return 
    end
    _G._V28_TraceActive = true
    _G._V28_TraceLog = {}

    local function log(s)
        _G._V28_TraceLog[#_G._V28_TraceLog+1] = 
            string.format("[%s] %s", os.date("%H:%M:%S"), s)
    end

    log("=== TRACE STARTED ===")

    -- Hook all vehicle-related modules
    local HOOK_MODULES = {
        "client.logic.lobby.ThemeVehicleManager",
        "client.logic.vehicle.VehicleCollectSystem",
        "client.logic.vehicle.LogicVehicleExtendedFeature",
        "client.logic.vehicle.LogicVehicleAccessory",
    }

    for _, path in ipairs(HOOK_MODULES) do
        pcall(function()
            local M = require(path)
            local i = M and M.__inner_impl
            if type(i) ~= "table" then return end
            
            for k, fn in pairs(i) do
                if type(fn) == "function" and type(k) == "string" then
                    local lk = k:lower()
                    if lk:find("show") or lk:find("spawn") or lk:find("create")
                       or lk:find("preview") or lk:find("change") or lk:find("debut")
                       or lk:find("drop") or lk:find("vehicle") then
                        local orig = fn
                        local fnName = tostring(k)
                        i[k] = function(self, ...)
                            local args = {}
                            for n = 1, math.min(5, select("#", ...)) do
                                local v = select(n, ...)
                                if type(v) == "table" then 
                                    args[#args+1] = "tbl"
                                else 
                                    args[#args+1] = tostring(v):sub(1, 30)
                                end
                            end
                            log("CALL " .. path:sub(-40) .. "." .. fnName .. "(" .. 
                                table.concat(args, ",") .. ")")
                            local ok, r = pcall(orig, self, ...)
                            if not ok then
                                log("  ✗ ERR: " .. tostring(r):sub(1, 200))
                            elseif r ~= nil then
                                log("  ↳ RET: " .. V(r, 0, 1))
                            end
                            return r
                        end
                    end
                end
            end
            log("Hooked: " .. path)
        end)
    end

    -- Auto-save every 10 sec
    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerLoop then
            ticker.AddTimerLoop(0, function()
                if _G._V28_TraceActive and #_G._V28_TraceLog > 0 then
                    S("v28_trace.txt", table.concat(_G._V28_TraceLog, "\n"))
                end
            end, -1, 10.0)
        end
    end)

    log("=== HOOKS READY ===")
    P("V28 TRACE", 
        "Trace active.\n\n" ..
        "Now:\n" ..
        "1. Garage kholo\n" ..
        "2. Coupe RB select karo\n" ..
        "3. McLaren skin apply karo\n" ..
        "4. Wait 10 sec\n" ..
        "5. V28_TraceStop()")
end

_G.V28_TraceStop = function()
    _G._V28_TraceActive = false
    local txt = table.concat(_G._V28_TraceLog or {}, "\n")
    S("v28_trace.txt", txt)
    P("V28 TRACE STOPPED", 
        "Saved: v28_trace.txt\n" ..
        "Lines: " .. #(_G._V28_TraceLog or {}))
end

-- ═══════════════════════════════════════════════════════════════════
-- WRAP HELPER
-- ═══════════════════════════════════════════════════════════════════
local PFX = "__v28_"
local function wrap(mod, name, wrapper)
    if not mod or type(mod[name]) ~= "function" then return false end
    if not mod[PFX .. name] then mod[PFX .. name] = mod[name] end
    mod[name] = wrapper(mod[PFX .. name])
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- PATCH ThemeVehicleManager
-- ═══════════════════════════════════════════════════════════════════
local patched = 0
pcall(function()
    local M = require("client.logic.lobby.ThemeVehicleManager")
    local i = M and M.__inner_impl
    if not i then return end

    if i.Vehicles == nil then i.Vehicles = {} end

    if wrap(i, "CheckVehicleTypeHasUnlock", function(orig)
        return function(self, ...) return true end
    end) then patched = patched + 1 end

    if wrap(i, "HaveEnoughVehicleShowSpecial", function(orig)
        return function(self, ...) return true end
    end) then patched = patched + 1 end

    if wrap(i, "NeedShowSpecialThemeEffect", function(orig)
        return function(self, ...) return true end
    end) then patched = patched + 1 end

    if wrap(i, "GetValidVehicleNum", function(orig)
        return function(self, ...) return 999 end
    end) then patched = patched + 1 end

    if wrap(i, "GetSelfVehicleIDs", function(orig)
        return function(self, ...)
            local r = orig(self, ...)
            if type(r) == "table" and next(r) then
                table.insert(r, 1, CFG.baseVehicleID)
                return r
            end
            return { CFG.baseVehicleID }
        end
    end) then patched = patched + 1 end

    if wrap(i, "ShowThemeVehicle", function(orig)
        return function(self, ...)
            local ok = pcall(orig, self, CFG.baseVehicleID)
            return ok
        end
    end) then patched = patched + 1 end

    if wrap(i, "_ShowSelfVehicle", function(orig)
        return function(self, ...)
            local tries = {
                function() return orig(self, CFG.baseVehicleID, CFG.skinInsID) end,
                function() return orig(self, CFG.baseVehicleID, CFG.insID) end,
                function() return orig(self, CFG.baseVehicleID) end,
                function() return orig(self) end,
            }
            for _, fn in ipairs(tries) do
                if pcall(fn) then return true end
            end
            return false
        end
    end) then patched = patched + 1 end

    if wrap(i, "_CreateVehicleModel", function(orig)
        return function(self, ...)
            local tries = {
                function() return orig(self, CFG.baseVehicleID, CFG.skinInsID) end,
                function() return orig(self, CFG.baseVehicleID) end,
                function() return orig(self) end,
            }
            for _, fn in ipairs(tries) do
                if pcall(fn) then return true end
            end
            return false
        end
    end) then patched = patched + 1 end

    if wrap(i, "PreviewGarageVehicle", function(orig)
        return function(self, vehicleID, ...)
            return orig(self, CFG.baseVehicleID, ...)
        end
    end) then patched = patched + 1 end

    if wrap(i, "OnVehicleChange", function(orig)
        return function(self, vehicleID, ...)
            return orig(self, CFG.baseVehicleID, ...)
        end
    end) then patched = patched + 1 end

    if wrap(i, "OnGarageVehicleChange", function(orig)
        return function(self, vehicleID, ...)
            return orig(self, CFG.baseVehicleID, ...)
        end
    end) then patched = patched + 1 end
end)

-- ═══════════════════════════════════════════════════════════════════
-- SET vst_skin
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local DM = _G.DataMgr
    if DM and DM.roleData then
        DM.roleData.vst_skin = CFG.insID
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- FAKE DataMgr data
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local DM = _G.DataMgr
    if not DM then return end

    if type(DM.vehicleSkinInsIDTable) == "table" then
        DM.vehicleSkinInsIDTable[902] = CFG.insID
        DM.vehicleSkinInsIDTable[961] = CFG.skinInsID
    end

    if type(DM.VehicleSlotList) == "table" then
        DM.VehicleSlotList[902] = { [1] = CFG.insID }
        DM.VehicleSlotList[961] = { [1] = CFG.skinInsID }
    end

    if type(DM.defaultVehicleSkinResIDTable) == "table" then
        DM.defaultVehicleSkinResIDTable[902] = 1961001
        DM.defaultVehicleSkinResIDTable[961] = 1961001
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- MANUAL SPAWN
-- ═══════════════════════════════════════════════════════════════════
_G.V28_Spawn = function()
    local results = {}
    
    pcall(function()
        local DM = _G.DataMgr
        if DM and DM.roleData then
            DM.roleData.vst_skin = CFG.insID
            results[#results+1] = "✓ vst_skin set"
        end
    end)
    
    pcall(function()
        local M = require("client.logic.lobby.ThemeVehicleManager")
        local i = M and M.__inner_impl
        if not i then results[#results+1] = "✗ TVM not loaded" return end
        
        if type(i.ShowThemeVehicle) == "function" then
            local ok = pcall(i.ShowThemeVehicle, i, CFG.baseVehicleID)
            results[#results+1] = "ShowThemeVehicle(902): " .. (ok and "OK" or "ERR")
        end
        
        if type(i._ShowSelfVehicle) == "function" then
            local ok = pcall(i._ShowSelfVehicle, i, CFG.baseVehicleID, CFG.insID)
            results[#results+1] = "_ShowSelfVehicle: " .. (ok and "OK" or "ERR")
        end
        
        if type(i.RefreshSpecialEffect) == "function" then
            pcall(i.RefreshSpecialEffect, i)
            results[#results+1] = "✓ RefreshSpecialEffect"
        end
        
        if type(i._ReinitShowModelActor) == "function" then
            pcall(i._ReinitShowModelActor, i)
            results[#results+1] = "✓ _ReinitShowModelActor"
        end
        
        if type(i.SetVehicleTick) == "function" then
            pcall(i.SetVehicleTick, i, true)
            results[#results+1] = "✓ SetVehicleTick"
        end
    end)
    
    local txt = table.concat(results, "\n")
    S("v28_spawn.txt", txt)
    P("V28 SPAWN", txt)
    return txt
end

-- ═══════════════════════════════════════════════════════════════════
-- AUTO-BOOT SEQUENCE
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        -- 3 sec: dump mod system
        ticker.AddTimerOnce(3.0, function()
            pcall(_G.V28_DumpVehicleMod)
        end)
        -- 5 sec: dump vehicle data
        ticker.AddTimerOnce(5.0, function()
            pcall(_G.V28_DumpVehicleData)
        end)
        -- 7 sec: start trace
        ticker.AddTimerOnce(7.0, function()
            pcall(_G.V28_TraceStart)
        end)
        -- 8 sec: manual spawn try
        ticker.AddTimerOnce(8.0, function()
            pcall(_G.V28_Spawn)
        end)
    end
end)

-- Report
S("v28_report.txt",
    "v28 REPORT\n" ..
    "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n" ..
    "Reverted: " .. reverted .. "\n" ..
    "Base Vehicle: 902 (Coupe RB)\n" ..
    "Skin: 1961014 (McLaren)\n" ..
    "InsID: " .. CFG.insID .. "\n" ..
    "Patched: " .. patched .. "\n\n" ..
    "Commands:\n" ..
    "  V28_DumpVehicleMod()  -- find mod module\n" ..
    "  V28_DumpVehicleData() -- dump vehicle state\n" ..
    "  V28_TraceStart()      -- trace calls\n" ..
    "  V28_TraceStop()       -- stop + save\n" ..
    "  V28_Spawn()           -- manual spawn\n"
)

P("v28 LOADED",
    "McLaren + Full Dumper\n\n" ..
    "Auto-run:\n" ..
    "  3s → Mod dump\n" ..
    "  5s → Vehicle data dump\n" ..
    "  7s → Trace start\n" ..
    "  8s → Spawn try\n\n" ..
    "Garage kholo Coupe RB select karo.\n" ..
    "10 sec baad: V28_TraceStop()")

print("[V28] Loaded. Full dumper + trace active.")

return true
