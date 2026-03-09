-- ===========================================================================
-- lsp.lua — LSP（Language Server Protocol）の設定
--
-- nimlangserver を Distrobox コンテナ ("atcoder-env") 内で起動し、
-- ホスト側の Neovim と接続する。
-- これにより、コンテナ内の Nim 環境を使いながら、
-- ホスト側のエディタで補完・定義ジャンプ・エラー表示が効く。
-- ===========================================================================
return {
  "neovim/nvim-lspconfig",
  dependencies = { "hrsh7th/cmp-nvim-lsp" },
  config = function()
    -- nvim-cmp の補完機能を LSP に伝える（これで LSP 由来の補完候補が出る）
    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    -- Neovim 0.11 以降の新しい LSP 設定 API を使う
    if vim.lsp.config then
      vim.lsp.config("nim_langserver", {
        -- Distrobox 経由でコンテナ内の nimlangserver を起動する
        cmd = { "distrobox", "enter", "atcoder-env", "--", "nimlangserver" },
        filetypes = { "nim" },
        -- プロジェクトのルートを判定するファイル（nim.cfg があるフォルダがルート）
        root_markers = { "nim.cfg", ".git" },
        capabilities = capabilities,
      })
      vim.lsp.enable("nim_langserver")
    else
      -- Neovim 0.10 以前のフォールバック
      require("lspconfig").nim_langserver.setup({
        cmd = { "distrobox", "enter", "atcoder-env", "--", "nimlangserver" },
        capabilities = capabilities,
      })
    end
  end,
}
