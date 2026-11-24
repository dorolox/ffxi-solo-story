-----------------------------------
-- solo_story : utilitaire partagé (pas de Module ici -> chargé comme fichier d'appui)
-- Proxy d'une entité : certaines méthodes sont remplacées, toutes les autres sont transmises
-- à la vraie entité. Sert à appeler une fonction d'origine de LSB en lui faisant "voir" un état
-- différent (KI possédée, pas de battlefield...) sans modifier le personnage.
-- Limite : le proxy ne peut pas être passé en argument à une fonction C++ (seulement des appels de méthode).
-----------------------------------
local M = {}

-- overrides : { nomMethode = function(entity, ...) ... end }
function M.wrap(entity, overrides)
    return setmetatable({}, {
        __index = function(_, key)
            local override = overrides[key]
            if override then
                return function(_, ...)
                    return override(entity, ...)
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

-- Répond "possédée" pour ces key items, sans les donner.
function M.withKeyItems(entity, keyItems)
    local granted = {}
    for _, ki in ipairs(keyItems) do
        granted[ki] = true
    end

    return M.wrap(entity, {
        hasKeyItem = function(real, keyItem)
            return granted[keyItem] == true or real:hasKeyItem(keyItem)
        end,
    })
end

return M
