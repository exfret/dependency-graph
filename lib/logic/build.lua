local xutils = require("lib.context-utils.init")
local state = require("lib.logic.state")
local concrete = require("lib.logic.concrete")
local abstract = require("lib.logic.abstract")
local group = require("lib.logic.group")
local balance = require("lib.logic.balance")
local setup = require("lib.logic.setup")

local key = DataRawLib.key.key

local build = function(params)
----------------------------------------------------------------------------------------------------
-- Initialize
----------------------------------------------------------------------------------------------------

    params = params or {}

    LookupLib.build()
    -- Make lookups global since they will be used often
    lu = LookupLib.lookup
    -- Contexts are not used in actual graph construction, but this is a good time to make sure they're up-to-date and created
    xutils.make_contexts()

    DepGraph.graph = {
        nodes = {},
        edges = {},
        sources = {},
    }
    state.init(DepGraph.graph)

----------------------------------------------------------------------------------------------------
-- Concrete nodes
----------------------------------------------------------------------------------------------------

    concrete.build()

----------------------------------------------------------------------------------------------------
-- Abstract nodes
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Group nodes
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Balance nodes
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Compat nodes
----------------------------------------------------------------------------------------------------

    -- TODO: Probably will do this as a folder, so that each mod can get its own file

----------------------------------------------------------------------------------------------------
-- Graph setup
----------------------------------------------------------------------------------------------------

    setup.complete()

----------------------------------------------------------------------------------------------------
-- Cleanup
----------------------------------------------------------------------------------------------------

    -- Set lu back to nil so that it doesn't pollute global namespace
    lu = nil
end

return build