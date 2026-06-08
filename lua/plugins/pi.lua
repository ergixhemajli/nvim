local M = {}

local state = {
  buf = nil,
  win = nil,
  job = nil,
}

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
end

-- Window-local options that were mistakenly set as buffer-local:
--   conceallevel, cursorline — use vim.wo[win], not vim.bo[buf]
local function open_window()
  vim.cmd('vnew')
  state.win = vim.api.nvim_get_current_win()
  local width = math.floor(vim.o.columns * 0.35)
  vim.api.nvim_win_set_width(state.win, width)
  state.buf = vim.api.nvim_get_current_buf()
  vim.bo[state.buf].bufhidden = 'wipe'
  vim.bo[state.buf].filetype = 'pi'
  -- Set terminal-specific options
  vim.wo[state.win].conceallevel = 2
  vim.wo[state.win].cursorline = true
end

function M.open()
  if is_valid_win(state.win) and is_valid_buf(state.buf) and state.job and vim.api.nvim_get_job_status(state.job) ~= 'dead' then
    vim.api.nvim_set_current_win(state.win)
    return
  end
  open_window()
  state.job = vim.fn.termopen('pi', {
    on_exit = function()
      clear_state()
    end,
  })
  vim.cmd.startinsert()
end

function M.close()
  if state.job and state.job > 0 then
    vim.fn.jobstop(state.job)
  end
  if is_valid_win(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  clear_state()
end

function M.toggle()
  if is_valid_win(state.win) then
    M.close()
  else
    M.open()
  end
end

function M.ask_input()
  vim.ui.input({ prompt = 'pi: ' }, function(input)
    if input and #input > 0 then
      if is_valid_win(state.win) and is_valid_buf(state.buf) then
        local handle = vim.api.nvim_buf_get_name(state.buf)
        vim.api.nvim_chan_send(vim.api.nvim_open_term(state.buf, {}), input .. '\n')
      else
        M.open()
        -- Re-send after a brief delay for the terminal to initialize
        vim.defer_fn(function()
          if is_valid_win(state.win) and is_valid_buf(state.buf) then
            local term_id = vim.api.nvim_open_term(state.buf, {})
            vim.api.nvim_chan_send(term_id, input .. '\n')
          end
        end, 300)
      end
    end
  end)
end

function M.send_visual_selection()
  local lines = vim.fn.getreg(vim.fn.getregtype('.'), true)
  if lines and #lines > 0 then
    if not (is_valid_win(state.win) and is_valid_buf(state.buf)) then
      M.open()
      vim.defer_fn(function()
        if is_valid_win(state.win) and is_valid_buf(state.buf) then
          local term_id = vim.api.nvim_open_term(state.buf, {})
          vim.api.nvim_chan_send(term_id, lines .. '\n')
        end
      end, 300)
    else
      local term_id = vim.api.nvim_open_term(state.buf, {})
      vim.api.nvim_chan_send(term_id, lines .. '\n')
    end
  end
end

function M.on_exit()
  clear_state()
end

function M.get_state()
  return state
end

function M.has_open()
  return is_valid_win(state.win) and is_valid_buf(state.buf)
end

function M.focus()
  if is_valid_win(state.win) then
    vim.api.nvim_set_current_win(state.win)
    vim.cmd.startinsert()
  end
end

-- Register user commands
vim.api.nvim_create_user_command('PiToggle', function()
  require('plugins.pi').toggle()
end, {})

vim.api.nvim_create_user_command('PiFocus', function()
  require('plugins.pi').focus()
end, {})

return M
