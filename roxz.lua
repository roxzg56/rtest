-- ═══════════════════════════════════════════════════════════════════
-- PSLOT DIAGNOSTIC v1
-- Ye 2 functions run karo aur output copy-paste karo
-- ═══════════════════════════════════════════════════════════════════

-- ═══ DIAG 1: Slot system — actual data structure dekho ═══
_G.PSlotDebug = function()
    local out = {}
    local function w(s) out[#out+1] = tostring(s) end
    w("═══ PROFILE SLOT DEBUG ═══")

    pcall(function()
        local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
        if type(M) ~= "table" then w("M: NOT LOADED") return end
        local i = M.__inner_impl
        if type(i) ~= "table" then w("i: NOT LOADED") return end

        -- 1) Table fields dhoondo jo slot data rakhti hain
        w("")
        w("─── MODULE FIELDS (data-looking) ───")
        local mt = getmetatable(M)
        for k, v in pairs(i) do
            if type(v) == "table" then
                local n = 0; for _ in pairs(v) do n = n + 1 end
                if n > 0 and n < 500 then
                    w("  __inner_impl." .. tostring(k) .. " = tbl(" .. n .. ")")
                    -- First few entries dikha
                    local shown = 0
                    for k2, v2 in pairs(v) do
                        if shown >= 3 then break end
                        shown = shown + 1
                        w("      [" .. tostring(k2) .. "] = " .. 
                          (type(v2) == "table" and "tbl{" .. tostring(next(v2)) .. ",...}" or tostring(v2)))
                    end
                end
            end
        end

        -- 2) GetSlotDataBySlotTypeAndIndex ko call karke dekho kya return karta hai
        w("")
        w("─── CALL TEST ───")
        if type(i.GetSlotDataBySlotTypeAndIndex) == "function" then
            for _, st in ipairs({ "Weapon", "Vehicle", "Pet", "AvatarShow", "BGWall", "Achievement",
                                 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }) do
                local ok, r = pcall(i.GetSlotDataBySlotTypeAndIndex, i, st, 1)
                if ok then
                    w("  GetSlotDataBySlotTypeAndIndex(" .. tostring(st) .. ", 1) = " .. 
                      (type(r) == "table" and ("tbl:" .. (next(r) and tostring(next(r)) or "empty")) or tostring(r)))
                else
                    w("  GetSlotDataBySlotTypeAndIndex(" .. tostring(st) .. ", 1) ERROR: " .. tostring(r))
                end
            end
        else
            w("  GetSlotDataBySlotTypeAndIndex: NIL")
        end

        -- 3) CurrentUId check — player khud ka data dekh raha hai ya doosre ka?
        w("")
        w("─── PLAYER CONTEXT ───")
        if type(i.GetCurUId) == "function" then
            local ok, uid = pcall(i.GetCurUId, i)
            w("  GetCurUId = " .. tostring(uid))
        end
        if _G.DataMgr and _G.DataMgr.roleData then
            w("  MyUID = " .. tostring(_G.DataMgr.roleData.uid))
        end
    end)

    -- print to console + write file
    local txt = table.concat(out, "\n")
    print(txt)
    pcall(function()
        local f = io.open("/storage/emulated/0/Android/data/com.pubg.imobile/files/pslot_debug.txt", "w")
        if f then f:write(txt); f:close() end
    end)
    return txt
end

