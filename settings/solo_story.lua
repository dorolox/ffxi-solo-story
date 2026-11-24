-----------------------------------
-- solo_story : interrupteurs du module (modules/solo_story/)
-----------------------------------
xi          = xi or {}
xi.settings = xi.settings or {}

xi.settings.solo_story =
{
    -- Kit de départ appliqué à la création du perso (premier login uniquement)
    STARTER_TRUSTS = true, -- 3 permis Trust + Excenmille, Naji, Kupipi
    STARTER_MOUNT  = true, -- Full Speed Ahead! terminée : Trainer's Whistle + Raptor (utilisable niv. 20)

    -- Trusts
    TRUST_FIVE = true, -- 5 Trusts sans les KI RoV Rhapsody in White/Crimson
    TRUST_IN_BATTLEFIELDS = true, -- Trusts autorisés dans tous les battlefields (BCNM, avatars, Limit Break...)

    -- Repos (/heal) : % des PV/PM max ajoutés à chaque tick (0 = désactivé). Intervalle : map.HEALING_TICK_DELAY
    REST_REGEN_PERCENT = 10,

    -- Téléportations : tous les home points + survival guides (une fois, à la connexion)
    WARPS_UNLOCK_ALL = true,
    -- Tarif home points / survival guides ÷ 5 (comme Rhapsody in White, sans la KI)
    WARPS_DISCOUNT   = true,

    -- Boutique de sorts : Moogle "Grimoire" à Lower Jeuno et dans les 3 capitales (rechargement de zone requis)
    SPELL_SHOP = true,

    -- Mobs trop forts : un mob de NO_AGGRO_LEVEL_DIFF niveaux ou plus au-dessus du joueur ne l'agresse pas.
    -- Lu par le coeur C++ (patch src/map/zone_entities.cpp, voir modules/solo_story/PATCHES.md). 0 = retail.
    -- Redémarrage des serveurs requis après modification.
    NO_AGGRO_LEVEL_DIFF = 6,

    -- Rangements : Mog Safe/Safe 2/Sack/Locker à 80, Locker permanent toutes zones, 2e étage débloqué
    STORAGE_UNLOCK_ALL = true,
    -- Commande !mog (sans GM) : menu du Moogle partout (zones patchées avec mogmenu)
    MOG_ANYWHERE = true,

    -- Rééquilibrage des jobs repris de CatsEyeXI (partie Lua : lua/job_rebalance.lua ;
    -- niveaux/rangs : sql/catseye_jobs.sql et data/*.yaml, appliqués indépendamment de ce réglage)
    CATSEYE_JOBS = true,
}
