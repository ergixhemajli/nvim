-- Set map leader and other options
vim.g.mapleader = ' '
vim.g.mapLocalLeader = ' '
vim.g.have_nerd_font = true

vim.schedule(function()
	vim.opt.clipboard = 'unnamedplus'
end)

-- Highlight text when yanking
vim.api.nvim_create_autocmd('TextYankPost', {
	desc = 'Highlight when yanking (copying) text',
	group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- Set editor options
vim.opt.swapfile = false
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.showmode = true
vim.opt.breakindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.cursorline = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"

-- Auto-closing brackets in insert mode
vim.api.nvim_set_keymap('i', '(', '()<Left>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '[', '[]<Left>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '{', '{}<Left>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '"', '""<Left>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', "'", "''<Left>", { noremap = true, silent = true })

-- Vertical split
vim.keymap.set('n', '<C-\\>', ':vsplit<CR>')

-- HTML auto-closing tags
vim.keymap.set('n', '<C-s>', '<esc>yiwi<lt><esc>ea></><esc>hpF>i')

-- Clear search highlighting
vim.keymap.set('n', '<C-f>', '<cmd>nohlsearch<CR>')

-- Window navigation keymaps
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Floating diagnostic
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code actions" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.open_float, { desc = "Show diagnostics" })
vim.keymap.set("n", "<leader>dl", function() vim.diagnostic.setloclist() end, { desc = "Diagnostic list" })

-- Plugin setup
vim.pack.add({
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/mason-org/mason.nvim" },
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
	{ src = "https://github.com/folke/lazydev.nvim" },
	{ src = "https://github.com/nvim-telescope/telescope.nvim" },
	{ src = "https://github.com/nvim-lua/plenary.nvim" },
	{ src = "https://github.com/folke/which-key.nvim" },
	{ src = "https://github.com/MagicDuck/grug-far.nvim"},
	{ src = "https://github.com/mfussenegger/nvim-jdtls"},
	{ src = "https://github.com/airblade/vim-gitgutter"}
})

require "mason".setup()
require "oil".setup()
require "telescope".setup()
require "which-key".setup()
require "grug-far".setup()

-- Keymaps for plugins
vim.keymap.set('n', '<leader>e', ":Oil<CR>", { desc = "Oil" })
vim.keymap.set('n', '<leader>m', ":Mason<CR>", { desc = "Mason" })
vim.keymap.set('n', '<leader>lf', vim.lsp.buf.format, { desc = "LSP format" })
vim.keymap.set('n', '<leader>ff', ":Telescope find_files<CR>", { desc = "Find files" })
vim.keymap.set('n', '<leader>fg', ":Telescope live_grep<CR>", { desc = "Grep" })
vim.keymap.set('n', '<leader>fb', ":Telescope buffers<CR>", { desc = "Buffers" })
vim.keymap.set('n', '<leader>sr', ":GrugFar<CR>", { desc = "Search/Replace" })

-- LSP settings
vim.cmd [[set completeopt+=menuone,noselect,popup]]

vim.api.nvim_create_autocmd('LspAttach', {
	group = vim.api.nvim_create_augroup('my.lsp', {}),
	callback = function(args)
		local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
		if client:supports_method('textDocument/completion') then
			-- Optional: trigger autocompletion on EVERY keypress
			local chars = {}; for i = 32, 126 do table.insert(chars, string.char(i)) end
			client.server_capabilities.completionProvider.triggerCharacters = chars
			vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
		end
	end,
})

-- Enable LSP for specific language servers
vim.lsp.enable({
	"lua_ls",
	"clangd",
	"kotlin_lsp",
	"ts_ls",
	"jsonls",
})

vim.lsp.config("kotlin_lsp", {
    cmd = { "kotlin-lsp", "--stdio" },
    filetypes = { "kotlin" },
    root_markers = {
        "settings.gradle",
        "settings.gradle.kts",
        "pom.xml",
        "build.gradle",
        "build.gradle.kts",
        "workspace.json",
    },
    on_attach = function(client, bufnr)
        -- Disable diagnostics for this client
        vim.diagnostic.enable(false, { bufnr = bufnr })
    end,
})

vim.lsp.enable('ts_ls')

vim.lsp.config("jsonls", {
	filetypes = {"json"},
	root_markers = {"*.json"}
})

--vim.lsp.config('kotlin_lsp', {
--    single_file_support = false,
--})

-- Go to definition and hover mappings
vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'Go to definition' })
vim.keymap.set('n', 'gh', vim.lsp.buf.hover, { desc = 'Show hover information' })

-- Set the default colorscheme
vim.cmd("colorscheme default")
vim.cmd(":hi statusline guibg=NONE")
