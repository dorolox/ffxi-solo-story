-----------------------------------
-- solo_story : rééquilibrage des jobs CatsEyeXI, partie combat (suite de job_rebalance.lua)
--  - NIN : +15 précision magique pour les ninjutsu lancés sur un ennemi
--  - SMN : +15 précision magique pour les Blood Pacts magiques ; +25 % de dégâts pour les
--          Blood Pacts de mérite du groupe 2 (Meteor Strike, Heavenly Strike, Wind Blade, Geocrush,
--          Thunderstorm, Grand Fall)
--  - WHM/RDM/RUN : sorts bar- de statut = base + compétence/5 (base 20 pour les -ra, 30 en mono-cible)
--  - Weapon skills renforcées : Wasp Sting, Viper Bite, Frostbite, Freezebite, Shadow of Death
--    (+CATSEYE_WS_BONUS % via le modificateur WEAPONSKILL_DAMAGE_BASE + wsID, ajouté le temps de la WS) ;
--    Frost (Frostbite, Freezebite) et Burn (Flaming Arrow, Hot Shot) pendant CATSEYE_WS_DEBUFF_DURATION s
--  - THF : chaque rang de mérite Ambush réduit le délai de Sneak Attack et Trick Attack de
--    CATSEYE_AMBUSH_RECAST s
-- Valeurs absentes de la source CatsEye (choisies avec le joueur) : réglables dans settings/solo_story.lua.
-- Interrupteur : CATSEYE_JOBS
-----------------------------------
require('modules/module_utils')
require('scripts/globals/weaponskills')
require('scripts/globals/mobskills')
require('scripts/globals/spells/enhancing_spell')
require('scripts/globals/job_utils/thief')
-----------------------------------
local m = Module:new('solo_story_job_rebalance_combat')

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

local function isPlayerAvatar(mob)
    if mob == nil or not mob:isAvatar() then
        return false
    end

    local master = mob:getMaster()
    return master ~= nil and master:isPC()
end

-- ===== Précision magique : ninjutsu (NIN) =====
m:addOverride('xi.combat.magicHitRate.calculateResistRate', function(actor, target, fedData)
    if
        cfg() and
        fedData ~= nil and
        fedData.skillType == xi.skill.NINJUTSU and
        actor ~= nil and actor:isPC() and
        target ~= nil and target:isMob()
    then
        local data = {}
        for k, v in pairs(fedData) do
            data[k] = v
        end

        data.bonusMacc = (data.bonusMacc or 0) + 15
        return super(actor, target, data)
    end

    return super(actor, target, fedData)
end)

-- ===== Blood Pacts (SMN) =====
m:addOverride('xi.mobskills.calculatePetMagicAccuracyBonus', function(mob)
    local bonus = super(mob)
    if cfg() and isPlayerAvatar(mob) then
        bonus = bonus + 15
    end

    return bonus
end)

local meritBloodPacts =
{
    [xi.jobAbility.METEOR_STRIKE]   = true,
    [xi.jobAbility.HEAVENLY_STRIKE] = true,
    [xi.jobAbility.WIND_BLADE]      = true,
    [xi.jobAbility.GEOCRUSH]        = true,
    [xi.jobAbility.THUNDERSTORM]    = true,
    [xi.jobAbility.GRAND_FALL]      = true,
}

m:addOverride('xi.mobskills.mobMagicalMove', function(mob, target, skill, action, skillParams)
    local info = super(mob, target, skill, action, skillParams)
    if
        cfg() and
        info ~= nil and (info.damage or 0) > 0 and (info.hitsLanded or 0) > 0 and
        isPlayerAvatar(mob) and
        skill ~= nil and meritBloodPacts[skill:getID()]
    then
        info.damage = math.floor(info.damage * 1.25)
    end

    return info
end)

-- ===== Sorts bar- de statut (WHM/RDM/RUN) =====
local barStatusRa = {}
for name, id in pairs(xi.magic.spell) do
    if string.sub(name, 1, 3) == 'BAR' and string.sub(name, -2) == 'RA' then
        barStatusRa[id] = true
    end
end

local function isBarStatus(effect)
    return effect == xi.effect.BARAMNESIA or (effect >= xi.effect.BARSLEEP and effect <= xi.effect.BARVIRUS)
