local vim = vim

local M = {}

local config = {
  keymaps = {},
  border = 'single',
  width = 0.8,
  height = 0.8,
  cmd = 'codex',
  -- whether to auto-install the codex CLI if not found (requires npm)
  autoinstall = false,
}

local state = {
  buf = nil,
  win = nil,
  job = nil,
}

function M.setup(user_config)
  config = vim.tbl_deep_extend('force', config, user_config or {})
  -- define commands for toggling the Codex popup
  vim.api.nvim_create_user_command('Codex', function() M.toggle() end, { desc = 'Toggle Codex popup' })
  vim.api.nvim_create_user_command('CodexToggle', function() M.toggle() end, { desc = 'Toggle Codex popup (alias)' })
  -- optional keymap for toggle
  if config.keymaps.toggle then
    vim.api.nvim_set_keymap('n', config.keymaps.toggle, '<cmd>CodexToggle<CR>', { noremap = true, silent = true })
  end
end

-- Create a floating window displaying the codex buffer
local function open_window()
  -- compute dimensions and position
  local width = math.floor(vim.o.columns * config.width)
  local height = math.floor(vim.o.lines * config.height)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  -- resolve border style (string or table)
  local border = config.border
  if type(border) == 'string' then
    local styles = {
      single = { {'╭','FloatBorder'},{'─','FloatBorder'},{'╮','FloatBorder'},{'│','FloatBorder'},{'╯','FloatBorder'},{'─','FloatBorder'},{'╰','FloatBorder'},{'│','FloatBorder'} },
      double = { {'╔','FloatBorder'},{'═','FloatBorder'},{'╗','FloatBorder'},{'║','FloatBorder'},{'╝','FloatBorder'},{'═','FloatBorder'},{'╚','FloatBorder'},{'║','FloatBorder'} },
      rounded = { {'╭','FloatBorder'},{'─','FloatBorder'},{'╮','FloatBorder'},{'│','FloatBorder'},{'╯','FloatBorder'},{'─','FloatBorder'},{'╰','FloatBorder'},{'│','FloatBorder'} },
      none = nil,
    }
    border = styles[border] or styles.single
  end
  -- open floating window
  state.win = vim.api.nvim_open_win(state.buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = border,
  })
end

function M.open()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_set_current_win(state.win)
    return
  end
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    -- create an unlisted scratch buffer for the terminal
    state.buf = vim.api.nvim_create_buf(false, false)
    -- buffer options
    vim.api.nvim_buf_set_option(state.buf, 'bufhidden', 'hide')
    vim.api.nvim_buf_set_option(state.buf, 'swapfile', false)
    vim.api.nvim_buf_set_option(state.buf, 'filetype', 'codex')
    -- map <Esc> in terminal and normal modes to close the Codex window
    vim.api.nvim_buf_set_keymap(state.buf, 't', '<Esc>', [[<C-\><C-n><cmd>lua require('codex').close()<CR>]], { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(state.buf, 'n', '<Esc>', [[<cmd>lua require('codex').close()<CR>]], { noremap = true, silent = true })
  end
  open_window()
  -- determine if config.cmd is a simple executable name (no args) for checking
  local check_cmd = nil
  if type(config.cmd) == 'string' then
    -- treat as simple executable if no whitespace (no args)
    if not config.cmd:find('%s') then
      check_cmd = config.cmd
    end
  elseif type(config.cmd) == 'table' and #config.cmd > 0 then
    check_cmd = config.cmd[1]
  end
  -- if simple command and not found, handle auto-install or notify
  if check_cmd and vim.fn.executable(check_cmd) == 0 then
    if config.autoinstall then
      if vim.fn.executable('npm') == 1 then
        -- install via npm in the floating terminal to show output
        do
          local shell_cmd = vim.o.shell or 'sh'
          local cmd = { shell_cmd, '-c', "echo 'Autoinstalling OpenAI Codex via npm...'; npm install -g @openai/codex" }
          state.job = vim.fn.termopen(cmd, {
            cwd = vim.loop.cwd(),
            on_exit = function(_, exit_code)
              if exit_code == 0 then
                vim.notify('[codex.nvim] codex CLI installed successfully', vim.log.levels.INFO)
                -- automatically re-launch codex CLI now that it's installed
                vim.schedule(function()
                  M.close()
                  state.buf = nil
                  M.open()
                end)
              else
                vim.notify('[codex.nvim] failed to install codex CLI', vim.log.levels.ERROR)
              end
              state.job = nil
            end,
          })
        end
      else
        -- show installation instructions in the Codex popup
        local msg = {
          'npm not found; cannot auto-install Codex CLI.',
          '',
          'Please install via your system package manager, or manually run:',
          '  npm install -g @openai/codex',
        }
        vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, msg)
      end
    else
      -- show instructions inline when autoinstall is disabled
      local msg = {
        'Codex CLI not found.',
        '',
        'Install with:',
        '  npm install -g @openai/codex',
        '',
        'Or enable autoinstall in your plugin setup:',
        '  require("codex").setup{ autoinstall = true }',
      }
      vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, msg)
    end
    return
  end
  -- spawn the Codex CLI in the floating terminal buffer
  if not state.job then
    state.job = vim.fn.termopen(config.cmd, {
      cwd = vim.loop.cwd(),
      on_exit = function()
        state.job = nil
      end,
    })
  end
end

function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
    state.win = nil
  end
end

function M.toggle()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    M.close()
  else
    M.open()
  end
end

function M.statusline()
  if state.job and not (state.win and vim.api.nvim_win_is_valid(state.win)) then
    return '[Codex]'
  end
  return ''
end

return M
