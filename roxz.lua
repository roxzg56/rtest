-- ═══════════════════════════════════════════════════════════════════
-- v32 — GRAND DEBUT DUMP + TRACE
-- Target: Vehicle Mod System + Grand Debut box opening animation
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
    if t == "string" then return #v > 70 and ('"'..v:sub(1,67)..'..."') or ('"'..v..'"') end
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
-- DUMP 1: SEARCH — Vehicle Mod System modules
-- ═══════════════════════════════════════════════════════════════════
_G.V32_Dump1_SearchModules = function()
    local out = {}
    local function w(s) out[#out+1] = tostring(s) end
    w("╔═══════════════════════════════════════════════════════════╗")
    w("║  VEHICLE MOD SYSTEM — MODULE SEARCH")
    w("║  Time: " .. os.date("%Y-%m-%d %H:%M:%S"))
    w("╚═══════════════════════════════════════════════════════════╝")
    w("")

    local KEYWORDS = {
        "vehiclemod", "modsystem", "granddebut", "debut",
        "vehiclemodify", "carmod", "collectionreward",
        "collectreward", "unlockreward", "vehiclecollect",
        "vehicleunlock", "premiumvehicle", "tierreward",
    }

    -- Search package.loaded
    w("═══ package.loaded (all matches) ═══")
    local matched = {}
    for path, mod in pairs(package.loaded) do
        if type(path) == "string" and type(mod) == "table" then
            local lk = path:lower()
            for _, kw in ipairs(KEYWORDS) do
                if lk:find(kw) then
                    matched[#matched+1] = path
                    break
                end
            end
        end
    end
    table.sort(matched)
    for _, m in ipairs(matched) do
        w("  " .. m)
    end
    w("  Total: " .. #matched)
    w("")

    -- LobbyModuleConfig
    w("═══ ModuleManager.LobbyModuleConfig ═══")
    pcall(function()
        local MM = _G.ModuleManager
        if MM and MM.LobbyModuleConfig then
            for key, cfg in pairs(MM.LobbyModuleConfig) do
                if type(cfg) == "table" and type(cfg.ModuleName) == "string" then
                    local lk = cfg.ModuleName:lower()
                    for _, kw in ipairs(KEYWORDS) do
                        if lk:find(kw) then
                            w("  " .. tostring(key) .. " = " .. cfg.ModuleName)
                            break
                        end
                    end
                end
            end
        end
    end)

    -- CommonModuleConfig
    w("")
    w("═══ ModuleManager.CommonModuleConfig ═══")
    pcall(function()
        local MM = _G.ModuleManager
        if MM and MM.CommonModuleConfig then
            for key, cfg in pairs(MM.CommonModuleConfig) do
                if type(cfg) == "table" and type(cfg.ModuleName) == "string" then
                    local lk = cfg.ModuleName:lower()
                    for _, kw in ipairs(KEYWORDS) do
                        if lk:find(kw) then
                            w("  " .. tostring(key) .. " = " .. cfg.ModuleName)
                            break
                        end
                    end
                end
            end
        end
    end)

    local txt = table.concat(out, "\n")
    S("v32_search.txt", txt)
    print(txt)
    P("V32 SEARCH", "Saved: v32_search.txt")
    return txt
end

-- ═══════════════════════════════════════════════════════════════════
-- DUMP 2: DETAILED — every matched module ka full structure
-- ═══════════════════════════════════════════════════════════════════
_G.V32_Dump2_Details = function()
    local out = {}
    local function w(s) out[#out+1] = tostring(s) end
    w("═══ DETAILED MODULE DUMP ═══")
    w("Time: " .. os.date("%Y-%m-%d %H:%M:%S"))
    w("")

    local KEYWORDS = {
        "vehiclemod", "modsystem", "granddebut", "debut",
        "vehiclemodify", "carmod", "collectionreward",
        "vehiclecollect", "tierreward",
    }

    local checked = 0
    for path, mod in pairs(package.loaded) do
        if type(path) == "string" and type(mod) == "table" then
            local lk = path:lower()
            local isMatch = false
            for _, kw in ipairs(KEYWORDS) do
                if lk:find(kw) then isMatch = true break end
            end

            if isMatch then
                checked = checked + 1
                w("")
                w("══════════════════════════════════════════════")
                w("MODULE: " .. path)
                w("══════════════════════════════════════════════")
                
                -- Top-level
                w("── TOP LEVEL ──")
                for k, v in pairs(mod) do
                    if type(k) == "string" and not k:match("^__") then
                        w("  [" .. type(v) .. "] " .. tostring(k) .. " = " .. V(v, 0, 1))
                    end
                end
                
                -- Inner impl
                local i = mod.__inner_impl
                if type(i) == "table" then
                    w("")
                    w("── __inner_impl ──")
                    local fns, tbls = {}, {}
                    for k, v in pairs(i) do
                        if type(v) == "function" then fns[#fns+1] = k
                        elseif type(v) == "table" then
                            local n = 0; for _ in pairs(v) do n = n + 1 end
                            tbls[#tbls+1] = k .. "(" .. n .. ")"
                        end
                    end
                    table.sort(fns, function(a,b) return tostring(a)<tostring(b) end)
                    table.sort(tbls, function(a,b) return tostring(a)<tostring(b) end)
                    
                    w("  FUNCTIONS (" .. #fns .. "):")
                    for _, fn in ipairs(fns) do
                        local info = debug.getinfo(i[fn], "S")
                        w("    fn " .. tostring(fn) .. " (" .. 
                          (info and info.linedefined or "?") .. ")")
                    end
                    
                    w("  TABLES (" .. #tbls .. "):")
                    for _, t in ipairs(tbls) do
                        w("    tbl " .. t)
                    end
                end
            end
        end
    end

    w("")
    w("Total modules checked: " .. checked)

    local txt = table.concat(out, "\n")
    S("v32_details.txt", txt)
    print(txt)
    P("V32 DETAILS", "Saved: v32_details.txt")
    return txt
end

-- ═══════════════════════════════════════════════════════════════════
-- ⭐ TRACE: Capture Grand Debut click sequence
-- ═══════════════════════════════════════════════════════════════════
_G._V32_TraceLog = {}
_G._V32_TraceActive = false

_G.V32_TraceStart = function()
    if _G._V32_TraceActive then
        P("V32", "Already tracing")
        return
    end
    _G._V32_TraceActive = true
    _G._V32_TraceLog = {}

    local function log(s)
        _G._V32_TraceLog[#_G._V32_TraceLog+1] = 
            string.format("[%s] %s", os.date("%H:%M:%S"), s)
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
                        else args[#args+1] = tostring(v):sub(1, 30) end
                    end
                    log("TVM." .. tostring(k) .. "(" .. table.concat(args, ",") .. ")")
                    local ok, r = pcall(orig, self, ...)
                    if not ok then log("  ✗ " .. tostring(r):sub(1, 150))
                    elseif r ~= nil then log("  ↳ " .. V(r, 0, 1)) end
                    return r
                end
            end
        end
        log("Hooked ThemeVehicleManager")
    end)

    -- Hook Vehicle Mod modules
    for path, mod in pairs(package.loaded) do
        if type(path) == "string" and type(mod) == "table" then
            local lk = path:lower()
            if lk:find("vehiclemod") or lk:find("granddebut") 
               or lk:find("modsystem") or lk:find("carmod") then
                local inner = mod.__inner_impl or mod
                if type(inner) == "table" then
                    for k, fn in pairs(inner) do
                        if type(fn) == "function" and type(k) == "string" then
                            local orig = fn
                            inner[k] = function(self, ...)
                                local args = {}
                                for n = 1, math.min(5, select("#", ...)) do
                                    local v = select(n, ...)
                                    if type(v) == "table" then args[#args+1] = "tbl"
                                    else args[#args+1] = tostring(v):sub(1, 30) end
                                end
                                log(path:sub(-30) .. "." .. tostring(k) .. "(" .. 
                                    table.concat(args, ",") .. ")")
                                local ok, r = pcall(orig, self, ...)
                                if not ok then log("  ✗ " .. tostring(r):sub(1, 150))
                                elseif r ~= nil then log("  ↳ " .. V(r, 0, 1)) end
                                return r
                            end
                        end
                    end
                end
            end
        end
    end

    -- Hook MiniTVActor / LobbyVehicle related
    for _, path in ipairs({
        "client.lobby_ue_object.Actor.MiniTV.MiniTVActor",
        "client.lobby_ue_object.Actor.LobbyVehicle",
        "client.lobby_ue_object.Actor.LobbyPawn",
    }) do
        pcall(function()
            local M = require(path)
            local i = M and M.__inner_impl
            if type(i) ~= "table" then return end
            for k, fn in pairs(i) do
                if type(fn) == "function" and type(k) == "string" then
                    local lk = k:lower()
                    if lk:find("drop") or lk:find("spawn") or lk:find("crate")
                       or lk:find("anim") or lk:find("open") or lk:find("show")
                       or lk:find("vehicle") or lk:find("debut") then
                        local orig = fn
                        i[k] = function(self, ...)
                            log(path:sub(-25) .. "." .. tostring(k))
                            local ok, r = pcall(orig, self, ...)
                            if not ok then log("  ✗ " .. tostring(r):sub(1, 100))
                            end
                            return r
                        end
                    end
                end
            end
        end)
    end

    log("=== HOOKS READY ===")

    -- Auto-save
    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerLoop then
            ticker.AddTimerLoop(0, function()
                if _G._V32_TraceActive and #_G._V32_TraceLog > 0 then
                    S("v32_trace.txt", table.concat(_G._V32_TraceLog, "\n"))
                end
            end, -1, 8.0)
        end
    end)

    P("V32 TRACE ON",
        "Trace active.\n\n" ..
        "NOW:\n" ..
        "1. Vehicle Mod System kholo\n" ..
        "2. Grand Debut tier click karo\n" ..
        "3. Box khulne ka animation dekho\n" ..
        "4. Wait 10 sec\n" ..
        "5. V32_TraceStop()")
end

_G.V32_TraceStop = function()
    _G._V32_TraceActive = false
    local txt = table.concat(_G._V32_TraceLog or {}, "\n")
    S("v32_trace.txt", txt)
    P("V32 TRACE STOP", 
        "Saved: v32_trace.txt\n" ..
        "Lines: " .. #(_G._V32_TraceLog or {}))
end

-- ═══════════════════════════════════════════════════════════════════
-- AUTO-RUN SEQUENCE
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(2.0, function()
            pcall(_G.V32_Dump1_SearchModules)
        end)
        ticker.AddTimerOnce(4.0, function()
            pcall(_G.V32_Dump2_Details)
        end)
        ticker.AddTimerOnce(6.0, function()
            pcall(_G.V32_TraceStart)
        end)
    end
end)

print("[V32] Loaded. Auto-dump + trace start in 6s.")
P("v32 LOADED",
    "Grand Debut Dumper\n\n" ..
    "Auto:\n" ..
    "  2s → Search modules\n" ..
    "  4s → Detail dump\n" ..
    "  6s → Trace start\n\n" ..
    "Phir:\n" ..
    "1. Mod System kholo\n" ..
    "2. Grand Debut click karo\n" ..
    "3. Wait 10 sec\n" ..
    "4. V32_TraceStop()")

return true
