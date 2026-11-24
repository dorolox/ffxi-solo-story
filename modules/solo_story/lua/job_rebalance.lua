-----------------------------------
-- solo_story : rééquilibrage des jobs repris de CatsEyeXI (bg-wiki CatsEyeXI_Systems/Jobs, rév. 2026-11-03)
-- Partie Lua. Les niveaux d'obtention / rangs sont dans sql/catseye_jobs.sql et data/*.yaml.
--  - "Postures" : Retaliation (WAR), Counterstance (MNK), Hasso et Seigan (SAM) durent 2 h
--    (délai 1 min : sql/catseye_jobs.sql ; Hasso/Seigan l'ont déjà en retail).
--  - MNK : Focus et Dodge 30 s -> 75 s, Footwork 60 s -> 120 s.
--  - NIN : Mijin Gakure laisse à 1 PV avec 3 ombres au lieu de tuer le ninja.
-- Les fonctions d'origine (scripts/globals/job_utils/*.lua) s'exécutent normalement ; seul l'effet
-- obtenu est allongé ensuite (setDuration en ms + resetStartTime).
-- Interrupteur : settings/solo_story.lua (CATSEYE_JOBS)
-----------------------------------
require('modules/module_utils')
require('scripts/globals/job_utils/warrior')
require('scripts/globals/job_utils/monk')
require('scripts/globals/job_utils/samurai')
require('scripts/globals/job_utils/ninja')
-----------------------------------
local m = Module:new('solo_story_job_rebalance')

local function enabled()
    local s = xi.settings.solo_story
    return s ~= nil and s.CATSEYE_JOBS == true
end

local function extendEffect(entity, effectId, seconds)
    local effect = entity and entity:getStatusEffect(effectId)
    if effect then
        effect:setDuration(seconds * 1000)
        effect:resetStartTime()
    end
end

-- { fonction, effet, durée (s), entité qui porte l'effet : 'player' ou 'target' }
local durations =
{
    { 'xi.job_utils.warrior.useRetaliation',  xi.effect.RETALIATION,   7200, 'player' },
    { 'xi.job_utils.monk.useCounterstance',   xi.effect.COUNTERSTANCE, 7200, 'target' },
    { 'xi.job_utils.samurai.useHasso',        xi.effect.HASSO,         7200, 'target' },
    { 'xi.job_utils.samurai.useSeigan',       xi.effect.SEIGAN,        7200, 'target' },
    { 'xi.job_utils.monk.useFocus',           xi.effect.FOCUS,           75, 'player' },
    { 'xi.job_utils.monk.useDodge',           xi.effect.DODGE,           75, 'player' },
    { 'xi.job_utils.monk.useFootwork',        xi.effect.FOOTWORK,       120, 'player' },
}

for _, row in ipairs(durations) do
    local target, effectId, seconds, holder = row[1], row[2], row[3], row[4]
    m:addOverride(target, function(player, abilityTarget, ability, ...)
        local result = super(player, abilityTarget, ability, ...)
        if enabled() then
            extendEffect(holder == 'player' and player or abilityTarget, effectId, seconds)
        end

        return result
    end)
end

-- Mijin Gakure : même calcul de dégâts que scripts/globals/job_utils/ninja.lua, mais le ninja reste à
-- 1 PV avec 3 ombres (Copy Image) au lieu de mourir.
m:addOverride('xi.job_utils.ninja.useMijinGakure', function(player, target, ability, action)
    if not enabled() then
        return super(player, target, ability, action)
    end

    local dmg        = math.floor(player:getHP() * 0.8)
    local resist     = xi.combat.magicHitRate.calculateResistRate(player, target, { actorStat = xi.mod.INT })
    local tmdaFactor = xi.combat.damage.calculateDamageAdjustment(target, false, true, false, false)
    local jpFactor   = 1 + player:getJobPointLevel(xi.jp.MIJIN_GAKURE_EFFECT) * 0.03

    dmg = math.floor(dmg * resist)
    dmg = math.floor(dmg * tmdaFactor)
    dmg = math.floor(dmg * jpFactor)
    dmg = utils.handleStoneskin(target, dmg, xi.attackType.SPECIAL)

    target:takeDamage(dmg, player, xi.attackType.SPECIAL, xi.damageType.ELEMENTAL)

    player:setHP(1)
    player:delStatusEffect(xi.effect.COPY_IMAGE)
    player:addStatusEffect(xi.effect.COPY_IMAGE, { power = 3, duration = 900, origin = player, subPower = 3, icon = xi.effect.COPY_IMAGE_3 })

    return dmg
end)
