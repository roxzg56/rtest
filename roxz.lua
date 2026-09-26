-- ═══════════════════════════════════════════════════════════════════
-- profile_pet_dump v2 — CORRECTED
-- Scans LobbyModuleConfig registry directly to find real paths
-- Focus: pet_manager, profileframe, socialcardframe, custom_presentation,
--        collect_pet_module, all wardrobe cosmetics
-- ═══════════════════════════════════════════════════════════════════

_G._PPDUMP2 = _G._PPDUMP2 or { phases = {}, last_state = nil, pc_attached = nil }

local DUMP_DIRS = {
    "/storage/emulated/0/Android/data/com.pubg.imobile/files/",
    "/storage/emulated/0/Android/data/com.vng.pubgmobile/files/",
    "/storage/emulated/0/Android/data/com.tencent.ig/files/",
    "/sdcard/",
}

local function _writeFile(name, content)
    for _, dir in ipairs(DUMP_DIRS) do
        local ok = false
        pcall(function()
            local f = io.open(dir .. name, "w")
            if f then f:write(content); f:close(); ok = true; print("[PPDUMP2] wrote " .. dir .. name) end
        end)
        if ok then return true end
    end
    return false
end

local function detectPhase()
    local phase
    pcall(function()
        if GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity() then
            phase = "lobby"
        elseif GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus() then
            phase = "match"
        end
    end)
    return phase
end

