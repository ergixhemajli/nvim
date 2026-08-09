local function render_markdown_with_glow()
  local tempfile = vim.fn.tempname() .. ".md"
  vim.cmd("write! " .. tempfile)

  -- open new tab so preview fills full window
  vim.cmd("tabnew")
  vim.cmd("terminal glow -p " .. vim.fn.fnameescape(tempfile))
  local bufnr = vim.api.nvim_get_current_buf()

  vim.cmd("startinsert!")

  vim.api.nvim_create_autocmd("TermClose", {
    buffer = bufnr,
    callback = function()
      pcall(vim.loop.fs_unlink, tempfile)
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
