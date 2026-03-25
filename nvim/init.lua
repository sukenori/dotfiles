-- init.lua — Neovim のメイン設定ファイル

-- 基本設定（エディタの見た目と挙動）
vim.opt.number         = true   -- 行番号を表示する
vim.opt.relativenumber = false  -- 相対行番号は既定で無効（エラーメッセージの行番号と合わせやすくする）
vim.opt.tabstop        = 2     -- Tab キーの幅を半角2文字分にする
vim.opt.shiftwidth     = 2     -- 自動インデントの幅を半角2文字分にする
vim.opt.expandtab      = true   -- Tab キーを押したらスペースに変換する
vim.opt.smartindent    = true   -- 改行時にインデントを自動調整する
vim.opt.timeout        = true   -- キーシーケンスのマッピング待機を有効化する
vim.opt.timeoutlen     = 500    -- 通常は軽快に操作できる待機時間
vim.opt.ttimeoutlen    = 10     -- 端末特殊キーの判定待ち時間
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
vim.keymap.set("i", "jj", "<Esc>", { silent = true, desc = "jjでノーマルモードへ戻る" })

-- Leader 入力待機を用途別に切り替える（通常/ゆっくり入力）
local timeout_profile = {
  fast = 200,
  slow = 1500,
}

local timeout_profile_name = "fast"
local function apply_timeout_profile(name)
  if name ~= "fast" and name ~= "slow" then
    return
  end
  timeout_profile_name = name
  vim.opt.timeoutlen = timeout_profile[name]
end

apply_timeout_profile(timeout_profile_name)

vim.keymap.set("n", "<Leader>tm", function()
  if timeout_profile_name == "fast" then
    apply_timeout_profile("slow")
    vim.notify("Timeout profile: slow (mobile)", vim.log.levels.INFO)
  else
    apply_timeout_profile("fast")
    vim.notify("Timeout profile: fast", vim.log.levels.INFO)
  end
end, { silent = true, desc = "Timeout profile toggle" })

-- クリップボード連携は OSC52 ベースに統一する。
-- これでコンテナ/SSH 越しでも `yy`, `p`, `"+y`, `"+p` を使いやすくする。
do
  local ok_osc52, osc52 = pcall(require, "vim.ui.clipboard.osc52")
  if ok_osc52 and osc52 then
    vim.g.clipboard = osc52
    vim.opt.clipboard = "unnamedplus"
  end
end

-- 端末で困ったら Ctrl+Shift+C / Ctrl+Shift+V を優先して使う。
-- その上で、Neovim 内の明示ショートカットも用意する。
vim.keymap.set({ "n", "v" }, "<Leader>y", '"+y', {
  silent = true,
  desc = "Copy to system clipboard",
})
vim.keymap.set("n", "<Leader>Y", '"+yy', {
  silent = true,
  desc = "Copy line to system clipboard",
})
vim.keymap.set({ "n", "v" }, "<Leader>p", '"+p', {
  silent = true,
  desc = "Paste from system clipboard",
})

-- LSP の状態確認・再起動
vim.keymap.set("n", "<Leader>ls", "<Cmd>LspStart<CR>", { silent = true, desc = "LSP: 起動" })
vim.keymap.set("n", "<Leader>li", "<Cmd>LspInfo<CR>", { silent = true, desc = "LSP: 状態確認" })
vim.keymap.set("n", "<Leader>lr", "<Cmd>LspRestart<CR>", { silent = true, desc = "LSP: 再起動" })

-- nvim を起動したカレントディレクトリ直下の .nvim.lua があれば読む
local function load_project_config_from_cwd()
  local uv = vim.uv or vim.loop
  local cwd = uv.cwd()
  local candidate = cwd .. "/.nvim.lua"
  local stat = uv.fs_stat(candidate)
  if not (stat and stat.type == "file") then
    return false
  end

  local ok, err = pcall(dofile, candidate)
  if not ok then
    vim.notify("project-local .nvim.lua の読み込みに失敗しました: " .. tostring(err), vim.log.levels.ERROR)
    return false
  end

  return true
end

-- 最後に project-local 設定を読むことで、必要ならグローバル設定を上書きできるようにする。
load_project_config_from_cwd()

-- project-local 設定適用後に、保存済みファイルへだけ LSP を起動する。
local function try_start_lsp_for_buffer(bufnr, opts)
  opts = opts or {}

  if not (bufnr and vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr)) then
    return false
  end

  if vim.bo[bufnr].buftype ~= "" then
    return false
  end

  local fname = vim.api.nvim_buf_get_name(bufnr)
  if fname == "" then
    return false
  end

  if vim.fn.filereadable(fname) ~= 1 and opts.write_if_missing then
    local can_write = vim.bo[bufnr].modifiable and not vim.bo[bufnr].readonly
    if can_write then
      pcall(vim.api.nvim_buf_call, bufnr, function()
        vim.cmd("silent! write")
      end)
    end
  end

  if vim.fn.filereadable(fname) ~= 1 then
    return false
  end

  pcall(vim.api.nvim_buf_call, bufnr, function()
    vim.cmd("silent! LspStart")
  end)
  return true
end

-- 起動直後は、引数で開かれたバッファに対して先に保存を試みてから LSP を起動する。
vim.schedule(function()
  try_start_lsp_for_buffer(vim.api.nvim_get_current_buf(), { write_if_missing = true })
end)

-- 新規ファイルは初回保存後に、既存ファイルは読み込み後に LSP 起動を試みる。
vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
  group = vim.api.nvim_create_augroup("UserLspStartForSavedFile", { clear = true }),
  callback = function(ev)
    local write_if_missing = (ev.event == "BufWritePost")
    try_start_lsp_for_buffer(ev.buf, { write_if_missing = write_if_missing })
  end,
})
