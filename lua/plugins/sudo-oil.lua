local M = {}

local defaults = {
  scratch_remote_dir = '/tmp',
  win = { width = 60, height = 6, border = 'single' },
  -- Bigger window for actually typing commands, not just a password prompt.
  shell_win = { width = 100, height = 30, border = 'single' },
}

M.config = vim.deepcopy(defaults)

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
end

--- Parse an oil-ssh:// buffer name into (host, absolute_path).
--- e.g. "oil-ssh://myserver-root//etc/nginx/nginx.conf"
---   -> host = "myserver-root", path = "/etc/nginx/nginx.conf"
local function parse_oil_ssh_url(bufname)
  local host, path = bufname:match('^oil%-ssh://([^/]+)/(/.+)$')
  return host, path
end

--- Open a small floating terminal running `cmd`, calling on_exit(code) when done.
--- Used so `sudo` can prompt interactively for a password.
local function floating_term(cmd, on_exit)
  local w, h = vim.o.columns, vim.o.lines
  local ww, wh = M.config.win.width, M.config.win.height
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    style = 'minimal',
    border = M.config.win.border,
    width = ww,
    height = wh,
    col = math.floor((w - ww) / 2),
    row = math.floor((h - wh) / 2),
  })
  vim.fn.jobstart(cmd, {
    term = true,
    on_exit = function(_, code)
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
        on_exit(code)
      end)
    end,
  })
  vim.cmd('startinsert')
end

--- Open a larger floating terminal for actually typing commands in
--- (as opposed to floating_term, which is sized for a quick sudo prompt).
--- Closes itself when the shell exits (e.g. you type `exit`).
local function open_interactive_shell(cmd)
  local w, h = vim.o.columns, vim.o.lines
  local sw = M.config.shell_win
  local ww = math.min(sw.width, w - 4)
  local wh = math.min(sw.height, h - 4)
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    style = 'minimal',
    border = sw.border,
    width = ww,
    height = wh,
    col = math.floor((w - ww) / 2),
    row = math.floor((h - wh) / 2),
  })
  vim.fn.jobstart(cmd, {
    term = true,
    on_exit = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end,
  })
  vim.cmd('startinsert')
end

--- Run `remote_cmd` on `host` via `ssh -t`, in a floating terminal (for the
--- sudo password prompt), calling on_exit(code) when done.
local function run_sudo_cmd(host, remote_cmd, on_exit)
  floating_term({ 'ssh', '-t', host, remote_cmd }, on_exit)
end

--- If the current buffer is an oil directory listing, tell oil to refresh
--- itself so the view reflects the change we just made remotely.
local function refresh_oil_if_applicable()
  if vim.bo.filetype == 'oil' then
    local ok, actions = pcall(require, 'oil.actions')
    if ok then
      actions.refresh.callback()
    end
  end
end

--- Escape a path for shelling out.
local function shell_path(p)
  return vim.fn.shellescape(p)
end

--- Figure out what path/host the current buffer + cursor position refers to.
--- Returns host, absolute_path, entry_type ('file' | 'directory' | 'link' | nil)
---   - In an oil directory listing: the entry under the cursor.
---   - In a regular oil-ssh file buffer: the file itself.
--- Returns nil for non-oil-ssh buffers.
local function resolve_target()
  local bufname = vim.api.nvim_buf_get_name(0)
  local host, path = parse_oil_ssh_url(bufname)
  if not host then
    return nil
  end

  if vim.bo.filetype == 'oil' then
    local ok, oil = pcall(require, 'oil')
    if not ok then
      vim.notify('[sudowrite] oil.nvim not found', vim.log.levels.ERROR)
      return nil
    end
    local entry = oil.get_cursor_entry()
    if not entry then
      vim.notify('[sudowrite] no entry under cursor', vim.log.levels.ERROR)
      return nil
    end
    local dir = path:gsub('/$', '')
    return host, dir .. '/' .. entry.name, entry.type
  end

  return host, path, 'file'
end

--- Resolve a user-supplied destination argument against a source path.
--- Absolute paths (leading "/") are used as-is; anything else is treated
--- as a new name/relative path inside the source's own directory.
local function resolve_dest(src, dest_arg)
  if dest_arg:match('^/') then
    return dest_arg
  end
  local dir = vim.fn.fnamemodify(src, ':h')
  return dir .. '/' .. dest_arg
end

