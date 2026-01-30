-- init.lua (clean Lua)

-- Convenience
local opt = vim.opt
local fn = vim.fn

-- Not really needed in Neovim, but harmless.
opt.compatible = false

-- Providers / built-ins
vim.g.editorconfig = true
vim.g.loaded_perl_provider = 0

-- Disable netrw early (nvim-tree expects this)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- UI / visuals
opt.termguicolors = true
opt.background = "dark"
opt.colorcolumn = "100"

opt.laststatus = 2
opt.cmdheight = 2
opt.showcmd = true
opt.showmatch = true
opt.showmode = true
opt.ruler = true
opt.number = true
opt.signcolumn = "yes"
opt.scrolloff = 5

-- Mouse
opt.mouse = "a"
opt.mousehide = true

-- Sound (nope)
opt.errorbells = false

-- Files / buffers
opt.backup = false
opt.writebackup = false
opt.autoread = true
opt.hidden = true
opt.fileformat = "unix"
opt.sessionoptions:append({ "unix", "slash" })

-- Editing
opt.expandtab = true
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.autoindent = true
opt.smartindent = true
opt.foldmethod = "manual"

-- Search
opt.incsearch = true
opt.ignorecase = true
opt.smartcase = true

-- Input behavior
opt.backspace = { "indent", "eol", "start" }

-- Shell
opt.shell = "/bin/sh"

-- Performance / messaging
opt.updatetime = 300
opt.shortmess:append("c")

-- Pack path (only if you're actually using native pack/* outside Nix)
opt.packpath:append(fn.expand("$HOME/.config/nvim/pack"))

-- Statusline (kept as-is)
opt.statusline = [[%<%f\ %h%m%r%=%-25.(ln=%l\ col=%c%V\ totlin=%L%)\ %h%m%r%=%-20(bval=0x%B,%n%Y%)%P]]

-- Diagnostics
local function diag_prefix(icon, diagnostic)
  return string.format("%s %s", icon, diagnostic.message)
end

vim.diagnostic.config({
  virtual_text = {
    prefix = "",
    format = function(diagnostic)
      local sev = diagnostic.severity
      if sev == vim.diagnostic.severity.ERROR then
        return diag_prefix("󰅚", diagnostic)
      elseif sev == vim.diagnostic.severity.WARN then
        return diag_prefix("⚠", diagnostic)
      elseif sev == vim.diagnostic.severity.INFO then
        return diag_prefix("ⓘ", diagnostic)
      elseif sev == vim.diagnostic.severity.HINT then
        return diag_prefix("󰌶", diagnostic)
      end
      return diag_prefix("■", diagnostic)
    end,
  },
  -- Neovim 0.11+: define diagnostic sign text here (sign_define() is deprecated)
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅚",
      [vim.diagnostic.severity.WARN]  = "⚠",
      [vim.diagnostic.severity.INFO]  = "ⓘ",
      [vim.diagnostic.severity.HINT]  = "󰌶",
    },
    -- If you ever want number-column highlights for diagnostics:
    -- numhl = {
    --   [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
    --   [vim.diagnostic.severity.WARN]  = "DiagnosticSignWarn",
    --   [vim.diagnostic.severity.INFO]  = "DiagnosticSignInfo",
    --   [vim.diagnostic.severity.HINT]  = "DiagnosticSignHint",
    -- },
  },
  update_in_insert = false,
  underline = true,
  severity_sort = true,
  float = {
    focusable = false,
    style = "minimal",
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },
})

-- Colorscheme
vim.cmd.colorscheme("gruvbox")

-- Remember folds/views safely (won't explode on unnamed/special buffers)
local view_group = vim.api.nvim_create_augroup("remember_folds", { clear = true })

local function is_real_file_buffer()
  if vim.bo.buftype ~= "" then
    return false
  end
  -- must have a filename
  return fn.expand("%:p") ~= ""
end

vim.api.nvim_create_autocmd("BufWinLeave", {
  group = view_group,
  callback = function()
    if is_real_file_buffer() then
      vim.cmd("silent! mkview")
    end
  end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = view_group,
  callback = function()
    if is_real_file_buffer() then
      vim.cmd("silent! loadview")
    end
  end,
})
