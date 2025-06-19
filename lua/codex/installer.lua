-- lua/codex/installer.lua
local state = require 'codex.state'
local M = {}
M.__test_ignore_path_check = false -- used in tests to skip path checks

local install_cmds = {
  npm = 'npm install -g @openai/codex',
  pnpm = 'pnpm add -g @openai/codex',
  yarn = 'yarn global add @openai/codex',
  bun = 'bun add -g @openai/codex',
  deno = [[deno install --global --allow-all -f --name codex npm:@openai/codex]],
}

local fallback_instructions = {
  pnpm = [[
    pnpm installed successfully, but Codex may not be in your PATH.
    Run `pnpm setup`, then restart your shell or add the output of `pnpm bin -g` to your PATH.
  ]],
  yarn = [[
    Yarn installed Codex, but the CLI may not be in your PATH.

    Try running:
      export PATH="$(yarn global bin):$PATH"

    You can also add it to your shell config file (e.g. .zshrc).
  ]],
  bun = [[
    Bun installed Codex, but it may not be available in your PATH.

    To fix:
      export BUN_INSTALL="$HOME/.bun"
      export PATH="$BUN_INSTALL/bin:$PATH"

    Then restart your shell or add it to your .bashrc/.zshrc.
  ]],
  deno = [[
    Deno installed Codex, but it may not be in your PATH.

    To fix:
      export DENO_INSTALL="$HOME/.deno"
      export PATH="$DENO_INSTALL/bin:$PATH"

    Then restart your shell or add it to your .bashrc/.zshrc.
  ]],
}

--- Detect supported global package managers.
---@return string[] available_pms
function M.detect_available_package_managers()
  local pm_list = { 'npm', 'pnpm', 'yarn', 'bun', 'deno' }
  local available = {}

  for _, pm in ipairs(pm_list) do
    if vim.fn.executable(pm) == 1 then
      table.insert(available, pm)
    end
  end

  -- corepack enables yarn/pnpm shims
  if vim.fn.executable 'corepack' == 1 then
    if vim.fn.executable 'pnpm' == 0 then
      os.execute 'corepack enable pnpm'
    end
    if vim.fn.executable 'yarn' == 0 then
      os.execute 'corepack enable yarn'
    end
    for _, pm in ipairs { 'pnpm', 'yarn' } do
      if vim.fn.executable(pm) == 1 and not vim.tbl_contains(available, pm) then
        table.insert(available, pm)
      end
    end
  end

  return available
end

function M.open_install_float()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end

  state.buf = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_buf_set_option(state.buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(state.buf, 'filetype', 'codex')

  local width = math.floor(vim.o.columns * 0.6)
  local height = 10
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  state.win = vim.api.nvim_open_win(state.buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  })
end

--- Run the install command in a floating terminal.
---@param pm string selected package manager
---@param on_success function callback when install completes successfully
function M.run_install(pm, on_success)
  local cmd_str = install_cmds[pm]
  if not cmd_str then
    vim.notify('[codex.nvim] Unsupported package manager: ' .. pm, vim.log.levels.ERROR)
    return
  end

  M.open_install_float()

  state.job = vim.fn.termopen(cmd_str, {
    cwd = vim.loop.cwd(),
    on_exit = function(_, code)
      if code == 0 then
        vim.notify('[codex.nvim] codex CLI installed successfully via ' .. pm, vim.log.levels.INFO)
        if not M.__test_ignore_path_check and vim.fn.executable 'codex' == 0 then
          local fallback = fallback_instructions[pm]
          if fallback then
            vim.notify('[codex.nvim] CLI not yet available on PATH.\n' .. fallback, vim.log.levels.WARN)
          else
            vim.notify('[codex.nvim] CLI not found in PATH after install. Try restarting your shell.', vim.log.levels.WARN)
          end
        end
        if on_success then
          vim.schedule(on_success)
        end
      else
        vim.notify('[codex.nvim] Installation failed via ' .. pm, vim.log.levels.ERROR)
        if not M.__test_ignore_path_check then
          vim.schedule(function()
            vim.cmd 'cquit 1'
          end)
        end
      end
      state.job = nil
    end,
  })
end

--- Prompt the user to select a package manager and run the install.
---@param on_done fun(success: boolean)
function M.prompt_autoinstall(on_done)
  local pms = M.detect_available_package_managers()
  if #pms == 0 then
    on_done(false)
    return
  end

  vim.schedule(function()
    vim.ui.select(pms, {
      prompt = 'Select package manager to install @openai/codex:',
      kind = 'codex-install',
    }, function(choice)
      if not choice then
        on_done(false)
        return
      end
      M.run_install(choice, function()
        if state.win and vim.api.nvim_win_is_valid(state.win) then
          vim.api.nvim_win_close(state.win, true)
          state.win = nil
        end
        on_done(true)
      end)
    end)
  end)
end

return M
