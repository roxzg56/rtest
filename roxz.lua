-- ═══════════════════════════════════════════════════════════════════
-- INSTANCE HUNTER v7 — Find instance anywhere in game memory
-- ═══════════════════════════════════════════════════════════════════

local DIR = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"

local function POPUP(t, m)
    pcall(function()
        local M = package.loaded["client.slua.logic.common.logic_common_msg_box"]
            or (pcall(require, "client.slua.logic.common.logic_common_msg_box")
                and require("client.slua.logic.common.logic_common_msg_box"))
        if M and M.Show then M.Show(1, tostring(t), tostring(m), function() end, function() end, "OK", "CLOSE") end
    end)
end

local function W(name, content)
    local f, err = io.open(DIR .. name, "w")
    if not f then return false, err end
    f:write(content or ""); f:close()
    return true
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
            if i > 15 then p[#p+1] = "...(+" .. (n-15) .. ")"; break end
            p[#p+1] = tostring(k) .. "=" .. V(val, d+1, m)
        end
        return "{" .. table.concat(p, ",") .. "}"
    end
    return "<" .. t .. ">"
end

-- ═══════════════════════════════════════════════════════════════════
-- HUNTER: find every table that has SetCurUId / GetCurUId as functions
-- ═══════════════════════════════════════════════════════════════════
_G.InstanceHunter = function()
    local out = {}
    local function w(s) out[#out+1] = tostring(s) end
    w("═══ INSTANCE HUNTER v7 ═══")
    w("Time: " .. os.date("%Y-%m-%d %H:%M:%S"))
    w("")

    -- METHOD 1: ModuleManager.GetModule with various call styles
    w("═══ METHOD 1: ModuleManager.GetModule ═══")
    local MM = _G.ModuleManager
    if type(MM) == "table" then
        w("ModuleManager type: table")
        w("GetModule type: " .. type(MM.GetModule))
        w("LobbyModuleConfig type: " .. type(MM.LobbyModuleConfig))
        
        if type(MM.LobbyModuleConfig) == "table" then
            for key, cfg in pairs(MM.LobbyModuleConfig) do
                if type(cfg) == "table" and type(cfg.ModuleName) == "string" 
                   and cfg.ModuleName:find("SocialLobby") then
                    w("  Found cfg: " .. tostring(key) .. " → " .. cfg.ModuleName)
                    -- Try different call styles
                    local tries = {
                        { "MM:GetModule(cfg)", function() return MM:GetModule(cfg) end },
                        { "MM.GetModule(MM, cfg)", function() return MM.GetModule(MM, cfg) end },
                        { "MM.GetModule(cfg)", function() return MM.GetModule(cfg) end },
                        { "MM:GetModule(cfg.KeyName)", function() return MM:GetModule(cfg.KeyName) end },
                        { "MM:GetModule(cfg.ModuleName)", function() return MM:GetModule(cfg.ModuleName) end },
                    }
                    for _, t in ipairs(tries) do
                        local ok, r = pcall(t[2])
                        w("  " .. t[1] .. " → " .. (ok and type(r) or ("ERR:"..tostring(r):sub(1,80))))
                        if ok and type(r) == "table" then
                            local n = 0; for _ in pairs(r) do n = n + 1 end
                            w("    KEYS: " .. n)
                            -- Check for data field
                            if r._tOthersSocialDataMap ~= nil then
                                w("    ✓ HAS _tOthersSocialDataMap")
                                w("    " .. V(r._tOthersSocialDataMap, 0, 2))
                            end
                        end
                    end
                end
            end
        end
    else
        w("ModuleManager NOT a table")
    end

    -- METHOD 2: Scan package.loaded for module files
    w("")
    w("═══ METHOD 2: Scan package.loaded ═══")
    for path, mod in pairs(package.loaded) do
        if type(path) == "string" and path:find("SocialLobby") then
            w("  " .. path .. " = " .. type(mod))
            if type(mod) == "table" then
                local n = 0; for _ in pairs(mod) do n = n + 1 end
                w("    keys: " .. n)
            end
        end
    end

    -- METHOD 3: Deep scan _G for tables with SetCurUId function
    w("")
    w("═══ METHOD 3: Deep scan _G for instance-like tables ═══")
    local candidates = {}
    local function checkTable(t, name, depth)
        if depth > 3 then return end
        if type(t) ~= "table" then return end
        if candidates[t] then return end
        candidates[t] = name
        -- Check signature
        if type(t.SetCurUId) == "function" or type(t.GetCurUId) == "function"
           or type(t.GetSlotDataBySlotTypeAndIndex) == "function" then
            w("  ✓ CANDIDATE: " .. name)
            w("    SetCurUId=" .. type(t.SetCurUId) .. 
              " GetCurUId=" .. type(t.GetCurUId) ..
              " GetSlotData=" .. type(t.GetSlotDataBySlotTypeAndIndex))
            w("    _tOthersSocialDataMap=" .. type(t._tOthersSocialDataMap))
        end
    end
    
    for k, v in pairs(_G) do
        if type(k) == "string" then
            checkTable(v, "_G." .. k, 1)
        end
    end

    -- METHOD 4: scan known game-wide containers
    w("")
    w("═══ METHOD 4: Known containers ═══")
    local containers = { "Game", "GameplayData", "UIManager", "UIManagerInstance",
                          "slua_GameFrontendHUD", "GameFrontendHUD", "Client",
                          "EventSystem", "PlayerController", "LocalPlayer" }
    for _, cn in ipairs(containers) do
        local c = _G[cn]
        if c ~= nil then
            w("  _G." .. cn .. " = " .. type(c))
            if type(c) == "table" then
                for k, v in pairs(c) do
                    if type(k) == "string" and type(v) == "table" then
                        if type(v.SetCurUId) == "function" or type(v.GetSlotDataBySlotTypeAndIndex) == "function" then
                            w("    ✓ " .. cn .. "." .. k .. " has slot signature")
                        end
                    end
                end
            end
        end
    end

    -- METHOD 5: Search through all LobbyModuleConfig-loaded modules
    w("")
    w("═══ METHOD 5: All LobbyModuleConfig instances ═══")
    if MM and type(MM.LobbyModuleConfig) == "table" and type(MM.GetModule) == "function" then
        local found = 0
        for key, cfg in pairs(MM.LobbyModuleConfig) do
            local ok, inst = pcall(MM.GetModule, MM, cfg)
            if ok and type(inst) == "table" then
                if type(inst.SetCurUId) == "function" 
                   or type(inst.GetSlotDataBySlotTypeAndIndex) == "function"
                   or type(inst.SetSlotUnlocked) == "function" then
                    w("  ✓ " .. tostring(key) .. " → instance has slot signature")
                    w("    " .. V(inst, 0, 1))
                    found = found + 1
                end
            end
        end
        w("  Found: " .. found .. " instances")
    end

    -- METHOD 6: Hook metamethods / __index to catch instance creation
    w("")
    w("═══ METHOD 6: Module class analysis ═══")
    local M = package.loaded["client.slua.logic.lobby.Left.Logic_SocialLobbyModule"]
    if type(M) == "table" then
        w("M type: table")
        w("M.__class: " .. type(M.__class))
        w("M.__instance: " .. type(M.__instance))
        w("M.instance: " .. type(M.instance))
        
        -- Check metatable
        local mt = getmetatable(M)
        if mt then
            w("M metatable: " .. V(mt, 0, 2))
            if mt.__call then w("  mt.__call = " .. tostring(mt.__call)) end
            if mt.__index then w("  mt.__index = " .. type(mt.__index)) end
        end
        
        -- Check __class
        if type(M.__class) == "table" then
            w("M.__class keys:")
            local i = 0
            for k, v in pairs(M.__class) do
                i = i + 1
                if i > 20 then break end
                w("  " .. tostring(k) .. " = " .. type(v))
            end
            -- Is there a constructor?
            if type(M.__class.ctor) == "function" then
                w("  ✓ M.__class.ctor exists")
            end
            if type(M.__class.new) == "function" then
                w("  ✓ M.__class.new exists")
            end
        end
    end

    local txt = table.concat(out, "\n")
    W("instance_hunter.txt", txt)
    print(txt)
    return txt
end

-- ═══════════════════════════════════════════════════════════════════
-- MEMORY HOOK — catch instance when it's created
-- ═══════════════════════════════════════════════════════════════════
_G.HookInstanceCreation = function()
    local M = package.loaded["client.slua.logic.lobby.Left.Logic_SocialLobbyModule"]
    if type(M) ~= "table" then print("[HOOK] M not loaded") return end

    -- Hook __class metatable
    if type(M.__class) == "table" then
        local cls = M.__class
        local mt = getmetatable(cls)
        if mt and type(mt.__call) == "function" then
            local origCall = mt.__call
            mt.__call = function(...)
                local inst = origCall(...)
                if type(inst) == "table" then
                    _G._SocialLobbyInstance = inst
                    print("[HOOK] Instance created! _G._SocialLobbyInstance set")
                    POPUP("INSTANCE CAUGHT", "Instance created!\nNow use InstInjectSlots()")
                end
                return inst
            end
            print("[HOOK] Hooked __call")
        end
    end

    -- Also hook the module M itself
    local mtM = getmetatable(M)
    if mtM and type(mtM.__call) == "function" then
        local origM = mtM.__call
        mtM.__call = function(...)
            local r = origM(...)
            if type(r) == "table" and (r.SetCurUId or r.GetSlotDataBySlotTypeAndIndex) then
                _G._SocialLobbyInstance = r
                print("[HOOK] Instance via M.__call! set _G._SocialLobbyInstance")
            end
            return r
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- INSTANCE DUMP — once we have it
-- ═══════════════════════════════════════════════════════════════════
_G.InstDump = function()
    local inst = _G._SocialLobbyInstance
    if not inst then
        POPUP("NO INSTANCE", "Hook it first, or check instance_hunter.txt")
        return
    end
    local out = {}
    local function w(s) out[#out+1] = tostring(s) end
    w("═══ INSTANCE DUMP ═══")
    w("Time: " .. os.date("%Y-%m-%d %H:%M:%S"))
    w("")
    local keys = {}
    for k in pairs(inst) do keys[#keys+1] = k end
    table.sort(keys, function(a,b) return tostring(a) < tostring(b) end)
    for _, k in ipairs(keys) do
        w("── " .. tostring(k) .. " (" .. type(inst[k]) .. ") ──")
        w("  " .. V(inst[k], 0, 4))
        w("")
    end
    local txt = table.concat(out, "\n")
    W("instance_full_dump.txt", txt)
    POPUP("INSTANCE DUMPED", "instance_full_dump.txt")
end

-- ═══════════════════════════════════════════════════════════════════
-- INJECT into _G._SocialLobbyInstance
-- ═══════════════════════════════════════════════════════════════════
_G.InstInjectSlots = function()
    local inst = _G._SocialLobbyInstance
    if not inst then
        POPUP("NO INSTANCE", "Run InstanceHunter first, then navigate to profile")
        return
    end

    local uid = "0"
    pcall(function()
        if _G.DataMgr and _G.DataMgr.roleData then
            uid = tostring(_G.DataMgr.roleData.uid or "0")
        end
    end)

    for _, tn in ipairs({ "_tOthersSocialDataMap", "_tSocialDataGetTime",
                          "_tSlotTypeMaxCountMap", "_tUCUnlockSlotMaxCount" }) do
        if inst[tn] == nil then inst[tn] = {} end
    end

    local SLOT_TYPES = { 1, 2, 3, 4, 5, 6, 7, 8 }
    local ITEMS = {
        [1] = { 101001, 101002, 101003, 101004, 101005, 101006 },
        [2] = { 903, 904, 905, 906, 907, 908 },
        [3] = { 50008, 50009, 50010, 50017, 50018, 50033 },
        [4] = { 10008, 10010, 10011, 20010, 20011, 20012 },
        [5] = { 10008, 10010, 10011, 20010, 20011, 20012 },
        [6] = { 10008, 10010, 10011, 20010, 20011, 20012 },
        [7] = { 10008, 10010, 10011, 20010, 20011, 20012 },
        [8] = { 10008, 10010, 10011, 20010, 20011, 20012 },
    }

    local function mkSlot(st, idx, itemID)
        return {
            slotType = st, slotTypeID = st, type = st,
            index = idx, slotIndex = idx,
            itemID = itemID, itemId = itemID, ItemID = itemID,
            resID = itemID, resId = itemID, skinID = itemID, skinId = itemID,
            isLock = false, isUnlock = true, isOwned = true,
            expire_ts = 0, expireTime = 0, isPermanent = true,
        }
    end

    local byType = {}
    for _, st in ipairs(SLOT_TYPES) do
        byType[st] = {}
        local pool = ITEMS[st] or ITEMS[1]
        for idx = 1, 6 do
            byType[st][idx] = mkSlot(st, idx, pool[((idx-1) % #pool) + 1])
        end
    end
    local flat = {}
    for idx = 1, 20 do
        local st = SLOT_TYPES[((idx-1) % #SLOT_TYPES) + 1]
        local pool = ITEMS[st] or ITEMS[1]
        flat[idx] = mkSlot(st, idx, pool[((idx-1) % #pool) + 1])
    end

    local socialData = {
        uid = uid, slotData = byType, slots = flat,
        allSlotData = flat, collectHallLevel = 999,
    }

    for _, k in ipairs({ uid, "self", "me", "current", 0, 1, "" }) do
        inst._tOthersSocialDataMap[k] = socialData
    end
    for _, st in ipairs(SLOT_TYPES) do
        inst._tSlotTypeMaxCountMap[st] = 6
        inst._tUCUnlockSlotMaxCount[st] = 0
    end

    pcall(function()
        if type(inst.SetCurUId) == "function" then inst.SetCurUId(inst, uid) end
        if type(inst.on_get_collect_hall_data_rsp) == "function" then
            inst.on_get_collect_hall_data_rsp(inst, socialData)
        end
    end)

    POPUP("INJECTED", "Instance patched!\nUID: " .. uid)
end

-- ═══════════════════════════════════════════════════════════════════
-- AUTO-BOOT: run hunter + hook
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(5.0, function()
            pcall(_G.InstanceHunter)
            pcall(_G.HookInstanceCreation)
            pcall(function()
                local t = require("common.time_ticker")
                if t and t.AddTimerOnce then
                    t.AddTimerOnce(2.0, function()
                        POPUP("HUNTER DONE",
                            "1. instance_hunter.txt saved\n" ..
                            "2. Creation hook active\n\n" ..
                            "NOW: Open Profile / Social Lobby\n" ..
                            "Instance catch hoga automatically\n" ..
                            "Then: InstInjectSlots()")
                    end)
                end
            end)
        end)
    end
end)

print("[v7] Hunter loaded. Instance hook will activate in 5s.")

return true
