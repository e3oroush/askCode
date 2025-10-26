local config = require("askCode.config")
local ui = require("askCode.ui")
local runner = require("askCode.runner")
local agents = require("askCode.agents")
local utils = require("askCode.utils")

local M = {}

local state = {
  history_file = nil,
  win_id = nil,
  buf_id = nil,
  display_content = "",
}

--- setup function
---@param cfg? Config
function M.setup(cfg)
  config.merge_with_default(cfg)
end

--- Applies replacement content to the originally selected lines
--- @param replacement_content string The content to replace with
--- @param selection_info table Selection boundaries {start_line, end_line, bufnr}
local function apply_replacement(replacement_content, selection_info)
  local bufnr = selection_info.bufnr
  local start_line = selection_info.start_line
  local end_line = selection_info.end_line

  if not vim.api.nvim_buf_is_valid(bufnr) then
    vim.notify("Original buffer is no longer valid", vim.log.levels.ERROR)
    return
  end

  local replacement_lines = vim.split(replacement_content, "\n")
  vim.api.nvim_buf_set_lines(bufnr, start_line - 1, end_line, false, replacement_lines)

  vim.notify("Replacement applied successfully", vim.log.levels.INFO)
end

--- Constructs a prompt for the AI assistant based on question, mode, and conversation history
--- @param question string The user's question or request
--- @param mode string The current editor mode (visual, normal, etc.)
--- @param history string|nil Previous conversation history, if any
--- @param is_replacement boolean|nil Whether this is a replacement request (default: false)
--- @return string The formatted prompt ready to send to the AI
local function get_full_prompt(question, mode, history, is_replacement)
  local replacement_instruction = ""
  if is_replacement then
    replacement_instruction =
      "\n\nIMPORTANT: Please provide your replacement code wrapped between <REPLACE> and </REPLACE> tags. Include any explanation outside the tags."
  end

  if history and history ~= "" then
    return string.format("%s\n\n--- USER ---\n%s%s", history, question, replacement_instruction)
  else
    local buffer_content = utils.get_buffer_content(mode)
    local filetype = vim.bo.filetype
    return string.format(
      "You're a code assistant without ability to change or edit files. Given the provided context, try to answer user's question. Here is the context for your answer:\nFiletype: %s\nContent:\n---\n%s\n---\n\n--- USER ---\n%s%s",
      filetype,
      buffer_content,
      question,
      replacement_instruction
    )
  end
end

--- Starts a new conversation with an AI agent about selected code
--- Closes any existing conversation and creates a new floating window
--- @param question string The question to ask the AI agent
--- @param mode string The mode context (e.g., visual selection info)
function M.ask(question, mode)
  -- If a conversation is already active, close it.
  if state.win_id and vim.api.nvim_win_is_valid(state.win_id) then
    vim.api.nvim_win_close(state.win_id, true)
  end
  if state.history_file then
    utils.delete_file(state.history_file)
  end

  state.history_file = vim.fn.tempname()
  state.display_content = ""

  local full_prompt = get_full_prompt(question, mode)
  utils.write_file(state.history_file, full_prompt)

  local agent_name = config.current_config.agent
  local agent = agents.get_agent(agent_name)
  if not agent then
    vim.notify("Agent not found: " .. agent_name, vim.log.levels.ERROR)
    return
  end

  -- Create floating window immediately with loading message
  local on_close = function()
    utils.delete_file(state.history_file)
    state.history_file = nil
    state.win_id = nil
    state.buf_id = nil
    state.display_content = ""
  end

  local command = agent.prepare_command(full_prompt)
  state.win_id, state.buf_id = ui.show_in_float("Loading...", on_close)

  local response_lines = {}
  local on_stdout = function(_, data)
    if data then
      for _, line in ipairs(data) do
        table.insert(response_lines, line)
      end
    end
  end

  local on_stderr = function(_, data)
    if data and agent_name == "amazonq" then
      for _, line in ipairs(data) do
        table.insert(response_lines, line)
      end
    end
  end

  local on_exit = function()
    local response = table.concat(response_lines, "\n")
    if agent.parse_response then
      local parsed = agent.parse_response(response)
      if parsed then
        response = parsed
      end
    end
    local agent_response = "\n\n--- AGENT ---\n" .. response
    utils.append_file(state.history_file, agent_response)

    state.display_content = "AGENT: " .. response
    ui.update_float(state.win_id, state.buf_id, state.display_content)
  end

  runner.run_command(
    { "sh", "-c", command },
    on_stdout,
    { on_stderr = on_stderr, on_exit = on_exit, stdout_buffered = true }
  )
end

