local a = require 'plenary.async.tests'

if vim.env.CI then
  describe('installer_spec', function()
    pending 'Skipping installer_spec in CI due to unreliable global path availability'
  end)
  return
end

describe('codex.nvim cold start installer flow', function()
  before_each(function()
    vim.cmd 'set noswapfile'

    -- Mock termopen to simulate successful install
    vim.fn.termopen = function(_, opts)
      if type(opts.on_exit) == 'function' then
        vim.defer_fn(function()
          opts.on_exit(0)
        end, 10)
      end
      return 42 -- fake job id
    end

    -- Stub UI select to simulate choosing npm
    vim.ui.select = function(items, _, on_choice)
      on_choice 'npm'
    end
  end)

  it('installs via selected PM and opens the window', function()
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
  end)
end)
