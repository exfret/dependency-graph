local key = DataRawLib.key.key
local ekey = DataRawLib.key.ekey

-- Tests for direct existence of an edge
local function test_iron_chest_buildable_edge()
    local iron_chest = graph.nodes[key("entity-place-item", "iron-chest")]
    assert(iron_chest ~= nil)
    local iron_chest_edge = graph.edges[ekey(key("item", "iron-chest"), key("entity-place-item", "iron-chest"))]
    assert(iron_chest_edge ~= nil)
end
test_iron_chest_buildable_edge()