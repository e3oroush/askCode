require("askCode")

vim.api.nvim_create_user_command("AskCode", function(opts)
  local mode
  if opts.range == 0 then
    mode = "n"
  else
    mode = "v"
  end
  if #opts.args == 0 then
    vim.ui.input({ prompt = "Question: " }, function(question)
      if question and question ~= "" then
        require("askCode").ask_or_follow_up(question, mode)
      end
    end)
  else
    require("askCode").ask_or_follow_up(opts.args, mode)
  end
end, { range = true, nargs = "?" })

vim.api.nvim_create_user_command("AskCodeReplace", function(opts)
  local mode
  if opts.range == 0 then
    mode = "n"
  else
    mode = "v"
    -- Store range info in a global variable that can be accessed by get_buffer_content
    vim.g.askcode_range = { start_line = opts.line1, end_line = opts.line2 }
  end
  if #opts.args == 0 then
    vim.ui.input({ prompt = "Replacement request: " }, function(question)
      if question and question ~= "" then
        require("askCode").ask_replace(question, mode)
      end
    end)
  else
    require("askCode").ask_replace(opts.args, mode)
  end
end, { range = true, nargs = "?" })
