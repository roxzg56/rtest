-- ═══════════════════════════════════════════════════════════════════
-- sd_v15.lua — FAKE ITEM INJECT into showroom display slots
--   Approach: call TryPutOnItem directly with our fake ID
--             + hide padlock overlay
--             + force refresh
-- ═══════════════════════════════════════════════════════════════════

_G._SD = _G._SD or { booted = false, log = {} }

local CFG = {
    DUMP_FILE = "sd_v15_log_",
    SAVE_DIRS = {
        "/storage/emulated/0/Android/data/com.pubg.imobile/files/",
        "/storage/emulated/0/Android/data/com.pubg.krmobile/files/",
        "/storage/emulated/0/Android/data/com.pubg.vng.pubgmobile/files/",
        "/storage/emulated/0/Android/data/com.pubg.vng.pubgmobile/files/",
        "/storage/emulated/0/Android/data/com.rekoo.pubgm/files/",
        "/sdcard/",
    },
    SAVE_KEY = "config.ini",
    TICK = 2.0,
    -- Fake IDs to inject (change these!)
    FAKE_VEHICLE = 1903193,   -- sample vehicle skin ID
    FAKE_WEAPON  = 101001,    -- sample weapon skin ID
    FAKE_AVATAR  = 1000079,   -- sample outfit ID
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
local function GMM(name)
    local ok, MM = pcall(require, "client.module_framework.ModuleManager")
    if not ok or not MM then return nil end
    local ok2, m = pcall(function() return MM.GetModule(name) end)
    if ok2 then return m end
    return nil
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
-- 1. DUMP TryPutOnItem signature via arity and first-call args
-- ═══════════════════════════════════════════════════════════════════

local function DUMP_DISPLAY_IMPL(tag, path)
    local impl = UNWRAP(GM(path))
    if not impl then W("[DUMP:" .. tag .. "] not loaded"); return end
    W("─── DUMP " .. tag .. " ───")
    local keys = {}
    for k in pairs(impl) do keys[#keys+1] = k end
    table.sort(keys, function(a,b) return tostring(a) < tostring(b) end)
    for _, k in ipairs(keys) do
        local v = impl[k]
        if type(k) == "string" then
            if type(v) == "function" then
                local info = debug and debug.getinfo and debug.getinfo(v)
                local n = info and info.nparams or "?"
                W("  fn: " .. k .. " (nparams=" .. tostring(n) .. ")")
            elseif type(v) == "table" then
                local n = 0; for _ in pairs(v) do n = n + 1 end
                W("  tbl[" .. n .. "]: " .. k)
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- 2. HOOK TryPutOnItem — observe args to learn signature
-- ═══════════════════════════════════════════════════════════════════

local LEARNED = { signature = nil }

local function HOOK_LEARN(tag, path)
    local impl = UNWRAP(GM(path))
    if not impl or type(impl.TryPutOnItem) ~= "function" then return end
    if impl._sd15_learn then return end
    impl._sd15_learn = true

    local orig = impl.TryPutOnItem
    impl.TryPutOnItem = function(self, ...)
        local args = { ... }
        W("[LEARN:" .. tag .. "] TryPutOnItem called with " .. #args .. " args:")
        for i, a in ipairs(args) do
            local t = type(a)
            local v = tostring(a)
            if #v > 60 then v = v:sub(1, 60) .. "..." end
            W("  arg" .. i .. " [" .. t .. "] = " .. v)
        end
        LEARNED.signature = args
        return orig(self, ...)
    end
    W("[LEARN:" .. tag .. "] TryPutOnItem hooked")
end

-- ═══════════════════════════════════════════════════════════════════
-- 3. INJECT FAKE ITEM — attempt using learned signature
-- ═══════════════════════════════════════════════════════════════════

local function INJECT_FAKE(tag, path, fakeID)
    local impl = UNWRAP(GM(path))
    if not impl or type(impl.TryPutOnItem) ~= "function" then
        W("[INJECT:" .. tag .. "] TryPutOnItem not available"); return
    end

    W("[INJECT:" .. tag .. "] attempting with ID " .. tostring(fakeID))

    -- Strategy 1: match learned signature
    local attempts = {
        -- pattern: function that builds args based on learned slot count
        function()
            local sig = LEARNED.signature
            if not sig then return false end
            local n = #sig
            local args = {}
            for i = 1, n do
                local a = sig[i]
                if type(a) == "number" and a == 0 then
                    args[i] = fakeID
                elseif type(a) == "number" then
                    args[i] = a
                elseif type(a) == "table" then
                    -- Try to inject into table
                    local t = {}
                    for k, v in pairs(a) do t[k] = v end
                    t.resid = fakeID
                    t.resID = fakeID
                    t.item_id = fakeID
                    t.itemid = fakeID
                    args[i] = t
                else
                    args[i] = a
                end
            end
            return pcall(function() impl:TryPutOnItem(table.unpack(args)) end)
        end,
        -- Strategy 2: common patterns (hall_part, slot_idx, item_res, item_ins, color, pattern, level, flag)
        function() return pcall(function() impl:TryPutOnItem(1, 0, fakeID, 0, 0, 0, 1, 0) end) end,
        -- Strategy 3: (slot_id, res_id, ins_id)
        function() return pcall(function() impl:TryPutOnItem(0, fakeID, 0) end) end,
        -- Strategy 4: (res_id, ins_id)
        function() return pcall(function() impl:TryPutOnItem(fakeID, 0) end) end,
        -- Strategy 5: single arg
        function() return pcall(function() impl:TryPutOnItem(fakeID) end) end,
    }

    for i, fn in ipairs(attempts) do
        local ok, result = fn()
        W("[INJECT:" .. tag .. "] attempt " .. i .. " → ok=" .. tostring(ok) .. " result=" .. tostring(result))
        if ok then break end
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- 4. HIDE PADLOCK OVERLAY
-- ═══════════════════════════════════════════════════════════════════

local function HIDE_LOCKS(uibp, tag)
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

local function HOOK_HIDE_SLOTS()
    local keys = {
        "SocialLobby_AvatarShowSlot_UIBP",
        "SocialLobby_VehicleSlot_UIBP",
        "SocialLobby_WeaponSlot_UIBP",
        "SocialLobby_PetSlot_UIBP",
        "SocialLobby_BGWallSlot_UIBP",
    }
    for _, key in ipairs(keys) do
        local impl = UNWRAP(GM("client.slua.umg.lobby.Left.3DUIOverride." .. key))
        if impl then
            for _, fn in ipairs({ "OnPostInitialize", "Initialize", "OnShow", "RefreshModelShow" }) do
                if type(impl[fn]) == "function" and not impl["_sd15_h_" .. fn] then
                    impl["_sd15_h_" .. fn] = true
                    local orig = impl[fn]
                    impl[fn] = function(self, ...)
                        local r = orig(self, ...)
                        local c = GETCHAR()
                        if c and c.AddGameTimer then
                            c:AddGameTimer(0.2, false, function()
                                local cnt = HIDE_LOCKS(self, key)
                                if cnt > 0 then W("[HIDE] " .. key .. "." .. fn .. " → " .. cnt) end
                            end)
                        else
                            HIDE_LOCKS(self, key)
                        end
                        return r
                    end
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- 5. FORCE REFRESH after inject
-- ═══════════════════════════════════════════════════════════════════

local function FORCE_REFRESH()
    -- Try to trigger model manager refresh
    local mm = UNWRAP(GM("GameLua.Mod.PlanCH.Client.SubSystem.Display.PlanCH_Display_Model_Manager_SubSystem_Client"))
    if mm then
        pcall(function()
            for k, v in pairs(mm) do
                if type(k) == "string" and type(v) == "function" then
                    local lower = string.lower(k)
                    if string.find(lower, "refresh", 1, true) or string.find(lower, "update", 1, true) then
                        pcall(function() mm[k](mm) end)
                    end
                end
            end
        end)
    end
    -- Try event post
    pcall(function()
        if EventSystem and EventSystem.postEvent then
            for _, ev in ipairs({ "EVENTID_HALL_DISPLAY_CHANGED", "EVENTID_SHOWROOM_REFRESH" }) do
                if _G[ev] then EventSystem:postEvent(EVENTTYPE_LOBBY, _G[ev]) end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- 6. UC SPOOF (keep working)
-- ═══════════════════════════════════════════════════════════════════

local KEYS = { "ticket","uc","gold","diamond","eternal_diamond","home_coin","bp","coupon","voucher" }
local function SPOOF_UC()
    local dm = _G.DataMgr
    if not dm then return end
    pcall(function() for _, k in ipairs(KEYS) do dm[k] = 999999999 end end)
    pcall(function()
        local mt = getmetatable(dm) or {}
        local old = mt.__index
        mt.__index = function(t, k)
            for _, key in ipairs(KEYS) do if k == key then return 999999999 end end
            if type(old) == "function" then return old(t, k) end
            if type(old) == "table" then return old[k] end
            return rawget(t, k)
        end
        setmetatable(dm, mt)
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- MASTER
-- ═══════════════════════════════════════════════════════════════════

local DISPLAY_PATHS = {
    { tag = "vehicle", path = "GameLua.Mod.PlanCH.Client.SubSystem.Display.PlanCH_Display_Vehicle_Client", fake = CFG.FAKE_VEHICLE },
    { tag = "weapon",  path = "GameLua.Mod.PlanCH.Client.SubSystem.Display.PlanCH_Display_Weapon_Client",  fake = CFG.FAKE_WEAPON },
    { tag = "avatar",  path = "GameLua.Mod.PlanCH.Client.SubSystem.Display.PlanCH_Display_Avatar_Client",  fake = CFG.FAKE_AVATAR },
}

function HOOK_ALL()
    W("═══ SD v15 ═══")
    pcall(SPOOF_UC)

    -- Dump + learn
    for _, dp in ipairs(DISPLAY_PATHS) do
        pcall(DUMP_DISPLAY_IMPL, dp.tag, dp.path)
        pcall(HOOK_LEARN, dp.tag, dp.path)
    end

    pcall(HOOK_HIDE_SLOTS)
    W("═══ DONE — enter showroom, click slots once to learn signature ═══")
end

-- Manual inject command
_G.SD_InjectFake = function()
    for _, dp in ipairs(DISPLAY_PATHS) do
        pcall(INJECT_FAKE, dp.tag, dp.path, dp.fake)
    end
    pcall(FORCE_REFRESH)
    W("[MANUAL] inject attempted")
end

_G.SD_SetFake = function(kind, id)
    kind = tostring(kind or ""):lower()
    id = tonumber(id) or 0
    if kind == "vehicle" then CFG.FAKE_VEHICLE = id
    elseif kind == "weapon" then CFG.FAKE_WEAPON = id
    elseif kind == "avatar" then CFG.FAKE_AVATAR = id end
    W("[MANUAL] " .. kind .. " = " .. id)
end

_G.SD_HideLocks = function()
    local total = 0
    for _, key in ipairs({
        "SocialLobby_AvatarShowSlot_UIBP","SocialLobby_VehicleSlot_UIBP",
        "SocialLobby_WeaponSlot_UIBP","SocialLobby_PetSlot_UIBP","SocialLobby_BGWallSlot_UIBP",
    }) do
        local impl = UNWRAP(GM("client.slua.umg.lobby.Left.3DUIOverride." .. key))
        if impl then total = total + HIDE_LOCKS(impl, key) end
    end
    W("[MANUAL] hid " .. total .. " lock widgets")
end

-- ═══════════════════════════════════════════════════════════════════
-- BOOT
-- ═══════════════════════════════════════════════════════════════════

local function BOOT()
    if _G._SD.booted then return end
    _G._SD.booted = true
    _PATH = RESOLVE()
    W("═══════════════════════════")
    W("  SD v15 — FAKE INJECT")
    W("  Log: " .. tostring(_PATH))
    W("═══════════════════════════")
    pcall(HOOK_ALL)
    POPUP("★ SD v15 ★", "Enter showroom.\nClick any slot once.\nThen use: _G.SD_InjectFake()")
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
    pcall(SPOOF_UC)

    local p = PHASE()
    if p ~= _last then
        _last = p
        W("[PHASE] → " .. p)
        if p == "lobby" then
            pcall(HOOK_HIDE_SLOTS)
            for _, dp in ipairs(DISPLAY_PATHS) do pcall(HOOK_LEARN, dp.tag, dp.path) end
        end
    end
end

_G.SD_Status = function()
    W("── STATUS ──")
    W("booted=" .. tostring(_G._SD.booted))
    W("learned_signature=" .. (LEARNED.signature and ("yes, " .. #LEARNED.signature .. " args") or "no"))
    print("[SD] status")
end

do
    local ok, tk = pcall(require, "common.time_ticker")
    if ok and tk and tk.AddTimerLoop then
        tk.AddTimerLoop(0, WATCH, -1, CFG.TICK)
    else
        pcall(WATCH)
    end
end

print("[sd_v15.lua] FAKE INJECT loaded")
