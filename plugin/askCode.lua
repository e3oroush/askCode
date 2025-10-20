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
        require("askCode").ask(question, mode)
      end
    end)
  else
    require("askCode").ask(opts.args, mode)
  end
end, { range = true, nargs = "?" })
