-- Core/Core.lua
local _, ns = ...
local L = ns.L

-- Centralized utility helpers for Core
local Utils = {}

-- Return true if value can be interpreted as a number
function Utils.canUseNumeric(val)
    if val == nil then return false end
    -- tonumber is safe for strings and numbers; protect with pcall for odd userdata
    local ok, n = pcall(tonumber, val)
    return ok and (n ~= nil)
end

-- Defensive wrapper around C_Spell.GetSpellInfo (or legacy GetSpellInfo)
function Utils.SafeGetSpellInfo(spellId)
    if not spellId then return nil end
    -- prefer secure C_Spell API when available
    local getter = (C_Spell and C_Spell.GetSpellInfo) or GetSpellInfo
    if not getter then return nil end
    local ok, name = pcall(getter, spellId)
    if not ok then return nil end
    return name
end

-- Export utilities
ns.Utils = ns.Utils or {}
for k, v in pairs(Utils) do ns.Utils[k] = v end

return ns.Utils
