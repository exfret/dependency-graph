DepGraph = {}

-- We must initialize these utils first
DepGraph.xutils = require("lib.context-utils.init")
DepGraph.gutils = require("lib.graph-utils.init")

-- build returns a function
DepGraph.build = require("lib.logic.build")