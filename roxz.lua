-- ===============================================================
-- roxs_v4.lua — hooks EVERY protocol handler, no exceptions
-- Log: /sdcard/roxs_v4.log
-- ===============================================================

local VERSION = "ROXS_V4"
local LOG_PATH = nil
for _, p in ipairs({
    "/storage/emulated/0/Android/data/com.pubg.imobile/files/roxs_v4.log",
    "/sdcard/roxs_v4.log",
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

-- Hook EVERY protocol handler's send_* and on_*_rsp
local hookedSend, hookedRsp = 0, 0
local handlerCount = 0

for path, mod in pairs(package.loaded) do
    if type(path) == "string" and path:find("client.network.Protocol.", 1, true) and type(mod) == "table" then
        handlerCount = handlerCount + 1
        for name, fn in pairs(mod) do
            if type(name) == "string" and type(fn) == "function" then
                if name:find("^send_") then
                    local orig = fn
                    mod[name] = function(...)
                        local n = select("#", ...)
                        local parts = {}
                        for i = 1, n do
                            local v = select(i, ...)
                            if type(v) == "table" then
                                local c = 0
                                for _ in pairs(v) do c = c + 1 end
                                parts[i] = "<table:" .. c .. ">"
                            else
                                parts[i] = tostring(v)
                            end
                        end
                        W(">>> CALL " .. path .. " :: " .. name .. " (" .. n .. "): " .. table.concat(parts, " | "))
                        local ok, r1, r2, r3 = pcall(orig, ...)
                        W("<<< RET " .. name .. " ok=" .. tostring(ok) .. " r=" .. tostring(r1))
                        if ok then return r1, r2, r3 end
                        return r1
                    end
                    hookedSend = hookedSend + 1
                elseif name:find("^on_") and name:find("_rsp") then
                    local orig = fn
                    mod[name] = function(...)
                        local n = select("#", ...)
                        local parts = {}
                        for i = 1, n do
                            local v = select(i, ...)
                            if type(v) == "table" then
                                local c = 0
                                for _ in pairs(v) do c = c + 1 end
                                parts[i] = "<table:" .. c .. ">"
                            else
                                parts[i] = tostring(v)
                            end
                        end
                        W(">>> RSP " .. path .. " :: " .. name .. " (" .. n .. "): " .. table.concat(parts, " | "))
                        return orig(...)
                    end
                    hookedRsp = hookedRsp + 1
                end
            end
        end
    end
end

W("handlers=" .. handlerCount .. " sends_hooked=" .. hookedSend .. " rsps_hooked=" .. hookedRsp)

-- UC bypass
local FAKE = 999999999
local dMgr = _G.DataMgr
if dMgr then
    pcall(function() dMgr.uc = FAKE; dMgr.UC = FAKE; dMgr.ticket = FAKE end)
    pcall(function() dMgr.GetUC = function() return FAKE end end)
    pcall(function() dMgr.CheckUC = function() return true end end)
    pcall(function() dMgr.CheckIsEnough = function() return true end end)
    W("UC patched")
end

-- Luckyback + unback price = 0
for _, p in ipairs({
    "client.slua.logic.lobby_activity.logic_luckyback_activity",
    "client.slua.logic.lobby_activity.logic_luckyunback_activity",
}) do
    local ok, m = pcall(require, p)
    if ok and m then
        pcall(function() m.GetOneDrawDiscountPrice = function() return 0 end end)
        pcall(function() m.GetTenDrawDiscountPrice = function() return 0 end end)
        pcall(function() m.HasEnoughUC = function() return true end end)
        pcall(function() m.GetNextDrawCost = function() return 0 end end)
    end
end
W("activity prices patched")

-- Heartbeat
local t_ok, ticker = pcall(require, "common.time_ticker")
if t_ok and ticker and ticker.AddTimerLoop then
    local tick = 0
    ticker.AddTimerLoop(0, function()
        pcall(function()
            tick = tick + 1
            if tick % 20 == 0 then
                if dMgr then pcall(function() dMgr.uc = FAKE end) end
                W("alive tick=" .. tick)
            end
        end)
    end, -1, 0.5)
    W("ticker started")
else
    W("NO TICKER")
end

W("=== READY ===")
