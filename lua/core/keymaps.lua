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

-- Claude keymaps
keymap('n', '<C-a>', function() require('plugins.claude').ask_input() end, { desc = 'Ask claude' })
keymap('i', '<C-a>', function()
  vim.cmd('stopinsert')
  require('plugins.claude').ask_input()
end, { desc = 'Ask claude' })
keymap('x', '<C-a>', function() require('plugins.claude').ask_with_visual_selection() end, { desc = 'Ask claude with selection' })
keymap('x', '<C-x>', function() require('plugins.claude').send_visual_selection() end, { desc = 'Send selection to claude' })
keymap({ 'n', 't' }, '<C-.>', function() require('plugins.claude').toggle() end, { desc = 'Toggle claude' })
keymap('t', '<Esc>', function() -- Exit terminal mode (does NOT interrupt claude)
  vim.api.nvim_input('<C-\\><C-n>')
end, { desc = 'Exit terminal mode' })
keymap('t', '<C-c>', function() -- Interrupt claude (or any foreground terminal process)
  vim.api.nvim_input('\x03')
end, { desc = 'Interrupt terminal process' })

-- Sudo write
local function parse_url(bufname)
  local userhost, path = bufname:match('^oil%-ssh://([^/]+)/(/.+)$')
  return userhost, path
end

vim.api.nvim_create_user_command('SudoWrite', function()
  local bufname = vim.api.nvim_buf_get_name(0)
  local host, remote_path = parse_url(bufname)
  if not host then
    vim.notify('Not a recognized oil-ssh buffer: ' .. bufname, vim.log.levels.ERROR)
    return
  end

  local tmp_local = vim.fn.tempname()
  vim.cmd('write! ' .. tmp_local)

  local tmp_remote = '/tmp/nvim_sudowrite_' .. vim.fn.fnamemodify(tmp_local, ':t')

  -- upload to a scratch path first (no sudo needed, normal user perms on /tmp)
  vim.fn.system({ 'scp', tmp_local, host .. ':' .. tmp_remote })
  if vim.v.shell_error ~= 0 then
    vim.notify('scp upload failed', vim.log.levels.ERROR)
    vim.fn.delete(tmp_local)
    return
  end

  -- floating terminal for the interactive sudo password prompt
  local w, h = vim.o.columns, vim.o.lines
  local ww, wh = 60, 6
  local win = vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), true, {
    relative = 'editor',
    style = 'minimal',
    border = 'single',
    width = ww,
    height = wh,
    col = math.floor((w - ww) / 2),
    row = math.floor((h - wh) / 2),
  })

  local remote_cmd = string.format(
    'sudo cp %s %s && sudo rm -f %s',
    vim.fn.shellescape(tmp_remote),
    vim.fn.shellescape(remote_path),
    vim.fn.shellescape(tmp_remote)
  )

  vim.fn.jobstart({ 'ssh', '-t', host, remote_cmd }, {
    term = true,
    on_exit = function(_, code)
      vim.fn.delete(tmp_local)
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      if code == 0 then
        vim.cmd('checktime')
        vim.notify('Sudo write succeeded', vim.log.levels.INFO)
      else
        vim.notify('Sudo write failed (exit ' .. code .. ')', vim.log.levels.ERROR)
      end
    end,
  })
  vim.cmd('startinsert')
end, { desc = 'Sudo write current oil-ssh buffer to remote host' })
