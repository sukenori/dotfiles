return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.8',
  dependencies = {
    'nvim-lua/plenary.nvim',
    -- fzfエンジンを依存関係として追加し、インストール時にmakeでビルドさせる
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
    }
  },
  config = function()
    local telescope = require('telescope')
    local builtin = require('telescope.builtin')

    -- Telescopeの基本設定と、fzf拡張の読み込み
    telescope.setup({
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        }
      }
    })
    
    -- fzf拡張をTelescopeにロード
    telescope.load_extension('fzf')

    -- ショートカットキーの設定例（スペースキーをleaderとしている場合）
    vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Live grep' })
  end
}

