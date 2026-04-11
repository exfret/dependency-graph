local state = require("lib.logic.state")

local set_class = state.set_class
local set_prot = state.set_prot
local add_node = state.add_node
local add_edge = state.add_edge
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
                add_edge("turret-has-ammo-category", "entity-operate", source.name)
            elseif source.type == "gun" then
                add_edge("gun-has-ammo-category", "item-gun", source.name, {
                    context = { ["automated"] = false },
                })
            end
        end
    end

----------------------------------------------------------------------------------------------------
-- Asteroid chunk
----------------------------------------------------------------------------------------------------

    --[[set_class("asteroid-chunk")

    for _, chunk in pairs(prots("asteroid-chunk")) do
        set_prot(chunk)

        ----------------------------------------
        add_node("asteroid-chunk", "OR")
        ----------------------------------------
        -- Can we encounter this asteroid chunk?

        -- Edges from locations where this chunk spawns naturally
        if lu.asteroid_to_place[key("asteroid-chunk", chunk.name)] ~= nil then
            for _, place in pairs(lu.asteroid_to_place[key("asteroid-chunk", chunk.name)]) do
                add_edge("space-place-spawns-chunk", place.type, place.name)
            end
        end
        -- Edges from entities that spawn this chunk when dying
        for _, source in pairs(tablize(lu.dying_spawns_reverse[key("asteroid-chunk", chunk.name)])) do
            if source.type == "entity" then
                add_edge("dying-spawns-create-chunk", "entity-kill", source.name)
            end
        end

        ----------------------------------------
        add_node("asteroid-chunk-mine", "AND")
        ----------------------------------------
        -- Can we mine this asteroid chunk?

        -- Asteroid chunks can always be mined automatically
        add_edge("chunk-to-mine", "asteroid-chunk", chunk.name, {
            context = { ["automated"] = true },
        })
        add_edge("asteroid-collector-for-mining", "asteroid-collector", "")
    end]]
end

return concrete