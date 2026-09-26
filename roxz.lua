-- ═══════════════════════════════════════════════════════════════════
-- SLOT OBSERVER v5.1 — PATH LOCKED
-- ONLY WRITES TO: /storage/emulated/0/Android/data/com.pubg.imobile/files/
-- No /sdcard fallback. No alternative paths. Only this one.
-- ═══════════════════════════════════════════════════════════════════

local DIR = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"

-- ─── POPUP ────────────────────────────────────────────────────────
local function POPUP(title, msg)
    pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
            or (pcall(require, "client.slua.logic.common.logic_common_msg_box")
                and require("client.slua.logic.common.logic_common_msg_box"))
        if Msg and Msg.Show then
            Msg.Show(1, tostring(title), tostring(msg), function() end, function() end, "OK", "CLOSE")
        end
    end)
end

-- ─── WRITE — ONLY TO DIR, NO FALLBACK ─────────────────────────────
local function W(name, content)
    local fullPath = DIR .. name
    local f, err = io.open(fullPath, "w")
    if not f then
        return false, fullPath, tostring(err or "open failed")
    end
    f:write(content or "")
    f:close()
    return true, fullPath, nil
end

-- ─── VALUE FORMATTER ──────────────────────────────────────────────
local function V(v, d, m)
    d, m = d or 0, m or 3
    if d > m then return "..." end
    local t = type(v)
    if t == "nil" then return "nil" end
    if t == "boolean" or t == "number" then return tostring(v) end
    if t == "string" then
        if #v > 80 then return '"' .. v:sub(1,77) .. '..."' end
        return '"' .. v .. '"'
    end
    if t == "function" then return "<fn>" end
    if t == "userdata" then return "<ud>" end
    if t == "table" then
        local p, i, n = {}, 0, 0
        for _ in pairs(v) do n = n + 1 end
        for k, val in pairs(v) do
            i = i + 1
            if i > 25 then p[#p+1] = "...(+" .. (n-25) .. ")"; break end
            p[#p+1] = tostring(k) .. "=" .. V(val, d+1, m)
        end
        return "{" .. table.concat(p, ",") .. "}"
    end
    return "<" .. t .. ">"
end

-- ═══════════════════════════════════════════════════════════════════
-- SNAPSHOT — deep dump of module
-- ═══════════════════════════════════════════════════════════════════
_G.SlotSnapshot = function(showPopup)
    local out = {}
    local function w(s) out[#out+1] = tostring(s) end
    w("═══ SLOT SNAPSHOT ═══")
    w("Time: " .. os.date("%Y-%m-%d %H:%M:%S"))
    w("Path: " .. DIR)
    w("")

    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    if type(M) ~= "table" then
        w("MODULE NOT LOADED")
        local txt = table.concat(out, "\n")
        local ok, path, err = W("slot_snapshot.txt", txt)
        if showPopup then POPUP(ok and "SNAPSHOT SAVED" or "SNAPSHOT FAIL", 
            ok and path or ("ERR: " .. tostring(err))) end
        return txt
    end
    w("MODULE LOADED: YES")

    local i = M.__inner_impl
    if type(i) ~= "table" then
        w("INNER NOT LOADED")
        local txt = table.concat(out, "\n")
        W("slot_snapshot.txt", txt)
        if showPopup then POPUP("SNAPSHOT", "Inner not loaded") end
        return txt
    end
    w("__inner_impl LOADED: YES")
    w("")

    w("═══ ALL FIELDS (deep) ═══")
    local keys = {}
    for k in pairs(i) do keys[#keys+1] = k end
    table.sort(keys, function(a,b) return tostring(a) < tostring(b) end)
    for _, k in ipairs(keys) do
        local v = i[k]
        w("")
        w("── " .. tostring(k) .. " (" .. type(v) .. ") ──")
        w("  " .. V(v, 0, 4))
    end

    w("")
    w("═══ __super_impl ═══")
    if type(i.__super_impl) == "table" then w("  " .. V(i.__super_impl, 0, 2)) end
    w("")
    w("═══ __super ═══")
    if type(i.__super) == "table" then w("  " .. V(i.__super, 0, 2)) end

    -- DataMgr snapshot (relevant fields)
    w("")
    w("═══ DataMgr.roleData (relevant) ═══")
    pcall(function()
        local DM = _G.DataMgr
        if DM and DM.roleData then
            for _, field in ipairs({ "uid", "cur_avatar_box_id", "headIconUrl",
                                     "friend_nickname_skin", "chat_bubble",
                                     "cur_team_notify_skin_id", "vst_skin",
                                     "nameFrameData", "social_card", "alias" }) do
                if DM.roleData[field] ~= nil then
                    w("  roleData." .. field .. " = " .. V(DM.roleData[field], 0, 3))
                end
            end
        end
    end)

    local txt = table.concat(out, "\n")
    local ok, path, err = W("slot_snapshot.txt", txt)
    if showPopup then
        if ok then POPUP("SNAPSHOT SAVED", "slot_snapshot.txt\n" .. #txt .. " bytes\n" .. path)
        else POPUP("SNAPSHOT FAIL", "ERR: " .. tostring(err)) end
    end
    return txt
end

-- ═══════════════════════════════════════════════════════════════════
-- TRACER — hook everything
-- ═══════════════════════════════════════════════════════════════════
_G.SlotTrace = function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    if type(M) ~= "table" then print("[T] not loaded") return end
    local i = M.__inner_impl
    if type(i) ~= "table" then print("[T] inner not loaded") return end

    if _G._SlotTrace then print("[T] already active") return end
    _G._SlotTrace = { log = {}, count = 0, start = os.time() }

    local function log(s)
        _G._SlotTrace.count = _G._SlotTrace.count + 1
        local e = string.format("[%s][%04d] %s", os.date("%H:%M:%S"), _G._SlotTrace.count, s)
        _G._SlotTrace.log[#_G._SlotTrace.log+1] = e
        if #_G._SlotTrace.log > 5000 then
            for _ = 1, 1000 do table.remove(_G._SlotTrace.log, 1) end
        end
    end

    log("TRACE STARTED — " .. tostring(os.date()))

    for name, fn in pairs(i) do
        if type(fn) == "function" and type(name) == "string" then
            local orig = fn
            local fnName = tostring(name)
            i[name] = function(self, ...)
                local argc = select("#", ...)
                local argStr = ""
                for n = 1, math.min(argc, 5) do
                    argStr = argStr .. V(select(n, ...), 0, 1) .. " "
                end
                log("→ " .. fnName .. "(" .. argStr .. ")")
                local ok, r = pcall(orig, self, ...)
                if not ok then
                    log("  ✗ ERR: " .. tostring(r):sub(1, 200))
                    return nil
                end
                log("  ↳ " .. fnName .. " = " .. V(r, 0, 2))
                return r
            end
        end
    end

    log("READY — open profile now")

    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerLoop then
            ticker.AddTimerLoop(0, function()
                if _G._SlotTrace then
                    W("slot_trace.txt", table.concat(_G._SlotTrace.log, "\n"))
                end
            end, -1, 20.0)
        end
    end)

    print("[T] Started. Open profile. Auto-save every 20s → " .. DIR .. "slot_trace.txt")
end

_G.SlotTraceDump = function(showPopup)
    if not _G._SlotTrace then
        if showPopup then POPUP("TRACE", "Not started") end
        return
    end
    local txt = table.concat(_G._SlotTrace.log, "\n")
    local ok, path, err = W("slot_trace.txt", txt)
    if showPopup then
        POPUP(ok and "TRACE SAVED" or "TRACE FAIL",
              ok and ("Lines: " .. #_G._SlotTrace.log .. "\n" .. path) or ("ERR: " .. tostring(err)))
    end
    return txt
end

-- ═══════════════════════════════════════════════════════════════════
-- CAR SPAWN TEST — separate trace for car
-- ═══════════════════════════════════════════════════════════════════
_G.CarSnapshot = function(showPopup)
    local out = {}
    local function w(s) out[#out+1] = tostring(s) end
    w("═══ CAR SNAPSHOT ═══")
    w("Time: " .. os.date("%Y-%m-%d %H:%M:%S"))
    w("")

    pcall(function()
        local DM = _G.DataMgr
        if DM then
            w("DataMgr.roleData.vst_skin = " .. tostring(DM.roleData and DM.roleData.vst_skin))
            w("")
            w("── VehicleSlotList ──")
            if DM.VehicleSlotList then
                for k, v in pairs(DM.VehicleSlotList) do
                    w("  [" .. tostring(k) .. "] = " .. V(v, 0, 3))
                end
            end
            w("")
            w("── vehicleSkinInsIDTable ──")
            if DM.vehicleSkinInsIDTable then
                for k, v in pairs(DM.vehicleSkinInsIDTable) do
                    w("  [" .. tostring(k) .. "] = " .. tostring(v))
                end
            end
            w("")
            w("── defaultVehicleSkinResIDTable ──")
            if DM.defaultVehicleSkinResIDTable then
                for k, v in pairs(DM.defaultVehicleSkinResIDTable) do
                    w("  [" .. tostring(k) .. "] = " .. tostring(v))
                end
            end
        end
    end)

    pcall(function()
        w("")
        w("── ThemeVehicleManager fields ──")
        local M = require("client.logic.lobby.ThemeVehicleManager")
        if type(M) == "table" and type(M.__inner_impl) == "table" then
            local i = M.__inner_impl
            for k, v in pairs(i) do
                if type(v) == "table" then
                    local n = 0; for _ in pairs(v) do n = n + 1 end
                    if n > 0 and n < 200 then
                        w("  " .. tostring(k) .. " = tbl(" .. n .. ") " .. V(v, 0, 3))
                    end
                end
            end
        end
    end)

    local txt = table.concat(out, "\n")
    local ok, path, err = W("car_snapshot.txt", txt)
    if showPopup then
        POPUP(ok and "CAR SNAPSHOT SAVED" or "CAR FAIL",
              ok and path or ("ERR: " .. tostring(err)))
    end
    return txt
end

-- ═══════════════════════════════════════════════════════════════════
-- PATH TEST — verify write works before anything else
-- ═══════════════════════════════════════════════════════════════════
_G.PathTest = function()
    local ok, path, err = W("_pathtest.txt", 
        "Written at " .. os.date("%Y-%m-%d %H:%M:%S") .. "\nPath: " .. DIR)
    if ok then
        POPUP("PATH OK", "Write successful:\n" .. path)
        print("[PATH] OK: " .. path)
    else
        POPUP("PATH FAIL", "Cannot write:\n" .. tostring(path) .. "\nERR: " .. tostring(err))
        print("[PATH] FAIL: " .. tostring(err))
    end
    return ok
end

-- ═══════════════════════════════════════════════════════════════════
-- AUTO-BOOT
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        -- 3 sec: path test
        ticker.AddTimerOnce(3.0, function()
            pcall(_G.PathTest)
        end)
        -- 6 sec: snapshot + trace
        ticker.AddTimerOnce(6.0, function()
            pcall(_G.SlotSnapshot, false)  -- silent
            pcall(_G.CarSnapshot, false)
            pcall(_G.SlotTrace)
            -- Popup summary
            pcall(function()
                local t = require("common.time_ticker")
                if t and t.AddTimerOnce then
                    t.AddTimerOnce(1.0, function()
                        POPUP("OBSERVER READY",
                            "Files written to:\n" .. DIR .. "\n\n" ..
                            "1. _pathtest.txt\n" ..
                            "2. slot_snapshot.txt\n" ..
                            "3. car_snapshot.txt\n" ..
                            "4. slot_trace.txt (live)\n\n" ..
                            "Open Profile + Social Lobby now.\n" ..
                            "Wait 15 sec, then check files.")
                    end)
                end
            end)
        end)
    end
end)

print("[v5.1] Loaded. Path: " .. DIR)

return true
