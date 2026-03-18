-- ===========================================================================
-- cmp.lua — nvim-cmp（入力補完ポップアップ）の設定
--
-- コードを打っているときに、関数名や変数名の候補をポップアップで表示する。
-- 情報源は主に2つ:
--   1. LSP からの型情報・関数情報
--   2. LuaSnip からのスニペット（定型コード）
-- ===========================================================================
return {
  "hrsh7th/nvim-cmp",
  dependencies = {
    "L3MON4D3/LuaSnip",         -- スニペットエンジン
    "saadparwaiz1/cmp_luasnip", -- LuaSnip を補完ソースとして使うためのアダプタ
    "hrsh7th/cmp-nvim-lsp"      -- LSP を補完ソースとして使うためのアダプタ
  },
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    local compare = cmp.config.compare

    cmp.setup({
      -- 候補表示時に先頭を自動選択しない（誤確定を防ぐ）
      preselect = cmp.PreselectMode.None,
      completion = {
        completeopt = "menu,menuone,noinsert,noselect",
      },

      -- スニペットの展開方法を指定
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },

      -- キー操作の設定
      mapping = cmp.mapping.preset.insert({
        ["<C-b>"]     = cmp.mapping.scroll_docs(-4),          -- ドキュメントを上にスクロール
        ["<C-f>"]     = cmp.mapping.scroll_docs(4),           -- ドキュメントを下にスクロール
        ["<C-Space>"] = cmp.mapping.complete(),                -- 手動で補完候補を出す
        -- Enter は「候補を明示選択している時だけ確定」し、未選択なら通常改行へフォールバックする。
        -- これで `let` などを打って Enter した時に改行＋インデントが素直に効く。
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
        ["<C-e>"]     = cmp.mapping.abort(),                   -- 選択/補完を中断して抜ける

        -- 1キーで選択に入りつつ下へ進む。候補が見えていなければ補完を開く。
        ["<C-n>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
          else
            cmp.complete()
          end
        end, { "i", "s" }),

        -- 逆方向（上へ移動）。必要なら C-e で選択状態から脱出。
        ["<C-p>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
          else
            fallback()
          end
        end, { "i", "s" }),

        -- Tab で次の候補 / スニペットの次の入力欄へ移動
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, { "i", "s" }),

        -- Shift+Tab で前の候補へ
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      }),

      -- 文字一致だけでなく、LSP のスコア・sortText、最近使った候補、近傍性なども使って並び替える。
      sorting = {
        priority_weight = 2,
        comparators = {
          -- LSP 候補をわずかに優先する（同程度の候補が並んだ時に効く）。
          function(entry1, entry2)
            local lsp1 = entry1.source.name == "nvim_lsp"
            local lsp2 = entry2.source.name == "nvim_lsp"
            if lsp1 ~= lsp2 then
              return lsp1
            end
          end,
          compare.exact,
          compare.score,
          compare.recently_used,
          compare.locality,
          compare.kind,
          compare.sort_text,
          compare.length,
          compare.order,
        },
      },

      -- 補完候補の情報源（上から優先度が高い）
      sources = cmp.config.sources({
        { name = "nvim_lsp" }, -- LSP からの候補
        { name = "luasnip" },  -- スニペット
      }),
    })
  end,
}