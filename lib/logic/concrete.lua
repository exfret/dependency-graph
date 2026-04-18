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
        for _, place in pairs(tablize(lu.asteroid_to_places[key("asteroid-chunk", chunk.name)])) do
            add_edge(place.type, place.name)
        end
        -- Edges from triggers that spawn this entity
        -- Includes dying spawns
        local stop = key("asteroid-chunk", chunk.name)
        for struct_ind, _ in pairs(tablize(lu.stop_to_triggers[stop])) do
            local struct = lu.triggers[struct_ind]
            add_edge(struct.start_type, struct.start_name, {
                desc = struct.edge_desc,
            })
        end

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

    set_class("damage-type")

    for _, damage in pairs(prots("damage-type")) do
        set_prot(damage)

        ----------------------------------------
        add_node("damage-type", "OR")
        ----------------------------------------
        -- Can we deal damage of this type?

        -- Edges from triggers to damage dealt of this type
        local stop = key("damage-type", damage.name)
        for struct_ind, _ in pairs(tablize(lu.stop_to_triggers[stop])) do
            local struct = lu.triggers[struct_ind]
            add_edge(struct.start_type, struct.start_name, {
                desc = struct.edge_desc,
            })
        end
        -- TODO: Impact damage
    end

    ----------------------------------------------------------------------
    -- Entity
    ----------------------------------------------------------------------

    set_class("entity")

    for _, entity in pairs(base_prots("entity")) do
        set_prot(entity)

        ----------------------------------------
        add_node("entity", "OR")
        ----------------------------------------
        -- Can we encounter this entity?

        -- TODO: Should having to build an entity turn off automated?
        -- TODO: Maybe think more about automated along with the other ones more. 
        -- TODO: Only add entity-build if the entity is buildable (or when optimization is turned off in settings)
        --[[local buildables = lu.buildables[key(entity)]
        if buildables ~= nil then
            add_edge("entity-build")
        end]]
        -- TODO: Autoplace
        --[[for room_key, _ in pairs(tablize(lu.autoplaceable_to_rooms[entity.name])) do
            -- Technically, we should check that there are non-colliding tiles too, but it would be very silly to have an entity in autoplace that can't be placed somewhere
            add_edge("room", room_key, {
                entity = entity.name,
                abilities = { ["isolated"] = true },
            })
        end]]
        for entity_with_corpse_name, _ in pairs(tablize(lu.entities_with_corpse[entity.name])) do
            add_edge("entity-kill", entity_with_corpse_name)
        end
        for spawner_name, _ in pairs(tablize(lu.spawners_with_capture_result[entity.name])) do
            add_edge("entity-capture-spawner", spawner_name)
        end
        -- TODO: Trigger creations, primarily ammo spawns, dying spawns, and capsules
        -- Asteroid spawning
        for _, place in pairs(tablize(lu.asteroid_to_places[key("entity", entity.name)])) do
            add_edge(place.type, place.name)
        end
        -- Starting character
        if entity.type == "character" and entity.name == "character" then
            add_edge("starting-character", "")
        end

        --[[if buildables ~= nil then
            ----------------------------------------
            add_node("entity-build", "AND")
            ----------------------------------------
            -- Can we build this entity using an item?
            -- Entities that can be planted are counted as being built, though later during randomization we might have to condition on it being a planted or built entity

            add_edge("entity-build-item")
            add_edge("entity-build-tile")
            local build_room_restrictions = lu.build_room_restrictions[entity.name]
            if build_room_restrictions ~= nil then
                add_edge("entity-build-surface-condition")
            end
            if categories.rolling_stock[entity.type] then
                add_edge("entity-build-rail")
            end

            ----------------------------------------
            add_node("entity-build-item", "OR")
            ----------------------------------------
            -- Can we get an item needed to build this entity?
            -- TODO
        end]]
    end
end

return concrete