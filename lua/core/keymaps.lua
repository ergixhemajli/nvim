local keymap = vim.keymap.set

-- Auto-closing brackets in insert mode
vim.api.nvim_set_keymap('i', '(', '()<Left>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '[', '[]<Left>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '{', '{}<Left>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '"', '""<Left>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', "'", "''<Left>", { noremap = true, silent = true })

-- Splits
keymap('n', '<C-\\>', ':vsplit<CR>', { desc = 'Vertical split' })
keymap('n', '<C-v>', ':vsplit<CR>', { desc = 'Vertical split' })
keymap('n', '<C-s>', ':split<CR>', { desc = 'Horizontal split' })

-- HTML auto-closing tags
keymap('n', '<C-t>', '<esc>yiwi<lt><esc>ea></><esc>hpF>i', { desc = 'Auto-close HTML tag' })

-- Clear search highlighting
keymap('n', '<C-f>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })

-- Window navigation
keymap('n', '<C-h>', '<C-w>h', { desc = 'Move focus left' })
keymap('n', '<C-l>', '<C-w>l', { desc = 'Move focus right' })
keymap('n', '<C-j>', '<C-w>j', { desc = 'Move focus down' })
keymap('n', '<C-k>', '<C-w>k', { desc = 'Move focus up' })
keymap('n', '<C-w>', ':close<CR>', { desc = 'Close current window' })

-- LSP keymaps
keymap('n', 'gd', vim.lsp.buf.definition, { desc = 'Go to definition' })
keymap('n', 'gh', vim.lsp.buf.hover, { desc = 'Show hover information' })
keymap('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'Code actions' })
keymap('n', '<leader>q', vim.diagnostic.open_float, { desc = 'Show diagnostics' })
keymap('n', '<leader>dl', function() vim.diagnostic.setloclist() end, { desc = 'Diagnostic list' })
keymap('n', '<leader>lf', vim.lsp.buf.format, { desc = 'LSP format' })

-- Plugin keymaps
keymap('n', '<leader>e', ':Oil<CR>', { desc = 'Oil file explorer' })
keymap('n', '<leader>m', ':Mason<CR>', { desc = 'Mason' })
keymap('n', '<leader>ff', ':Telescope find_files<CR>', { desc = 'Find files' })
keymap('n', '<leader>fg', ':Telescope live_grep<CR>', { desc = 'Grep' })
keymap('n', '<leader>fb', ':Telescope buffers<CR>', { desc = 'Buffers' })
keymap('n', '<leader>sr', ':GrugFar<CR>', { desc = 'Search/Replace' })
keymap('n', '<leader>gd', ':DiffviewOpen<CR>', { desc = 'Git diff' })
keymap('n', '<leader>gh', ':DiffviewFileHistory %<CR>', { desc = 'File git history' })
keymap('n', '<leader>gc', ':DiffviewClose<CR>', { desc = 'Close diff' })

-- Opencode keymaps
keymap({ 'n', 'x' }, '<C-a>', function() require('opencode').ask('@this: ', { submit = true }) end, { desc = 'Ask opencode' })
keymap({ 'n', 'x' }, '<C-x>', function() require('opencode').select() end, { desc = 'Select opencode' })
keymap({ 'n', 't' }, '<C-.>', function() require('opencode').toggle() end, { desc = 'Toggle opencode' })
keymap({ 'n', 'x' }, 'go', function() return require('opencode').operator('@this ') end, { desc = 'Add range to opencode', expr = true })
keymap('n', 'goo', function() return require('opencode').operator('@this ') .. '_' end, { desc = 'Add line to opencode', expr = true })
