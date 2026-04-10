local contexts = require("lib.contexts.init")

local isolated = contexts.abilities.isolated
local automated = contexts.abilities.automated
local key = DataRawLib.key.key
local prots = DataRawLib.traversal.prots

local concrete = {}

concrete.build = function()
----------------------------------------------------------------------------------------------------
-- Ammo Category
----------------------------------------------------------------------------------------------------

    set_class("ammo-category")

    for _, cat in pairs(prots("ammo-category")) do
        set_prot(cat)

        ----------------------------------------
        add_node("ammo-category", "OR")
        ----------------------------------------
        -- Can we use ammo of this ammo_category in some ammo turret or gun?
        
        for _, source in pairs(lu.ammo_category_sources) do
            if source.type == "turret" then
                add_edge("entity-operate", source.name)
            elseif source.type == "gun" then
                add_edge("item-gun", source.name, {
                    abilities = { [automated] = false },
                })
            end
        end
    end

----------------------------------------------------------------------------------------------------
-- Asteroid chunk
----------------------------------------------------------------------------------------------------

    set_class("asteroid-chunk")

    for _, chunk in pairs(prots("asteroid-chunk")) do
        set_prot(chunk)

        ----------------------------------------
        add_node("asteroid-chunk", "OR")
        ----------------------------------------
        -- Can we encounter this asteroid chunk?

        -- Edges from locations where this chunk spawns naturally
        if lu.asteroid_to_place[key("asteroid-chunk", chunk.name)] ~= nil then
            for _, place in pairs(lu.asteroid_to_place[key("asteroid-chunk", chunk.name)]) do
                add_edge(place.type, place.name)
            end
        end
        -- Edges from entities that spawn this chunk when dying
        for _, source in pairs(tablize(lu.dying_spawns_reverse[key("asteroid-chunk", chunk.name)])) do
            if source.type == "entity" then
                add_edge("entity-kill", source.name)
            end
        end

        ----------------------------------------
        add_node("asteroid-chunk-mine", "AND")
        ----------------------------------------
        -- Can we mine this asteroid chunk?

        -- Asteroid chunks can always be mined automatically
        add_edge("asteroid-chunk", chunk.name, {
            abilities = { [automated] = true },
        })
        add_edge("asteroid-collector", "")
    end

end

return concrete