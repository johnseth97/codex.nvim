pcall(require, 'luarocks.loader')

local runner = require 'luacov.runner'
runner.init {
  statsfile = 'luacov.stats.out',
  reportfile = 'luacov.report.out',
  tick = true,
}

local harness = require 'plenary.test_harness'

-- 🧪 Run tests
local ok, err = xpcall(function()
  if type(harness.run) == 'function' then
    harness.run()
  else
    harness.test_directory('tests', {})
  end
end, debug.traceback)

-- 💾 Flush coverage
runner.shutdown()

-- ✅ Exit logic
if not ok then
  io.stderr:write('Test runner failed:\n', err, '\n')
  os.exit(1)
end

-- 🔁 Final fallback — do not try vim.cmd or cquit; just exit
os.exit(0)
