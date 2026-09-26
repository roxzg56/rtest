-- ═══════════════════════════════════════════════════════════════════
-- FIX v8 — MULTI-PATH WRITE + VERIFIED
-- Har file 4 jagah likhi jaayegi. Ek toh kaam karega.
-- ═══════════════════════════════════════════════════════════════════

local PATHS = {
    "/storage/emulated/0/Android/data/com.pubg.imobile/files/",
    "/storage/emulated/0/Android/data/com.vng.pubgmobile/files/",
    "/storage/emulated/0/Android/data/com.tencent.ig/files/",
    "/sdcard/",
}

local function POPUP(t, m)
    pcall(function()
        local M = package.loaded["client.slua.logic.common.logic_common_msg_box"]
            or (pcall(require, "client.slua.logic.common.logic_common_msg_box")
                and require("client.slua.logic.common.logic_common_msg_box"))
        if M and M.Show then M.Show(1, tostring(t), tostring(m), function() end, function() end, "OK", "CLOSE") end
    end)
    print("[POPUP] " .. tostring(t) .. " | " .. tostring(m))
end

-- ═══ WRITE to ALL paths, verify each ═══════════════════════════════
local function SAVE(name, content)
    local saved = {}
    local failed = {}
    for _, dir in ipairs(PATHS) do
        local full = dir .. name
        local f = io.open(full, "w")
        if f then
            local ok = pcall(function() f:write(content or "") end)
            f:close()
            if ok then
                -- Verify read back
                local vf = io.open(full, "r")
                if vf then
                    local read = vf:read("*a") or ""
                    vf:close()
                    if #read > 0 then
                        saved[#saved+1] = full .. " (" .. #read .. "b)"
                    else
                        failed[#failed+1] = full .. " (empty)"
                    end
                else
                    failed[#failed+1] = full .. " (no read)"
                end
            else
                failed[#failed+1] = full .. " (write err)"
            end
        else
            failed[#failed+1] = full .. " (open fail)"
        end
    end
    return saved, failed
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
            if i > 15 then p[#p+1] = "...(+"..(n-15)..")"; break end
            p[#p+1] = tostring(k).."="..V(val,d+1,m)
        end
        return "{"..table.concat(p,",").."}"
    end
    return "<"..t..">"
end

-- ═══════════════════════════════════════════════════════════════════
-- FIND INSTANCE — 5 ways
-- ═══════════════════════════════════════════════════════════════════
local function findInstance()
    -- Way 1: cached
    if _G._SocialInstance then return _G._SocialInstance, "cache" end

    -- Way 2: ModuleManager
    local MM = _G.ModuleManager
    if type(MM) == "table" and type(MM.GetModule) == "function" and type(MM.LobbyModuleConfig) == "table" then
        for key, cfg in pairs(MM.LobbyModuleConfig) do
            if type(cfg) == "table" and type(cfg.ModuleName) == "string" and cfg.ModuleName:find("SocialLobby") then
                local ok, inst = pcall(MM.GetModule, MM, cfg)
                if ok and type(inst) == "table" and (inst.SetCurUId or inst.GetSlotDataBySlotTypeAndIndex) then
                    _G._SocialInstance = inst
                    return inst, "GetModule"
                end
            end
        end
    end

    -- Way 3: M.instance / M.__instance / M.obj
    local M = package.loaded["client.slua.logic.lobby.Left.Logic_SocialLobbyModule"]
    if type(M) == "table" then
        for _, k in ipairs({ "instance", "_instance", "__instance", "obj", "_obj", "self" }) do
            if type(M[k]) == "table" and (M[k].SetCurUId or M[k].GetSlotDataBySlotTypeAndIndex) then
                _G._SocialInstance = M[k]
                return M[k], "M."..k
            end
        end
        -- Way 3b: M itself has methods at top level?
        if type(M.SetCurUId) == "function" and type(M.GetSlotDataBySlotTypeAndIndex) == "function" then
            _G._SocialInstance = M
            return M, "M-direct"
        end
    end

    -- Way 4: _G scan
    for k, v in pairs(_G) do
        if type(v) == "table" and type(k) == "string" then
            if type(v.SetCurUId) == "function" and type(v.GetSlotDataBySlotTypeAndIndex) == "function" then
                _G._SocialInstance = v
                return v, "_G."..k
            end
        end
    end

    -- Way 5: hunt for __inner_impl instance — the one with data fields
    -- Check all LobbyModuleConfig instances
    if MM and type(MM.LobbyModuleConfig) == "table" and type(MM.GetModule) == "function" then
        for key, cfg in pairs(MM.LobbyModuleConfig) do
            local ok, inst = pcall(MM.GetModule, MM, cfg)
            if ok and type(inst) == "table" then
                -- Look for the module that has _tOthersSocialDataMap OR SetSlotUnlocked
                if inst._tOthersSocialDataMap ~= nil or type(inst.SetSlotUnlocked) == "function" then
                    _G._SocialInstance = inst
                    return inst, "LobbyCfg["..tostring(key).."]"
                end
            end
        end
    end

    return nil, "not found"
end

-- ═══════════════════════════════════════════════════════════════════
-- INSTANCE DUMP
-- ═══════════════════════════════════════════════════════════════════
_G.InstDump = function()
    local inst, how = findInstance()
    if not inst then
        POPUP("NO INSTANCE", "Run InstHook() then open profile")
        return
    end
    local out = {}
    local function w(s) out[#out+1] = tostring(s) end
    w("═══ INSTANCE DUMP via " .. how .. " ═══")
    w("Time: " .. os.date("%Y-%m-%d %H:%M:%S"))
    w("")
    local keys = {}
    for k in pairs(inst) do keys[#keys+1] = k end
    table.sort(keys, function(a,b) return tostring(a)<tostring(b) end)
    for _, k in ipairs(keys) do
        w("── " .. tostring(k) .. " (" .. type(inst[k]) .. ") ──")
        w("  " .. V(inst[k], 0, 4))
        w("")
    end
    local txt = table.concat(out, "\n")
    local saved, failed = SAVE("inst_dump.txt", txt)
    POPUP("INSTANCE DUMPED",
        "FOUND via: " .. how .. "\n\n" ..
        "SAVED TO:\n" .. table.concat(saved, "\n") .. "\n\n" ..
        (#failed > 0 and ("FAILED:\n" .. table.concat(failed, "\n")) or "All paths OK"))
end

-- ═══════════════════════════════════════════════════════════════════
-- HUNT — quick check all 5 methods
-- ═══════════════════════════════════════════════════════════════════
_G.InstHunt = function()
    local out = {}
    local function w(s) out[#out+1] = tostring(s) end
    w("═══ INSTANCE HUNT ═══")
    w("Time: " .. os.date("%Y-%m-%d %H:%M:%S"))
    w("")

    -- Test all methods
    local M = package.loaded["client.slua.logic.lobby.Left.Logic_SocialLobbyModule"]
    w("M type: " .. type(M))
    if type(M) == "table" then
        w("M.SetCurUId: " .. type(M.SetCurUId))
        w("M.GetSlotDataBySlotTypeAndIndex: " .. type(M.GetSlotDataBySlotTypeAndIndex))
        w("M.instance: " .. type(M.instance))
        w("M.__instance: " .. type(M.__instance))
        w("M._config: " .. V(M._config, 0, 2))
    end

    w("")
    local MM = _G.ModuleManager
    w("ModuleManager: " .. type(MM))
    if type(MM) == "table" then
        w("GetModule: " .. type(MM.GetModule))
        w("LobbyModuleConfig: " .. type(MM.LobbyModuleConfig))
        if type(MM.LobbyModuleConfig) == "table" then
            local found = 0
            for k, cfg in pairs(MM.LobbyModuleConfig) do
                if type(cfg) == "table" and tostring(cfg.ModuleName or ""):find("SocialLobby") then
                    found = found + 1
                    w("  SocialLobby cfg: " .. tostring(k) .. " → " .. tostring(cfg.ModuleName))
                    -- Try resolve
                    local ok, inst = pcall(MM.GetModule, MM, cfg)
                    w("    GetModule → " .. (ok and type(inst) or "ERR:"..tostring(inst):sub(1,60)))
                    if ok and type(inst) == "table" then
                        local n = 0; for _ in pairs(inst) do n = n + 1 end
                        w("    inst keys: " .. n)
                        w("    SetCurUId: " .. type(inst.SetCurUId))
                        w("    _tOthersSocialDataMap: " .. type(inst._tOthersSocialDataMap))
                    end
                end
            end
            w("  Total SocialLobby cfgs: " .. found)
        end
    end

    w("")
    w("── _G scan for slot-signature tables ──")
    local hits = 0
    for k, v in pairs(_G) do
        if type(k) == "string" and type(v) == "table" 
           and type(v.SetCurUId) == "function" 
           and type(v.GetSlotDataBySlotTypeAndIndex) == "function" then
            hits = hits + 1
            w("  ✓ _G." .. k)
        end
    end
    w("  Total: " .. hits)

    w("")
    w("── All LobbyModule instances with slot signature ──")
    if MM and type(MM.LobbyModuleConfig) == "table" and type(MM.GetModule) == "function" then
        local hits2 = 0
        for k, cfg in pairs(MM.LobbyModuleConfig) do
            local ok, inst = pcall(MM.GetModule, MM, cfg)
            if ok and type(inst) == "table" 
               and type(inst.SetCurUId) == "function" then
                hits2 = hits2 + 1
                w("  ✓ " .. tostring(k) .. " (" .. tostring(cfg.ModuleName) .. ")")
            end
        end
        w("  Total: " .. hits2)
    end

    local txt = table.concat(out, "\n")
    local saved, failed = SAVE("inst_hunt.txt", txt)
    POPUP("HUNT DONE",
        "SAVED TO:\n" .. table.concat(saved, "\n") .. "\n\n" ..
        "Failed: " .. #failed .. " paths")
end

-- ═══════════════════════════════════════════════════════════════════
-- HOOK __call to catch instance
-- ═══════════════════════════════════════════════════════════════════
_G.InstHook = function()
    local M = package.loaded["client.slua.logic.lobby.Left.Logic_SocialLobbyModule"]
    if type(M) ~= "table" then print("[HOOK] M not loaded") return end

    -- Hook M itself if callable
    local mtM = getmetatable(M)
    if mtM and type(mtM.__call) == "function" and not mtM.__hooked then
        local orig = mtM.__call
        mtM.__call = function(...)
            local r = orig(...)
            if type(r) == "table" and (r.SetCurUId or r.GetSlotDataBySlotTypeAndIndex) then
                _G._SocialInstance = r
                print("[HOOK] instance caught via M.__call")
            end
            return r
        end
        mtM.__hooked = true
        print("[HOOK] M.__call hooked")
    end

    -- Hook __class if callable
    if type(M.__class) == "table" then
        local mtC = getmetatable(M.__class)
        if mtC and type(mtC.__call) == "function" and not mtC.__hooked then
            local orig = mtC.__call
            mtC.__call = function(...)
                local r = orig(...)
                if type(r) == "table" and (r.SetCurUId or r.GetSlotDataBySlotTypeAndIndex) then
                    _G._SocialInstance = r
                    print("[HOOK] instance caught via __class.__call")
                end
                return r
            end
            mtC.__hooked = true
            print("[HOOK] __class.__call hooked")
        end
    end

    POPUP("HOOK ACTIVE", "Instance hook ready.\nOpen profile now.")
end

-- ═══════════════════════════════════════════════════════════════════
-- INJECT — put fake slots on instance
-- ═══════════════════════════════════════════════════════════════════
_G.InstInject = function()
    local inst, how = findInstance()
    if not inst then
        POPUP("NO INSTANCE", "Run InstHook then open profile, then InstInject()")
        return
    end

    local uid = "0"
    pcall(function()
        if _G.DataMgr and _G.DataMgr.roleData then
            uid = tostring(_G.DataMgr.roleData.uid or "0")
        end
    end)

    -- Init data fields
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

    local n = 0
    for _ in pairs(inst._tOthersSocialDataMap) do n = n + 1 end

    POPUP("INJECTED", 
        "Instance patched via " .. how .. "\n" ..
        "UID: " .. uid .. "\n" ..
        "Data keys: " .. n .. "\n\n" ..
        "Reopen Profile to see")
end

-- ═══════════════════════════════════════════════════════════════════
-- CAR SPAWN — force legendary car
-- ═══════════════════════════════════════════════════════════════════
_G.CarSpawn = function(vehicleID)
    vehicleID = vehicleID or 903
    local M = require("client.logic.lobby.ThemeVehicleManager")
    if type(M) ~= "table" then POPUP("CAR", "Not loaded") return end
    local i = M.__inner_impl
    if type(i) ~= "table" then POPUP("CAR", "Inner not loaded") return end

    -- Try multiple functions
    local tried = {}
    for _, fnName in ipairs({ "ShowThemeVehicle", "_ShowSelfVehicle", "_CreateVehicleModel",
                              "_TryCreateVehicleModel", "PreviewGarageVehicle", "OnVehicleChange" }) do
        if type(i[fnName]) == "function" then
            local ok, err = pcall(i[fnName], i, vehicleID)
            tried[#tried+1] = fnName .. "=" .. (ok and "OK" or tostring(err):sub(1,40))
        end
    end
    -- Try with table
    pcall(function()
        if type(i.ShowThemeVehicle) == "function" then
            i.ShowThemeVehicle(i, { vehicleID = vehicleID })
        end
    end)

    POPUP("CAR SPAWN", "ID: " .. vehicleID .. "\n" .. table.concat(tried, "\n"))
end

-- ═══════════════════════════════════════════════════════════════════
-- BOOT — auto-run
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(3.0, function()
            pcall(_G.InstHunt)
            pcall(_G.InstHook)
        end)
    end
end)

-- Immediate test — write a proof file RIGHT NOW
pcall(function()
    local saved, failed = SAVE("_proof.txt", "Loaded at " .. os.date() .. "\nMulti-path writer active.")
    POPUP("✓ LOADED", 
        "SAVED TO:\n" .. table.concat(saved, "\n") .. "\n\n" ..
        "FAILED:\n" .. (table.concat(failed, "\n")))
end)

print("[v8] Loaded. Multi-path writer active. 4 files max.")

return true
