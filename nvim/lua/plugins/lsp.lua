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
    vim.diagnostic.config({
      virtual_text = true,
      underline = true,
      signs = true,
      update_in_insert = false,
      severity_sort = true,
    })

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspKeymaps", { clear = true }),
      callback = function(ev)
        local opts = { buffer = ev.buf, silent = true }
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
        vim.keymap.set("n", "<Leader>rn", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<Leader>ca", vim.lsp.buf.code_action, opts)
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
        vim.keymap.set("n", "<Leader>le", vim.diagnostic.open_float, opts)
      end,
    })

    -- nvim-cmp の補完機能を LSP に伝える（これで LSP 由来の補完候補が出る）
    local capabilities = require("cmp_nvim_lsp").default_capabilities()
    local nimble_bin = vim.fn.expand("~/.nimble/bin")
    local server = nimble_bin .. "/nimlangserver"
    local server_path = nimble_bin .. ":/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    local cmd = {
      "distrobox",
      "enter",
      "atcoder-env",
      "--",
      "env",
      "PATH=" .. server_path,
      server,
    }

    -- Neovim 0.11 以降の新しい LSP 設定 API を使う
    if vim.lsp.config then
      vim.lsp.config("nim_langserver", {
        -- Distrobox 経由でコンテナ内の nimlangserver を起動する
        -- nimlangserver が内部で呼ぶ nimsuggest 用に PATH も明示する
        cmd = cmd,
        filetypes = { "nim" },
        -- プロジェクトのルートを判定するファイル（nim.cfg があるフォルダがルート）
        root_markers = { "nim.cfg", ".git" },
        capabilities = capabilities,
      })
      vim.lsp.enable("nim_langserver")
    else
      -- Neovim 0.10 以前のフォールバック
      require("lspconfig").nim_langserver.setup({
        cmd = cmd,
        capabilities = capabilities,
      })
    end
  end,
}
