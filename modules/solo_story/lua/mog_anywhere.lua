-----------------------------------
-- solo_story : commande !mog (sans droits GM) qui ouvre le menu du Moogle partout.
-- Le menu n'est réellement utilisable que dans les zones qui ont `mogmenu` : les correctifs
-- modules/solo_story/data/zones/*/zone.yaml l'ajoutent à toutes les zones (voir
-- tools/gen_mogmenu_patches.py). Le Storage reste réservé à ta propre Mog House (règle du cœur).
-- Interrupteur : settings/solo_story.lua (MOG_ANYWHERE)
-----------------------------------
require('modules/module_utils')
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0, -- tous les joueurs (command_handler.cpp : permission > m_GMlevel refusé)
    parameters = '',
}

commandObj.onTrigger = function(player)
    local s = xi.settings.solo_story
    if s == nil or s.MOG_ANYWHERE ~= true then
        player:printToPlayer('La commande !mog est désactivée.', xi.msg.channel.SYSTEM_3)
        return
    end

    if not player:canUseMisc(xi.zoneMisc.MOGMENU) then
        player:printToPlayer('Pas de menu du Moogle dans cette zone.', xi.msg.channel.SYSTEM_3)
        return
    end

    player:sendMenu(xi.menuType.MOOGLE)
end

xi.module.registerCommand('mog', commandObj)
