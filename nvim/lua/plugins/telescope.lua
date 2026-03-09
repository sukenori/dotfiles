-- ===========================================================================
-- telescope.lua — Telescope（ファイル検索・全文検索）の設定
--
-- Leader + ff でファイル名検索、Leader + fg で全文検索ができる。
-- 内部で fzf アルゴリズムを使い、あいまい一致で高速に絞り込む。
-- ===========================================================================
return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
  dependencies = {
    "nvim-lua/plenary.nvim",
    -- fzf ネイティブ拡張（C 言語で書かれた高速な検索エンジン）
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },
  config = function()
    local telescope = require("telescope")
    local builtin = require("telescope.builtin")

    telescope.setup({
      extensions = {
        fzf = {
          fuzzy = true,                   -- あいまい検索を有効にする
          override_generic_sorter = true, -- 汎用ソートを fzf に任せる
          override_file_sorter = true,    -- ファイルソートも fzf に任せる
          case_mode = "smart_case",       -- 大文字を含むと大文字小文字を区別する
        },
      },
    })

    -- fzf 拡張を読み込む
    telescope.load_extension("fzf")

    -- キーマップ
    vim.keymap.set("n", "<Leader>ff", builtin.find_files, { desc = "ファイル名で検索" })
    vim.keymap.set("n", "<Leader>fg", builtin.live_grep,  { desc = "全文検索 (grep)" })
  end,
}
