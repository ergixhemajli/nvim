local lsp = vim.lsp

local function setup(server, opts)
	if opts then
		lsp.config(server, opts)
	end
	lsp.enable(server)
end

-- Add new servers with one of these:
--   setup('bashls')
--   setup('yamlls', { settings = { yaml = { keyOrdering = false } } })

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
setup('lua_ls')

-- clangd (C/C++)
setup('clangd')

-- TypeScript
setup('ts_ls')

-- Tailwind CSS
setup('tailwindcss', {
	filetypes = {
		'html',
		'css',
		'scss',
		'javascript',
		'javascriptreact',
		'typescript',
		'typescriptreact',
		'vue',
		'svelte',
		'astro',
	},
	root_markers = {
		'tailwind.config.js',
		'tailwind.config.cjs',
		'tailwind.config.mjs',
		'tailwind.config.ts',
		'postcss.config.js',
		'postcss.config.cjs',
		'package.json',
		'.git',
	},
})

-- JSON
setup('jsonls', {
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

-- Kotlin
setup('kotlin_lsp', {
	cmd = { 'kotlin-lsp', '--stdio' },
	filetypes = { 'kotlin' },
	single_file_support = true,
	root_markers = {
		'settings.gradle',
		'settings.gradle.kts',
		'pom.xml',
		'build.gradle',
		'build.gradle.kts',
		'gradle.properties',
		'gradlew',
		'mvnw',
		'workspace.json',
		'.git', -- fallback so LSP also starts in monorepos/single-module trees
	},
})
