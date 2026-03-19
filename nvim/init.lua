-- init.lua — Neovim のメイン設定ファイル

-- 基本設定（エディタの見た目と挙動）
vim.opt.number         = true   -- 行番号を表示する
vim.opt.relativenumber = false  -- 相対行番号は既定で無効（エラーメッセージの行番号と合わせやすくする）
vim.opt.tabstop        = 2     -- Tab キーの幅を半角2文字分にする
vim.opt.shiftwidth     = 2     -- 自動インデントの幅を半角2文字分にする
vim.opt.expandtab      = true   -- Tab キーを押したらスペースに変換する
vim.opt.smartindent    = true   -- 改行時にインデントを自動調整する
vim.opt.splitright     = true   -- 縦分割を右側に開く（CopilotChat 等）
vim.opt.termguicolors  = true   -- 24bit カラーを有効にして配色を見やすくする
vim.g.mapleader        = " "   -- Leader をスペースにする
vim.g.maplocalleader   = ","   -- プロジェクトローカルのキーマップは , を起点にする

-- 配色テーマと syntax ハイライトを明示的に有効化する。
vim.cmd("syntax enable")

-- lazy.nvim（プラグインマネージャ）のインストールと起動
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
-- lua/plugins/ フォルダ内のプラグイン設定ファイルを読み込む
require("lazy").setup({
  spec = { { import = "plugins" } },
})

-- 共通キーマップ
vim.keymap.set("n", "<Leader>w", "<Cmd>write<CR>", { silent = true, desc = "保存" })
vim.keymap.set("n", "<Leader>q", "<Cmd>quit<CR>", { silent = true, desc = "終了" })
vim.keymap.set("n", "<Leader>h", "<Cmd>nohlsearch<CR>", { silent = true, desc = "検索ハイライト解除" })
vim.keymap.set("n", "<Leader>nr", function()
  vim.o.relativenumber = not vim.o.relativenumber
end, { silent = true, desc = "相対行番号の切替" })
vim.keymap.set("n", "<C-h>", "<C-w>h", { silent = true, desc = "左のウィンドウへ移動" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { silent = true, desc = "下のウィンドウへ移動" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { silent = true, desc = "上のウィンドウへ移動" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { silent = true, desc = "右のウィンドウへ移動" })

-- LSP の状態確認・再起動
vim.keymap.set("n", "<Leader>ls", "<Cmd>LspStart<CR>", { silent = true, desc = "LSP: 起動" })
vim.keymap.set("n", "<Leader>li", "<Cmd>LspInfo<CR>", { silent = true, desc = "LSP: 状態確認" })
vim.keymap.set("n", "<Leader>lr", "<Cmd>LspRestart<CR>", { silent = true, desc = "LSP: 再起動" })

-- 現在の作業ディレクトリから親をたどり、project-local の .nvim.lua を1つだけ読む
local function load_project_config()
  local uv = vim.uv or vim.loop
  local cwd = uv.cwd()

  while cwd and cwd ~= "" do
    local candidate = cwd .. "/.nvim.lua"
    local stat = uv.fs_stat(candidate)
    if stat and stat.type == "file" then
      dofile(candidate)
      return
    end

    local parent = vim.fn.fnamemodify(cwd, ":h")
    if parent == cwd or parent == "" then
      return
    end
    cwd = parent
  end
end
-- 最後に project-local 設定を読むことで、必要ならグローバル設定を上書きできるようにする。
load_project_config()
