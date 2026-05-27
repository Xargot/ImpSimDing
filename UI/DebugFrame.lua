local addonName, ns = ...
ns = ImpSimDingNS

local DB = ns.DB
local A  = ns.A

local f
local testMode = false
local lastAlertTime = 0
local ALERT_COOLDOWN = 2.5

---------------------------------------------------------------------
-- CREATE DEBUG FRAME
---------------------------------------------------------------------

local function CreateDebug()
    f = CreateFrame("Frame", "ImpSimDingDebugFrame", UIParent, "BackdropTemplate")
    f:SetSize(260, 300)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    f:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile     = true, tileSize = 16, edgeSize = 12,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(0, 0, 0, 0.7)

    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.text:SetPoint("TOPLEFT", 8, -8)
    f.text:SetJustifyH("LEFT")
    f.text:SetJustifyV("TOP")

    f.timerText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    f.timerText:SetPoint("BOTTOMLEFT", 8, 8)
    f.timerText:SetText("Timer: 0.0s")

    ---------------------------------------------------------
    -- STOP/PAUSE BUTTON (existing)
    ---------------------------------------------------------
    f.markButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.markButton:SetSize(80, 20)
    f.markButton:SetPoint("BOTTOMRIGHT", -8, 8)
    f.markButton:SetText("Mark")

    ---------------------------------------------------------
    -- TEST BUTTON (moved ABOVE stop button)
    ---------------------------------------------------------
    f.testButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.testButton:SetSize(80, 20)
    f.testButton:SetPoint("BOTTOMRIGHT", -8, 32) -- moved UP
    f.testButton:SetText("Test")

    f:Hide()
end

---------------------------------------------------------------------
-- SESSION TIMER (continuous from login / reload)
---------------------------------------------------------------------

function ns.GetSessionElapsed()
    if A.sessionStartTime and A.sessionStartTime > 0 then
        return GetTime() - A.sessionStartTime
    end
    return 0
end

function ns.OnFirstImpSpawned()
    A.firstImpPending = false
    A.firstLogin = false
end

function ns.ResetSessionTimer()
    A.sessionStartTime = GetTime()
end

function ns.ResetFirstImpTimer()
    ns.ResetSessionTimer()
end

local function UpdateTimerDisplay()
    if not f or not f.timerText then
        return
    end
    f.timerText:SetText(string.format("Session: %.1fs", ns.GetSessionElapsed()))
end

local function SetupTimerUpdate()
    f:SetScript("OnUpdate", function()
        UpdateTimerDisplay()
    end)
end

---------------------------------------------------------------------
-- MARK BUTTON DEBUG DUMP
---------------------------------------------------------------------

local function SetupMarkButton()
    f.markButton:SetScript("OnClick", function()
        local now = GetTime()
        local sessionElapsed = ns.GetSessionElapsed()
        print(string.format("|cff00ff00[ImpSimDing]|r Session Mark: %.2fs since login (now=%.2f)", sessionElapsed, now))

        for _, imp in ipairs(A.imps) do
            local remaining = imp.diesAt - now
            print(string.format(
                "  Imp %d: spawn=%.2f diesAt=%.2f remaining=%.2f",
                imp.id,
                imp.spawnTime or -1,
                imp.diesAt or -1,
                remaining
            ))
        end
    end)
end

---------------------------------------------------------------------
-- IMPLOSION POPUP
---------------------------------------------------------------------

local imploPopup = CreateFrame("Frame", "ImpSimDingImplosionPopup", UIParent)
imploPopup:SetSize(260, 80)
imploPopup:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
imploPopup:Hide()

imploPopup.bg = imploPopup:CreateTexture(nil, "BACKGROUND")
imploPopup.bg:SetAllPoints()
imploPopup.bg:SetColorTexture(0, 0, 0, 0.65)

imploPopup.text = imploPopup:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
imploPopup.text:SetPoint("CENTER")
imploPopup.text:SetText("|cffff4444IMPLOSION NOW|r")

imploPopup.fade = imploPopup:CreateAnimationGroup()
local fadeIn = imploPopup.fade:CreateAnimation("Alpha")
fadeIn:SetFromAlpha(0)
fadeIn:SetToAlpha(1)
fadeIn:SetDuration(0.15)

local fadeOut = imploPopup.fade:CreateAnimation("Alpha")
fadeOut:SetFromAlpha(1)
fadeOut:SetToAlpha(0)
fadeOut:SetDuration(0.4)
fadeOut:SetStartDelay(0.8)

imploPopup.fade:SetScript("OnFinished", function()
    imploPopup:Hide()
end)

function ns.ShowImplosionPopup()
    imploPopup:Show()
    imploPopup:SetAlpha(0)
    imploPopup.fade:Stop()
    imploPopup.fade:Play()
    local soundId = DB().soundId or (ns.SOUND_OPTIONS and ns.SOUND_OPTIONS[1].id) or 8959
    PlaySound(soundId, "Master")
