local config = require("askCode.config")
local M = {}

--- Creates a floating window relative to the cursor.
-- The window is used to display results. The size of the window is
-- calculated to be 70% of the editor's dimensions, with a maximum
-- width of 80 columns and a maximum height of 20 lines.
M.create_floating_window = function()
  local width = math.floor(vim.o.columns * 0.7)
  if width > 80 then
    width = 80
  end

  local height = math.floor(vim.o.lines * 0.7)
  if height > 20 then
    height = 20
  end

  local win_opts = {
    relative = "cursor",
    width = width,
    height = height,
    row = 1,
    col = 0,
    style = "minimal",
    border = "rounded",
  }
  local result_buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = result_buffer })
  local float_win = vim.api.nvim_open_win(result_buffer, true, win_opts)
  M.float_win = float_win
  M.result_buffer = result_buffer
  vim.keymap.set("n", config.current_config.quit_key, "<cmd>quit<cr>", { buffer = M.result_buffer })
end

--- Streams lines of text to the floating window's buffer.
-- This function appends the given lines to the end of the buffer
-- associated with the floating window. It ensures the window and buffer
-- are still valid before attempting to modify them. The modification
-- is scheduled to run on the main loop to prevent UI glitches.
---@param lines table A table of strings, where each string is a line to be appended.
M.stream_text_to_window = function(lines)
  vim.schedule(function()
    if not (M.result_buffer and vim.api.nvim_buf_is_valid(M.result_buffer)) then
      return
    end
    if not (M.float_win and vim.api.nvim_win_is_valid(M.float_win)) then
      return
    end

    vim.api.nvim_set_option_value("modifiable", true, { buf = M.result_buffer })
    -- append the lines to the end of buffer
    vim.api.nvim_buf_set_lines(M.result_buffer, -1, -1, false, lines)
    vim.api.nvim_set_option_value("modifiable", false, { buf = M.result_buffer })

    -- Scroll to the bottom to show new content
    local line_count = vim.api.nvim_buf_line_count(M.result_buffer)
    vim.api.nvim_win_set_cursor(M.float_win, { line_count, 0 })
  end)
end

return M
