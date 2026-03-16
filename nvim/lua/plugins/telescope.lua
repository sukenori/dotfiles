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

    -- 優先検索スコープは外部ファイルで定義する。
    -- 具体的な対象ディレクトリは各 setup.sh 側で管理する。
    local function priority_scope_dirs()
      local scope_file = vim.fn.stdpath("config") .. "/telescope_priority_dirs.txt"
      if vim.fn.filereadable(scope_file) ~= 1 then
        return {}
      end

      local dirs = {}
      local seen = {}

      for _, line in ipairs(vim.fn.readfile(scope_file)) do
        local dir = vim.trim(line)
        if dir ~= "" and not dir:match("^#") then
          dir = vim.fn.expand(dir)
          if vim.fn.isdirectory(dir) == 1 and not seen[dir] then
            seen[dir] = true
            table.insert(dirs, dir)
          end
        end
      end

      return dirs
    end

    -- キーマップ
    -- 主要キーは優先スコープを既定にし、対象ディレクトリが無い場合のみ通常検索へ戻す
    vim.keymap.set("n", "<Leader>ff", function()
      local dirs = priority_scope_dirs()
      if #dirs > 0 then
        builtin.find_files({
          search_dirs = dirs,
          prompt_title = "Priority Scope Files",
        })
      else
        builtin.find_files()
      end
    end, { desc = "優先スコープでファイル検索" })

    vim.keymap.set("n", "<Leader>fg", function()
      local dirs = priority_scope_dirs()
      if #dirs > 0 then
        builtin.live_grep({
          search_dirs = dirs,
          prompt_title = "Priority Scope Grep",
        })
      else
        builtin.live_grep()
      end
    end, { desc = "優先スコープで全文検索" })
  end,
}