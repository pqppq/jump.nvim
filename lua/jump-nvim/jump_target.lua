-- jump-nvim/jump_target.lua
-- Jump target generation and scoring.
--
-- A jump target is a table representing a single location the cursor can jump to:
--   { lnum, col, win, buf }  -- all values are 0-indexed
--
-- get_xxx_targets(ctx, lines) functions return a list of targets.
-- Additional target types (word, char, pattern, ...) will be added in later steps.

local M = {}

-- Compute the Manhattan distance between a target and the cursor.
-- cursor = { row, col }, both 0-indexed.
local function distance(target, cursor)
  return math.abs(target.lnum - cursor[1]) + math.abs(target.col - cursor[2])
end

-- Return a new list of targets sorted by ascending Manhattan distance from the
-- cursor. Targets closest to the cursor appear first and will receive the
-- shortest (easiest) labels in the assignment step.
function M.sort_by_distance(targets, cursor)
  local sorted = {}
  for _, t in ipairs(targets) do
    sorted[#sorted + 1] = t
  end
  table.sort(sorted, function(a, b)
    return distance(a, cursor) < distance(b, cursor)
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

return M
