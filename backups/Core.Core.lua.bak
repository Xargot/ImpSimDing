local addonName, ns = ...
ns = ImpSimDingNS

---------------------------------------------------------------------
-- SPELL IDS (Retail Midnight 12.0.5)
---------------------------------------------------------------------
ns.HOG_SPELL_ID        = 105174     -- Hand of Gul'dan
ns.IMPLOSION_SPELL_ID  = 196277     -- Implosion
ns.DEMONBOLT_SPELL_ID  = 264178     -- Demonbolt
ns.DEMONIC_CORE_AURA   = 264173     -- Demonic Core buff

---------------------------------------------------------------------
-- CONSTANTS
---------------------------------------------------------------------
ns.FIRST_SPAWN_DELAY   = 12.5
ns.DEATH_OFFSET        = 0

---------------------------------------------------------------------
-- CORE OBJECT
---------------------------------------------------------------------
local A = {}
ns.A = A

---------------------------------------------------------------------
-- STATE
---------------------------------------------------------------------
A.imps = {}
A.totalSpawned = 0

A.lastPassiveSpawn = 0
A.firstLogin = true
A.firstImpPending = true

A.demonicCoreStacks = 0
A.soulShardsAtCastStart = nil
A.sessionStartTime = 0

---------------------------------------------------------------------
-- 12.x secret value helpers
---------------------------------------------------------------------

local function canUseNumeric(value)
    if value == nil then
        return false
    end
    if issecretvalue and issecretvalue(value) then
        return canaccessvalue and canaccessvalue(value)
    end
    return true
end

---------------------------------------------------------------------
-- DEMONIC CORE TRACKING
---------------------------------------------------------------------

function A:UpdateDemonicCore()
    local stacks = 0
    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(ns.DEMONIC_CORE_AURA)
        if aura then
            local apps = aura.applications
            local charges = aura.charges
            if apps and canUseNumeric(apps) and apps > 0 then
                stacks = apps
            elseif charges and canUseNumeric(charges) and charges > 0 then
                stacks = charges
            else
                -- Aura present but stack count may be secret in 12.x restricted combat
                stacks = 1
            end
        end
    end
    A.demonicCoreStacks = stacks
end

---------------------------------------------------------------------
-- IMP LIFETIME (haste-scaled, matches energy/bolt despawn)
---------------------------------------------------------------------

function ns.GetWildImpLifetime(npcId)
    local base = ns.PASSIVE_IMP_LIFETIME or 21.5
    if npcId == 55659 then
        base = ns.HOG_IMP_LIFETIME or 12
    end

    local haste = 0
    if UnitSpellHaste then
        haste = UnitSpellHaste("player") or 0
    end
    return base / (1 + (haste / 100)) + ns.DEATH_OFFSET
end

---------------------------------------------------------------------
-- IMP TRACKING (12.x: spell events + passive timer; no combat log)
---------------------------------------------------------------------

function A:AddTrackedImp(guid, npcId)
    local now = GetTime()
    local lifetime = ns.GetWildImpLifetime(npcId)

    if not guid then
        guid = string.format("sim-%d-%d", now * 10000, math.random(1000, 9999))
    end

    table.insert(self.imps, {
        id        = now * 10000 + math.random(1000),
        spawnTime = now,
        diesAt    = now + lifetime,
        guid      = guid,
        npcId     = npcId,
    })

    self.totalSpawned = self.totalSpawned + 1
end

function A:SpawnPassiveImp()
    local wasFirstPending = self.firstImpPending
    self.firstLogin = false
    self.firstImpPending = false

    self:AddTrackedImp(nil, 143622)

    if wasFirstPending and ns.OnFirstImpSpawned then
        ns.OnFirstImpSpawned()
    end
end

function A:CheckPassiveSpawn()
    local now = GetTime()

    if self.firstImpPending then
        if now - self.lastPassiveSpawn >= ns.FIRST_SPAWN_DELAY then
            self.lastPassiveSpawn = now
            self:SpawnPassiveImp()
        end
        return
    end

    if now - self.lastPassiveSpawn >= ns.PASSIVE_INTERVAL then
        self.lastPassiveSpawn = now
        self:SpawnPassiveImp()
    end
end

function A:RemoveImpByGUID(guid)
    if not guid then
        return
    end
    for i = #self.imps, 1, -1 do
        if self.imps[i].guid == guid then
            table.remove(self.imps, i)
        end
    end
end

function A:RemoveOldestImps(count)
    if count <= 0 then
        return
    end

    table.sort(self.imps, function(a, b)
        return a.spawnTime < b.spawnTime
    end)

    for _ = 1, math.min(count, #self.imps) do
        table.remove(self.imps, 1)
    end
end

function A:ExtendAllImps(extraSeconds)
    local now = GetTime()
    for _, imp in ipairs(self.imps) do
        if imp.diesAt > now then
            imp.diesAt = imp.diesAt + extraSeconds
        end
    end
end

function A:ResetAfterImplosion()
    self:ClearImps()
    self.lastPassiveSpawn = GetTime()
    self.firstImpPending = true
    self.firstLogin = false
end

---------------------------------------------------------------------
-- IMP REMOVAL
---------------------------------------------------------------------

function A:ClearImps()
    self.imps = {}
end

function A:PruneImps()
    local now = GetTime()
    local alive = {}

    for _, imp in ipairs(self.imps) do
        if imp.diesAt > now then
            table.insert(alive, imp)
        end
    end

    self.imps = alive
end

---------------------------------------------------------------------
-- SPELL COOLDOWN (WoW 12.0+ — C_Spell, secret-safe)
---------------------------------------------------------------------

function ns.GetSpellCooldownRemaining(spellId)
    if not spellId then
        return nil
    end

    -- Prefer non-secret isActive when cooldown data is restricted (12.x)
    if C_Spell and C_Spell.GetSpellCooldown then
        local cd = C_Spell.GetSpellCooldown(spellId)
        if cd and cd.isActive == false then
            return 0
        end
    end

    if C_Spell and C_Spell.GetSpellCooldownDuration then
        local durObj = C_Spell.GetSpellCooldownDuration(spellId)
        if durObj then
            if durObj.IsZero and durObj:IsZero() then
                return 0
            end
            local remaining = durObj:GetRemainingDuration()
            if canUseNumeric(remaining) then
                return math.max(0, remaining)
            end
        end
    end

    if C_Spell and C_Spell.GetSpellCooldown then
        local cd = C_Spell.GetSpellCooldown(spellId)
        if cd then
            if cd.isEnabled == false then
                return nil
            end
            local start, duration = cd.startTime, cd.duration
            if canUseNumeric(start) and canUseNumeric(duration) then
                if start == 0 or duration == 0 then
                    return 0
                end
                return math.max(0, (start + duration) - GetTime())
            end
        end
    end

    return nil
end

function ns.IsSpellOffCooldown(spellId)
    if C_Spell and C_Spell.GetSpellCooldown then
        local cd = C_Spell.GetSpellCooldown(spellId)
        if cd and cd.isActive ~= nil then
            return cd.isActive == false
        end
    end

    if C_Spell and C_Spell.IsSpellUsable then
        local usable = C_Spell.IsSpellUsable(spellId)
        if usable ~= nil and canUseNumeric(usable) then
            return usable == true
        end
    end

    local remaining = ns.GetSpellCooldownRemaining(spellId)
    if remaining == nil then
        return false
    end
    return remaining <= 0
end

---------------------------------------------------------------------
-- DEBUG HOOK
---------------------------------------------------------------------

function A:DebugTick()
    self:CheckPassiveSpawn()
    self:PruneImps()
    ns.UpdateDebug()
end
