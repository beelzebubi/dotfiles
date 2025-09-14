-- return {

vim.keymap.set('t', '<esc><esc>', '<c-\\><c-n>')

local state = {
  floating = {
    buf = -1,
    win = -1,
  },
}

function OpenCenteredFloat(opts)
  opts = opts or {}
  local columns = vim.o.columns
  local lines = vim.o.lines

  -- Standard: 80 % des verfügbaren Platzes
  local win_width = math.floor((opts.width or columns * 0.8) + 0.5)
  local win_height = math.floor((opts.height or lines * 0.8) + 0.5)

  -- Position berechnen (zentriert)
  local row = math.floor((lines - win_height) / 2)
  local col = math.floor((columns - win_width) / 2)

  -- Neues scratch-Buffer erzeugen
  local buf = nil
  if vim.api.nvim_buf_is_valid(opts.buf) then
    buf = opts.buf
  else
    buf = vim.api.nvim_create_buf(false, true) -- [listed=false, scratch=true]
  end

  -- Fenster-Optionen
  local win_opts = {
    style = 'minimal',
    relative = 'editor',
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    border = 'rounded', -- Alternativen: 'single', 'double', {…} usw.
  }

  -- Fenster öffnen
  local win = vim.api.nvim_open_win(buf, true, win_opts)

  return { buf = buf, win = win }
end

local toggle_teminal = function()
  if not vim.api.nvim_win_is_valid(state.floating.win) then
    state.floating = OpenCenteredFloat { buf = state.floating.buf }
    if vim.bo[state.floating.buf].buftype ~= 'terminal' then
      vim.cmd.terminal()
    end
  else
    vim.api.nvim_win_hide(state.floating.win)
  end
end

vim.api.nvim_create_user_command('Floaterminal', toggle_teminal, {})
vim.keymap.set({ 'n', 't' }, '<leader>tt', toggle_teminal, { desc = '[T]oggle [T]erminal window' })
-- }
return {
  {
    dir = '~/.config/nvim/lua/custom/plugins/floaterminal.lua',
    lazy = true,
    cmd = { 'Floaterminal' },
    keys = { '<leader>tt' },
  },
}
