-- tests/test_utils.lua
local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality

local child = MiniTest.new_child_neovim()

local T = new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua([[Utils = require('askCode.utils')]])
    end,
    post_once = child.stop,
  },
})

T["get_buffer_content"] = new_set()

T["get_buffer_content"]["should return full buffer content in normal mode"] = function()
  child.lua([[ 
    vim.api.nvim_command('new')
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {'line 1', 'line 2', 'line 3'})
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
  ]])
  local content = child.lua_get('Utils.get_buffer_content("n")')
  eq(content, "line 1\nline 2\nline 3")
end

T["get_buffer_content"]["should return selected lines in visual mode"] = function()
  child.lua([[ 
    vim.api.nvim_command('new')
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {'line 1', 'line 2', 'line 3'})
    vim.fn.setpos("'<", {0, 2, 1})
    vim.fn.setpos("'>", {0, 2, 1})
    vim.api.nvim_feedkeys('V', 'v', false)
  ]])
  local content = child.lua_get('Utils.get_buffer_content("v")')
  eq(content, "line 2")
end

return T
