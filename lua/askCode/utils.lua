M = {}

--- Gets the content of the current buffer.
--- If in visual mode, it returns the selected lines. Otherwise, it returns the whole buffer content.
--- @param mode string the vim mode it's either 'n' for normal or 'v' for visual mode
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

--- Reads the content of a file.
--- @param file_path string The path to the file.
--- @return string The content of the file.
function M.read_file(file_path)
  local file = io.open(file_path, "r")
  if not file then
    return ""
  end
  local content = file:read("*a")
  file:close()
  return content
end

--- Writes content to a file, overwriting existing content.
--- @param file_path string The path to the file.
--- @param content string The content to write.
function M.write_file(file_path, content)
  local file = io.open(file_path, "w")
  if not file then
    return
  end
  file:write(content)
  file:close()
end

--- Appends content to a file.
--- @param file_path string The path to the file.
--- @param content string The content to append.
function M.append_file(file_path, content)
  local file = io.open(file_path, "a")
  if not file then
    return
  end
  file:write(content)
  file:close()
end

--- Deletes a file.
--- @param file_path string The path to the file.
function M.delete_file(file_path)
  os.remove(file_path)
end

--- Parses replacement content from AI response
--- @param response string The full AI response
--- @return table|nil {replacement_content = string, explanation = string} or nil if no replacement found
function M.parse_replacement_response(response)
  local replacement_start = response:find("<REPLACE>")
  if not replacement_start then
    return nil
  end

  local content_start = replacement_start + 9 -- length of "<REPLACE>"
  local replacement_end = response:find("</REPLACE>", content_start)
  if not replacement_end then
    return nil
  end

  local replacement_content = response:sub(content_start, replacement_end - 1)
  -- Remove leading/trailing newlines
  replacement_content = replacement_content:gsub("^%s*\n", ""):gsub("\n%s*$", "")

  -- Build explanation by removing the entire replacement block
  local before_block = response:sub(1, replacement_start - 1)
  local after_block = response:sub(replacement_end + 10) -- length of "</REPLACE>"
  local explanation = before_block .. after_block

  return {
    replacement_content = replacement_content,
    explanation = explanation:gsub("^%s+", ""):gsub("%s+$", ""), -- trim whitespace
  }
end

return M
