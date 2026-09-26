-- ═══════════════════════════════════════════════════════════════════
-- REAL FIX v4 — Bytecode Dump + Popup + Auto-Run
-- Reason: Source .lua is inside .pak, NOT on disk. Use debug.getinfo
--         + string.dump to extract bytecode instead.
-- All output: /storage/emulated/0/Android/data/com.pubg.imobile/files/
-- ═══════════════════════════════════════════════════════════════════

local DUMP_DIR = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"

-- ─── POPUP HELPER ──────────────────────────────────────────────────
local function POPUP(title, msg)
    pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
            or (pcall(require, "client.slua.logic.common.logic_common_msg_box")
                and require("client.slua.logic.common.logic_common_msg_box"))
        if Msg and Msg.Show then
            Msg.Show(1, tostring(title), tostring(msg), 
                function() end, function() end, "OK", "CLOSE")
        end
    end)
    print("[POPUP] " .. tostring(title) .. " | " .. tostring(msg))
end

-- ─── WRITE FILE (guaranteed) ───────────────────────────────────────
local function WRITE(name, content)
    local fullPath = DUMP_DIR .. name
    local wrote = false
    local errMsg = ""
    pcall(function()
        local f, err = io.open(fullPath, "w")
        if f then
            f:write(content or "")
            f:close()
            wrote = true
        else
            errMsg = tostring(err or "unknown")
        end
    end)
    if not wrote then
        -- Fallback to /sdcard/
        pcall(function()
            local altPath = "/sdcard/" .. name
            local f = io.open(altPath, "w")
            if f then
                f:write(content or "")
                f:close()
                wrote = true
                fullPath = altPath
            end
        end)
    end
    return wrote, fullPath, errMsg
end

