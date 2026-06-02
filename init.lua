require('core.options')
require('core.keymaps')

vim.pack.add(require('plugins.spec'))
require('plugins.config')

require('lsp.config')

vim.cmd('colorscheme default')
vim.cmd('hi statusline guibg=NONE')
