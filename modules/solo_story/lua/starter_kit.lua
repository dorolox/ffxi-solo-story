-----------------------------------
-- solo_story : kit de départ à la création du perso
-- Surcharge xi.player.charCreate (scripts/globals/player.lua), appelée par
-- xi.player.onGameIn au tout premier login du personnage.
-- Interrupteurs : settings/solo_story.lua
-----------------------------------
require('modules/module_utils')
-----------------------------------
local m = Module:new('solo_story_starter_kit')

local function cfg(key)
    local s = xi.settings.solo_story
    return s ~= nil and s[key] == true
end

-- Équivalent des 3 quêtes de permis (The Trustworthy / Clarion Star / Wetata) :
-- chacune donne son permis et un Trust. Les Trusts suivants (Ayame, Curilla...)
-- restent à obtenir normalement.
local function giveStarterTrusts(player)
    player:addKeyItem(xi.keyItem.SAN_DORIA_TRUST_PERMIT)
    player:addKeyItem(xi.keyItem.BASTOK_TRUST_PERMIT)
    player:addKeyItem(xi.keyItem.WINDURST_TRUST_PERMIT)

    for _, spellId in ipairs({ xi.magic.spell.EXCENMILLE, xi.magic.spell.NAJI, xi.magic.spell.KUPIPI }) do
        player:addSpell(spellId, { silentLog = true })
    end
end

-- Équivalent de la récompense de Full Speed Ahead! (Mapitoto, Upper Jeuno).
-- Le niveau 20 reste exigé par le cœur (0x01a_action.cpp) pour monter.
local function giveStarterMount(player)
    player:addQuest(xi.questLog.JEUNO, xi.quest.id.jeuno.FULL_SPEED_AHEAD)
    player:completeQuest(xi.questLog.JEUNO, xi.quest.id.jeuno.FULL_SPEED_AHEAD)
    player:addKeyItem(xi.keyItem.TRAINERS_WHISTLE)
    player:addKeyItem(xi.keyItem.RAPTOR_COMPANION)
end

m:addOverride('xi.player.charCreate', function(player)
    super(player)

    if cfg('STARTER_TRUSTS') then
        giveStarterTrusts(player)
    end

    if cfg('STARTER_MOUNT') then
        giveStarterMount(player)
    end
end)
