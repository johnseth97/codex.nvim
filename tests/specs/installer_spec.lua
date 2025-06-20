local a = require 'plenary.async.tests'

describe('codex.nvim cold start installer flow', function()
  before_each(function()
    vim.cmd 'set noswapfile'
    vim.cmd 'silent! bwipeout!'

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
end)
