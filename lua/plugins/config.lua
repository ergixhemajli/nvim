require('mason').setup()
require('oil').setup()
require('telescope').setup()
require('which-key').setup()
require('grug-far').setup()
require('diffview').setup()


require('conform').setup({
    formatters_by_ft = {
        kotlin = { 'ktfmt', 'ktlint' },
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
        timeout_ms = 500,
    },
})

vim.g.opencode_opts = {}

vim.g.copilot_filetypes = {
    zsh = false,
    env = false,
}
