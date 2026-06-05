require('mason').setup()
require('oil').setup()
require('telescope').setup()
require('which-key').setup()
require('grug-far').setup()
require('diffview').setup()

local function opencode_terminal_opts()
    return {
        split = 'right',
        width = math.floor(vim.o.columns * 0.35),
    }
end

local function with_e444_fallback(fn)
    local ok, err = pcall(fn)
    if ok then
        return
    end

    local msg = tostring(err)
    if not msg:match('E444') then
        vim.notify(msg, vim.log.levels.ERROR, { title = 'opencode' })
        return
    end

    vim.cmd('new')
    local retry_ok, retry_err = pcall(fn)
    if not retry_ok then
        vim.notify(tostring(retry_err), vim.log.levels.ERROR, { title = 'opencode' })
    end
end

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

vim.g.opencode_opts = {
    server = {
        start = function()
            require('opencode.terminal').open('opencode --port', opencode_terminal_opts())
        end,
        stop = function()
            with_e444_fallback(function()
                require('opencode.terminal').close()
            end)
        end,
        toggle = function()
            with_e444_fallback(function()
                require('opencode.terminal').toggle('opencode --port', opencode_terminal_opts())
            end)
        end,
    },
}

vim.g.copilot_filetypes = {
    zsh = false,
    env = false,
}
