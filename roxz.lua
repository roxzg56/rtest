-- ===============================================================
-- roxs_v3_min.lua — MINIMAL DIAGNOSTIC
-- Yeh file: sirf batayegi ki load hui ya nahi
-- Log: /sdcard/roxs_v3.log
-- Pehle purani files hata de: roxs.lua, gdump_live.lua, uc_bypass.lua
-- Sirf YEH file mods/ mein rakho
-- ===============================================================

local VERSION = "ROXS_V3_MIN"

-- io test — kaunsa path write hota hai
local LOG_PATH = nil
for _, p in ipairs({
    "/storage/emulated/0/Android/data/com.pubg.imobile/files/roxs_v3.log",
    "/sdcard/roxs_v3.log",
}) do
    local ok = pcall(function()
        local f = io.open(p, "a")
        if f then f:close() end
    end)
    if ok then LOG_PATH = p; break end
end

if not LOG_PATH then return end

local function W(msg)
    pcall(function()
        local f = io.open(LOG_PATH, "a")
        if f then
            f:write(os.date("%H:%M:%S") .. " [" .. VERSION .. "] " .. tostring(msg) .. "\n")
            f:close()
        end
    end)
end

W("=== BOOT " .. os.date() .. " ===")
print("[" .. VERSION .. "] BOOT")

-- Har version ka marker — agar tu v3 dekh raha hai toh file load hui
-- Agar v1 ya v2 dekh raha hai toh purani file abhi bhi chal rahi hai
W("VERSION_MARKER_12345_UNIQUE")

-- StoreHandler load test
local okSH, SH = pcall(require, "client.network.Protocol.StoreHandler")
W("SH require ok=" .. tostring(okSH))
W("SH type=" .. type(SH))

if okSH and SH and type(SH) == "table" then
    -- list all send_ methods
    local sends = {}
    for k, v in pairs(SH) do
        if type(k) == "string" and k:find("^send_") and type(v) == "function" then
            sends[#sends+1] = k
        end
    end
    table.sort(sends)
    W("SH sends count=" .. #sends)
    for _, s in ipairs(sends) do
        W("  " .. s)
    end

    -- hook draw methods
    local DRAW_METHODS = {
        "send_do_one_draw_by_activity_req",
        "send_do_draw_discount_by_activity_req",
        "send_do_biochemical_activity_one_draw_req",
        "send_buy_shop_by_id_req",
        "send_buy_market_by_id_req",
        "send_get_lucky_draw_unback_activity_req",
        "send_limited_discount_buy",
    }
    for _, m in ipairs(DRAW_METHODS) do
        if type(SH[m]) == "function" then
            local orig = SH[m]
            SH[m] = function(...)
                local n = select("#", ...)
                local parts = {}
                for i = 1, n do parts[i] = tostring(select(i, ...)) end
                W(">>> CALL " .. m .. " (" .. n .. "): " .. table.concat(parts, " | "))
                local rok, r1, r2, r3 = pcall(orig, ...)
                W("<<< RET " .. m .. " ok=" .. tostring(rok) .. " r1=" .. tostring(r1))
                if rok then return r1, r2, r3 end
                return r1
            end
            W("hooked " .. m)
        else
            W("NOT FOUND " .. m)
        end
    end

    -- hook rsp methods
    local RSP_METHODS = {
        "on_do_one_draw_by_activity_rsp",
        "on_get_lucky_draw_unback_activity_rsp",
        "on_buy_shop_by_id_rsp",
    }
    for _, m in ipairs(RSP_METHODS) do
        if type(SH[m]) == "function" then
            local orig = SH[m]
            SH[m] = function(...)
                local n = select("#", ...)
                local parts = {}
                for i = 1, n do parts[i] = tostring(select(i, ...)) end
                W(">>> RSP " .. m .. " (" .. n .. "): " .. table.concat(parts, " | "))
                return orig(...)
            end
            W("hooked rsp " .. m)
        end
    end
end

-- UC bypass — tight pcalls
local FAKE = 999999999
local dMgr = _G.DataMgr
W("dMgr=" .. tostring(dMgr))
if dMgr then
    pcall(function() dMgr.uc = FAKE end)
    pcall(function() dMgr.UC = FAKE end)
    pcall(function() dMgr.ticket = FAKE end)
    pcall(function() dMgr.GetUC = function() return FAKE end end)
    pcall(function() dMgr.CheckUC = function() return true end end)
    pcall(function() dMgr.CheckIsEnough = function() return true end end)
    W("UC patched dMgr.uc=" .. tostring(dMgr.uc))
else
    W("dMgr NOT FOUND")
end

-- Luckyback module price getters -> 0
local lb_ok, lb = pcall(require, "client.slua.logic.lobby_activity.logic_luckyback_activity")
W("luckyback ok=" .. tostring(lb_ok))
if lb_ok and lb then
    pcall(function() lb.GetOneDrawDiscountPrice = function() return 0 end end)
    pcall(function() if lb.GetTenDrawDiscountPrice then lb.GetTenDrawDiscountPrice = function() return 0 end end end)
    pcall(function() if lb.HasEnoughUC then lb.HasEnoughUC = function() return true end end end)
    W("luckyback patched")
end

-- Heartbeat
local t_ok, ticker = pcall(require, "common.time_ticker")
W("ticker ok=" .. tostring(t_ok))
if t_ok and ticker and ticker.AddTimerLoop then
    local tick = 0
    ticker.AddTimerLoop(0, function()
        pcall(function()
            tick = tick + 1
            if tick % 10 == 0 then
                W("ALIVE tick=" .. tick .. " dMgr.uc=" .. tostring(dMgr and dMgr.uc))
            end
        end)
    end, -1, 0.5)
    W("timer loop started")
else
    W("NO TICKER")
end

W("=== READY ===")
print("[" .. VERSION .. "] READY")
