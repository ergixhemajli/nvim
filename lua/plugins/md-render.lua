local function render_markdown_with_glow()
  local tempfile = vim.fn.tempname() .. ".md"
  vim.cmd("write! " .. tempfile)

  vim.cmd("enew")
  local bufnr = vim.api.nvim_get_current_buf()

  local command = "terminal glow -p " .. tempfile

  vim.cmd(command)

  vim.cmd("startinsert!")

  vim.api.nvim_create_autocmd("TermClose", {
    buffer = bufnr,
    callback = function()
			vim.uv.fs_unlink(tempfile)
      pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    end,
  })
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.keymap.set(
      "n",
      "<leader>md",
      render_markdown_with_glow,
      { silent = true, buffer = true, desc = "render markdown with glow" }
    )
  end,
})
