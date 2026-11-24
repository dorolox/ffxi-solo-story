-----------------------------------
-- solo_story : rangements débloqués (une fois par personnage, à la connexion, charVar versionnée)
--  - Mog Safe (et Safe 2, même taille côté cœur) 50 -> 80, Mog Sack 0 -> 80, Mog Locker 0 -> 80
--  - Mog Locker : location "toutes zones" jusqu'à l'expiration max (INT32), sans pièces de bronze
--  - Mog House 2F (Mog Safe 2) : flags des 3 quêtes de sortie de Mog House + flag 2F (0x20),
--    style du 2e étage = nation du joueur (bits 0x80/0x100, scripts/globals/moghouse.lua)
-- Inventaire, Satchel, Case et Wardrobes 1-8 sont déjà à 80 (settings + défauts de char_storage).
-- Le Storage reste lié aux meubles posés dans la Mog House (règle retail, C++).
-- Interrupteur : settings/solo_story.lua (STORAGE_UNLOCK_ALL)
-----------------------------------
require('modules/module_utils')
require('scripts/globals/moghouse')
-----------------------------------
local m = Module:new('solo_story_storage_unlock')

local UNLOCK_VAR     = '[solo_story]storageUnlocked'
local UNLOCK_VERSION = 1
local MAX_SIZE       = 80
local INT32_MAX      = 2147483647

local function growTo(player, location, size)
    local delta = size - player:getContainerSize(location)
    if delta > 0 then
        player:changeContainerSize(location, delta)
    end

    return delta
end

local function unlockStorage(player)
    local safeDelta = growTo(player, xi.inv.MOGSAFE, MAX_SIZE)
    if safeDelta > 0 then
        -- Safe 2 prend la taille du Safe au chargement ; on l'aligne aussi pour la session en cours.
        player:changeContainerSize(xi.inv.MOGSAFE2, safeDelta)
    end

    growTo(player, xi.inv.MOGSACK, MAX_SIZE)
    growTo(player, xi.inv.MOGLOCKER, MAX_SIZE)

    xi.moghouse.setMogLockerAccessType(player, xi.moghouse.lockerAccessType.ALLAREAS)
    player:setCharVar('mog-locker-expiry-timestamp', INT32_MAX)
    player:changeContainerSize(xi.inv.MOGLOCKER, 0) -- renvoie les tailles au client

    -- Quêtes de sortie de Mog House (0x01 0x02 0x04) + 2e étage débloqué (0x20), style = nation.
    local flag  = bit.bor(player:getMoghouseFlag(), 0x0001, 0x0002, 0x0004, 0x0020)
    local style = player:getNation()
    flag = bit.band(flag, bit.bnot(0x0180))
    flag = bit.bor(flag, bit.lshift(bit.band(style, 0x3), 7))
    player:setMoghouseFlag(flag)
end

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)

    local s = xi.settings.solo_story
    if
        not zoning and
        s ~= nil and s.STORAGE_UNLOCK_ALL == true and
        player:getCharVar(UNLOCK_VAR) < UNLOCK_VERSION
    then
        unlockStorage(player)
        player:setCharVar(UNLOCK_VAR, UNLOCK_VERSION)
        player:printToPlayer('Mog Safe, Safe 2, Sack et Locker débloqués (80 places).', xi.msg.channel.SYSTEM_3)
    end
end)
