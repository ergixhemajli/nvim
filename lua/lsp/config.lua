local lsp = vim.lsp

-- LSP completion setup on attach
vim.api.nvim_create_autocmd('LspAttach', {
	group = vim.api.nvim_create_augroup('my.lsp', {}),
	callback = function(args)
		local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
		if client:supports_method('textDocument/completion') then
			local chars = {}
			for i = 32, 126 do
				table.insert(chars, string.char(i))
			end
			client.server_capabilities.completionProvider.triggerCharacters = chars
			vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
		end
	end,
})

-- lua-language-server
lsp.enable('lua_ls')

-- clangd (C/C++)
lsp.enable('clangd')

-- TypeScript
lsp.enable('ts_ls')

-- JSON
lsp.config('jsonls', {
	filetypes = { 'json', 'jsonc' },
	root_markers = { '.git', 'package.json' },
	settings = {
		json = {
			format = {
				enable = true,
			},
		},
	},
})
lsp.enable('jsonls')

-- Kotlin
lsp.config('kotlin_lsp', {
	cmd = { 'kotlin-lsp', '--stdio' },
	filetypes = { 'kotlin' },
	root_markers = {
		'settings.gradle',
		'settings.gradle.kts',
		'pom.xml',
		'build.gradle',
		'build.gradle.kts',
		'workspace.json',
	},
	on_attach = function(_, bufnr)
		vim.diagnostic.enable(false, { bufnr = bufnr })
	end,
})
lsp.enable('kotlin_lsp')
