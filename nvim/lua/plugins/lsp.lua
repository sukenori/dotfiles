return {
  "neovim/nvim-lspconfig",
  config = function()
    -- cmp-nvim-lspの機能（入力補完能力）をLSPサーバーに教え込む準備
    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    -- nimlangserverの起動と接続
    require("lspconfig").nimlangserver.setup({
      capabilities = capabilities,
    })
  end,
}

