-- docx-viewer.lua
-- Open .docx files in Neovim as read-only text buffers.
--
-- first one available wins:
--   1. pandoc  -> Markdown (headings, lists, tables, bold/italic)
--   2. unzip   -> plain text pulled from word/document.xml
--
-- commands:
--   :DocxRefresh   re-read the file from disk
--   :DocxBackend   show backend, resolved path and pandoc location

local M = {}

M.config = {
  pandoc_args = { "-f", "docx", "-t", "markdown", "--wrap=none" },
  filetype = "markdown",
}

-- Neovim's bundled zip.vim also claims *.docx (it treats them as zip archives)
-- and appends its file listing to the buffer. Stop it from doing that.
-- This must happen before runtime/plugin/zipPlugin.vim is sourced, which is the
-- case for files in ~/.config/nvim/plugin/ and for plugin-manager setups.
if vim.g.zipPlugin_ext == nil and vim.g.loaded_zipPlugin == nil then
  vim.g.zipPlugin_ext = table.concat({
    "*.aar", "*.apk", "*.celzip", "*.crtx", "*.ear", "*.epub", "*.gcsx", "*.glox",
    "*.gqsx", "*.ja", "*.jar", "*.kmz", "*.odb", "*.odc", "*.odf", "*.odg", "*.odi",
    "*.odm", "*.odp", "*.ods", "*.odt", "*.otc", "*.otf", "*.otg", "*.oth", "*.oti",
    "*.otp", "*.ots", "*.ott", "*.oxt", "*.pkpass", "*.potm", "*.potx", "*.ppam",
    "*.ppsm", "*.ppsx", "*.pptm", "*.pptx", "*.sldx", "*.thmx", "*.vdw", "*.war",
    "*.whl", "*.wsz", "*.xap", "*.xlam", "*.xlsb", "*.xlsm", "*.xlsx", "*.xltm",
    "*.xltx", "*.xpi", "*.zip",
  }, ",")
end

local function xml_to_text(xml)
  xml = xml:gsub("</w:p>", "\n")
  xml = xml:gsub("<w:br[^>]*/>", "\n")
  xml = xml:gsub("<w:tab[^>]*/>", "\t")
  xml = xml:gsub("<[^>]+>", "")
  xml = xml:gsub("&lt;", "<")
  xml = xml:gsub("&gt;", ">")
  xml = xml:gsub("&quot;", '"')
  xml = xml:gsub("&apos;", "'")
  xml = xml:gsub("&amp;", "&")
  return xml
end

-- Turn whatever the buffer is called into a real file path on disk.
local function resolve_path(name)
  name = name:gsub("^zipfile:", ""):gsub("^file://", "")
  name = name:gsub("::.*$", "") -- zipfile:/x.docx::word/document.xml -> /x.docx
  return vim.fn.fnamemodify(vim.fn.expand(name), ":p")
end

local function run(cmd)
  local res = vim.system(cmd, { text = true }):wait()
  return res.code, res.stdout or "", res.stderr or ""
end

local function render(path)
  if not vim.uv.fs_stat(path) then
    return { "File not found: " .. path }, "error"
  end

  if vim.fn.executable("pandoc") == 1 then
    local cmd = { "pandoc" }
    vim.list_extend(cmd, M.config.pandoc_args)
    table.insert(cmd, path)
    local code, out, err = run(cmd)
    if code == 0 then
      return vim.split(out, "\n", { plain = true }), "pandoc"
    end
    local lines = { "pandoc failed (exit " .. code .. ") for:", "  " .. path, "" }
    vim.list_extend(lines, vim.split(err, "\n", { plain = true }))
    return lines, "pandoc (error)"
  end

  if vim.fn.executable("unzip") == 1 then
    local code, out, err = run({ "unzip", "-p", path, "word/document.xml" })
    if code == 0 then
      return vim.split(xml_to_text(out), "\n", { plain = true }), "unzip"
    end
    local lines = { "unzip failed (exit " .. code .. ") for:", "  " .. path, "" }
    vim.list_extend(lines, vim.split(err, "\n", { plain = true }))
    return lines, "unzip (error)"
  end

  return { "Neither pandoc nor unzip found in PATH." }, "none"
end

function M.load(buf)
  buf = (buf and buf ~= 0) and buf or vim.api.nvim_get_current_buf()
  local path = resolve_path(vim.api.nvim_buf_get_name(buf))
  local lines, backend = render(path)

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.b[buf].docx_backend = backend
  vim.b[buf].docx_path = path

  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false
  vim.bo[buf].readonly = true
  vim.bo[buf].filetype = M.config.filetype
  pcall(vim.api.nvim_win_set_cursor, 0, { 1, 0 })
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

local group = vim.api.nvim_create_augroup("DocxViewer", { clear = true })

-- If zipPlugin.vim was already sourced before us, drop its *.docx handlers.
vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  once = true,
  callback = function()
    pcall(vim.api.nvim_clear_autocmds, {
      group = "zip",
      event = { "BufReadCmd", "FileReadCmd" },
      pattern = { "*.docx", "*.docm", "*.dotx", "*.dotm" },
    })
  end,
})

vim.api.nvim_create_autocmd("BufReadCmd", {
  group = group,
  pattern = { "*.docx", "*.dotx" },
  callback = function(args)
    M.load(args.buf)
  end,
})

vim.api.nvim_create_user_command("DocxRefresh", function()
  M.load()
end, {})

vim.api.nvim_create_user_command("DocxBackend", function()
  print(("backend: %s | path: %s | pandoc: %s"):format(
    vim.b.docx_backend or "n/a",
    vim.b.docx_path or "n/a",
    vim.fn.exepath("pandoc")
  ))
end, {})

return M
