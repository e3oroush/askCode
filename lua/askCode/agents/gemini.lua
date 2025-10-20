-- lua/askCode/agents/gemini.lua

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
  return string.format("echo %s | gemini", escaped_prompt)
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

  return result
end

return M
