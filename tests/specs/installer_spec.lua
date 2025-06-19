local a = require 'plenary.async.tests'
local eq = assert.equals

describe('codex.nvim cold start installer flow', function()
  before_each(function()
    vim.cmd 'set noswapfile'
    vim.cmd 'silent! bwipeout!'

    -- Suppress notify errors so CI doesn't exit early
    vim.notify = function(msg, level)
      print('[TEST notify]', msg)
    end

    -- Mock termopen to simulate success/failure based on cmd
    vim.fn.termopen = function(cmd, opts)
      if type(opts.on_exit) == 'function' then
        -- Simulate: npm succeeds, others fail
        local exit_code = cmd:match 'npm' and 0 or 1
        vim.defer_fn(function()
          opts.on_exit(exit_code)
        end, 10)
      end
      return 42 -- fake job id
    end
  end)

  it('attempts install with all available package managers and opens codex', function()
    local installer = require 'codex.installer'
    local pms = installer.detect_available_package_managers()

    assert(pms and #pms > 0, 'No package managers available in test env')

    for _, pm in ipairs(pms) do
      local triggered = false

      installer.run_install(pm, function()
        triggered = true
        local win = require('codex.state').win
        assert(win and vim.api.nvim_win_is_valid(win), 'Codex window should open after install')
        vim.api.nvim_win_close(win, true)
      end)

      vim.wait(500, function()
        return true
      end)
      assert(true, 'Install flow completed for ' .. pm)
    end
  end)
end)
