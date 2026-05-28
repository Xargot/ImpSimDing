local addonName, ns = ...
ns = ImpSimDingNS
local A = ns.A

-- WoW 12.0 removed COMBAT_LOG_EVENT_UNFILTERED for addons; use unit spell events.

local function canUseNumeric(value)
    if value == nil then
        return false
    end
    if issecretvalue and issecretvalue(value) then
        return canaccessvalue and canaccessvalue(value)
    end
    return true
end

local SOUL_SHARD_POWER = Enum.PowerType.SoulShards
local NPC_HOG = 55659
local NPC_PASSIVE = 143622

function A:OnSpellCastStart(unit, spellId)
    if unit ~= "player" or spellId ~= ns.HOG_SPELL_ID then
        return
    end
    A.soulShardsAtCastStart = UnitPower("player", SOUL_SHARD_POWER)
end

local function GetHoGImpCount()
    local now = UnitPower("player", SOUL_SHARD_POWER)
    local before = A.soulShardsAtCastStart
    A.soulShardsAtCastStart = nil

    if before and canUseNumeric(before) and canUseNumeric(now) then
        local spent = before - now
        if spent > 0 then
            return math.max(1, math.min(3, math.floor(spent + 0.001)))
        end
    end

    return 3
end

function A:OnSpellCastSucceeded(unit, spellId)
    if unit ~= "player" then
        return
    end

    if spellId == ns.HOG_SPELL_ID then
        local count = GetHoGImpCount()
        for _ = 1, count do
            A:AddTrackedImp(nil, NPC_HOG)
        end
        return
    end

    if spellId == ns.IMPLOSION_SPELL_ID then
        A:ResetAfterImplosion()
        return
    end

    if spellId == ns.TYRANT_SPELL_ID then
        A:ExtendAllImps(ns.TYRANT_EXTENSION)
        return
    end

    if spellId == ns.POWER_SIPHON_SPELL_ID then
        A:RemoveOldestImps(2)
    end
end