--- Figure out (host, dir) to open a shell in for the current buffer.
---   - In an oil directory listing: that directory.
---   - In a regular oil-ssh file buffer: its parent directory.
local function dir_for_shell()
  local bufname = vim.api.nvim_buf_get_name(0)
  local host, path = parse_oil_ssh_url(bufname)
  if not host then
    return nil
  end
  local dir = path
  if vim.bo.filetype ~= 'oil' then
    dir = vim.fn.fnamemodify(path, ':h')
  end
  dir = dir:gsub('/$', '')
  if dir == '' then
    dir = '/'
  end
  return host, dir
end

--- Core routine: write buffer `bufnr`'s content to `remote_path` on `host` as
--- root. Works whether remote_path already exists or not (creates parent
--- dirs too).
function M._sudo_write_to(bufnr, host, remote_path)
  local tmp_local = vim.fn.tempname()

  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd('write! ' .. vim.fn.fnameescape(tmp_local))
  end)
  vim.fn.system({ 'chmod', '600', tmp_local }) -- don't leave content world-readable in /tmp

  local tmp_remote = M.config.scratch_remote_dir .. '/nvim_sudowrite_' .. vim.fn.fnamemodify(tmp_local, ':t')

  vim.fn.system({ 'scp', '-q', tmp_local, host .. ':' .. tmp_remote })
  if vim.v.shell_error ~= 0 then
    vim.notify('[sudowrite] scp upload failed', vim.log.levels.ERROR)
    vim.fn.delete(tmp_local)
    return
  end

  local parent = vim.fn.fnamemodify(remote_path, ':h')
  local remote_cmd = string.format(
    'sudo mkdir -p %s && sudo cp %s %s && sudo rm -f %s',
    vim.fn.shellescape(parent),
    vim.fn.shellescape(tmp_remote),
    vim.fn.shellescape(remote_path),
    vim.fn.shellescape(tmp_remote)
  )

  run_sudo_cmd(host, remote_cmd, function(code)
    vim.fn.delete(tmp_local)
    if code == 0 then
      vim.api.nvim_buf_call(bufnr, function()
        vim.bo.modified = false
        vim.cmd('checktime')
      end)
      vim.notify('[sudowrite] wrote ' .. remote_path, vim.log.levels.INFO)
    else
      vim.notify('[sudowrite] failed (exit ' .. code .. ')', vim.log.levels.ERROR)
    end
  end)
end

--- Write buffer content to a local path using sudo.
function M._sudo_write_local(bufnr, target_path)
  local tmp = vim.fn.tempname()
  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd('write! ' .. vim.fn.fnameescape(tmp))
  end)
  vim.fn.system({ 'chmod', '600', tmp })

  local target_dir = vim.fn.fnamemodify(target_path, ':h')
  local cmd = string.format(
    'sudo mkdir -p %s && sudo cp %s %s',
    shell_path(target_dir),
    shell_path(tmp),
    shell_path(target_path)
  )

  vim.fn.system(cmd)
  vim.fn.delete(tmp)
  if vim.v.shell_error ~= 0 then
    vim.notify('[sudowrite] local write failed (check sudo password)', vim.log.levels.ERROR)
    return
  end
  vim.api.nvim_buf_call(bufnr, function()
    vim.bo.modified = false
    vim.cmd('checktime')
  end)
  vim.notify('[sudowrite] wrote ' .. target_path, vim.log.levels.INFO)
end

--- :SudoWrite — write the current buffer to its own path as root.
--- Works for oil-ssh buffers (remote) and regular file buffers (local).
function M.write()
  local bufnr = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local host, remote_path = parse_oil_ssh_url(bufname)
  if host then
    -- oil-ssh buffer: remote write
    M._sudo_write_to(bufnr, host, remote_path)
    return
  end
  -- Regular file buffer: local write
  local target_path = vim.fn.fnamemodify(bufname, ':p')
  if target_path == '' then
    vim.notify('[sudowrite] no file path for this buffer', vim.log.levels.ERROR)
    return
  end
  M._sudo_write_local(bufnr, target_path)
end

