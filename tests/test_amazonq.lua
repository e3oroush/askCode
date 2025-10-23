local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality

-- Create an isolated Neovim instance for testing
local child = MiniTest.new_child_neovim()

-- Define the main test set for this file
local T = new_set({
  hooks = {
    -- Before each test case, restart Neovim with a minimal config
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      -- Load the amazonq agent module
      child.lua([[Agent = require('askCode.agents.amazonq')]])
    end,
    -- After all tests in this set are done, stop the child process
    post_once = child.stop,
  },
})

-- Test setup function
T["setup"] = new_set()

T["setup"]["should merge configuration"] = function()
  child.lua([[Agent.setup({ test_option = "test_value" })]])
  local config = child.lua_get([[Agent.config.test_option]])
  eq(config, "test_value")
end

-- Test prepare_command function
T["prepare_command"] = new_set()

T["prepare_command"]["should format command correctly"] = function()
  local command = child.lua_get([[Agent.prepare_command("test prompt")]])
  eq(command, "echo 'test prompt' | q chat --no-interactive")
end

T["prepare_command"]["should escape special characters"] = function()
  local command = child.lua_get([[Agent.prepare_command("test 'quoted' prompt")]])
  eq(command, "echo 'test '\\''quoted'\\'' prompt' | q chat --no-interactive")
end

-- Test parse_response function
T["parse_response"] = new_set()

T["parse_response"]["should return input string"] = function()
  local result = child.lua_get([[Agent.parse_response("test response")]])
  eq(result, "test response")
end

T["parse_response"]["should return nil for empty string"] = function()
  local result = child.lua_get([[Agent.parse_response("")]])
  eq(result, vim.NIL)
end

T["parse_response"]["should return nil for nil input"] = function()
  local result = child.lua_get([[Agent.parse_response(nil)]])
  eq(result, vim.NIL)
end

-- Test ask function with mocked io.popen
T["ask"] = new_set()

T["ask"]["should return response from command"] = function()
  -- Mock io.popen to avoid running the actual 'q' command
  child.lua([[
    local original_popen = io.popen
    io.popen = function(command)
      assert(command == "echo 'test prompt' | q chat --no-interactive")
      return {
        read = function() return "mocked amazonq response" end,
        close = function() end,
      }
    end
  ]])

  local response = child.lua_get([[Agent.ask('test prompt')]])
  eq(response, "mocked amazonq response")

  -- Restore original function
  child.lua([[io.popen = original_popen]])
end

T["ask"]["should return nil when command fails"] = function()
  -- Mock io.popen to return nil (command failure)
  child.lua([[
    local original_popen = io.popen
    io.popen = function(command)
      return nil
    end
  ]])

  local response = child.lua_get([[Agent.ask('test prompt')]])
  eq(response, vim.NIL)

  -- Restore original function
  child.lua([[io.popen = original_popen]])
end

T["ask"]["should return nil for empty response"] = function()
  -- Mock io.popen to return empty response
  child.lua([[
    local original_popen = io.popen
    io.popen = function(command)
      return {
        read = function() return "" end,
        close = function() end,
      }
    end
  ]])

  local response = child.lua_get([[Agent.ask('test prompt')]])
  eq(response, vim.NIL)

  -- Restore original function
  child.lua([[io.popen = original_popen]])
end

return T
