-- Core/SpellHandlers.lua
local _, ns = ...
local L = ns.L
local Utils = ns.Utils or {}
local A = ns.A

-- Safely get a numeric power value for a unit and power type (kept for compatibility)
local function SafeUnitPower(unit, powerType)
    if not unit or not powerType then return 0 end
    local ok, val = pcall(UnitPower, unit, powerType)
    if not ok or val == nil then return 0 end
    return tonumber(val) or 0
end

-- Get count of HoG imps using the addon-managed imp list (Midnight-safe)
local function GetHoGImpCount()
    if not A or not A.imps then return 0 end
    return #A.imps
end

-- Robust spell name resolution for Midnight
local function ResolveSpellName(spellId)
    if not spellId then return nil end
    -- Try C_Spell first
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, spellId)
        if ok and info then
            if type(info) == "table" and info.name then
                return info.name
            elseif type(info) == "string" then
                return info
            else
                -- sometimes GetSpellInfo returns multiple values; try first
                return info
            end
        end
    end
    -- Fallback to legacy GetSpellInfo
    if GetSpellInfo then
        local ok, name = pcall(GetSpellInfo, spellId)
        if ok then return name end
    end
    return nil
end

-- Hardened implosion handler that tolerates missing APIs and nils
local function HandleImplosion(spellId)
    if not spellId then return end
    local name = ResolveSpellName(spellId)
    if not name then return end
    if ns.TriggerImplosionPopup and type(ns.TriggerImplosionPopup) == "function" then
        pcall(ns.TriggerImplosionPopup, name)
    end
end

-- Expose handlers
ns.SpellHandlers = ns.SpellHandlers or {}
ns.SpellHandlers.GetHoGImpCount = GetHoGImpCount
ns.SpellHandlers.HandleImplosion = HandleImplosion

return ns.SpellHandlers
