local addonName, ns = ...

-- Shared namespace
ImpSimDingNS = ImpSimDingNS or {}
ns = ImpSimDingNS

-- Constants
ns.IMPLOSION_SPELL_ID      = 196277
ns.HAND_OF_GULDAN_SPELL_ID = 105174
ns.DEMONBOLT_SPELL_ID      = 264178

ns.PASSIVE_IMP_LIFETIME = 21.5 -- inner demons / passive wild imps (~33.5s from login with 12.5s delay)
ns.HOG_IMP_LIFETIME     = 12   -- Hand of Gul'dan imps (~6 fel bolts at 0% haste)
ns.PASSIVE_INTERVAL     = 12   -- inner demons passive interval
ns.TYRANT_SPELL_ID     = 265187
ns.POWER_SIPHON_SPELL_ID = 264130
ns.TYRANT_EXTENSION    = 15

ns.MINIMAP_ICON_TEXTURE = "Interface\\AddOns\\ImpSimDing\\Media\\minimap-icon.tga"

ns.SOUND_OPTIONS = {
    { name = "Raid Warning",       id = 8959  },
    { name = "Ready Check",        id = 8960  },
    { name = "Bell Toll Alliance", id = 54189 },
    { name = "Bell Toll Horde",    id = 54188 },
    { name = "PVP Queue",          id = 8459  },
    { name = "Epic Loot",          id = 8957  },
    { name = "Level Up",           id = 888   },
}

local defaults = {
    debug        = false,
    threshold    = 6,
    soundId      = ns.SOUND_OPTIONS[1].id,
    minimapAngle = 225,
}

function ns.DB()
    if not ImpSimDingDB then
        ImpSimDingDB = CopyTable(defaults)
    end
    return ImpSimDingDB
end