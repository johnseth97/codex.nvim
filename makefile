# Makefile for codex.nvim testing and coverage
# Usage:
#   make test      - run unit tests
#   make coverage  - run tests + generate coverage (luacov + lcov.info)

# Force correct Lua version for Neovim (Lua 5.1)

# Headless Neovim test runner
NVIM_TEST_CMD = nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/"

.PHONY: test coverage clean

test:
	@bash -c 'eval "$$(luarocks --lua-version=5.1 path)" && \
	  nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/"'

coverage:
	@bash -c 'eval "$$(luarocks --lua-version=5.1 path)" && \
	  nvim --headless -u tests/minimal_init.lua -c "luafile tests/run_cov.lua" || exit 0 && \
	  if [ -f luacov.stats.out ]; then \
	    echo "::group::Coverage"; \
	    luacov -t LcovReporter; \
	    echo "::endgroup::"; \
	  else \
	    echo "luacov.stats.out not found, skipping coverage report."; \
	  fi'

clean:
	rm -f luacov.stats.out lcov.info
	@echo "Cleaned coverage artifacts"

install-deps:
	luarocks --lua-version=5.1 install --local luacov
	luarocks --lua-version=5.1 install --local luacov-reporter-lcov
	luarocks --lua-version=5.1 install --local luacheck	
	if [ ! -d ~/.local/share/nvim/site/pack/test/start/plenary.nvim ]; then \
		echo "Installing plenary.nvim dependency..."; \
		mkdir -p ~/.local/share/nvim/site/pack/test/start; \
		git clone https://github.com/nvim-lua/plenary.nvim ~/.local/share/nvim/site/pack/test/start/plenary.nvim || true; \
	else \
		echo "plenary.nvim already installed."; \
	fi

