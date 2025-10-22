local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality

local child = MiniTest.new_child_neovim()

-- Define main test set for this file
local T = new_set({
  hooks = {
    pre_case = function()
      -- Restart child process with custom 'init.lua' script
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua([[Agent = require('askCode.agents.gemini')]])
    end,
    -- This will be executed one after all tests from this set are finished
    post_once = child.stop,
  },
})

-- Test set for the 'setup' function
T["setup"] = new_set()

T["setup"]["should merge custom config"] = function()
  child.lua([[
    Agent.setup({ model = 'gemini-pro' })
  ]])
  local config = child.lua_get([[Agent.config]])
  eq(config, { model = "gemini-pro" })
end

-- Test set for the 'prepare_command' function
T["prepare_command"] = new_set()

T["prepare_command"]["should return correct command for simple prompt"] = function()
  local command = child.lua_get([[Agent.prepare_command('hello')]])
  eq(command, "echo 'hello' | gemini --output-format json")
end

T["prepare_command"]["should handle special characters in prompt"] = function()
  local command = child.lua_get([[Agent.prepare_command("a'b;c")]])
  eq(command, [[echo 'a'\''b;c' | gemini --output-format json]])
end

-- Test set for the 'ask' function
T["ask"] = new_set()

T["ask"]["should return mocked output on success"] = function()
  child.lua([[
    _G.original_popen = io.popen
    io.popen = function(command)
      local expected_command = Agent.prepare_command('hello')
      if command ~= expected_command then
        error(string.format("Unexpected command. Got: '%s', Expected: '%s'", command, expected_command))
      end
      return {
        read = function() return '{"response": "mocked response"}' end,
        close = function() end,
      }
    end
  ]])

  local response = child.lua_get([[Agent.ask('hello')]])
  eq(response, "mocked response")
  child.lua([[io.popen = _G.original_popen]])
end

T["ask"]["should return nil when command fails"] = function()
  child.lua([[
    _G.original_popen = io.popen
    io.popen = function(command)
      return nil
    end
  ]])

  local response = child.lua_get([[Agent.ask('any prompt')]])
  eq(response, vim.NIL)
  child.lua([[io.popen = _G.original_popen]])
end

return T
