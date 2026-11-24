-----------------------------------
-- solo_story : tests rangements (lua/storage_unlock.lua) et !mog (lua/mog_anywhere.lua + data/zones)
-----------------------------------
describe('solo_story storage and mog menu', function()
    it('unlocks safe, safe 2, sack and locker to 80, permanent all-areas locker and 2nd floor', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE })
        -- spawnPlayer déclenche déjà la connexion (nation 0 à ce moment) : on rejoue le déblocage
        -- après avoir fixé la nation, comme pour un vrai perso créé avec sa nation.
        player:setNation(xi.nation.WINDURST)
        player:setCharVar('[solo_story]storageUnlocked', 0)
        xi.player.onGameIn(player, false, false)

        for name, loc in pairs({ safe = xi.inv.MOGSAFE, safe2 = xi.inv.MOGSAFE2, sack = xi.inv.MOGSACK, locker = xi.inv.MOGLOCKER }) do
            assert(player:getContainerSize(loc) == 80, string.format('%s size %d', name, player:getContainerSize(loc)))
        end

        assert(player:getCharVar('mog-locker-access-type') == xi.moghouse.lockerAccessType.ALLAREAS, 'locker not all areas')
        assert(player:getCharVar('mog-locker-expiry-timestamp') == 2147483647, 'locker lease not permanent')

        local flag = player:getMoghouseFlag()
        assert(bit.band(flag, 0x0027) == 0x0027, string.format('moghouse flags 0x%X', flag))
        assert(bit.band(flag, 0x0180) == 0x0100, string.format('second floor style: flag 0x%X nation %d WINDURST=%d', flag, player:getNation(), xi.nation.WINDURST))

        -- Une 2e connexion ne réapplique rien (tailles inchangées)
        xi.player.onGameIn(player, false, false)
        assert(player:getContainerSize(xi.inv.MOGSAFE) == 80, 'safe grew again')
    end)

    it('registers !mog for non-GM players', function()
        local found
        for _, entry in ipairs(xi.module.commandRegistry or {}) do
            if entry.name == 'mog' then
                found = entry.command
            end
        end

        if found == nil and xi.commands then
            found = xi.commands.mog
        end

        assert(found ~= nil, '!mog not registered')
        assert(found.cmdprops.permission == 0, 'permission should be 0')
    end)

    it('patches zones with mogmenu (East Ronfaure yes, GM jail no)', function()
        local field = xi.test.world:spawnPlayer({ zone = xi.zone.EAST_RONFAURE })
        assert(field:canUseMisc(xi.zoneMisc.MOGMENU), 'East Ronfaure should allow the mog menu')

        local jail = xi.test.world:spawnPlayer({ zone = xi.zone.MORDION_GAOL })
        assert(not jail:canUseMisc(xi.zoneMisc.MOGMENU), 'Mordion Gaol must stay without mog menu')
    end)
end)
