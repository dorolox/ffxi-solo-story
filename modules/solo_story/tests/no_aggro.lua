-----------------------------------
-- solo_story : test du patch "mobs trop forts" (src/map/zone_entities.cpp, tapMobAggro)
-- Mise en place reprise de scripts/tests/systems/aggro_retap.lua.
-----------------------------------
describe('solo_story no aggro from much stronger mobs', function()
    local PLAYER_LEVEL = 20

    -- Renvoie true si le mob (au niveau mobLevel) agresse un joueur niveau 20 qui entre dans son champ de vision.
    local function aggroes(mobLevel)
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.IFRITS_CAULDRON, job = xi.job.WAR, level = PLAYER_LEVEL })
        local mob = player.entities:get('Volcanic_Bomb')
        mob:respawn()
        mob:setMobLevel(mobLevel)

        mob:setAggressive(true)
        mob:setMobMod(xi.mobMod.ALWAYS_AGGRO, 1)
        mob:setMobMod(xi.mobMod.DETECTION, xi.detects.SIGHT)
        mob:setMobMod(xi.mobMod.SIGHT_RANGE, 20)
        mob:setMobMod(xi.mobMod.ROAM_COOL, 3600)
        mob:setPos(-97.6, 19.7, -14.2)
        mob:clearPath()

        for _ = 1, 10 do
            xi.test.world:skipTime(5)
            xi.test.world:tickEntity(mob)
        end

        local mx, my, mz = mob:getXPos(), mob:getYPos(), mob:getZPos()
        mob:lookAt(mx + 100.0, my, mz)
        player.actions:move(mx + 30.0, my, mz)
        player.actions:move(mx + 3.0, my, mz)

        assert(mob:getMainLvl() == mobLevel, string.format('mob level %d, expected %d', mob:getMainLvl(), mobLevel))
        return mob:isEngaged()
    end

    it('does not aggro when the mob is NO_AGGRO_LEVEL_DIFF (6) levels or more above', function()
        xi.test.world:setSetting('solo_story.NO_AGGRO_LEVEL_DIFF', 6)
        assert(not aggroes(PLAYER_LEVEL + 6), 'mob 6 levels above should not aggro')
    end)

    it('still aggroes when the mob is less than NO_AGGRO_LEVEL_DIFF levels above', function()
        xi.test.world:setSetting('solo_story.NO_AGGRO_LEVEL_DIFF', 6)
        assert(aggroes(PLAYER_LEVEL + 5), 'mob 5 levels above should aggro')
    end)

    it('keeps the retail behavior when NO_AGGRO_LEVEL_DIFF is 0', function()
        xi.test.world:setSetting('solo_story.NO_AGGRO_LEVEL_DIFF', 0)
        assert(aggroes(PLAYER_LEVEL + 10), 'with the setting at 0 a much stronger mob should aggro')
    end)
end)
