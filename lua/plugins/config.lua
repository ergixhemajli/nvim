require('mason').setup()
require('mason-tool-installer').setup({
    ensure_installed = {
        'tailwindcss-language-server',
    },
    auto_update = false,
    run_on_start = true,
    start_delay = 3000,
})
require('oil').setup()
require('telescope').setup()
require('which-key').setup({
  triggers = {
    { '<Space>', mode = 'nxso' },
  },
})
require('grug-far').setup()
require('diffview').setup()

-- Opencode config is disabled while using pi.
-- local function opencode_terminal_opts()
--     return {
--         split = 'right',
--         width = math.floor(vim.o.columns * 0.35),
--     }
-- end
--
-- local function with_e444_fallback(fn)
--     local ok, err = pcall(fn)
--     if ok then
--         return
--     end
--
--     local msg = tostring(err)
--     if not msg:match('E444') then
--         vim.notify(msg, vim.log.levels.ERROR, { title = 'opencode' })
--         return
--     end
--
--     vim.cmd('new')
--     local retry_ok, retry_err = pcall(fn)
--     if not retry_ok then
--         vim.notify(tostring(retry_err), vim.log.levels.ERROR, { title = 'opencode' })
--     end
-- end
--
-- local function patch_opencode_disconnect()
--     local ok, server_mod = pcall(require, 'opencode.server')
--     if not ok or type(server_mod) ~= 'table' or type(server_mod.disconnect) ~= 'function' then
--         return
--     end
--
--     local original_disconnect = server_mod.disconnect
--     server_mod.disconnect = function(self)
--         if self == nil then
--             if server_mod.connected ~= nil then
--                 return original_disconnect(server_mod.connected)
--             end
--             return
--         end
--
--         return original_disconnect(self)
--     end
-- end
--
-- patch_opencode_disconnect()

-- pi plugin manages its own state; no setup needed

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

-- vim.g.opencode_opts = {
--     server = {
--         start = function()
--             require('opencode.terminal').open('opencode --port', opencode_terminal_opts())
--         end,
--         stop = function()
--             with_e444_fallback(function()
--                 require('opencode.terminal').close()
--             end)
--         end,
--         toggle = function()
--             with_e444_fallback(function()
--                 require('opencode.terminal').toggle('opencode --port', opencode_terminal_opts())
--             end)
--         end,
--     },
-- }

vim.g.copilot_filetypes = {
    zsh = false,
    env = false,
}
