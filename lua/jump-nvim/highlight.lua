-- jump-nvim/highlight.lua
-- Highlight group definitions.
--
-- `highlight default` is intentionally NOT used here. In lazy-loading setups,
-- setup() is called after the colorscheme has already run `:hi clear`, which
-- leaves groups in a "cleared" (defined but empty) state. `highlight default`
-- treats "cleared" as already defined and silently skips the group.
-- By always setting highlights unconditionally, we ensure colors are correct.
--
-- Users who want to override colors should do so after calling setup(), e.g.:\
--   require('jump-nvim').setup()
--   vim.api.nvim_set_hl(0, 'JumpNextKey', { fg = '#your-color', bold = true })

local M = {}

-- Register all highlight groups used by jump-nvim.
-- Called from setup() and re-called whenever the colorscheme changes.
function M.apply()
  -- Single-char label (immediately confirms a target): pink bold
  vim.api.nvim_set_hl(0, 'JumpNextKey', { fg = '#ff007c', bold = true, ctermfg = 198 })

  -- First char of a two-char label (still narrowing down): cyan bold
  vim.api.nvim_set_hl(0, 'JumpNextKey1', { fg = '#00dfff', bold = true, ctermfg = 45 })

  -- Second char of a two-char label (the key to press after the prefix): blue
  vim.api.nvim_set_hl(0, 'JumpNextKey2', { fg = '#2b8db3', ctermfg = 33 })

  -- Non-target text: dimmed grey
  vim.api.nvim_set_hl(
    0,
    'JumpUnmatched',
    { fg = '#666666', bg = 'bg', sp = '#666666', ctermfg = 242 }
  )

  -- Virtual cursor shown while jumping: same appearance as the normal cursor
  vim.api.nvim_set_hl(0, 'JumpCursor', { link = 'Cursor' })
end

-- Create an autocmd that re-registers highlights when the colorscheme changes.
-- Without this, highlights would be lost after a `:colorscheme` command.
function M.watch_colorscheme()
  local group = vim.api.nvim_create_augroup('JumpInitHighlight', { clear = true })
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = group,
    callback = function()
      require('jump-nvim.highlight').apply()
    end,
  })
end

return M
