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

local function get_full_prompt(question, mode, history)
  if history and history ~= "" then
    return string.format("%s\n\n--- USER ---\n%s", history, question)
  else
    local buffer_content = utils.get_buffer_content(mode)
    local filetype = vim.bo.filetype
    return string.format(
      "You're a code assistant without ability to change or edit files. Given the provided context, try to answer user's question. Here is the context for your answer:\nFiletype: %s\nContent:\n---\n%s\n---\n\n--- USER ---\n%s",
      filetype,
      buffer_content,
      question
    )
  end
end

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

  state.win_id, state.buf_id = ui.show_in_float("Loading...", on_close)

  local command = agent.prepare_command(full_prompt)

  local response_lines = {}
  local on_stdout = function(_, data)
    if data then
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

  runner.run_command({ "sh", "-c", command }, on_stdout, { on_exit = on_exit, stdout_buffered = true })
end

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

  runner.run_command({ "sh", "-c", command }, on_stdout, { on_exit = on_exit, stdout_buffered = true })
end

function M.ask_or_follow_up(question, mode)
  if not state.history_file or not (state.win_id and vim.api.nvim_win_is_valid(state.win_id)) then
    M.ask(question, mode)
  else
    M.follow_up(question)
  end
end


function M.get_state_for_test()
  return state
end

return M
