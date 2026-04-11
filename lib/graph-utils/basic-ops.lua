local key = DataRawLib.key.key
local ekey = DataRawLib.key.ekey

local basic_ops = {}

-- Default node should have values set for all standard node fields
local default_node = {
    object_type = "node",
    type = "", -- Must be provided
    name = "", -- Must be provided
    op = "", -- Must be provided
    pre = {},
    dep = {},
    num_pre = 0,
    num_dep = 0,
}
basic_ops.add_node = function(graph, node_type, node_name, op, extra)
    assert(node_type ~= nil)
    assert(node_name ~= nil)
    assert(op == "OR" or op == "AND")

    local node = table.deepcopy(default_node)
    node.type = node_type
    node.name = node_name
    node.op = op
    if extra ~= nil then
        for k, v in pairs(extra) do
            assert(node[k] == nil)
            node[k] = v
        end
    end

    graph.nodes[key(node)] = node
    -- If op is AND, initially add to sources
    if op == "AND" then
        graph.sources[key(node)] = true
    end

    return node
end

-- out_or_in is "out" if we're updating outdegree, or "in" if updating indegree
basic_ops.update_degree_info = function(graph, node_key, out_or_in, change)
    assert(type(node_key) == "string")
    assert(out_or_in == "out" or out_or_in == "in")
    local key_to_change
    if out_or_in == "out" then
        key_to_change = "num_dep"
    elseif out_or_in == "in" then
        key_to_change = "num_pre"
    end
    local node = graph.nodes[node_key]
    node[key_to_change] = node[key_to_change] + change
    if node[key_to_change] == 0 and node.op == "AND" then
        graph.sources[key(node)] = true
    else
        graph.sources[key(node)] = nil
    end
end
-- Default edge should have values set for all standard node fields
local default_edge = {
    object_type = "edge",
    type = "", -- Must be provided
    start = "", -- Must be provided
    stop = "", -- Must be provided
}
-- start and stop can be given as the actual nodes, in which case they're converted to keys
-- flags is extra info about the creation, mainly here whether to not update degree info yet (because the nodes are maybe not created)
basic_ops.add_edge = function(graph, edge_type, start, stop, extra, flags)
    assert(type(edge_type) == "string")
    if type(start) == "table" then
        start = key(start)
    end
    if type(stop) == "table" then
        stop = key(stop)
    end
    flags = flags or {}

    local edge = table.deepcopy(edge)
    edge.type = edge_type
    edge.start = start
    edge.stop = stop
    if extra ~= nil then
        for k, v in pairs(extra) do
            assert(node[k] == nil)
            edge[k] = v
        end
    end

    graph.edges[ekey(edge)] = edge
    if not flag.build_in_progress then
        basic_ops.update_degree_info(graph, edge.start, "out", 1)
        basic_ops.update_degree_info(graph, edge.stop, "in", 1)
    end
    
    return edge
end

return basic_ops