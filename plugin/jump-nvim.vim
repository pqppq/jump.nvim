" jump-nvim.vim
" Plugin entry point. Defines user-facing commands.

" Prevent loading the plugin more than once.
if exists('g:jump_nvim_loaded')
  finish
endif
let g:jump_nvim_loaded = 1

" Require Neovim 0.5.0 or later.
if !has('nvim-0.5.0')
  echohl Error
  echom '[jump-nvim] Neovim >= 0.5.0 is required.'
  echohl clear
  finish
endif

" ---- Commands ----

" Jump to word starts (full implementation coming in Step 8).
command! JumpWord lua require('jump-nvim').jump_words()
