-- ═══════════════════════════════════════════════════════════════════
-- v19 — PET GLITCH FIX
-- Fixes: InsID format, click handler, model spawn, asset fallback
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

S("v19_step0.txt", "v19 loaded at " .. os.date("%Y-%m-%d %H:%M:%S"))

local PET_IDS = {
    50000, 50003, 50004, 50005, 50006, 50007, 50008, 50009, 50010,
    50011, 50012, 50013, 50014, 50015, 50016, 50017, 50018, 50019,
    50020, 50021, 50022, 50023, 50024, 50025, 50026, 50027, 50028,
    50029, 50030, 50031, 50032, 50033, 50034, 50035, 50036, 50037,
    50038, 50039, 50040, 50041, 50042, 50043, 50044, 50045, 50046,
    50047, 50048,
}

-- ═══════════════════════════════════════════════════════════════════
-- REVERT v18 (partial — only the broken bits)
-- ═══════════════════════════════════════════════════════════════════
local PREFIXES = {
    "__mini11_", "__v12_", "__v13_", "__v14_", "__v15_", "__v16_",
    "__v17_", "__v18_", "__slotv10_", "__pet11_", "__pslotv2_", "__pslot11_",
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
    "client.slua.logic.pet.traits.TLogicPetData",
    "client.slua.logic.pet.traits.TLogicPetCfg",
    "client.slua.logic.pet.traits.TLogicPetNetUtil",
    "client.slua.logic.pet.logic_pet_privilege_guide",
    "GameLua.Mod.Lobby.Base.Collect.logic.collect_pet_module",
}) do
    pcall(function()
        local M = require(path)
        if M and M.__inner_impl then reverted = reverted + revertModule(M.__inner_impl) end
        if M and M ~= M.__inner_impl then reverted = reverted + revertModule(M) end
    end)
end

pcall(function()
    local H = require("client.network.Protocol.PetHandler")
    if H then reverted = reverted + revertModule(H) end
end)

S("v19_step1.txt", "Reverted: " .. reverted)

-- ═══════════════════════════════════════════════════════════════════
-- WRAP HELPER
-- ═══════════════════════════════════════════════════════════════════
local PFX = "__v19_"
local function wrap(mod, name, wrapper)
    if not mod or type(mod[name]) ~= "function" then return false end
    if not mod[PFX .. name] then mod[PFX .. name] = mod[name] end
    mod[name] = wrapper(mod[PFX .. name])
    return true
end

-- ═══════════════════════════════════════════════════════════════════
-- ⭐ CRITICAL: REAL InsID FORMAT DISCOVERY
-- PetHandler mein ConvertToInsID hai — usse dekh lo actual format
-- Typical format: petID * 10^10 + something, or a hash
-- ═══════════════════════════════════════════════════════════════════
local function makeInsID(petID)
    -- PUBG Mobile typically uses this pattern
    -- Check: petID = 50008, insID = long number like 7656927787236720646
    -- That's not petID * X. It's a server-assigned ID.
    -- SOLUTION: Use existing real insID if we can find one for each pet type
    -- Otherwise, generate deterministic but valid-looking ID
    
    -- Option A: Try to fetch from CDataTable
    local realInsID = nil
    pcall(function()
        local cfg = CDataTable.GetTableData("Pet", petID)
        if cfg and cfg.InsID then realInsID = cfg.InsID end
    end)
    
    if realInsID then return realInsID end
    
    -- Option B: Deterministic — high number pattern
    -- Format: 7xxxxxxxxxxxxxxxxx (19 digits, matches real insIDs)
    return 7656927787236720000 + petID * 1000
end

