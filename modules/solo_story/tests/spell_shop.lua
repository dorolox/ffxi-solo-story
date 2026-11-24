-----------------------------------
-- solo_story : test de la boutique de sorts (modules/solo_story/lua/spell_shop.lua)
-----------------------------------
describe('solo_story spell shop', function()
    local SCROLL_OF_CURE    = 4609 -- Cure : WHM 1, RDM 3, PLD 5, SCH 5 ; prix PNJ 67
    local SCROLL_OF_CURE_II = 4610 -- Cure II : WHM 11
    local SCROLL_OF_FIRE    = 4752 -- Fire : BLM 13, RDM 19

    local function priceOf(stock, itemId)
        for _, row in ipairs(stock) do
            if row[1] == itemId then
                return row[2]
            end
        end

        return nil
    end

    it('offers the spells of the main job up to its level, at the NPC price', function()
        local player = xi.test.world:spawnPlayer({ job = xi.job.WHM, level = 1 })
        local stock = xi.soloStory.buildSpellShopStock(player)
        assert(priceOf(stock, SCROLL_OF_CURE) == 67, 'Cure missing or wrong price')
        assert(priceOf(stock, SCROLL_OF_CURE_II) == nil, 'Cure II offered below level 11')
        assert(priceOf(stock, SCROLL_OF_FIRE) == nil, 'Fire offered to a WHM')
    end)

    it('hides spells already known', function()
        local player = xi.test.world:spawnPlayer({ job = xi.job.WHM, level = 1 })
        player:addSpell(xi.magic.spell.CURE)
        local stock = xi.soloStory.buildSpellShopStock(player)
        assert(priceOf(stock, SCROLL_OF_CURE) == nil, 'known spell still offered')
    end)

    it('includes the subjob spells up to the subjob level', function()
        local player = xi.test.world:spawnPlayer({ job = xi.job.WAR, level = 40 })
        player:changeJob(xi.job.WAR)
        player:changesJob(xi.job.BLM)
        player:setsLevel(20)
        local stock = xi.soloStory.buildSpellShopStock(player)
        assert(priceOf(stock, SCROLL_OF_FIRE) ~= nil, 'subjob BLM 20 should see Fire (BLM 13)')
    end)

    it('spawns Grimoire in Lower Jeuno and opens the shop with the filtered stock', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.LOWER_JEUNO, job = xi.job.WHM, level = 1 })
        local seen
        local original = xi.shop.general
        xi.shop.general = function(p, stock, log)
            seen = stock
            return original(p, stock, log)
        end

        local ok, err = pcall(function()
            player.entities:gotoAndTrigger('DE_Grimoire') -- préfixe interne des entités dynamiques
        end)
        xi.shop.general = original

        assert(ok, tostring(err))
        assert(seen ~= nil, 'shop was not opened')
        assert(priceOf(seen, SCROLL_OF_CURE) == 67, 'shop stock does not contain Cure at 67')
    end)
end)
