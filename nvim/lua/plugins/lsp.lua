-- lsp.lua — LSP（Language Server Protocol）の共通設定

return {
  "neovim/nvim-lspconfig", -- プラグインマネージャの lazy.nvim に以下の設定をした nvim-lspconfig を渡す
  config = function()
    -- nvim-cmp が入っている場合は、LSP の補完 capability を共通設定として配布
    if vim.lsp and vim.lsp.config then
      -- Neovim が標準で持つ LSP クライアント能力（補完・hover・定義ジャンプなど）のデフォルトテーブルを生成
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      -- cmp_nvim_lsp プラグインを安全に読み込み
      local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      if ok_cmp then
        -- 読み込めたら、nvim-cmp の補完候補を LSP が返せるよう capabilities を拡張
        capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
      end
      -- "*" はすべての LSP サーバーへの一括適用
      vim.lsp.config("*", {
        capabilities = capabilities,
      })
    end

    -- NeoVim の診断（エラー・警告）表示の設定
    vim.diagnostic.config({
      virtual_text = {  -- 行の右端に表示されるインラインの診断テキスト（バーチャルテキスト）の設定
        source = "if_many",  -- ソースが複数ある時はソース名を表示
        spacing = 1,  -- コード本体とバーチャルテキストの間隔を1に
      },
      underline = true,  -- 問題のある箇所に下線を引く
      -- サインカラム（行番号の左側）に表示するアイコンの定義
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = "E",
          [vim.diagnostic.severity.WARN] = "W",
          [vim.diagnostic.severity.INFO] = "I",
          [vim.diagnostic.severity.HINT] = "H",
        },
      },
      update_in_insert = true,  -- 入力中も診断を更新して、位置と内容を追従させる
      severity_sort = true,   -- 重要度の高い順（アイコンの順）にソートする
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