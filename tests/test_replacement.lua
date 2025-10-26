local utils = require("askCode.utils")

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      -- Setup before each test case
    end,
    post_case = function()
      -- Cleanup after each test case
    end,
  },
})

T["parse_replacement_response"] = MiniTest.new_set()

T["parse_replacement_response"]["extracts replacement content correctly"] = function()
  local response = [[
This is an explanation of the code.

<REPLACE>
function hello()
  print("Hello, World!")
end
</REPLACE>

This is additional explanation.
]]

  local result = utils.parse_replacement_response(response)
  
  MiniTest.expect.equality(result.replacement_content, [[function hello()
  print("Hello, World!")
end]])
  
  -- The explanation should have the replacement block removed but may have extra newlines
  MiniTest.expect.equality(result.explanation, "This is an explanation of the code.\n\n\n\nThis is additional explanation.")
end

T["parse_replacement_response"]["returns nil when no replacement block"] = function()
  local response = "This is just a regular response without replacement blocks."
  
  local result = utils.parse_replacement_response(response)
  
  MiniTest.expect.equality(result, nil)
end

T["parse_replacement_response"]["handles multiple replacement blocks"] = function()
  local response = [[
Explanation here.

<REPLACE>
first block
</REPLACE>

More text.

<REPLACE>
second block
</REPLACE>
]]

  local result = utils.parse_replacement_response(response)
  
  -- Should extract the first replacement block
  MiniTest.expect.equality(result.replacement_content, "first block")
end

return T
