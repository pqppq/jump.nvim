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
