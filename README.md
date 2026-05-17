# jump.nvim

Lightweight cursor jump plugin for Neovim, inspired by hop.nvim. Jump to any word or line on screen with minimal keystrokes.

## Features

- **JumpWord** — jump to any word start on visible lines
- **JumpWordCurrentLine** — jump to any word start on the current line
- **JumpLine** — jump to the start of any visible line
- Directional prefix separation: pressing a 2-char prefix narrows candidates to above or below the cursor
- Closest targets get single-key labels for instant jumps

## Requirements

- Neovim >= 0.5.0

## Installation

```lua
-- lazy.nvim
{
  "pqppq/jump.nvim",
  event = "VeryLazy",
  opts = {},
  keys = {
    { "<leader>s", "<cmd>JumpLine<cr>", desc = "Jump to line" },
    { "<leader>k", "<cmd>JumpWord<cr>", desc = "Jump to word" },
    { "<leader>l", "<cmd>JumpWordCurrentLine<cr>", desc = "Jump to word on current line" },
  },
}
```

## Configuration

Default values:

```lua
require("jump-nvim").setup({
  -- Characters used for labels (home-row first)
  keys = "asdghklqwertyuiopzxcvbnmfj",
  -- Key to cancel the jump session
  quit_key = "<Esc>",
  -- Jump immediately if there is only one target
  jump_on_sole_occurrence = true,
  -- Re-register highlights on ColorScheme changes
  create_hl_autocmd = true,
  -- Render labels in uppercase
  uppercase_labels = false,
})
```

## Commands

| Command                | Description                             |
| ---------------------- | --------------------------------------- |
| `:JumpWord`            | Jump to word starts on visible lines    |
| `:JumpWordCurrentLine` | Jump to word starts on the current line |
| `:JumpLine`            | Jump to the start of any visible line   |
