vim.g.mapleader = ' '
vim.g.mapLocalLeader = ' '
vim.g.have_nerd_font = true

vim.schedule(function()
	vim.opt.clipboard = 'unnamedplus'
end)

vim.o.swapfile = false
vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = 'a'
vim.o.showmode = true
vim.o.breakindent = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.cursorline = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.termguicolors = true
vim.o.signcolumn = "yes"
vim.o.autoread = true

vim.cmd [[set completeopt+=menuone,noselect,popup]]

vim.api.nvim_create_autocmd('TextYankPost', {
	desc = 'Highlight when yanking (copying) text',
	group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

vim.api.nvim_create_user_command('ReloadConfig', function()
	for name, _ in pairs(package.loaded) do
		if name:match('^core') or name:match('^plugins') or name:match('^lsp') or name:match('^opencode') then
			package.loaded[name] = nil
		end
	end

	dofile(vim.fn.expand('$MYVIMRC'))
	vim.notify('Config reloaded', vim.log.levels.INFO, { title = 'nvim' })
end, { desc = 'Reload Neovim config' })