-- Deep value formatter (same as v1)
local function _dv(v, depth, maxDepth)
    depth, maxDepth = depth or 0, maxDepth or 3
    local t = type(v)
    if t == "nil"     then return "nil" end
    if t == "boolean" then return tostring(v) end
    if t == "number"  then return tostring(v) end
    if t == "string"  then
        if #v > 160 then return string.format("%q", v:sub(1, 157) .. "...") end
        return string.format("%q", v)
    end
    if t == "function" then return "<fn>" end
    if t == "userdata" then
        local name = "<ud>"
        pcall(function() if v.GetName then name = "<ud:" .. tostring(v:GetName()) .. ">" end end)
        return name
    end
    if t == "thread"   then return "<thread>" end
    if t == "table" then
        if depth >= maxDepth then
            local n = 0; for _ in pairs(v) do n = n + 1 end
            return "<tbl:" .. n .. ">"
        end
        local parts, i, n = {}, 0, 0
        for _ in pairs(v) do n = n + 1 end
        for k, val in pairs(v) do
            i = i + 1
            if i > 40 then parts[#parts + 1] = "...(+" .. (n - 40) .. ")"; break end
            parts[#parts + 1] = tostring(k) .. "=" .. _dv(val, depth + 1, maxDepth)
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return "<" .. t .. ">"
end

-- Dump a single module
local function dumpModule(buf, modPath, mod, deepInner)
    buf[#buf + 1] = ""
    buf[#buf + 1] = string.rep("─", 68)
    buf[#buf + 1] = "MODULE: " .. modPath
    buf[#buf + 1] = string.rep("─", 68)

    if not mod then
        buf[#buf + 1] = "  STATUS: NOT LOADED (nil)"
        return
    end
    if type(mod) ~= "table" then
        buf[#buf + 1] = "  STATUS: loaded, type = " .. type(mod)
        return
    end

    buf[#buf + 1] = "  STATUS: loaded (table)"
    local keys = {}
    for k in pairs(mod) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    buf[#buf + 1] = "  KEY COUNT: " .. #keys

    local fns, tbls, scalars, uds = {}, {}, {}, {}
    for _, k in ipairs(keys) do
        local v = mod[k]
        local vt = type(v)
        if vt == "function" then fns[#fns + 1] = k
        elseif vt == "table" then tbls[#tbls + 1] = k
        elseif vt == "userdata" then uds[#uds + 1] = k
        else scalars[#scalars + 1] = k end
    end

    if #fns > 0 then
        buf[#buf + 1] = ""
        buf[#buf + 1] = "  FUNCTIONS (" .. #fns .. "):"
        for _, k in ipairs(fns) do
            local info = ""
            pcall(function()
                local dbg = debug and debug.getinfo and debug.getinfo(mod[k], "S")
                if dbg then
                    if dbg.what == "C" then info = " [C]"
                    elseif dbg.source then
                        local src = dbg.source:gsub("^@", "")
                        if #src > 70 then src = "..." .. src:sub(-67) end
                        info = " [" .. src .. ":" .. tostring(dbg.linedefined or 0) .. "]"
                    end
                end
            end)
            buf[#buf + 1] = "    fn " .. tostring(k) .. info
        end
    end

    if #tbls > 0 then
        buf[#buf + 1] = ""
        buf[#buf + 1] = "  TABLES (" .. #tbls .. "):"
        for _, k in ipairs(tbls) do
            local v = mod[k]
            local n = 0; for _ in pairs(v) do n = n + 1 end
            buf[#buf + 1] = "    tbl " .. tostring(k) .. " (" .. n .. " keys)"
            buf[#buf + 1] = "      " .. _dv(v, 0, 4)
        end
    end

    if #uds > 0 then
        buf[#buf + 1] = ""
        buf[#buf + 1] = "  USERDATA (" .. #uds .. "):"
        for _, k in ipairs(uds) do
            buf[#buf + 1] = "    ud " .. tostring(k) .. " = " .. _dv(mod[k], 0, 1)
        end
    end

    if #scalars > 0 then
        buf[#buf + 1] = ""
        buf[#buf + 1] = "  SCALARS (" .. #scalars .. "):"
        for _, k in ipairs(scalars) do
            buf[#buf + 1] = "    " .. tostring(k) .. " = " .. _dv(mod[k], 0, 2)
        end
    end

    -- __inner_impl deep
    if type(mod.__inner_impl) == "table" then
        buf[#buf + 1] = ""
        buf[#buf + 1] = "  ▶ __inner_impl (deep):"
        local iimpl = mod.__inner_impl
        local ikeys = {}
        for k in pairs(iimpl) do ikeys[#ikeys + 1] = k end
        table.sort(ikeys, function(a, b) return tostring(a) < tostring(b) end)
        for _, ik in ipairs(ikeys) do
            local iv = iimpl[ik]
            if type(iv) == "function" then
                local info = ""
                pcall(function()
                    local dbg = debug and debug.getinfo and debug.getinfo(iv, "S")
                    if dbg and dbg.source then
                        local src = dbg.source:gsub("^@", "")
                        if #src > 70 then src = "..." .. src:sub(-67) end
                        info = " [" .. src .. ":" .. tostring(dbg.linedefined or 0) .. "]"
                    end
                end)
                buf[#buf + 1] = "    fn " .. tostring(ik) .. info
            else
                buf[#buf + 1] = "    " .. tostring(ik) .. " = " .. _dv(iv, 0, 3)
            end
        end
    end

    local mt = getmetatable(mod)
    if mt then
        buf[#buf + 1] = "  METATABLE: " .. _dv(mt, 0, 2)
    end
end

-- ─── KEY: resolve module via LobbyModuleConfig registry ───────────
local function resolveViaRegistry(keyName)
    local mod = nil
    pcall(function()
        if _G.ModuleManager and _G.ModuleManager.LobbyModuleConfig and _G.ModuleManager.LobbyModuleConfig[keyName] then
            local cfg = _G.ModuleManager.LobbyModuleConfig[keyName]
            local path = cfg.ModuleName
            mod = _G.ModuleManager.GetModule(cfg) or package.loaded[path]
            if not mod and path then
                -- try require
                local ok, r = pcall(require, path)
                if ok then mod = r end
            end
        end
    end)
    return mod
end

-- ─── PET DUMP (v2 — correct paths) ────────────────────────────────
local function buildPetDumpV2()
    local b = {}
    local function w(s) b[#b + 1] = tostring(s) end
    w("╔═══════════════════════════════════════════════════════════╗")
    w("║  PET DUMP v2 — REAL PATHS FROM REGISTRY")
    w("║  " .. os.date("%Y-%m-%d %H:%M:%S"))
    w("╚═══════════════════════════════════════════════════════════╝")
    w("")

    -- 1. Registry-based resolution (THE CORRECT WAY)
    w(string.rep("═", 68))
    w("REGISTRY-BASED PET MODULE RESOLUTION")
    w(string.rep("═", 68))
    local petKeys = {
        "pet_manager",
        "logic_pet_privilege_guide",
        "collect_pet_module",
    }
    for _, keyName in ipairs(petKeys) do
        w("")
        w("─── LobbyModuleConfig[" .. keyName .. "] ───")
        local cfg = nil
        pcall(function()
            cfg = _G.ModuleManager and _G.ModuleManager.LobbyModuleConfig
                and _G.ModuleManager.LobbyModuleConfig[keyName]
        end)
        if cfg then
            w("  cfg.ModuleName = " .. tostring(cfg.ModuleName))
            w("  cfg.KeyName    = " .. tostring(cfg.KeyName))
            w("  cfg.ModuleLevel= " .. tostring(cfg.ModuleLevel))
            local mod = resolveViaRegistry(keyName)
            if mod then
                w("  RESOLVED — dumping module:")
                dumpModule(b, keyName .. " (" .. tostring(cfg.ModuleName) .. ")", mod, true)
            else
                w("  RESOLVED → nil (module not instantiated yet)")
            end
        else
            w("  NOT REGISTERED in LobbyModuleConfig")
        end
    end

    -- 2. Direct package.loaded scan for pet-related
    w("")
    w(string.rep("═", 68))
    w("SCAN: package.loaded keys matching 'pet' or 'companion'")
    w(string.rep("═", 68))
    local hits = {}
    for k in pairs(package.loaded) do
        if type(k) == "string" then
            local lk = k:lower()
            if lk:find("pet") or lk:find("companion") then
                hits[#hits + 1] = k
            end
        end
    end
    table.sort(hits)
    if #hits == 0 then
        w("  NONE — pet modules lazy-loaded on first access")
    else
        for _, k in ipairs(hits) do
            w("  found: " .. k)
            pcall(dumpModule, b, k, package.loaded[k])
        end
    end

    -- 3. CDataTable pet tables
    w("")
    w(string.rep("═", 68))
    w("CDataTable — pet/companion tables")
    w(string.rep("═", 68))
    pcall(function()
        local candidates = {
            "Pet", "PetInfo", "PetSkin", "PetDress", "PetAction", "PetLevel",
            "PetUpgrade", "PetSkill", "PetAccessory", "PetVoice",
            "Companion", "CompanionSkin", "CompanionConfig",
            "Wingman", "WingmanSkin",
        }
        for _, tname in ipairs(candidates) do
            local cfg = CDataTable.GetTable(tname)
            if cfg then
                local n = 0; for _ in pairs(cfg) do n = n + 1 end
                w("  CDataTable[" .. tname .. "] = " .. n .. " entries")
                local i = 0
                for id, row in pairs(cfg) do
                    i = i + 1
                    if i > 5 then w("    ...(+" .. (n - 5) .. ")"); break end
                    w("    [" .. tostring(id) .. "] = " .. _dv(row, 0, 3))
                end
            else
                w("  CDataTable[" .. tname .. "] = NOT FOUND")
            end
        end
    end)

    -- 4. DataMgr pet fields
    w("")
    w(string.rep("═", 68))
    w("DataMgr — fields matching pet/companion/wingman")
    w(string.rep("═", 68))
    local dmHits = {}
    if _G.DataMgr then
        for k, v in pairs(_G.DataMgr) do
            if type(k) == "string" then
                local lk = k:lower()
                if lk:find("pet") or lk:find("companion") or lk:find("wingman") then
                    dmHits[#dmHits + 1] = k
                end
            end
        end
    end
    if #dmHits == 0 then
        w("  NONE")
    else
        table.sort(dmHits)
        for _, k in ipairs(dmHits) do
            w("  DataMgr." .. k .. " = " .. _dv(_G.DataMgr[k], 0, 4))
        end
    end

    _writeFile("pet_dump_v2_lobby.txt", table.concat(b, "\n"))
end

-- ─── PROFILE EXTENDED DUMP (missing modules from v1) ──────────────
local function buildProfileExtendedDumpV2()
    local b = {}
    local function w(s) b[#b + 1] = tostring(s) end
    w("╔═══════════════════════════════════════════════════════════╗")
    w("║  PROFILE EXTENDED DUMP v2 — modules missed in v1")
    w("║  " .. os.date("%Y-%m-%d %H:%M:%S"))
    w("╚═══════════════════════════════════════════════════════════╝")

    -- Registry-based resolution for missed modules
    local registryKeys = {
        -- Profile frames
        "logic_roleInfo_profileframe",
        "logic_roleInfo_socialcardframe",
        "logic_roleInfo_HonourCertificate",
        "logic_roleInfo_honor_title_select",
        "logic_roleInfo_weaponstrength_title_select",
        -- Real profile path
        "logic_profile",
        -- Person space extended
        "logic_custom_presentation",
        "logic_personalization_download",
        "logic_popular_gift_pk",
        "logic_popular_streak",
        "logic_popular_pk_result",
        -- Social lobby
        "Logic_SocialLobbyModule",
        "Logic_SocialLobbyEditMgrModule",
        "logic_module_social_person_space",
        -- Wardrobe cosmetics
        "logic_legend_weapon",
        "LogicMultiItemModule",
        "LogicParticleEmote",
        "LobbyIdleUnlock",
        "logic_outfit_combination",
        "logic_card_collect_wardrobe_show",
        "logic_wardrobe_wow_vehicle",
        "logic_wardrobe_wheel",
        "logic_wardrobe_tag_mgr",
        "red_point_manager",
        "wardrobe_red_point",
        -- Vehicle extended
        "LogicVehicleAccessory",
        "LogicVehicleExtendedFeature",
        "LogicVehicleDecalExchange",
        "LogicVehicleResDependencyUtil",
        "ThemeVehicleManager",
        "SportCarSystem",
        "VehicleCollectSystem",
        "vehicle_collect_manager",
        "upgradeVehicle",
        -- Glide
        "GlideSystem",
        -- Home/person space
        "logic_home_entry",
        "logic_home_status",
        "logic_home_door_plate",
        "logic_home_liveTogether_crystal",
        -- Emote
        "LobbyEmoteManager",
        "UniqueEmoteManager",
        -- Emote/misc
        "AvatarDataCenter",
        "AvatarCheckerModule",
    }

    for _, keyName in ipairs(registryKeys) do
        w("")
        w(string.rep("─", 68))
        w("REGISTRY KEY: " .. keyName)
        w(string.rep("─", 68))
        local cfg = nil
        pcall(function()
            cfg = _G.ModuleManager and _G.ModuleManager.LobbyModuleConfig
                and _G.ModuleManager.LobbyModuleConfig[keyName]
        end)
        if cfg then
            w("  ModuleName = " .. tostring(cfg.ModuleName))
            local mod = resolveViaRegistry(keyName)
            if mod then
                dumpModule(b, keyName .. " → " .. tostring(cfg.ModuleName), mod, true)
            else
                w("  RESOLVED → nil (not instantiated)")
                -- Try package.loaded fallback
                local direct = package.loaded[cfg.ModuleName]
                if direct then
                    w("  package.loaded[" .. cfg.ModuleName .. "] EXISTS:")
                    dumpModule(b, cfg.ModuleName, direct, true)
                end
            end
        else
            w("  NOT REGISTERED in LobbyModuleConfig")
        end
    end

    _writeFile("profile_extended_v2_lobby.txt", table.concat(b, "\n"))
end

-- ─── FULL REGISTRY SCAN (optional — dumps every registered module) ─
-- ⚠️ This generates a HUGE file. Only run manually.
_G.PPDumpFullRegistry = function()
    local b = {}
    local function w(s) b[#b + 1] = tostring(s) end
    w("╔═══════════════════════════════════════════════════════════╗")
    w("║  FULL LobbyModuleConfig REGISTRY DUMP")
    w("║  " .. os.date("%Y-%m-%d %H:%M:%S"))
    w("╚═══════════════════════════════════════════════════════════╝")

    local reg = nil
    pcall(function() reg = _G.ModuleManager and _G.ModuleManager.LobbyModuleConfig end)
    if not reg then w("  LobbyModuleConfig NOT AVAILABLE"); _writeFile("registry_full_dump.txt", table.concat(b, "\n")); return end

    local keys = {}
    for k in pairs(reg) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    w("  TOTAL REGISTERED KEYS: " .. #keys)

    for _, k in ipairs(keys) do
        local cfg = reg[k]
        w("")
        w("── " .. k .. " ──")
        if type(cfg) == "table" then
            w("   ModuleName  = " .. tostring(cfg.ModuleName))
            w("   KeyName     = " .. tostring(cfg.KeyName))
            w("   ModuleLevel = " .. tostring(cfg.ModuleLevel))
        else
            w("   cfg = " .. _dv(cfg, 0, 2))
        end
    end

    _writeFile("registry_full_dump.txt", table.concat(b, "\n"))
end

-- ─── FIRE ─────────────────────────────────────────────────────────
local function fire(phase, tag)
    if _G._PPDUMP2.phases[phase] then return false end
    if phase ~= "lobby" then return false end
    if not _G.DataMgr then return false end

    _G._PPDUMP2.phases[phase] = os.time()
    print("[PPDUMP2] FIRING [" .. phase .. "] (" .. tag .. ")")

    pcall(buildPetDumpV2)
    pcall(buildProfileExtendedDumpV2)

    print("[PPDUMP2] DONE — check pet_dump_v2_lobby.txt + profile_extended_v2_lobby.txt")
    return true
end

local function watchTick()
    local phase = detectPhase()
    if not phase then return end
    if phase ~= _G._PPDUMP2.last_state then
        print("[PPDUMP2] phase: " .. tostring(_G._PPDUMP2.last_state) .. " → " .. phase)
        _G._PPDUMP2.last_state = phase
    end
    if phase == "lobby" and not _G._PPDUMP2.phases.lobby then
        local key = "_phase_enter_lobby"
        if not _G._PPDUMP2[key] then
            _G._PPDUMP2[key] = os.time()
        elseif (os.time() - _G._PPDUMP2[key]) >= 4 then
            fire("lobby", "watchdog")
        end
    end
end

pcall(function()
    local p = detectPhase()
    if p == "lobby" then fire("lobby", "immediate") end
end)

pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerLoop then
        ticker.AddTimerLoop(0, watchTick, -1, 2.0)
        print("[PPDUMP2] watcher started (2s)")
    end
end)

pcall(function()
    local function attach()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if pc and slua.isValid(pc) and pc.AddGameTimer and pc ~= _G._PPDUMP2.pc_attached then
            _G._PPDUMP2.pc_attached = pc
            pc:AddGameTimer(2.0, true, watchTick)
        end
    end
    attach()
    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerLoop then
            ticker.AddTimerLoop(0, attach, -1, 5.0)
        end
    end)
end)

pcall(function()
    if EventSystem and EventSystem.registEvent then
        if EVENTTYPE_LOBBY and EVENTID_SHOW_LOBBY then
            EventSystem:registEvent(EVENTTYPE_LOBBY, EVENTID_SHOW_LOBBY, function()
                pcall(function()
                    local ticker = require("common.time_ticker")
                    if ticker and ticker.AddTimerOnce then
                        ticker.AddTimerOnce(4.0, watchTick)
                    end
                end)
            end)
        end
    end
end)

_G.PP2Status = function()
    print("=== PPDUMP2 STATUS ===")
    print("last_state:", _G._PPDUMP2.last_state or "nil")
    for p, t in pairs(_G._PPDUMP2.phases) do
        print("  " .. p .. " → " .. os.date("%H:%M:%S", t))
    end
end

_G.PP2Force = function()
    _G._PPDUMP2.phases.lobby = nil
    _G._PPDUMP2._phase_enter_lobby = os.time() - 10
    fire("lobby", "forced")
end

_G.PP2Reset = function()
    _G._PPDUMP2.phases = {}
    _G._PPDUMP2.last_state = nil
    print("[PPDUMP2] reset")
end

print("[profile_pet_dump v2] loaded — registry-based, correct paths")
