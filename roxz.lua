-- ═══════════════════════════════════════════════════════════════════
-- sd_v18.lua — CLEAN INJECT (from learned signatures)
--   weapon/avatar: v3 pattern (0, res_id, 0, 0, 0, 0, 1) → OK
--   vehicle:       force via ProcOneDisplayInfo (TryPutOnItem crashes)
--   padlock kill:  aggressive widget scan
-- ═══════════════════════════════════════════════════════════════════

_G._SD = _G._SD or { booted = false, log = {} }

local CFG = {
    DUMP_FILE = "sd_v18_log_",
    SAVE_DIRS = {
        "/storage/emulated/0/Android/data/com.pubg.imobile/files/",
        "/storage/emulated/0/Android/data/com.pubg.krmobile/files/",
        "/storage/emulated/0/Android/data/com.pubg.vng.pubgmobile/files/",
        "/storage/emulated/0/Android/data/com.vng.pubgmobile/files/",
        "/storage/emulated/0/Android/data/com.rekoo.pubgm/files/",
        "/sdcard/",
    },
    SAVE_KEY = "config.ini",
    TICK = 1.5,
    AUTO_DELAY = 0.8,
    -- Change these to inject other items
    FAKE_VEHICLE = 1901001,
    FAKE_WEAPON  = 101001,
    FAKE_AVATAR  = 1000079,
}

local function POPUP(t, m)
    pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
                    or require("client.slua.logic.common.logic_common_msg_box")
        if Msg and Msg.Show then Msg.Show(4, tostring(t), tostring(m)) end
    end)
end