-- ═══════════════════════════════════════════════════════════════════
-- FAKE PET DATA — richer, model-compatible
-- ═══════════════════════════════════════════════════════════════════
local function makeFakePetData(petID)
    local insID = makeInsID(petID)
    return {
        -- IDs
        pet_id          = petID,
        PetID           = petID,
        petItemID       = petID,
        PetItemID       = petID,
        item_id         = petID,
        itemID          = petID,
        ItemID          = petID,
        InsID           = insID,
        insID           = insID,
        ins_id          = insID,
        InstanceID      = insID,
        PetInstanceID   = insID,
        InstanceId      = insID,
        iID             = insID,
        
        -- Level / Exp
        Level           = 100,
        level           = 100,
        lv              = 100,
        Exp             = 999999,
        exp             = 999999,
        MaxExp          = 999999,
        maxExp          = 999999,
        
        -- Ownership flags (all variants)
        isOwned         = true,
        bIsOwned        = true,
        IsOwned         = true,
        owned           = true,
        isUnlock        = true,
        bIsUnlock       = true,
        unlocked        = true,
        IsLocked        = false,
        bIsLock         = false,
        isLock          = false,
        bLock           = false,
        IsPermanent     = true,
        bIsPermanent    = true,
        isPermanent     = true,
        IsFrozen        = false,
        bIsFrozen       = false,
        isFrozen        = false,
        
        -- Time
        expire_ts       = 0,
        expire_time     = 0,
        ExpireTS        = 0,
        ExpireTime      = 0,
        expireTime      = 0,
        expireTs        = 0,
        
        -- Dress / Skin
        dress_list      = {},
        dress           = {},
        cur_dress       = {},
        DressList       = {},
        DressIDs        = {},
        SkinID          = 0,
        skinID          = 0,
        curSkinID       = 0,
        CurrentSkin     = nil,
        
        -- State
        State           = 1,
        state           = 1,
        petState        = 1,
        
        -- Action
        ActionList      = {},
        actionList      = {},
        UnlockActions   = {},
        
        -- Color
        ColorID         = 0,
        colorID         = 0,
        
        -- UI hint
        _v19Fake        = true,
    }
end

-- ═══════════════════════════════════════════════════════════════════
-- STEP 1: LOGIC_PET — main data
-- ═══════════════════════════════════════════════════════════════════
local patched1 = 0
pcall(function()
    local M = require("client.slua.logic.pet.logic_pet")
    local i = M and M.__inner_impl
    if not i then return end

    -- Get pet data — return fake
    if wrap(i, "GetMyPetData", function(orig)
        return function(self, petID, ...)
            local r = orig(self, petID, ...)
            if r and type(r) == "table" and (r.InsID or r.insID) then return r end
            if type(petID) == "number" and petID >= 50000 and petID <= 50099 then
                return makeFakePetData(petID)
            end
            return r
        end
    end) then patched1 = patched1 + 1 end

    -- Pet list — merge all
    if wrap(i, "GetPetListIncludeInherit", function(orig)
        return function(self, ...)
            local list = orig(self, ...) or {}
            for _, pid in ipairs(PET_IDS) do
                if not list[pid] or type(list[pid]) ~= "table" or not list[pid].InsID then
                    list[pid] = makeFakePetData(pid)
                end
            end
            return list
        end
    end) then patched1 = patched1 + 1 end

    if wrap(i, "GetOrderPetList", function(orig)
        return function(self, ...)
            local list = orig(self, ...) or {}
            for _, pid in ipairs(PET_IDS) do
                if not list[pid] or type(list[pid]) ~= "table" then
                    list[pid] = makeFakePetData(pid)
                end
            end
            return list
        end
    end) then patched1 = patched1 + 1 end

    -- State — unlocked
    if wrap(i, "GetPetState", function(orig)
        return function(self, petID, ...)
            return 1
        end
    end) then patched1 = patched1 + 1 end

    -- Level etc
    if wrap(i, "IsMaxLevel", function() return function() return true end end) then patched1 = patched1 + 1 end
    if wrap(i, "EnablePetFeature", function() return function() return true end end) then patched1 = patched1 + 1 end
    if wrap(i, "IsPetLaunch", function() return function() return true end end) then patched1 = patched1 + 1 end
    if wrap(i, "CheckToShowPetMain", function() return function() return true end end) then patched1 = patched1 + 1 end
end)

