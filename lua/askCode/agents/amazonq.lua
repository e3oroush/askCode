local M = {
  config = {},
}

--- Merges the given configuration with the default settings.
--- This function will be used to configure the agent in the future.
--- @param cfg table The configuration table to merge.
function M.setup(cfg)
  M.config = vim.tbl_deep_extend("force", M.config, cfg or {})
end

--- Prepares the shell command for sending a prompt to the AmazonQ CLI.
--- @param prompt string The prompt to be sent.
--- @return string The fully formed shell command.
function M.prepare_command(prompt)
  -- Escape the prompt to ensure it's safely passed to the shell.
  local escaped_prompt = vim.fn.shellescape(prompt)
  return string.format("echo %s | q chat --no-interactive", escaped_prompt)
end

--- Parses the response from the AmazonQ CLI.
--- @param response_string string The response string to parse.
--- @return string? The response, or nil if parsing fails.
function M.parse_response(response_string)
  -- AmazonQ doesn't support JSON yet, so return the input string for consistency
  if not response_string or response_string == "" then
    vim.notify("Empty response from AmazonQ", vim.log.levels.ERROR)
    return nil
  end
  return response_string
end

--- Sends a prompt to the AmazonQ CLI and returns the response.
--- It uses a non-interactive mode by piping the prompt to the CLI.
--- @param prompt string The prompt to send to the AmazonQ CLI.
--- @return string? The response from the CLI, or nil if an error occurred.
function M.ask(prompt)
  local command = M.prepare_command(prompt)

  -- Execute the command and capture the output.
  local handle = io.popen(command)
  if not handle then
    vim.notify("Failed to execute amazonq command", vim.log.levels.ERROR)
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
