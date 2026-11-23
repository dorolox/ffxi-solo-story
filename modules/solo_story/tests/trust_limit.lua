-----------------------------------
-- solo_story : test de la limite de Trusts (modules/solo_story/lua/trust_limit.lua)
-- Lancement :
--   docker compose run --rm --no-deps -v ./modules/solo_story/tests:/server/scripts/tests/solo_story \
--     map ./xi_test --file solo_story
-----------------------------------
describe('solo_story trust limit', function()
    local party = { xi.magic.spell.NAJI, xi.magic.spell.KUPIPI, xi.magic.spell.EXCENMILLE, xi.magic.spell.AYAME }
    local saved

    -- Invoque directement n Trusts (spawnTrust ne passe pas par canCast)
    local function withTrusts(n)
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE })
        player:addKeyItem(xi.keyItem.SAN_DORIA_TRUST_PERMIT)
        for i = 1, n do
            player:spawnTrust(party[i])
        end

        xi.test.world:skipTime(1)
        return player
    end

    local function canCastNext(player)
        local spellId = xi.magic.spell.VOLKER
        return xi.trust.canCast(player, { getID = function() return spellId end })
    end

    before_each(function()
        saved = xi.settings.solo_story.TRUST_FIVE
    end)

    after_each(function()
        xi.settings.solo_story.TRUST_FIVE = saved
    end)

    it('allows a 4th and 5th trust without the RoV key items when TRUST_FIVE is on', function()
        xi.settings.solo_story.TRUST_FIVE = true
        assert(canCastNext(withTrusts(3)) == 0, '4th trust refused')
        local player = withTrusts(4)
        assert(canCastNext(player) == 0, '5th trust refused')
        assert(not player:hasKeyItem(xi.keyItem.RHAPSODY_IN_WHITE), 'Rhapsody in White must not be given')
        assert(not player:hasKeyItem(xi.keyItem.RHAPSODY_IN_CRIMSON), 'Rhapsody in Crimson must not be given')
    end)

    it('still caps the party at 6 (5 trusts + player)', function()
        xi.settings.solo_story.TRUST_FIVE = true
        local player = withTrusts(4)
        player:spawnTrust(xi.magic.spell.VOLKER)
        xi.test.world:skipTime(1)
        local spellId = xi.magic.spell.CURILLA
        assert(xi.trust.canCast(player, { getID = function() return spellId end }) == -1, '6th trust allowed')
    end)

    it('keeps the retail limit of 3 when TRUST_FIVE is off', function()
        xi.settings.solo_story.TRUST_FIVE = false
        assert(canCastNext(withTrusts(3)) == -1, '4th trust allowed without the key item')
    end)
end)
