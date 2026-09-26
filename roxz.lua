-- ═══════════════════════════════════════════════════════════════════
-- v20 — CLEAN SLATE REVERT + SURGICAL PET UNLOCK
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

S("v20_step0.txt", "v20 loaded at " .. os.date("%Y-%m-%d %H:%M:%S"))

-- ═══════════════════════════════════════════════════════════════════
-- STEP 1: NUCLEAR REVERT — every prefix, every module
-- ═══════════════════════════════════════════════════════════════════
local PREFIXES = {
    "__mini11_", "__v12_", "__v13_", "__v14_", "__v15_", "__v16_",
    "__v17_", "__v18_", "__v19_",
    "__slotv10_", "__pet11_", "__pslotv2_", "__pslot11_",
}

local reverted = 0
local modulesReverted = {}

local function revertModule(mod, modName)
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
    if cnt > 0 and modName then
        modulesReverted[#modulesReverted+1] = modName .. ":" .. cnt
    end
    return cnt
end

-- All modules we've EVER touched across v10-v19
local ALL_MODULES = {
    -- Pet
    "client.slua.logic.pet.logic_pet",
    "client.slua.logic.pet.pet_manager",
    "client.slua.logic.pet.pet_pawn_pool",
    "client.slua.logic.pet.pet_config",
    "client.slua.logic.pet.reddot_pet",
    "client.slua.logic.pet.logic_pet_privilege_guide",
    "client.slua.logic.pet.traits.TLogicPetData",
    "client.slua.logic.pet.traits.TLogicPetCfg",
    "client.slua.logic.pet.traits.TLogicPetNetUtil",
    "client.network.Protocol.PetHandler",
    "GameLua.Mod.Lobby.Base.Collect.logic.collect_pet_module",
    -- UI (ye tha jo menu tod diya)
    "client.slua.umg.pet.pet_main",
    "client.slua.umg.pet.pet_choosepet",
    "client.slua.umg.pet.pet_carry_select",
    "client.slua.umg.pet.pet_levelup",
    "client.slua.umg.pet.pet_setting",
    "client.slua.umg.pet.pet_feed",
    "client.slua.umg.pet.pet_rename",
    "client.slua.umg.pet.pet_share",
    "client.slua.umg.pet.pet_access",
    "client.slua.umg.pet.pet_dress_card",
    "client.slua.umg.pet.pet_decompose_notice",
    -- Slots
    "client.slua.logic.lobby.Left.Logic_SocialLobbyModule",
    "client.slua.logic.lobby.Left.Logic_SocialLobbyEditMgrModule",
    "client.logic.lobby.ThemeVehicleManager",
    "client.logic.vehicle.VehicleCollectSystem",
    "client.logic.vehicle.LogicVehicleExtendedFeature",
    "client.logic.vehicle.LogicVehicleAccessory",
    -- Handlers
    "client.network.Protocol.SocialLobbyHandler",
    "client.network.Protocol.CollectHallHandler",
    "client.network.Protocol.SocialCardBGHandler",
}

for _, path in ipairs(ALL_MODULES) do
    pcall(function()
        local M = require(path)
        if M and M.__inner_impl and M.__inner_impl ~= M then
            reverted = reverted + revertModule(M.__inner_impl, path .. ".inner")
        end
        if M and M ~= M.__inner_impl then
            reverted = reverted + revertModule(M, path)
        end
        -- Also check package.loaded directly
        local M2 = package.loaded[path]
        if M2 and M2 ~= M then
            if M2.__inner_impl then
                reverted = reverted + revertModule(M2.__inner_impl)
            end
            reverted = reverted + revertModule(M2)
        end
    end)
end

S("v20_step1.txt", "Reverted: " .. reverted .. "\nModules:\n" .. table.concat(modulesReverted, "\n"))

-- ═══════════════════════════════════════════════════════════════════
-- STEP 2: VERIFY MENU WORKS (test only, no patch)
-- ═══════════════════════════════════════════════════════════════════
S("v20_step2.txt", "Menu should work now (no UI patches)")

-- ═══════════════════════════════════════════════════════════════════
-- STEP 3: MINIMAL SURGICAL PATCH — ONLY 6 functions
-- ═══════════════════════════════════════════════════════════════════
local PFX = "__v20_"
local function wrap(mod, name, wrapper)
    if not mod or type(mod[name]) ~= "function" then return false end
    if not mod[PFX .. name] then mod[PFX .. name] = mod[name] end
    mod[name] = wrapper(mod[PFX .. name])
    return true
end

local patched = {}

-- ═══════════════════════════════════════════════════════════════════
-- PATCH 1: Pet ownership — HasPet returns true (only this)
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local D = require("client.slua.logic.pet.traits.TLogicPetData")
    local i = D and D.__inner_impl
    if not i then return end

    if wrap(i, "HasPet", function(orig)
        return function(self, petID, ...)
            -- Only bypass for pet IDs (50000-50099)
            if type(petID) == "number" and petID >= 50000 and petID <= 50099 then
                return true
            end
            return orig(self, petID, ...)
        end
    end) then patched[#patched+1] = "HasPet" end

    if wrap(i, "HasPetPermanently", function(orig)
        return function(self, petID, ...)
            if type(petID) == "number" and petID >= 50000 and petID <= 50099 then
                return true
            end
            return orig(self, petID, ...)
        end
    end) then patched[#patched+1] = "HasPetPermanently" end
end)

-- ═══════════════════════════════════════════════════════════════════
-- PATCH 2: IsPetFrozen → false (no expiry)
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local D = require("client.slua.logic.pet.traits.TLogicPetData")
    local i = D and D.__inner_impl
    if not i then return end

    if wrap(i, "IsPetFrozen", function(orig)
        return function(self, petID, ...)
            if type(petID) == "number" and petID >= 50000 then return false end
            return orig(self, petID, ...)
        end
    end) then patched[#patched+1] = "IsPetFrozen" end
end)

-- ═══════════════════════════════════════════════════════════════════
-- PATCH 3: GetPetState → unlocked
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local M = require("client.slua.logic.pet.logic_pet")
    local i = M and M.__inner_impl
    if not i then return end

    if wrap(i, "GetPetState", function(orig)
        return function(self, petID, ...)
            if type(petID) == "number" and petID >= 50000 and petID <= 50099 then
                return 1
            end
            return orig(self, petID, ...)
        end
    end) then patched[#patched+1] = "GetPetState" end
end)

-- ═══════════════════════════════════════════════════════════════════
-- PATCH 4: Pet data getter — real InsID from CDataTable if exists
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local D = require("client.slua.logic.pet.traits.TLogicPetData")
    local i = D and D.__inner_impl
    if not i then return end

    if wrap(i, "GetPetDataByPetItemID", function(orig)
        return function(self, petID, ...)
            local r = orig(self, petID, ...)
            if r then return r end
            if type(petID) == "number" and petID >= 50000 and petID <= 50099 then
                -- Try to fetch REAL config from CDataTable
                local cfg = nil
                pcall(function()
                    cfg = CDataTable.GetTableData("Pet", petID)
                end)
                if cfg then
                    return {
                        pet_id = petID, PetID = petID, PetItemID = petID,
                        itemID = petID, ItemID = petID,
                        InsID = cfg.InsID or cfg.insID or (petID * 1000),
                        Level = cfg.Level or 1, level = 1,
                        isOwned = true, IsLocked = false, isPermanent = true,
                        expire_ts = 0, dress_list = {},
                    }
                end
                -- Fallback — no CDataTable entry
                return {
                    pet_id = petID, PetID = petID, PetItemID = petID,
                    itemID = petID, ItemID = petID,
                    InsID = petID * 1000, Level = 1, level = 1,
                    isOwned = true, IsLocked = false, isPermanent = true,
                    expire_ts = 0, dress_list = {},
                }
            end
            return r
        end
    end) then patched[#patched+1] = "GetPetDataByPetItemID" end
end)

-- ═══════════════════════════════════════════════════════════════════
-- PATCH 5: Equip request — don't send to server
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local H = require("client.network.Protocol.PetHandler")
    if type(H) ~= "table" then return end

    local sendBlock = {
        "send_equip_pet_req",
        "send_unequip_pet_req",
        "send_pet_used_dress_req",
        "send_pet_unload_dress_req",
    }
    for _, fn in ipairs(sendBlock) do
        if type(H[fn]) == "function" then
            local rspName = fn:gsub("^send_", "on_"):gsub("_req$", "_rsp")
            H[fn] = function(...)
                pcall(function()
                    if type(H[rspName]) == "function" then pcall(H[rspName], 0) end
                end)
                return true
            end
            patched[#patched+1] = fn
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- PATCH 6: Equip rsp — force success
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local H = require("client.network.Protocol.PetHandler")
    if type(H) ~= "table" then return end

    local rspForce = {
        "on_equip_pet_rsp",
        "on_unequip_pet_rsp",
        "on_pet_used_dress_rsp",
        "on_pet_unload_dress_rsp",
    }
    for _, fn in ipairs(rspForce) do
        if type(H[fn]) == "function" then
            local orig = H[fn]
            H[fn] = function(...)
                local args = {...}
                if type(args[1]) == "number" and args[1] ~= 0 then
                    args[1] = 0
                end
                local ok, err = pcall(orig, table.unpack(args))
                return ok, err
            end
            patched[#patched+1] = fn
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- FINAL REPORT
-- ═══════════════════════════════════════════════════════════════════
S("v20_report.txt",
    "v20 CLEAN REPORT\n" ..
    "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n" ..
    "Reverted: " .. reverted .. " functions\n" ..
    "Patched: " .. #patched .. " functions\n" ..
    "Patched functions:\n" ..
    table.concat(patched, "\n")
)

P("v20 CLEAN",
    "Reverted: " .. reverted .. "\n" ..
    "Patched: " .. #patched .. "\n\n" ..
    "Ab check karo:\n" ..
    "1. Companion button kaam karta?\n" ..
    "2. Menu khulta?\n" ..
    "3. Pet click?\n\n" ..
    "Report bhej: v20_report.txt")

return true
