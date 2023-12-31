--[[
Inversion of control pattern

Adapters:
Provide a central place in the code where lazy.nvim is used
Provide a central place in the code where LazyVim is used

Domain:
Provide a central place in the code for the actual logic

Making sure the integration works -> see e2e_spec.lua
Making sure lazymenu works -> see unit test specs
--]]

---@type LazyMenuAdapters
local adapters = {
  plugin = require("lazymenu.adapters.plugin"),
  lsp = require("lazymenu.adapters.lsp"),
  safe_keymap_set = require("lazymenu.adapters.safe_keymap_set"),
}

---@type LazyMenuDomain
local domain = {
  plugin = require("lazymenu.domain.plugin"),
  lsp = require("lazymenu.domain.lsp"),
  keymaps = require("lazymenu.domain.keymaps"),
}

return require("lazymenu").on_hook(adapters, domain)
