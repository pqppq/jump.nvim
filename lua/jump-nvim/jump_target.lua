-- jump-nvim/jump_target.lua
-- Jump target generation and scoring.
--
-- A jump target is a table representing a single location the cursor can jump to:
--   { lnum, col, win, buf }  -- all values are 0-indexed
--
-- get_xxx_targets(ctx, lines) functions return a list of targets.
-- Additional target types (word, char, pattern, ...) will be added in later steps.

local M = {}

-- Return a new list of targets sorted by line-first distance from the cursor.
--
-- Primary key:   absolute line distance  (|lnum - cursor_row|)
-- Secondary key: absolute column distance (|col  - cursor_col|)
--
-- This groups all targets on the same line together in the sorted output.
-- Because labels are assigned sequentially, targets on the same line will
-- naturally share the same prefix key for 2-char labels. This matches how
-- users navigate: they first identify the target line, press the prefix key
-- to narrow down to that line, then press the suffix key for the exact
-- position.
function M.sort_by_distance(targets, cursor)
  local sorted = {}
  for _, t in ipairs(targets) do
    sorted[#sorted + 1] = t
  end
  table.sort(sorted, function(a, b)
    local a_row = math.abs(a.lnum - cursor[1])
    local b_row = math.abs(b.lnum - cursor[1])
    if a_row ~= b_row then
      return a_row < b_row
    end
    return math.abs(a.col - cursor[2]) < math.abs(b.col - cursor[2])
  end)
  return sorted
end

-- Return one target per visible line at column 0.
function M.get_line_start_targets(ctx, lines)
  local targets = {}
  for _, line in ipairs(lines) do
    targets[#targets + 1] = {
      lnum = line.lnum,
      col = 0,
      win = ctx.win,
      buf = ctx.buf,
    }
  end
  return targets
end

-- Return one target at the start of every word on each visible line.
-- A "word start" is a position where a word character appears after a
-- non-word character (or at column 0). This matches Vim's \<\w pattern.
function M.get_word_start_targets(ctx, lines)
  -- \w\+ matches one full word, so the match end advances past the entire
  -- word. The target is placed at the start of each match.
  local regex = vim.regex('\\<\\w\\+')
  local targets = {}

  for _, line in ipairs(lines) do
    local text = line.text
    local offset = 0

    while offset < #text do
      local s, e = regex:match_str(text:sub(offset + 1))
      if not s then
        break
      end

      targets[#targets + 1] = {
        lnum = line.lnum,
        col = offset + s,
        win = ctx.win,
        buf = ctx.buf,
      }

      -- Advance past the entire word to find the next one.
      offset = offset + e
    end
  end

  return targets
end

return M
