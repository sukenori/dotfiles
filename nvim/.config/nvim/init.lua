-- init.lua — VSCode (vscode-neovim) とターミナル Neovim の共通設定

-- リーダーキー（<Leader>）
vim.g.mapleader = "\\"
-- ローカルリーダーキー（<LocalLeader>）
-- 混乱を避けるため <Leader> と同じに揃える
vim.g.maplocalleader = "\\"

-- trust エラーを避けるため exrc は使わず、後段で .nvim.lua を手動で読む
vim.opt.exrc = false

-- ホーム配下で所有者が自分の .nvim.lua だけを読み込む
local function load_project_config()
  local uv = vim.uv or vim.loop
  local cwd = uv.cwd()
  local home = vim.fn.expand("~")
  local uid = uv.getuid and uv.getuid() or nil

  while cwd and cwd:sub(1, #home) == home do
    local candidate = cwd .. "/.nvim.lua"
    local stat = uv.fs_stat(candidate)
    if stat and stat.type == "file" and (uid == nil or stat.uid == uid) then
      local ok, err = pcall(dofile, candidate)
      if not ok then
        vim.schedule(function()
          vim.notify(".nvim.lua 読み込み失敗: " .. tostring(err), vim.log.levels.ERROR)
        end)
      end
      return
    end

    if cwd == home then
      return
    end

    local parent = vim.fn.fnamemodify(cwd, ":h")
    if parent == cwd or parent == "" then
      return
    end
    cwd = parent
  end
end

if not vim.g.vscode then
  -- ターミナル Neovim のみの UI 設定
  vim.opt.number = true

  -- 補完メニュー表示の挙動を明示する
  -- menu: 候補メニューを出す
  -- menuone: 候補が1件でもメニューを出す
  -- noselect: 候補を自動選択しない（Enter 誤確定を防ぐ）
  vim.opt.completeopt = { "menu", "menuone", "noselect" }

  -- nvim-cmp を標準補完として使う
  local cmp = require("cmp")
  cmp.setup({
    snippet = {
      expand = function(args)
        if vim.snippet and vim.snippet.expand then
          vim.snippet.expand(args.body)
        end
      end,
    },
    mapping = cmp.mapping.preset.insert({
      ["<C-Space>"] = cmp.mapping.complete(), -- 補完メニューを手動で開く
      ["<CR>"] = cmp.mapping.confirm({ select = true }), -- 補完候補を確定する
      ["<Tab>"] = cmp.mapping.select_next_item(), -- 次の候補へ移動する
      ["<S-Tab>"] = cmp.mapping.select_prev_item(), -- 前の候補へ移動する
    }),
    sources = cmp.config.sources({
      { name = "nvim_lsp" }, -- Language Server 由来の補完
      { name = "path" }, -- ファイルパスの補完
      { name = "buffer" }, -- 現在バッファ内単語の補完
    }),
  })
end

load_project_config()
