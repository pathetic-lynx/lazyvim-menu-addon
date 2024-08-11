local Config = require("lazyvim_menu_addon.config")
local M = {}

-- The fragment of a plugin is defined in LazyVim, not by the user
---@param plugin LazyPlugin
function M.is_lazyvim_fragment(plugin)
  return plugin and plugin._ and plugin._.module and plugin._.module:find("lazyvim", 1, true)
end

-- Return a new key when key is in leaders_to_change
-- Otherwise, return the key unchanged
---@param key string
---@return string
function M.change_when_matched(key)
  local result = key
  local f = io.open("/home/ghost/debug.log", "a+")
  f:write("key: ".. key .."\n")
  for leader, new_leader in pairs(Config.options.leaders_to_change) do
    f:write(" leader: ".. leader .."\n")
    f:write(" new_leader: ".. new_leader .."\n")
    if key:find(leader, 1, true) then
      f:write(" REPLACE: ".. new_leader .."\n")
      result = key:gsub(leader, new_leader)
      break
    end
  end
  f:write("RESULT: ".. result .."\n")
  return result
end

return M
