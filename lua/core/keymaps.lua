local keymap = vim.keymap.set

-- Auto-closing brackets in insert mode
vim.api.nvim_set_keymap('i', '(', '()<Left>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '[', '[]<Left>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '{', '{}<Left>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '"', '""<Left>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', "'", "''<Left>", { noremap = true, silent = true })

-- Window navigation
keymap('n', '<C-h>', '<C-w>h', { desc = 'Move focus left' })
keymap('n', '<C-l>', '<C-w>l', { desc = 'Move focus right' })
keymap('n', '<C-j>', '<C-w>j', { desc = 'Move focus down' })
keymap('n', '<C-k>', '<C-w>k', { desc = 'Move focus up' })
keymap('n', '<C-w>', ':close<CR>', { desc = 'Close current window' })

-- Splits (Ctrl-based only)
keymap('n', '<C-s>', ':split<CR>', { desc = 'Horizontal split' })
keymap('n', '<C-v>', ':vsplit<CR>', { desc = 'Vertical split' })

-- Toggle terminal mode with Ctrl-Hjkl
keymap('t', '<C-h>', '<C-\\><C-n><C-w>h', { desc = 'Terminal: switch to left window' })
keymap('t', '<C-j>', '<C-\\><C-n><C-w>j', { desc = 'Terminal: switch to below window' })
keymap('t', '<C-k>', '<C-\\><C-n><C-w>k', { desc = 'Terminal: switch to above window' })
keymap('t', '<C-l>', '<C-\\><C-n><C-w>l', { desc = 'Terminal: switch to right window' })

-- HTML auto-closing tag
keymap('n', '<C-t>', '<esc>yiwi<lt><esc>ea></><esc>hpF>i', { desc = 'Auto-close HTML tag' })

-- Clear search highlighting
keymap('n', '<C-f>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })

-- LSP keymaps
keymap('n', 'gd', vim.lsp.buf.definition, { desc = 'Go to definition' })
keymap('n', 'gh', vim.lsp.buf.hover, { desc = 'Show hover information' })
keymap('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'Code actions' })
keymap('n', '<leader>q', vim.diagnostic.open_float, { desc = 'Show diagnostics' })
keymap('n', '<leader>dl', function() vim.diagnostic.setloclist() end, { desc = 'Diagnostic list' })
keymap('n', '<leader>lf', vim.lsp.buf.format, { desc = 'LSP format' })

-- Plugin keymaps
keymap('n', '<leader>e', ':Oil<CR>', { desc = 'Oil file explorer' })
keymap('n', '<leader>mc', ':Mason<CR>', { desc = 'Mason' })
keymap('n', '<leader>ff', ':Telescope find_files<CR>', { desc = 'Find files' })
keymap('n', '<leader>fg', ':Telescope live_grep<CR>', { desc = 'Grep' })
keymap('n', '<leader>fb', ':Telescope buffers<CR>', { desc = 'Buffers' })
keymap('n', '<leader>sr', ':GrugFar<CR>', { desc = 'Search/Replace' })
keymap('n', '<leader>gd', ':DiffviewOpen<CR>', { desc = 'Git diff' })
keymap('n', '<leader>gh', ':DiffviewFileHistory %<CR>', { desc = 'File git history' })
keymap('n', '<leader>gc', ':DiffviewClose<CR>', { desc = 'Close diff' })
keymap('n', '<leader>oc', ':!code -g %:p<CR>', { desc = 'Open current file in VS Code' })

-- Pi keymaps
keymap('n', '<C-a>', function() require('plugins.pi').ask_input() end, { desc = 'Ask pi' })
keymap('i', '<C-a>', function()
  vim.cmd('stopinsert')
  require('plugins.pi').ask_input()
end, { desc = 'Ask pi' })
keymap('x', '<C-a>', function() require('plugins.pi').ask_with_visual_selection() end, { desc = 'Ask pi with selection' })
keymap('x', '<C-x>', function() require('plugins.pi').send_visual_selection() end, { desc = 'Send selection to pi' })
keymap({ 'n', 't' }, '<C-.>', function() require('plugins.pi').toggle() end, { desc = 'Toggle pi' })

-- Exit terminal mode (does NOT interrupt pi)
keymap('t', '<Esc>', function()
  vim.api.nvim_input('<C-\\><C-n>')
end, { desc = 'Exit terminal mode' })
-- Interrupt pi (or any foreground terminal process)
keymap('t', '<C-c>', function()
  vim.api.nvim_input('\x03')
end, { desc = 'Interrupt terminal process' })
