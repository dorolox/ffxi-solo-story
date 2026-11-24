-----------------------------------
-- solo_story : tests du rééquilibrage, partie 3 (lua/job_rebalance_extra.lua)
-----------------------------------
describe('solo_story CatsEye rebalance part 3', function()
    local function setJobs(on)
        xi.settings.solo_story.CATSEYE_JOBS = on
    end

    after_each(function()
        setJobs(true)
    end)

    it('removes the ranged distance penalty for players', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.RNG, level = 75 })
        local mob = player.entities:get('Forest_Hare')
        mob:respawn()
        xi.test.world:skipTime(1)
        player:setPos(mob:getXPos() + 1, mob:getYPos(), mob:getZPos()) -- bout portant : pénalité en retail
        assert(xi.combat.ranged.accuracyDistancePenalty(player, mob) == 0, 'accuracy penalty not removed')
        assert(xi.combat.ranged.attackDistancePenalty(player, mob) == 0, 'attack penalty not removed')
    end)

    it('halves the Martial Arts TP penalty for hand-to-hand', function()
        local player = xi.test.world:spawnPlayer({ job = xi.job.MNK, level = 75 })
        assert(player:getMod(xi.mod.MARTIAL_ARTS) > 0, 'MNK 75 should have Martial Arts')
        local delay = 480

        setJobs(false)
        local retail = xi.combat.tp.getModifiedDelayAndCanZanshin(player, delay)
        setJobs(true)
        local soloStory = xi.combat.tp.getModifiedDelayAndCanZanshin(player, delay)

        assert(soloStory.modifiedDelay > retail.modifiedDelay,
            string.format('TP delay %s -> %s', tostring(retail.modifiedDelay), tostring(soloStory.modifiedDelay)))
    end)

    it('empowers a called jug pet with the +CHR bonuses and +10% DEF', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.BST, level = 75 })
        player:addMod(xi.mod.CHR, 40)
        player:addItem(xi.item.JUG_OF_CARROT_BROTH)
        player:equipItem(xi.item.JUG_OF_CARROT_BROTH, nil, xi.slot.AMMO)

        xi.job_utils.beastmaster.useCallBeast(player, player, nil)
        xi.test.world:skipTime(1)

        local pet = player:getPet()
        assert(pet ~= nil and pet:isJugPet(), 'no jug pet')
        local bonus = math.floor((40 + player:getMerit(xi.merit.CHR)) / 2)
        assert(pet:getMod(xi.mod.ATTP) >= bonus, string.format('ATTP %d < %d', pet:getMod(xi.mod.ATTP), bonus))
        assert(pet:getMod(xi.mod.DEFP) >= 10 + bonus, string.format('DEFP %d', pet:getMod(xi.mod.DEFP)))
    end)
end)
