-- Core
require('core.options')
require('core.keymaps')

-- Plugin manager (Neovim 0.12+ vim.pack)
-- External plugins: see lua/plugins/spec.lua
-- Custom modules: require() these explicitly
vim.pack.add(require('plugins.spec'))
require('plugins.config')

-- Custom plugins
require('plugins.claude')
require('plugins.md-render')

-- LSP
require('lsp.config')

-- UI
vim.cmd('colorscheme default')
vim.cmd('hi statusline guibg=NONE')

vim.o.background = "dark" -- or "light" for light mode
