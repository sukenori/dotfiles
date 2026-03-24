-- cmp.lua — nvim-cmp（入力補完ポップアップ）の設定

return {
  "hrsh7th/nvim-cmp",
  dependencies = {
    "L3MON4D3/LuaSnip",         -- スニペットエンジン
    "saadparwaiz1/cmp_luasnip", -- LuaSnip を補完ソースとして使うためのアダプタ
    "hrsh7th/cmp-nvim-lsp",     -- LSP を補完ソースとして使うためのアダプタ
  },
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    local uv = vim.uv or vim.loop
    local line_rg_file_glob = (type(vim.g.user_line_rg_file_glob) == "string" and vim.g.user_line_rg_file_glob ~= "")
      and vim.g.user_line_rg_file_glob
      or nil
    local startswith = vim.startswith or function(s, prefix)
      return s:sub(1, #prefix) == prefix
    end

    -- .nvim/ripgrep_scope_dirs.txt から検索スコープを
    local function find_scope_file(bufnr)
      local function find_from(start_path)
        if not start_path or start_path == "" then
          return nil
        end

        local found = vim.fs.find(".nvim/ripgrep_scope_dirs.txt", {
          path = start_path,
          upward = true,
        })[1]

        if found and vim.fn.filereadable(found) == 1 then
          return found
        end

        return nil
      end

      local bufname = vim.api.nvim_buf_get_name(bufnr or 0)
      if bufname ~= "" then
        local abs = vim.fn.fnamemodify(bufname, ":p")
        local real = uv.fs_realpath(abs) or abs
        local from_buf = find_from(vim.fs.dirname(real))
        if from_buf then
          return from_buf
        end
      end

      return find_from(uv.cwd())
    end

    local function priority_scope_dirs(bufnr)
      local scope_file = find_scope_file(bufnr)
      if not scope_file then
        return {}
      end

      local dirs = {}
      local seen = {}

      for _, line in ipairs(vim.fn.readfile(scope_file)) do
        local dir = vim.trim(line)
        if dir ~= "" and not dir:match("^#") then
          dir = vim.fn.expand(dir)
          if vim.fn.isdirectory(dir) == 1 and not seen[dir] then
            seen[dir] = true
            table.insert(dirs, dir)
          end
        end
      end

      return dirs
    end

    -- ripgrep を行単位で利用するカスタムソース
    local cp_source = {}
    function cp_source:new()
      return setmetatable({}, { __index = cp_source })
    end

    function cp_source:get_keyword_pattern()
      -- 空白以外の文字からカーソル位置までを「ひと塊のキーワード」として扱う
      return [[\S.*]]
    end

    function cp_source:complete(request, callback)
      local input = request.context.cursor_before_line:sub(request.offset)
      input = vim.trim(input)

      local dirs = priority_scope_dirs(request.context.bufnr)
      if #dirs == 0 then
        callback({ items = {}, isIncomplete = false })
        return
      end

      -- 固定文字列検索で記号をそのまま扱う。
      local cmd = {
        "rg",
        "-F",
        "--no-heading",
        "--no-filename",
        "--smart-case",
        "--color=never",
        input,
      }
      if line_rg_file_glob then
        table.insert(cmd, "--glob")
        table.insert(cmd, line_rg_file_glob)
      end
      for _, dir in ipairs(dirs) do
        table.insert(cmd, dir)
      end

      local function build_items(stdout, code)
        local items = {}
        if code == 0 and stdout then
          local seen = {}
          for line in string.gmatch(stdout, "[^\r\n]+") do
            local text = vim.trim(line)
            if #text > #input and startswith(text, input) and not seen[text] then
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

      vim.system(cmd, { text = true }, function(obj)
        local items = build_items(obj.stdout, obj.code)

        vim.schedule(function()
          callback({ items = items, isIncomplete = false })
        end)
      end)
    end

    cmp.register_source("line_rg", cp_source:new())

    -- 補完候補の情報源（上から優先度が高い）
    local function build_sources()
      return cmp.config.sources({
        { name = "luasnip" },  -- スニペット
        { name = "nvim_lsp" }, -- LSP
        { name = "line_rg" },
      })
    end

    cmp.setup({
      -- 候補表示時に先頭を自動選択しない（誤確定を防ぐ）
      preselect = cmp.PreselectMode.None,
      completion = {
        completeopt = "menu,menuone,noinsert,noselect",
      },

      -- スニペットの展開方法を指定
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },

      -- キー操作の設定
      mapping = cmp.mapping.preset.insert({
        ["<C-Space>"] = cmp.mapping.complete(), -- 手動で補完候補を出す
        ["<C-e>"]     = cmp.mapping.abort(),    -- 補完／選択を中断して抜ける

        -- next 選択に入り下へ進む、候補が見えていなければ補完を開く
        ["<C-n>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
          else
            cmp.complete()
          end
        end, { "i", "s" }),

        -- previous 逆方向（上）に移動
        ["<C-p>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
          else
            fallback()
          end
        end, { "i", "s" }),

        -- Tab で次の候補／スニペットの次の入力欄へ移動
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, { "i", "s" }),

        -- Shift+Tab で前の候補へ移動
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),

        -- Enter は「候補を明示選択している時だけ確定」し、未選択なら通常改行へフォールバック
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

        -- forward ドキュメントを下にスクロール
        ["<C-f>"]     = cmp.mapping.scroll_docs(4),

        -- backward ドキュメントを上にスクロール
        ["<C-b>"]     = cmp.mapping.scroll_docs(-4),
      }),

      sources = build_sources(),
    })
  end,
}