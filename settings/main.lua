-----------------------------------
-- solo_story : surcharges de settings/default/main.lua
-- ⚠ ALL_MAPS, SUBJOB_QUEST_LEVEL, ADVANCED_JOB_LEVEL, INITIAL_LEVEL_CAP, START_INVENTORY ne s'appliquent qu'à la création du perso.
-----------------------------------
xi          = xi or {}
xi.settings = xi.settings or {}

xi.settings.main =
{
    EXP_RATE = 2.0, -- XP des scripts (quêtes, etc.)

    -- Création du perso
    ALL_MAPS             = 1,  -- toutes les cartes
    SUBJOB_QUEST_LEVEL   = 0,  -- sous-job débloqué dès le départ
    ADVANCED_JOB_LEVEL   = 0,  -- jobs avancés PLD..SCH débloqués (GEO/RUN non inclus)
    INITIAL_LEVEL_CAP    = 99, -- plafond 99 dès la création (quêtes Limit Break facultatives)
    UNLOCK_OUTPOST_WARPS = 2,  -- tous les warps d'outpost + Tu'Lia et Tavnazia
    START_INVENTORY      = 80, -- inventaire et satchel au max

    -- Confort / Trusts
    SNEAK_INVIS_DURATION_MULTIPLIER = 3,
    ENABLE_TRUST_ALTER_EGO_EXPO     = 1, -- bonus Expo : HPP/MPP/résistances
}
