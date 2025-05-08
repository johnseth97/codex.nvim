local a = require 'plenary.async.tests'
local eq = assert.equals

describe('codex.nvim cold start installer flow', function()
  before_each(function()
    vim.cmd 'set noswapfile'
    vim.cmd 'silent! bwipeout!'

    -- Mock termopen to simulate successful install
    vim.fn.termopen = function(cmd, opts)
      if type(opts.on_exit) == 'function' then
        vim.defer_fn(function()
          opts.on_exit(0)
        end, 10)
      end
      return 42 -- fake job id
    end
  end)

  local function open_and_install(pm_index)
    local installer = require 'codex.installer'
    local available = installer.detect_available_package_managers()
    if #available < pm_index then
      pending('Skipping test: PM index ' .. pm_index .. ' not available on system')
      return
    end

    local selected_pm = nil
    vim.ui.select = function(items, opts, on_choice)
      selected_pm = items[pm_index]
      on_choice(selected_pm)
    end

    local codex = require 'codex'
    codex.setup {
      cmd = 'codex',
      autoinstall = true,
    }

    codex.open()

    vim.wait(1000, function()
      return require('codex.state').job == nil and require('codex.state').win ~= nil
    end, 10)

    local win = require('codex.state').win
    assert(win and vim.api.nvim_win_is_valid(win), 'Codex window should be open after install')

    codex.close()
    assert(not vim.api.nvim_win_is_valid(win), 'Codex window should be closed')
  end

  for i = 1, 3 do
    it('installs with PM index ' .. i .. ' and relaunches codex', function()
      open_and_install(i)
    end)
  end
end)
