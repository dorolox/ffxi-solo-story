-----------------------------------
-- solo_story : boutique de sorts
-- Un Moogle "Grimoire" près du home point n°1 de Lower Jeuno et des 3 capitales.
-- Il vend les parchemins des sorts que le job principal OU le sous-job peut apprendre à son
-- niveau actuel, sauf ceux déjà connus. Paiement en gil (boutique standard du jeu, 254 max).
-- Données (parchemin -> sort, niveaux par job, prix) : spell_shop_data.lua, généré par
-- modules/solo_story/tools/gen_spell_shop.py (prix des marchands PNJ, sinon prix AH).
-- NB : les sorts Addendum du SCH s'apprennent avec Addendum actif (règle LSB de canLearnSpell).
-- Interrupteur : settings/solo_story.lua (SPELL_SHOP)
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Lower_Jeuno/Zone')
require('scripts/zones/Southern_San_dOria/Zone')
require('scripts/zones/Bastok_Mines/Zone')
require('scripts/zones/Windurst_Woods/Zone')
local spellShopData = require('modules/solo_story/lua/spell_shop_data')
-----------------------------------
local m = Module:new('solo_story_spell_shop')

local MAX_SHOP_ITEMS = 254 -- createShop(uint8 size) avec un emplacement réservé
local NPC_LOOK       = 82  -- Moogle (docs/model_ids.txt)

local function enabled()
    local s = xi.settings.solo_story
    return s ~= nil and s.SPELL_SHOP == true
end

local function learnLevel(entry, job, jobLevel)
    local required = job and job > 0 and entry.jobs[job]
    if required and required <= jobLevel then
        return required
    end

    return nil
end

-- Exposé pour les tests.
xi.soloStory = xi.soloStory or {}
xi.soloStory.buildSpellShopStock = function(player)
    local mainJob, mainLvl = player:getMainJob(), player:getMainLvl()
    local subJob, subLvl   = player:getSubJob(), player:getSubLvl()
    local candidates       = {}

    for _, entry in ipairs(spellShopData) do
        local level = learnLevel(entry, mainJob, mainLvl) or learnLevel(entry, subJob, subLvl)
        if level and not player:hasSpell(entry.spell) then
            table.insert(candidates, { entry = entry, level = level })
        end
    end

    table.sort(candidates, function(a, b)
        if a.level ~= b.level then
            return a.level < b.level
        end

        return a.entry.item < b.entry.item
    end)

    local stock = {}
    for i = 1, math.min(#candidates, MAX_SHOP_ITEMS) do
        table.insert(stock, { candidates[i].entry.item, candidates[i].entry.price })
    end

    return stock, #candidates
end

local function onTrigger(player, npc)
    if not enabled() then
        return
    end

    local stock, total = xi.soloStory.buildSpellShopStock(player)
    if #stock == 0 then
        player:printToPlayer('Grimoire : je n\'ai aucun sort que tu puisses apprendre pour l\'instant, kupo !', xi.msg.channel.NS_SAY, npc:getPacketName())
        return
    end

    if total > #stock then
        player:printToPlayer(string.format('Grimoire : %d sorts disponibles, voici les %d premiers.', total, #stock), xi.msg.channel.SYSTEM_3)
    end

    xi.shop.general(player, stock)
end

-- Position : près du home point n°1 (scripts/globals/homepoint.lua), décalé pour ne pas le recouvrir.
local placements =
{
    { zone = 'Lower_Jeuno',        x =  -97.0, y = 0, z = -183.0, rot =   0 },
    { zone = 'Southern_San_dOria', x =  -83.5, y = 1, z =  -64.5, rot =  45 },
    { zone = 'Bastok_Mines',       x =   41.0, y = 0, z =  -43.0, rot =   0 },
    { zone = 'Windurst_Woods',     x =   11.0, y = -2, z =    0.0, rot =   0 },
}

for _, place in ipairs(placements) do
    m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', place.zone), function(zone)
        super(zone)

        if not enabled() then
            return
        end

        zone:insertDynamicEntity({
            objtype    = xi.objType.NPC,
            name       = 'Grimoire',
            packetName = 'Grimoire',
            look       = NPC_LOOK,
            x          = place.x,
            y          = place.y,
            z          = place.z,
            rotation   = place.rot,
            widescan   = 1,
            onTrigger  = onTrigger,
        })
    end)
end
