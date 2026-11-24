-----------------------------------
-- solo_story : test des Trusts en battlefield (modules/solo_story/lua/trust_battlefield.lua)
-- Entrée réelle dans Save the Children (Ghelsba Outpost), mise en place reprise de
-- scripts/tests/missions/sandoria.lua, puis allowTrusts forcé à false pour ce battlefield.
-----------------------------------
describe('solo_story trusts in battlefields', function()
    local bfId = xi.battlefield.id.SAVE_THE_CHILDREN
    local player
    local saved = {}

    local function nextTrust()
        local spellId = xi.magic.spell.VOLKER
        return xi.trust.canCast(player, { getID = function() return spellId end })
    end

    before_each(function()
        saved.setting     = xi.settings.solo_story.TRUST_IN_BATTLEFIELDS
        saved.allowTrusts = xi.battlefield.contents[bfId].allowTrusts
        saved.countFn     = xi.trust.checkBattlefieldTrustCount

        player = xi.test.world:spawnPlayer()
        player:setNation(xi.nation.SANDORIA)

        -- Comme scripts/tests/missions/sandoria.lua : évite la cinématique SoA qui s'intercale
        player:addMission(xi.mission.log_id.SOA, xi.mission.id.soa.RUMORS_FROM_THE_WEST)
        local missionStatus = player:getMissionStatus(xi.mission.log_id.SOA)
        missionStatus = utils.mask.setBit(missionStatus, 0, true)
        missionStatus = utils.mask.setBit(missionStatus, 1, true)
        player:setMissionStatus(xi.mission.log_id.SOA, missionStatus)
        player:completeMission(xi.mission.log_id.SOA, xi.mission.id.soa.RUMORS_FROM_THE_WEST)

        player:setRank(1)
        player:addMission(xi.mission.log_id.SANDORIA, xi.mission.id.sandoria.SMASH_THE_ORCISH_SCOUTS)
        player:completeMission(xi.mission.log_id.SANDORIA, xi.mission.id.sandoria.SMASH_THE_ORCISH_SCOUTS)
        player:addMission(xi.mission.log_id.SANDORIA, xi.mission.id.sandoria.BAT_HUNT)
        player:completeMission(xi.mission.log_id.SANDORIA, xi.mission.id.sandoria.BAT_HUNT)
        player:gotoZone(xi.zone.SOUTHERN_SAN_DORIA)
        player.entities:gotoAndTrigger('Ambrotien', { eventId = 2009, finishOption = 102 })
        player:gotoZone(xi.zone.NORTHERN_SAN_DORIA)
        player.entities:gotoAndTrigger('Arnau', { eventId = 693 })
        player:gotoZone(xi.zone.GHELSBA_OUTPOST)
        player.bcnm:enter('Hut_Door', bfId)
        assert(player:getBattlefieldID() == bfId, 'not inside the battlefield')

        xi.battlefield.contents[bfId].allowTrusts = false
    end)

    after_each(function()
        xi.settings.solo_story.TRUST_IN_BATTLEFIELDS = saved.setting
        xi.battlefield.contents[bfId].allowTrusts    = saved.allowTrusts
        xi.trust.checkBattlefieldTrustCount          = saved.countFn
    end)

    it('refuses trusts in a no-trust battlefield when TRUST_IN_BATTLEFIELDS is off', function()
        xi.settings.solo_story.TRUST_IN_BATTLEFIELDS = false
        assert(nextTrust() == xi.msg.basic.TRUST_NO_CAST_TRUST, 'trust allowed with the setting off')
    end)

    it('allows trusts and lifts the participant cap when TRUST_IN_BATTLEFIELDS is on', function()
        xi.settings.solo_story.TRUST_IN_BATTLEFIELDS = true
        local sawBattlefield = 'not called'
        xi.trust.checkBattlefieldTrustCount = function(caster)
            sawBattlefield = caster:getBattlefield()
            return saved.countFn(caster)
        end

        assert(nextTrust() == 0, 'trust refused with the setting on')
        assert(sawBattlefield == nil, 'participant cap still sees the battlefield')
        assert(player:getBattlefieldID() == bfId, 'the real player left the battlefield')

        -- Le Trust invoqué fait partie du battlefield (trustutils::SpawnTrust)
        player:spawnTrust(xi.magic.spell.VOLKER)
        xi.test.world:skipTime(1)
        local trust
        for _, member in ipairs(player:getPartyWithTrusts()) do
            if member:isTrust() then
                trust = member
            end
        end

        assert(trust, 'trust was not summoned')
        assert(trust:getBattlefieldID() == bfId, 'trust is not part of the battlefield')
    end)
end)
