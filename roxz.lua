-- ═══════════════════════════════════════════════════════════════════
-- DIRECT FIX v9 — No diagnostic, ship it
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

local function SAVE(name, content)
    local f = io.open(DIR .. name, "w")
    if not f then
        f = io.open("/sdcard/" .. name, "w")
    end
    if not f then return false end
    f:write(content or ""); f:close()
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- INSTANCE FINDER — multiple ways, whatever works
-- ═══════════════════════════════════════════════════════════════════
local function getInstance()
    -- Try cached
    if _G._SInst then return _G._SInst end

    local MM = _G.ModuleManager
    if type(MM) == "table" and MM.LobbyModuleConfig then
        for k, cfg in pairs(MM.LobbyModuleConfig) do
            local name = type(cfg) == "table" and cfg.ModuleName or nil
            if type(name) == "string" and name:find("SocialLobby") then
                -- Try GetModule call styles
                local tries = {
                    function() return MM:GetModule(cfg) end,
                    function() return MM.GetModule(MM, cfg) end,
                    function() return MM.GetModule(cfg) end,
                    function() return MM:GetModule(name) end,
                    function() return MM:GetModule(k) end,
                }
                for _, t in ipairs(tries) do
                    local ok, r = pcall(t)
                    if ok and type(r) == "table" and type(r.GetSlotDataBySlotTypeAndIndex) == "function" then
                        _G._SInst = r
                        return r
                    end
                end
            end
        end
    end

    -- Try M directly
    local M = package.loaded["client.slua.logic.lobby.Left.Logic_SocialLobbyModule"]
    if type(M) == "table" and type(M.GetSlotDataBySlotTypeAndIndex) == "function" then
        _G._SInst = M
        return M
    end

    -- Try __inner_impl wrapped instance
    if type(M) == "table" and type(M.__inner_impl) == "table" then
        local inner = M.__inner_impl
        -- inner itself might BE the instance after all
        if type(inner.GetSlotDataBySlotTypeAndIndex) == "function" then
            _G._SInst = inner
            return inner
        end
    end

    return nil
end

-- ═══════════════════════════════════════════════════════════════════
-- PATCH SELF — get self via first self-arg
-- ═══════════════════════════════════════════════════════════════════
-- Key insight: koi bhi method call ho, self = actual instance
-- Toh: method ko hook karo, self capture karo, cache karo

local function hookSelfCapture()
    local M = package.loaded["client.slua.logic.lobby.Left.Logic_SocialLobbyModule"]
    if type(M) ~= "table" then return end

    local candidates = { M, M.__inner_impl }
    for _, obj in ipairs(candidates) do
        if type(obj) == "table" then
            for name, fn in pairs(obj) do
                if type(fn) == "function" and type(name) == "string" 
                   and name == "SetCurUId" then
                    if not obj["__selfcapture_" .. name] then
                        obj["__selfcapture_" .. name] = fn
                        obj[name] = function(self, ...)
                            if type(self) == "table" and type(self.GetSlotDataBySlotTypeAndIndex) == "function" then
                                _G._SInst = self
                            end
                            return obj["__selfcapture_" .. name](self, ...)
                        end
                    end
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- FORCE INJECT — call on any instance we have
-- ═══════════════════════════════════════════════════════════════════
local function injectInto(inst)
    if type(inst) ~= "table" then return false end

    local uid = "0"
    pcall(function()
        if _G.DataMgr and _G.DataMgr.roleData then
            uid = tostring(_G.DataMgr.roleData.uid or "0")
        end
    end)

    -- Init fields
    inst._tOthersSocialDataMap = inst._tOthersSocialDataMap or {}
    inst._tSocialDataGetTime = inst._tSocialDataGetTime or {}
    inst._tSlotTypeMaxCountMap = inst._tSlotTypeMaxCountMap or {}
    inst._tUCUnlockSlotMaxCount = inst._tUCUnlockSlotMaxCount or {}

    -- Real pools
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
        uid = uid, UID = uid,
        slotData = byType, slots = flat,
        allSlotData = flat, collectHallLevel = 999,
    }

    for _, k in ipairs({ uid, "self", "me", "current", 0, 1, "" }) do
        inst._tOthersSocialDataMap[k] = socialData
    end

    for _, st in ipairs(SLOT_TYPES) do
        inst._tSlotTypeMaxCountMap[st] = 6
        inst._tUCUnlockSlotMaxCount[st] = 0
    end

    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- MAIN — RUN THIS
