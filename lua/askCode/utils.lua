M = {}

--- Gets the content of the current buffer.
--- If in visual mode, it returns the selected lines. Otherwise, it returns the whole buffer content.
--- @params mode string the vim mode it's either 'n' for normal or 'v' for visual mode
--- @return string The content of the buffer.
function M.get_buffer_content(mode)
  local is_visual = mode == "v" or mode == "V" or mode == "\22"

  local bufnr = vim.api.nvim_get_current_buf()
  local lines

  if is_visual then
    local _, start_line, _, _ = unpack(vim.fn.getpos("'<"))
    local _, end_line, _, _ = unpack(vim.fn.getpos("'>"))
    lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
  else
    lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  end

  local content = table.concat(lines, "\n")
  return content
end

return M
