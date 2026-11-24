-----------------------------------
-- solo_story : téléportations
-- 1) Débloque tous les home points (0..121) et survival guides (32 bits x 3 groupes) à la
--    connexion, une fois par personnage (charVar versionnée). Même logique que la commande GM
--    scripts/commands/addallwarps.lua, sans droits GM.
-- 2) Tarif des home points / survival guides divisé par 5, comme avec la KI Rhapsody in White
--    (RoV), sans donner la KI : les fonctions d'origine sont appelées avec un proxy du joueur
--    (entity_proxy.lua), donc le prix affiché dans le menu et le prix débité restent cohérents.
-- Les outposts sont gérés par settings/main.lua (UNLOCK_OUTPOST_WARPS).
-- Interrupteurs : settings/solo_story.lua (WARPS_UNLOCK_ALL, WARPS_DISCOUNT)
-----------------------------------
require('modules/module_utils')
require('scripts/globals/teleports')
local proxy = require('modules/solo_story/lua/entity_proxy')
-----------------------------------
local m = Module:new('solo_story_warps')

local UNLOCK_VAR     = '[solo_story]warpsUnlocked'
local UNLOCK_VERSION = 1 -- à incrémenter si la liste change, pour ré-appliquer aux persos existants

local function cfg(key)
    local s = xi.settings.solo_story
    return s ~= nil and s[key] == true
end

local function unlockAllWarps(player)
    for bitIndex = 0, 31 do
        for group = 0, 2 do
            player:addTeleport(xi.teleport.type.SURVIVAL, bitIndex, group)
        end
    end

    for i = 0, 121 do
        player:addTeleport(xi.teleport.type.HOMEPOINT, i % 32, math.floor(i / 32))
    end
end

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)

    if
        not zoning and
        cfg('WARPS_UNLOCK_ALL') and
        player:getCharVar(UNLOCK_VAR) < UNLOCK_VERSION
    then
        unlockAllWarps(player)
        player:setCharVar(UNLOCK_VAR, UNLOCK_VERSION)
        player:printToPlayer('Home points et survival guides débloqués.', xi.msg.channel.SYSTEM_3)
    end
end)

local function discounted(player)
    if cfg('WARPS_DISCOUNT') then
        return proxy.withKeyItems(player, { xi.keyItem.RHAPSODY_IN_WHITE })
    end

    return player
end

-- Le KI est testé à l'affichage (onTrigger) et au paiement (onEventFinish).
m:addOverride('xi.homepoint.onTrigger', function(player, csid, index)
    return super(discounted(player), csid, index)
end)

m:addOverride('xi.homepoint.onEventFinish', function(player, csid, option, event)
    return super(discounted(player), csid, option, event)
end)

m:addOverride('xi.survivalGuide.onTrigger', function(player)
    return super(discounted(player))
end)

m:addOverride('xi.survivalGuide.onEventFinish', function(player, eventId, option, npc)
    return super(discounted(player), eventId, option, npc)
end)
