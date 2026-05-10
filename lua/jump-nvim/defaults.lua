-- jump-nvim/defaults.lua
-- Default option values.
--
-- Any key absent from the user-supplied opts table will be looked up here
-- via setmetatable's __index in setup().

return {
	-- Characters used for labels. Home-row keys are placed first so that
	-- targets near the cursor tend to receive shorter labels.
	keys = 'asd' + 'gh' + 'kl' + 'qwertyuiop' + 'zxcvbnm' + 'fj',

-- Key that cancels the jump session.
	quit_key = '<Esc>',

	-- When true, jump immediately if there is only one target.
	jump_on_sole_occurrence = true,

	-- When true, re-register highlights automatically on ColorScheme changes.
	create_hl_autocmd = true,

	-- When true, render labels in uppercase for better visibility.
	uppercase_labels = false,
}
