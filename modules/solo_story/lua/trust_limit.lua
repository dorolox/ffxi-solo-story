-----------------------------------
-- solo_story : 5 Trusts dès le départ
-- Retail/LSB : 4e Trust = KI Rhapsody in White (RoV 1-6), 5e = Rhapsody in Crimson (RoV 2-13),
-- contrôlés dans xi.trust.canCast (scripts/globals/trust.lua).
-- On appelle l'original avec un proxy du lanceur qui répond "oui" à ces deux KI uniquement
-- (voir entity_proxy.lua). Le reste (6 membres max, zones/battlefields interdits) est inchangé,
-- et les KI ne sont PAS données : aucun effet sur les missions RoV, boutiques, survival guides.
-- Interrupteur : settings/solo_story.lua (TRUST_FIVE)
-----------------------------------
require('modules/module_utils')
require('scripts/globals/trust')
local proxy = require('modules/solo_story/lua/entity_proxy')
-----------------------------------
local m = Module:new('solo_story_trust_limit')

m:addOverride('xi.trust.canCast', function(caster, spell, notAllowedTrustIds)
    local s = xi.settings.solo_story
    if s ~= nil and s.TRUST_FIVE == true then
        local fake = proxy.withKeyItems(caster, { xi.keyItem.RHAPSODY_IN_WHITE, xi.keyItem.RHAPSODY_IN_CRIMSON })
        return super(fake, spell, notAllowedTrustIds)
    end

    return super(caster, spell, notAllowedTrustIds)
end)
