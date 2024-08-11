local Config = require("lazyvim_menu_addon.config")
local Utils = require("lazyvim_menu_addon.domain.utils")

---@class LazyVimMenuAddonPluginDomain
local M = {}

local Opts = {}
local Keys = {}

-- Property contains key-value pairs to change
--- @param prop table
function Opts.change_property(prop)
  if not type(prop) == "table" then
    return prop
  end

  local result = {}
  for key, value in pairs(prop) do
    result[Utils.change_when_matched(key)] = value
  end
  return result
end

local function printTable(tbl, indent)
  indent = indent or ""
  local s = ""
  for k, v in pairs(tbl) do
    if type(v) == "table" then
      s = s.. indent .. tostring(k) .. ":"
      s = s..printTable(v, indent .. "  ")
    else
      s = s..indent .. tostring(k) .. ": " .. tostring(v)
    end
  end
  return s
end

-- Property is a function executing vim.keymap.set
--- @param prop function
function Opts.inject_vim_keymap_set(prop)
  if not type(prop) == "function" then
    return prop
  end

  local prop_orig = prop
  prop = function(...)
    local keymap_set_orig = vim.keymap.set

    ---@diagnostic disable-next-line: duplicate-set-field
    vim.keymap.set = function(mode, l, r, opts) -- intercept
      local f = io.open("/home/ghost/debug.log", "a+")
      local result = Utils.change_when_matched(l)
      if result ~= l then
        f:write("changing from " .. l .. " to " .. result .. "\n")
      end
      keymap_set_orig(mode, result, r, opts)
      -- f:write(printTable(vim.keymap))
      f:write("executing decorator\n")
      -- f:write(" r=" .. printTable(r) .. "\n")
      f:write(" opts="..printTable(opts) .."\n")
      f:write(" mode=" .. mode .. "\n")
      -- f:write(prop .. "\n")
    end
    prop_orig(...) -- Example: Calls the rhs of gitsigns: on_attach = function(buffer) ...code... end
    vim.keymap.set = keymap_set_orig -- release
  end

  return prop
end

-- -- Change leader keys in plugin.opts
-- -- Supports two approaches:
-- --   1. The keys are property values in the opts table: --> Change the keys. Example: which-key.nvim
-- --   2. The keys are in a rhs function in the opts table: --> Decorate the function. Example: gitsigns.nvim
---@param opts_to_change table|fun(_, opts:table)
---@param prop string
function Opts.change(opts_to_change, prop)
  local f = io.open("/home/ghost/debug.log", "a+")
  f:write(prop .. "\n")
  local function modify(opts)
    if opts[prop] then
      f:write("exists\n")
      if type(opts[prop]) == "function" then
        f:write("function\n")
      end
      opts[prop] = type(opts[prop]) == "function" and Opts.inject_vim_keymap_set(opts[prop])
        or Opts.change_property(opts[prop])
    end
    return opts
  end

  ---@return fun(_, opts:table):table
  local function inject()
    return function(_, merged_opts) -- called in lazy.core.plugin._values
      local result = opts_to_change(_, merged_opts) or merged_opts
      return modify(result)
    end
  end

  return type(opts_to_change) == "function" and inject() or modify(opts_to_change)
end

-- Change leader keys in plugin.keys
function Keys.change(keys_to_change)
  local function modify(keys)
    return vim.tbl_map(function(lazy_mapping)
      lazy_mapping[1] = Utils.change_when_matched(lazy_mapping[1])
      return lazy_mapping
    end, keys)
  end

  ---@return fun(_, keys:table):table
  local function inject()
    return function(_, merged_keys) -- called in lazy.core.handler.init.resolve
      local result = keys_to_change(_, merged_keys) or merged_keys
      return modify(result)
    end
  end

  return type(keys_to_change) == "function" and inject() or modify(keys_to_change)
end

-- Change leader keys in plugin.keys
-- Change leader keys in plugin.opts
-- In LazyVim v10.8.2, plugin.keys is always a table(mini.surround does not contain leader keys)
--
---@param adapter_cb fun(_, plugin:LazyPlugin, results?:string[])
---@return fun(_, plugin:LazyPlugin, results?:string[]):LazyPlugin
function M.change(adapter_cb)
  -- See lazy.core.plugins.spec.add
  ---@param _ LazySpec
  ---@param plugin LazyPlugin
  ---@param results? string[]
  return function(_, plugin, results)
    plugin = adapter_cb(_, plugin, results) -- lazy.nvim adds and merges the fragment

    if not (plugin and type(plugin) == "table" and Utils.is_lazyvim_fragment(plugin)) then
      return plugin -- do not change plugin fragments defined by the user
    end

    local keys = rawget(plugin, "keys")
    if keys then
      plugin.keys = Keys.change(keys)
    end

    local opts = rawget(plugin, "opts")
    if opts then
      for plugin_name, property_with_keys in pairs(Config.options.change_in_opts) do
        if plugin_name == plugin.name then
          plugin.opts = Opts.change(plugin.opts, property_with_keys)
        end
      end
    end

    return plugin
  end
end

return M
