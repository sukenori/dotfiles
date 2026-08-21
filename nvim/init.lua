-- init.lua — Neovim のメイン設定ファイル

-- 基本設定（エディタの見た目と挙動）
vim.opt.number         = true   -- 行番号を表示する
vim.opt.tabstop        = 2     -- Tab キーの幅を半角2文字分にする
vim.opt.shiftwidth     = 2     -- 自動インデントの幅を半角2文字分にする
vim.opt.expandtab      = true   -- Tab キーを押したらスペースに変換する
vim.opt.smartindent    = true   -- 改行時にインデントを自動調整する
vim.g.mapleader        = "\\"   -- Leader を \ にする
vim.g.maplocalleader   = "_"   -- プロジェクトローカルのキーマップは _ を起点にする

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

vim.g.loaded_zipPlugin = 1
vim.g.loaded_zip = 1

-- OSC52 でクリップボード連携
local osc52 = require("vim.ui.clipboard.osc52")
vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = osc52.copy("+"),
    ["*"] = osc52.copy("*"),
  },
  paste = {
    ["+"] = osc52.paste("+"),
    ["*"] = osc52.paste("*"),
  },
}
vim.opt.clipboard = "unnamedplus"

-- lazy.nvim の設定が終わった直後（バッファが開かれる前）に、nvim を起動したカレントディレクトリに .nvim.lua があれば読む
local local_cfg = vim.fn.getcwd() .. "/.nvim.lua"
if vim.fn.filereadable(local_cfg) == 1 then
  dofile(local_cfg)
end