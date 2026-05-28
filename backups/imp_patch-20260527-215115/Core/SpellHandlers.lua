-- Core/SpellHandlers.lua
local _, ns = ...
local L = ns.L
local Utils = ns.Utils or {}

-- Safely get a numeric power value for a unit and power type
local function SafeUnitPower(unit, powerType)
    if not unit or not powerType then return 0 end
    local ok, val = pcall(UnitPower, unit, powerType)
    if not ok or val == nil then return 0 end
    return tonumber(val) or 0
end

-- Get count of Imps (or similar) with defensive checks
local function GetHoGImpCount(unit)
    -- If unit is nil, default to player
    unit = unit or "player"
    -- SPELL_POWER_HOLY_POWER may not be defined in all contexts; guard it
    local powerType = rawget(_G, "SPELL_POWER_HOLY_POWER") or 0
    local count = SafeUnitPower(unit, powerType)
    return math.floor(count)
end

-- Hardened implosion handler that tolerates missing APIs and nils
local function HandleImplosion(spellId)
    if not spellId then return end
    local name = Utils.SafeGetSpellInfo and Utils.SafeGetSpellInfo(spellId) or nil
    if not name then
        -- fallback: try legacy GetSpellInfo if available
        if GetSpellInfo then
            local ok, n = pcall(GetSpellInfo, spellId)
            if ok then name = n end
        end
    end
    if not name then return end
    -- existing implosion logic should be invoked here; keep minimal side effects
    if ns.TriggerImplosionPopup and type(ns.TriggerImplosionPopup) == "function" then
        pcall(ns.TriggerImplosionPopup, name)
    end
end

-- Expose handlers
ns.SpellHandlers = ns.SpellHandlers or {}
ns.SpellHandlers.GetHoGImpCount = GetHoGImpCount
ns.SpellHandlers.HandleImplosion = HandleImplosion

return ns.SpellHandlers
