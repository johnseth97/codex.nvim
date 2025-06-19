vim.cmd 'set rtp+=.'
vim.cmd 'set rtp+=./plenary.nvim' -- if using as a submodule or symlinked
require 'plugin.codex' -- triggers plugin/gh_dash.lua
vim.opt.runtimepath:append(vim.fn.getcwd())
vim.opt.runtimepath:append(vim.fn.stdpath 'data' .. '/site/pack/deps/start/plenary.nvim')
