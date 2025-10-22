# AskCode.nvim

AskCode is a Neovim plugin that helps developers explore and understand codebases by connecting to CLI-based AI assistants like `gemini-cli` and `amazonq`. It acts as your in-editor guide, letting you ask context-aware questions about selected code and receive answers without leaving Neovim.

✨ **Features**

- **Multi-agent support**: Choose your preferred AI backend (Gemini, AmazonQ, etc.).
- **Configurable**: Select agents and tweak settings via a simple Lua API.
- **Prepared prompts**: Built-in use cases like explaining code, finding bugs, or suggesting optimizations.
- **Extensible**: Add your own agents and custom prompts.
- **Neovim-native UI**: Responses are displayed in floating windows or splits, asynchronously and non-blockingly.

## 🚀 Getting Started

### Prerequisites

- Neovim (v0.9.0 or later)
- A compatible AI assistant CLI installed and configured in your shell environment (e.g., `gemini-cli`, `amazonq`).

### Installation

Install `askCode.nvim` using your favorite package manager.

**Lazy.nvim**

```lua
{
  "askCode/askCode.nvim",
  config = function()
    require("askCode").setup({
      -- Your configuration here
    })
  end,
}
```

**Packer.nvim**

```lua
use {
  "askCode/askCode.nvim",
  config = function()
    require("askCode").setup({
      -- Your configuration here
    })
  end,
}
```

### Basic Configuration

By default, `askCode.nvim` uses `gemini-cli`. You can configure it to use a different agent or customize its behavior.

```lua
-- lua/askCode/config.lua
require("askCode").setup({
  agent = "gemini", -- Or your preferred agent
  },
})
```

## Usage

1.  **Select code**: Select a block of code in visual mode.
2.  **Run a prompt**: Use the `:AskCode <prompt_name>` command, where `<prompt_name>` is one of the configured prompts (e.g., `:AskCode "Explain this code"`).
3.  **View the response**: The AI-generated response will appear in a floating window or split.

You can also map the commands to keybindings for easier access:

```lua
-- Map "Explain this code" to <leader>ae
vim.api.nvim_set_keymap("v", "<leader>ae", ":AskCode "Explain this code"<CR>", { noremap = true, silent = true })

-- Map "Find potential bugs" to <leader>ab
vim.api.nvim_set_keymap("v", "<leader>ab", ":AskCode "Find potential bugs"<CR>", { noremap = true, silent = true })
```

## Development

Contributions are welcome! To get started with development:

1.  **Clone the repository**:

    ```sh
    git clone https://github.com/askCode/askCode.nvim.git
    cd askCode.nvim
    ```

2.  **Set up the development environment**:

    The plugin uses `mini.nvim` for its test framework. The tests can be run using the `make test` command.

3.  **Run the tests**:

    ```sh
    make test
    ```

    This command will run the test suite and ensure that everything is working as expected.

### Test Framework

The project uses `mini.nvim` for its testing framework. You can find more information about it in the [mini.nvim TESTING.md](https://github.com/nvim-mini/mini.nvim/blob/main/TESTING.md) file.

## Todo

- [ ] **Integrate AmazonQ Agent**: Add a new agent for AmazonQ by implementing the `prepare_command` function for its CLI.
- [ ] **Support Streaming JSON**: Improve the stream processor to parse chunked JSON responses for real-time display.
- [ ] **Support Follow-up Questions**: Maintain conversation history to allow for follow-up questions.
- [ ] **Support Prompt Templates**: Allow users to define custom prompt templates in the configuration.
