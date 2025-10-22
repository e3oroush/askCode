local M = {
  config = {},
}

--- Merges the given configuration with the default settings.
--- This function will be used to configure the agent in the future.
--- @param cfg table The configuration table to merge.
function M.setup(cfg)
  M.config = vim.tbl_deep_extend("force", M.config, cfg or {})
end

--- Prepares the shell command for sending a prompt to the Gemini CLI.
--- @param prompt string The prompt to be sent.
--- @return string The fully formed shell command.
function M.prepare_command(prompt)
  -- Escape the prompt to ensure it's safely passed to the shell.
  local escaped_prompt = vim.fn.shellescape(prompt)
  return string.format("echo %s | gemini --output-format json", escaped_prompt)
end

--- Parses the JSON response from the Gemini CLI.
--- @param json_string string The JSON string to parse.
--- @return string? The extracted response, or nil if parsing fails.
function M.parse_response(json_string)
  -- vim.fn.json_decode is not safe, so we need to wrap it in a pcall
  local ok, decoded = pcall(vim.fn.json_decode, json_string)
  if not ok or type(decoded) ~= "table" or not decoded.response then
    vim.notify("Failed to parse Gemini response: " .. tostring(json_string), vim.log.levels.ERROR)
    return nil
  end
  return decoded.response
end

--- Sends a prompt to the Gemini CLI and returns the response.
--- It uses a non-interactive mode by piping the prompt to the CLI.
--- @param prompt string The prompt to send to the Gemini CLI.
--- @return string? The response from the CLI, or nil if an error occurred.
function M.ask(prompt)
  local command = M.prepare_command(prompt)

  -- Execute the command and capture the output.
  local handle = io.popen(command)
  if not handle then
    vim.notify("Failed to execute gemini command", vim.log.levels.ERROR)
    return nil
  end

  local result = handle:read("*a")
  handle:close()

  if result and result ~= "" then
    return M.parse_response(result)
  end

  return nil
end

return M