-- lsp.lua — LSP（Language Server Protocol）の共通設定

return {
  "neovim/nvim-lspconfig",
  config = function()
    -- nvim-cmp が入っている場合は、LSP の補完 capability を共通設定として配布
    if vim.lsp and vim.lsp.config then
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      if ok_cmp then
        capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
      end
      vim.lsp.config("*", {
        capabilities = capabilities,
      })
    end    

    -- 診断（エラー・警告）の設定
    vim.diagnostic.config({
      virtual_text = {   -- 行の右端に表示されるインラインの診断テキスト（バーチャルテキスト）の設定
        source = "if_many",  -- ソースが複数ある時はソース名を表示
        spacing = 1,  -- コード本体とバーチャルテキストの間隔を1に
      },
      underline = true,       -- 問題のある箇所に下線を引く
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = "E",
          [vim.diagnostic.severity.WARN] = "W",
          [vim.diagnostic.severity.INFO] = "I",
          [vim.diagnostic.severity.HINT] = "H",
        },
      },
      update_in_insert = true,  -- 入力中も診断を更新して、位置と内容を追従させる
      severity_sort = true,   -- 重要度の高い診断を優先して扱う
      float = {
        border = "rounded",  -- ポップアップの枠線を角丸に
        source = "if_many",
        scope = "cursor",   -- 行全体ではなく、現在カーソルが乗っている位置のエラーのみを表示
        focus = false,  -- カーソルのフォーカスをエディタ側に残す
      },
    })

    -- LSP が各バッファにアタッチしたときに、そのバッファ専用のキーマップをグローバルに設定する
    vim.api.nvim_create_autocmd("LspAttach", {
      -- 同じ種類の autocommand を UserLspKeymaps にまとめて重複を防ぐ
      -- clear = true にして再読み込み時に古い定義が残らないようにする
      group = vim.api.nvim_create_augroup("UserLspKeymaps", { clear = true }),
      callback = function(ev) -- LSP がアタッチされた時に実行されるコールバック関数
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
        -- カーソル位置のインターフェースの実装場所へジャンプする
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
        -- 変数名などをプロジェクト全体で安全に変更する
        vim.keymap.set("n", "<Leader>rn", vim.lsp.buf.rename, opts)
        -- その場で実行できる自動importの追加やエラーの自動修正などのメニュー（code action）を表示する
        vim.keymap.set("n", "<Leader>ca", vim.lsp.buf.code_action, opts)
        -- 1つ前のエラーや警告に移動する
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
        -- 1つ次のエラーや警告に移動する
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
      end,
    })
  end,
}