-----------------------------------
-- solo_story : test du kit de départ (modules/solo_story/lua/starter_kit.lua + settings/main.lua)
-- NB: ALL_MAPS n'est pas testable ici, xi_test force ALL_MAPS = 0 (src/test/test_engine.cpp).
-----------------------------------
describe('solo_story starter kit', function()
    it('gives permits, starter trusts, the raptor mount and the level cap at creation', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE })
        xi.player.charCreate(player)

        for _, ki in ipairs({
            xi.keyItem.SAN_DORIA_TRUST_PERMIT, xi.keyItem.BASTOK_TRUST_PERMIT, xi.keyItem.WINDURST_TRUST_PERMIT,
            xi.keyItem.TRAINERS_WHISTLE, xi.keyItem.RAPTOR_COMPANION,
        }) do
            assert(player:hasKeyItem(ki), string.format('missing key item %d', ki))
        end

        for _, spellId in ipairs({ xi.magic.spell.EXCENMILLE, xi.magic.spell.NAJI, xi.magic.spell.KUPIPI }) do
            assert(player:hasSpell(spellId), string.format('missing trust spell %d', spellId))
        end

        assert(player:hasCompletedQuest(xi.questLog.JEUNO, xi.quest.id.jeuno.FULL_SPEED_AHEAD), 'Full Speed Ahead! not completed')
        assert(player:getLevelCap() == xi.settings.main.INITIAL_LEVEL_CAP,
            string.format('level cap %d, expected %d', player:getLevelCap(), xi.settings.main.INITIAL_LEVEL_CAP))
    end)
end)
