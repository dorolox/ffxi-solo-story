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

    -- Repos (/heal) : % des PV/PM max ajoutés à chaque tick (0 = désactivé). Intervalle : map.HEALING_TICK_DELAY
    REST_REGEN_PERCENT = 10,
}
