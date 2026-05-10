-- jump-nvim/init.lua
-- Main module.
--
-- Users initialise the plugin by calling:
--   require('jump-nvim').setup(opts)
-- Individual jump_xxx() functions will be added in later steps.

local M = {}

-- Merge global opts with per-call overrides.
-- Keys absent in `opts` fall back to M.opts (which itself falls back to defaults)
-- via setmetatable's __index chain.
local function resolve_opts(opts)
  return setmetatable(opts or {}, { __index = M.opts })
end

-- Initialise the plugin. Must be called from the user's init.lua.
--
-- Example:
--   require('jump-nvim').setup({
--     keys = 'asdfghjkl',
--     uppercase_labels = true,
--   })
function M.setup(opts)
  -- Merge user options on top of defaults and persist them.
  local default_ops = require('jump-nvim.defaults')
  M.opts = setmetatable(opts or {}, { __index = default_ops })
  M.initialized = true

  -- Register highlight groups.
  local highlight = require('jump-nvim.highlight')
  highlight.apply()

  -- Optionally re-register highlights when the colorscheme changes.
  if M.opts.create_hl_autocmd then
    highlight.watch_colorscheme()
  end
end

-- Placeholder called by :JumpWord.
-- Will be replaced with the real implementation in Steps 4-7.
function M.jump_words(opts)
  opts = resolve_opts(opts)

  if not M.initialized then
    vim.notify(
      '[jump-nvim] setup() has not been called. Add require("jump-nvim").setup() to your init.lua.',
      vim.log.levels.ERROR
    )
    return
  end

  -- TODO: Step 4 - collect jump targets from visible lines
  -- TODO: Step 5 - assign labels to targets
  -- TODO: Step 6 - render dimming and label extmarks
  -- TODO: Step 7 - key input loop and cursor movement
  vim.notify('[jump-nvim] jump_words: not yet implemented (Steps 4-7).', vim.log.levels.INFO)
end

return M
