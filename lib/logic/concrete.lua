local state = require("lib.logic.state")

local set_class = state.set_class
local set_prot = state.set_prot
local add_node = state.add_node
local add_edge = state.add_edge

local collision_mask_util = require("__core__.lualib.collision-mask-util")
local categories = DataRawLib.categories
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
        for place_name, _ in pairs(tablize(lu.asteroid_to_places[key("asteroid-chunk", chunk.name)])) do
            local place = lu.space_places[place_name]
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
        -- Edges for other sources
        for _, source_info in pairs(tablize(lu.damage_type_to_sources[damage.name])) do
            add_edge(source_info.start_type, source_info.start_name, {
                desc = source_info.edge_desc,
            })
        end
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
        local placeables = lu.placeables[entity.name]
        if placeables ~= nil then
            add_edge("entity-place")
        end
        local plantables = lu.plantables[entity.name]
        if plantables ~= nil then
            add_edge("entity-plant")
        end
        for planet_name, _ in pairs(tablize(lu.autoplaceable_to_planet[key("entity", entity.name)])) do
            add_edge("room", key("room", planet_name), {
                entity = entity.name,
                context = { ["isolated"] = true },
            })
        end
        for entity_with_corpse_name, _ in pairs(tablize(lu.entities_with_corpse[entity.name])) do
            add_edge("entity-kill", entity_with_corpse_name)
        end
        for spawner_name, _ in pairs(tablize(lu.spawners_with_capture_result[entity.name])) do
            add_edge("entity-capture-spawner", spawner_name)
        end
        -- TODO: Trigger creations, primarily ammo spawns, dying spawns, and capsules
        -- Asteroid spawning
        for place_name, _ in pairs(tablize(lu.asteroid_to_places[key("entity", entity.name)])) do
            local place = lu.space_places[place_name]
            add_edge(place.type, place.name)
        end
        -- Starting character
        if entity.type == "character" and entity.name == "character" then
            add_edge("starting-character", "")
        end

        if placeables ~= nil then
            ----------------------------------------
            add_node("entity-place", "AND")
            ----------------------------------------
            -- Can we place this entity using an item?
            -- Does not include planting entities by agricultural towers

            add_edge("entity-place-item")
            add_edge("entity-build-tile")
            -- TODO
            --local build_room_restrictions = lu.build_room_restrictions[entity.name]
            if build_room_restrictions ~= nil then
                add_edge("entity-build-surface-condition")
            end
            if categories.rolling_stock[entity.type] then
                add_edge("entity-build-rail")
            end

            ----------------------------------------
            add_node("entity-place-item", "OR")
            ----------------------------------------
            -- Can we get an item needed to place this entity?
            
            for item_name, _ in pairs(placeables) do
                add_edge("item", item_name)
            end
        end
        if plantables ~= nil then
            ----------------------------------------
            add_node("entity-plant", "AND")
            ----------------------------------------
            -- Can we plant this entity using an item and an agricultural tower?
            -- Entities that can be planted are counted as being built, though later during randomization we might have to condition on it being a planted or built entity

            add_edge("entity-plant-item")
            add_edge("entity-build-tile")
            --local build_room_restrictions = lu.build_room_restrictions[entity.name]
            if build_room_restrictions ~= nil then
                add_edge("entity-build-surface-condition")
            end
            -- No need to check for rolling stock because only plants can be planted

            ----------------------------------------
            add_node("entity-plant-item", "OR")
            ----------------------------------------
            -- Can we get an item needed to plant this entity?
            
            for item_name, _ in pairs(plantables) do
                add_edge("item", item_name)
            end
        end
        if plantables ~= nil or placeables ~= nil then
            ----------------------------------------
            add_node("entity-build-tile", "OR")
            ----------------------------------------
            -- Can we access a tile on which the entity can be built? (i.e., no collision)

            -- For optimization, we precompute possible tile collision masks and make a tile-collision node for each group, then simply have this depend on the right groups
            -- If there's a restriction, this gets more complicated, so just depend on the individual tiles (note that this overrides collision masks)
            if not (entity.autoplace ~= nil and entity.autoplace.tile_restriction ~= nil) then
                -- TODO
                --add_edge("entity-collision-group", lu.entity_to_collision_group[entity.name])
            else
                -- This is luckily an OR over tiles and transitions
                for _, restriction in pairs(entity.autoplace.tile_restriction) do
                    -- Ignore transition restrictions (those could play a role but only in mods that force buildings to be on specific transitions)
                    -- Still check collision in case a mod does something dumb since that's easy
                    if type(restriction) == "string" and not collision_mask_util.masks_collide(data.raw.tile[restriction].collision_mask, entity.collision_mask or collision_mask_util.get_default_mask(entity.type)) then
                        add_edge("tile", restriction)
                    end
                end
            end
        end
    end
end

return concrete