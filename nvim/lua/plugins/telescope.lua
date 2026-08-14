-- telescope.lua — Telescope（ファイル検索・全文検索）の共通設定
--
-- 以前はここに .nvim/scope_dirs.txt を読んで検索対象を絞る
-- 「優先スコープ」機構を持たせていたが、
-- 過去解答・自作ライブラリ・Nim-ACLといった横断検索は
-- すべてプロジェクトローカル側（atcoder-nim.telescope_cp）の
-- 専用pickerへ移したため、ここは素のfind_files/live_grepに戻す。
-- dotfilesはどのプロジェクトにも依存しない状態を保つ。

return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
  dependencies = {
    "nvim-lua/plenary.nvim",
    -- fzf ネイティブ拡張（Dockerfile でインストールした、高速なあいまい検索エンジン）
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },
  config = function()
    local telescope = require("telescope")
    local builtin = require("telescope.builtin")

    telescope.setup({
      defaults = {
        -- Nim は syntax/nim.vim（レガシー正規表現構文）で色付けする方針で、
        -- treesitter パーサーを導入していない。
        -- Telescope preview がそれでも treesitter 経路で色付けしようとし、
        -- previewers/utils.lua の ft_to_lang / get_lang が nil になって
        -- 選択のたびにクラッシュするため、nim だけ無効化する。
        -- （C++ など、実際に treesitter が機能する言語の preview には影響しない）
        preview = {
          treesitter = {
            disable = { "nim" },
          },
        },
      },
      extensions = {
        fzf = {
          fuzzy = true,                   -- あいまい検索を有効にする
          override_generic_sorter = true, -- 汎用ソートを fzf に任せる
          override_file_sorter = true,    -- ファイルソートも fzf に任せる
          case_mode = "smart_case",       -- 大文字を含むと大文字小文字を区別するが、小文字だけなら区別しない
        },
      },
    })

    -- fzf 拡張を読み込む
    telescope.load_extension("fzf")

    -- 汎用のファイル検索・全文検索。
    -- カレントディレクトリ以下を対象にする、Telescopeの素の挙動のまま。
    vim.keymap.set("n", "<Leader>ff", builtin.find_files, { desc = "ファイル検索" })
    vim.keymap.set("n", "<Leader>fg", builtin.live_grep, { desc = "全文検索" })
  end,
}