--- :SudoNewFile [name] — start editing a brand-new file inside a root-owned
--- remote directory. Nothing is created on the remote yet; the file is
--- actually created on your next :SudoWrite (sudo cp creates it if missing).
function M.new_file(name_arg)
  local bufname = vim.api.nvim_buf_get_name(0)
  local host, existing_path = parse_oil_ssh_url(bufname)
  if not host then
    vim.notify('[sudowrite] not an oil-ssh buffer: ' .. bufname, vim.log.levels.ERROR)
    return
  end

  local base_dir = existing_path
  if vim.bo.filetype ~= 'oil' then
    base_dir = vim.fn.fnamemodify(existing_path, ':h')
  end
  base_dir = base_dir:gsub('/$', '')

  local name = name_arg
  if not name or name == '' then
    name = vim.fn.input('New file name (in ' .. base_dir .. '/): ')
    if name == '' then
      vim.notify('[sudowrite] cancelled', vim.log.levels.INFO)
      return
    end
  end

  local target_path = base_dir .. '/' .. name

  vim.cmd('enew')
  vim.api.nvim_buf_set_name(0, 'oil-ssh://' .. host .. target_path)
  vim.bo.buftype = ''
  vim.bo.modified = false

  vim.notify(
    '[sudowrite] editing new file ' .. target_path .. ' — write it, then run :SudoWrite to create it remotely',
    vim.log.levels.INFO
  )
end

--- :SudoMkdir [name] — create a directory.
--- Remote: uses sudo mkdir on the host. Local: uses vim.fn.mkdir directly.
function M.mkdir(name_arg)
  local bufname = vim.api.nvim_buf_get_name(0)
  local host, path = parse_oil_ssh_url(bufname)

  local base_dir
  if host then
    -- oil-ssh buffer
    base_dir = path:gsub('/$', '')
  elseif vim.bo.filetype == 'oil' then
    -- local oil buffer
    local ok, oil = pcall(require, 'oil')
    if not ok then
      vim.notify('[sudowrite] oil.nvim not found', vim.log.levels.ERROR)
      return
    end
    base_dir = oil.get_current_dir() or vim.fn.getcwd()
  else
    -- regular file buffer
    local target_path = vim.fn.fnamemodify(bufname, ':p')
    base_dir = vim.fn.fnamemodify(target_path, ':h')
    if base_dir == '' then
      base_dir = vim.fn.getcwd()
    end
  end

  local name = name_arg
  if not name or name == '' then
    name = vim.fn.input('New directory name (in ' .. base_dir .. '/): ')
    if name == '' then
      vim.notify('[sudowrite] cancelled', vim.log.levels.INFO)
      return
    end
  end

  local target = base_dir .. '/' .. name
  if host then
    -- Remote: sudo mkdir
    local remote_cmd = string.format('sudo mkdir -p %s', vim.fn.shellescape(target))
    run_sudo_cmd(host, remote_cmd, function(code)
      if code == 0 then
        vim.notify('[sudowrite] created directory ' .. target, vim.log.levels.INFO)
        refresh_oil_if_applicable()
      else
        vim.notify('[sudowrite] mkdir failed (exit ' .. code .. ')', vim.log.levels.ERROR)
      end
    end)
  else
    -- Local: plain mkdir
    vim.fn.mkdir(target, 'p')
    vim.notify('[sudowrite] created directory ' .. target, vim.log.levels.INFO)
    refresh_oil_if_applicable()
  end
end

--- :SudoRename [dest] / :SudoMove [dest] — rename or move a file/dir as root.
--- - In an oil listing: acts on the entry under the cursor.
--- - In a file buffer: acts on the file you're editing, and follows the
---   rename (buffer stays open, pointed at the new path).
--- `dest` may be a bare new name (renames in place) or an absolute path
--- (moves elsewhere).
function M.mv(dest_arg)
  local host, src, _ = resolve_target()
  if not host then
    return
  end

  local was_own_buffer = (vim.bo.filetype ~= 'oil')

  if not dest_arg or dest_arg == '' then
    dest_arg = vim.fn.input('Rename/move ' .. src .. ' to: ', src)
    if dest_arg == '' or dest_arg == src then
      vim.notify('[sudowrite] cancelled', vim.log.levels.INFO)
      return
    end
  end
  local dst = resolve_dest(src, dest_arg)

  local remote_cmd = string.format('sudo mv %s %s', shell_path(src), shell_path(dst))
  run_sudo_cmd(host, remote_cmd, function(code)
    if code ~= 0 then
      vim.notify('[sudowrite] move failed (exit ' .. code .. ')', vim.log.levels.ERROR)
      return
    end
    vim.notify('[sudowrite] moved ' .. src .. ' -> ' .. dst, vim.log.levels.INFO)
    if was_own_buffer then
      vim.api.nvim_buf_set_name(0, 'oil-ssh://' .. host .. dst)
      vim.bo.modified = false
      vim.cmd('checktime')
    else
      refresh_oil_if_applicable()
    end
  end)
