-- ═══════════════════════════════════════════════════════════════════
-- FIX v6 — INSTANCE RESOLVER (not class)
-- Reason: __inner_impl is CLASS. Data is on INSTANCE.
-- ═══════════════════════════════════════════════════════════════════

local DIR = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"

local function POPUP(title, msg)
    pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
            or (pcall(require, "client.slua.logic.common.logic_common_msg_box")
                and require("client.slua.logic.common.logic_common_msg_box"))
        if Msg and Msg.Show then
            Msg.Show(1, tostring(title), tostring(msg), function() end, function() end, "OK", "CLOSE")
        end
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
-- INSTANCE RESOLVER — find the real instance
-- ═══════════════════════════════════════════════════════════════════
local function resolveInstance()
    local out = {}
    local function w(s) out[#out+1] = tostring(s) end
    w("═══ INSTANCE RESOLVER ═══")
    w("")

    -- Method 1: ModuleManager.GetModule
    local MM = _G.ModuleManager
    if type(MM) == "table" and type(MM.GetModule) == "function" then
        pcall(function()
            local cfg = MM.LobbyModuleConfig and MM.LobbyModuleConfig.Logic_SocialLobbyModule
            if not cfg then
                -- try other key names
                for k, v in pairs(MM.LobbyModuleConfig or {}) do
                    if type(v) == "table" and type(v.ModuleName) == "string" 
                       and v.ModuleName:find("SocialLobby") then
                        cfg = v
                        break
                    end
                end
            end
            if cfg then
                w("cfg found: " .. tostring(cfg.ModuleName))
                local inst = MM:GetModule(cfg)
                if inst and type(inst) == "table" then
                    w("INSTANCE VIA GetModule: table(" .. 
                        (function() local n=0;for _ in pairs(inst)do n=n+1 end;return n end)() .. ")")
                    -- Check for data fields
                    local dataFields = { "_tOthersSocialDataMap", "_tSocialDataGetTime",
                                         "_tSlotTypeMaxCountMap", "_tUCUnlockSlotMaxCount",
                                         "_tWeaponSlotIndex", "_nCurWeaponPage",
                                         "_nCreateModelIndex", "_bGMIsShowMark",
                                         "_bIsShowQualityEffectHideTip" }
                    for _, fn in ipairs(dataFields) do
                        if inst[fn] ~= nil then
                            w("  inst." .. fn .. " = " .. V(inst[fn], 0, 3))
                        end
                    end
                    return inst, "GetModule"
                else
                    w("GetModule returned: " .. tostring(inst))
                end
            end
        end)
    end

    -- Method 2: File-level .instance
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    if type(M) == "table" then
        w("")
        w("Checking M fields for instance...")
        for _, k in ipairs({ "instance", "_instance", "obj", "_obj", "__obj", "self", "__instance" }) do
            if M[k] ~= nil then
                w("  M." .. k .. " = " .. type(M[k]))
            end
        end

        -- Method 3: Check __inner_impl.__class
        if type(M.__inner_impl) == "table" and type(M.__inner_impl.__class) == "table" then
            w("")
            w("M.__inner_impl.__class exists")
        end

        -- Method 4: M.__inner_impl.__bounds (Lua 5.3 has upvalue bounds sometimes)
        if type(M.__inner_impl) == "table" and M.__inner_impl.__bounds ~= nil then
            w("  M.__inner_impl.__bounds = " .. V(M.__inner_impl.__bounds, 0, 3))
        end
    end

    -- Method 5: scan _G for instances
    w("")
    w("Scanning _G for SocialLobby refs...")
    for k, v in pairs(_G) do
        if type(k) == "string" and k:lower():find("sociallobby") then
            w("  _G." .. k .. " = " .. type(v))
        end
    end

    local txt = table.concat(out, "\n")
    W("instance_resolve.txt", txt)
    return nil, "not found"
end

-- ═══════════════════════════════════════════════════════════════════
-- FULL INSTANCE DUMP — once resolved
-- ═══════════════════════════════════════════════════════════════════
_G.InstDump = function()
    local inst, method = resolveInstance()
    if not inst then
        POPUP("INSTANCE", "Not found. Check instance_resolve.txt")
        return
    end

    local out = {}
    local function w(s) out[#out+1] = tostring(s) end
    w("═══ INSTANCE DUMP (via " .. method .. ") ═══")
    w("Time: " .. os.date("%Y-%m-%d %H:%M:%S"))
    w("")

    w("═══ ALL FIELDS (deep) ═══")
    local keys = {}
    for k in pairs(inst) do keys[#keys+1] = k end
    table.sort(keys, function(a,b) return tostring(a) < tostring(b) end)
    for _, k in ipairs(keys) do
        local v = inst[k]
        w("── " .. tostring(k) .. " (" .. type(v) .. ") ──")
        w("  " .. V(v, 0, 4))
        w("")
    end

    local txt = table.concat(out, "\n")
    local ok = W("instance_full_dump.txt", txt)
    if ok then POPUP("INSTANCE DUMPED", "instance_full_dump.txt\n" .. #txt .. " bytes\nvia " .. method)
    else POPUP("FAIL", "Cannot write") end
end

-- ═══════════════════════════════════════════════════════════════════
-- INJECT INTO INSTANCE (only if instance found)
-- ═══════════════════════════════════════════════════════════════════
_G.InstInjectSlots = function()
    local inst = resolveInstance()
    if not inst then
        POPUP("INJECT", "Instance not found")
        return
    end

    local uid = "0"
    pcall(function()
        if _G.DataMgr and _G.DataMgr.roleData then
            uid = tostring(_G.DataMgr.roleData.uid or "0")
        end
    end)

    -- Init missing data fields on INSTANCE
    for _, tn in ipairs({ "_tOthersSocialDataMap", "_tSocialDataGetTime",
                          "_tSlotTypeMaxCountMap", "_tUCUnlockSlotMaxCount" }) do
        if inst[tn] == nil then
            inst[tn] = {}
            print("[INJ] init inst." .. tn .. " = {}")
        end
    end
    if inst._tWeaponSlotIndex == nil then
        inst._tWeaponSlotIndex = { [1] = {}, [2] = {} }
    end

    -- Real item pools
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
            slotType = st, slotTypeID = st, SlotType = st, type = st,
            index = idx, slotIndex = idx, Index = idx, SlotIndex = idx,
            itemID = itemID, itemId = itemID, ItemID = itemID,
            resID = itemID, resId = itemID, ResID = itemID,
            skinID = itemID, skinId = itemID, SkinID = itemID,
            skin_res_id = itemID, res_id = itemID, resid = itemID,
            isLock = false, isUnlock = true, isLocked = false, isOwned = true,
            bIsLock = false, bLock = false, bIsUnlock = true,
            expire_ts = 0, expire_time = 0, expireTime = 0, isPermanent = true,
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
        uid = uid, UID = uid,
        slotData = byType, slots = flat, allSlotData = flat,
        collectHallLevel = 999, hallLevel = 999,
    }

    local keys = { uid, tostring(uid), "self", "me", "current", 0, 1, "" }
    for _, k in ipairs(keys) do
        inst._tOthersSocialDataMap[k] = socialData
    end

    for _, st in ipairs(SLOT_TYPES) do
        inst._tSlotTypeMaxCountMap[st] = 6
        inst._tUCUnlockSlotMaxCount[st] = 0
    end

    pcall(function()
        if type(inst.SetCurUId) == "function" then inst.SetCurUId(inst, uid) end
    end)
    pcall(function()
        if type(inst.on_get_collect_hall_data_rsp) == "function" then
            inst.on_get_collect_hall_data_rsp(inst, socialData)
        end
    end)

    local cnt = 0; for _ in pairs(inst._tOthersSocialDataMap) do cnt = cnt + 1 end
    POPUP("INJECTED", "Instance patched\nUID: " .. uid .. "\nKeys: " .. cnt)
end

-- ═══════════════════════════════════════════════════════════════════
-- AUTO-BOOT
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(5.0, function()
            pcall(function()
                local inst, method = resolveInstance()
                if inst then
                    POPUP("INSTANCE FOUND", "via: " .. method)
                    pcall(_G.InstDump)
                else
                    POPUP("INSTANCE MISSING", "Check instance_resolve.txt")
                end
            end)
        end)
    end
end)

print("[v6] Loaded. Instance resolver will auto-fire in 5s.")

return true
