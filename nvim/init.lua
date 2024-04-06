local cmd = vim.cmd
local fn = vim.fn

vim.opt.compatible = false

-- Enable true colour support
if fn.has('termguicolors') then
  opt.termguicolors = true
end

-- See :h <option> to see what the options do

-- Configure Neovim diagnostic messages

local function prefix_diagnostic(prefix, diagnostic)
  return string.format(prefix .. ' %s', diagnostic.message)
end

local sign = function(opts)
  fn.sign_define(opts.name, {
    texthl = opts.name,
    text = opts.text,
    numhl = '',
  })
end
-- Requires Nerd fonts
sign { name = 'DiagnosticSignError', text = '󰅚' }
sign { name = 'DiagnosticSignWarn', text = '⚠' }
sign { name = 'DiagnosticSignInfo', text = 'ⓘ' }
sign { name = 'DiagnosticSignHint', text = '󰌶' }

vim.diagnostic.config {
  virtual_text = {
    prefix = '',
    format = function(diagnostic)
      local severity = diagnostic.severity
      if severity == vim.diagnostic.severity.ERROR then
        return prefix_diagnostic('󰅚', diagnostic)
      end
      if severity == vim.diagnostic.severity.WARN then
        return prefix_diagnostic('⚠', diagnostic)
      end
      if severity == vim.diagnostic.severity.INFO then
        return prefix_diagnostic('ⓘ', diagnostic)
      end
      if severity == vim.diagnostic.severity.HINT then
        return prefix_diagnostic('󰌶', diagnostic)
      end
      return prefix_diagnostic('■', diagnostic)
    end,
  },
  signs = true,
  update_in_insert = false,
  underline = true,
  severity_sort = true,
  float = {
    focusable = false,
    style = 'minimal',
    border = 'rounded',
    source = 'always',
    header = '',
    prefix = '',
  },
}

vim.g.editorconfig = true

vim.opt.colorcolumn = '100'

-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- set termguicolors to enable highlight groups
vim.opt.termguicolors = true

vim.opt.syntax = "enable"

-- filetype plugin indent on

vim.opt.foldmethod = "manual"

-- Last two lines of the window are status lines.
vim.opt.laststatus = 2

-- python3_host_prog = "/home//.pyenv/versions/venv_py3nvim/bin/python"

loaded_perl_provider = 0

-- Parse this out if you must. Or just look at the status line and see if it is ok for you.
vim.opt.statusline = [[%<%f\ %h%m%r%=%-25.(ln=%l\ col=%c%V\ totlin=%L%)\ %h%m%r%=%-20(bval=0x%B,%n%Y%)%P]]

-- Bell-on-error is the worst. Especially when you have a HDMI bug that affects
-- Pulse Audio. :-/
vim.opt.errorbells = false

-- Better for the eyes
vim.opt.background = "dark"

-- Auto-enable mouse in terminal.
vim.opt.mouse = "a"

-- Hide mouse cursor when typing.
vim.opt.mousehide = true

-- Show last 5 lines when scrolling, so that you have some look-ahead room.
vim.opt.scrolloff = 5

--  no backup files
vim.opt.backup = false
vim.opt.writebackup = false

-- Helpful stuff in lower right.
vim.opt.showcmd = true

-- Match braces.
vim.opt.showmatch = true

-- Show whether in, i.e., visual/insert/etc.
vim.opt.showmode = true

-- show location in file (Top/Bottom/%).
vim.opt.ruler = true

-- sets fileformat to unix <N-L> not win <C-R><N-L>
vim.opt.fileformat = "unix"

-- sets unix files and backslashes to forward slashes even in windows
vim.opt.sessionoptions = vim.opt.sessionoptions + "unix,slash"

-- Give more space for displaying messages.
vim.opt.cmdheight = 2

-- Show line numbers.
vim.opt.number = true

-- Search as you type.
vim.opt.incsearch = true

-- Ignore case on search.
vim.opt.ignorecase = true

-- If capitalized, use as typed. Otherwise, ignore case.
vim.opt.smartcase = true

-- Controls how backspace works.
vim.opt.backspace = "2"

-- Use spaces instead of tabs.
vim.opt.expandtab = true

-- Use 4 space tabs.
vim.opt.tabstop = 4

-- Use 4 spaces when using <BS>.
vim.opt.softtabstop = 4

-- Use 4 spaces for tabs in autoindent.
vim.opt.shiftwidth = 4

-- Copy indent on next line when hitting enter, 
-- or using o or O cmd in insert mode.
vim.opt.autoindent = true

-- reload file automatically.
vim.opt.autoread = true

-- Attempt to indent based on "rules".
vim.opt.smartindent = true

-- hide buffers instead of unloading them
vim.opt.hidden = true

-- Run commands in a known shell.
vim.opt.shell = "/bin/sh"

-- Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
-- delays and poor user experience.
vim.opt.updatetime = 300

-- Do not pass messages to |ins-completion-menu|.
vim.opt.shortmess = vim.opt.shortmess + "c"

-- Always show the signcolumn, otherwise it would shift the text each time
-- diagnostics appear/become resolved.
vim.opt.signcolumn = "yes"

vim.opt.packpath = vim.opt.packpath + "$HOME/.config/nvim/pack"

vim.cmd("colorscheme gruvbox")

vim.cmd([[
augroup remember_folds
  autocmd!
  autocmd BufWinLeave * mkview
  autocmd BufWinEnter * silent! loadview
augroup END