-- ═══════════════════════════════════════════════════════════════════
_G.Fix = function()
    -- 1. Setup hook
    hookSelfCapture()

    -- 2. Try get instance
    local inst = getInstance()
    if inst then
        injectInto(inst)
        POPUP("✓ INSTANCE FOUND", "Patched directly!\nOpen profile to verify.")
        return
    end

    -- 3. Not found — hook & tell user
    local M = package.loaded["client.slua.logic.lobby.Left.Logic_SocialLobbyModule"]
    if type(M) == "table" and type(M.__inner_impl) == "table" then
        -- Patch the inner_impl so when instance IS created, it will auto-inject
        local inner = M.__inner_impl
        -- Hook SetCurUId on inner_impl
        if type(inner.SetCurUId) == "function" and not inner.__autoinject then
            local origSet = inner.SetCurUId
            inner.SetCurUId = function(self, ...)
                local r = origSet(self, ...)
                if not _G._SInst and type(self) == "table" and self ~= inner then
                    _G._SInst = self
                    injectInto(self)
                    POPUP("✓ INSTANCE CAUGHT", "Auto-patched on SetCurUId!\nOpen profile.")
                end
                return r
            end
            inner.__autoinject = true
        end

        -- Hook GetSlotDataBySlotTypeAndIndex
        if type(inner.GetSlotDataBySlotTypeAndIndex) == "function" and not inner.__autoinject2 then
            local origGet = inner.GetSlotDataBySlotTypeAndIndex
            inner.GetSlotDataBySlotTypeAndIndex = function(self, slotType, index, ...)
                if not _G._SInst and type(self) == "table" and self ~= inner then
                    _G._SInst = self
                    injectInto(self)
                    POPUP("✓ INSTANCE CAUGHT", "Auto-patched!\nOpen profile.")
                end
                return origGet(self, slotType, index, ...)
            end
            inner.__autoinject2 = true
        end
    end

    POPUP("HOOKED", 
        "Instance hook active.\n" ..
        "Open Profile / Social Lobby now.\n" ..
        "Instance auto-catch hoga.")
end

-- ═══════════════════════════════════════════════════════════════════
-- CAR SPAWN — direct try
-- ═══════════════════════════════════════════════════════════════════
_G.CarSpawn = function(vehicleID)
    vehicleID = vehicleID or 903
    local M = require("client.logic.lobby.ThemeVehicleManager")
    local i = type(M) == "table" and M.__inner_impl or nil
    if type(i) ~= "table" then POPUP("CAR", "Not loaded") return end

    local tried = {}
    for _, fnName in ipairs({ "ShowThemeVehicle", "_ShowSelfVehicle", "_CreateVehicleModel",
                              "PreviewGarageVehicle", "OnVehicleChange", "OnGarageVehicleChange" }) do
        if type(i[fnName]) == "function" then
            local ok, err = pcall(i[fnName], i, vehicleID)
            tried[#tried+1] = fnName .. "=" .. (ok and "OK" or "ERR")
        end
    end

    -- Hook it too so when instance available, catch
    if type(i.ShowThemeVehicle) == "function" and not i.__carhook then
        local orig = i.ShowThemeVehicle
        i.ShowThemeVehicle = function(self, ...)
            local r = orig(self, ...)
            if type(self) == "table" and self ~= i then
                _G._CarInst = self
                pcall(orig, self, vehicleID)
            end
            return r
        end
        i.__carhook = true
    end

    POPUP("CAR SPAWN", "ID: " .. vehicleID .. "\nTried: " .. table.concat(tried, "\n"))
end

-- ═══════════════════════════════════════════════════════════════════
-- AUTO-RUN on load
-- ═══════════════════════════════════════════════════════════════════
pcall(_G.Fix)

print("[v9] Loaded. Fix() auto-ran.")

return true
