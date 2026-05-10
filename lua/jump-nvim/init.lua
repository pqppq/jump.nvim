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

-- Ensure highlight groups exist. They may have been cleared by a colorscheme
-- change that our autocmd missed (e.g. lazy-loading timing issues).
local function ensure_highlights()
  local hl = vim.api.nvim_get_hl(0, { name = 'JumpNextKey' })
  if not hl.fg then
    require('jump-nvim.highlight').apply()
  end
end

-- Wire up the full pipeline from window context to sorted jump targets.
-- Returns targets sorted by distance from cursor, and the window context.
local function collect(generator, opts)
  local window = require('jump-nvim.window')
  local jump_target = require('jump-nvim.jump_target')

  local ctx = window.context()
  local lines = window.visible_lines(ctx)
  local targets = generator(ctx, lines)

  return jump_target.sort_by_distance(targets, ctx.cursor), ctx
end

-- Jump to the start of any visible line.
-- Will be wired to the input loop in Step 7.
function M.jump_lines(opts)
  ensure_highlights()

  opts = resolve_opts(opts)
  local jump_target = require('jump-nvim.jump_target')
  local label = require('jump-nvim.label')
  local hint = require('jump-nvim.hint')
  local window = require('jump-nvim.window')

  local targets, ctx = collect(jump_target.by_line_start, opts)
  local hints = label.assign(targets, opts.keys)
  local lines = window.visible_lines(ctx)

  hint.dim(ctx.buf, lines)
  hint.render(hints, opts)

  -- TODO: Step 7 - key input loop and cursor movement
  vim.notify(
    string.format('[jump-nvim] jump_lines: rendered %d hints', #hints),
    vim.log.levels.INFO
  )
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
