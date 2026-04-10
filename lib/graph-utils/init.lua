local gutils = {}

-- graph-utils is split up into multiple files mainly for organization
-- Everything will still be at the same top level in the DepGraph.gutils table
local filenames = {
    "basic-ops",
    "subdivision",
}
for _, filename in pairs(filenames) do
    local sub_utils = require("lib.graph-utils." .. filename)
    for k, v in pairs(sub_utils) do
        if gutils[k] ~= nil then
            error("Attempt to redefine graph utility " .. k)
        end
        gutils[k] = v
    end
end

return gutils