end

---------------------------------------------------------------------
-- TEST BUTTON (Option C)
---------------------------------------------------------------------

local function SetupTestButton()
    f.testButton:SetScript("OnClick", function()
        testMode = true

        print("|cff00ff00[ImpSimDing]|r TEST MODE ACTIVATED")
        print("---- DEBUG SNAPSHOT ----")

        local now = GetTime()

        print("Alive Imps:", #A.imps)
        print("Total Spawned:", A.totalSpawned)
        print("Demonic Core stacks:", A.demonicCoreStacks)

        local nextDeath = nil
        for _, imp in ipairs(A.imps) do
            local remaining = imp.diesAt - now
            if not nextDeath or remaining < nextDeath then
                nextDeath = remaining
            end
        end

        print("Next Death:", nextDeath or "None")

        local cd = ns.GetSpellCooldownRemaining(ns.IMPLOSION_SPELL_ID)
        if cd ~= nil then
            print("Implosion CD:", string.format("%.2f", cd))
        else
            print("Implosion CD: (unavailable)")
        end

        ns.ShowImplosionPopup()
    end)
end

---------------------------------------------------------------------
-- SAFE COOLDOWN CHECK
---------------------------------------------------------------------

function ns.IsImplosionReady()
    if testMode then
        return true
    end

    return ns.IsSpellOffCooldown(ns.IMPLOSION_SPELL_ID)
end

---------------------------------------------------------------------
-- IMP LIST HELPERS
---------------------------------------------------------------------

local function BuildImpList(now)
    local list = {}

    for _, imp in ipairs(A.imps) do
        local remaining = imp.diesAt - now
        if remaining < 0 then remaining = 0 end

        table.insert(list, {
            id        = imp.id,
            remaining = remaining,
        })
    end

    table.sort(list, function(a, b)
        return a.remaining < b.remaining
    end)

    return list
end

local function GetNextSpawn(now)
    if A.firstImpPending then
        local remaining = ns.FIRST_SPAWN_DELAY - (now - A.lastPassiveSpawn)
        if remaining < 0 then remaining = 0 end
        return remaining
    end
    local elapsed = now - A.lastPassiveSpawn
    local remaining = (ns.PASSIVE_INTERVAL or 12) - elapsed
    if remaining < 0 then remaining = 0 end
    return remaining
end

local function GetNextDeath(now)
    local nextDeath = nil
    for _, imp in ipairs(A.imps) do
        local remaining = imp.diesAt - now
        if remaining > 0 and (not nextDeath or remaining < nextDeath) then
            nextDeath = remaining
        end
    end
    return nextDeath
end

local function CheckImplosion(now)
    if testMode then
        return
    end

    local alive = #A.imps
    local nextDeath = GetNextDeath(now)
    local threshold = DB().threshold or 6
    local highThreshold = threshold + 2
    local shouldImplode = false

    if ns.IsImplosionReady() then
        if alive >= highThreshold then
            shouldImplode = true
        elseif alive >= threshold and nextDeath and nextDeath > 3 then
            shouldImplode = true
        end
    end

    if shouldImplode and (now - lastAlertTime) >= ALERT_COOLDOWN then
        lastAlertTime = now
        ns.ShowImplosionPopup()
    end
end

---------------------------------------------------------------------
-- UPDATE DEBUG + IMPLOSION LOGIC
---------------------------------------------------------------------

function ns.UpdateDebug()
    if not f then return end

    local now = GetTime()

    CheckImplosion(now)

    if not DB().debug then
        f:Hide()
        return
    end

    f:Show()

    local alive     = #A.imps
    local total     = A.totalSpawned
    local nextSpawn = GetNextSpawn(now)
    local nextDeath = GetNextDeath(now)

    local lines = {}

    table.insert(lines, string.format("Alive Imps: %d", alive))
    table.insert(lines, string.format("Total Spawned: %d", total))
    table.insert(lines, string.format("Demonic Core: %d", A.demonicCoreStacks))
    table.insert(lines, string.format("Next Spawn: %.1fs", nextSpawn))

    if nextDeath then
        table.insert(lines, string.format("Next Death: %.1fs", nextDeath))
    else
        table.insert(lines, "Next Death: —")
    end

    table.insert(lines, "")

    local impList = BuildImpList(now)
    for i, data in ipairs(impList) do
        table.insert(lines, string.format("Imp #%d — dies in %.1fs", i, data.remaining))
    end

    f.text:SetText(table.concat(lines, "\n"))
end

---------------------------------------------------------------------
-- INIT
---------------------------------------------------------------------

CreateDebug()
SetupMarkButton()
SetupTestButton()
SetupTimerUpdate()

if A.sessionStartTime and A.sessionStartTime > 0 then
    UpdateTimerDisplay()
elseif A.firstImpPending then
    ns.ResetSessionTimer()
    UpdateTimerDisplay()
end
