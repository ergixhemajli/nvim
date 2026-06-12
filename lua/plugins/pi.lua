local M = {}

local state = {
  buf = nil,
  win = nil,
  job = nil,
  pending = {},
}

local function close_window_only()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
end

local function is_valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function is_valid_buf(buf)
  return buf and vim.api.nvim_buf_is_valid(buf)
end

local function clear_state()
  state.buf = nil
  state.win = nil
  state.job = nil
  state.pending = {}
end

local function is_running_job()
  if not state.job or state.job <= 0 then
    return false
  end

  local ok, status = pcall(vim.fn.jobwait, { state.job }, 0)
  return ok and status and status[1] == -1
end

local function flush_pending()
  if not is_running_job() then
    return false
  end

  if #state.pending == 0 then
    return true
  end

  for _, input in ipairs(state.pending) do
    vim.fn.chansend(state.job, input)
    vim.fn.chansend(state.job, '\n')
  end

  state.pending = {}
  return true
end

local function selection_kind()
  local mode = vim.fn.mode(1)
  if mode == 'v' or mode == 'V' or mode == '\22' then
    return mode
  end
  local last = vim.fn.visualmode()
  if last == 'v' or last == 'V' or last == '\22' then
    return last
  end
  return nil
end

local function get_visual_selection_data()
  local bufnr = vim.api.nvim_get_current_buf()
  local start = vim.fn.getpos("'<")
  local finish = vim.fn.getpos("'>")

  if start[2] == 0 or finish[2] == 0 then
    return nil
  end

  local kind = selection_kind() or 'v'
  local srow, scol = start[2], start[3] - 1
  local erow, ecol = finish[2], finish[3] - 1

  if srow > erow or (srow == erow and scol > ecol) then
    srow, erow = erow, srow
    scol, ecol = ecol, scol
  end

  local text
  if kind == '\22' then
    -- block selection
    local lines = vim.api.nvim_buf_get_lines(bufnr, srow - 1, erow, false)
    local pieces = {}
    local from_col = math.min(scol, ecol)
    local to_col = math.max(scol, ecol)
    for _, line in ipairs(lines) do
      local line_len = #line
      if from_col < line_len then
        table.insert(pieces, line:sub(from_col + 1, math.min(to_col + 1, line_len)))
      else
        table.insert(pieces, '')
      end
    end
    text = table.concat(pieces, '\n')
  elseif kind == 'V' then
    local lines = vim.api.nvim_buf_get_lines(bufnr, srow - 1, erow, false)
    text = table.concat(lines, '\n')
    scol = 0
    local last = lines[#lines] or ''
    ecol = math.max(0, #last - 1)
  else
    local lines = vim.api.nvim_buf_get_text(bufnr, srow - 1, scol, erow - 1, ecol + 1, {})
    text = table.concat(lines, '\n')
  end

  return {
    text = text,
    kind = kind,
    srow = srow,
    scol = scol,
    erow = erow,
    ecol = ecol,
    bufnr = bufnr,
  }
end

local function abs_path(path)
  if not path or path == '' then
    return ''
  end
  return vim.fn.fnamemodify(path, ':p')
end

local function format_location(bufnr, lnum, col)
  local name = abs_path(vim.api.nvim_buf_get_name(bufnr))
  if name == '' then
    return ''
  end
  if lnum and col then
    return string.format('%s:%d:%d', name, lnum, col)
  elseif lnum then
    return string.format('%s:%d', name, lnum)
  end
  return name
end

local function buffers_value()
  local out = {}
  for _, b in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    local name = format_location(b.bufnr)
    if name ~= '' then
      table.insert(out, name)
    end
  end
  return #out > 0 and table.concat(out, ', ') or ''
end

local function diagnostics_value(bufnr)
  local diags = vim.diagnostic.get(bufnr)
  if #diags == 0 then
    return ''
  end
  local lines = {}
  for _, d in ipairs(diags) do
    local loc = format_location(bufnr, d.lnum + 1, d.col + 1)
    local msg = (d.message or ''):gsub('%s+', ' ')
    table.insert(lines, string.format('- %s %s', loc, msg))
  end
  return table.concat(lines, '\n')
end

local function visible_value()
  local out = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local name = format_location(buf)
    if name ~= '' then
      local start_line = vim.fn.line('w0', win)
      local end_line = vim.fn.line('w$', win)
      table.insert(out, string.format('%s:%d-%d', name, start_line, end_line))
    end
  end
  return #out > 0 and table.concat(out, ', ') or ''
end

local function quickfix_value()
  local qf = vim.fn.getqflist()
  if #qf == 0 then
    return ''
  end
  local out = {}
  for _, entry in ipairs(qf) do
    if entry.bufnr and entry.bufnr > 0 then
      local loc = format_location(entry.bufnr, entry.lnum, entry.col)
      if loc ~= '' then
        table.insert(out, loc)
      end
    end
  end
  return #out > 0 and table.concat(out, ', ') or ''
end

local function diff_value()
  local result = vim.system({ 'git', '--no-pager', 'diff' }, { text = true }):wait()
  if result.code == 129 then
    return ''
  end
  if result.code ~= 0 then
    return ''
  end
  return result.stdout and result.stdout ~= '' and result.stdout or ''
end

local function marks_value()
  local marks = vim.fn.getmarklist()
  local out = {}
  for _, mark in ipairs(marks) do
    if type(mark.mark) == 'string' and mark.mark:match("^'[A-Z]$") then
      local pos = mark.pos or {}
      local bufnr, lnum, col = pos[1], pos[2], pos[3]
      if bufnr and bufnr > 0 then
        local loc = format_location(bufnr, lnum, col)
        if loc ~= '' then
          table.insert(out, loc)
        end
      end
    end
  end
  return #out > 0 and table.concat(out, ', ') or ''
end

local function grapple_value()
  local ok, grapple = pcall(require, 'grapple')
  if not ok or not grapple or not grapple.tags then
    return ''
  end
  local tags = grapple.tags() or {}
  if #tags == 0 then
    return ''
  end
  local out = {}
  for _, tag in ipairs(tags) do
    local path = abs_path(tag.path)
    if path ~= '' then
      table.insert(out, path)
    end
  end
  return #out > 0 and table.concat(out, ', ') or ''
end

local function current_context(selection)
  local bufnr = vim.api.nvim_get_current_buf()
  local file = format_location(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)

  local this_value
  if selection and selection.text and #selection.text > 0 then
    local loc = file ~= '' and string.format('%s:%d-%d', file, selection.srow, selection.erow) or 'selection'
    this_value = string.format('%s\n```\n%s\n```', loc, selection.text)
  else
    if file ~= '' then
      this_value = string.format('%s:%d', file, cursor[1])
    else
      this_value = string.format('line %d', cursor[1])
    end
  end

  return {
    ['@this'] = this_value,
    ['@buffer'] = file,
    ['@buffers'] = buffers_value(),
    ['@visible'] = visible_value(),
    ['@diagnostics'] = diagnostics_value(bufnr),
    ['@quickfix'] = quickfix_value(),
    ['@diff'] = diff_value(),
    ['@marks'] = marks_value(),
    ['@grapple'] = grapple_value(),
  }
end

local function apply_context_modifiers(prompt, values)
  local out = prompt
  for key, value in pairs(values) do
    if value and value ~= '' then
      out = out:gsub(key, value)
    end
  end
  return out
end

local CONTEXT_PLACEHOLDERS = {
  '@this',
  '@buffer',
  '@buffers',
  '@visible',
  '@diagnostics',
  '@quickfix',
  '@diff',
  '@marks',
  '@grapple',
}

-- Completion for vim.ui.input via :help input()-completion
_G.pi_context_completion = function(_, cmdline)
  local start_idx, end_idx = cmdline:find('([^%s]+)$')
  local latest = start_idx and cmdline:sub(start_idx, end_idx) or nil

  local items = {}
  for _, placeholder in ipairs(CONTEXT_PLACEHOLDERS) do
    if not latest then
      table.insert(items, cmdline .. placeholder)
    elseif placeholder:find(latest, 1, true) == 1 then
      local new_cmd = cmdline:sub(1, start_idx - 1) .. placeholder .. cmdline:sub(end_idx + 1)
      table.insert(items, new_cmd)
    end
  end
  return items
end

function M.open()
  if is_valid_win(state.win) then
    vim.api.nvim_set_current_win(state.win)
    return
  end

  if is_valid_buf(state.buf) and is_running_job() then
    local previous_win = vim.api.nvim_get_current_win()
    vim.cmd('vsplit')
    state.win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(state.win, state.buf)
    vim.api.nvim_win_set_width(state.win, math.floor(vim.o.columns * 0.35))
    vim.api.nvim_set_current_win(previous_win)
    flush_pending()
    return
  end

  if is_valid_buf(state.buf) then
    vim.api.nvim_buf_delete(state.buf, { force = true })
  end
  -- Keep pending messages queued when opening a fresh Pi instance.
  state.buf = nil
  state.win = nil
  state.job = nil

  local previous_win = vim.api.nvim_get_current_win()
  state.buf = vim.api.nvim_create_buf(false, false)
  vim.bo[state.buf].bufhidden = 'hide'
  vim.bo[state.buf].filetype = 'pi'

  vim.cmd('vnew')
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.win, state.buf)
  vim.api.nvim_win_set_width(state.win, math.floor(vim.o.columns * 0.35))

  state.job = vim.fn.jobstart('pi', {
    term = true,
    on_exit = function()
      vim.schedule(function()
        M.close()
      end)
    end,
  })

  vim.api.nvim_set_current_win(previous_win)
  vim.defer_fn(flush_pending, 200)
end

function M.close()
  if state.job then
    vim.fn.jobstop(state.job)
  end
  close_window_only()
  if is_valid_buf(state.buf) then
    vim.api.nvim_buf_delete(state.buf, { force = true })
  end
  clear_state()
end

function M.toggle()
  if is_valid_win(state.win) then
    close_window_only()
  else
    M.open()
  end
end

function M.focus()
  if is_valid_win(state.win) then
    vim.api.nvim_set_current_win(state.win)
    vim.cmd('startinsert')
  end
end

function M.has_open()
  return is_valid_win(state.win) and is_valid_buf(state.buf) and is_running_job()
end

function M.send_input(input)
  if not input or #input == 0 then
    return
  end

  table.insert(state.pending, input)

  if flush_pending() then
    return
  end

  M.open()

  local attempts = 0
  local function try_flush()
    attempts = attempts + 1
    if flush_pending() then
      return
    end
    if attempts < 40 then
      vim.defer_fn(try_flush, 100)
    end
  end

  vim.defer_fn(try_flush, 100)
end

function M.ask_input(opts)
  opts = opts or {}
  local selection = opts.selection
  local values = current_context(selection)

  vim.ui.input({
    prompt = 'ask pi: ',
    completion = 'customlist,v:lua.pi_context_completion',
  }, function(input)
    if not input or #input == 0 then
      return
    end

    local rendered = apply_context_modifiers(input, values)

    -- If visual selection exists and user didn't explicitly use @this,
    -- auto-attach selected content at send time.
    if selection and selection.text and #selection.text > 0 and not input:find('@this', 1, true) then
      rendered = rendered .. '\n\n' .. values['@this']
    end

    M.send_input(rendered)
  end)
end

function M.ask_with_visual_selection()
  local esc = vim.api.nvim_replace_termcodes('<Esc>', true, false, true)
  vim.api.nvim_feedkeys(esc, 'nx', false)
  vim.schedule(function()
    local selection = get_visual_selection_data()
    M.ask_input({ selection = selection })
  end)
end

function M.get_visual_selection()
  local selection = get_visual_selection_data()
  return selection and selection.text or ''
end

function M.send_visual_selection()
  local selection = get_visual_selection_data()
  if selection and selection.text and #selection.text > 0 then
    M.send_input(selection.text)
  end
end

function M.on_exit()
  clear_state()
end

function M.get_state()
  return state
end

vim.api.nvim_create_user_command('PiToggle', function()
  require('plugins.pi').toggle()
end, {})

vim.api.nvim_create_user_command('PiClose', function()
  require('plugins.pi').close()
end, {})

vim.api.nvim_create_user_command('PiFocus', function()
  require('plugins.pi').focus()
end, {})

return M
