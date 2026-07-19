-- telescope.lua — Telescope（ファイル検索・全文検索）の設定

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
        -- プロジェクトローカルで vim.g.user_telescope_file_glob が設定されていれば live_grep の検索対象ファイルを絞る
        additional_args = function()
          local glob = vim.g.user_telescope_file_glob
          if glob and glob ~= "" then
            return { "--glob", glob }
          end
          return {}
        end,
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

    -- 優先検索スコープは project-local の .nvim 下に置いた scope_dirs.txt で定義する
    local function find_scope_file()
      local found = vim.fs.find(".nvim/scope_dirs.txt", {
        path = vim.fs.dirname(vim.api.nvim_buf_get_name(0)),
        upward = true,
      })[1] or vim.fs.find(".nvim/scope_dirs.txt", {
        path = vim.uv.cwd(),
        upward = true,
      })[1]
      return found
    end

    local function priority_scope_dirs()
      -- scope_dirs.txt のパスを取得する（見つからなければ空リストを返す）
      local scope_file = find_scope_file()
      if not scope_file then
        return {}
      end

      local dirs = {}
      local seen = {} -- 重複ディレクトリを除外するためのセット

      -- scope_dirs.txt を1行ずつ読む
      for _, line in ipairs(vim.fn.readfile(scope_file)) do
        local dir = vim.trim(line)                               -- 前後の空白を除去する
        if dir ~= "" and not dir:match("^#") then                -- 空行とコメント行（# 始まり）を無視する
          dir = vim.fn.expand(dir)                               -- ~ などの環境変数・略記を展開する
          if vim.fn.isdirectory(dir) == 1 and not seen[dir] then -- 実在するディレクトリかつ未登録のみ追加
            seen[dir] = true
            table.insert(dirs, dir)
          end
        end
      end

      return dirs
    end

    -- キーマップ
    vim.keymap.set("n", "<Leader>ff", function() -- ファイル検索（find files）
      local dirs = priority_scope_dirs()
      if #dirs > 0 then
        -- スコープが定義されていれば対象ディレクトリ限定でファイル検索
        builtin.find_files({
          search_dirs = dirs,
          prompt_title = "Priority Scope Files",
        })
      else
        -- スコープ未定義ならカレントディレクトリ以下を対象に通常検索
        builtin.find_files()
      end
    end, { desc = "優先スコープでファイル検索" })

    vim.keymap.set("n", "<Leader>fg", function() -- 全文検索（find grep）
      local dirs = priority_scope_dirs()
      if #dirs > 0 then
        -- スコープが定義されていれば対象ディレクトリ限定で全文検索
        builtin.live_grep({
          search_dirs = dirs,
          prompt_title = "Priority Scope Grep",
        })
      else
        -- スコープ未定義ならカレントディレクトリ以下を対象に通常検索
        builtin.live_grep()
      end
    end, { desc = "優先スコープで全文検索" })
  end,
}