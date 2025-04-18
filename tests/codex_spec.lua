-- tests/codex_spec.lua
-- luacheck: globals describe it assert eq
-- luacheck: ignore a            -- “a” is imported but unused
local a = require("plenary.async.tests")
local eq = assert.equals

describe("codex.nvim", function()
	before_each(function()
		vim.cmd("set noswapfile") -- prevent side effects
		vim.cmd("silent! bwipeout!") -- close any open codex windows
	end)

	it("loads the module", function()
		local ok, codex = pcall(require, "codex")
		assert(ok, "codex module failed to load")
		assert(codex.open, "codex.open missing")
		assert(codex.close, "codex.close missing")
		assert(codex.toggle, "codex.toggle missing")
	end)

	it("creates Codex commands", function()
		require("codex").setup({ keymaps = {} })

		local cmds = vim.api.nvim_get_commands({})
		assert(cmds["Codex"], "Codex command not found")
		assert(cmds["CodexToggle"], "CodexToggle command not found")
	end)

	it("opens a floating terminal window", function()
		require("codex").setup({ cmd = "echo 'test'" })
		require("codex").open()

		local win = vim.api.nvim_get_current_win()
		local buf = vim.api.nvim_win_get_buf(win)
		local ft = vim.api.nvim_buf_get_option(buf, "filetype")
		eq(ft, "codex")

		require("codex").close()
	end)

	it("toggles the window", function()
		require("codex").setup({ cmd = "echo 'test'" })

		require("codex").toggle()
		local win1 = vim.api.nvim_get_current_win()
		assert(vim.api.nvim_win_is_valid(win1), "Codex window should be open")

		require("codex").toggle()
		local still_valid = pcall(vim.api.nvim_win_get_buf, win1)
		assert(not still_valid, "Codex window should be closed")
	end)

	it("shows statusline only when job is active but window is not", function()
		require("codex").setup({ cmd = "sleep 1000" })
		require("codex").open()

		vim.defer_fn(function()
			require("codex").close()
			local status = require("codex").statusline()
			eq(status, "[Codex]")
		end, 100)
	end)
end)
