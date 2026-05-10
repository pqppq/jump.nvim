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

  -- Re-register highlights whenever the colorscheme changes at runtime.
  if M.opts.create_hl_autocmd then
    highlight.watch_colorscheme()
  end

  -- Defer initial highlight registration to run after the current event
  -- loop completes. This ensures highlights are applied after any pending
  -- colorscheme initialization, regardless of plugin load order.
  vim.schedule(function()
    highlight.apply()
  end)
end

-- Move the cursor to a target position.
local function move_cursor_to(target)
  vim.api.nvim_win_set_cursor(target.win, { target.lnum + 1, target.col })
end

-- Display hints for the given targets, wait for key input, and jump.
-- Shared by all jump_xxx() functions.
--
-- 1. If only one target and jump_on_sole_occurrence, jump immediately.
-- 2. Dim visible lines and render labels.
-- 3. Enter a key-input loop:
--    - quit_key cancels the session.
--    - A valid key narrows hints via filter_hints.
--    - When a target is fully resolved, move the cursor there.
-- 4. Always clean up extmarks before returning.
local function jump_to(targets, ctx, opts)
  local label = require('jump-nvim.label')
  local hint = require('jump-nvim.hint')
  local window = require('jump-nvim.window')

  -- Nothing to do if there are no targets.
  if #targets == 0 then
    return
  end

  -- Jump immediately when there is only one target.
  if #targets == 1 and opts.jump_on_sole_occurrence then
    move_cursor_to(targets[1])
    return
  end

  local hints = label.assign(targets, opts.keys)
  local lines = window.visible_lines(ctx)

  hint.dim(ctx.buf, lines)
  hint.render(hints, opts)
  vim.cmd('redraw')

  -- Resolve the quit_key to the internal byte representation so we can
  -- compare it against the raw return value of getcharstr().
  local quit = vim.api.nvim_replace_termcodes(opts.quit_key, true, false, true)

  -- Key input loop.
  while true do
    local ok, key = pcall(vim.fn.getcharstr)
    if not ok or key == quit then
      break
    end

    local done, remaining = label.filter_hints(hints, key)
    if done then
      hint.clear(ctx.buf)
      move_cursor_to(done)
      return
    end

    if #remaining == 0 then
      -- No hints matched — treat as cancel.
      break
    end

    -- Re-render with the narrowed-down hints.
    hints = remaining
    hint.clear(ctx.buf)
    hint.dim(ctx.buf, lines)
    hint.render(hints, opts)
    vim.cmd('redraw')
  end

  -- Clean up on cancel / no match.
  hint.clear(ctx.buf)
end

-- Jump to the start of any visible line.
function M.jump_lines(opts)
  opts = resolve_opts(opts)
  local window = require('jump-nvim.window')
  local jump_target = require('jump-nvim.jump_target')

  local ctx = window.context()
  local lines = window.visible_lines(ctx)
  local targets =
    jump_target.sort_by_distance(jump_target.get_line_start_targets(ctx, lines), ctx.cursor)

  jump_to(targets, ctx, opts)
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