end

--- :SudoCopy [dest] — copy a file/dir as root (recurses for directories).
--- Same source resolution as :SudoRename.
function M.cp(dest_arg)
  local host, src, etype = resolve_target()
  if not host then
    return
  end

  if not dest_arg or dest_arg == '' then
    dest_arg = vim.fn.input('Copy ' .. src .. ' to: ', src)
    if dest_arg == '' then
      vim.notify('[sudowrite] cancelled', vim.log.levels.INFO)
      return
    end
  end
  local dst = resolve_dest(src, dest_arg)

  local flag = (etype == 'directory') and '-r ' or ''
  local remote_cmd = string.format('sudo cp %s%s %s', flag, shell_path(src), shell_path(dst))
  run_sudo_cmd(host, remote_cmd, function(code)
    if code == 0 then
      vim.notify('[sudowrite] copied ' .. src .. ' -> ' .. dst, vim.log.levels.INFO)
      refresh_oil_if_applicable()
    else
      vim.notify('[sudowrite] copy failed (exit ' .. code .. ')', vim.log.levels.ERROR)
    end
  end)
end

--- Delete an entry from any oil directory buffer (local or ssh).
local function delete_oil_entry()
  local ok, oil = pcall(require, 'oil')
  if not ok then
    vim.notify('[sudowrite] oil.nvim not found', vim.log.levels.ERROR)
    return
  end

  local entry = oil.get_cursor_entry()
  local dir = oil.get_current_dir()
  if not entry or not dir then
    vim.notify('[sudowrite] no entry under cursor', vim.log.levels.ERROR)
    return
  end

  local target = dir .. entry.name
  local choice = vim.fn.confirm(
    string.format('Delete %s (%s)?', target, entry.type or 'file'),
    '&Yes\n&No',
    2
  )
  if choice ~= 1 then
    vim.notify('[sudowrite] cancelled', vim.log.levels.INFO)
    return
  end

  local flags = (entry.type == 'directory') and 'rf' or ''
  local ok_delete = vim.fn.delete(target, flags)
  if ok_delete ~= 0 then
    vim.notify('[sudowrite] local delete failed: ' .. target, vim.log.levels.ERROR)
    return
  end

  vim.notify('[sudowrite] deleted ' .. target, vim.log.levels.INFO)
  refresh_oil_if_applicable()
end

--- :SudoDelete — delete an entry from an oil directory buffer.
--- Local entries deleted directly; remote entries via sudo.
--- If you delete the file you're currently editing, the buffer is wiped out afterward.
function M.rm()
  if vim.bo.filetype == 'oil' then
    local bufname = vim.api.nvim_buf_get_name(0)
    local host, _ = parse_oil_ssh_url(bufname)
    if not host then
      delete_oil_entry()
      return
    end
  end

  local host, target, etype = resolve_target()
  if not host then
    vim.notify('[sudowrite] not an oil-ssh buffer', vim.log.levels.ERROR)
    return
  end

  local was_own_buffer = (vim.bo.filetype ~= 'oil')

  local answer = vim.fn.input(string.format('Delete %s (%s) on %s? [y/N] ', target, etype or 'file', host))
  if answer:lower() ~= 'y' then
    vim.notify('[sudowrite] cancelled', vim.log.levels.INFO)
    return
  end

  local flag = (etype == 'directory') and '-rf' or '-f'
  local remote_cmd = string.format('sudo rm %s %s', flag, vim.fn.shellescape(target))
  run_sudo_cmd(host, remote_cmd, function(code)
    if code ~= 0 then
      vim.notify('[sudowrite] delete failed (exit ' .. code .. ')', vim.log.levels.ERROR)
      return
    end
    vim.notify('[sudowrite] deleted ' .. target, vim.log.levels.INFO)
    if was_own_buffer then
      vim.bo.modified = false
      vim.cmd('bwipeout!')
    else
      refresh_oil_if_applicable()
    end
  end)
end

