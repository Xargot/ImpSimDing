local addonName, ns = ...
ns = ImpSimDingNS

local A  = ns.A
local DB = ns.DB

SLASH_IMPSIMDING1 = "/impsim"
SlashCmdList["IMPSIMDING"] = function(msg)
    msg = (msg or ""):lower()

    if msg == "reset" then
        A:ClearImps()
        A.totalSpawned = 0
        A.lastPassiveSpawn = GetTime()
        A.firstImpPending = true
        A.firstLogin = true
        if ns.UpdateDebug then ns.UpdateDebug() end
        print("|cff9966ffImpSimDing:|r Imp count reset.")
        return
    end

    if msg == "debug on" then
        DB().debug = true
        if ns.UpdateDebug then ns.UpdateDebug() end
        print("|cff9966ffImpSimDing:|r Debug ON")
        return
    end

    if msg == "debug off" then
        DB().debug = false
        if ns.UpdateDebug then ns.UpdateDebug() end
        print("|cff9966ffImpSimDing:|r Debug OFF")
        return
    end

    if msg == "config" or msg == "options" then
        if ns.OpenOptions then ns.OpenOptions() end
        return
    end

    print("|cff9966ffImpSimDing commands:|r")
    print("  /impsim reset      - reset imp count")
    print("  /impsim debug on   - show debug frame")
    print("  /impsim debug off  - hide debug frame")
    print("  /impsim config     - open options")
end