-- ─── BYTECODE DUMPER ───────────────────────────────────────────────
-- Extract function bytecode via string.dump, save as .luac for decompiling
local function dumpFunctionBytecode(fnName, fn, outBuf)
    if type(fn) ~= "function" then return end
    local info = debug.getinfo(fn, "S")
    if not info then return end

    local header = string.format(
        "── FUNCTION: %s ──\n  source=%s\n  short_src=%s\n  line=%s..%s\n  what=%s\n  nups=%s\n",
        fnName, tostring(info.source), tostring(info.short_src),
        tostring(info.linedefined), tostring(info.lastlinedefined),
        tostring(info.what), tostring(info.nups or 0)
    )
    outBuf[#outBuf+1] = header

    -- Dump bytecode
    local ok, bc = pcall(string.dump, fn)
    if ok and bc then
        outBuf[#outBuf+1] = string.format("  BYTECODE SIZE: %d bytes\n", #bc)
        -- Hex dump first 256 bytes
        local hex = {}
        for i = 1, math.min(256, #bc) do
            hex[#hex+1] = string.format("%02X", bc:byte(i))
        end
        outBuf[#outBuf+1] = "  BYTECODE HEX (first 256):\n  " .. table.concat(hex, " ") .. "\n"
    else
        outBuf[#outBuf+1] = "  BYTECODE DUMP FAILED (C function)\n"
    end

    -- Dump constants if LUA 5.1 (getconstants via debug)
    pcall(function()
        local consts = {}
        local i = 1
        while true do
            local name, val = debug.getupvalue(fn, i)
            if not name then break end
            consts[#consts+1] = "  UP" .. i .. " " .. tostring(name) .. " = " .. 
                (type(val) == "table" and ("tbl:" .. (next(val) and tostring(next(val)) or "empty")) or tostring(val))
            i = i + 1
        end
        if #consts > 0 then
            outBuf[#outBuf+1] = "  UPVALUES:\n" .. table.concat(consts, "\n") .. "\n"
        end
    end)

    outBuf[#outBuf+1] = "\n"
end

-- ═══════════════════════════════════════════════════════════════════
-- MAIN: DUMP SLOT MODULE STRUCTURE
-- ═══════════════════════════════════════════════════════════════════
_G.PSlotDumpAll = function(showPopup)
    local out = {}
    local function w(s) out[#out+1] = tostring(s) end

    w("╔═══════════════════════════════════════════════════════════╗")
    w("║  PSLOT DUMP v4 — " .. os.date("%Y-%m-%d %H:%M:%S"))
    w("║  Path: " .. DUMP_DIR)
    w("╚═══════════════════════════════════════════════════════════╝")
    w("")

    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    if type(M) ~= "table" then
        w("MODULE NOT LOADED")
        local txt = table.concat(out, "\n")
        WRITE("pslot_dump.txt", txt)
        if showPopup then POPUP("PSLOT DUMP", "Module NOT loaded!") end
        return txt
    end
    local i = M.__inner_impl
    if type(i) ~= "table" then
        w("INNER NOT LOADED")
        local txt = table.concat(out, "\n")
        WRITE("pslot_dump.txt", txt)
        if showPopup then POPUP("PSLOT DUMP", "Inner NOT loaded!") end
        return txt
    end

    w("═══ MODULE FIELD INVENTORY ═══")
    w("")
    local fnCount, tblCount, scalarCount = 0, 0, 0
    local funcs = {}
    for k, v in pairs(i) do
        local vt = type(v)
        if vt == "table" then
            tblCount = tblCount + 1
            local n = 0; for _ in pairs(v) do n = n + 1 end
            w(string.format("[tbl:%3d] %s", n, tostring(k)))
        elseif vt == "function" then
            fnCount = fnCount + 1
            funcs[#funcs+1] = k
            local info = debug.getinfo(v, "S")
            w(string.format("[fn]  %s  (line %s of %s)", 
                tostring(k), 
                tostring(info and info.linedefined or "?"), 
                tostring(info and info.short_src or "?")
            ))
        else
            scalarCount = scalarCount + 1
            w(string.format("[%-5s] %s = %s", vt, tostring(k), tostring(v)))
        end
    end
    w("")
    w(string.format("SUMMARY: %d functions, %d tables, %d scalars", fnCount, tblCount, scalarCount))
    w("")

    -- Sort functions alphabetically
    table.sort(funcs)

    -- Dump each function's metadata + bytecode
    w(string.rep("═", 68))
    w("FUNCTION BYTECODE DUMP (" .. #funcs .. " functions)")
    w(string.rep("═", 68))
    w("")

    for _, fnName in ipairs(funcs) do
        pcall(dumpFunctionBytecode, fnName, i[fnName], out)
    end

    -- Also dump the top-level module
    w(string.rep("═", 68))
    w("TOP-LEVEL MODULE FUNCTIONS")
    w(string.rep("═", 68))
    w("")
    for k, v in pairs(M) do
        if type(v) == "function" and type(k) == "string" and not k:match("^__") then
            pcall(dumpFunctionBytecode, "M." .. tostring(k), v, out)
        end
    end

    local txt = table.concat(out, "\n")
    local ok, path, err = WRITE("pslot_dump.txt", txt)

    if showPopup then
        if ok then
            POPUP("✓ PSLOT DUMP SAVED", 
                "File: pslot_dump.txt\n" ..
                "Size: " .. #txt .. " bytes\n" ..
                "Path: com.pubg.imobile/files/\n\n" ..
                "Functions: " .. fnCount .. "\n" ..
                "Tables: " .. tblCount
            )
        else
            POPUP("✗ DUMP FAILED", "Error: " .. tostring(err))
        end
    end

    print("[PSLOT v4] Dump saved to: " .. tostring(path))
    return txt
end

-- ═══════════════════════════════════════════════════════════════════
-- RUNTIME TRACER (auto-saves every 30 sec)
-- ═══════════════════════════════════════════════════════════════════
_G.TraceSlots = function()
    local M = require("client.slua.logic.lobby.Left.Logic_SocialLobbyModule")
    if type(M) ~= "table" then return end
    local i = M.__inner_impl
    if type(i) ~= "table" then return end

    if _G._STrace then
        print("[TRACE] Already active")
        return
    end
    _G._STrace = { log = {}, start = os.time(), count = 0 }

    local function log(s)
        _G._STrace.count = _G._STrace.count + 1
        local entry = string.format("[%s][%04d] %s", os.date("%H:%M:%S"), _G._STrace.count, s)
        _G._STrace.log[#_G._STrace.log+1] = entry
        print("[T] " .. entry)
        if #_G._STrace.log > 5000 then
            -- Trim if too big
            for _ = 1, 1000 do table.remove(_G._STrace.log, 1) end
        end
    end

    log("TRACE STARTED for Logic_SocialLobbyModule")

    local hooked = 0
    for name, fn in pairs(i) do
        if type(fn) == "function" and type(name) == "string" then
            local orig = fn
            i[name] = function(self, ...)
                local argc = select("#", ...)
                local argStr = ""
                for n = 1, math.min(argc, 4) do
                    local v = select(n, ...)
                    if type(v) == "table" then
                        argStr = argStr .. "tbl "
                    else
                        argStr = argStr .. tostring(v):sub(1, 20) .. " "
                    end
                end
                log("CALL " .. name .. "(" .. argStr .. ")")

                local ok, r = pcall(orig, self, ...)
                if not ok then
                    log("  ⚠ ERR " .. name .. " → " .. tostring(r):sub(1, 120))
                    return nil
                end
                if r ~= nil then
                    if type(r) == "table" then
                        local n = 0; for _ in pairs(r) do n = n + 1 end
                        log("  ↳ RET tbl(" .. n .. ")")
                    else
                        log("  ↳ RET " .. tostring(r):sub(1, 60))
                    end
                else
                    log("  ↳ RET nil")
                end
                return r
            end
            hooked = hooked + 1
        end
    end

    log("HOOKED " .. hooked .. " functions")
    print("[TRACE] Hooked " .. hooked .. " functions. Open profile now.")

    -- Auto-save every 30 seconds
    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerLoop then
            ticker.AddTimerLoop(0, function()
                if not _G._STrace then return end
                pcall(function()
                    local txt = table.concat(_G._STrace.log, "\n")
                    WRITE("pslot_trace.txt", txt)
                end)
            end, -1, 30.0)
        end
    end)
end

_G.DumpTrace = function(showPopup)
    if not _G._STrace then 
        if showPopup then POPUP("TRACE", "No trace data") end
        return
    end
    local txt = table.concat(_G._STrace.log, "\n")
    local ok, path = WRITE("pslot_trace.txt", txt)
    if showPopup then
        if ok then
            POPUP("✓ TRACE SAVED", 
                "Lines: " .. #_G._STrace.log .. "\n" ..
                "Size: " .. #txt .. " bytes\n" ..
                "File: pslot_trace.txt")
        else
            POPUP("✗ TRACE FAIL", path)
        end
    end
    return txt
end

-- ═══════════════════════════════════════════════════════════════════
-- AUTO-BOOT: dump on load + popup
-- ═══════════════════════════════════════════════════════════════════
_G.PSlotBoot = function()
    -- 1. Fire dump
    local txt = _G.PSlotDumpAll(true)
    -- 2. Start trace
    pcall(_G.TraceSlots)
end

-- Auto-run after 5 seconds (game has loaded module by then)
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(5.0, function()
            pcall(_G.PSlotBoot)
        end)
    end
end)

-- Also do immediate test-write to confirm path works
pcall(function()
    local testOK, testPath = WRITE("_pslot_test.txt", 
        "LOADED at " .. os.date("%Y-%m-%d %H:%M:%S") .. "\nPath OK: " .. DUMP_DIR)
    if testOK then
        print("[PATH TEST] ✓ Write OK: " .. testPath)
    else
        print("[PATH TEST] ✗ Write FAILED to: " .. DUMP_DIR)
        -- Try to alert user
        pcall(function()
            local ticker = require("common.time_ticker")
            if ticker and ticker.AddTimerOnce then
                ticker.AddTimerOnce(3.0, function()
                    POPUP("⚠ PATH WARNING", 
                        "Could not write to:\n" .. DUMP_DIR .. "\n" ..
                        "Check storage permission.")
                end)
            end
        end)
    end
end)

print("[PSLOT v4] Loaded. Auto-dump will fire in 5s. Files → " .. DUMP_DIR)

return true
