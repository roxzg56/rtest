-- ═══════════════════════════════════════════════════════════════════
-- v21 — SURGICAL PET UNLOCK
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

S("v21_step0.txt", "v21 loaded at " .. os.date("%Y-%m-%d %H:%M:%S"))

local PET_IDS = {
    50000, 50003, 50004, 50005, 50006, 50007, 50008, 50009, 50010,
    50011, 50012, 50013, 50014, 50015, 50016, 50017, 50018, 50019,
    50020, 50021, 50022, 50023, 50024, 50025, 50026, 50027, 50028,
    50029, 50030, 50031, 50032, 50033, 50034, 50035, 50036, 50037,
    50038, 50039, 50040, 50041, 50042, 50043, 50044, 50045, 50046,
    50047, 50048,
}

-- GLOBAL: store equipped pet locally
_G._V21_EQUIPPED_PET = _G._V21_EQUIPPED_PET or 0
_G._V21_EQUIPPED_INS = _G._V21_EQUIPPED_INS or 0

-- ═══════════════════════════════════════════════════════════════════
-- REVERT every prefix
-- ═══════════════════════════════════════════════════════════════════
local PREFIXES = {
    "__mini11_", "__v12_", "__v13_", "__v14_", "__v15_", "__v16_",
    "__v17_", "__v18_", "__v19_", "__v20_",
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
    "client.slua.logic.pet.reddot_pet",
    "client.slua.logic.pet.logic_pet_privilege_guide",
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

S("v21_step1.txt", "Reverted: " .. reverted)

-- ═══════════════════════════════════════════════════════════════════
-- WRAP HELPER
-- ═══════════════════════════════════════════════════════════════════
local PFX = "__v21_"
local function wrap(mod, name, wrapper)
    if not mod or type(mod[name]) ~= "function" then return false end
    if not mod[PFX .. name] then mod[PFX .. name] = mod[name] end
    mod[name] = wrapper(mod[PFX .. name])
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- FAKE PET DATA — with proper InsID 19-digit format
-- ═══════════════════════════════════════════════════════════════════
local function makeInsID(petID)
    -- Real InsIDs are ~19 digits starting with 7
    return 7656927787236720000 + petID * 1000000
end

local function makeFakePet(petID)
    local insID = makeInsID(petID)
    return {
        -- IDs (all variants)
        pet_id = petID, PetID = petID, petID = petID,
        petItemID = petID, PetItemID = petID,
        item_id = petID, itemID = petID, ItemID = petID,
        id = petID, ID = petID,
        InsID = insID, insID = insID, ins_id = insID,
        InstanceID = insID, instanceID = insID,
        PetInstanceID = insID, PetInsID = insID,
        
        -- Ownership (all variants)
        isOwned = true, bIsOwned = true, IsOwned = true,
        owned = true, has = true, has_pet = true,
        isUnlock = true, bIsUnlock = true, isUnlocked = true,
        unlocked = true, is_lock = false, bIsLock = false,
        isLock = false, IsLock = false, IsLocked = false,
        bLock = false, lock = false,
        
        -- Level
        Level = 100, level = 100, lv = 100, petLevel = 100,
        Exp = 999999, exp = 999999,
        MaxExp = 999999, maxExp = 999999,
        
        -- Time
        expire_ts = 0, expire_time = 0, expireTime = 0,
        ExpireTS = 0, ExpireTime = 0, expireTs = 0,
        isPermanent = true, IsPermanent = true, bIsPermanent = true,
        isFrozen = false, IsFrozen = false, bIsFrozen = false,
        
        -- State
        State = 1, state = 1, petState = 1, PetState = 1,
        
        -- Dress
        dress_list = {}, DressList = {}, dress = {},
        cur_dress = {}, DressIDs = {}, dressIDs = {},
        
        -- Misc
        SkinID = 0, skinID = 0, curSkinID = 0,
        ColorID = 0, colorID = 0,
        ActionList = {}, actionList = {},
        UnlockActions = {},
    }
end

-- ═══════════════════════════════════════════════════════════════════
-- PATCH 1: TLogicPetData — ownership (has all variants)
-- ═══════════════════════════════════════════════════════════════════
local p1 = {}
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
                if type(petID) == "number" and petID >= 50000 and petID <= 50099 then
                    return true
                end
                return orig(self, petID, ...)
            end
        end) then p1[#p1+1] = fn end
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
        end) then p1[#p1+1] = fn end
    end

    -- Data getters — return fake for any pet
    local getterFns = { "GetPetDataByInsID", "GetPetDataByPetItemID",
                        "GetPetDataIncludeInherit", "GetPetInfo" }
    for _, fn in ipairs(getterFns) do
        if wrap(i, fn, function(orig)
            return function(self, key, ...)
                local r = orig(self, key, ...)
                if r and type(r) == "table" then return r end
                local nid = tonumber(key)
                if nid then
                    if nid >= 50000 and nid <= 50099 then
                        return makeFakePet(nid)
                    end
                    -- insID reverse lookup
                    if nid >= 7656927787236720000 then
                        local pid = math.floor((nid - 7656927787236720000) / 1000000)
                        if pid >= 50000 and pid <= 50099 then
                            return makeFakePet(pid)
                        end
                    end
                end
                return r
            end
        end) then p1[#p1+1] = fn end
    end

    -- Owned list — merge all
    local listFns = { "GetOwnedPetList", "GetPetDataIncludeInherit" }
    for _, fn in ipairs(listFns) do
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

    -- Equipped ins id
    if wrap(i, "GetEquipedPetInsID", function(orig)
        return function(self, ...)
            local r = orig(self, ...)
            if r and r ~= 0 then return r end
            if _G._V21_EQUIPPED_PET > 0 then
                return makeInsID(_G._V21_EQUIPPED_PET)
            end
            return r
        end
    end) then p1[#p1+1] = "GetEquipedPetInsID" end

    if wrap(i, "GetEquipedPetItemID", function(orig)
        return function(self, ...)
            local r = orig(self, ...)
            if r and r ~= 0 then return r end
            if _G._V21_EQUIPPED_PET > 0 then return _G._V21_EQUIPPED_PET end
            return r
        end
    end) then p1[#p1+1] = "GetEquipedPetItemID" end

    -- Counts
    if wrap(i, "GetMaxCarryPetCount", function(orig) 
        return function(self, ...) return 6 end 
    end) then p1[#p1+1] = "GetMaxCarryPetCount" end
end)

-- ═══════════════════════════════════════════════════════════════════
-- PATCH 2: logic_pet — main data
-- ═══════════════════════════════════════════════════════════════════
local p2 = {}
pcall(function()
    local M = require("client.slua.logic.pet.logic_pet")
    local i = M and M.__inner_impl
    if not i then return end

    -- List functions — merge all (this is the one that fixes LOCK)
    local listFns = { "GetPetListIncludeInherit", "GetOrderPetList" }
    for _, fn in ipairs(listFns) do
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
        end) then p2[#p2+1] = fn end
    end

    -- GetMyPetData
    if wrap(i, "GetMyPetData", function(orig)
        return function(self, petID, ...)
            local r = orig(self, petID, ...)
            if r and type(r) == "table" then return r end
            if type(petID) == "number" and petID >= 50000 and petID <= 50099 then
                return makeFakePet(petID)
            end
            return r
        end
    end) then p2[#p2+1] = "GetMyPetData" end

    -- State
    if wrap(i, "GetPetState", function(orig)
        return function(self, petID, ...)
            if type(petID) == "number" and petID >= 50000 and petID <= 50099 then
                return 1
            end
            return orig(self, petID, ...)
        end
    end) then p2[#p2+1] = "GetPetState" end

    -- Various — safe defaults
    if wrap(i, "IsMaxLevel", function(orig) 
        return function(self, ...) return true end 
    end) then p2[#p2+1] = "IsMaxLevel" end

    if wrap(i, "EnablePetFeature", function(orig) 
        return function(self, ...) return true end 
    end) then p2[#p2+1] = "EnablePetFeature" end

    if wrap(i, "IsPetLaunch", function(orig) 
        return function(self, ...) return true end 
    end) then p2[#p2+1] = "IsPetLaunch" end

    if wrap(i, "CheckToShowPetMain", function(orig) 
        return function(self, ...) return true end 
    end) then p2[#p2+1] = "CheckToShowPetMain" end

    if wrap(i, "NeedShowExpirationNotice", function(orig) 
        return function(self, ...) return false end 
    end) then p2[#p2+1] = "NeedShowExpirationNotice" end

    if wrap(i, "GetActionDiff", function(orig) 
        return function(self, ...) return true end 
    end) then p2[#p2+1] = "GetActionDiff" end
end)

-- ═══════════════════════════════════════════════════════════════════
-- PATCH 3: TLogicPetCfg — item validity (removes lock icon)
-- ═══════════════════════════════════════════════════════════════════
local p3 = {}
pcall(function()
    local C = require("client.slua.logic.pet.traits.TLogicPetCfg")
    local i = C and C.__inner_impl
    if not i then return end

    if wrap(i, "IsPetIDBlocked", function(orig)
        return function(self, petID, ...)
            if type(petID) == "number" and petID >= 50000 and petID <= 50099 then
                return false
            end
            return orig(self, petID, ...)
        end
    end) then p3[#p3+1] = "IsPetIDBlocked" end

    if wrap(i, "IsPetItemValid", function(orig)
        return function(self, itemID, ...)
            if type(itemID) == "number" and itemID >= 50000 and itemID <= 50099 then
                return true
            end
            return orig(self, itemID, ...)
        end
    end) then p3[#p3+1] = "IsPetItemValid" end

    if wrap(i, "IsPetForPrivilegeAssetReady", function(orig) 
        return function(self, ...) return true end 
    end) then p3[#p3+1] = "IsPetForPrivilegeAssetReady" end

    if wrap(i, "IsPetEnlargeEnabled", function(orig) 
        return function(self, ...) return true end 
    end) then p3[#p3+1] = "IsPetEnlargeEnabled" end

    if wrap(i, "IsUpgradablePet", function(orig) 
        return function(self, ...) return true end 
    end) then p3[#p3+1] = "IsUpgradablePet" end

    if wrap(i, "GetUnlockActionNeedLevel", function(orig) 
        return function(self, ...) return 1 end 
    end) then p3[#p3+1] = "GetUnlockActionNeedLevel" end
end)

-- ═══════════════════════════════════════════════════════════════════
-- PATCH 4: TLogicPetNetUtil — ConvertToInsID + rsp handlers
-- ═══════════════════════════════════════════════════════════════════
local p4 = {}
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
    end) then p4[#p4+1] = "ConvertToInsID" end

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
    end) then p4[#p4+1] = "ConvertToPetID" end

    -- All rsp handlers → force err=0
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
                end) then p4[#p4+1] = name end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- PATCH 5: PET HANDLER — block sends + force rsp + track equip
-- ═══════════════════════════════════════════════════════════════════
local p5 = {}
pcall(function()
    local H = require("client.network.Protocol.PetHandler")
    if type(H) ~= "table" then return end

    -- Equip: capture petID, store globally, don't send
    if type(H.send_equip_pet_req) == "function" then
        H.send_equip_pet_req = function(petID, ...)
            -- Try to extract petID from args
            local pid = nil
            if type(petID) == "number" and petID >= 50000 and petID <= 50099 then
                pid = petID
            end
            if not pid then
                -- scan args
                for n = 1, select("#", petID, ...) do
                    local v = select(n, petID, ...)
                    if type(v) == "number" and v >= 50000 and v <= 50099 then
                        pid = v
                        break
                    end
                end
            end
            if pid then
                _G._V21_EQUIPPED_PET = pid
                _G._V21_EQUIPPED_INS = makeInsID(pid)
                print("[V21] EQUIPPED pet=" .. pid)
            end
            -- Fake rsp
            pcall(function()
                if type(H.on_equip_pet_rsp) == "function" then
                    pcall(H.on_equip_pet_rsp, 0, pid or petID)
                end
            end)
            return true
        end
        p5[#p5+1] = "send_equip_pet_req"
    end

    -- Unequip
    if type(H.send_unequip_pet_req) == "function" then
        H.send_unequip_pet_req = function(...)
            _G._V21_EQUIPPED_PET = 0
            _G._V21_EQUIPPED_INS = 0
            pcall(function()
                if type(H.on_unequip_pet_rsp) == "function" then
                    pcall(H.on_unequip_pet_rsp, 0)
                end
            end)
            return true
        end
        p5[#p5+1] = "send_unequip_pet_req"
    end

    -- Other sends block
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
                    if type(H[rspName]) == "function" then
                        pcall(H[rspName], 0)
                    end
                end)
                return true
            end
            p5[#p5+1] = fn
        end
    end

    -- Force all rsp err=0
    for name, fn in pairs(H) do
        if type(fn) == "function" and type(name) == "string" and name:sub(1, 3) == "on_" then
            local orig = fn
            H[name] = function(...)
                local args = {...}
                if type(args[1]) == "number" and args[1] ~= 0 then args[1] = 0 end
                local ok, err = pcall(orig, table.unpack(args))
                return ok, err
            end
            p5[#p5+1] = name
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- PATCH 6: COLLECT PET MODULE
-- ═══════════════════════════════════════════════════════════════════
local p6 = {}
pcall(function()
    local M = require("GameLua.Mod.Lobby.Base.Collect.logic.collect_pet_module")
    local i = M and M.__inner_impl
    if not i then return end

    if wrap(i, "GetPetOwnedData", function(orig)
        return function(self, ...)
            local list = orig(self, ...) or {}
            if type(list) ~= "table" then list = {} end
            for _, pid in ipairs(PET_IDS) do
                if not list[pid] then list[pid] = makeFakePet(pid) end
            end
            return list
        end
    end) then p6[#p6+1] = "GetPetOwnedData" end

    if wrap(i, "HasRed", function(orig) 
        return function(self, ...) return false end 
    end) then p6[#p6+1] = "HasRed" end
end)

-- ═══════════════════════════════════════════════════════════════════
-- PATCH 7: AUTO-REAPPLY every 3s
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerLoop then
        ticker.AddTimerLoop(0, function()
            pcall(function()
                -- Keep pet list populated in case server cleared it
                local D = require("client.slua.logic.pet.traits.TLogicPetData")
                if D and D.__inner_impl then
                    -- nothing to do here, wraps handle it
                end
            end)
        end, -1, 3.0)
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- REPORT
-- ═══════════════════════════════════════════════════════════════════
local total = #p1 + #p2 + #p3 + #p4 + #p5 + #p6

S("v21_report.txt",
    "v21 REPORT\n" ..
    "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n" ..
    "Reverted: " .. reverted .. "\n" ..
    "TLogicPetData: " .. #p1 .. " (list=" .. table.concat(p1, ",") .. ")\n" ..
    "logic_pet: " .. #p2 .. " (list=" .. table.concat(p2, ",") .. ")\n" ..
    "TLogicPetCfg: " .. #p3 .. " (list=" .. table.concat(p3, ",") .. ")\n" ..
    "TLogicPetNetUtil: " .. #p4 .. "\n" ..
    "PetHandler: " .. #p5 .. "\n" ..
    "collect_pet: " .. #p6 .. "\n" ..
    "TOTAL: " .. total .. "\n"
)

P("v21 LOADED",
    "Reverted: " .. reverted .. "\n" ..
    "Patched: " .. total .. "\n\n" ..
    "Test:\n" ..
    "1. Pet menu kholo\n" ..
    "2. Sab pets UNLOCKED dikhne chahiye\n" ..
    "3. Koi pet pe click\n" ..
    "4. Equip dabao\n\n" ..
    "Report: v21_report.txt")

return true
