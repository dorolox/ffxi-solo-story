-----------------------------------
-- solo_story : rééquilibrage des jobs CatsEyeXI, partie 3 (tout en Lua)
--  - Tous : pas de pénalité de distance au tir (xi.combat.ranged.*DistancePenalty = 0)
--  - MNK/PUP : pénalité de TP des mains nues due à Martial Arts divisée par deux
--    (xi.combat.tp.getModifiedDelayAndCanZanshin voit Martial Arts / 2)
--  - BST (pets jug et charmés appelés par Call Beast / Bestial Loyalty) :
--      DEF +10 % ; bonus CHR = min(100, +CHR / 2) en ATT%, ACC, MATT, MACC, DEF%, dégâts de skillchain ;
--      contre +CHR / 8 ; capacités Ready x (1 + +CHR/400) x min(2, 1 + TP/3000)
--      (+CHR = CHR apporté par l'équipement/effets/mérites, mérites comptés double)
--  - THF : Trick Attack consommé par un coup transfère CATSEYE_TRICK_ATTACK_TRANSFER % de la haine du
--    voleur (CE et VE) au partenaire
--  - NIN : ninjutsu élémentaire qui inflige des dégâts -> TP = Ninja Tool Expertise (mod NINJA_TOOL, max 100)
-- Interrupteur : CATSEYE_JOBS
-----------------------------------
require('modules/module_utils')
require('scripts/globals/mobskills')
require('scripts/globals/job_utils/beastmaster')
require('scripts/globals/spells/damage_spell')
local proxy = require('modules/solo_story/lua/entity_proxy')
-----------------------------------
local m = Module:new('solo_story_job_rebalance_extra')

local function cfg(key, default)
    local s = xi.settings.solo_story
    if s == nil or s.CATSEYE_JOBS ~= true then
        return nil
    end

    if key == nil then
        return true
    end

    local value = s[key]
    if value == nil then
        return default
    end

    return value
end

-- ===== Tir : pas de pénalité de distance =====
m:addOverride('xi.combat.ranged.accuracyDistancePenalty', function(attacker, target, ...)
    if cfg() and attacker ~= nil and attacker:isPC() then
        return 0
    end

    return super(attacker, target, ...)
end)

m:addOverride('xi.combat.ranged.attackDistancePenalty', function(actor, target, ...)
    if cfg() and actor ~= nil and actor:isPC() then
        return 0
    end

    return super(actor, target, ...)
end)

-- ===== Mains nues : moitié de la pénalité de TP de Martial Arts =====
m:addOverride('xi.combat.tp.getModifiedDelayAndCanZanshin', function(actor, delay)
    if cfg() and actor ~= nil and actor:isPC() and actor:getMod(xi.mod.MARTIAL_ARTS) > 0 then
        local halfMartialArts = proxy.wrap(actor, {
            getMod = function(real, mod)
                if mod == xi.mod.MARTIAL_ARTS then
                    return math.floor(real:getMod(mod) / 2)
                end

                return real:getMod(mod)
            end,
        })
        return super(halfMartialArts, delay)
    end

    return super(actor, delay)
end)

-- ===== BST : pets renforcés =====
local function plusCHR(master)
    return math.max(0, master:getMod(xi.mod.CHR) + master:getMerit(xi.merit.CHR))
end

local function empowerPet(player)
    local pet = player:getPet()
    if pet == nil or pet:getLocalVar('[solo_story]bstBuffed') == 1 then
        return
    end

    local chr   = plusCHR(player)
    local bonus = math.min(100, math.floor(chr / 2))
    pet:addMod(xi.mod.DEFP, 10 + bonus)
    pet:addMod(xi.mod.ATTP, bonus)
    pet:addMod(xi.mod.ACC, bonus)
    pet:addMod(xi.mod.MATT, bonus)
    pet:addMod(xi.mod.MACC, bonus)
    pet:addMod(xi.mod.SKILLCHAINDMG, bonus)
    pet:addMod(xi.mod.COUNTER, math.floor(chr / 8))
    pet:setLocalVar('[solo_story]bstBuffed', 1)
end

for _, fn in ipairs({ 'xi.job_utils.beastmaster.useCallBeast', 'xi.job_utils.beastmaster.useBestialLoyalty' }) do
    m:addOverride(fn, function(player, target, ability, ...)
        local result = super(player, target, ability, ...)
        if cfg() then
            empowerPet(player)
        end

        return result
    end)
end

local function readyMultiplier(mob, skill)
    if not cfg() or mob == nil or not mob:isJugPet() then
        return 1
    end

    local master = mob:getMaster()
    if master == nil or not master:isPC() then
        return 1
    end

    local tp = skill and skill:getTP() or 0
    return (1 + plusCHR(master) / 400) * math.min(2, 1 + tp / 3000)
end

for _, fn in ipairs({ 'xi.mobskills.mobPhysicalMove', 'xi.mobskills.mobMagicalMove' }) do
    m:addOverride(fn, function(mob, target, skill, ...)
        local info = super(mob, target, skill, ...)
        local mult = readyMultiplier(mob, skill)
        if mult ~= 1 and info ~= nil and (info.damage or 0) > 0 and (info.hitsLanded or 0) > 0 then
            info.damage = math.floor(info.damage * mult)
        end

        return info
    end)
end

-- ===== THF : Trick Attack transfère une partie de la haine =====
m:addOverride('xi.effects.trick_attack.onEffectLose', function(thief, effect)
    super(thief, effect)

    local percent = cfg('CATSEYE_TRICK_ATTACK_TRANSFER', 50)
    -- Encore du temps restant = consommé par un coup (et non expiré).
    if not percent or percent <= 0 or not thief:isPC() or effect:getTimeRemaining() <= 0 then
        return
    end

    local mob = thief:getTarget()
    if mob == nil or not mob:isMob() then
        return
    end

    local partner = thief:getTrickAttackChar(mob)
    if partner == nil or partner:getID() == thief:getID() then
        return
    end

    local ce, ve = mob:getCE(thief), mob:getVE(thief)
    local ceMove = math.floor(ce * percent / 100)
    local veMove = math.floor(ve * percent / 100)
    if ceMove + veMove > 0 then
        mob:setCE(thief, ce - ceMove)
        mob:setVE(thief, ve - veMove)
        mob:addEnmity(partner, ceMove, veMove)
    end
end)

-- ===== NIN : TP sur ninjutsu élémentaire =====
m:addOverride('xi.spells.damage.useDamageSpell', function(caster, target, spell)
    local damage = super(caster, target, spell)
    if
        cfg() and
        (damage or 0) > 0 and
        caster ~= nil and caster:isPC() and
        target ~= nil and target:isMob() and
        spell:getSkillType() == xi.skill.NINJUTSU
    then
        local tp = math.min(100, caster:getMod(xi.mod.NINJA_TOOL))
        if tp > 0 then
            caster:addTP(tp)
        end
    end

    return damage
end)
