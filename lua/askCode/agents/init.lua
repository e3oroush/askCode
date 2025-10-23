local M = {}

---@class Agent
---@field prepare_command function
---@field parse_response function

M.agents = {
  gemini = require("askCode.agents.gemini"),
  amazonq = require("askCode.agents.amazonq"),
}

---@param name string The name of the agent to get.
---@return Agent? The agent module.
function M.get_agent(name)
  return M.agents[name]
end

return M
