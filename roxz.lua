-- ═══════════════════════════════════════════════════════════════════
-- sd_v17.lua — AUTO-INJECT on showroom enter
--   No manual command needed. Trigger on EntryVisitCollectionHall.
-- ═══════════════════════════════════════════════════════════════════

_G._SD = _G._SD or { booted = false, log = {} }

local CFG = {
    DUMP_FILE = "sd_v17_log_",
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
    FAKE_VEHICLE = 1901001,
    FAKE_WEAPON  = 101001,
    FAKE_AVATAR  = 1000079,
    SLOT_HALL_PART = 0,
    SLOT_INDEX = 0,
    AUTO_DELAY = 1.0,   -- seconds after showroom enter
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
-- INJECT LOGIC
-- ═══════════════════════════════════════════════════════════════════

local TARGETS = {
    { tag="vehicle", path="GameLua.Mod.PlanCH.Client.SubSystem.Display.PlanCH_Display_Vehicle_Client", fake=CFG.FAKE_VEHICLE },
    { tag="weapon",  path="GameLua.Mod.PlanCH.Client.SubSystem.Display.PlanCH_Display_Weapon_Client",  fake=CFG.FAKE_WEAPON },
    { tag="avatar",  path="GameLua.Mod.PlanCH.Client.SubSystem.Display.PlanCH_Display_Avatar_Client",  fake=CFG.FAKE_AVATAR },
}

local LEARNED = {}

local function TRY_INJECT(tag, path, fake)
    local impl = UNWRAP(GM(path))
    if not impl or type(impl.TryPutOnItem) ~= "function" then
        W("[INJ:" .. tag .. "] not loaded"); return
    end
    W("[INJ:" .. tag .. "] fake=" .. fake)

    -- If we learned real signature from observation, use it
    local sig = LEARNED[tag]
    if sig then
        local args = {}
        for i, a in ipairs(sig) do
            if type(a) == "number" and a == 0 then args[i] = fake
            elseif type(a) == "number" then args[i] = a
            elseif type(a) == "table" then
                local t = {}
                for k, v in pairs(a) do t[k] = v end
                t.res_id = fake; t.resid = fake; t.resID = fake
                args[i] = t
            else args[i] = a end
        end
        local ok = pcall(function() impl:TryPutOnItem(table.unpack(args)) end)
        W("[INJ:" .. tag .. "] learned-sig → ok=" .. tostring(ok))
        if ok then return true end
    end

    -- Fallback variations
    local vars = {
        { CFG.SLOT_HALL_PART, CFG.SLOT_INDEX, fake, 0, 0, 0, 1 },
        { CFG.SLOT_HALL_PART, CFG.SLOT_INDEX, fake, 0, 0, 0, 1, 0 },
        { CFG.SLOT_INDEX, fake, 0, 0, 0, 0, 1 },
        { fake, 0, CFG.SLOT_HALL_PART, CFG.SLOT_INDEX, 0, 0, 1 },
        { { res_id=fake, resid=fake, resID=fake, item_id=fake, count=1,
            ins_id=0, hall_part=CFG.SLOT_HALL_PART, slot_index=CFG.SLOT_INDEX },
          CFG.SLOT_HALL_PART, CFG.SLOT_INDEX, fake, 0, 0, 0, 1 },
    }
    for vi, a in ipairs(vars) do
        local ok, err = pcall(function() impl:TryPutOnItem(table.unpack(a)) end)
        W("[INJ:" .. tag .. "] v" .. vi .. " → ok=" .. tostring(ok) .. " err=" .. tostring(err):sub(1,100))
        if ok then return true end
    end
    return false
end

local function FAB(tag, fake)
    return {
        hall_part=CFG.SLOT_HALL_PART, hallPart=CFG.SLOT_HALL_PART,
        slot_index=CFG.SLOT_INDEX, slotIndex=CFG.SLOT_INDEX, slot=CFG.SLOT_INDEX,
        res_id=fake, resid=fake, resID=fake, item_id=fake, itemid=fake,
        ins_id=0, instid=0, count=1, color=0, pattern=0, level=1,
        is_lock=false, isLock=false, is_unlock=true, isUnlock=true, unlock=true,
    }
end

local function TRY_PROC(tag, path, fake)
    local impl = UNWRAP(GM(path))
    if not impl or type(impl.ProcOneDisplayInfo) ~= "function" then return false end
    local info = FAB(tag, fake)
    local ok = pcall(function() impl:ProcOneDisplayInfo(CFG.SLOT_HALL_PART, info) end)
    if not ok then ok = pcall(function() impl:ProcOneDisplayInfo(info) end) end
    W("[PROC:" .. tag .. "] ok=" .. tostring(ok))
    return ok
end

local function FORCE_REFRESH()
    for _, p in ipairs({
        "GameLua.Mod.PlanCH.Client.SubSystem.Display.PlanCH_Display_Vehicle_Client",
        "GameLua.Mod.PlanCH.Client.SubSystem.Display.PlanCH_Display_Weapon_Client",
        "GameLua.Mod.PlanCH.Client.SubSystem.Display.PlanCH_Display_Avatar_Client",
    }) do
        local impl = UNWRAP(GM(p))
        if impl and type(impl.UpdateDisplayInfoFromDS) == "function" then
            pcall(function() impl:UpdateDisplayInfoFromDS(nil) end)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- PADLOCK HIDE
-- ═══════════════════════════════════════════════════════════════════

local function HIDE_LOCKS(uibp)
    if not uibp then return 0 end
    local n = 0
    pcall(function()
        local ESV = import("ESlateVisibility")
        for k, v in pairs(uibp) do
            if type(k) == "string" and v and slua.isValid(v) then
                local lower = string.lower(k)
                if string.find(lower, "lock", 1, true) or string.find(lower, "padlock", 1, true) then
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

local function HOOK_HIDE_ON_SLOTS()
    for _, key in ipairs(SLOT_KEYS) do
        local impl = UNWRAP(GM("client.slua.umg.lobby.Left.3DUIOverride." .. key))
        if impl then
            for _, fn in ipairs({ "OnPostInitialize","Initialize","OnShow","RefreshModelShow" }) do
                if type(impl[fn]) == "function" and not impl["_sd17_h_" .. fn] then
                    impl["_sd17_h_" .. fn] = true
                    local orig = impl[fn]
                    impl[fn] = function(self, ...)
                        local r = orig(self, ...)
                        local c = GETCHAR()
                        if c and c.AddGameTimer then
                            c:AddGameTimer(0.15, false, function()
                                local cnt = HIDE_LOCKS(self)
                                if cnt > 0 then W("[HIDE] " .. key .. " → " .. cnt) end
                            end)
                        end
                        return r
                    end
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- OBSERVE — learn signatures from natural clicks
-- ═══════════════════════════════════════════════════════════════════

local function HOOK_OBSERVE()
    for _, t in ipairs(TARGETS) do
        local impl = UNWRAP(GM(t.path))
        if impl then
            if type(impl.TryPutOnItem) == "function" and not impl._sd17_observe then
                impl._sd17_observe = true
                local orig = impl.TryPutOnItem
                impl.TryPutOnItem = function(self, ...)
                    local args = { ... }
                    LEARNED[t.tag] = args
                    W("[LEARN:" .. t.tag .. "] TryPutOnItem(" .. #args .. " args)")
                    for i, a in ipairs(args) do
                        local s = tostring(a)
                        if #s > 60 then s = s:sub(1, 60) .. ".." end
                        W("  a" .. i .. " [" .. type(a) .. "] = " .. s)
                    end
                    return orig(self, ...)
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- AUTO-INJECT on showroom enter
-- ═══════════════════════════════════════════════════════════════════

local function AUTO_INJECT()
    W("═══ AUTO INJECT ═══")
    for _, t in ipairs(TARGETS) do
        pcall(TRY_INJECT, t.tag, t.path, t.fake)
        pcall(TRY_PROC, t.tag, t.path, t.fake)
    end
    pcall(FORCE_REFRESH)
    pcall(HOOK_HIDE_ON_SLOTS)
    POPUP("★ SD v17 ★", "Auto-inject done")
    W("═══ AUTO INJECT DONE ═══")
end

local function HOOK_ENTRY()
    -- Multiple entry points to catch showroom open
    local entry = UNWRAP(GM("client.slua.logic.CollectionHall.LogicCollectionHallEntry"))
    if entry then
        HK(entry, "EntryVisitCollectionHall", "_sd17_entry", function()
            W("[ENTRY] showroom entry detected")
            local c = GETCHAR()
            if c and c.AddGameTimer then
                c:AddGameTimer(CFG.AUTO_DELAY, false, AUTO_INJECT)
            else
                AUTO_INJECT()
            end
        end)
        W("[ENTRY] EntryVisitCollectionHall hooked")
    end

    -- Hall data OnHallLevelChanged — fires on showroom load
    local hd = UNWRAP(GM("GameLua.Mod.PlanCH.Client.SubSystem.HallData.PlanCH_HallData_Client"))
    if hd then
        HK(hd, "OnHallLevelChanged", "_sd17_hall", function()
            W("[ENTRY] hall level changed")
            local c = GETCHAR()
            if c and c.AddGameTimer then
                c:AddGameTimer(CFG.AUTO_DELAY, false, AUTO_INJECT)
            end
        end)
    end

    -- Display subsystems OnInit — fires when editor opens
    for _, t in ipairs(TARGETS) do
        local impl = UNWRAP(GM(t.path))
        if impl and type(impl.OnInit) == "function" and not impl._sd17_init then
            impl._sd17_init = true
            local orig = impl.OnInit
            impl.OnInit = function(self, ...)
                W("[ENTRY] " .. t.tag .. " OnInit")
                local c = GETCHAR()
                if c and c.AddGameTimer then
                    c:AddGameTimer(CFG.AUTO_DELAY, false, AUTO_INJECT)
                end
                return orig(self, ...)
            end
        end
    end

    -- OnPostEnterEditMode — for weapon
    local w = UNWRAP(GM("GameLua.Mod.PlanCH.Client.SubSystem.Display.PlanCH_Display_Weapon_Client"))
    if w and type(w.OnPostEnterEditMode) == "function" and not w._sd17_edit then
        w._sd17_edit = true
        local orig = w.OnPostEnterEditMode
        w.OnPostEnterEditMode = function(self, ...)
            W("[ENTRY] weapon edit mode")
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
    W("═══════════════════════════")
    W("  SD v17 — AUTO INJECT")
    W("  Log: " .. tostring(_PATH))
    W("═══════════════════════════")
    pcall(HOOK_ENTRY)
    pcall(HOOK_OBSERVE)
    pcall(HOOK_HIDE_ON_SLOTS)
    POPUP("★ SD v17 ★", "Auto-inject on showroom enter.\nBas showroom kholo.")
    W("Ready — open showroom")
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
            pcall(HOOK_ENTRY)
            pcall(HOOK_OBSERVE)
            pcall(HOOK_HIDE_ON_SLOTS)
        end
    end
end

_G.SD_Inject    = function() AUTO_INJECT() end
_G.SD_Status    = function() W("booted=" .. tostring(_G._SD.booted)); print("[SD] status") end
_G.SD_SetFake   = function(kind, id)
    id = tonumber(id) or 0
    kind = tostring(kind or ""):lower()
    if kind == "vehicle" then CFG.FAKE_VEHICLE = id
    elseif kind == "weapon" then CFG.FAKE_WEAPON = id
    elseif kind == "avatar" then CFG.FAKE_AVATAR = id end
    W("[SET] " .. kind .. " = " .. id)
end

do
    local ok, tk = pcall(require, "common.time_ticker")
    if ok and tk and tk.AddTimerLoop then
        tk.AddTimerLoop(0, WATCH, -1, CFG.TICK)
    else
        pcall(WATCH)
    end
end

print("[sd_v17.lua] AUTO-INJECT loaded")
