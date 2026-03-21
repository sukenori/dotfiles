-- cmp.lua — nvim-cmp（入力補完ポップアップ）の設定

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
    local compare = cmp.config.compare   -- nvim-cmpが用意している標準ソート関数群への参照

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
        ["<C-Space>"] = cmp.mapping.complete(),      -- 手動で補完候補を出す
        ["<C-e>"]     = cmp.mapping.abort(),         -- 補完／選択を中断して抜ける

        -- next 選択に入り下へ進む、候補が見えていなければ補完を開く
        ["<C-n>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
          else
            cmp.complete()
          end
        end, { "i", "s" }),

        -- previous 逆方向（上）に移動
        ["<C-p>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
          else
            fallback()
          end
        end, { "i", "s" }),
        
        -- Enter は「候補を明示選択している時だけ確定」し、未選択なら通常改行へフォールバック
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

        -- Tab で次の候補／スニペットの次の入力欄へ移動
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

        ["<C-f>"]     = cmp.mapping.scroll_docs(4),  -- forward ドキュメントを下にスクロール
        ["<C-b>"]     = cmp.mapping.scroll_docs(-4), -- backward ドキュメントを上にスクロール

      }),

      -- 文字一致だけでなく、LSP のスコア・sortText、最近使った候補、近傍性なども使って並び替える
      sorting = {
        priority_weight = 2,
        comparators = {
          -- LSP 由来をわずかに優先する
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