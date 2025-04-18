# Codex Neovim Plugin

A Neovim plugin integrating the open-sourced Codex CLI (`codex`).

Features:
- Toggle Codex floating window with `:CodexToggle`
- Optional keymap mapping via `setup` call
- Background running when window hidden
- Statusline integration via `require('codex').statusline()`

Installation:
Use your plugin manager, e.g., with packer.nvim:
```lua
use {
  'johnseth97/codex.nvim',
  config = function()
    require('codex').setup {
      keymaps = { toggle = '<leader>cc' },
      border = 'double',
      width = 0.8,
      height = 0.8,
    }
  end,
}
```
For lazy.nvim:
```lua
return {
  'johnseth97/codex.nvim',
  lazy = true,
  keys = {
    {
      '<leader>cc',
      function()
        require('codex').toggle()
      end,
      desc = 'Toggle Codex popup',
    },
  },
  config = function()
    require('codex').setup {
      keymaps = {}, -- <-- disable internal mapping
      border = 'rounded',
      width = 0.8,
      height = 0.8,
    }
  end,
}
```

Usage:
- Call `:Codex` (or `:CodexToggle`) to open or close the Codex popup.
-- Map your own keybindings via the `keymaps.toggle` setting.
- Add to your statusline:
```vim
set statusline+=%{v:lua.require'codex'.statusline()}
```
