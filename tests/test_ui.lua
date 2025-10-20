local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality

local child = MiniTest.new_child_neovim()

-- Define main test set of this file
local T = new_set({
  -- Register hooks
  hooks = {
    -- This will be executed before every (even nested) case
    pre_case = function()
      -- Restart child process with custom 'init.lua' script
      child.restart({ "-u", "scripts/minimal_init.lua" })
      -- Set editor dimensions for predictable window size
      child.o.columns = 100
      child.o.lines = 40
      -- Load tested module
      child.lua([[ui = require('askCode.ui')]])
    end,
    -- This will be executed one after all tests from this set are finished
    post_once = child.stop,
  },
})

-- Test set for create_floating_window
T["create_floating_window()"] = new_set()

T["create_floating_window()"]["creates a floating window with correct dimensions"] = function()
  -- Get current window handle
  local current_win_handle = child.lua_get('vim.api.nvim_get_current_win()')

  -- Execute the function
  child.lua([[ui.create_floating_window()]])

  -- Get window and buffer handles
  local win_handle = child.lua_get([[ui.float_win]])
  local buf_handle = child.lua_get([[ui.result_buffer]])

  -- Check if window and buffer are valid
  eq(child.lua_get('vim.api.nvim_win_is_valid(' .. win_handle .. ')'), true)
  eq(child.lua_get('vim.api.nvim_buf_is_valid(' .. buf_handle .. ')'), true)

  -- Get window config
  local win_config = child.lua_get('vim.api.nvim_win_get_config(' .. win_handle .. ')')

  -- Assert window properties
  eq(win_config.relative, "win")
  eq(win_config.win, current_win_handle)
  eq(win_config.width, 70)
  eq(win_config.height, 20)
  eq(win_config.row, 1)
  eq(win_config.col, 0)
  eq(win_config.border, { "╭", "─", "╮", "│", "╯", "─", "╰", "│" })
end

-- Test set for stream_text_to_window
T["stream_text_to_window()"] = new_set()

T["stream_text_to_window()"]["streams text to the window"] = function()
  -- Create the window first
  child.lua([[ui.create_floating_window()]])

  -- Stream some lines
  local lines_to_stream = { "hello", "world" }
  child.lua('ui.stream_text_to_window(...)', { lines_to_stream })

  -- Wait for vim.schedule to execute
  child.lua('vim.loop.sleep(50)')

  -- Verify buffer content
  local buf_handle = child.lua_get([[ui.result_buffer]])
  local buffer_content = child.lua_get('vim.api.nvim_buf_get_lines(' .. buf_handle .. ', 0, -1, false)')
  eq(buffer_content, { "", "hello", "world" })

  -- Verify cursor position
  local win_handle = child.lua_get([[ui.float_win]])
  local cursor_pos = child.lua_get('vim.api.nvim_win_get_cursor(' .. win_handle .. ')')
  eq(cursor_pos[1], 3)
end

T["stream_text_to_window()"]["appends text on multiple calls"] = function()
  -- Create the window first
  child.lua([[ui.create_floating_window()]])

  -- Stream first line
  child.lua('ui.stream_text_to_window(...)', { { "line 1" } })
  child.lua('vim.loop.sleep(50)')

  -- Stream more lines
  child.lua('ui.stream_text_to_window(...)', { { "line 2", "line 3" } })
  child.lua('vim.loop.sleep(50)')

  -- Verify buffer content
  local buf_handle = child.lua_get([[ui.result_buffer]])
  local buffer_content = child.lua_get('vim.api.nvim_buf_get_lines(' .. buf_handle .. ', 0, -1, false)')
  eq(buffer_content, { "", "line 1", "line 2", "line 3" })

  -- Verify cursor position
  local win_handle = child.lua_get([[ui.float_win]])
  local cursor_pos = child.lua_get('vim.api.nvim_win_get_cursor(' .. win_handle .. ')')
  eq(cursor_pos[1], 4)
end

return T
