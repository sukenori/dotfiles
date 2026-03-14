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
    local uv = vim.uv or vim.loop

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

    -- AtCoder 用の検索スコープ（ライブラリ/提出ログ）
    -- ユーザー要望: cp-nim-lib(または cp-nim-log) と cp-solved-log を優先検索する
    local function atcoder_scope_dirs()
      local home = uv.os_homedir()
      local candidates = {
        home .. "/cp-nim-lib",
        home .. "/cp-nim-log", -- 名前違いにも対応（存在すれば採用）
        home .. "/cp-solved-log",
      }

      local dirs = {}
      for _, dir in ipairs(candidates) do
        if vim.fn.isdirectory(dir) == 1 then
          table.insert(dirs, dir)
        end
      end
      return dirs
    end

    -- キーマップ
    -- 主要キーは AtCoder スコープを既定にし、対象ディレクトリが無い場合のみ通常検索へ戻す
    vim.keymap.set("n", "<Leader>ff", function()
      local dirs = atcoder_scope_dirs()
      if #dirs > 0 then
        builtin.find_files({
          search_dirs = dirs,
          prompt_title = "AtCoder Scope Files",
        })
      else
        builtin.find_files()
      end
    end, { desc = "AtCoder スコープでファイル検索" })

    vim.keymap.set("n", "<Leader>fg", function()
      local dirs = atcoder_scope_dirs()
      if #dirs > 0 then
        builtin.live_grep({
          search_dirs = dirs,
          prompt_title = "AtCoder Scope Grep",
        })
      else
        builtin.live_grep()
      end
    end, { desc = "AtCoder スコープで全文検索" })
  end,
}