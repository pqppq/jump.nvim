-- jump-nvim/hint.lua
-- Renders jump labels and dimming using Neovim extmarks.
--
-- Two layers of extmarks are placed in a single namespace:
--   1. Dim layer  — covers every visible line with JumpUnmatched (low priority)
--   2. Label layer — overlays each hint position with its key label (high priority)
--
-- Calling clear() removes both layers at once by clearing the namespace.

local M = {}

-- Single namespace shared by all extmarks placed during a jump session.
M.ns = vim.api.nvim_create_namespace('jump-nvim')

-- Priority high enough to override any other plugin's extmarks (e.g. hlchunk.nvim).
-- During a jump session our labels must always be on top.
local PRIORITY_DIM = 65534
local PRIORITY_LABEL = 65535

-- Dim all visible lines by covering them with the JumpUnmatched highlight.
-- Lines that are folded (text == '') are skipped.
function M.dim(buf, lines)
  for _, line in ipairs(lines) do
    if line.text ~= '' then
      vim.api.nvim_buf_set_extmark(buf, M.ns, line.lnum, 0, {
        end_col = #line.text,
        hl_group = 'JumpUnmatched',
        hl_eol = true, -- dim the area after the last character too
        priority = PRIORITY_DIM,
      })
    end
  end
end

-- Build the virt_text table for a label.
-- 1-char label: single pink bold character (JumpNextKey)
-- 2-char label: cyan first char (JumpNextKey1) + blue second char (JumpNextKey2)
local function label_virt_text(label, uppercase)
  local text = uppercase and label:upper() or label
  if #text == 1 then
    return { { text, 'JumpNextKey' } }
  else
    return {
      { text:sub(1, 1), 'JumpNextKey1' },
      { text:sub(2, 2), 'JumpNextKey2' },
    }
  end
end

-- Overlay label extmarks on each hint position.
-- opts.uppercase_labels controls whether labels are rendered in uppercase.
function M.render(hints, opts)
  for _, h in ipairs(hints) do
    local t = h.target
    vim.api.nvim_buf_set_extmark(t.buf, M.ns, t.lnum, t.col, {
      virt_text = label_virt_text(h.label, opts.uppercase_labels),
      virt_text_pos = 'overlay',
      priority = PRIORITY_LABEL,
    })
  end
end

-- Remove all extmarks placed by jump-nvim in the given buffer.
function M.clear(buf)
  vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)
end

return M
