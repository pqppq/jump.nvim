-- jump-nvim/defaults.lua
-- Default option values.
--
-- Any key absent from the user-supplied opts table will be looked up here
-- via setmetatable's __index in setup().

return {
  -- Characters used for labels. Home-row keys are placed first so that
  -- targets near the cursor tend to receive shorter labels.
  keys = 'asd' .. 'gh' .. 'kl' .. 'qwertyuiop' .. 'zxcvbnm' .. 'fj',

  -- Key that cancels the jump session.
  quit_key = '<Esc>',

  -- When true, render labels in uppercase for better visibility.
  uppercase_labels = false,
}
