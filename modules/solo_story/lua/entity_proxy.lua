-----------------------------------
-- solo_story : utilitaire partagé (pas de Module ici -> chargé comme fichier d'appui)
-- Proxy d'une entité joueur qui répond "possédée" pour certaines key items, sans les donner.
-- Toutes les autres méthodes sont transmises à la vraie entité.
-- Limite : le proxy ne peut pas être passé en argument à une fonction C++ (seulement des appels de méthode).
-----------------------------------
local M = {}

function M.withKeyItems(entity, keyItems)
    local granted = {}
    for _, ki in ipairs(keyItems) do
        granted[ki] = true
    end

    return setmetatable({}, {
        __index = function(_, key)
            if key == 'hasKeyItem' then
                return function(_, keyItem)
                    return granted[keyItem] == true or entity:hasKeyItem(keyItem)
                end
            end

            local value = entity[key]
            if type(value) == 'function' then
                return function(_, ...)
                    return value(entity, ...)
                end
            end

            return value
        end,
    })
end

return M