local _PATH = nil
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
    local full = "[" .. os.date("%H:%M:%S") .. "] " .. tostring(line)
    _G._SD.log[#_G._SD.log+1] = full
    if _PATH then pcall(function()
        local f = io.open(_PATH, "a"); if f then f:write(full .. "\n"); f:close() end
    end) end
    print("[SD] " .. full)
end

local function GM(p)
    local m = package.loaded[p]; if m then return m end
    local ok, r = pcall(require, p); if ok then return r end
    return nil
end
local function UNWRAP(m)
    if not m then return nil end
    if type(m) == "table" and type(m.__inner_impl) == "table" then return m.__inner_impl end
    return m
end
local function HK(owner, name, tag, cb)
    if not owner then return false end
    local ok, tv = pcall(function() return owner[tag] end)
    if ok and tv then return true end
    local ok2, t = pcall(function() return type(owner[name]) end)
    if not ok2 or t ~= "function" then return false end
    local ok3, orig = pcall(function() return owner[name] end)
    if not ok3 then return false end
    return pcall(function()
        owner[tag] = true
        owner[name] = function(self, ...) pcall(cb, self, ...); return orig(self, ...) end
    end)
end
local function GETCHAR()
    local ok, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if ok and GD and GD.GetPlayerCharacter then
        local c = GD.GetPlayerCharacter()
        if c and slua.isValid(c) then return c end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════
-- CLEAN INJECT — only the v3 pattern (which worked)
-- ═══════════════════════════════════════════════════════════════════

local WEAPON_PATH  = "GameLua.Mod.PlanCH.Client.SubSystem.Display.PlanCH_Display_Weapon_Client"
local AVATAR_PATH  = "GameLua.Mod.PlanCH.Client.SubSystem.Display.PlanCH_Display_Avatar_Client"
local VEHICLE_PATH = "GameLua.Mod.PlanCH.Client.SubSystem.Display.PlanCH_Display_Vehicle_Client"

local function INJECT_V3(tag, path, fake)
    local impl = UNWRAP(GM(path))
    if not impl or type(impl.TryPutOnItem) ~= "function" then
        W("[INJ:" .. tag .. "] not available"); return false
    end
    -- v3 pattern: (0, res_id, 0, 0, 0, 0, 1)
    local ok, err = pcall(function() impl:TryPutOnItem(0, fake, 0, 0, 0, 0, 1) end)
    W("[INJ:" .. tag .. "] v3 → ok=" .. tostring(ok) .. (ok and "" or (" err=" .. tostring(err):sub(1,100))))
    return ok
end

-- Fallback: ProcOneDisplayInfo for vehicle (which crashed on TryPutOnItem)
local function FABRICATE_INFO(tag, fake)
    return {
        hall_part=0, hallPart=0,
        slot_index=0, slotIndex=0, slot=0,
        res_id=fake, resid=fake, resID=fake,
        item_id=fake, itemid=fake,
        ins_id=0, instid=0,
        count=1, color=0, pattern=0, level=1,
        is_lock=false, isLock=false,
        is_unlock=true, isUnlock=true, unlock=true,
    }
end

local function INJECT_PROC(tag, path, fake)
    local impl = UNWRAP(GM(path))
    if not impl or type(impl.ProcOneDisplayInfo) ~= "function" then return false end
    local info = FABRICATE_INFO(tag, fake)
    local ok, err = pcall(function() impl:ProcOneDisplayInfo(0, info) end)
    W("[PROC:" .. tag .. "] → ok=" .. tostring(ok) .. (ok and "" or (" err=" .. tostring(err):sub(1,100))))
    return ok
end

-- ═══════════════════════════════════════════════════════════════════
-- AGGRESSIVE PADLOCK KILL
-- ═══════════════════════════════════════════════════════════════════

local function KILL_ALL_LOCKS(uibp, tag)
    if not uibp or type(uibp) ~= "table" then return 0 end
    local n = 0
    pcall(function()
        local ESV = import("ESlateVisibility")
        for k, v in pairs(uibp) do
            if type(k) == "string" and v and slua.isValid(v) then
                local lower = string.lower(k)
                if string.find(lower, "lock", 1, true) or string.find(lower, "padlock", 1, true)
                   or string.find(lower, "kong", 1, true) or string.find(lower, "suo", 1, true) then
                    pcall(function()
                        if v.SetVisibility then v:SetVisibility(ESV and ESV.Collapsed or 2) end
                        if v.SetRenderOpacity then v:SetRenderOpacity(0) end
                    end)
                    n = n + 1
                end
            end
        end
    end)
    return n
end

local SLOT_KEYS = {
    "SocialLobby_AvatarShowSlot_UIBP","SocialLobby_VehicleSlot_UIBP",
    "SocialLobby_WeaponSlot_UIBP","SocialLobby_PetSlot_UIBP","SocialLobby_BGWallSlot_UIBP",
}

local function HOOK_SLOT_UI_ONCE(key)
    local impl = UNWRAP(GM("client.slua.umg.lobby.Left.3DUIOverride." .. key))
    if not impl then return end
    for _, fn in ipairs({ "OnPostInitialize","Initialize","OnShow","RefreshModelShow","OnUpdateVehicleFeatureData" }) do
        if type(impl[fn]) == "function" and not impl["_sd18_" .. fn] then
            impl["_sd18_" .. fn] = true
            local orig = impl[fn]
            impl[fn] = function(self, ...)
                local r = orig(self, ...)
                local c = GETCHAR()
                if c and c.AddGameTimer then
                    c:AddGameTimer(0.15, false, function()
                        local cnt = KILL_ALL_LOCKS(self, key)
                        if cnt > 0 then W("[HIDE] " .. key .. "→" .. cnt) end
                    end)
                else
                    KILL_ALL_LOCKS(self, key)
                end
                return r
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- KILL LOCK POPUP
-- ═══════════════════════════════════════════════════════════════════

local function KILL_POPUP()
    local popup = UNWRAP(GM("GameLua.Mod.PlanCH.Client.UI.Popup.PlanCH_Hall_Slot_Locked_UIBP"))
    if not popup then return end
    for _, fn in ipairs({ "OnShow","UpdateUI","UpdateSlotInfo","OnHallSlotUnlock","AdjustUIPosition" }) do
        pcall(function() popup[fn] = function() end end)
    end
    W("[POPUP] locked popup killed")
end

-- ═══════════════════════════════════════════════════════════════════
-- MAIN AUTO INJECT
-- ═══════════════════════════════════════════════════════════════════

local function AUTO_INJECT()
    W("═══ INJECT ═══")

    -- Weapon: v3 pattern works
    INJECT_V3("weapon", WEAPON_PATH, CFG.FAKE_WEAPON)
    INJECT_PROC("weapon", WEAPON_PATH, CFG.FAKE_WEAPON)

    -- Avatar: v3 pattern works
    INJECT_V3("avatar", AVATAR_PATH, CFG.FAKE_AVATAR)
    INJECT_PROC("avatar", AVATAR_PATH, CFG.FAKE_AVATAR)

    -- Vehicle: TryPutOnItem crashes, so just ProcOneDisplayInfo + direct display info injection
    INJECT_PROC("vehicle", VEHICLE_PATH, CFG.FAKE_VEHICLE)

    -- Kill padlocks
    for _, key in ipairs(SLOT_KEYS) do
        local impl = UNWRAP(GM("client.slua.umg.lobby.Left.3DUIOverride." .. key))
        if impl then KILL_ALL_LOCKS(impl, key) end
    end

    W("═══ DONE ═══")
end

-- ═══════════════════════════════════════════════════════════════════
-- HOOK ENTRY
-- ═══════════════════════════════════════════════════════════════════

local function HOOK_ENTRY()
    local entry = UNWRAP(GM("client.slua.logic.CollectionHall.LogicCollectionHallEntry"))
    if entry then
        HK(entry, "EntryVisitCollectionHall", "_sd18_entry", function()
            W("[ENTRY] showroom enter")
            local c = GETCHAR()
            if c and c.AddGameTimer then
                c:AddGameTimer(CFG.AUTO_DELAY, false, AUTO_INJECT)
            else
                AUTO_INJECT()
            end
        end)
    end

    -- OnInit triggers
    for _, path in ipairs({ WEAPON_PATH, AVATAR_PATH, VEHICLE_PATH }) do
        local impl = UNWRAP(GM(path))
        if impl and type(impl.OnInit) == "function" and not impl._sd18_init then
            impl._sd18_init = true
            local orig = impl.OnInit
            impl.OnInit = function(self, ...)
                local c = GETCHAR()
                if c and c.AddGameTimer then
                    c:AddGameTimer(CFG.AUTO_DELAY, false, AUTO_INJECT)
                end
                return orig(self, ...)
            end
        end
    end

    -- Weapon edit mode
    local w = UNWRAP(GM(WEAPON_PATH))
    if w and type(w.OnPostEnterEditMode) == "function" and not w._sd18_edit then
        w._sd18_edit = true
        local orig = w.OnPostEnterEditMode
        w.OnPostEnterEditMode = function(self, ...)
            local c = GETCHAR()
            if c and c.AddGameTimer then c:AddGameTimer(CFG.AUTO_DELAY, false, AUTO_INJECT) end
            return orig(self, ...)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- BOOT
-- ═══════════════════════════════════════════════════════════════════

local function BOOT()
    if _G._SD.booted then return end
    _G._SD.booted = true
    _PATH = RESOLVE()
    W("═══════════════════")
    W("  SD v18")
    W("  Log: " .. tostring(_PATH))
    W("═══════════════════")
    pcall(KILL_POPUP)
    pcall(HOOK_ENTRY)
    for _, k in ipairs(SLOT_KEYS) do pcall(HOOK_SLOT_UI_ONCE, k) end
    POPUP("★ SD v18 ★", "Clean inject + padlock kill.\nShowroom kholo.")
    W("Ready")
end

local function PHASE()
    local p = "unknown"
    pcall(function()
        if GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity() then p = "lobby" end
        if GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus() then p = "match" end
    end)
    return p
end

local _last = "unknown"
local function WATCH()
    if not _G._SD.booted then
        if GETCHAR() then pcall(BOOT) end
        return
    end
    local p = PHASE()
    if p ~= _last then
        _last = p
        W("[PHASE] → " .. p)
        if p == "lobby" then
            pcall(KILL_POPUP)
            pcall(HOOK_ENTRY)
            for _, k in ipairs(SLOT_KEYS) do pcall(HOOK_SLOT_UI_ONCE, k) end
        end
    end
end

-- Manual
_G.SD_Inject = function() AUTO_INJECT() end
_G.SD_KillLocks = function()
    for _, key in ipairs(SLOT_KEYS) do
        local impl = UNWRAP(GM("client.slua.umg.lobby.Left.3DUIOverride." .. key))
        if impl then KILL_ALL_LOCKS(impl, key) end
    end
    W("[MANUAL] locks killed")
end
_G.SD_SetFake = function(kind, id)
    id = tonumber(id) or 0
    kind = tostring(kind or ""):lower()
    if kind == "vehicle" then CFG.FAKE_VEHICLE = id
    elseif kind == "weapon" then CFG.FAKE_WEAPON = id
    elseif kind == "avatar" then CFG.FAKE_AVATAR = id end
end

do
    local ok, tk = pcall(require, "common.time_ticker")
    if ok and tk and tk.AddTimerLoop then
        tk.AddTimerLoop(0, WATCH, -1, CFG.TICK)
    else
        pcall(WATCH)
    end
end

print("[sd_v18.lua] loaded")
