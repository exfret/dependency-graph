local state = require("lib.logic.state")

local set_class = state.set_class
local set_prot = state.set_prot
local add_node = state.add_node
local add_edge = state.add_edge
local key = DataRawLib.key.key
local base_prots = DataRawLib.traversal.base_prots
local prots = DataRawLib.traversal.prots
local tablize = DataRawLib.traversal.tablize

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
                    context = { ["automated"] = false },
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
        for _, place in pairs(lu.asteroid_to_places[key("asteroid-chunk", chunk.name)]) do
            add_edge(place.type, place.name)
        end
        -- Edges from entities that spawn this chunk when dying
        -- TODO: Implement after I figure out triggers situation better
        --[[for _, source in pairs(tablize(lu.dying_spawns_reverse[key("asteroid-chunk", chunk.name)])) do
            if source.type == "entity" then
                add_edge("entity-kill", source.name)
            end
        end]]

        ----------------------------------------
        add_node("asteroid-chunk-mine", "AND")
        ----------------------------------------
        -- Can we mine this asteroid chunk?

        -- Asteroid chunks can always be mined automatically
        add_edge("asteroid-chunk", chunk.name, {
            context = { ["automated"] = true },
        })
        add_edge("asteroid-collector", "")
    end

    ----------------------------------------------------------------------
    -- Damage Type
    ----------------------------------------------------------------------

    -- TODO

    ----------------------------------------------------------------------
    -- Entity
    ----------------------------------------------------------------------

    --[[set_class("entity")

    for _, entity in pairs(base_prots("entity")) do
        set_prot(entity)

        ----------------------------------------
        add_node("entity", "OR")
        ----------------------------------------
        -- Can we encounter this entity?

        -- TODO: Should having to build an entity turn off automated?
        -- TODO: Maybe think more about automated along with the other ones more. 
        -- TODO: Only add entity-build if the entity is buildable (or when optimization is turned off in settings)
        add_edge("entity-build")
        for room_key, _ in pairs(tablize(lu.rooms_spawning_entity[entity.name])) do
            -- Technically, we should check that there are non-colliding tiles too, but it would be very silly to have an entity in autoplace that can't be placed somewhere
            add_edge("room-autoplace", room_key, {
                entity = entity.name,
                abilities = { ["automated"] = true },
            }) -- Being directly from a room leads to isolated
        end
        for other_entity_name, _ in pairs(tablize(lu.entities_with_corpse[entity.name])) do
            add_edge("entity-kill", other_entity_name)
        end
    end]]
end

return concrete