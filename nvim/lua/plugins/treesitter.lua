-- treesitter.lua — Tree-sitter 共通設定
-- project-local でマイナー言語の設定をする場合に備えてインデントは smartindent（init.lua）に任せ、treesitter では有効化しない

return {
  {
    "nvim-treesitter/nvim-treesitter",
    -- lazy update 実行時にパーサを一緒に更新
    build = ":TSUpdate",
    -- select / swap / move の textobjects 拡張機能
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    -- nvim-treesitter v0.9 系までは nvim-treesitter.configs モジュールに setup があった
    -- pcall で安全に require し、関数として取れた場合はそれを使う
    config = function()
      local ts_setup
      do
        local ok_configs, configs = pcall(require, "nvim-treesitter.configs")
        if ok_configs and type(configs.setup) == "function" then
          ts_setup = configs.setup
        -- v1.0 系への移行で setup の場所が nvim-treesitter 本体に移動した
        -- 上で取れなかった場合のフォールバック
        else
          local ok_main, main = pcall(require, "nvim-treesitter")
          if ok_main and type(main.setup) == "function" then
            ts_setup = main.setup
          end
        end
      end
      -- どちらの API でも setup が見つからなかった場合のガード
      if type(ts_setup) ~= "function" then
        vim.schedule(function()
          vim.notify("nvim-treesitter の setup 関数を読み込めませんでした", vim.log.levels.ERROR)
        end)
        return
      end

      -- 起動時に必ず入れておく汎用パーサーの一覧
      -- query は .scm クエリファイルの編集用、vim/vimdoc は Vim スクリプトとヘルプ文書用
      ts_setup({
        ensure_installed = {
          "bash",
          "lua",
          "markdown",
          "markdown_inline",
          "query",
          "vim",
          "vimdoc",
        },
        -- ensure_installed にないパーサでも、そのファイルタイプを開いた瞬間に自動インストールする
        auto_install = true,

        -- Tree-sitter ベースのハイライトを有効化する
        highlight = {
          enable = true,
          disable = { "nim" },
          -- 従来の正規表現 syntax ハイライトを無効にする（両方オンにすると処理が二重になって遅くなり、競合で色が乱れることもある）
          additional_vim_regex_highlighting = false,
        },

        incremental_selection = {
          enable = true,
          keymaps = {
            -- ノーマルモードで gnn と押すと、カーソル位置にある構文ノードの選択開始
            init_selection   = "gnn",
            -- その後、grn で一段外にノードへ拡張
            node_incremental = "grn",
            -- grm で逆に一段内のノードに縮小
            node_decremental = "grm",
          },
        },

        textobjects = {
          select = {
            enable    = true,
            -- カーソルが textobject の手前にいても先読みして次の対象を見つける
            lookahead = true,
            keymaps = {
              -- vaf で関数全体（シグネチャ＋本体）を選択（v でなく d（削除）や y（ヤンク）でも使える）
              ["af"] = "@function.outer",
              -- vif で本体のみを選択
              ["if"] = "@function.inner",
              -- vac でクラス全体を選択
              ["ac"] = "@class.outer",
              -- vic でクラス内部を選択
              ["ic"] = "@class.inner",
              -- vaa で引数ひとつ（カンマ含む）を選択
              ["aa"] = "@parameter.outer",
              -- via で引数の値のみを選択
              ["ia"] = "@parameter.inner",
            },
          },
          swap = {
            enable = true,
            -- ]a でカーソル位置の引数を次の引数と入れ替え
            swap_next     = { ["]a"] = "@parameter.inner" },
            -- [a で前の引数と入れ替え
            swap_previous = { ["[a"] = "@parameter.inner" },
          },
          move = {
            enable    = true,
            --  Ctrl+O/Ctrl+I のジャンプリストに乗る
            set_jumps = true,
            -- ]f で次の関数先頭
            goto_next_start     = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
            -- [f で前の関数先頭にジャンプ
            goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
          },
        },
      })
    end,
  },
}