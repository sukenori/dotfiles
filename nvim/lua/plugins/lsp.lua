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
    -- 診断（エラー・警告）の見せ方をまとめて設定する。
    vim.diagnostic.config({
      virtual_text = true,    -- 行内にエラー内容を直接表示する
      underline = true,       -- 問題のある箇所に下線を引く
      signs = true,           -- 行番号横に記号を出して問題の有無を見やすくする
      update_in_insert = false, -- 入力中は診断を更新せず、ノイズを減らす
      severity_sort = true,   -- 重要度の高い診断を優先して扱う
    })

    -- LSP が各バッファに接続された瞬間だけ、そのバッファ専用のキーマップを設定する。
    vim.api.nvim_create_autocmd("LspAttach", {
      -- 同じ種類の autocommand をまとめるグループ。
      -- clear = true にしておくと再読み込み時に古い定義が残らない。
      group = vim.api.nvim_create_augroup("UserLspKeymaps", { clear = true }),
      callback = function(ev)
        -- 今アタッチされたバッファだけに効く buffer-local keymap を作るための共通オプション。
        local opts = { buffer = ev.buf, silent = true }

        -- カーソル位置のシンボルについて、型情報や説明を小さなウィンドウで表示する。
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        -- カーソル位置の定義元へジャンプする。
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        -- カーソル位置の宣言元へジャンプする。
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
        -- カーソル位置のシンボルがどこで参照されているか一覧する。
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        -- カーソル位置の実装へジャンプする。
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
        -- シンボル名を安全に一括変更する。
        vim.keymap.set("n", "<Leader>rn", vim.lsp.buf.rename, opts)
        -- その場で実行できる修正候補や変換候補を表示する。
        vim.keymap.set("n", "<Leader>ca", vim.lsp.buf.code_action, opts)
        -- 1つ前の診断へ移動する。
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
        -- 1つ次の診断へ移動する。
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
        -- カーソル位置の診断内容をフロートで表示する。
        vim.keymap.set("n", "<Leader>le", vim.diagnostic.open_float, opts)
      end,
    })
  end,
}