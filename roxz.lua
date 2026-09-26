-- ═══════════════════════════════════════════════════════════════════
-- v13 BULLETPROOF
-- Har step file + popup. Kuch bhi silent fail nahi hoga.
-- Path: /storage/emulated/0/Android/data/com.pubg.imobile/files/
-- ═══════════════════════════════════════════════════════════════════

local DIR = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"
local STEP = 0

-- ─── FILE WRITER (sabse pehle test) ────────────────────────────────
local function S(name, content)
    local f = io.open(DIR .. name, "w")
    if not f then return false end
    f:write(content or "")
    f:close()
    return true
end

-- ─── POPUP WRITER ──────────────────────────────────────────────────
local function P(t, m)
    pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
        if not Msg then
            local ok, r = pcall(require, "client.slua.logic.common.logic_common_msg_box")
            if ok then Msg = r end
        end
        if Msg and Msg.Show then
            Msg.Show(1, tostring(t), tostring(m), function() end, function() end, "OK", "CLOSE")
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 0 — PROOF OF LIFE (happens immediately, before anything else)
-- ═══════════════════════════════════════════════════════════════════
STEP = 0
local s0 = S("v13_step0.txt", "Step 0 - file loaded at " .. os.date("%Y-%m-%d %H:%M:%S"))
print("[V13] STEP 0 — file loaded, s0=" .. tostring(s0))

-- ═══════════════════════════════════════════════════════════════════
-- STEP 1 — REVERT V11
-- ═══════════════════════════════════════════════════════════════════
STEP = 1
local reverted = 0
local revertErr = ""

pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    if M and M.__inner_impl then
        local i = M.__inner_impl
        local keys = {}
        for k in pairs(i) do
            if type(k) == "string" and k:sub(1, 9) == "__mini11_" then
                keys[#keys+1] = k
            end
        end
        for _, k in ipairs(keys) do
            local orig = k:sub(10)
            if type(i[k]) == "function" then
                i[orig] = i[k]
                reverted = reverted + 1
            end
            i[k] = nil
        end
    end
end)

pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyEditMgrModule")
    if M and M.__inner_impl then
        local i = M.__inner_impl
        local keys = {}
        for k in pairs(i) do
            if type(k) == "string" and k:sub(1, 9) == "__mini11_" then
                keys[#keys+1] = k
            end
        end
        for _, k in ipairs(keys) do
            local orig = k:sub(10)
            if type(i[k]) == "function" then
                i[orig] = i[k]
                reverted = reverted + 1
            end
            i[k] = nil
        end
    end
end)

S("v13_step1.txt", "Step 1 - reverted " .. reverted .. " v11 functions")
print("[V13] STEP 1 — reverted: " .. reverted)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 2 — APPLY SLOT UNLOCK
-- ═══════════════════════════════════════════════════════════════════
STEP = 2
local unlockCount = 0
local PFX = "__v13_"

local function wrap(tbl, name, wrapper)
    if not tbl or type(tbl[name]) ~= "function" then return false end
    if not tbl[PFX .. name] then tbl[PFX .. name] = tbl[name] end
    tbl[name] = wrapper(tbl[PFX .. name])
    return true
end

pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    local i = M and M.__inner_impl
    if not i then return end

    if wrap(i, "GetSlotIsUnlockedByCollectHallLevel", function(orig)
        return function(self, st, idx, ...)
            return true
        end
    end) then unlockCount = unlockCount + 1 end

    if wrap(i, "GetSlotIsUnlockBySlotTypeAndIndex", function(orig)
        return function(self, st, idx, ...)
            return true
        end
    end) then unlockCount = unlockCount + 1 end
end)

S("v13_step2.txt", "Step 2 - slot unlock applied: " .. unlockCount)
print("[V13] STEP 2 — unlock: " .. unlockCount)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 3 — APPLY SLOT EQUIP
-- ═══════════════════════════════════════════════════════════════════
STEP = 3
local equipCount = 0

pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    local i = M and M.__inner_impl
    if not i then return end

    for _, fn in ipairs({
        "WeaponSlotEquipItemId", "VehicleSlotEquipItemId",
        "PetSlotEquipItemId", "PetSlotEquipClotheItemId",
        "BGWallSlotEquipItemId", "AvatarShowSlotEquipItemId",
        "AchievementSlotEquipItemId",
    }) do
        if type(i[fn]) == "function" then
            wrap(i, fn, function(orig)
                return function(self, ...)
                    pcall(orig, self, ...)
                    return true
                end
            end)
            equipCount = equipCount + 1
        end
    end

    if wrap(i, "CheckSlotTypeIsUseItemId", function(orig)
        return function(self, ...) return true end
    end) then equipCount = equipCount + 1 end
end)

S("v13_step3.txt", "Step 3 - slot equip applied: " .. equipCount)
print("[V13] STEP 3 — equip: " .. equipCount)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 4 — FIX SAVE FLOW (RSP only, NOT state trackers)
-- ═══════════════════════════════════════════════════════════════════
STEP = 4
local rspCount = 0

pcall(function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyEditMgrModule")
    local i = M and M.__inner_impl
    if not i then return end

    -- ONLY RSP handlers — force success
    local rspHandlers = {
        "on_edit_all_collect_hall_rsp",
        "on_edit_honor_display_rsp",
        "on_set_collect_hall_background_rsp",
    }
    for _, fn in ipairs(rspHandlers) do
        if type(i[fn]) == "function" then
            wrap(i, fn, function(orig)
                return function(self, err, ...)
                    local ok, r = pcall(orig, self, 0, ...)
                    return ok and r or true
                end
            end)
            rspCount = rspCount + 1
        end
    end
end)

S("v13_step4.txt", "Step 4 - RSP forced: " .. rspCount)
print("[V13] STEP 4 — rsp: " .. rspCount)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 5 — NETWORK HANDLERS
-- ═══════════════════════════════════════════════════════════════════
STEP = 5
local netCount = 0

pcall(function()
    for _, path in ipairs({
        "client.network.Protocol.SocialLobbyHandler",
        "client.network.Protocol.CollectHallHandler",
    }) do
        local ok, H = pcall(require, path)
        if ok and type(H) == "table" then
            for name, fn in pairs(H) do
                if type(fn) == "function" and type(name) == "string" and name:find("send_") then
                    local rspName = name:gsub("^send_", "on_"):gsub("_req$", "_rsp")
                    if type(H[rspName]) == "function" then
                        H[name] = function(...)
                            pcall(H[rspName], 0)
                            return true
                        end
                        netCount = netCount + 1
                    end
                end
            end
        end
    end
end)

S("v13_step5.txt", "Step 5 - network wrapped: " .. netCount)
print("[V13] STEP 5 — net: " .. netCount)

-- ═══════════════════════════════════════════════════════════════════
-- FINAL REPORT
-- ═══════════════════════════════════════════════════════════════════
local report = "v13 REPORT\n"
    .. "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"
    .. "Step 0: file loaded = " .. tostring(s0) .. "\n"
    .. "Step 1: reverted v11 = " .. reverted .. "\n"
    .. "Step 2: slot unlock = " .. unlockCount .. "\n"
    .. "Step 3: slot equip = " .. equipCount .. "\n"
    .. "Step 4: RSP handlers = " .. rspCount .. "\n"
    .. "Step 5: network = " .. netCount .. "\n"

S("v13_report.txt", report)
print("[V13] REPORT WRITTEN")

-- ═══════════════════════════════════════════════════════════════════
-- POPUP — multiple attempts (in case first one fails)
-- ═══════════════════════════════════════════════════════════════════
local popupMsg = "Reverted: " .. reverted .. "\n"
    .. "Unlock: " .. unlockCount .. "\n"
    .. "Equip: " .. equipCount .. "\n"
    .. "RSP: " .. rspCount .. "\n"
    .. "Net: " .. netCount

P("v13 LOADED", popupMsg)
print("[V13] POPUP FIRED (1st attempt)")

-- Schedule follow-up popup in case first one got missed
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(3.0, function()
            P("v13 CONFIRMED", popupMsg)
            print("[V13] POPUP FIRED (2nd attempt - delayed)")
        end)
        ticker.AddTimerOnce(8.0, function()
            P("v13 STILL RUNNING", "If you see this, code is active.\n\n" .. popupMsg)
            print("[V13] POPUP FIRED (3rd attempt - delayed)")
        end)
    end
end)

print("[V13] === ALL DONE ===")

return true
