-- ===========================================================================
-- init.lua — Neovim のメイン設定ファイル
--
-- 構成:
--   このファイル    … 基本設定 + AtCoder 用キーマップ
--   lua/plugins/   … プラグインごとの設定（lazy.nvim が自動で読み込む）
--     copilot.lua  … GitHub Copilot（AI 補完 + チャット）
--     cmp.lua      … nvim-cmp（入力補完のポップアップ）
--     lsp.lua      … LSP（nimlangserver との接続）
--     telescope.lua… Telescope（ファイル検索・全文検索）
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- 基本設定（エディタの見た目と挙動）
-- ---------------------------------------------------------------------------
vim.opt.number         = true   -- 行番号を表示する
vim.opt.relativenumber = true   -- カーソルからの相対行番号も表示する
vim.opt.tabstop        = 2     -- Tab キーの幅を半角2文字分にする
vim.opt.shiftwidth     = 2     -- 自動インデントの幅を半角2文字分にする
vim.opt.expandtab      = true   -- Tab キーを押したらスペースに変換する
vim.opt.smartindent    = true   -- 改行時にインデントを自動調整する
vim.g.mapleader        = " "   -- Space キーを Leader キー（ショートカットの起点）にする

-- ---------------------------------------------------------------------------
-- lazy.nvim（プラグインマネージャ）の自動インストールと起動
-- ---------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- lua/plugins/ フォルダ内の設定ファイルを自動で読み込む
require("lazy").setup({
  spec = { { import = "plugins" } },
})

-- ---------------------------------------------------------------------------
-- AtCoder 用キーマップ（tmux の下ペインにコマンドを送り込む）
--
-- 前提: tmux/start-main.sh で起動すると、上ペインが Neovim、
--       下ペインがシェルになる。ここではその下ペインにコマンドを送る。
-- ---------------------------------------------------------------------------
local env_dir = vim.fn.expand("~/atcoder-nim-env")

--- 現在開いているファイルの、atcoder-nim-env からの相対パスを返す
local function get_make_file()
  local abs = vim.fn.expand("%:p")
  return abs:gsub("^" .. vim.pesc(env_dir) .. "/", "")
end

--- tmux の下ペイン（ペイン番号2）にコマンドを送って実行する
local function tmux_send(cmd)
  vim.cmd("w") -- まず保存
  vim.fn.system(string.format("tmux send-keys -t main:editor.2 '%s' Enter", cmd))
end

-- Leader + c : コンパイル
vim.keymap.set("n", "<Leader>c", function()
  tmux_send(string.format("make -C %s build FILE=%s", env_dir, get_make_file()))
end, { silent = true, desc = "AtCoder: コンパイル" })

-- Leader + s : テスト＋自動提出（ファイル名から URL を推測）
vim.keymap.set("n", "<Leader>s", function()
  tmux_send(string.format("make -C %s submit-auto FILE=%s", env_dir, get_make_file()))
end, { silent = true, desc = "AtCoder: テスト＋提出" })

-- Leader + u : テスト＋提出（クリップボードの URL を使う）
vim.keymap.set("n", "<Leader>u", function()
  local url = vim.fn.getreg("+"):gsub("%s+", "")
  if url == "" then
    print("クリップボードが空です")
    return
  end
  tmux_send(string.format("make -C %s submit-url FILE=%s URL=%s", env_dir, get_make_file(), url))
end, { silent = true, desc = "AtCoder: URL 指定で提出" })

-- Leader + b : バンドル（ライブラリ展開）してクリップボードにコピー
vim.keymap.set("n", "<Leader>b", function()
  vim.cmd("w")
  vim.fn.system(string.format("make -C %s bundle FILE=%s", env_dir, get_make_file()))
  local target = env_dir .. "/bundled.txt"
  if vim.fn.filereadable(target) == 1 then
    local lines = vim.fn.readfile(target)
    vim.fn.setreg("+", table.concat(lines, "\n") .. "\n")
    print("バンドル結果をクリップボードにコピーしました")
  else
    print("エラー: " .. target .. " が見つかりません")
  end
end, { silent = true, desc = "AtCoder: バンドル＋コピー" })