end

m:addOverride('xi.spells.enhancing.calculateEnhancingBasePower', function(caster, target, spell, spellId, spellEffect)
    local power = super(caster, target, spell, spellId, spellEffect)
    if cfg() and isBarStatus(spellEffect) then
        local base = barStatusRa[spellId] and 20 or 30
        power = base + math.floor(caster:getSkillLevel(xi.skill.ENHANCING_MAGIC) / 5)
    end

    return power
end)

-- ===== Weapon skills renforcées + Frost / Burn =====
local boostedWeaponskills =
{
    [xi.weaponskill.WASP_STING]      = true,
    [xi.weaponskill.VIPER_BITE]      = true,
    [xi.weaponskill.FROSTBITE]       = true,
    [xi.weaponskill.FREEZEBITE]      = true,
    [xi.weaponskill.SHADOW_OF_DEATH] = true,
}

local weaponskillDebuff =
{
    [xi.weaponskill.FROSTBITE]     = xi.effect.FROST,
    [xi.weaponskill.FREEZEBITE]    = xi.effect.FROST,
    [xi.weaponskill.FLAMING_ARROW] = xi.effect.BURN,
    [xi.weaponskill.HOT_SHOT]      = xi.effect.BURN,
}

-- Même puissance que les sorts Frost/Burn (scripts/globals/spells/enfeebling_spell.lua), selon l'INT.
local function elementalDebuffPotency(attacker)
    local intStat = attacker:getStat(xi.mod.INT)
    local potency = 1
    if intStat > 150 then
        potency = 5
    elseif intStat > 100 then
        potency = 4
    elseif intStat > 70 then
        potency = 3
    elseif intStat > 40 then
        potency = 2
    end

    return potency + attacker:getMerit(xi.merit.ELEMENTAL_DEBUFF_EFFECT)
end

local function wrapWeaponskill(fnName)
    m:addOverride(fnName, function(attacker, target, wsID, params, tp, action, primary, ...)
        local active = cfg() and attacker ~= nil and attacker:isPC()
        local bonus  = active and boostedWeaponskills[wsID] and cfg('CATSEYE_WS_BONUS', 50) or 0
        local mod    = xi.mod.WEAPONSKILL_DAMAGE_BASE + wsID

        if bonus > 0 then
            attacker:addMod(mod, bonus)
        end

        local ok, damage, criticalHit, tpHits, extraHits = pcall(super, attacker, target, wsID, params, tp, action, primary, ...)

        if bonus > 0 then
            attacker:delMod(mod, bonus)
        end

        if not ok then
            error(damage)
        end

        local debuff = active and weaponskillDebuff[wsID]
        if debuff and (damage or 0) > 0 and target ~= nil and not target:isDead() and not target:hasStatusEffect(debuff) then
            target:addStatusEffect(debuff, {
                power    = elementalDebuffPotency(attacker),
                duration = cfg('CATSEYE_WS_DEBUFF_DURATION', 30),
                origin   = attacker,
                tick     = 3,
            })
        end

        return damage, criticalHit, tpHits, extraHits
    end)
end

wrapWeaponskill('xi.weaponskills.doPhysicalWeaponskill')
wrapWeaponskill('xi.weaponskills.doMagicWeaponskill')
wrapWeaponskill('xi.weaponskills.doRangedWeaponskill')

-- ===== THF : mérites Ambush -> délai de Sneak Attack / Trick Attack =====
local function ambushRecast(player, ability)
    local seconds = cfg('CATSEYE_AMBUSH_RECAST', 5)
    if seconds and ability ~= nil and player:isPC() then
        local ranks = math.floor(player:getMerit(xi.merit.AMBUSH) / 3)
        if ranks > 0 then
            ability:setRecast(math.max(0, ability:getRecast() - ranks * seconds))
        end
    end
end

for _, fn in ipairs({ 'xi.job_utils.thief.useSneakAttack', 'xi.job_utils.thief.useTrickAttack' }) do
    m:addOverride(fn, function(player, target, ability, ...)
        local result = super(player, target, ability, ...)
        ambushRecast(player, ability)
        return result
    end)
end
