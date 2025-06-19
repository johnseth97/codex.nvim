-- run_cov.lua

-- 1) Load LuaRocks (for luacov, etc.)
pcall(require, 'luarocks.loader')

-- 2) Start LuaCov, with tick=true so it flushes periodically
local runner = require 'luacov.runner'
runner.init {
  statsfile = 'luacov.stats.out',
  reportfile = 'luacov.report.out',
  tick = true,
}

-- 3) Helper to invoke Plenary’s harness
local harness = require 'plenary.test_harness'
local function run_tests()
  if type(harness.run) == 'function' then
    harness.run() -- Plenary ≤2023‑11
  else
    harness.test_directory('tests', {}) -- Plenary ≥2023‑12
  end
end

-- 4) Run the tests inside xpcall so we always land in the `finally` block
local ok, err = xpcall(run_tests, debug.traceback)

-- 5) Shutdown LuaCov (flush the stats) *before* we quit Neovim
runner.shutdown()

-- 6) If the harness errored, re‑throw so CI sees a failure
if not ok then
  error('Test runner failed:\n' .. err)
end

-- 7) Quit *all* windows and exit Neovim cleanly
vim.cmd 'qa!'
