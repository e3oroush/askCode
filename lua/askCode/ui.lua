local config = require("askCode.config")
local M = {}

--- Creates a floating window to show content.
-- @param content string The content to display.
-- @param on_close function A callback to execute when the window is closed.
-- @return number, number The window ID and buffer ID.
function M.show_in_float(content, on_close)
  local window_config = config.current_config.window

  local width = math.floor(vim.o.columns * window_config.width_ratio)
  if width > window_config.max_width then
    width = window_config.max_width
  end

  local height = math.floor(vim.o.lines * window_config.height_ratio)
  if height > window_config.max_height then
    height = window_config.max_height
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
  local buf_id = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf_id })

  local win_id = vim.api.nvim_open_win(buf_id, true, win_opts)

  -- Set content
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf_id })
  vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, vim.split(content, "\n"))
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf_id })

  -- Keymap to close
  vim.keymap.set("n", config.current_config.quit_key, function()
    if vim.api.nvim_win_is_valid(win_id) then
      vim.api.nvim_win_close(win_id, true)
    end
    if on_close then
      on_close()
    end
  end, { buffer = buf_id })

  return win_id, buf_id
end

--- Updates the content of a floating window.
-- @param win_id number The ID of the window to update.
-- @param buf_id number The ID of the buffer to update.
-- @param content string The new content.
-- @param cursor_line number|nil Optional line number to position cursor (defaults to end).
function M.update_float(win_id, buf_id, content, cursor_line)
  vim.schedule(function()
    if not (buf_id and vim.api.nvim_buf_is_valid(buf_id)) then
      return
    end
    if not (win_id and vim.api.nvim_win_is_valid(win_id)) then
      return
    end

    vim.api.nvim_set_option_value("modifiable", true, { buf = buf_id })
    vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, vim.split(content, "\n"))
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf_id })

    -- Position cursor
    local line_count = vim.api.nvim_buf_line_count(buf_id)
    local target_line = cursor_line or line_count
    vim.api.nvim_win_set_cursor(win_id, { target_line, 0 })
  end)
end

return M
