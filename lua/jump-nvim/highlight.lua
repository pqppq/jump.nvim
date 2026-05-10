-- jump-nvim/highlight.lua
-- Highlight group definitions.
--
-- When rendering labels via extmarks, Neovim uses highlight groups to color
-- the text. Using `highlight default` allows users to override the colors
-- in their own colorscheme configuration.

local M = {}

-- Register all highlight groups used by jump-nvim.
-- Called from setup() and re-called whenever the colorscheme changes.
function M.apply()
  -- Single-char label (immediately confirms a target): pink bold
  vim.api.nvim_command('highlight default JumpNextKey  guifg=#ff007c gui=bold ctermfg=198 cterm=bold')

  -- First char of a two-char label (still narrowing down): cyan bold
  vim.api.nvim_command('highlight default JumpNextKey1 guifg=#00dfff gui=bold ctermfg=45 cterm=bold')

  -- Second char of a two-char label (the key to press after the prefix): blue
  vim.api.nvim_command('highlight default JumpNextKey2 guifg=#2b8db3 ctermfg=33')

  -- Non-target text: dimmed grey
  vim.api.nvim_command('highlight default JumpUnmatched guifg=#666666 guibg=bg guisp=#666666 ctermfg=242')

  -- Virtual cursor shown while jumping: same appearance as the normal cursor
  vim.api.nvim_command('highlight default link JumpCursor Cursor')
end

-- Create an autocmd that re-registers highlights when the colorscheme changes.
-- Without this, highlights would be lost after a `:colorscheme` command.
function M.watch_colorscheme()
  vim.api.nvim_command('augroup JumpInitHighlight')
  vim.api.nvim_command('autocmd!')
  vim.api.nvim_command("autocmd ColorScheme * lua require'jump-nvim.highlight'.apply()")
  vim.api.nvim_command('augroup end')
end

return M
