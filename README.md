# Codex Neovim Plugin
<img width="1480" alt="image" src="https://github.com/user-attachments/assets/eac126c5-e71c-4de9-817a-bf4e8f2f6af9" />

## A Neovim plugin integrating the open-sourced Codex CLI (`codex`).
> Latest version: ![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/johnseth97/codex.nvim?sort=semver)

### Features:
- ✅ Toggle Codex floating window with `:CodexToggle`
- ✅ Optional keymap mapping via `setup` call
- ✅ Background running when window hidden
- ✅ Statusline integration via `require('codex').status()` 

### Installation:

- Install the `codex` CLI via npm, or mark autoinstall as true in the config function

```bash
npm install -g @openai/codex
```

- Grab an API key from OpenAI and set it in your environment variables:
  - Note: You can also set it in your `~/.bashrc` or `~/.zshrc` file to persist across sessions, but be careful with security. Especially if you share your config files.

```bash
export OPENAI_API_KEY=your_api_key
```

- Use your plugin manager, e.g. lazy.nvim:

```lua
return {
  'johnseth97/codex.nvim',
  lazy = true,
  keys = {
    {
      '<leader>cc',
      function() require('codex').toggle() end,
      desc = 'Toggle Codex popup',
    },
  },
  opts = {
    keymaps     = {},    -- disable internal mapping
    border      = 'rounded', -- or 'double'
    width       = 0.8,
    height      = 0.8,
    autoinstall = true,
  },
}
```

### Usage:
- Call `:Codex` (or `:CodexToggle`) to open or close the Codex popup.
-- Map your own keybindings via the `keymaps.toggle` setting.
- Add the following code to show backgrounded Codex window in lualine:
```lua
require('codex').status() -- drop in to your lualine sections
```
