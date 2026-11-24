require('mason').setup({
  ui = {
    border = 'rounded',
    keymaps = {
      apply_language_filter = '<Nop>',
    },
  },
})

local oil = require("oil")

local mtime_sort = {
	{ "type", "asc" },
	{ "mtime", "desc" },
}

oil.setup({
	columns = { "icon" },
	keymaps = {
		["<C-h>"] = false,
		["<C-l>"] = false,
		["<C-k>"] = false,
		["<C-j>"] = false,
	},
	view_options = {
		sort = mtime_sort,
	},
})



require('telescope').setup()

require('which-key').setup({
  triggers = {
    { '<Space>', mode = 'nxso' },
  },
})

require('grug-far').setup()

require('diffview').setup()

require('conform').setup({
    formatters_by_ft = {
        kotlin = { 'ktfmt' },
        java = { 'google-java-format' },
        json = { 'jsonlint' },
        javascript = { 'prettierd' },
        javascriptreact = { 'prettierd' },
        typescript = { 'prettierd' },
        typescriptreact = { 'prettierd' },
        vue = { 'prettierd' },
        css = { 'prettierd' },
        scss = { 'prettierd' },
        sass = { 'prettierd' },
        less = { 'prettierd' },
        html = { 'prettierd' },
        yaml = { 'prettierd' },
        markdown = { 'prettierd' },
        ['markdown.mdx'] = { 'prettierd' },
        graphql = { 'prettierd' },
    },
    format_on_save = {
        lsp_fallback = true,
        timeout_ms = 5000,
    },
})

vim.g.copilot_npx = false
vim.g.copilot_filetypes = {
    zsh = false,
    env = false,
}

-- nvim-highlight-colors: foreground highlight on color values
vim.schedule(function()
    local ok, hl = pcall(require, 'nvim-highlight-colors')
    if ok then
        hl.setup({
            render = 'background',
            enable_hex = true,
            enable_short_hex = true,
            enable_rgb = true,
            enable_hsl = true,
            enable_hsl_without_function = true,
            enable_var_usage = true,
            enable_named_colors = true,
            enable_tailwind = true,

						exclude_buffer = function(bufnr)
            local name = vim.api.nvim_buf_get_name(bufnr)
            return name:match("%.zshrc$") ~= nil
        end,
        })
    end
end)

-- Custom plugins
require('plugins.pi')
require('plugins.sudo-oil')
require('plugins.docx-viewer').setup({
  pandoc_args = { "-f", "docx", "-t", "markdown", "--wrap=none" },
  filetype = "markdown",
})


