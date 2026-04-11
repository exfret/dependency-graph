local xutils = {}

-- context-utils is split up into multiple files mainly for organization
-- Everything will still be at the same top level in the DepGraph.xutils table
local filenames = {
    "abilities-enum",
    "make-contexts",
}
for _, filename in pairs(filenames) do
    local sub_utils = require("lib.context-utils." .. filename)
    for k, v in pairs(sub_utils) do
        if xutils[k] ~= nil then
            error("Attempt to redefine context utility " .. k)
        end
        xutils[k] = v
    end
end

return xutils