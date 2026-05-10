-- jump-nvim/label.lua
-- Assigns key labels to jump targets.
--
-- A hint pairs a target with the key sequence the user must type to jump there:
--   { target = { lnum, col, win, buf }, label = "a" | "ab" }
--
-- Label assignment strategy:
--   targets are pre-sorted by distance (closest first), so closer targets
--   naturally receive shorter (1-char) labels.
--
--   Given K available keys and N targets:
--   - Reserve P keys as "prefix" keys for 2-char labels.
--   - The remaining (K-P) keys are used as 1-char labels for the closest targets.
--   - The P prefix keys each pair with all K keys to form P*K 2-char labels.
--   - Total capacity: (K-P) + P*K = K + P*(K-1)
--   - P is the minimum value that satisfies capacity >= N.
--
-- Directional assignment (assign_directional):
--   2-char labels are split by direction relative to the cursor.
--   Above-cursor targets and below-cursor targets receive disjoint prefix
--   keys, so pressing a prefix key narrows candidates to a single direction.
--   Closest targets (regardless of direction) still get 1-char labels.
--
--   Key layout:
--     keys[1 .. Pa]              — prefix keys for above
--     keys[Pa+1 .. Pa+Pb]        — prefix keys for below
--     keys[Pa+Pb+1 .. K]         — 1-char labels (closest targets)
--   Suffix keys for all 2-char labels use the full K keys.

local M = {}

-- Find the minimum number of prefix keys needed to label all targets.
local function prefix_count(n_targets, n_keys)
  local p = 0
  -- Each additional prefix key adds (n_keys - 1) capacity
  -- (it converts one 1-char slot into n_keys 2-char slots)
  while n_keys + p * (n_keys - 1) < n_targets do
    p = p + 1
    if p >= n_keys then
      return p -- all keys become prefixes; may not cover all targets
    end
  end
  return p
end

-- Assign labels to targets and return a list of hints.
-- targets: list of targets sorted by distance (closest first)
-- keys:    string of available key characters
--
-- Returns a list of { target, label } where hints[i].target == targets[i].
-- Returns an empty table if targets is empty.
function M.assign(targets, keys)
  local n = #targets
  local k = #keys
  if n == 0 then
    return {}
  end

  local p = prefix_count(n, k)
  local hints = {}
  local idx = 1 -- current target index

  -- 1-char labels: use keys[p+1 .. k] for the closest targets
  for i = p + 1, k do
    if idx > n then
      break
    end
    hints[idx] = { target = targets[idx], label = keys:sub(i, i) }
    idx = idx + 1
  end

  -- 2-char labels: keys[1..p] are prefixes, each paired with all k keys
  for i = 1, p do
    for j = 1, k do
      if idx > n then
        break
      end
      hints[idx] = { target = targets[idx], label = keys:sub(i, i) .. keys:sub(j, j) }
      idx = idx + 1
    end
  end

  return hints
end

-- Assign labels with directional separation for 2-char labels.
-- targets:    list of targets sorted by distance (closest first)
-- cursor_row: 0-indexed row of the cursor
-- keys:       string of available key characters
--
-- When all targets fit in 1-char labels (N <= K), falls back to assign().
-- Otherwise, the closest targets get 1-char labels and the remaining targets
-- are split into above/below groups with disjoint prefix keys.
function M.assign_directional(targets, cursor_row, keys)
  local k = #keys
  local n = #targets
  if n == 0 then
    return {}
  end

  -- All targets fit in 1-char labels — no directional split needed.
  if n <= k then
    return M.assign(targets, keys)
  end

  -- Iteratively find the stable split between 1-char and 2-char labels.
  -- Each iteration: split the tail targets by direction, compute the prefix
  -- keys needed per direction, and derive the 1-char budget.
  -- n_1char decreases monotonically, so this always converges.
  local n_1char = k
  local p_above, p_below = 0, 0

  for _ = 1, k do
    local na, nb = 0, 0
    for i = n_1char + 1, n do
      if targets[i].lnum < cursor_row then
        na = na + 1
      elseif targets[i].lnum > cursor_row then
        nb = nb + 1
      else
        -- Current-line overflow: assign to the smaller direction group.
        if na <= nb then
          na = na + 1
        else
          nb = nb + 1
        end
      end
    end

    p_above = na > 0 and math.ceil(na / k) or 0
    p_below = nb > 0 and math.ceil(nb / k) or 0
    local new_1char = math.max(0, k - p_above - p_below)

    if new_1char == n_1char then
      break
    end
    n_1char = new_1char
  end

  -- Build the above / below target lists for 2-char assignment.
  local above = {}
  local below = {}
  for i = n_1char + 1, n do
    if targets[i].lnum < cursor_row then
      above[#above + 1] = targets[i]
    elseif targets[i].lnum > cursor_row then
      below[#below + 1] = targets[i]
    else
      if #above <= #below then
        above[#above + 1] = targets[i]
      else
        below[#below + 1] = targets[i]
      end
    end
  end

  local hints = {}

  -- 1-char labels: keys[p_above + p_below + 1 .. k]
  local one_char_start = p_above + p_below
  for i = 1, n_1char do
    local key_pos = one_char_start + i
    if key_pos <= k then
      hints[#hints + 1] = { target = targets[i], label = keys:sub(key_pos, key_pos) }
    end
  end

  -- Above 2-char: prefix keys[1 .. p_above], suffix all k keys
  local ti = 1
  for p = 1, p_above do
    local prefix = keys:sub(p, p)
    for s = 1, k do
      if ti > #above then
        break
      end
      hints[#hints + 1] = { target = above[ti], label = prefix .. keys:sub(s, s) }
      ti = ti + 1
    end
  end

  -- Below 2-char: prefix keys[p_above + 1 .. p_above + p_below], suffix all k keys
  ti = 1
  for p = p_above + 1, p_above + p_below do
    local prefix = keys:sub(p, p)
    for s = 1, k do
      if ti > #below then
        break
      end
      hints[#hints + 1] = { target = below[ti], label = prefix .. keys:sub(s, s) }
      ti = ti + 1
    end
  end

  return hints
end

-- Filter hints to those whose label starts with `key`, then strip that
-- leading character. Used in the key input loop (Step 7).
--
-- Returns { done, hints } where:
--   done  = the matched target if a 1-char label was fully consumed, else nil
--   hints = remaining hints with their label shortened by one character
function M.filter_hints(hints, key)
  local remaining = {}
  for _, h in ipairs(hints) do
    if h.label:sub(1, 1) == key then
      if #h.label == 1 then
        -- Label fully consumed: this is the target to jump to
        return h.target, {}
      end
      remaining[#remaining + 1] = { target = h.target, label = h.label:sub(2) }
    end
  end
  return nil, remaining
end

return M
