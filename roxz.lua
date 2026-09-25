-- ═══════════════════════════════════════════════════════════════════
-- showroom_unlock.lua v2 — Collection Showroom (PlanCH) slots unlock
--   Standalone — no Phase 1 dependency
--   Popup on boot + on lobby + on showroom enter
--   Uses SubsystemMgr:Get (correct loader for PlanCH subsystems)
--   Debug log written to file so we know what happened
-- ═══════════════════════════════════════════════════════════════════

_G._SR = _G._SR or { booted = false, phase = "unknown", log = {} }

-- ═══ CONFIG ═══
local CFG = {
    BRAND = "SHOWROOM UNLOCK v2",
    DUMP_FILE = "showroom_unlock_log_",
    SAVE_DIRS = {
        "/storage/emulated/0/Android/data/com.pubg.imobile/files/",
        "/storage/emulated/0/Android/data/com.pubg.krmobile/files/",
        "/storage/emulated/0/Android/data/com.vng.pubgmobile/files/",
        "/storage/emulated/0/Android/data/com.vng.pubgmobile/files/",
        "/storage/emulated/0/Android/data/com.rekoo.pubgm/files/",
        "/sdcard/",
    },
    SAVE_KEY = "config.ini",
    SHOW_POPUPS = true,
    TICK = 2.0,
}

-- ═══ POPUP ═══
local function POPUP(t, m)
    if not CFG.SHOW_POPUPS then return end
    pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
                    or require("client.slua.logic.common.logic_common_msg_box")
        if Msg and Msg.Show then Msg.Show(4, tostring(t), tostring(m)) end
    end)
end

-- ═══ LOG FILE ═══
local _PATH, _buf = nil, {}

local function RESOLVE()
    local ts = os.date("%Y%m%d_%H%M%S")
    local name = CFG.DUMP_FILE .. ts .. ".txt"
    for _, d in ipairs(CFG.SAVE_DIRS) do
        local f = io.open(d .. CFG.SAVE_KEY, "r")
        if f then f:close()
            local w = io.open(d .. name, "a"); if w then w:close(); return d .. name end
        end
    end
    for _, d in ipairs(CFG.SAVE_DIRS) do
        local w = io.open(d .. name, "a"); if w then w:close(); return d .. name end
    end
    return nil
end

