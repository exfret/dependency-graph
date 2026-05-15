local state = require("lib.logic.state")

local set_class = state.set_class
local set_prot = state.set_prot
local add_node = state.add_node
local add_edge = state.add_edge

local collision_mask_util = require("__core__.lualib.collision-mask-util")
local categories = DataRawLib.categories
local cat_sigs = DataRawLib.cat_sigs
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
        local placeables = lu.placeables[entity.name]
        if placeables ~= nil then
            add_edge("entity-place")
        end
        local plantables = lu.plantables[entity.name]
        if plantables ~= nil then
            add_edge("entity-plant")
        end
        -- Doesn't check for a tile where the entity can actually be placed, so if an entity has an autoplace for a planet but can't be placed there, this check will give a false positive
        -- However, I hope the cases where a mod defines something as autoplaceable but it's not actually placeable will be rare
        for planet_name, _ in pairs(tablize(lu.autoplaceable_to_planets[key("entity", entity.name)])) do
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
        -- Edges from triggers that spawn this entity
        -- Doesn't check special things like tile buildability, collision checks, etc. that might prevent the entity from actually appearing
        local stop = key("entity", entity.name)
        for struct_ind, _ in pairs(tablize(lu.stop_to_triggers[stop])) do
            local struct = lu.triggers[struct_ind]
            add_edge(struct.start_type, struct.start_name, {
                desc = struct.edge_desc,
            })
        end

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
            local build_room_restrictions = lu.build_room_restrictions[entity.name]
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
            local build_room_restrictions = lu.build_room_restrictions[entity.name]
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

            -- For optimization, we precompute all occurring collision masks and make a collision-group node for each group, then simply have this node depend on the right tiles (which helps because collision masks are often repeated)
            -- If there's a tile restriction or tile buildability rules (in which case buildability_tiles ~= nil), this gets more complicated, so just depend on the individual tiles (which are found during lookup construction)
            local buildability_tiles = lu.entity_buildability_tiles[entity.name]
            if buildability_tiles == nil then
                add_edge("collision-group", lu.entity_to_collision_group[entity.name])
            else
                for tile_name, _ in pairs(buildability_tiles) do
                    add_edge("tile", tile_name)
                end
            end

            if build_room_restrictions ~= nil then
                ----------------------------------------
                add_node("entity-build-surface-condition", "OR")
                ----------------------------------------
                -- Can we access a room with the right surface conditions for this entity?

                for room_key, _ in pairs(build_room_restrictions) do
                    add_edge("room", room_key)
                end
            end

            if categories.rolling_stock[entity.type] then
                ----------------------------------------
                add_node("entity-build-rail", "OR")
                ----------------------------------------
                -- Can we build a rail to put this rolling stock on?

                -- If it's a rolling stock (locomotive/cargo wagon/etc.), check that we can build some rail that it does not collide with
                -- Technically, we should test that the rail also shares a tile with the locomotive that both can be placed on, but also I could have a life and I think I'd take the latter
                -- TODO: Maybe do a grouping of rails/rolling stock collision masks for efficiency
                for rail_class, _ in pairs(categories.rail) do
                    for _, rail in pairs(prots(rail_class)) do
                        if not collision_mask_util.masks_collide(entity.collision_mask or collision_mask_util.get_default_mask(entity.type), rail.collision_mask or collision_mask_util.get_default_mask(rail.type)) then
                            add_edge("entity", rail.name)
                        end
                    end
                end
            end
        end

        -- TODO: Only build entity-operate nodes for entities deemed operable
        -- I'm just playing it safe for now due to past issues with assumptions on what could be operated
        ----------------------------------------
        add_node("entity-operate", "AND")
        ----------------------------------------
        -- Can we operate this entity (ensure it's heated, powered, etc.)?

        add_edge("entity", entity.name, {
            abilities = { [2] = true } -- Automatic operation doesn't require automatic production
        })
        if categories.energy_sources_input[entity.type] then
            add_edge("entity-operate-energy")
        end
        if categories.fluid_required[entity.type] then
            add_edge("entity-operate-fluid")
        end
        -- Thrusters need two specific fluids (AND), not a generic "OR" fluid requirement
        if entity.type == "thruster" then
            add_edge("fluid", entity.fuel_fluid_box.filter)
            add_edge("fluid", entity.oxidizer_fluid_box.filter)
        end
        -- CRITICAL TODO: Freezability check code
        --[[if lutils.check_freezable(entity) then
            add_edge("warmth", "")
        end]]
        if lu.py_operability_module_cats[entity.name] ~= nil then
            add_edge("entity-operate-py-module")
        end
        -- Note: Ammo turrets are "operable" without ammo; since the damage is on the ammo, we actually need to check if there is a turret to shoot an ammo rather than check if there is ammo for a turret to shoot

        if categories.energy_sources_input[entity.type] ~= nil then
            ----------------------------------------
            add_node("entity-operate-energy", "AND")
            ----------------------------------------
            -- Can we power this entity?

            -- Note: Entities still depend on "void" energy source even if their energy_source is nil so that randomization is still possible later
            -- The energy source nodes are generic/entity independent, but burner energy sources that have different fuel_categories are counted as distinct
            -- TODO: Later, also distinguish fluid energy sources based off fluid box filters/whether they burn fluid, and heat energy sources based on min/max heat etc., but for now just having one of each is fine
            local burner_energy_source
            local fluid_energy_source
            for _, energy_prop in pairs(tablize(categories.energy_sources_input[entity.type])) do
                local energy_source = entity[energy_prop]
                if energy_source == nil or energy_source.type == "void" then
                    add_edge("energy-source-void", "")
                elseif energy_source.type == "burner" then
                    -- There can only be one burner energy source
                    burner_energy_source = energy_source
                    add_edge("entity-burner-fuel")
                elseif energy_source.type == "electric" then
                    add_edge("energy-source-electric", "")
                elseif energy_source.type == "fluid" then
                    -- There can only be one fluid energy source
                    fluid_energy_source = energy_source
                    add_edge("entity-fluid-fuel")
                elseif energy_source.type == "heat" then
                    add_edge("energy-source-heat", "")
                end
            end

            if burner_energy_source ~= nil then
                ----------------------------------------
                add_node("entity-burner-fuel", "OR")
                ----------------------------------------
                -- Can we provide this entity with (solid) fuel needed to power it?

                for _, fuel_category in pairs(burner_energy_source.fuel_categories or {"chemical"}) do
                    add_edge("fuel-category", cat_sigs.fcat_name(fuel_category, burner_energy_source.burnt_inventory_size))
                end
            end
            if fluid_energy_source ~= nil then
                ----------------------------------------
                add_node("entity-fluid-fuel", "OR")
                ----------------------------------------
                -- Can we provide this entity with fluid fuel needed to power it?

                local fluids_to_check = prots("fluid")
                if fluid_energy_source.fluid_box.filter ~= nil then
                    fluids_to_check = {fluids_to_check[fluid_energy_source.fluid_box.filter]}
                end

                if fluid_energy_source.burns_fluid == true then
                    for _, fluid in pairs(fluids_to_check) do
                        if fluid.fuel_value ~= nil and util.parse_energy(fluid.fuel_value) > 0 then
                            add_edge("fluid", fluid.name)
                        end
                    end
                else
                    -- CRITICAL TODO: Temperature based logic!
                end
            end
        end
    end
end

return concrete