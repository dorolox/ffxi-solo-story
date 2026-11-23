-----------------------------------
-- solo_story : régénération au repos (/heal) accélérée
-- Ajoute REST_REGEN_PERCENT % des PV/PM max à chaque tick de HEALING, en plus du calcul
-- retail de scripts/effects/healing.lua (qui reste appelé via super).
-- Mêmes blocages que le retail : pas de bonus au 1er tick, ni sous Disease/Plague/Curse II,
-- ni si le repos a été annulé (avatar/esprit invoqué).
-- L'intervalle entre ticks se règle dans settings/map.lua (HEALING_TICK_DELAY).
-- Interrupteur : settings/solo_story.lua (REST_REGEN_PERCENT, 0 = désactivé)
-----------------------------------
require('modules/module_utils')
-----------------------------------
local m = Module:new('solo_story_rest_regen')

m:addOverride('xi.effects.healing.onEffectTick', function(target, effect)
    super(target, effect)

    local s       = xi.settings.solo_story
    local percent = s and s.REST_REGEN_PERCENT or 0
    if
        percent <= 0 or
        not target:isPC() or
        effect:getTickCount() <= 1 or
        not target:hasStatusEffect(xi.effect.HEALING) or
        target:hasStatusEffect(xi.effect.DISEASE) or
        target:hasStatusEffect(xi.effect.PLAGUE) or
        target:hasStatusEffect(xi.effect.CURSE_II)
    then
        return
    end

    local bonusHP = math.floor(target:getMaxHP() * percent / 100)
    local bonusMP = math.floor(target:getMaxMP() * percent / 100)

    if bonusHP > 0 then
        target:addHPLeaveSleeping(bonusHP)
    end

    if bonusMP > 0 then
        target:addMP(bonusMP)
    end
end)
