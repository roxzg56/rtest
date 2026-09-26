-- ═══════════════════════════════════════════════════════════════════
-- v22 — BUTTON FORCE-OPEN + MINIMAL PET PATCH
-- Path: /storage/emulated/0/Android/data/com.pubg.imobile/files/
-- ═══════════════════════════════════════════════════════════════════

local DIR = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"

local function S(name, content)
    local f = io.open(DIR .. name, "w")
    if not f then return false end
    f:write(content or ""); f:close()
    return true
end

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

S("v22_step0.txt", "v22 loaded at " .. os.date("%Y-%m-%d %H:%M:%S"))

local PET_IDS = {
    50000, 50003, 50004, 50005, 50006, 50007, 50008, 50009, 50010,
    50011, 50012, 50013, 50014, 50015, 50016, 50017, 50018, 50019,
    50020, 50021, 50022, 50023, 50024, 50025, 50026, 50027, 50028,
    50029, 50030, 50031, 50032, 50033, 50034, 50035, 50036, 50037,
    50038, 50039, 50040, 50041, 50042, 50043, 50044, 50045, 50046,
    50047, 50048,
}

_G._V22_EQUIPPED_PET = _G._V22_EQUIPPED_PET or 0

-- ═══════════════════════════════════════════════════════════════════
-- REVERT
-- ═══════════════════════════════════════════════════════════════════
local PREFIXES = {
    "__mini11_", "__v12_", "__v13_", "__v14_", "__v15_", "__v16_",
    "__v17_", "__v18_", "__v19_", "__v20_", "__v21_",
    "__slotv10_", "__pet11_", "__pslotv2_", "__pslot11_",
}
local reverted = 0
local function revertModule(mod)
    if type(mod) ~= "table" then return 0 end
    local cnt = 0
    local backups = {}
    for k in pairs(mod) do
        if type(k) == "string" then
            for _, pfx in ipairs(PREFIXES) do
                if k:sub(1, #pfx) == pfx then
                    backups[#backups+1] = {bk = k, orig = k:sub(#pfx+1)}
                    break
                end
            end
        end
    end
    for _, item in ipairs(backups) do
        if type(mod[item.bk]) == "function" then
            mod[item.orig] = mod[item.bk]
            cnt = cnt + 1
        end
        mod[item.bk] = nil
    end
    return cnt
end

for _, path in ipairs({
    "client.slua.logic.pet.logic_pet",
    "client.slua.logic.pet.pet_manager",
    "client.slua.logic.pet.pet_pawn_pool",
    "client.slua.logic.pet.traits.TLogicPetData",
    "client.slua.logic.pet.traits.TLogicPetCfg",
    "client.slua.logic.pet.traits.TLogicPetNetUtil",
    "client.slua.logic.pet.logic_pet_privilege_guide",
    "client.slua.logic.pet.reddot_pet",
    "client.network.Protocol.PetHandler",
    "GameLua.Mod.Lobby.Base.Collect.logic.collect_pet_module",
}) do
    pcall(function()
        local M = require(path)
        if M and M.__inner_impl and M.__inner_impl ~= M then
            reverted = reverted + revertModule(M.__inner_impl)
        end
        if M and M ~= M.__inner_impl then
            reverted = reverted + revertModule(M)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- WRAP HELPER
-- ═══════════════════════════════════════════════════════════════════
local PFX = "__v22_"
local function wrap(mod, name, wrapper)
    if not mod or type(mod[name]) ~= "function" then return false end
    if not mod[PFX .. name] then mod[PFX .. name] = mod[name] end
    mod[name] = wrapper(mod[PFX .. name])
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- FAKE PET DATA
-- ═══════════════════════════════════════════════════════════════════
local function makeInsID(petID) return 7656927787236720000 + petID * 1000000 end

local function makeFakePet(petID)
    return {
        pet_id = petID, PetID = petID, petItemID = petID, PetItemID = petID,
        itemID = petID, ItemID = petID,
        InsID = makeInsID(petID), insID = makeInsID(petID),
        InstanceID = makeInsID(petID),
        Level = 100, level = 100, Exp = 999999,
        isOwned = true, bIsOwned = true, IsOwned = true,
        isUnlock = true, bIsUnlock = true, unlocked = true,
        IsLocked = false, bIsLock = false, isLock = false,
        IsPermanent = true, bIsPermanent = true, isPermanent = true,
        IsFrozen = false, bIsFrozen = false, isFrozen = false,
        expire_ts = 0, expire_time = 0, expireTime = 0,
        State = 1, state = 1, petState = 1,
        dress_list = {}, DressList = {},
    }
end

-- ═══════════════════════════════════════════════════════════════════
-- PATCH 1: logic_pet — feature + entry
-- ═══════════════════════════════════════════════════════════════════
local p1 = {}
pcall(function()
    local M = require("client.slua.logic.pet.logic_pet")
    local i = M and M.__inner_impl
    if not i then return end

    -- Feature enabled
    if wrap(i, "EnablePetFeature", function(orig)
        return function(self, ...) return true end
    end) then p1[#p1+1] = "EnablePetFeature" end

    -- Show main gate
    if wrap(i, "CheckToShowPetMain", function(orig)
        return function(self, ...) return true end
    end) then p1[#p1+1] = "CheckToShowPetMain" end

    -- Launch
    if wrap(i, "IsPetLaunch", function(orig)
        return function(self, ...) return true end
    end) then p1[#p1+1] = "IsPetLaunch" end

    -- Enter main — FORCE OPEN
    if wrap(i, "EnterMain", function(orig)
        return function(self, ...)
            local ok, err = pcall(orig, self, ...)
            if not ok then
                print("[V22] EnterMain error: " .. tostring(err):sub(1, 120))
            end
            return true
        end
    end) then p1[#p1+1] = "EnterMain" end

    -- Enter pet portal — FORCE OPEN
    if wrap(i, "EnterPetPortal", function(orig)
        return function(self, ...)
            pcall(orig, self, ...)
            return true
        end
    end) then p1[#p1+1] = "EnterPetPortal" end

    -- Open workshop — FORCE OPEN
    if wrap(i, "OpenPetWorkShop", function(orig)
        return function(self, ...)
            pcall(orig, self, ...)
            return true
        end
    end) then p1[#p1+1] = "OpenPetWorkShop" end

    -- Pet state
    if wrap(i, "GetPetState", function(orig)
        return function(self, petID, ...)
            if type(petID) == "number" and petID >= 50000 and petID <= 50099 then
                return 1
            end
            return orig(self, petID, ...)
        end
    end) then p1[#p1+1] = "GetPetState" end

    -- Get my pet data
    if wrap(i, "GetMyPetData", function(orig)
        return function(self, petID, ...)
            local r = orig(self, petID, ...)
            if r and type(r) == "table" then return r end
            if type(petID) == "number" and petID >= 50000 and petID <= 50099 then
                return makeFakePet(petID)
            end
            return r
        end
    end) then p1[#p1+1] = "GetMyPetData" end

    -- List functions — merge all 47
    for _, fn in ipairs({ "GetPetListIncludeInherit", "GetOrderPetList" }) do
        if wrap(i, fn, function(orig)
            return function(self, ...)
                local list = orig(self, ...) or {}
                if type(list) ~= "table" then list = {} end
                for _, pid in ipairs(PET_IDS) do
                    if not list[pid] or type(list[pid]) ~= "table" then
                        list[pid] = makeFakePet(pid)
                    end
                end
                return list
            end
        end) then p1[#p1+1] = fn end
    end

    -- Misc safe
    if wrap(i, "IsMaxLevel", function(orig) return function() return true end end) then p1[#p1+1] = "IsMaxLevel" end
    if wrap(i, "NeedShowExpirationNotice", function(orig) return function() return false end end) then p1[#p1+1] = "NeedShowExpirationNotice" end
    if wrap(i, "GetActionDiff", function(orig) return function() return true end end) then p1[#p1+1] = "GetActionDiff" end
    if wrap(i, "ValidateDataOutDated", function(orig) return function() return false end end) then p1[#p1+1] = "ValidateDataOutDated" end
end)

-- ═══════════════════════════════════════════════════════════════════
-- PATCH 2: TLogicPetData — ownership
-- ═══════════════════════════════════════════════════════════════════
local p2 = {}
pcall(function()
    local D = require("client.slua.logic.pet.traits.TLogicPetData")
    local i = D and D.__inner_impl
    if not i then return end

    local trueFns = {
        "HasPet", "HasPetPermanently", "HavePermanentPet",
        "HasPetIncludeInherit", "IsPetEquip", "HasEquipedPet",
        "HasExpandSlotPriv", "HasPetDress", "HasPetDressPermanently",
        "HasValidPetDress", "HasPetActionDress", "IsInDress", "IsActionUnLock",
    }
    for _, fn in ipairs(trueFns) do
        if wrap(i, fn, function(orig)
            return function(self, petID, ...)
                if type(petID) == "number" and petID >= 50000 and petID <= 50099 then return true end
                return orig(self, petID, ...)
            end
        end) then p2[#p2+1] = fn end
    end

    local falseFns = {
        "IsPetFrozen", "IsPetTimeLimitedOwning", "IsInheritPet",
        "IsPetDressFrozen", "IsDressTimeLimitedOwning",
    }
    for _, fn in ipairs(falseFns) do
        if wrap(i, fn, function(orig)
            return function(self, petID, ...)
                if type(petID) == "number" and petID >= 50000 then return false end
                return orig(self, petID, ...)
            end
        end) then p2[#p2+1] = fn end
    end

    local getterFns = { "GetPetDataByInsID", "GetPetDataByPetItemID",
                        "GetPetDataIncludeInherit", "GetPetInfo" }
    for _, fn in ipairs(getterFns) do
        if wrap(i, fn, function(orig)
            return function(self, key, ...)
                local r = orig(self, key, ...)
                if r and type(r) == "table" then return r end
                local nid = tonumber(key)
                if nid then
                    if nid >= 50000 and nid <= 50099 then return makeFakePet(nid) end
                    if nid >= 7656927787236720000 then
                        local pid = math.floor((nid - 7656927787236720000) / 1000000)
                        if pid >= 50000 and pid <= 50099 then return makeFakePet(pid) end
                    end
                end
                return r
            end
        end) then p2[#p2+1] = fn end
    end

    if wrap(i, "GetOwnedPetList", function(orig)
        return function(self, ...)
            local list = orig(self, ...) or {}
            if type(list) ~= "table" then list = {} end
            for _, pid in ipairs(PET_IDS) do
                if not list[pid] or type(list[pid]) ~= "table" then
                    list[pid] = makeFakePet(pid)
                end
            end
            return list
        end
    end) then p2[#p2+1] = "GetOwnedPetList" end

    if wrap(i, "GetEquipedPetInsID", function(orig)
        return function(self, ...)
            if _G._V22_EQUIPPED_PET > 0 then return makeInsID(_G._V22_EQUIPPED_PET) end
            return orig(self, ...)
        end
    end) then p2[#p2+1] = "GetEquipedPetInsID" end

    if wrap(i, "GetEquipedPetItemID", function(orig)
        return function(self, ...)
            if _G._V22_EQUIPPED_PET > 0 then return _G._V22_EQUIPPED_PET end
            return orig(self, ...)
        end
    end) then p2[#p2+1] = "GetEquipedPetItemID" end

    if wrap(i, "GetMaxCarryPetCount", function(orig) return function() return 6 end end) then p2[#p2+1] = "GetMaxCarryPetCount" end
end)

-- ═══════════════════════════════════════════════════════════════════
-- PATCH 3: TLogicPetCfg — remove LOCK
-- ═══════════════════════════════════════════════════════════════════
local p3 = {}
pcall(function()
    local C = require("client.slua.logic.pet.traits.TLogicPetCfg")
    local i = C and C.__inner_impl
    if not i then return end

    if wrap(i, "IsPetIDBlocked", function(orig)
        return function(self, petID, ...)
            if type(petID) == "number" and petID >= 50000 and petID <= 50099 then return false end
            return orig(self, petID, ...)
        end
    end) then p3[#p3+1] = "IsPetIDBlocked" end

    if wrap(i, "IsPetItemValid", function(orig)
        return function(self, itemID, ...)
            if type(itemID) == "number" and itemID >= 50000 and itemID <= 50099 then return true end
            return orig(self, itemID, ...)
        end
    end) then p3[#p3+1] = "IsPetItemValid" end

    if wrap(i, "IsPetForPrivilegeAssetReady", function(orig) return function() return true end end) then p3[#p3+1] = "IsPetForPrivilegeAssetReady" end
    if wrap(i, "IsPetEnlargeEnabled", function(orig) return function() return true end end) then p3[#p3+1] = "IsPetEnlargeEnabled" end
    if wrap(i, "IsUpgradablePet", function(orig) return function() return true end end) then p3[#p3+1] = "IsUpgradablePet" end
    if wrap(i, "GetUnlockActionNeedLevel", function(orig) return function() return 1 end end) then p3[#p3+1] = "GetUnlockActionNeedLevel" end
end)

-- ═══════════════════════════════════════════════════════════════════
-- PATCH 4: PRIVILEGE GUIDE — remove unlock gate
-- ═══════════════════════════════════════════════════════════════════
local p4 = {}
pcall(function()
    local M = require("client.slua.logic.pet.logic_pet_privilege_guide")
    local i = M and M.__inner_impl
    if not i then return end

    if wrap(i, "_HasPrivilegeForGuidType", function(orig)
        return function(self, ...) return true end
    end) then p4[#p4+1] = "_HasPrivilegeForGuidType" end

    if wrap(i, "IsCanShowGuide", function(orig)
        return function(self, ...) return false end
    end) then p4[#p4+1] = "IsCanShowGuide" end
end)

-- ═══════════════════════════════════════════════════════════════════
-- PATCH 5: NETUTIL — InsID conversion
-- ═══════════════════════════════════════════════════════════════════
local p5 = {}
pcall(function()
    local N = require("client.slua.logic.pet.traits.TLogicPetNetUtil")
    local i = N and N.__inner_impl
    if not i then return end

    if wrap(i, "ConvertToInsID", function(orig)
        return function(self, petID, ...)
            local r = orig(self, petID, ...)
            if r and r ~= 0 then return r end
            if type(petID) == "number" and petID >= 50000 and petID <= 50099 then
                return makeInsID(petID)
            end
            return r
        end
    end) then p5[#p5+1] = "ConvertToInsID" end

    if wrap(i, "ConvertToPetID", function(orig)
        return function(self, insID, ...)
            local r = orig(self, insID, ...)
            if r and r ~= 0 then return r end
            local nid = tonumber(insID)
            if nid and nid >= 7656927787236720000 then
                local pid = math.floor((nid - 7656927787236720000) / 1000000)
                if pid >= 50000 and pid <= 50099 then return pid end
            end
            return r
        end
    end) then p5[#p5+1] = "ConvertToPetID" end

    -- All rsp handlers force err=0
    for name, fn in pairs(i) do
        if type(fn) == "function" and type(name) == "string" then
            local lk = name:lower()
            if lk:find("_rsp") or lk:find("^on_") then
                if wrap(i, name, function(orig)
                    return function(self, ...)
                        local args = {...}
                        if type(args[1]) == "number" and args[1] ~= 0 then args[1] = 0 end
                        return orig(self, table.unpack(args))
                    end
                end) then p5[#p5+1] = name end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- PATCH 6: PET HANDLER — block sends + track equip
-- ═══════════════════════════════════════════════════════════════════
local p6 = {}
pcall(function()
    local H = require("client.network.Protocol.PetHandler")
    if type(H) ~= "table" then return end

    if type(H.send_equip_pet_req) == "function" then
        H.send_equip_pet_req = function(a, b, ...)
            local pid = nil
            for _, v in ipairs({a, b, ...}) do
                if type(v) == "number" and v >= 50000 and v <= 50099 then pid = v break end
            end
            if pid then _G._V22_EQUIPPED_PET = pid end
            pcall(function()
                if type(H.on_equip_pet_rsp) == "function" then pcall(H.on_equip_pet_rsp, 0, pid or a) end
            end)
            return true
        end
        p6[#p6+1] = "send_equip_pet_req"
    end

    if type(H.send_unequip_pet_req) == "function" then
        H.send_unequip_pet_req = function(...)
            _G._V22_EQUIPPED_PET = 0
            pcall(function()
                if type(H.on_unequip_pet_rsp) == "function" then pcall(H.on_unequip_pet_rsp, 0) end
            end)
            return true
        end
        p6[#p6+1] = "send_unequip_pet_req"
    end

    local otherSends = {
        "send_pet_used_dress_req", "send_pet_unload_dress_req",
        "send_pet_add_exp_req", "send_pet_reanme_req",
        "send_pet_action_req", "send_pet_show_req",
        "send_set_pet_color_req", "send_change_pet_model_req",
        "send_get_pet_tab_info_req", "send_get_pet_switch_effect_req",
        "send_set_equip_pet_switch_effect_req", "send_shared_pet_config_req",
        "send_query_pet_dress_shop_info_req", "send_carry_pet_req",
        "send_get_pet_data_req", "send_get_minitv_data_req",
        "send_pet_decompose_list_req", "send_set_assistant_undeploy_req",
    }
    for _, fn in ipairs(otherSends) do
        if type(H[fn]) == "function" then
            local rspName = fn:gsub("^send_", "on_"):gsub("_req$", "_rsp")
            H[fn] = function(...)
                pcall(function()
                    if type(H[rspName]) == "function" then pcall(H[rspName], 0) end
                end)
                return true
            end
            p6[#p6+1] = fn
        end
    end

    for name, fn in pairs(H) do
        if type(fn) == "function" and type(name) == "string" and name:sub(1, 3) == "on_" then
            local orig = fn
            H[name] = function(...)
                local args = {...}
                if type(args[1]) == "number" and args[1] ~= 0 then args[1] = 0 end
                return orig(table.unpack(args))
            end
            p6[#p6+1] = name
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- PATCH 7: MANUAL OPEN UI — agar button kaam na kare
-- ═══════════════════════════════════════════════════════════════════
_G.OpenPetUI = function()
    local opened = false
    local tried = {}

    -- Try UIManager directly
    pcall(function()
        local UM = _G.UIManager
        if UM and type(UM.OpenUI) == "function" then
            local ok = pcall(UM.OpenUI, UM, "pet_main")
            tried[#tried+1] = "UIManager.OpenUI(pet_main)=" .. tostring(ok)
            if ok then opened = true end
        end
        if UM and type(UM.ShowUI) == "function" then
            local ok = pcall(UM.ShowUI, UM, {keyName="pet_main"})
            tried[#tried+1] = "UIManager.ShowUI(pet_main)=" .. tostring(ok)
            if ok then opened = true end
        end
    end)

    -- Try logic_pet.EnterMain
    pcall(function()
        local M = require("client.slua.logic.pet.logic_pet")
        local i = M and M.__inner_impl
        if i and type(i.EnterMain) == "function" then
            local ok = pcall(i.EnterMain, i)
            tried[#tried+1] = "logic_pet.EnterMain=" .. tostring(ok)
            if ok then opened = true end
        end
    end)

    -- Try UI config path
    pcall(function()
        local cfg = package.loaded["client.slua.config.ui_configs.pet_ui_configs"]
        if cfg and cfg.pet_main then
            local path = cfg.pet_main.path
            local UM = _G.UIManager
            if UM and type(UM.ShowUIByPath) == "function" then
                local ok = pcall(UM.ShowUIByPath, UM, path)
                tried[#tried+1] = "ShowUIByPath=" .. tostring(ok)
                if ok then opened = true end
            end
        end
    end)

    P("OpenPetUI", table.concat(tried, "\n"))
    return opened
end

-- ═══════════════════════════════════════════════════════════════════
-- FINAL
-- ═══════════════════════════════════════════════════════════════════
local total = #p1 + #p2 + #p3 + #p4 + #p5 + #p6

S("v22_report.txt",
    "v22 REPORT\n" ..
    "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n" ..
    "Reverted: " .. reverted .. "\n" ..
    "logic_pet: " .. #p1 .. "\n" ..
    "TLogicPetData: " .. #p2 .. "\n" ..
    "TLogicPetCfg: " .. #p3 .. "\n" ..
    "privilege_guide: " .. #p4 .. "\n" ..
    "TLogicPetNetUtil: " .. #p5 .. "\n" ..
    "PetHandler: " .. #p6 .. "\n" ..
    "TOTAL: " .. total .. "\n"
)

P("v22 LOADED",
    "Reverted: " .. reverted .. "\n" ..
    "Patched: " .. total .. "\n\n" ..
    "Test:\n" ..
    "1. Companion button dabao\n" ..
    "2. Agar button na chale:\n" ..
    "   OpenPetUI() call karo\n" ..
    "3. Pets unlocked dikhenge\n" ..
    "4. Equip karo")

return true
