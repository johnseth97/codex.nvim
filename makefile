# Makefile for codex.nvim testing and coverage

# Force correct Lua version for Neovim (Lua 5.1)
LUAROCKS_ENV = eval "$(luarocks --lua-version=5.1 path)"

# Add Lazy-installed plenary.nvim to runtimepath
PLENARY_PATH = ~/.local/share/nvim/lazy/plenary.nvim
EXTRA_RTP = --cmd "set rtp+=$(PLENARY_PATH)"

.PHONY: test coverage clean install-deps

test:
	$(LUAROCKS_ENV) && nvim --headless $(EXTRA_RTP) -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/specs/"

coverage:
	$(LUAROCKS_ENV) && nvim --headless $(EXTRA_RTP) -u tests/minimal_init.lua -c "luafile tests/run_cov.lua"
	ls -lh luacov.stats.out
	$(LUAROCKS_ENV) && luacov -t LcovReporter
	@echo "Generated coverage report: lcov.info"

clean:
	rm -f luacov.stats.out lcov.info
	@echo "Cleaned coverage artifacts"

install-deps:
	luarocks --lua-version=5.1 install luacov || true
	luarocks --lua-version=5.1 install luacov-reporter-lcov || true
	luarocks --lua-version=5.1 install luacheck || true
	if [ ! -d ~/.local/share/nvim/lazy ]; then
		mkdir -p ~/.local/share/nvim/lazy
	fi
	git clone https://github.com/nvim-lua/plenary.nvim ~/.local/share/nvim/lazy/plenary.nvim || true
