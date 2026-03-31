if vim.g.did_load_treesitter_plugin then
  return
end
vim.g.did_load_treesitter_plugin = true

-- Treesitter-based folding
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

-- Register json parser for jsonc
pcall(function()
  vim.treesitter.language.register("json", "jsonc")
end)

-- Nu support
vim.api.nvim_create_autocmd("FileType", {
  pattern = "nu",
  callback = function(args)
    vim.schedule(function()
      pcall(vim.treesitter.start, args.buf, "nu")
    end)
  end,
})

local ok, textobjects = pcall(require, "nvim-treesitter-textobjects")
if ok then
  textobjects.setup({
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ['af'] = '@function.outer',
        ['if'] = '@function.inner',
        ['ac'] = '@class.outer',
        ['ic'] = '@class.inner',
        ['aC'] = '@call.outer',
        ['iC'] = '@call.inner',
        ['a#'] = '@comment.outer',
        ['i#'] = '@comment.outer',
        ['ai'] = '@conditional.outer',
        ['ii'] = '@conditional.outer',
        ['al'] = '@loop.outer',
        ['il'] = '@loop.inner',
        ['aP'] = '@parameter.outer',
        ['iP'] = '@parameter.inner',
      },
      selection_modes = {
        ['@parameter.outer'] = 'v',
        ['@function.outer'] = 'V',
        ['@class.outer'] = '<c-v>',
      },
    },
    swap = {
      enable = true,
      swap_next = {
        ['<leader>a'] = '@parameter.inner',
      },
      swap_previous = {
        ['<leader>A'] = '@parameter.inner',
      },
    },
    move = {
      set_jumps = true,
      goto_next_start = {
        [']m'] = '@function.outer',
        [']P'] = '@parameter.outer',
      },
      goto_next_end = {
        [']m'] = '@function.outer',
        [']P'] = '@parameter.outer',
      },
      goto_previous_start = {
        ['[m'] = '@function.outer',
        ['[P'] = '@parameter.outer',
      },
      goto_previous_end = {
        ['[m'] = '@function.outer',
        ['[P'] = '@parameter.outer',
      },
    },
  })
end