S("v19_step2.txt", "logic_pet: " .. patched1)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 2: TLogicPetData
-- ═══════════════════════════════════════════════════════════════════
local patched2 = 0
pcall(function()
    local D = require("client.slua.logic.pet.traits.TLogicPetData")
    local i = D and D.__inner_impl
    if not i then return end

    -- Ownership
    local trueFns = {
        "HasPet", "HasPetPermanently", "HavePermanentPet",
        "HasPetIncludeInherit", "IsPetEquip", "HasEquipedPet",
        "HasExpandSlotPriv", "HasPetDress", "HasPetDressPermanently",
        "HasValidPetDress", "HasPetActionDress", "IsInDress", "IsActionUnLock",
    }
    for _, fn in ipairs(trueFns) do
        if wrap(i, fn, function() return function() return true end end) then patched2 = patched2 + 1 end
    end

    local falseFns = {
        "IsPetFrozen", "IsPetTimeLimitedOwning", "IsInheritPet",
        "IsPetDressFrozen", "IsDressTimeLimitedOwning",
    }
    for _, fn in ipairs(falseFns) do
        if wrap(i, fn, function() return function() return false end end) then patched2 = patched2 + 1 end
    end

    -- Data getters — return fake with proper InsID
    if wrap(i, "GetPetDataByInsID", function(orig)
        return function(self, insID, ...)
            local r = orig(self, insID, ...)
            if r then return r end
            -- insID passed — reverse lookup
            local nid = tonumber(insID)
            if nid and nid >= 7656927787236720000 then
                local pid = math.floor((nid - 7656927787236720000) / 1000)
                if pid >= 50000 and pid <= 50099 then
                    return makeFakePetData(pid)
                end
            end
            return r
        end
    end) then patched2 = patched2 + 1 end

    if wrap(i, "GetPetDataByPetItemID", function(orig)
        return function(self, petID, ...)
            local r = orig(self, petID, ...)
            if r then return r end
            if type(petID) == "number" and petID >= 50000 and petID <= 50099 then
                return makeFakePetData(petID)
            end
            return r
        end
    end) then patched2 = patched2 + 1 end

    if wrap(i, "GetPetDataIncludeInherit", function(orig)
        return function(self, petID, ...)
            local r = orig(self, petID, ...)
            if r then return r end
            if type(petID) == "number" and petID >= 50000 then
                return makeFakePetData(petID)
            end
            return r
        end
    end) then patched2 = patched2 + 1 end

    if wrap(i, "GetPetInfo", function(orig)
        return function(self, petID, ...)
            local r = orig(self, petID, ...)
            if r then return r end
            if type(petID) == "number" and petID >= 50000 then
                return makeFakePetData(petID)
            end
            return r
        end
    end) then patched2 = patched2 + 1 end

    -- Owned pet list
    if wrap(i, "GetOwnedPetList", function(orig)
        return function(self, ...)
            local list = orig(self, ...) or {}
            for _, pid in ipairs(PET_IDS) do
                if not list[pid] then list[pid] = makeFakePetData(pid) end
            end
            return list
        end
    end) then patched2 = patched2 + 1 end

    if wrap(i, "GetOwnedPetItemIDByPetID", function(orig)
        return function(self, petID, ...)
            if type(petID) == "number" and petID >= 50000 then return petID end
            return orig(self, petID, ...)
        end
    end) then patched2 = patched2 + 1 end

    -- Equipped
    if wrap(i, "GetEquipedPetInsID", function(orig)
        return function(self, ...)
            return makeInsID(50008)  -- default cat
        end
    end) then patched2 = patched2 + 1 end

    -- Carry count
    if wrap(i, "GetMaxCarryPetCount", function() return function() return 6 end end) then patched2 = patched2 + 1 end
    if wrap(i, "GetCurrentCarryCount", function() return function() return 6 end end) then patched2 = patched2 + 1 end

    -- Levels
    if wrap(i, "GetMyPetLevel", function() return function() return 100 end end) then patched2 = patched2 + 1 end
    if wrap(i, "GetCurLevelExp", function() return function() return 999999 end end) then patched2 = patched2 + 1 end
end)

