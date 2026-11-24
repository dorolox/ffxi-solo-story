-----------------------------------
-- solo_story : Trusts autorisés dans tous les battlefields (BCNM, épreuves d'avatars, Limit Break...)
-- Dans xi.trust.canCast (scripts/globals/trust.lua), 3 contrôles dépendent du battlefield :
--   1) battlefield.contents[id].allowTrusts (false par défaut : 141 battlefields sur 200)
--   2) battlefields RoV qui exigent la KI Rhapsody in Umber
--   3) checkBattlefieldTrustCount : joueurs + Trusts < maxPlayers (1 en Limit Break, 3 en orbes...)
-- On appelle l'original avec un proxy qui "n'est pas dans un battlefield" (getBattlefieldID = -1,
-- getBattlefield = nil). Le reste reste actif : groupe de 6 max, villes, alliance, ennemis en vue.
-- Le Trust invoqué hérite bien du battlefield de son maître (trustutils::SpawnTrust).
-- Les Trusts sont toujours renvoyés à l'entrée d'un battlefield (comme en retail) : les réinvoquer dedans.
-- Interrupteur : settings/solo_story.lua (TRUST_IN_BATTLEFIELDS)
-----------------------------------
require('modules/module_utils')
require('scripts/globals/trust')
local proxy = require('modules/solo_story/lua/entity_proxy')
-----------------------------------
local m = Module:new('solo_story_trust_battlefield')

m:addOverride('xi.trust.canCast', function(caster, spell, notAllowedTrustIds)
    local s = xi.settings.solo_story
    if s ~= nil and s.TRUST_IN_BATTLEFIELDS == true and caster:getBattlefieldID() ~= -1 then
        local outside = proxy.wrap(caster, {
            getBattlefieldID = function() return -1 end, -- valeur C++ hors battlefield (l'id 0 existe)
            getBattlefield   = function() return nil end,
        })
        return super(outside, spell, notAllowedTrustIds)
    end

    return super(caster, spell, notAllowedTrustIds)
end)
