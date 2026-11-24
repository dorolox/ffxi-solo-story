-----------------------------------
-- solo_story : test des téléportations (modules/solo_story/lua/warps.lua)
-----------------------------------
describe('solo_story warps', function()
    local saved = {}
    local TELEPORT = 2 -- selection.TELEPORT (scripts/globals/homepoint.lua)

    before_each(function()
        saved.unlock   = xi.settings.solo_story.WARPS_UNLOCK_ALL
        saved.discount = xi.settings.solo_story.WARPS_DISCOUNT
    end)

    after_each(function()
        xi.settings.solo_story.WARPS_UNLOCK_ALL = saved.unlock
        xi.settings.solo_story.WARPS_DISCOUNT   = saved.discount
    end)

    it('unlocks every home point and survival guide once at login', function()
        xi.settings.solo_story.WARPS_UNLOCK_ALL = true
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.SOUTHERN_SAN_DORIA })
        xi.player.onGameIn(player, false, false)

        for _, i in ipairs({ 0, 9, 63, 121 }) do
            assert(player:hasTeleport(xi.teleport.type.HOMEPOINT, i % 32, math.floor(i / 32)), 'missing home point ' .. i)
        end

        for _, g in ipairs({ 0, 1, 2 }) do
            assert(player:hasTeleport(xi.teleport.type.SURVIVAL, 31, g), 'missing survival guide group ' .. g)
        end

        assert(player:getCharVar('[solo_story]warpsUnlocked') >= 1, 'unlock flag not set')
        assert(not player:hasKeyItem(xi.keyItem.RHAPSODY_IN_WHITE), 'Rhapsody in White must not be given')
    end)

    -- Home point San d'Oria #1 (index 0, groupe 1) -> Bastok Mines #1 (index 9, groupe 2) : 500 g retail.
    local function costOfTeleport(discount)
        xi.settings.solo_story.WARPS_UNLOCK_ALL = true
        xi.settings.solo_story.WARPS_DISCOUNT   = discount
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.SOUTHERN_SAN_DORIA })
        xi.player.onGameIn(player, false, false)
        player:setGil(10000)
        player.entities:gotoAndTrigger('HomePoint#1', { eventId = 8700, finishOption = bit.bor(TELEPORT, bit.lshift(9, 16)) })
        return 10000 - player:getGil()
    end

    it('charges 1/5 of the retail fee when WARPS_DISCOUNT is on', function()
        local cost = costOfTeleport(true)
        assert(cost == 100, string.format('expected 100 gil, paid %d', cost))
    end)

    it('charges the retail fee when WARPS_DISCOUNT is off', function()
        local cost = costOfTeleport(false)
        assert(cost == 500, string.format('expected 500 gil, paid %d', cost))
    end)
end)
