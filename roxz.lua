-- ═══════════════════════════════════════════════════════════════════
-- v23.1 — SPAWN DISCOVERY
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
    if t == "string" then return #v > 60 and ('"'..v:sub(1,57)..'..."') or ('"'..v..'"') end
    if t == "function" then return "<fn>" end
    if t == "userdata" then return "<ud>" end
    if t == "table" then
        local p, i, n = {}, 0, 0
        for _ in pairs(v) do n = n + 1 end
        for k, val in pairs(v) do
            i = i + 1
            if i > 12 then p[#p+1] = "...(+"..(n-12)..")"; break end
            p[#p+1] = tostring(k).."="..V(val,d+1,m)
        end
        return "{"..table.concat(p,",").."}"
    end
    return "<"..t..">"
end

-- ═══════════════════════════════════════════════════════════════════
-- DIAG 1: FULL DUMP ThemeVehicleManager
-- ═══════════════════════════════════════════════════════════════════
_G.V23Dump = function()
    local out = {}
    local function w(s) out[#out+1] = tostring(s) end
    w("═══ THEME VEHICLE MANAGER DUMP ═══")
    w("Time: " .. os.date("%Y-%m-%d %H:%M:%S"))
    w("")

    local M = require("client.logic.lobby.ThemeVehicleManager")
    if type(M) ~= "table" then w("NOT LOADED") S("v23_dump.txt", table.concat(out,"\n")) return end
    w("Module type: table")
    w("Module keys: " .. (function() local n=0 for _ in pairs(M) do n=n+1 end return n end)())
    w("")

    -- Top level
    w("── TOP LEVEL FIELDS ──")
    for k, v in pairs(M) do
        local vt = type(v)
        w("  [" .. vt .. "] " .. tostring(k) .. " = " .. V(v, 0, 2))
    end

    -- Inner impl
    local i = M.__inner_impl
    if type(i) ~= "table" then
        w("__inner_impl NOT TABLE")
        S("v23_dump.txt", table.concat(out,"\n"))
        return
    end
    w("")
    w("── __inner_impl FIELDS ──")
    local fns, tbls, scals = {}, {}, {}
    for k, v in pairs(i) do
        local vt = type(v)
        if vt == "function" then
            fns[#fns+1] = k
        elseif vt == "table" then
            tbls[#tbls+1] = k
        else
            scals[#scals+1] = k
        end
    end
    table.sort(fns, function(a,b) return tostring(a)<tostring(b) end)
    table.sort(tbls, function(a,b) return tostring(a)<tostring(b) end)

    w("")
    w("── FUNCTIONS (" .. #fns .. ") ──")
    for _, k in ipairs(fns) do
        local info = debug.getinfo(i[k], "S")
        local src = info and (info.short_src or "?") or "?"
        local ln = info and info.linedefined or 0
        w(string.format("  %s  (%s:%d)", tostring(k), tostring(src), ln))
    end

    w("")
    w("── TABLES (" .. #tbls .. ") ──")
    for _, k in ipairs(tbls) do
        local v = i[k]
        local n = 0
        for _ in pairs(v) do n = n + 1 end
        w(string.format("  %s (size=%d) = %s", tostring(k), n, V(v, 0, 3)))
    end

    w("")
    w("── SCALARS (" .. #scals .. ") ──")
    for _, k in ipairs(scals) do
        w(string.format("  %s = %s", tostring(k), V(i[k], 0, 2)))
    end

    -- Also check instance via ModuleManager
    w("")
    w("── INSTANCE CHECK ──")
    pcall(function()
        local MM = _G.ModuleManager
        if MM and type(MM.GetModule) == "function" and MM.LobbyModuleConfig then
            for key, cfg in pairs(MM.LobbyModuleConfig) do
                if type(cfg) == "table" and tostring(cfg.ModuleName or ""):find("ThemeVehicle") then
                    w("Found cfg: " .. tostring(key))
                    local ok, inst = pcall(MM.GetModule, MM, cfg)
                    w("  GetModule → " .. (ok and type(inst) or "ERR"))
                    if ok and type(inst) == "table" then
                        local n = 0
                        for _ in pairs(inst) do n = n + 1 end
                        w("  instance keys: " .. n)
                        -- Check data fields
                        for _, fn in ipairs({ "Vehicles", "RepeatTags", "_tVehicles",
                                             "_vehicles", "VehicleList", "curVehicle" }) do
                            if inst[fn] ~= nil then
                                w("  inst." .. fn .. " = " .. V(inst[fn], 0, 2))
                            end
                        end
                    end
                end
            end
        end
    end)

    local txt = table.concat(out, "\n")
    S("v23_dump.txt", txt)
    P("V23 DUMP", "Saved: v23_dump.txt\n" .. #txt .. " bytes")
end

-- ═══════════════════════════════════════════════════════════════════
-- DIAG 2: TRACE ALL CALLS in ThemeVehicleManager
-- ═══════════════════════════════════════════════════════════════════
_G._V23TraceLog = {}
_G._V23TraceActive = false

_G.V23TraceStart = function()
    if _G._V23TraceActive then P("V23", "Trace already active") return end
    _G._V23TraceActive = true
    _G._V23TraceLog = {}

    local function log(s)
        _G._V23TraceLog[#_G._V23TraceLog+1] = string.format("[%s] %s", os.date("%H:%M:%S"), s)
    end

    log("=== TRACE STARTED ===")

    -- Hook ThemeVehicleManager
    pcall(function()
        local M = require("client.logic.lobby.ThemeVehicleManager")
        local i = M and M.__inner_impl
        if not i then return end
        for k, fn in pairs(i) do
            if type(fn) == "function" and type(k) == "string" then
                local orig = fn
                i[k] = function(self, ...)
                    local args = {}
                    for n = 1, math.min(5, select("#", ...)) do
                        local v = select(n, ...)
                        if type(v) == "table" then args[#args+1] = "tbl"
                        else args[#args+1] = tostring(v):sub(1, 40) end
                    end
                    log("TVM:" .. tostring(k) .. "(" .. table.concat(args, ",") .. ")")
                    local ok, r = pcall(orig, self, ...)
                    if not ok then
                        log("  ERR: " .. tostring(r):sub(1, 100))
                    elseif r ~= nil then
                        log("  RET: " .. V(r, 0, 1))
                    end
                    return r
                end
            end
        end
        log("Hooked ThemeVehicleManager functions")
    end)

    -- Hook VehicleCollectSystem
    pcall(function()
        local M = require("client.logic.vehicle.VehicleCollectSystem")
        local i = M and M.__inner_impl
        if not i then return end
        for k, fn in pairs(i) do
            if type(fn) == "function" and type(k) == "string" then
                local orig = fn
                i[k] = function(self, ...)
                    local args = {}
                    for n = 1, math.min(5, select("#", ...)) do
                        local v = select(n, ...)
                        if type(v) == "table" then args[#args+1] = "tbl"
                        else args[#args+1] = tostring(v):sub(1, 40) end
                    end
                    log("VCS:" .. tostring(k) .. "(" .. table.concat(args, ",") .. ")")
                    local ok, r = pcall(orig, self, ...)
                    if not ok then log("  ERR: " .. tostring(r):sub(1, 100))
                    elseif r ~= nil then log("  RET: " .. V(r, 0, 1)) end
                    return r
                end
            end
        end
        log("Hooked VehicleCollectSystem functions")
    end)

    -- Hook lobby module
    pcall(function()
        local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
        local i = M and M.__inner_impl
        if not i then return end
        for k, fn in pairs(i) do
            if type(fn) == "function" and type(k) == "string" then
                local lk = k:lower()
                if lk:find("vehicle") or lk:find("car") or lk:find("scene") then
                    local orig = fn
                    i[k] = function(self, ...)
                        log("SLM:" .. tostring(k))
                        local ok, r = pcall(orig, self, ...)
                        if not ok then log("  ERR: " .. tostring(r):sub(1, 100)) end
                        return r
                    end
                end
            end
        end
        log("Hooked SocialLobbyModule (vehicle-related)")
    end)

    -- Auto-save every 15s
    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerLoop then
            ticker.AddTimerLoop(0, function()
                if not _G._V23TraceActive then return end
                pcall(function()
                    S("v23_trace.txt", table.concat(_G._V23TraceLog, "\n"))
                end)
            end, -1, 15.0)
        end
    end)

    P("V23 TRACE", "Started. Now:\n1. Go to lobby\n2. Open garage\n3. Select a car\n4. Wait 10s\n5. Then call V23TraceStop()")
end

_G.V23TraceStop = function()
    _G._V23TraceActive = false
    local txt = table.concat(_G._V23TraceLog or {}, "\n")
    S("v23_trace.txt", txt)
    P("V23 TRACE", "Saved: v23_trace.txt\nLines: " .. #(_G._V23TraceLog or {}))
end

-- ═══════════════════════════════════════════════════════════════════
-- DIAG 3: Test spawn with every vehicle ID and see what works
-- ═══════════════════════════════════════════════════════════════════
_G.V23TestAll = function()
    local M = require("client.logic.lobby.ThemeVehicleManager")
    local i = M and M.__inner_impl
    if not i then P("V23", "Module not loaded") return end

    local testIDs = { 901, 903, 904, 905, 906, 907, 908, 910, 930, 960, 961 }
    local results = {}
    for _, vid in ipairs(testIDs) do
        local fnResults = {}
        for _, fnName in ipairs({
            "ShowThemeVehicle", "_ShowSelfVehicle", "_CreateVehicleModel",
            "_TryCreateVehicleModel", "PreviewGarageVehicle", "OnVehicleChange"
        }) do
            if type(i[fnName]) == "function" then
                local ok, err = pcall(i[fnName], i, vid)
                fnResults[#fnResults+1] = fnName .. "=" .. (ok and "OK" or "ERR")
            else
                fnResults[#fnResults+1] = fnName .. "=NIL"
            end
        end
        results[#results+1] = "ID " .. vid .. ": " .. table.concat(fnResults, " ")
    end

    local txt = table.concat(results, "\n")
    S("v23_test_all.txt", txt)
    P("V23 TEST ALL", "Check v23_test_all.txt\n" .. #testIDs .. " IDs tested")
end

-- ═══════════════════════════════════════════════════════════════════
-- DIAG 4: What does the game call when opening garage?
-- Check data structures used in spawn
-- ═══════════════════════════════════════════════════════════════════
_G.V23CheckData = function()
    local out = {}
    local function w(s) out[#out+1] = tostring(s) end
    w("═══ SPAWN DATA CHECK ═══")

    -- DataMgr vehicle-related
    pcall(function()
        local DM = _G.DataMgr
        if DM then
            for _, k in ipairs({ "roleData", "VehicleSlotList", "vst_skin",
                                 "vehicleSkinInsIDTable", "defaultVehicleSkinResIDTable",
                                 "defaultVehicleSkinResID", "curVehicle" }) do
                if DM[k] ~= nil then
                    w("DM." .. k .. " = " .. V(DM[k], 0, 3))
                end
            end
            if DM.roleData then
                for k, v in pairs(DM.roleData) do
                    local lk = tostring(k):lower()
                    if lk:find("vehicle") or lk:find("car") or lk:find("vst") then
                        w("DM.roleData." .. tostring(k) .. " = " .. V(v, 0, 3))
                    end
                end
            end
        end
    end)

    -- Check the actual Vehicle UI modules
    pcall(function()
        for _, path in ipairs({
            "client.logic.lobby.GarageThemeSystem",
            "client.logic.vehicle.SportCarSystem",
            "client.logic.lobby.LobbyThemeManager",
            "client.slua.umg.NewSetting.GraphicsNew.LogicFPSAutoAdjust",
        }) do
            local ok, M = pcall(require, path)
            if ok and M ~= nil then
                w("Module exists: " .. path)
            end
        end
    end)

    local txt = table.concat(out, "\n")
    S("v23_datacheck.txt", txt)
    P("V23 DATACHECK", "Saved: v23_datacheck.txt")
end

-- ═══════════════════════════════════════════════════════════════════
-- Auto-run dump + trace
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(3.0, function()
            pcall(_G.V23Dump)
        end)
        ticker.AddTimerOnce(5.0, function()
            pcall(_G.V23CheckData)
        end)
        ticker.AddTimerOnce(8.0, function()
            pcall(_G.V23TraceStart)
            P("V23 READY", "Files auto-saved:\n- v23_dump.txt\n- v23_datacheck.txt\n\nTrace active.\n\nGo lobby → open garage.\nWait 10s.\nThen V23TraceStop()")
        end)
    end
end)

print("[V23.1] Discovery loaded. Auto-dump in 3s+5s+8s.")

return true
