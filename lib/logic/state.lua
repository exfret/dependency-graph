-- This file keeps state while building the graph to make the building process easier
-- Also has the responsibility of actually adding the nodes etc.

local gutils = DepGraph.gutils
local key = DataRawLib.key.key

local state = {}

local graph
local type_info
local edge_info

local curr
local curr_class
local curr_prot

state.init = function(logic_graph, logic_type_info, logic_edge_info)
    graph = logic_graph
    type_info = logic_type_info
    edge_info = logic_edge_info

    curr = nil
    curr_class = nil
    curr_prot = nil
end

state.set_class = function(class_name)
    curr_class
end