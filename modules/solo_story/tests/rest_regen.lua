-----------------------------------
-- solo_story : test de la régénération au repos (modules/solo_story/lua/rest_regen.lua)
-----------------------------------
local ffi = require('ffi')

describe('solo_story rest regen', function()
    local saved

    before_each(function()
        saved = xi.settings.solo_story.REST_REGEN_PERCENT
    end)

    after_each(function()
        xi.settings.solo_story.REST_REGEN_PERCENT = saved
    end)

    -- Fait 2 ticks de repos (le 1er ne soigne pas) et renvoie les PV regagnés.
    local function healedAfterTwoTicks(percent)
        xi.settings.solo_story.REST_REGEN_PERCENT = percent
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, level = 75, job = xi.job.WAR })
        player:setHP(1)
        -- Vrai paquet client /heal (0x0E8), comme scripts/tests/systems/monstrosity/restrictions.lua
        local camp = ffi.new('uint8_t[8]')
        camp[4] = 1
        player.packets:send(0x0E8, camp, assert(ffi.sizeof(camp)))
        assert(player:hasStatusEffect(xi.effect.HEALING), '/heal did not start')
        -- skipTime ne déclenche qu'un tick par appel : on avance tick par tick.
        for _ = 1, 2 do
            xi.test.world:skipTime(xi.settings.map.HEALING_TICK_DELAY)
        end
        return player:getHP() - 1, player:getMaxHP()
    end

    it('adds REST_REGEN_PERCENT of max HP on top of the retail heal', function()
        local retail = healedAfterTwoTicks(0)
        local boosted, maxHP = healedAfterTwoTicks(10)
        local expectedBonus = math.floor(maxHP * 10 / 100)
        assert(boosted - retail >= expectedBonus,
            string.format('bonus too small: retail %d, boosted %d, max %d', retail, boosted, maxHP))
    end)

    it('does nothing when REST_REGEN_PERCENT is 0', function()
        local a = healedAfterTwoTicks(0)
        assert(a > 0 and a < 100, string.format('unexpected retail heal %d', a))
    end)
end)
