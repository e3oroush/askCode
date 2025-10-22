local config = require("askCode.config")
local ui = require("askCode.ui")
local runner = require("askCode.runner")
local agents = require("askCode.agents")
local utils = require("askCode.utils")

M = {}

--- setup function
---@param cfg? Config
function M.setup(cfg)
  config.merge_with_default(cfg)
end

local function _create_stream_processor(current_config, agent)
  if current_config.output_format == "json" and agent.parse_response then
    -- JSON processor
    local all_lines = {}
    return {
      handle_data = function(lines)
        vim.list_extend(all_lines, lines)
      end,
      handle_exit = function()
        local full_response = table.concat(all_lines, "\n")
        if full_response == "" then
          return
        end
        local parsed = agent.parse_response(full_response)
        if parsed then
          ui.stream_text_to_window(vim.split(parsed, "\n"))
        else
          ui.stream_text_to_window(all_lines)
        end
      end,
    }
  else
    -- Plain text processor
    return {
      handle_data = function(lines)
        ui.stream_text_to_window(lines)
      end,
      handle_exit = function() end,
    }
  end
end

--- @param question string The question to ask.
function M.ask(question, mode)
  local buffer_content = utils.get_buffer_content(mode)
  local filetype = vim.bo.filetype

  local new_question = string.format(
    "You're a code assistant without ability to change or edit files. Given the provided context, try to answer user's question. Here is the context for your answer:\nFiletype: %s\nContent:\n---\n%s\n---\n\nThe user question is: %s",
    filetype,
    buffer_content,
    question
  )

  ui.create_floating_window()

  local agent_name = config.current_config.agent
  local agent = agents.get_agent(agent_name)

  if not agent then
    vim.notify("Agent not found: " .. agent_name, vim.log.levels.ERROR)
    return
  end

  local command = agent.prepare_command(new_question)
  if config.current_config.debug then
    vim.notify("Running command: " .. command)
  end

  local processor = _create_stream_processor(config.current_config, agent)

  local partial_line = ""
  local on_stdout = function(_, data, _)
    if not data or #data == 0 then
      return
    end

    data[1] = partial_line .. data[1]
    partial_line = ""

    if #data > 0 then
      partial_line = table.remove(data)
    end

    if #data > 0 then
      processor.handle_data(data)
    end
  end

  local on_exit = function()
    if partial_line ~= "" then
      processor.handle_data({ partial_line })
    end
    processor.handle_exit()
  end

  runner.run_command({ "sh", "-c", command }, on_stdout, { on_exit = on_exit })
end

return M
