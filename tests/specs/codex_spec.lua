-- tests/codex_spec.lua
-- luacheck: globals describe it assert eq
-- luacheck: ignore a            -- “a” is imported but unused
local a = require 'plenary.async.tests'
local eq = assert.equals

describe('codex.nvim', function()
  before_each(function()
    vim.cmd 'set noswapfile' -- prevent side effects
    vim.cmd 'silent! bwipeout!' -- close any open codex windows
  end)

  it('loads the module', function()
    local ok, codex = pcall(require, 'codex')
    assert(ok, 'codex module failed to load')
    assert(codex.open, 'codex.open missing')
    assert(codex.close, 'codex.close missing')
    assert(codex.toggle, 'codex.toggle missing')
  end)

  it('creates Codex commands', function()
    require('codex').setup { keymaps = {} }

    local cmds = vim.api.nvim_get_commands {}
    assert(cmds['Codex'], 'Codex command not found')
    assert(cmds['CodexToggle'], 'CodexToggle command not found')
  end)

  it('opens a floating terminal window', function()
    require('codex').setup { cmd = { 'echo', 'test' } }
    require('codex').open()

    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.api.nvim_buf_get_option(buf, 'filetype')
    eq(ft, 'codex')

    require('codex').close()
  end)

  it('toggles the window', function()
    require('codex').setup { cmd = { 'echo', 'test' } }

    require('codex').toggle()
    local win1 = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_win_get_buf(win1)

    assert(vim.api.nvim_win_is_valid(win1), 'Codex window should be open')

    print('🔍 buffer modified before toggle:', vim.api.nvim_buf_get_option(buf, 'modified'))

    -- Optional: manually mark it clean
    vim.api.nvim_buf_set_option(buf, 'modified', false)

    require('codex').toggle()

    local ok, _ = pcall(vim.api.nvim_win_get_buf, win1)
    assert(not ok, 'Codex window should be closed')
  end)

  it('shows statusline only when job is active but window is not', function()
    require('codex').setup { cmd = { 'sleep', '1000' } }
    require('codex').open()

    vim.defer_fn(function()
      require('codex').close()
      local status = require('codex').statusline()
      eq(status, '[Codex]')
    end, 100)
  end)

  it('passes -m <model> to termopen when configured', function()
    local original_fn = vim.fn
    local termopen_called = false
    local received_cmd = {}

    -- Mock vim.fn with proxy
    vim.fn = setmetatable({
      termopen = function(cmd, opts)
        termopen_called = true
        received_cmd = cmd
        if type(opts.on_exit) == 'function' then
          vim.defer_fn(function()
            opts.on_exit(0)
          end, 10)
        end
        return 123
      end,
    }, { __index = original_fn })

    -- Reload module fresh
    package.loaded['codex'] = nil
    package.loaded['codex.state'] = nil
    local codex = require 'codex'

    codex.setup {
      cmd = 'codex',
      model = 'o3-mini',
    }

    codex.open()

    vim.wait(500, function()
      return termopen_called
    end, 10)

    assert(termopen_called, 'termopen should be called')
    assert(type(received_cmd) == 'table', 'cmd should be passed as a list')
    assert(vim.tbl_contains(received_cmd, '-m'), 'should include -m flag')
    assert(vim.tbl_contains(received_cmd, 'o3-mini'), 'should include specified model name')

    -- Restore original
    vim.fn = original_fn
  end)
end)
