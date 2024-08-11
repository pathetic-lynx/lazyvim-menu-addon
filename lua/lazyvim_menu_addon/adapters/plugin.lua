---@class LazyVimMenuAddonPluginAdapter
local M = {}

---@return LazyVimMenuAddonConfig
function M.get_opts()
  local plugin = require("lazy.core.config").spec.plugins["lazyvim-menu-addon"]

  ---@type LazyVimMenuAddonConfig | fun(LazyPlugin, opts:table):LazyVimMenuAddonConfig
  local opts = plugin.opts or {}
  if type(opts) == "function" then
    return opts(plugin, {})
  end
  return opts
end

---@param change_cb fun(add_cb:fun())
function M.inject(change_cb)
  local Meta = require("lazy.core.meta")
  local add_decorated = change_cb(Meta.add)

  ---@diagnostic disable-next-line: duplicate-set-field
  Meta.add = function(_, plugin, results)
    return add_decorated(_, plugin, results)
  end

  local Keys = require("lazy.core.handler.keys")
  local _add_decorated = change_cb(Keys._add)

  ---@diagnostic disable-next-line: duplicate-set-field
  Keys._add = function(_, plugin, results)
    return _add_decorated(_, plugin, results)
  end
end

return M
