-- ═══════════════════════════════════════════════════════════════════
-- v43 HOT RELOADER — Same folder script watcher
-- Path: /storage/emulated/0/Android/data/com.pubg.imobile/files/
-- Ek baar daalo. Phir *.lua changes auto re-run honge.
-- ═══════════════════════════════════════════════════════════════════
pcall(function()
    local DIR = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"
    local REGISTRY = {}     -- [filename] = { hash, lastRun }
    local CHECK_INTERVAL = 1.5

    local function blog(s)
        pcall(function()
            local f = io.open(DIR .. "hotreload.log", "a")
            if f then
                f:write("[" .. os.date("%H:%M:%S") .. "] " .. tostring(s) .. "\n")
                f:close()
            end
        end)
    end

    -- Simple djb2 hash
    local function hash(s)
        local h = 5381
        for i = 1, #s do
            h = (h * 33 + s:byte(i)) % 4294967296
        end
        return h
    end

    -- List *.lua in DIR (io.popen primary, known names fallback)
    local function listFiles()
        local names = {}
        local seen = {}
        local ok, pipe = pcall(io.popen, "ls " .. DIR .. "*.lua 2>/dev/null")
        if ok and pipe then
            for line in pipe:lines() do
                local n = line:match("([^/]+)$")
                if n and n:match("%.lua$") and not seen[n] then
                    seen[n] = true
                    names[#names+1] = n
                end
            end
            pipe:close()
        end
        if #names == 0 then
            for _, n in ipairs({
                "run.lua", "main.lua", "inject.lua", "active.lua",
                "v43.lua", "v44.lua", "v45.lua", "v46.lua", "v47.lua",
                "drop.lua", "vehicle.lua", "spawn.lua",
            }) do
                local f = io.open(DIR .. n, "r")
                if f then
                    f:close()
                    names[#names+1] = n
                end
            end
        end
        return names
    end

    -- Run one file if changed
    local function runIfChanged(name)
        if name == "hotreload.lua" then return end  -- skip self
        local path = DIR .. name
        local f = io.open(path, "r")
        if not f then return end
        local src = f:read("*a")
        f:close()
        if not src or #src == 0 then return end

        local h = hash(src)
        local reg = REGISTRY[name]
        if reg and reg.hash == h then return end

        local fn, perr = (loadstring or load)(src, name)
        if not fn then
            blog("PARSE FAIL " .. name .. " :: " .. tostring(perr):sub(1, 120))
            return
        end

        local ok, rerr = pcall(fn)
        if ok then
            REGISTRY[name] = { hash = h, lastRun = os.time() }
            blog("RUN OK " .. name .. " (" .. #src .. "b, hash=" .. h .. ")")
        else
            REGISTRY[name] = { hash = h, lastRun = os.time() }
            blog("RUN ERR " .. name .. " :: " .. tostring(rerr):sub(1, 200))
        end
    end

    local function scanAll()
        for _, n in ipairs(listFiles()) do
            pcall(runIfChanged, n)
        end
    end

    -- Avoid duplicate timers
    if _G.__HOT_RELOADER_ACTIVE then
        blog("Re-instantiated — rescanning")
        pcall(scanAll)
        return
    end
    _G.__HOT_RELOADER_ACTIVE = true

    blog("════════════════════════════════════")
    blog("HOT RELOADER START — DIR=" .. DIR)
    blog("════════════════════════════════════")

    -- Initial scan
    pcall(scanAll)

    -- Ticker loop
    local tick = 0
    local function loopFn()
        tick = tick + 1
        pcall(scanAll)
        if tick % 40 == 0 then
            blog("tick " .. tick .. " (alive)")
        end
    end

    pcall(function()
        local tk = require("common.time_ticker")
        if tk and tk.AddTimerLoop then
            tk.AddTimerLoop(0, loopFn, -1, CHECK_INTERVAL)
            blog("Ticker loop @ " .. CHECK_INTERVAL .. "s")
        elseif _G.SetTimer then
            _G.SetTimer(CHECK_INTERVAL, loopFn, -1)
            blog("SetTimer fallback @ " .. CHECK_INTERVAL .. "s")
        else
            blog("NO TIMER AVAILABLE")
        end
    end)

    -- Manual reload API
    _G.HOT_RELOAD_NOW = function()
        REGISTRY = {}
        scanAll()
        blog("MANUAL RELOAD triggered")
    end

    _G.HOT_STATUS = function()
        local lines = {}
        for name, r in pairs(REGISTRY) do
            lines[#lines+1] = name .. " hash=" .. r.hash
        end
        return table.concat(lines, "\n")
    end

    -- Popup
    pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
        if Msg and Msg.Show then
            Msg.Show(1, "HOT RELOADER",
                "Active. Files in:\n" .. DIR ..
                "\n\nEdit any *.lua → auto re-run.",
                function() end, function() end, "OK", "CLOSE")
        end
    end)

    print("[HOT RELOADER] active")
end)
-- ═══════════════════════════════════════════════════════════════════
-- END HOT RELOADER — original BRPlayerCharacterBase code continues below
-- ═══════════════════════════════════════════════════════════════════
