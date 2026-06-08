local keymap = vim.keymap.set

-- Auto-closing brackets in insert mode
vim.api.nvim_set_keymap('i', '(', '()<Left>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '[', '[]<Left>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '{', '{}<Left>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '"', '""<Left>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', "'", "''<Left>", { noremap = true, silent = true })

-- Splits
keymap('n', '<leader>v', ':vsplit<CR>', { desc = 'Vertical split' })
keymap('n', '<leader>|', ':vsplit<CR>', { desc = 'Vertical split' })
keymap('n', '<leader>h', ':split<CR>', { desc = 'Horizontal split' })
keymap('n', '<leader>s', ':split<CR>', { desc = 'Horizontal split' })

-- Toggle terminal mode with Ctrl-Hjkl
keymap('t', '<C-h>', '<C-\\><C-n><C-w>h', { desc = 'Terminal: switch to left window' })
keymap('t', '<C-j>', '<C-\\><C-n><C-w>j', { desc = 'Terminal: switch to below window' })
keymap('t', '<C-k>', '<C-\\><C-n><C-w>k', { desc = 'Terminal: switch to above window' })
keymap('t', '<C-l>', '<C-\\><C-n><C-w>l', { desc = 'Terminal: switch to right window' })

-- Pi keymaps
keymap({ 'n', 'x' }, '<C-a>', function() require('plugins.pi').ask_input() end, { desc = 'Ask pi' })
keymap('x', '<C-x>', function() require('plugins.pi').send_visual_selection() end, { desc = 'Send selection to pi' })
keymap({ 'n', 't' }, '<C-.>', '<cmd>PiToggle<CR>', { desc = 'Toggle pi' })

-- Exit terminal mode (does NOT interrupt pi)
keymap('t', '<Esc>', function()
  vim.api.nvim_input('<C-\\><C-n>')
end, { desc = 'Exit terminal mode' })
-- Interrupt pi (or any foreground terminal process)
keymap('t', '<C-c>', function()
  vim.api.nvim_input('\x03')
end, { desc = 'Interrupt terminal process' })
