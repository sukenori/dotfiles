-- cmp.lua — nvim-cmp（入力補完ポップアップ）の共通設定
--
-- ここに置くのは「どのプロジェクトでも使う」補完だけ。
-- 過去解答の横断検索・ライブラリのinclude/import・snippetの一覧検索は
-- すべて Telescope 側（プロジェクトローカル設定）へ移し、
-- cmpはLSPとLuaSnipという「素直な二本柱」だけを持つ。

return {
  "hrsh7th/nvim-cmp", -- プラグインマネージャの lazy.nvim に以下の設定をした nvim-cmp を渡す
  dependencies = {
    "L3MON4D3/LuaSnip",         -- スニペットエンジン
    "saadparwaiz1/cmp_luasnip", -- LuaSnip を補完ソースとして使うためのアダプタ
    "hrsh7th/cmp-nvim-lsp",     -- LSP を補完ソースとして使うためのアダプタ
  },
  config = function() -- 初期設定用関数宣言
    local cmp = require("cmp")         -- cmp プラグインの機能（モジュール）を変数に呼び出し
    local luasnip = require("luasnip") -- luasnip プラグインの機能（モジュール）を変数に呼び出し

    -- 補完候補の情報源とその表示順位（上から優先度が高い）を決める関数
    --
    -- プロジェクトローカル側（例: atcoder-nim-env/.nvim.lua）では、
    -- この上に cmp.setup.buffer({ sources = ... }) を重ねて
    -- line_rg のようなプロジェクト固有sourceを buffer 単位で追加できる。
    -- ここでは「どこでも安全に使える」二本だけを既定にする。
    local function build_sources()
      return cmp.config.sources({
        { name = "luasnip" },  -- スニペット
        { name = "nvim_lsp" }, -- LSP
      })
    end

    -- nvim-cmp 全体のセットアップ
    cmp.setup({
      -- 候補表示時に先頭を自動選択しない
      preselect = cmp.PreselectMode.None,
      completion = {
        completeopt = "menu,menuone,noinsert,noselect",
      },

      -- 補完候補の中からスニペットが選ばれた場合は LuaSnip を使って展開
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },

      -- 挿入モードでのキー操作設定
      mapping = cmp.mapping.preset.insert({
        -- Ctrl+Space 手動で補完候補を出す
        ["<C-Space>"] = cmp.mapping.complete(),

        -- Ctrl+e 補完／選択を中断して exit
        ["<C-e>"] = cmp.mapping.abort(),

        -- Ctrl+n （補完を開き）next の候補に進む
        ["<C-n>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
          else
            cmp.complete()
          end
        end, { "i", "s" }), -- 挿入モードと選択モード

        -- Ctrl+p previous 逆方向（上）に移動
        ["<C-p>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
          else
            fallback()
          end
        end, { "i", "s" }),

        -- Enter 「候補を明示選択している時だけ」確定（未選択なら通常改行）
        ["<CR>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            local entry = cmp.get_selected_entry()
            if entry then
              cmp.confirm({ select = false })
              return
            end
          end
          fallback()
        end, { "i", "s" }),

        -- Ctrl+f 補完に付随するドキュメントを下（forward）にスクロール
        ["<C-f>"] = cmp.mapping.scroll_docs(4),

        -- Ctrl+b ドキュメントを上（backward）にスクロール
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
      }),

      -- 先ほど定義した補完ソースの優先順位を適用して nvim-cmp のセットアップを終了
      sources = build_sources(),
    })
  end,
}