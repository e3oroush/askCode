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
      -- Load the plugin or module you are testing
      child.lua([[
        M = require('askCode')
        runner = require('askCode.runner')
        ui = require('askCode.ui')
        utils = require('askCode.utils')
        agents = require('askCode.agents')
        config = require('askCode.config')
      ]])
    end,
    -- After all tests in this set are done, stop the child process
    post_once = child.stop,
  },
})

-- Define a nested test set for a specific function or feature
T["ask"] = new_set()

-- Define a test case for plain text streaming
T["ask"]["should stream plain text response to the window"] = function()
  -- 1. Mock dependencies
  child.lua([[
    -- Set config for plain text
    config.merge_with_default({ output_format = 'text' })

    -- Mock get_buffer_content
    utils.get_buffer_content = function() return "mock buffer content" end

    -- Mock get_agent
    agents.get_agent = function(name)
      return {
        prepare_command = function(question) return "echo 'mocked response'" end
      }
    end

    -- Mock create_floating_window
    ui.create_floating_window = function() end

    -- Mock run_command
    local captured_output = {}
    runner.run_command = function(cmd, on_stdout, on_exit)
      on_stdout(nil, { "mocked response line 1", "mocked response line 2" }, nil)
      on_exit.on_exit()
    end

    -- Mock stream_text_to_window to capture output
    ui.stream_text_to_window = function(lines)
      vim.list_extend(captured_output, lines)
    end

    _G.captured_output = captured_output
  ]])

  -- 2. Execute the function
  child.lua([[M.ask('test question', 'visual')]])

  -- 3. Assert the expected outcome
  local result = child.lua_get("_G.captured_output")
  eq(result, { "mocked response line 1", "mocked response line 2" })
end

-- Define a test case for JSON response
T["ask"]["should parse and stream JSON response to the window"] = function()
  -- 1. Mock dependencies
  child.lua([[
    -- Set config for json
    config.merge_with_default({ output_format = 'json' })

    -- Mock get_buffer_content
    utils.get_buffer_content = function() return "mock buffer content" end

    -- Mock get_agent
    agents.get_agent = function(name)
      return {
        prepare_command = function(question) return "echo 'json response'" end,
        parse_response = function(json_string)
          -- In a real scenario, this would parse JSON. Here we just check the input.
          if json_string == '{"response": "parsed content"}' then
            return "parsed content"
          else
            return nil
          end
        end
      }
    end

    -- Mock create_floating_window
    ui.create_floating_window = function() end

    -- Mock run_command
    local captured_output = {}
    runner.run_command = function(cmd, on_stdout, on_exit)
      on_stdout(nil, { '{"response": "parsed content"}' }, nil)
      on_exit.on_exit()
    end

    -- Mock stream_text_to_window to capture output
    ui.stream_text_to_window = function(lines)
      vim.list_extend(captured_output, lines)
    end

    _G.captured_output = captured_output
  ]])

  -- 2. Execute the function
  child.lua([[M.ask('test question', 'visual')]])

  -- 3. Assert the expected outcome
  local result = child.lua_get("_G.captured_output")
  eq(result, { "parsed content" })
end


return T
