-- ===========================================================================
-- lsp.lua — LSP（Language Server Protocol）の共通設定
--
-- ここでは診断表示や、LSP が attach された後の共通キーマップだけを定義する。
-- 言語ごとのサーバー起動方法は、グローバル設定に埋め込まず、
-- 必要なプロジェクト側の .nvim.lua などで追加する。
-- ===========================================================================
return {
  "neovim/nvim-lspconfig",
  config = function()
    local function apply_lsp_visual_highlights()
      -- 意味ハイライトは LSP semantic token を優先し、通常の構文色へ自然に寄せる。
      vim.api.nvim_set_hl(0, "@lsp.type.function", { link = "Function" })
      vim.api.nvim_set_hl(0, "@lsp.type.method", { link = "Function" })
      vim.api.nvim_set_hl(0, "@lsp.type.parameter", { link = "Identifier" })
      vim.api.nvim_set_hl(0, "@lsp.type.variable", { link = "Identifier" })
      vim.api.nvim_set_hl(0, "@lsp.type.property", { link = "Identifier" })

      -- 診断下線は装飾ではなく視認性を優先する。
      vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { undercurl = true })
      vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { undercurl = true })
      vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo", { undercurl = true })
      vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", { undercurl = true })
    end

    apply_lsp_visual_highlights()

    -- 色テーマ切替後も、意味ハイライトと診断下線の方針を維持する。
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("UserLspVisualHighlights", { clear = true }),
      callback = apply_lsp_visual_highlights,
    })

    -- 診断（エラー・警告）の見せ方をまとめて設定する。
    vim.diagnostic.config({
      virtual_text = false,   -- 画面ノイズを減らし、詳細はフロートウィンドウで確認する
      underline = true,       -- 問題のある箇所に下線を引く
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = "E",
          [vim.diagnostic.severity.WARN] = "W",
          [vim.diagnostic.severity.INFO] = "I",
          [vim.diagnostic.severity.HINT] = "H",
        },
      },
      update_in_insert = false, -- 入力中は診断を更新せず、ノイズを減らす
      severity_sort = true,   -- 重要度の高い診断を優先して扱う
      float = {
        border = "rounded",
        source = "if_many",
      },
    })

    -- LSP が各バッファに接続された瞬間だけ、そのバッファ専用のキーマップを設定する
    vim.api.nvim_create_autocmd("LspAttach", {
      -- 同じ種類の autocommand をまとめるグループ。
      -- clear = true にしておくと再読み込み時に古い定義が残らない。
      group = vim.api.nvim_create_augroup("UserLspKeymaps", { clear = true }),
      callback = function(ev)
        local client_id = ev.data and ev.data.client_id or nil
        local client = client_id and vim.lsp.get_client_by_id(client_id) or nil

        -- サーバーが semantic token（関数・変数・引数などの「意味」に基づく色分け用データ）を提供していれば明示的に開始する
        if client
          and client.server_capabilities.semanticTokensProvider
          and vim.lsp.semantic_tokens
          and vim.lsp.semantic_tokens.start
        then
          pcall(vim.lsp.semantic_tokens.start, ev.buf, client.id)
        end

        -- 今アタッチされたバッファだけに効く buffer-local keymap を作るにあたっての共通オプション
        local opts = { buffer = ev.buf, silent = true }

        -- カーソル位置のシンボルについて、型情報や説明を小さなウィンドウで表示する
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        -- カーソル位置の定義元へジャンプする
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        -- カーソル位置の宣言元へジャンプする
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
        -- カーソル位置のシンボルがどこで参照されているか一覧する
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        -- カーソル位置の実装へジャンプする
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
        -- シンボル名を安全に一括変更する
        vim.keymap.set("n", "<Leader>rn", vim.lsp.buf.rename, opts)
        -- その場で実行できる修正候補や変換候補を表示する
        vim.keymap.set("n", "<Leader>ca", vim.lsp.buf.code_action, opts)
        -- 1つ前の診断へ移動する
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
        -- 1つ次の診断へ移動する
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
        -- カーソル位置の診断内容をフロートで表示する
        vim.keymap.set("n", "<Leader>le", vim.diagnostic.open_float, opts)
      end,
    })
  end,
}