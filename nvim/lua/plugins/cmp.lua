-- cmp.lua — nvim-cmp（入力補完ポップアップ）の設定

return {
  "hrsh7th/nvim-cmp", -- プラグインマネージャの lazy.nvim に以下の設定をした nvim-cmp を渡す
  dependencies = {              -- 依存関係
    "L3MON4D3/LuaSnip",         -- スニペットエンジン
    "saadparwaiz1/cmp_luasnip", -- LuaSnip を補完ソースとして使うためのアダプタ
    "hrsh7th/cmp-nvim-lsp",     -- LSP を補完ソースとして使うためのアダプタ
  },
  config = function() -- プラグインがダウンロードされた直後に実行される初期設定用の無名関数宣言
    local cmp = require("cmp")         -- cmp プラグインの機能（モジュール）を変数に呼び出し
    local luasnip = require("luasnip") -- luasnip プラグインの機能（モジュール）を変数に呼び出し
    local line_rg_file_glob = (type(vim.g.user_line_rg_file_glob) == "string" and vim.g.user_line_rg_file_glob ~= "")
      and vim.g.user_line_rg_file_glob
      or nil          -- ripgrep の検索対象指定用グローバル変数があれば取得し、なければ nil を代入

    -- カーソルより前に「空白以外の文字」があるかどうかを判定する関数
    -- これを cmp の enabled 判定に使い、入力が空のときは補完自体を無効化する
    local function has_words_before()
      -- 現在カーソルがある行の文字列をそのまま取得
      local line = vim.api.nvim_get_current_line()
      -- カーソルの列番号（0始まり）を取得。行番号は使わないので [2] だけを取り出す
      local col = vim.api.nvim_win_get_cursor(0)[2]
      -- 行頭からカーソル位置までを切り出す（Luaのsubは1始まりだが、0始まりのcolをそのまま終端に使ってよい）
      local before_cursor = line:sub(1, col)
      -- 前後の空白を除いても文字列が残るなら true（＝何か入力されている）
      return vim.trim(before_cursor) ~= ""
    end

    -- ripgrep を使って行単位の補完を行うためのカスタムソース用オブジェクトと、それを生成する new 関数を定義
    local cp_source = {}
    function cp_source:new()
      return setmetatable({}, { __index = cp_source })
    end
    -- 補完のトリガーとして「空白以外の文字からカーソル位置まで」の正規表現を定義（offset を定義）
    function cp_source:get_keyword_pattern()
      return [[\S.*]]
    end
    -- 補完処理を定義
    function cp_source:complete(request, callback)
      -- 行頭からカーソル位置までの全体から、補完の開始位置（offset）から末尾までを切り出し
      local input = request.context.cursor_before_line:sub(request.offset)
      -- 念のため、空白を取り除く
      input = vim.trim(input)

      -- 入力が空文字列なら、ripgrep を起動せず即座に候補なしで終了する
      -- （空文字を rg にそのまま渡すと全行に一致してしまい、古い検索の残骸のような挙動につながるため）
      if input == "" then
        callback({ items = {}, isIncomplete = false })
        return
      end

      -- プロジェクトローカルにある検索スコープを指定する .nvim/scope_dirs.txt を探す
      local scope_file = vim.fs.find(".nvim/scope_dirs.txt", {
      path = vim.fn.getcwd(),
      upward = true,
      })[1]
      -- .nvim/scope_dirs.txt 内のディレクトリリストを作る
      local dirs = {}
      if scope_file then
        for _, line in ipairs(vim.fn.readfile(scope_file)) do
          local dir = vim.trim(line)
          if dir ~= "" and not dir:match("^#") then
            table.insert(dirs, vim.fn.expand(dir))
          end
        end
      end
      -- ファイルが存在しない、または有効なパスが 0 個の場合は補完候補なしとして処理を終了
      if #dirs == 0 then
        callback({ items = {}, isIncomplete = false })
        return
      end

      -- ripgrep の実行コマンドと引数を定義
      local cmd = {
        "rg",            -- ripgrepを呼ぶコマンド名
        "-F",            -- --fixed-strings 入力文字列（input）を正規表現としてではなく、ただの文字列としてそのまま検索させる（*や.といった記号が含まれていてもエラーにならない）
        "--no-heading",  -- ripgrepが返す「どのファイルで見つかったか」の見出しの出力をオフに
        "--no-filename", -- 先頭に付く「ファイル名:」という出力もオフに（「見つけた行のテキストだけ」を取得）
        "--smart-case",  -- キーワードがすべて小文字なら大文字・小文字を区別しない、大文字が1文字でも含まれていたら厳密に区別して探す
        "--color=never", -- 見つかった文字を赤くハイライトするなどの色付けを禁止（エスケープシーケンスが挿入されてテキストデータとして扱いにくくなるため）
        input,           -- 検索する文字列（常に「今の入力」を使う。固定文字列にしてはいけない）
      }
      -- グローバル変数でファイルパターンの指定があればコマンドに追加
      if line_rg_file_glob then
        table.insert(cmd, "--glob") -- ファイル名やパスのパターン（グロブパターン）で検索対象にする、ないし除外する
        table.insert(cmd, line_rg_file_glob)
      end
      -- コマンドの最後に検索対象となるディレクトリをすべて追加して完成
      for _, dir in ipairs(dirs) do
        table.insert(cmd, dir)
      end

      -- ripgrep の実行結果を受け取り、補完候補のリストを作成するための内部関数
      local function build_items(stdout, code)
        local items = {}
        -- コマンドが成功して出力がある場合、重複チェック用のテーブルを用意し、出力を改行ごとに分割して処理
        if code == 0 and stdout then
          local seen = {}
          for line in string.gmatch(stdout, "[^\r\n]+") do
            -- 各行の前後の空白を取り除き、入力中の文字列よりも長く、かつ入力文字列から始まっていて、まだリストにない文字列を抽出
            local text = vim.trim(line)
            if #text > #input and vim.startswith(text, input) and not seen[text] then
              -- 抽出した文字列に対し、重複チェックのフラグを立て、補完候補のデータ形式に整形してリストに追加
              seen[text] = true
              table.insert(items, {
                label = text,
                insertText = text,
                kind = cmp.lsp.CompletionItemKind.Text,
              })
            end
          end
        end

        return items
      end

      -- 非同期で ripgrep コマンドを実行し、完了後に build_items 関数で候補リストを作成、Neovimのメイン処理に結果を渡して補完メニューを表示させる
      -- .system は Neovim 外のコマンドを裏側で実行する関数、第1引数はコマンド、第2引数はバイナリではなくテキストデータを指定、第3引数はコマンド実行後の結果に実行する関数
      -- その第3引数の関数、obj に対する操作を function で受け、その下に書かれている
      vim.system(cmd, { text = true }, function(obj)
        -- rg（ripgrep）に限らず、.stdout はコマンドの標準出力、.code は終了コード（0 なら見つかった、1 なら見つからなかった、2 ならエラー）
        local items = build_items(obj.stdout, obj.code)
        -- .schedule は Neovim のメインループがアイドルになったときに渡した関数の実行を予約する
        vim.schedule(function()
          -- 補完候補のリストを受け取り、画面にポップアップを表示する nvim-cmp の関数
          -- isIncomplete は不完全かどうか（追加検索の必要性）
          callback({ items = items, isIncomplete = false })
        end)
      end)
    end

    -- 作成した一連のカスタムソース処理を、line_rg という名前で nvim-cmp に登録
    cmp.register_source("line_rg", cp_source:new())

    -- 補完候補の情報源とその表示順位（上から優先度が高い）を決める関数
    local function build_sources()
      return cmp.config.sources({
        { name = "luasnip" },  -- スニペット
        { name = "nvim_lsp" }, -- LSP
        { name = "line_rg" },  -- ripgrep ソース
      })
    end

    -- nvim-cmp 全体のセットアップ
    cmp.setup({
      -- cmp が「今この瞬間に補完を行うべきか」を毎回判定する公式フック
      -- カーソルの直前に文字が何もない（＝全部消した直後や改行直後）なら false を返し、
      -- cmp 自体を無効化して、開いていた補完メニューも閉じさせる
      -- これにより、以前あった「削除後も古い候補（headerなど）が残り続ける」現象を、
      -- 自作の abort() 呼び出しではなく cmp 本体の管理下で解消する
      enabled = function()
        return has_words_before()
      end,

      -- 候補表示時に先頭を自動選択しない
      preselect = cmp.PreselectMode.None,
      completion = {
        completeopt = "menu,menuone,noinsert,noselect",
      },

      -- 補完候補の中からスニペットが選ばれた場合は LuaSnip を使って展開
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },

      -- 挿入モードでのキー操作設定
      mapping = cmp.mapping.preset.insert({
        -- Ctrl+Space 手動で補完候補を出す
        ["<C-Space>"] = cmp.mapping.complete(),

        -- Ctrl+e 補完／選択を中断して exit
        ["<C-e>"] = cmp.mapping.abort(),

        -- Ctrl+n （補完を開き）next の候補に進む
        ["<C-n>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
          else
            cmp.complete()
          end
        end, { "i", "s" }), -- 挿入モードと選択モード

        -- previous 逆方向（上）に移動 Ctrlとpの操作です。メニューが出ていれば前の候補へ移動し、出ていなければ本来のキー動作を行います。
        ["<C-p>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
          else
            fallback()
          end
        end, { "i", "s" }),

        -- Enter は「候補を明示選択している時だけ確定」し、未選択なら通常改行へフォールバック Enterキーの操作です。メニューが表示されており、かつ矢印キーなどで明示的に候補を選んでいる時だけその候補を確定します。選んでいない場合は通常の改行を行います。
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

        -- forward ドキュメントを下にスクロール Ctrlとfで補完候補に付随するドキュメントを下にスクロールし、Ctrlとbで上にスクロールします。ここでキー操作の設定を終了します。
        ["<C-f>"]     = cmp.mapping.scroll_docs(4),

        -- backward ドキュメントを上にスクロール
        ["<C-b>"]     = cmp.mapping.scroll_docs(-4),
      }),

      -- 先ほど定義した補完ソースの優先順位を適用してnvim-cmpのセットアップを終了し、設定ファイル全体を閉じます。
      sources = build_sources(),
    })
  end,
}