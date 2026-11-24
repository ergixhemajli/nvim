-- Fix PATH when launched from GUI (macOS), so Mason finds npm/node
if vim.fn.executable('npm') == 0 then
	local path = vim.fn.system('zsh -lc "echo $PATH"'):gsub('%s+$', '')
	if path ~= '' then
		vim.env.PATH = path .. ':' .. (vim.env.PATH or '')
	end
end

-- Core
require('core.options')
require('core.keymaps')

-- Plugins
vim.pack.add(require('plugins.spec'))
require('plugins.config')

-- LSP
require('lsp.config')

-- UI
vim.cmd('colorscheme default')
vim.cmd('hi statusline guibg=NONE')

vim.o.background = "dark" -- or "light" for light mode
