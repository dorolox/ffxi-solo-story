-----------------------------------
-- solo_story : 5 Trusts dès le départ
-- Retail/LSB : 4e Trust = KI Rhapsody in White (RoV 1-6), 5e = Rhapsody in Crimson (RoV 2-13),
-- contrôlés dans xi.trust.canCast (scripts/globals/trust.lua).
-- Plutôt que recopier canCast (qui dépend de la table locale rovKIBattlefieldIDs),
-- on appelle l'original avec un proxy du lanceur qui répond "oui" à ces deux KI
-- uniquement. Tout le reste (6 membres max, zones/battlefields interdits, etc.) est inchangé,
-- et les KI ne sont PAS données : aucun effet sur les missions RoV, boutiques, survival guides.
-- Interrupteur : settings/solo_story.lua (TRUST_FIVE)
-----------------------------------
require('modules/module_utils')
require('scripts/globals/trust')
-----------------------------------
local m = Module:new('solo_story_trust_limit')

local function makeCasterProxy(caster)
    local granted =
    {
        [xi.keyItem.RHAPSODY_IN_WHITE]   = true,
        [xi.keyItem.RHAPSODY_IN_CRIMSON] = true,
    }

    return setmetatable({}, {
        __index = function(_, key)
            if key == 'hasKeyItem' then
                return function(_, keyItem)
                    return granted[keyItem] == true or caster:hasKeyItem(keyItem)
                end
            end

            local value = caster[key]
            if type(value) == 'function' then
                return function(_, ...)
                    return value(caster, ...)
                end
            end

            return value
        end,
    })
end

m:addOverride('xi.trust.canCast', function(caster, spell, notAllowedTrustIds)
    local s = xi.settings.solo_story
    if s ~= nil and s.TRUST_FIVE == true then
        return super(makeCasterProxy(caster), spell, notAllowedTrustIds)
    end

    return super(caster, spell, notAllowedTrustIds)
end)