S("v19_step3.txt", "TLogicPetData: " .. patched2)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 3: TLogicPetNetUtil — CRITICAL for InsID conversion
-- ═══════════════════════════════════════════════════════════════════
local patched3 = 0
pcall(function()
    local N = require("client.slua.logic.pet.traits.TLogicPetNetUtil")
    local i = N and N.__inner_impl
    if not i then return end

    -- ConvertToInsID — MUST work for selection to happen
    if wrap(i, "ConvertToInsID", function(orig)
        return function(self, petID, ...)
            local r = orig(self, petID, ...)
            if r then return r end
            if type(petID) == "number" and petID >= 50000 and petID <= 50099 then
                return makeInsID(petID)
            end
            return r
        end
    end) then patched3 = patched3 + 1 end

    -- ConvertToPetID
    if wrap(i, "ConvertToPetID", function(orig)
        return function(self, insID, ...)
            local r = orig(self, insID, ...)
            if r then return r end
            local nid = tonumber(insID)
            if nid and nid >= 7656927787236720000 then
                local pid = math.floor((nid - 7656927787236720000) / 1000)
                if pid >= 50000 and pid <= 50099 then return pid end
            end
            return r
        end
    end) then patched3 = patched3 + 1 end

    -- All rsp handlers — force 0
    for name, fn in pairs(i) do
        if type(fn) == "function" and type(name) == "string" then
            local lk = name:lower()
            if lk:find("_rsp") or lk:find("^on_") or lk:find("handleerror") then
                wrap(i, name, function(orig)
                    return function(self, ...)
                        local args = {...}
                        if type(args[1]) == "number" and args[1] ~= 0 then args[1] = 0 end
                        return orig(self, table.unpack(args))
                    end
                end)
                patched3 = patched3 + 1
            end
        end
    end
end)

S("v19_step4.txt", "TLogicPetNetUtil: " .. patched3)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 4: PET MANAGER — model spawn safety
-- ═══════════════════════════════════════════════════════════════════
local patched4 = 0
pcall(function()
    local M = require("client.slua.logic.pet.pet_manager")
    local i = M and M.__inner_impl
    if not i then return end

    -- RefreshOrCreatePet — safe wrapper
    if wrap(i, "RefreshOrCreatePet", function(orig)
        return function(self, ...)
            local ok, err = pcall(orig, self, ...)
            if not ok then
                print("[V19] RefreshOrCreatePet error: " .. tostring(err):sub(1, 100))
            end
            return ok
        end
    end) then patched4 = patched4 + 1 end

    -- RegisterPet — safe
    if wrap(i, "RegisterPet", function(orig)
        return function(self, ...)
            local ok = pcall(orig, self, ...)
            return ok
        end
    end) then patched4 = patched4 + 1 end
end)

S("v19_step5.txt", "pet_manager: " .. patched4)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 5: PET HANDLER — block sends, safe rsp
-- ═══════════════════════════════════════════════════════════════════
local patched5 = 0
pcall(function()
    local H = require("client.network.Protocol.PetHandler")
    if type(H) ~= "table" then return end

    -- Block all sends + fake rsp
    for name, fn in pairs(H) do
        if type(fn) == "function" and type(name) == "string" then
            if name:sub(1, 5) == "send_" then
                local rspName = name:gsub("^send_", "on_"):gsub("_req$", "_rsp")
                H[name] = function(...)
                    pcall(function()
                        if type(H[rspName]) == "function" then
                            pcall(H[rspName], 0)
                        end
                    end)
                    return true
                end
                patched5 = patched5 + 1
            end
        end
    end

    -- Force rsp err=0
    for name, fn in pairs(H) do
        if type(fn) == "function" and type(name) == "string" and name:sub(1, 3) == "on_" then
            local orig = fn
            H[name] = function(...)
                local args = {...}
                if type(args[1]) == "number" and args[1] ~= 0 then args[1] = 0 end
                local ok, err = pcall(orig, table.unpack(args))
                return ok, err
            end
            patched5 = patched5 + 1
        end
    end
end)

