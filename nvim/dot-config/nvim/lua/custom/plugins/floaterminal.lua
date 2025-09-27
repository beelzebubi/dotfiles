return {
  -- Lazy-Spezifikation
  name = 'floaterminal',
  dir = '.',
  lazy = false,
  -- cmd = { 'Floaterminal' },
  -- keys = { '<leader>tt' },

  -- config wird beim Laden ausgeführt
  config = function()
    local state = { floating = { buf = -1, win = -1 } }

    local function open_centered_float(opts)
      opts = opts or {}
      local columns = vim.o.columns
      local lines = vim.o.lines

      local win_width = math.floor((opts.width or columns * 0.8) + 0.5)
      local win_height = math.floor((opts.height or lines * 0.8) + 0.5)

      local row = math.floor((lines - win_height) / 2)
      local col = math.floor((columns - win_width) / 2)

      local buf = (vim.api.nvim_buf_is_valid(opts.buf) and opts.buf) or vim.api.nvim_create_buf(false, true)

      local win_opts = {
        style = 'minimal',
        relative = 'editor',
        width = win_width,
        height = win_height,
        row = row,
        col = col,
        border = 'rounded',
      }

      local win = vim.api.nvim_open_win(buf, true, win_opts)
      return { buf = buf, win = win }
    end

    local function toggle_terminal()
      if not vim.api.nvim_win_is_valid(state.floating.win) then
        state.floating = open_centered_float { buf = state.floating.buf }
        if vim.bo[state.floating.buf].buftype ~= 'terminal' then
          vim.cmd.terminal()
          vim.api.nvim_feedkeys('i', 'n', false)
        else
          vim.api.nvim_feedkeys('i', 'n', false)
        end
      else
        vim.api.nvim_win_hide(state.floating.win)
      end
    end

    -- Keymaps und Command registrieren
    vim.keymap.set('t', '<esc><esc>', '<c-\\><c-n>')
    vim.keymap.set({ 'n', 't' }, '<leader>tt', toggle_terminal, { desc = '[T]oggle floating [T]erminal window' })
    vim.api.nvim_create_user_command('Floaterminal', toggle_terminal, {})

    -- Optional: Funktion global verfügbar machen
    _G.toggle_floaterminal = toggle_terminal
  end,
}
