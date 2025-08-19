-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  { -- VimTeX for working with TeX
    'lervag/vimtex',
    lazy = false, -- we don't want lazy to load VimTeX
    -- tag = "v2.15 -- uncomment to fix to specific release
    config = function()
      vim.g.vimtex_view_method = 'zathura' -- oder skim, okular, sumatrapdf...
      vim.g.vimtex_compiler_method = 'latexmk'
    end,
  },
}
