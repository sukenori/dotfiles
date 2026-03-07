return {
  "hrsh7th/nvim-cmp",
  dependencies = {
    "neovim/nvim-lspconfig",
    "hrsh7th/cmp-nvim-lsp",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
  },
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")

    cmp.setup({
      -- スニペットエンジンの指定
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      
      -- キーマッピング（定番のTabキー移動設定）
      mapping = cmp.mapping.preset.insert({
        ["<C-Space>"] = cmp.mapping.complete(), -- 手動で補完枠を出す
        ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Enterで確定

        -- Tabキーで次の候補へ（またはスニペットの次の入力枠へ）
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, { "i", "s" }),

        -- Shift+Tabで前の候補へ
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

      -- 情報源（ソース）の登録と優先順位
      sources = cmp.config.sources({
        { name = "nvim_lsp" }, -- 1. LSP（nimlangserver）からの関数や型情報
        { name = "luasnip" },  -- 2. 自作のLuaSnipスニペット
      })
    })
  end,
}