local function W(line)
    local ts = os.date("%H:%M:%S")
    local full = "[" .. ts .. "] " .. tostring(line)
    _buf[#_buf+1] = full
    _G._SR.log[#_G._SR.log+1] = full
    if _PATH and #_buf >= 5 then
        local f = io.open(_PATH, "a")
        if f then
            f:write(table.concat(_buf, "\n")); f:write("\n"); f:close()
        end
        _buf = {}
    end
    print("[SR] " .. full)
end

local function FLUSH()
    if _PATH and #_buf > 0 then
        local f = io.open(_PATH, "a")
        if f then f:write(table.concat(_buf, "\n")); f:write("\n"); f:close() end
        _buf = {}
    end
end

-- ═══ UTILS ═══
local function GM(p)
    local m = package.loaded[p]; if m then return m end
    local ok, r = pcall(require, p); if ok then return r end
    return nil
end

local function GET_SUBSYS(name)
    local ok, SM = pcall(require, "GameLua.GameCore.Module.Subsystem.SubsystemMgr")
    if not ok or not SM or not SM.Get then
        W("[SUBSYS] SubsystemMgr not available")
        return nil
    end
    local ok2, s = pcall(function() return SM:Get(name) end)
    if ok2 and s then return s end
    return nil
end

-- Try class path → module path → subsystem
local function FIND_MODULE(path, subsys_name)
    -- 1. Try direct require path
    local m = GM(path)
    if m then
        W("[FIND] " .. path .. " via require/package.loaded")
        return m
    end
    -- 2. Try import path (class)
    local ok, cls = pcall(import, path)
    if ok and cls then
        if type(cls.__inner_impl) == "table" then
            W("[FIND] " .. path .. " via import (__inner_impl)")
            return cls.__inner_impl
        end
        W("[FIND] " .. path .. " via import (direct)")
        return cls
    end
    -- 3. Try SubsystemMgr
    if subsys_name then
        local s = GET_SUBSYS(subsys_name)
        if s then
            W("[FIND] " .. path .. " via SubsystemMgr:" .. subsys_name)
            return s
        end
    end
    W("[FIND] " .. path .. " NOT FOUND")
    return nil
end

-- ═══ HOOK HELPERS ═══
local function HK(owner, name, tag, cb)
    if not owner or type(owner[name]) ~= "function" or owner[tag] then return false end
    owner[tag] = true
    local orig = owner[name]
    owner[name] = function(self, ...)
        pcall(cb, self, ...)
        return orig(self, ...)
    end
    return true
end

local function OVERRIDE(owner, name, newfn, tag)
    if not owner or type(owner[name]) ~= "function" or owner[tag] then return false end
    owner[tag] = true
    owner[name] = newfn
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- SLOT UNLOCK
-- ═══════════════════════════════════════════════════════════════════

local SKIN_SLOT_UNLOCK_PATHS = {
    "GameLua.Mod.PlanCH.Client.SubSystem.HallData.PlanCH_SkinSlotUnlock_Config",
    "GameLua.Mod.PlanCH.Client.Subsystem.HallData.PlanCH_SkinSlotUnlock_Config",
    "GameLua.Mod.PlanCH.Client.SubSystem.HallData.PlanCH_SkinSlotUnlock",
}

local function HOOK_SKIN_SLOT_UNLOCK()
    local ssc = nil
    for _, path in ipairs(SKIN_SLOT_UNLOCK_PATHS) do
        ssc = FIND_MODULE(path, "PlanCH_SkinSlotUnlock_Config")
        if ssc then break end
    end
    if not ssc then
        W("[SLOT] SkinSlotUnlock NOT found in any known path")
        return false
    end

    local n = 0

    -- Patch all known functions
    if type(ssc.IsSlotUnlock) == "function" then
        ssc.IsSlotUnlock = function() return true end
        n = n + 1
    end
    if type(ssc.IsPaySlot) == "function" then
        ssc.IsPaySlot = function() return false end
        n = n + 1
    end
    if type(ssc.GetAllSlotCount) == "function" then
        ssc.GetAllSlotCount = function() return 999 end
        n = n + 1
    end
    if type(ssc.GetAllSlotList) == "function" then
        -- keep original but hook for observation
        HK(ssc, "GetAllSlotList", "_sr_sr_list", function(self, ...)
            local args = { ... }
            W("[SLOT] GetAllSlotList called args=" .. tostring(#args))
        end)
        n = n + 1
    end
    if type(ssc.GetUnlockSlotCount) == "function" then
        ssc.GetUnlockSlotCount = function() return 999 end
        n = n + 1
    end
    if type(ssc.GetUnlockNextSlotCost) == "function" then
        ssc.GetUnlockNextSlotCost = function() return 0 end
        n = n + 1
    end
    if type(ssc.ShowPayToUnlockSlotUI) == "function" then
        ssc.ShowPayToUnlockSlotUI = function() end
        n = n + 1
    end
    if type(ssc.UpdateUnlockData) == "function" then
        HK(ssc, "UpdateUnlockData", "_sr_sr_upd", function(self, ...)
            W("[SLOT] UpdateUnlockData fired")
        end)
        n = n + 1
    end

    W("[SLOT] SkinSlotUnlock hooked: " .. n .. " functions")
    _G._SR.slot_hooked = n
    return n > 0
end

-- ═══════════════════════════════════════════════════════════════════
-- HALL PART (slot count per hall part)
-- ═══════════════════════════════════════════════════════════════════

local function HOOK_HALL_PART()
    local shpc = FIND_MODULE(
        "GameLua.Mod.PlanCH.Client.SubSystem.HallData.PlanCH_SkinHallPart_Config",
        "PlanCH_SkinHallPart_Config"
    )
    if not shpc then
        W("[HALLPART] not found")
        return
    end
    local n = 0
    if type(shpc.GetHallPartSlotCnt) == "function" then
        shpc.GetHallPartSlotCnt = function() return 999 end
        n = n + 1
    end
    if type(shpc.IsDisplaySlotInHallPart) == "function" then
        shpc.IsDisplaySlotInHallPart = function() return true end
        n = n + 1
    end
    W("[HALLPART] hooked: " .. n)
end

-- ═══════════════════════════════════════════════════════════════════
-- DISPLAY SUBSYSTEMS (avatar / vehicle / weapon / pet)
-- ═══════════════════════════════════════════════════════════════════

local function HOOK_DISPLAY(tag, paths, subsys_names)
    local impl = nil
    for _, p in ipairs(paths) do
        for _, s in ipairs(subsys_names) do
            impl = FIND_MODULE(p, s)
            if impl then break end
        end
        if impl then break end
    end
    if not impl then
        W("[DISP:" .. tag .. "] not found")
        return
    end

    local n = 0
    if type(impl.IsValidSlotInfo) == "function" then
        impl.IsValidSlotInfo = function() return true end
        n = n + 1
    end
    if type(impl.FindNextFreeSlot) == "function" then
        impl.FindNextFreeSlot = function() return 0 end
        n = n + 1
    end
    if type(impl.IsSameDisplayInfo) == "function" then
        impl.IsSameDisplayInfo = function() return false end
        n = n + 1
    end
    if type(impl.TryPutOnItem) == "function" then
        local orig = impl.TryPutOnItem
        impl.TryPutOnItem = function(self, ...)
            local args = { ... }
            W("[DISP:" .. tag .. "] TryPutOnItem called with " .. #args .. " args")
            local ok, r = pcall(orig, self, ...)
            if not ok then
                W("[DISP:" .. tag .. "] TryPutOnItem errored, applying locally")
                _G._SR["last_" .. tag] = args
            end
            return r
        end
        n = n + 1
    end
    if type(impl.AutoPutOnItems) == "function" then
        HK(impl, "AutoPutOnItems", "_sr_auto_" .. tag, function()
            W("[DISP:" .. tag .. "] AutoPutOnItems fired")
        end)
        n = n + 1
    end
    W("[DISP:" .. tag .. "] hooked: " .. n)
end

-- ═══════════════════════════════════════════════════════════════════
-- NETWORK HANDLER — skip server, apply local
-- ═══════════════════════════════════════════════════════════════════

local function HOOK_NET()
    local h = GM("client.network.Protocol.CollectionHallEditHandler")
    if not h then
        W("[NET] CollectionHallEditHandler not loaded")
        return
    end
    local n = 0

    if type(h.send_edit_collect_hall_req) == "function" then
        local orig = h.send_edit_collect_hall_req
        h.send_edit_collect_hall_req = function(self, ...)
            local args = { ... }
            W("[NET] send_edit_collect_hall_req SKIPPED — args: " .. #args)
            _G._SR.last_edit_req = args
            -- Fabricate success response for UI
            pcall(function()
                if h.on_edit_collect_hall_rsp then
                    h.on_edit_collect_hall_rsp(0, args[1] or {}, args[2] or 0)
                end
            end)
            -- Don't call original (skip server)
        end
        n = n + 1
    end

    if type(h.send_set_collect_hall_common_equipment_req) == "function" then
        h.send_set_collect_hall_common_equipment_req = function(self, ...)
            local args = { ... }
            W("[NET] send_set_collect_hall_common_equipment_req SKIPPED")
            _G._SR.last_equip_req = args
            pcall(function()
                if h.on_set_collect_hall_common_equipment_rsp then
                    h.on_set_collect_hall_common_equipment_rsp(0, args[1] or {}, args[2] or {}, 0)
                end
            end)
        end
        n = n + 1
    end

    if type(h.send_change_collect_hall_skin_req) == "function" then
        h.send_change_collect_hall_skin_req = function(self, ...)
            local args = { ... }
            W("[NET] send_change_collect_hall_skin_req SKIPPED")
            _G._SR.last_skin_req = args
            pcall(function()
                if h.on_change_collect_hall_skin_rsp then
                    h.on_change_collect_hall_skin_rsp(0, args[1] or 0)
                end
            end)
        end
        n = n + 1
    end

    if type(h.send_unlock_collect_hall_slot_req) == "function" then
        h.send_unlock_collect_hall_slot_req = function(self, ...)
            local args = { ... }
            W("[NET] send_unlock_collect_hall_slot_req SKIPPED")
            _G._SR.last_unlock_req = args
        end
        n = n + 1
    end

    W("[NET] hooked: " .. n)
end

-- ═══════════════════════════════════════════════════════════════════
-- ENTRY HOOK — re-arm on showroom entry
-- ═══════════════════════════════════════════════════════════════════

local function HOOK_ENTRY()
    local e = GM("client.slua.logic.CollectionHall.LogicCollectionHallEntry")
    if not e then
        W("[ENTRY] LogicCollectionHallEntry not loaded")
        return
    end
    HK(e, "EntryVisitCollectionHall", "_sr_entry", function(self, ...)
        W("[ENTRY] showroom entered — re-arming all hooks")
        pcall(HOOK_ALL)
    end)
    W("[ENTRY] hooked")
end

-- ═══════════════════════════════════════════════════════════════════
-- MASTER
-- ═══════════════════════════════════════════════════════════════════

function HOOK_ALL()
    W("═══ RE-ARMING ALL HOOKS ═══")
    pcall(HOOK_SKIN_SLOT_UNLOCK)
    pcall(HOOK_HALL_PART)

    HOOK_DISPLAY("avatar",
        { "GameLua.Mod.PlanCH.Client.SubSystem.Display.PlanCH_Display_Avatar_Client" },
        { "PlanCH_Display_Avatar_Client" })
    HOOK_DISPLAY("vehicle",
        { "GameLua.Mod.PlanCH.Client.SubSystem.Display.PlanCH_Display_Vehicle_Client" },
        { "PlanCH_Display_Vehicle_Client" })
    HOOK_DISPLAY("weapon",
        { "GameLua.Mod.PlanCH.Client.SubSystem.Display.PlanCH_Display_Weapon_Client" },
        { "PlanCH_Display_Weapon_Client" })
    HOOK_DISPLAY("pet",
        { "GameLua.Mod.PlanCH.Client.SubSystem.Display.PlanCH_Display_Pet_Client" },
        { "PlanCH_Display_Pet_Client" })

    pcall(HOOK_NET)
    pcall(HOOK_ENTRY)

    W("═══ ALL HOOKS ARMED ═══")
    FLUSH()
end

-- ═══════════════════════════════════════════════════════════════════
-- BOOT
-- ═══════════════════════════════════════════════════════════════════

local function GETCHAR()
    local ok, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if ok and GD and GD.GetPlayerCharacter then
        local c = GD.GetPlayerCharacter()
        if c and slua.isValid(c) then return c end
    end
    return nil
end

local function BOOT()
    if _G._SR.booted then return end
    _G._SR.booted = true

    _PATH = RESOLVE()
    W("═══════════════════════════════════════════")
    W("  SHOWROOM UNLOCK — session start")
    W("  Path: " .. tostring(_PATH))
    W("═══════════════════════════════════════════")

    HOOK_ALL()

    POPUP("★ " .. CFG.BRAND .. " ★",
        "Loaded.\n\nOpen Collection Showroom\nto test slot unlock.\n\nCheck log:\n" .. tostring(_PATH))

    W("Boot complete")
    FLUSH()
end

local function PHASE()
    local p = "unknown"
    pcall(function()
        if GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity() then p = "lobby" end
        if GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus() then p = "match" end
    end)
    return p
end

local _last_phase = "unknown"

local function WATCH()
    if not _G._SR.booted then
        if GETCHAR() then pcall(BOOT) end
        return
    end
    local p = PHASE()
    if p ~= _last_phase then
        _last_phase = p
        _G._SR.phase = p
        W("[PHASE] → " .. p)
        if p == "lobby" then
            pcall(HOOK_ALL)
        end
    end
end

-- ═══ MANUAL API ═══
_G.SR_Status = function()
    W("─── STATUS ───")
    W("booted=" .. tostring(_G._SR.booted) .. " phase=" .. PHASE())
    W("slot_hooked=" .. tostring(_G._SR.slot_hooked or 0))
    W("showroom_entered=" .. tostring(_G._SR.showroom_entered_at or "never"))
    W("last_edit=" .. tostring(_G._SR.last_edit_req and "yes" or "no"))
    FLUSH()
    print("[SR] status dumped to log")
end
_G.SR_HookNow = function() HOOK_ALL() end
_G.SR_Export = function() FLUSH() end

-- ═══ ARM WATCHDOG ═══
do
    local ok, tk = pcall(require, "common.time_ticker")
    if ok and tk and tk.AddTimerLoop then
        tk.AddTimerLoop(0, WATCH, -1, CFG.TICK)
        W("[WATCHDOG] armed (" .. CFG.TICK .. "s)")
    else
        W("[WATCHDOG] time_ticker missing")
        pcall(WATCH)
    end
end

print("[showroom_unlock.lua v2] loaded — check for popup, then enter showroom")