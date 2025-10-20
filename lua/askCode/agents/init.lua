local M = {}

M.agents = {
  gemini = require("askCode.agents.gemini"),
}

---@param name string The name of the agent to get.
---@return table? The agent module.
function M.get_agent(name)
  return M.agents[name]
end

return M
