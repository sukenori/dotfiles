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
    local qf_session = require("util.quickfix_session")
  qf_session.setup_qf_quit_key()  -- qでの一発復帰キーを有効化

  telescope.setup({
    defaults = {
      preview = {
        treesitter = {
          disable = { "nim" },
        },
      },
    },
    extensions = {
      fzf = {
        fuzzy = true,
        override_generic_sorter = true,
        override_file_sorter = true,
        case_mode = "smart_case",
      },
    },
  })

    -- fzf 拡張を読み込む
    telescope.load_extension("fzf")

    vim.keymap.set("n", "<Leader>ff", function()
      qf_session.save()
      builtin.find_files()
    end, { desc = "ファイル検索" })

    vim.keymap.set("n", "<Leader>fg", function()
      qf_session.save()
      builtin.live_grep()
    end, { desc = "全文検索" })
  end,
}