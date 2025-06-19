# Makefile for codex.nvim testing and coverage
# Usage:
#   make test      - run unit tests
#   make coverage  - run tests + generate coverage (luacov + lcov.info)

# Force correct Lua version for Neovim (Lua 5.1)
LUAROCKS_ENV = eval "$(luarocks --lua-version=5.1 path)"

# Headless Neovim test runner
NVIM_TEST_CMD = nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/specs/"

.PHONY: test coverage clean

test:
	$(LUAROCKS_ENV) && $(NVIM_TEST_CMD)

coverage:
	$(LUAROCKS_ENV) && nvim --headless -u tests/minimal_init.lua -c "luafile tests/run_cov.lua"
	ls -lh luacov.stats.out
	$(LUAROCKS_ENV) && luacov -t LcovReporter
	@echo "Generated coverage report: lcov.info"

clean:
	rm -f luacov.stats.out lcov.info
	@echo "Cleaned coverage artifacts"

install-deps:
	luarocks --lua-version=5.1 install luacov || true
	git clone https://github.com/nvim-lua/plenary.nvim tests/plenary.nvim || true
