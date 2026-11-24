-----------------------------------
-- solo_story : tests du rééquilibrage des jobs (sql/catseye_jobs.sql, lua/job_rebalance.lua)
-----------------------------------
describe('solo_story CatsEye job rebalance', function()
    local function spawn(job, level)
        return xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = job, level = level })
    end

    describe('levels (SQL)', function()
        it('gives THF Dual Wield at level 20', function()
            assert(spawn(xi.job.THF, 20):getMod(xi.mod.DUAL_WIELD) > 0, 'THF 20 should have Dual Wield')
            assert(spawn(xi.job.THF, 19):getMod(xi.mod.DUAL_WIELD) == 0, 'THF 19 should not have Dual Wield yet')
        end)

        it('gives MNK Attack Bonus at level 30', function()
            local mnk30, mnk29 = spawn(xi.job.MNK, 30), spawn(xi.job.MNK, 29)
            assert(mnk30:getMod(xi.mod.ATTP) > mnk29:getMod(xi.mod.ATTP) or mnk30:getMod(xi.mod.ATT) > mnk29:getMod(xi.mod.ATT),
                'MNK 30 should gain Attack Bonus')
        end)
    end)

    describe('stances and durations (Lua)', function()
        local cases =
        {
            { 'WAR Retaliation',   xi.job.WAR, 60, function(p) xi.job_utils.warrior.useRetaliation(p, p, nil) end,  xi.effect.RETALIATION,   7200 },
            { 'MNK Counterstance', xi.job.MNK, 45, function(p) xi.job_utils.monk.useCounterstance(p, p, nil) end,   xi.effect.COUNTERSTANCE, 7200 },
            { 'SAM Hasso',         xi.job.SAM, 25, function(p) xi.job_utils.samurai.useHasso(p, p, nil) end,        xi.effect.HASSO,         7200 },
            { 'MNK Focus',         xi.job.MNK, 25, function(p) xi.job_utils.monk.useFocus(p, p, nil) end,           xi.effect.FOCUS,           75 },
            { 'MNK Footwork',      xi.job.MNK, 65, function(p) xi.job_utils.monk.useFootwork(p, p, nil) end,        xi.effect.FOOTWORK,       120 },
        }

        for _, c in ipairs(cases) do
            it(c[1] .. ' lasts ' .. c[6] .. ' s', function()
                local player = spawn(c[2], c[3])
                c[4](player)
                local effect = player:getStatusEffect(c[5])
                assert(effect, 'effect not applied')
                assert(effect:getDuration() == c[6] * 1000, string.format('duration %d ms', effect:getDuration()))
            end)
        end
    end)

    it('NIN Mijin Gakure leaves the ninja at 1 HP with 3 shadows', function()
        local player = spawn(xi.job.NIN, 75)
        local mob = player.entities:get('Forest_Hare') or player.entities:get('Wild_Rabbit')
        player:setHP(player:getMaxHP())
        xi.job_utils.ninja.useMijinGakure(player, mob, nil, nil)
        assert(not player:isDead(), 'ninja died')
        assert(player:getHP() == 1, string.format('HP %d', player:getHP()))
        local shadows = player:getStatusEffect(xi.effect.COPY_IMAGE)
        assert(shadows and shadows:getPower() == 3, 'expected 3 shadows')
    end)
end)
