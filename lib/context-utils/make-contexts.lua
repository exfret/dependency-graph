local abilities = require("lib.context-utils.abilities-enum").abilities

local key = DataRawLib.key.key

local make_contexts = {}

make_contexts.make_ability_strings = function(index)
    index = index or 1
    if index == #abilities then
        return {"0", "1"}
    end

    local ability_strings = {}
    for _, ability_value in pairs({"0", "1"}) do
        for _, suffix in pairs(make_contexts.make_ability_strings(index + 1)) do
            table.insert(ability_strings, ability_value .. suffix)
        end
    end
    if index == 1 then
        -- If this is the outermost call, set abilities_strings
        -- By this point, DepGraph.xutils should be set and global
        DepGraph.xutils.ability_strings = ability_strings
    else
        return ability_strings
    end
end

make_contexts.make_contexts = function()
    make_contexts.make_ability_strings()

    local contexts = {}
    for room_key, room in pairs(lu.rooms) do
        for _, ability_string in pairs(DepGraph.xutils.ability_strings) do
            contexts[key(room_key, ability_string)] = {
                room = room_key,
                abilities = ability_string,
            }
        end
    end

    DepGraph.xutils.contexts = contexts
end

return make_contexts