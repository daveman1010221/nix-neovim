if vim.g.did_load_plugins_plugin then
  return
end
vim.g.did_load_plugins_plugin = true

-- many plugins annoyingly require a call to a 'setup' function to be loaded,
-- even with default configs

require('nvim-tree').setup({
   sort_by = "case_sensitive",
   view = {
     width = 30,
   },
   renderer = {
     group_empty = true,
   },
   filters = {
     dotfiles = true,
   },
})

require('gruvbox').setup({
  terminal_colors = true, -- add neovim terminal colors
  undercurl = true,
  underline = true,
  bold = true,
  italic = {
    strings = true,
    emphasis = true,
    comments = true,
    operators = false,
    folds = true,
  },
  strikethrough = true,
  invert_selection = false,
  invert_signs = false,
  invert_tabline = false,
  invert_intend_guides = false,
  inverse = true, -- invert background for search, diffs, statuslines and errors
  contrast = "hard", -- can be "hard", "soft" or empty string
  palette_overrides = {},
  overrides = {},
  dim_inactive = false,
  transparent_mode = false,
})

require("neoconf").setup({
  -- override any of the default settings here
})

-- Neovim 0.11+ LSP configuration (replaces deprecated lspconfig.setup() API)
-- See :help lspconfig-nvim-0.11 and :help vim.lsp.config
-- If nixpkgs provides only `pyright` (and not `pyright-langserver`),
-- force the command so the config is usable.
vim.lsp.config("pyright", {
  cmd = (vim.fn.executable("pyright-langserver") == 1)
    and { "pyright-langserver", "--stdio" }
    or { "pyright", "--stdio" },
})
vim.lsp.enable("pyright")

-- Lua
vim.lsp.enable("lua_ls")

-- JSON
vim.lsp.enable("jsonls")

require('which-key').setup()
