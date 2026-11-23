-----------------------------------
-- solo_story : surcharges de settings/default/map.lua
-- Seules les clés listées ici changent ; les autres gardent les valeurs par défaut (fillMissingKeys).
-----------------------------------
xi          = xi or {}
xi.settings = xi.settings or {}

xi.settings.map =
{
    -- XP
    EXP_RATE      = 2.0, -- XP des mobs
    CAPACITY_RATE = 2.0, -- Capacity points (Job Points)
    EXP_RETAIN    = 1,   -- 1 = aucune perte d'XP à la mort

    -- Trusts (plage valide 0.1 à 2.0)
    ALTER_EGO_HP_MULTIPLIER    = 1.5,
    ALTER_EGO_MP_MULTIPLIER    = 1.5,
    ALTER_EGO_STAT_MULTIPLIER  = 1.2,
    ALTER_EGO_SKILL_MULTIPLIER = 1.2,
    TRUST_TP_MULTIPLIER        = 1.5,

    -- Repos (/heal) : un tick toutes les 3 s (retail 10). Bonus en % : settings/solo_story.lua
    HEALING_TICK_DELAY = 3,
}
