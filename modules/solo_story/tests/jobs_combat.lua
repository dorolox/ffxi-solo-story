-----------------------------------
-- solo_story : tests du rééquilibrage combat (lua/job_rebalance_combat.lua)
-----------------------------------
describe('solo_story CatsEye combat rebalance', function()
    local function drkWithFrostbite()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.DRK, level = 75 })
        player:setSkillLevel(xi.skill.GREAT_SWORD, 3000) -- x10 : 300 de compétence
        player:addItem(xi.item.CLAYMORE)
        player:equipItem(xi.item.CLAYMORE, nil, xi.slot.MAIN)
        player:setTP(1000)
        local mob = player.entities:get('Forest_Hare')
        mob:respawn()
        xi.test.world:skipTime(1)
        mob:setHP(mob:getMaxHP())
        stub('xi.combat.physicalHitRate.getPhysicalHitRate', 1)
        return player, mob
    end

    it('adds CATSEYE_WS_BONUS to Frostbite while it runs, then removes it, and applies Frost', function()
        local player, mob = drkWithFrostbite()
        local mod = xi.mod.WEAPONSKILL_DAMAGE_BASE + xi.weaponskill.FROSTBITE
        local seen

        -- Appelée au milieu du calcul de doMagicWeaponskill : on y lit le modificateur actif.
        stub('xi.combat.damage.scarletDeliriumMultiplier', function(attacker)
            seen = attacker:getMod(mod)
            return 1
        end)

        local hpBefore = mob:getHP()
        player.actions:engage(mob)
        player.actions:useWeaponskill(mob, xi.weaponskill.FROSTBITE)
        xi.test.world:skipTime(3)
        local diag = string.format('tp=%d mobHP %d->%d dist=%.1f engaged=%s', player:getTP(), hpBefore, mob:getHP(), player:checkDistance(mob), tostring(player:isEngaged()))

        assert(seen == xi.settings.solo_story.CATSEYE_WS_BONUS, string.format('bonus during WS: %s (%s)', tostring(seen), diag))
        assert(player:getMod(mod) == 0, 'bonus not removed after the WS')
        assert(mob:isDead() or mob:hasStatusEffect(xi.effect.FROST), 'Frost not applied')
    end)

    it('bar-status spells scale with enhancing skill (30 single / 20 -ra, + skill/5)', function()
        local player = xi.test.world:spawnPlayer({ job = xi.job.WHM, level = 75 })
        local skill = player:getSkillLevel(xi.skill.ENHANCING_MAGIC)
        local spell = { getSkillType = function() return xi.skill.ENHANCING_MAGIC end }
        local single = xi.spells.enhancing.calculateEnhancingBasePower(player, player, spell, xi.magic.spell.BARSLEEP, xi.effect.BARSLEEP)
        local ra     = xi.spells.enhancing.calculateEnhancingBasePower(player, player, spell, xi.magic.spell.BARSLEEPRA, xi.effect.BARSLEEP)
        assert(single == 30 + math.floor(skill / 5), string.format('single %d (skill %d)', single, skill))
        assert(ra == 20 + math.floor(skill / 5), string.format('ra %d (skill %d)', ra, skill))
    end)

    it('gives player avatars +15 magic accuracy', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.SMN, level = 75 })
        player:spawnPet(xi.petId.CARBUNCLE)
        xi.test.world:skipTime(1)
        local avatar = player:getPet()
        assert(avatar and avatar:isAvatar(), 'no avatar')

        xi.settings.solo_story.CATSEYE_JOBS = false
        local before = xi.mobskills.calculatePetMagicAccuracyBonus(avatar)
        xi.settings.solo_story.CATSEYE_JOBS = true
        local after = xi.mobskills.calculatePetMagicAccuracyBonus(avatar)
        assert(after == before + 15, string.format('bonus %d -> %d', before, after))
    end)
end)