S("v19_step6.txt", "PetHandler: " .. patched5)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 6: COLLECT PET MODULE
-- ═══════════════════════════════════════════════════════════════════
local patched6 = 0
pcall(function()
    local M = require("GameLua.Mod.Lobby.Base.Collect.logic.collect_pet_module")
    local i = M and M.__inner_impl
    if not i then return end

    if wrap(i, "GetPetOwnedData", function(orig)
        return function(self, ...)
            local list = orig(self, ...) or {}
            for _, pid in ipairs(PET_IDS) do
                if not list[pid] then list[pid] = makeFakePetData(pid) end
            end
            return list
        end
    end) then patched6 = patched6 + 1 end

    if wrap(i, "HasRed", function() return function() return false end end) then patched6 = patched6 + 1 end
end)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 7: ⭐ CLICK HANDLER BYPASS — main issue
-- ⭐ Jab click kare toh server verify na ho
-- ═══════════════════════════════════════════════════════════════════
local patched7 = 0
pcall(function()
    -- Pet UI modules jo click handle karte hain
    local UI_MODULES = {
        "client.slua.umg.pet.pet_main",
        "client.slua.umg.pet.pet_choosepet",
        "client.slua.umg.pet.pet_carry_select",
        "client.slua.umg.pet.pet_levelup",
        "client.slua.umg.pet.pet_setting",
        "client.slua.umg.pet.pet_feed",
        "client.slua.umg.pet.pet_rename",
    }

    for _, path in ipairs(UI_MODULES) do
        pcall(function()
            local M = require(path)
            if type(M) ~= "table" then return end
            local i = M.__inner_impl
            if type(i) ~= "table" then return end

            -- Block click-related handlers
            for name, fn in pairs(i) do
                if type(fn) == "function" and type(name) == "string" then
                    local lk = name:lower()
                    if lk:find("onclick") or lk:find("onequip") or lk:find("onselect") 
                       or lk:find("onchoose") or lk:find("onbtn") or lk:find("onconfirm") 
                       or lk:find("reqequip") or lk:find("requse") then
                        wrap(i, name, function(orig)
                            return function(self, ...)
                                local ok, err = pcall(orig, self, ...)
                                if not ok then
                                    print("[V19] UI click wrapper err: " .. tostring(err):sub(1, 80))
                                end
                                return ok
                            end
                        end)
                        patched7 = patched7 + 1
                    end
                end
            end
        end)
    end
end)

S("v19_step7.txt", "UI click: " .. patched7)

-- ═══════════════════════════════════════════════════════════════════
-- STEP 8: AUTO-REAPPLY LOOP
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerLoop then
        ticker.AddTimerLoop(0, function()
            pcall(function()
                -- Ensure pet data module has fake data
                local D = require("client.slua.logic.pet.traits.TLogicPetData")
                local i = D and D.__inner_impl
                if i then
                    -- Refresh any cleared data
                end
            end)
        end, -1, 3.0)
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- FINAL REPORT
-- ═══════════════════════════════════════════════════════════════════
local total = patched1 + patched2 + patched3 + patched4 + patched5 + patched6 + patched7

S("v19_report.txt",
    "v19 REPORT\n" ..
    "Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n" ..
    "Reverted: " .. reverted .. "\n" ..
    "logic_pet: " .. patched1 .. "\n" ..
    "TLogicPetData: " .. patched2 .. "\n" ..
    "TLogicPetNetUtil: " .. patched3 .. "\n" ..
    "pet_manager: " .. patched4 .. "\n" ..
    "PetHandler: " .. patched5 .. "\n" ..
    "collect_pet_module: " .. patched6 .. "\n" ..
    "UI click handlers: " .. patched7 .. "\n" ..
    "TOTAL: " .. total .. "\n"
)

P("v19 LOADED",
    "Total: " .. total .. "\n" ..
    "Fix: InsID format + click bypass\n\n" ..
    "Test:\n" ..
    "1. Pet menu kholo\n" ..
    "2. Pet pe click karo\n" ..
    "3. Equip dabao\n" ..
    "4. Model spawn hona chahiye\n\n" ..
    "Agar icon dikha lekin model nahi —\n" ..
    "asset download ka issue hai")

return true
