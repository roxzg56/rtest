-- ═══════════════════════════════════════════════════════════════════
-- PATH-FIXED READER + TRACER + INJECT v3.1
-- All output goes to: /storage/emulated/0/Android/data/com.pubg.imobile/files/
-- ═══════════════════════════════════════════════════════════════════

local DUMP_DIR = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"

-- ─── FILE WRITE HELPER ─────────────────────────────────────────────
local function writeDump(name, content)
    local ok = false
    pcall(function()
        local f = io.open(DUMP_DIR .. name, "w")
        if f then
            f:write(content or "")
            f:close()
            ok = true
            print("[DUMP] wrote " .. DUMP_DIR .. name)
        end
    end)
    return ok
end

-- ─── SOURCE READER (source files bhi us path se) ───────────────────
_G.ReadSourceFile = function(relPath, lineStart, lineEnd)
    -- Clean path
    local clean = relPath:gsub("^@", ""):gsub("^%.\\", ""):gsub("^%.%/", ""):gsub("\\", "/")
    
    local roots = {
        DUMP_DIR,                              -- primary
        DUMP_DIR .. "Script/",
        DUMP_DIR .. "UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/",
        "/sdcard/",
    }
    
    for _, root in ipairs(roots) do
        local f = io.open(root .. clean, "r")
        if f then
            local content = f:read("*a")
            f:close()
            if lineStart and lineEnd then
                local lines = {}
                local i = 0
                for line in content:gmatch("[^\n]*") do
                    i = i + 1
                    if i >= lineStart and i <= lineEnd then
                        lines[#lines+1] = string.format("%4d | %s", i, line)
                    end
                    if i > lineEnd then break end
                end
                return table.concat(lines, "\n"), root .. clean
            end
            return content, root .. clean
        end
    end
    return nil, nil
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 1: SLOT SOURCE READER
-- ═══════════════════════════════════════════════════════════════════
_G.SlotSourceRead = function()
    local out = {}
    local function w(s) out[#out+1] = tostring(s) end
    w("═══ SLOT SOURCE READ — " .. os.date("%Y-%m-%d %H:%M:%S") .. " ═══")
    w("Dump dir: " .. DUMP_DIR)
    w("")

    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    if type(M) ~= "table" then w("MODULE NOT LOADED"); writeDump("slot_source.txt", table.concat(out, "\n")); return end
    local i = M.__inner_impl
    if type(i) ~= "table" then w("INNER NOT LOADED"); writeDump("slot_source.txt", table.concat(out, "\n")); return end

    local function dumpFn(fnName)
        local fn = i[fnName]
        if type(fn) ~= "function" then
            w("")
            w("── " .. fnName .. " : NOT A FUNCTION ──")
            return
        end
        local info = debug.getinfo(fn, "S")
        if not info then
            w("")
            w("── " .. fnName .. " : NO INFO ──")
            return
        end
        w("")
        w("══════════════════════════════════════════════")
        w("FUNCTION: " .. fnName)
        w("  source      = " .. tostring(info.source))
        w("  short_src   = " .. tostring(info.short_src))
        w("  linedefined = " .. tostring(info.linedefined))
        w("  lastdefined = " .. tostring(info.lastlinedefined))
        w("══════════════════════════════════════════════")

        -- Read the file
        local src, realPath = _G.ReadSourceFile(info.short_src or info.source)
        if src then
            w("  FILE: " .. realPath .. " (" .. #src .. " bytes)")
            w("")
            -- Full function body
            local i3 = 0
            for line in src:gmatch("[^\n]*") do
                i3 = i3 + 1
                if i3 >= info.linedefined and i3 <= info.lastdefined then
                    w(string.format("%4d | %s", i3, line))
                end
                if i3 > info.lastdefined then break end
            end
        else
            w("  FILE NOT READABLE at any root")
        end
    end

    -- Key functions to dump
    local funcs = {
        "GetSlotDataBySlotTypeAndIndex",
        "GetSlotTypeMaxCount",
        "GetSlotTypeUCUnlockMaxCount",
        "GetSlotIsUnlockedByCollectHallLevel",
        "GetCollectHallLevel",
        "SetCurUId",
        "GetCurUId",
        "on_get_collect_hall_data_rsp",
        "PetSlotEquipClotheItemId",
        "BGWallSlotEquipItemId",
        "AvatarShowSlotEquipItemId",
        "AchievementSlotEquipItemId",
        "SetCreateModelIndex",
        "GetCreateModelIndex",
    }

    for _, fn in ipairs(funcs) do
        pcall(dumpFn, fn)
    end

    -- Also dump the module structure
    w("")
    w("")
    w("═══ MODULE FIELD INVENTORY ═══")
    for k, v in pairs(i) do
        local vt = type(v)
        if vt == "table" then
            local n = 0; for _ in pairs(v) do n = n + 1 end
            w(string.format("  [table:%d] %s", n, tostring(k)))
        elseif vt == "function" then
            local info = debug.getinfo(v, "S")
            local line = info and info.linedefined or "?"
            local src = info and (info.short_src or "?") or "?"
            w(string.format("  [fn] %s (line %s in %s)", tostring(k), tostring(line), tostring(src)))
        else
            w(string.format("  [%s] %s = %s", vt, tostring(k), tostring(v)))
        end
    end

    local txt = table.concat(out, "\n")
    writeDump("slot_source.txt", txt)
    print(txt)
    return txt
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 2: TRACER
-- ═══════════════════════════════════════════════════════════════════
_G.TraceSlots = function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    if type(M) ~= "table" then print("[TRACE] Module not loaded") return end
    local i = M.__inner_impl
    if type(i) ~= "table" then print("[TRACE] Inner not loaded") return end

    if _G._SlotTraceActive then
        print("[TRACE] Already active")
        return
    end
    _G._SlotTraceActive = true
    _G._SlotTraceLog = {}
    _G._SlotTraceStart = os.time()

    local function log(line)
        _G._SlotTraceLog[#_G._SlotTraceLog+1] = 
            string.format("[%s] %s", os.date("%H:%M:%S"), line)
    end

    log("=== TRACE STARTED ===")

    for name, fn in pairs(i) do
        if type(fn) == "function" and type(name) == "string" 
           and not name:match("^__") and not name:match("^_t") then
            local orig = fn
            i[name] = function(self, ...)
                local args = {}
                for n = 1, math.min(3, select("#", ...)) do
                    local v = select(n, ...)
                    if type(v) == "table" then
                        args[#args+1] = "tbl"
                    else
                        args[#args+1] = tostring(v)
                    end
                end
                log("CALL " .. name .. "(" .. table.concat(args, ",") .. ")")
                local ok, r = pcall(orig, self, ...)
                if not ok then
                    log("  ERR " .. name .. " → " .. tostring(r))
                    return nil
                end
                if r ~= nil then
                    if type(r) == "table" then
                        local n = 0; for _ in pairs(r) do n = n + 1 end
                        log("  RET " .. name .. " → tbl(" .. n .. ")")
                    else
                        log("  RET " .. name .. " → " .. tostring(r))
                    end
                else
                    log("  RET " .. name .. " → nil")
                end
                return r
            end
        end
    end

    log("=== ALL HOOKED. Open profile now. ===")
    print("[TRACE] Hooked. Open profile/social lobby now, then call DumpTrace()")
end

_G.DumpTrace = function()
    if not _G._SlotTraceLog then print("[TRACE] No trace data") return end
    _G._SlotTraceLog[#_G._SlotTraceLog+1] = "=== TRACE ENDED ==="
    local txt = table.concat(_G._SlotTraceLog, "\n")
    writeDump("slot_trace.txt", txt)
    print("[TRACE] Wrote " .. #_G._SlotTraceLog .. " lines")
    return txt
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 3: FORCE INJECT (multi-structure)
-- ═══════════════════════════════════════════════════════════════════
_G.ForceInjectSlots = function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    if type(M) ~= "table" then print("[FORCE] Module not loaded") return end
    local i = M.__inner_impl
    if type(i) ~= "table" then print("[FORCE] Inner not loaded") return end

    local uid = "0"
    pcall(function()
        if _G.DataMgr and _G.DataMgr.roleData then
            uid = tostring(_G.DataMgr.roleData.uid or "0")
        end
    end)

    -- Init all missing tables
    local initTables = {
        "_tOthersSocialDataMap", "_tSocialDataGetTime", "_tSlotTypeMaxCountMap",
        "_tUCUnlockSlotMaxCount", "_tWeaponSlotIndex",
    }
    for _, tn in ipairs(initTables) do
        if i[tn] == nil then
            i[tn] = {}
            print("[FORCE] Init " .. tn .. " = {}")
        end
    end
    if i._tWeaponSlotIndex and not i._tWeaponSlotIndex[1] then
        i._tWeaponSlotIndex = { [1] = {}, [2] = {} }
    end

    -- Real item IDs
    local SLOT_TYPES = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }
    local ITEMS = {
        [1] = { 101001, 101002, 101003, 101004, 101005, 101006 },
        [2] = { 903, 904, 905, 906, 907, 908 },
        [3] = { 50008, 50009, 50010, 50017, 50018, 50033 },
        [4] = { 10008, 10010, 10011, 20010, 20011, 20012 },
        [5] = { 10008, 10010, 10011, 20010, 20011, 20012 },
        [6] = { 10008, 10010, 10011, 20010, 20011, 20012 },
        [7] = { 10008, 10010, 10011, 20010, 20011, 20012 },
        [8] = { 10008, 10010, 10011, 20010, 20011, 20012 },
        [9] = { 10008, 10010, 10011, 20010, 20011, 20012 },
        [10] = { 10008, 10010, 10011, 20010, 20011, 20012 },
    }

    local function makeSlot(st, idx, itemID)
        return {
            slotType = st, SlotType = st, slotTypeID = st, type = st,
            index = idx, slotIndex = idx, Index = idx, SlotIndex = idx,
            itemID = itemID, itemId = itemID, ItemID = itemID,
            resID = itemID, resId = itemID, ResID = itemID,
            skinID = itemID, skinId = itemID, SkinID = itemID,
            skin_res_id = itemID, res_id = itemID, resid = itemID,
            isLock = false, isUnlock = true, isLocked = false, isOwned = true,
            expire_ts = 0, expire_time = 0, expireTime = 0, isPermanent = true,
            bIsLock = false, bLock = false, bIsUnlock = true,
        }
    end

    -- Build nested structure (by slotType → index)
    local byType = {}
    for _, st in ipairs(SLOT_TYPES) do
        byType[st] = {}
        local pool = ITEMS[st] or ITEMS[1]
        for idx = 1, 6 do
            byType[st][idx] = makeSlot(st, idx, pool[((idx-1) % #pool) + 1])
        end
    end

    -- Build flat structure (by index)
    local flat = {}
    for idx = 1, 20 do
        local st = SLOT_TYPES[((idx-1) % #SLOT_TYPES) + 1]
        local pool = ITEMS[st] or ITEMS[1]
        flat[idx] = makeSlot(st, idx, pool[((idx-1) % #pool) + 1])
    end

    -- Build a huge social data object with ALL possible key names
    local socialData = {
        uid = uid, UID = uid, playerUID = uid, PlayerUID = uid,
        slotData = byType, SlotData = byType, slotMap = byType, SlotMap = byType,
        slots = flat, Slots = flat, slotList = flat, SlotList = flat,
        allSlotData = flat, AllSlotData = flat,
        data = byType, Data = byType,
    }

    -- Inject into every possible location
    local keys = { uid, tostring(uid), "self", "me", "current", "_self", "SELF", 0, 1, "" }
    for _, k in ipairs(keys) do
        i._tOthersSocialDataMap[k] = socialData
    end

    -- Set max counts
    for _, st in ipairs(SLOT_TYPES) do
        i._tSlotTypeMaxCountMap[st] = 6
        i._tUCUnlockSlotMaxCount[st] = 0
    end

    -- Set UID
    pcall(function()
        if type(i.SetCurUId) == "function" then
            i.SetCurUId(i, uid)
        end
    end)

    -- Fire refresh
    pcall(function()
        if type(i.on_get_collect_hall_data_rsp) == "function" then
            i.on_get_collect_hall_data_rsp(i, socialData)
        end
    end)

    local n = 0; for _ in pairs(i._tOthersSocialDataMap) do n = n + 1 end
    print("[FORCE] Injected. _tOthersSocialDataMap now has " .. n .. " keys")
    print("[FORCE] MyUID = " .. uid)
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 4: CAR SPAWN — all methods tried
-- ═══════════════════════════════════════════════════════════════════
_G.ForceCarSpawn = function(vehicleID)
    vehicleID = vehicleID or 903
    local M = require("client.logic.lobby.ThemeVehicleManager")
    if type(M) ~= "table" then print("[CAR] Module not loaded") return end
    local i = M.__inner_impl
    if type(i) ~= "table" then print("[CAR] Inner not loaded") return end

    if i.Vehicles == nil then i.Vehicles = {} end

    print("[CAR] Attempting spawn vehicleID=" .. tostring(vehicleID))

    local methods = {
        { "ShowThemeVehicle", vehicleID },
        { "ShowThemeVehicle", vehicleID, 1 },
        { "_ShowSelfVehicle", vehicleID },
        { "_CreateVehicleModel", vehicleID },
        { "_TryCreateVehicleModel", vehicleID },
        { "PreviewGarageVehicle", vehicleID },
        { "OnVehicleChange", vehicleID, 1 },
        { "OnGarageVehicleChange", vehicleID },
        { "SetVehicleTick", true },
    }

    for _, m in ipairs(methods) {
        local fnName = m[1]
        local args = { m[2], m[3] }
        if type(i[fnName]) == "function" then
            local ok, err = pcall(i[fnName], i, args[1], args[2])
            print("[CAR] " .. fnName .. " → " .. (ok and "OK" or ("ERR: " .. tostring(err))))
        else
            print("[CAR] " .. fnName .. " → NOT A FUNCTION")
        end
    end

    -- Also try passing table format
    pcall(function()
        if type(i.ShowThemeVehicle) == "function" then
            i.ShowThemeVehicle(i, { vehicleID = vehicleID, ID = vehicleID })
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- AUTO-RUN
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(5.0, function()
            pcall(_G.SlotSourceRead)
        end)
    end
end)

print("[PATH-FIX v3.1] Loaded. Dumps go to: " .. DUMP_DIR)

return true
