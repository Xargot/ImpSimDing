local addonName, ns = ...

ns = ImpSimDingNS

local A = ns.A



---------------------------------------------------------------------

-- EVENT FRAME

---------------------------------------------------------------------

local f = CreateFrame("Frame")

f:RegisterEvent("PLAYER_LOGIN")

-- 12.0+: COMBAT_LOG_EVENT_UNFILTERED is forbidden; use player spell unit events.

f:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")

f:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")

f:RegisterUnitEvent("UNIT_AURA", "player")



---------------------------------------------------------------------

-- HANDLERS TABLE

---------------------------------------------------------------------

local handlers = {}



---------------------------------------------------------------------

-- PLAYER LOGIN

---------------------------------------------------------------------

function handlers.PLAYER_LOGIN()
    local now = GetTime()
    A.sessionStartTime = now
    A.lastPassiveSpawn = now
    A.firstImpPending = true
    A.firstLogin = true
    A.soulShardsAtCastStart = nil
    A:UpdateDemonicCore()
    if ns.ResetSessionTimer then
        ns.ResetSessionTimer()
    end
end



---------------------------------------------------------------------

-- UNIT AURA (Demonic Core tracking)

---------------------------------------------------------------------

function handlers.UNIT_AURA(unit)

    if unit == "player" then

        A:UpdateDemonicCore()

    end

end



---------------------------------------------------------------------

-- SPELL CASTS (HoG / Implosion / Tyrant / Power Siphon)

---------------------------------------------------------------------

function handlers.UNIT_SPELLCAST_START(unit, _, spellId)

    A:OnSpellCastStart(unit, spellId)

end



function handlers.UNIT_SPELLCAST_SUCCEEDED(unit, _, spellId)

    A:OnSpellCastSucceeded(unit, spellId)

end



---------------------------------------------------------------------

-- ON UPDATE (passive spawn + prune + UI)

---------------------------------------------------------------------

f:SetScript("OnUpdate", function()

    A:DebugTick()

end)



---------------------------------------------------------------------

-- EVENT DISPATCH

---------------------------------------------------------------------

f:SetScript("OnEvent", function(_, event, ...)

    if handlers[event] then

        handlers[event](...)

    end

end)

