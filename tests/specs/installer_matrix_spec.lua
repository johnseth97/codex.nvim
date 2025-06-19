local a = require 'plenary.async.tests'
local eq = assert.equals

describe('codex.nvim multi-installer matrix flow', function()
  before_each(function()
    vim.cmd 'set noswapfile'
    vim.cmd 'silent! bwipeout!'
    require('codex.installer').__test_ignore_path_check = true -- Skip path checks for tests

    -- Capture notify messages for assertions
    _G.__codex_notify_log = {}
    vim.notify = function(msg, level)
      table.insert(_G.__codex_notify_log, { msg = msg, level = level })
      print('[notify]', msg)
    end

    -- Fake termopen for simulating install results
    vim.fn.termopen = function(cmd, opts)
      local success = cmd:match 'npm' or cmd:match 'pnpm' or cmd:match 'yarn'
      local code = success and 0 or 1
      vim.defer_fn(function()
        if opts.on_exit then
          opts.on_exit(1234, code) -- job_id, exit_code
        end
      end, 10)
      return 1234
    end
  end)

  it('tries each supported PM and handles success/failure gracefully', function()
    local installer = require 'codex.installer'
    local state = require 'codex.state'
    local available = installer.detect_available_package_managers()
    assert(#available > 0, 'No package managers available for test')

    for _, pm in ipairs(available) do
      local triggered = false

      installer.run_install(pm, function()
        triggered = true
        local win = state.win
        assert(win and vim.api.nvim_win_is_valid(win), 'Codex float should open on success')
        vim.api.nvim_win_close(win, true)
        state.win = nil
      end)

      vim.wait(500, function()
        return state.job == nil
      end)

      local success_pms = {
        npm = true,
        pnpm = true,
        yarn = true,
      }

      if not success_pms[pm] then
        assert(found_notice, 'Failure should notify for ' .. pm)
      else
        assert(not found_notice, 'Should not show failure notice for successful PM: ' .. pm)
      end

      local found_notice = false
      for _, entry in ipairs(_G.__codex_notify_log) do
        if entry.msg:match 'Installation failed' and entry.msg:match(pm) then
          found_notice = true
          break
        end
      end

      if pm ~= 'npm' then
        assert(found_notice, 'Failure should notify for ' .. pm)
      end
    end
  end)
end)