-- ═══ DIAG 2: Vehicle system — kya dikh raha hai, kya callable hai ═══
_G.CarDebug = function()
    local out = {}
    local function w(s) out[#out+1] = tostring(s) end
    w("═══ VEHICLE DEBUG ═══")

    -- DataMgr se current vehicle slots
    pcall(function()
        local DM = _G.DataMgr
        if DM then
            w("─── DataMgr.roleData.vst_skin ───")
            w("  vst_skin = " .. tostring(DM.roleData and DM.roleData.vst_skin))
            w("─── DataMgr.VehicleSlotList ───")
            if DM.VehicleSlotList then
                for k, v in pairs(DM.VehicleSlotList) do
                    w("  [" .. tostring(k) .. "] = " .. tostring(v))
                end
            else
                w("  NOT FOUND")
            end
            w("─── DataMgr.vehicleSkinInsIDTable (count) ───")
            if DM.vehicleSkinInsIDTable then
                local n = 0; for _ in pairs(DM.vehicleSkinInsIDTable) do n = n + 1 end
                w("  count = " .. n)
            else
                w("  NOT FOUND")
            end
            w("─── DataMgr.defaultVehicleSkinResIDTable (count) ───")
            if DM.defaultVehicleSkinResIDTable then
                local n = 0; for _ in pairs(DM.defaultVehicleSkinResIDTable) do n = n + 1 end
                w("  count = " .. n)
            end
        end
    end)

    -- CDataTable tables
    pcall(function()
        w("")
        w("─── CDataTable tables ───")
        for _, tn in ipairs({ "Vehicle", "VehicleSkin", "VehicleSkinResID",
                              "Item", "VehicleUpgrade", "VehicleAccessory" }) do
            local t = CDataTable.GetTable(tn)
            if t then
                local n = 0; for _ in pairs(t) do n = n + 1 end
                w("  " .. tn .. " = " .. n .. " entries")
                -- Show 5 sample IDs
                local shown = 0
                for id, row in pairs(t) do
                    if shown >= 5 then break end
                    shown = shown + 1
                    w("      [" .. tostring(id) .. "] = " .. 
                      (type(row) == "table" and "tbl" or tostring(row)))
                end
            else
                w("  " .. tn .. " = NOT FOUND")
            end
        end
    end)

    -- ThemeVehicleManager
    pcall(function()
        w("")
        w("─── ThemeVehicleManager ───")
        local M = require("client.logic.lobby.ThemeVehicleManager")
        if type(M) == "table" then
            local i = M.__inner_impl
            if type(i) == "table" then
                w("  Has GetSelfVehicleIDs: " .. tostring(type(i.GetSelfVehicleIDs)))
                w("  Has _ShowSelfVehicle: " .. tostring(type(i._ShowSelfVehicle)))
                w("  Has ShowThemeVehicle: " .. tostring(type(i.ShowThemeVehicle)))
                w("  Has _CreateVehicleModel: " .. tostring(type(i._CreateVehicleModel)))
                w("  Has OnVehicleChange: " .. tostring(type(i.OnVehicleChange)))
                w("  Has PreviewGarageVehicle: " .. tostring(type(i.PreviewGarageVehicle)))
                -- Vehicles table
                if type(i.Vehicles) == "table" then
                    local n = 0; for _ in pairs(i.Vehicles) do n = n + 1 end
                    w("  Vehicles tbl count = " .. n)
                    for k, v in pairs(i.Vehicles) do
                        w("      Vehicles[" .. tostring(k) .. "] = " .. tostring(v))
                    end
                end
            else
                w("  __inner_impl NOT LOADED")
            end
        else
            w("  ThemeVehicleManager NOT LOADED")
        end
    end)

    -- VehicleCollectSystem — GetDefaultShowVehicle
    pcall(function()
        w("")
        w("─── VehicleCollectSystem ───")
        local M = require("client.logic.vehicle.VehicleCollectSystem")
        if type(M) == "table" then
            local i = M.__inner_impl
            if type(i) == "table" then
                if type(i.GetDefaultShowVehicle) == "function" then
                    local ok, r = pcall(i.GetDefaultShowVehicle, i)
                    w("  GetDefaultShowVehicle() = " .. tostring(r))
                end
                if type(i.GetVehicleListBySort) == "function" then
                    local ok, r = pcall(i.GetVehicleListBySort, i)
                    if ok and type(r) == "table" then
                        local n = 0; for _ in pairs(r) do n = n + 1 end
                        w("  GetVehicleListBySort: " .. n .. " items")
                        local shown = 0
                        for k, v in pairs(r) do
                            if shown >= 10 then break end
                            shown = shown + 1
                            w("      [" .. tostring(k) .. "] = " .. tostring(v))
                        end
                    end
                end
            end
        end
    end)

    local txt = table.concat(out, "\n")
    print(txt)
    pcall(function()
        local f = io.open("//storage/emulated/0/Android/data/com.pubg.imobile/files/car_debug.txt", "w")
        if f then f:write(txt); f:close() end
    end)
    return txt
end

-- Auto-run dono on next lobby
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(8.0, function()
            pcall(_G.PSlotDebug)
            pcall(_G.CarDebug)
        end)
    end
end)

return true