--- Open an interactive shell on the host of the current oil-ssh buffer,
--- as your normal user, starting in the same directory.
function M.remote_shell()
  local host, dir = dir_for_shell()
  if not host then
    vim.notify('[sudowrite] not an oil-ssh buffer', vim.log.levels.ERROR)
    return
  end
  local remote_cmd = string.format('cd %s && exec ${SHELL:-bash}', vim.fn.shellescape(dir))
  open_interactive_shell({ 'ssh', '-t', host, remote_cmd })
end

--- Open an interactive root shell on the current oil-ssh host.
function M.sudo_shell()
  local host, dir = dir_for_shell()
  if not host then
    vim.notify('[sudowrite] not an oil-ssh buffer', vim.log.levels.ERROR)
    return
  end
  local inner = string.format('cd %s && exec bash', vim.fn.shellescape(dir))
  local remote_cmd = string.format('sudo -i bash -c %s', vim.fn.shellescape(inner))
  open_interactive_shell({ 'ssh', '-t', host, remote_cmd })
end

--- Unified Shell command. :Shell opens a normal shell, :Shell --sudo opens root shell.
function M.shell(opts)
  opts = opts or {}
  local is_sudo = opts.args and opts.args:match('sudo') ~= nil

  -- Oil-ssh buffer: shell on the remote host
  local bufname = vim.api.nvim_buf_get_name(0)
  local host, path = parse_oil_ssh_url(bufname)
  if host then
    local dir = path
    if vim.bo.filetype ~= 'oil' then
      dir = vim.fn.fnamemodify(path, ':h')
    end
    dir = dir:gsub('/$', '')
    if dir == '' then
      dir = '/'
    end
    local cmd = string.format('cd %s && exec ${SHELL:-bash}', vim.fn.shellescape(dir))
    if is_sudo then
      cmd = string.format('sudo -i bash -c %s', vim.fn.shellescape('cd ' .. vim.fn.shellescape(dir) .. ' && exec bash'))
    end
    open_interactive_shell({ 'ssh', '-t', host, cmd })
    return
  end

  -- Oil buffer (local): open terminal in the oil directory
  if vim.bo.filetype == 'oil' then
    local ok, oil = pcall(require, 'oil')
    if ok then
      local dir = oil.get_current_dir() or vim.fn.getcwd()
      open_interactive_shell({ 'bash', '-c', 'cd ' .. vim.fn.shellescape(dir) .. ' && exec ${SHELL:-bash}' })
      return
    end
  end

  -- Regular file buffer: open terminal in the file's directory
  local target_path = vim.fn.fnamemodify(bufname, ':p')
  local dir = vim.fn.fnamemodify(target_path, ':h')
  if dir == '' then
    dir = vim.fn.getcwd()
  end
  open_interactive_shell({ 'bash', '-c', 'cd ' .. vim.fn.shellescape(dir) .. ' && exec ${SHELL:-bash}' })
end

vim.api.nvim_create_user_command('SudoWrite', function()
  require('plugins.sudo-oil').write()
end, { desc = 'Write current oil-ssh buffer to remote host via sudo' })

vim.api.nvim_create_user_command('SudoNewFile', function(opts)
  require('plugins.sudo-oil').new_file(opts.args)
end, { nargs = '?', desc = 'Create a new file in a root-owned remote directory via sudo' })

vim.api.nvim_create_user_command('SudoMkdir', function(opts)
  require('plugins.sudo-oil').mkdir(opts.args)
end, { nargs = '?', desc = 'Create a directory in a root-owned remote directory via sudo' })

vim.api.nvim_create_user_command('SudoRename', function(opts)
  require('plugins.sudo-oil').mv(opts.args)
end, { nargs = '?', desc = 'Rename/move current file or cursor entry via sudo' })

vim.api.nvim_create_user_command('SudoMove', function(opts)
  require('plugins.sudo-oil').mv(opts.args)
end, { nargs = '?', desc = 'Rename/move current file or cursor entry via sudo' })

vim.api.nvim_create_user_command('SudoCopy', function(opts)
  require('plugins.sudo-oil').cp(opts.args)
end, { nargs = '?', desc = 'Copy current file or cursor entry via sudo' })

vim.api.nvim_create_user_command('SudoDelete', function()
  require('plugins.sudo-oil').rm()
end, { desc = 'Delete current file or cursor entry via sudo' })

vim.api.nvim_create_user_command('Shell', function(opts)
  require('plugins.sudo-oil').shell(opts)
end, { nargs = '?', desc = 'Open interactive shell on current buffer context (use --sudo for root)' })

return M