--- Continues an existing conversation with a follow-up question
--- Appends to the current conversation history and updates the display
--- @param question string The follow-up question to ask
function M.follow_up(question)
  if not state.history_file then
    vim.notify("No active conversation. Start a new one with :AskCode", vim.log.levels.WARN)
    return
  end

  local user_question = "\n\n--- USER ---\n" .. question
  utils.append_file(state.history_file, user_question)

  local history_content = utils.read_file(state.history_file)

  local agent_name = config.current_config.agent
  local agent = agents.get_agent(agent_name)
  if not agent then
    vim.notify("Agent not found: " .. agent_name, vim.log.levels.ERROR)
    return
  end

  -- Calculate cursor position at end of previous answer
  local previous_content_lines = vim.split(state.display_content, "\n")
  local cursor_position = #previous_content_lines + 3 -- +3 for separator lines

  local command = agent.prepare_command(history_content)

  local response_lines = {}
  local on_stdout = function(_, data)
    if data then
      for _, line in ipairs(data) do
        table.insert(response_lines, line)
      end
    end
  end

  local on_stderr = function(_, data)
    if data and agent_name == "amazonq" then
      for _, line in ipairs(data) do
        table.insert(response_lines, line)
      end
    end
  end

  local on_exit = function()
    local response = table.concat(response_lines, "\n")
    if agent.parse_response then
      local parsed = agent.parse_response(response)
      if parsed then
        response = parsed
      end
    end
    local agent_response = "\n\n--- AGENT ---\n" .. response
    utils.append_file(state.history_file, agent_response)

    local new_display_part = string.format("\n\n---\n\nUSER: %s\n\nAGENT: %s", question, response)
    state.display_content = state.display_content .. new_display_part

    ui.update_float(state.win_id, state.buf_id, state.display_content, cursor_position)
  end

  runner.run_command(
    { "sh", "-c", command },
    on_stdout,
    { on_stderr = on_stderr, on_exit = on_exit, stdout_buffered = true }
  )
end

--- Starts a replacement conversation with an AI agent about selected code
--- Shows response in editable window with apply/cancel options
--- @param question string The question to ask the AI agent
--- @param mode string The mode context (e.g., visual selection info)
function M.ask_replace(question, mode)
  -- Only work in visual mode
  local is_visual = mode == "v" or mode == "V" or mode == "\22"
  if not is_visual then
    vim.notify("AskCodeReplace only works with visual selection", vim.log.levels.ERROR)
    return
  end

  -- Store selection info
  local bufnr = vim.api.nvim_get_current_buf()
  local _, start_line, _, _ = unpack(vim.fn.getpos("'<"))
  local _, end_line, _, _ = unpack(vim.fn.getpos("'>"))
  local selection_info = {
    bufnr = bufnr,
    start_line = start_line,
    end_line = end_line,
  }
  local on_close = function()
    -- Cleanup if needed
  end
  local on_apply = function(edited_content)
    local parsed = utils.parse_replacement_response(edited_content)
    if parsed and parsed.replacement_content then
      vim.notify("replacing")
      apply_replacement(parsed.replacement_content, selection_info)
    else
      vim.notify("No replacement block found in edited content", vim.log.levels.WARN)
    end
  end

  local full_prompt = get_full_prompt(question, mode, nil, true)

  local agent_name = config.current_config.agent
  local agent = agents.get_agent(agent_name)
  if not agent then
    vim.notify("Agent not found: " .. agent_name, vim.log.levels.ERROR)
    return
  end

  local command = agent.prepare_command(full_prompt)
  state.display_content = "Press Q to apply replacement, q to cancel\n\n"
  state.win_id, state.buf_id = ui.show_in_float(state.display_content, on_close, true, on_apply)

  local response_lines = {}
  local on_stdout = function(_, data)
    if data then
      for _, line in ipairs(data) do
        table.insert(response_lines, line)
      end
    end
  end

  local on_stderr = function(_, data)
    if data and agent_name == "amazonq" then
      for _, line in ipairs(data) do
        table.insert(response_lines, line)
      end
    end
  end

  local on_exit = function()
    local response = table.concat(response_lines, "\n")
    if agent.parse_response then
      local parsed = agent.parse_response(response)
      if parsed then
        response = parsed
      end
    end

    state.display_content = state.display_content .. response
    ui.update_float(state.win_id, state.buf_id, state.display_content, nil, true)
  end

  runner.run_command(
    { "sh", "-c", command },
    on_stdout,
    { on_stderr = on_stderr, on_exit = on_exit, stdout_buffered = true }
  )
end

function M.ask_or_follow_up(question, mode)
  if not state.history_file or not (state.win_id and vim.api.nvim_win_is_valid(state.win_id)) then
    M.ask(question, mode)
  else
    M.follow_up(question)
  end
end

return M
