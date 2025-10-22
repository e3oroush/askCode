---@class Config
---@field agent string
---@field debug boolean
---@field quit_key string
---@field output_format string

local M = {}

---@type Config config
M.default = {
  agent = "gemini",
  debug = false,
  quit_key = "q",
  output_format = "json",
}

--- updates config
---@param changes? Config
---@return Config
function M.merge_with_default(changes)
  changes = changes or {}

  -- merge basic settings
  ---@type Config
  local config = vim.tbl_deep_extend("force", M.default, changes)
  M.current_config = config
  return M.current_config
end

M.current_config = M.default

return M
