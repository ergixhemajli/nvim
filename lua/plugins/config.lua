require('mason').setup({
  ui = {
    border = 'rounded',
    keymaps = {
      apply_language_filter = false,
    },
  },
})

local oil = require("oil")

oil.setup({
	keymaps = {
		["<C-h>"] = false,
		["<C-l>"] = false,
		["<C-k>"] = false,
		["<C-j>"] = false,
	},
	view_options = {
    sort = {
      { "birthtime", "desc" },
    },
  },
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "oil",
  callback = function()
    local dir = oil.get_current_dir()
    if not dir then
      return
    end

    -- Look for .git, but stop at your home folder so directories like ~/Downloads sort correctly
    local git_roots = vim.fs.find(".git", {
      path = dir,
      upward = true,
      type = "directory",
      stop = vim.uv.os_homedir(),
    })

    if #git_roots > 0 then
      -- Reset to oil's default project sorting when inside a git repo
      oil.set_sort({
        { "type", "asc" },
        { "name", "asc" },
      })
    else
      -- Force date sorting if the autocommand re-triggers
      oil.set_sort({ { "birthtime", "desc" } })
    end
  end,
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
