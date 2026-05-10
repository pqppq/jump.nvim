-- jump-nvim/window.lua
-- Collects visible-line and cursor context from the current window.

local M = {}

-- Return the context for the current window.
--
-- All line numbers are 0-indexed throughout jump-nvim to match the
-- nvim_buf_get_lines / nvim_buf_set_extmark APIs directly.
--
-- Returns:
--   {
--     win    = <window handle>,
--     buf    = <buffer handle>,
--     cursor = { row, col },   -- both 0-indexed
--     top    = <first visible line, 0-indexed inclusive>,
--     bot    = <last  visible line, 0-indexed exclusive>,
--   }
function M.context()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local info = vim.fn.getwininfo(win)[1]

  -- nvim_win_get_cursor returns { 1-indexed row, 0-indexed byte col }
  local cursor = vim.api.nvim_win_get_cursor(win)

  return {
    win = win,
    buf = buf,
    cursor = { cursor[1] - 1, cursor[2] }, -- normalize row to 0-indexed
    top = info.topline - 1, -- normalize to 0-indexed inclusive
    bot = info.botline, -- 0-indexed exclusive (== 1-indexed inclusive)
  }
end

-- Iterator that yields { lnum, is_folded } for each visible line group.
--
-- foldclosedend() takes a 1-indexed line number and returns the 1-indexed
-- last line of the fold, or -1 when the line is not folded.
-- Assigning fold_end (1-indexed) to lnum (0-indexed) correctly advances to
-- the line after the fold:
--   fold ends at 1-indexed N  →  next 0-indexed line = N  (not N-1)
local function iter_lines(ctx)
  local lnum = ctx.top
  return function()
    if lnum >= ctx.bot then
      return nil
    end

    local fold_end = vim.api.nvim_win_call(ctx.win, function()
      return vim.fn.foldclosedend(lnum + 1)
    end)

    local current = lnum
    if fold_end == -1 then
      lnum = lnum + 1
      return current, false
    else
      lnum = fold_end
      return current, true
    end
  end
end

-- Return the visible, non-folded lines for the given window context.
--
-- Folded regions are skipped — only the first line of a fold is included
-- (as an empty string), since jump_target.lua will find no matches in it.
--
-- Returns a list of { lnum, text } where lnum is 0-indexed.
function M.visible_lines(ctx)
  local lines = {}
  for lnum, is_folded in iter_lines(ctx) do
    local text = is_folded and '' or vim.api.nvim_buf_get_lines(ctx.buf, lnum, lnum + 1, false)[1]
    lines[#lines + 1] = { lnum = lnum, text = text }
  end
  return lines
end

return M
