-- This file keeps state while building the graph to make the building process easier
-- Also has the responsibility of actually adding the nodes etc.

local gutils = DepGraph.gutils
local key = DataRawLib.key.key

local state = {}

local graph

local curr
local curr_class
local curr_prot

state.init = function(logic_graph)
    graph = logic_graph

    curr = nil
    curr_class = nil
    curr_prot = nil
end

state.set_class = function(class_name)
    curr_class = class_name
end

state.set_prot = function(prot)
    curr_prot = prot
end

-- node_name can be nil, in which case we try to use curr_prot.name
-- extra can contain the following keys:
--  * canonical: either a table {type = node_type, name = node_name} for the "canonical" node for a given one, or a single string for type if name is shared
--  * context: true (signalling a "forgetter" that transmits all contexts), a string (signalling a "setter" that transmits a specific context), or a table (if I need more versatility later)
--  * mechanic: true if this node represents a fundamental game mechanic (usually something that can't be randomized, like the edge from electric energy distribution to electric energy)
-- It can also have overrides for class or prot
state.add_node = function(node_type, op, node_name, extra)
    node_name = node_name or curr_prot.name
    assert(node_name ~= nil)

    extra = extra or {}
    extra.class = extra.class or curr_class
    if extra.prot == nil and curr_prot ~= nil then
        extra.prot = key(curr_prot)
    end
    extra.canonical = extra.canonical or curr_class

    curr = gutils.add_node(graph, node_type, node_name, op, extra)
end

state.add_edge = function(start_type, start_name, extra, stop_type, stop_name)
    assert(start_type ~= nil)
    start_name = start_name or curr_prot.name
    stop_type = stop_type or curr.type
    stop_name = stop_name or curr.name

    extra = extra or {}

    gutils.add_edge(graph, key(start_type, start_name), key(stop_type, stop_name), extra, {build_in_progress = true})
end

return state