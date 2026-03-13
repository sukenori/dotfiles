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
    "hrsh7th/cmp-nvim-lsp",     -- LSP を補完ソースとして使うためのアダプタ
    "L3MON4D3/LuaSnip",         -- スニペットエンジン
    "saadparwaiz1/cmp_luasnip", -- LuaSnip を補完ソースとして使うためのアダプタ
  },
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")

    cmp.setup({
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
        ["<CR>"]      = cmp.mapping.confirm({ select = true }), -- Enter で確定

        -- Tab で次の候補 / スニペットの次の入力欄へ移動
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, { "i", "s" }),

        -- Shift+Tab で前の候補へ
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      }),

      -- 補完候補の情報源（上から優先度が高い）
      sources = cmp.config.sources({
        { name = "nvim_lsp" }, -- LSP からの候補
        { name = "luasnip" },  -- スニペット
      }),
    })
  end,
}