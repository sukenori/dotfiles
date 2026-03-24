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
vim.keymap.set("n", "<C-h>", "<C-w>h", { silent = true, desc = "左のウィンドウへ移動" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { silent = true, desc = "下のウィンドウへ移動" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { silent = true, desc = "上のウィンドウへ移動" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { silent = true, desc = "右のウィンドウへ移動" })
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

local function clipboard_copy_text(text)
  local in_docker = (vim.fn.filereadable("/.dockerenv") == 1)

  if vim.fn.executable("termux-clipboard-set") == 1 then
    vim.fn.system({ "termux-clipboard-set" }, text)
    if vim.v.shell_error == 0 then
      return true
    end
  end

  if vim.fn.executable("powershell.exe") == 1 then
    vim.fn.system({
      "powershell.exe",
      "-NoProfile",
      "-NonInteractive",
      "-ExecutionPolicy",
      "Bypass",
      "-Command",
      "$input | Set-Clipboard",
    }, text)
    if vim.v.shell_error == 0 then
      return true
    end
  end

  if vim.fn.executable("wl-copy") == 1 then
    vim.fn.system({ "wl-copy" }, text)
    if vim.v.shell_error == 0 then
      return true
    end
  end

  if vim.fn.executable("xclip") == 1 then
    vim.fn.system({ "xclip", "-selection", "clipboard" }, text)
    if vim.v.shell_error == 0 then
      return true
    end
  end

  local ok_osc52, osc52 = pcall(require, "vim.ui.clipboard.osc52")
  if ok_osc52 and type(osc52.copy) == "function" then
    local ok = pcall(function()
      osc52.copy("+")(vim.split(text, "\n", { plain = true }), "v")
    end)
    if ok then
      return true
    end
  end

  if in_docker then
    return false, "コンテナ内では貼り付け元取得が制限されます。貼り付けは端末側 Ctrl+Shift+V を使ってください"
  end
  return false, "利用可能な clipboard backend が見つかりません"
end

local function clipboard_paste_text()
  local in_docker = (vim.fn.filereadable("/.dockerenv") == 1)

  if vim.fn.executable("termux-clipboard-get") == 1 then
    local t = vim.fn.system({ "termux-clipboard-get" })
    if vim.v.shell_error == 0 then
      return t:gsub("\r\n", "\n")
    end
  end

  if vim.fn.executable("powershell.exe") == 1 then
    local t = vim.fn.system({
      "powershell.exe",
      "-NoProfile",
      "-NonInteractive",
      "-ExecutionPolicy",
      "Bypass",
      "-Command",
      "Get-Clipboard -Raw",
    })
    if vim.v.shell_error == 0 then
      return t:gsub("\r\n", "\n")
    end
  end

  if vim.fn.executable("wl-paste") == 1 then
    local t = vim.fn.system({ "wl-paste", "-n" })
    if vim.v.shell_error == 0 then
      return t
    end
  end

  if vim.fn.executable("xclip") == 1 then
    local t = vim.fn.system({ "xclip", "-o", "-selection", "clipboard" })
    if vim.v.shell_error == 0 then
      return t
    end
  end

  if in_docker then
    return nil, "コンテナ内 Neovim では外部 clipboard 取得が難しいため、端末側 Ctrl+Shift+V を使ってください"
  end
  return nil, "clipboard からの貼り付けに使える backend がありません"
end

local function paste_from_system_clipboard()
  local text, err = clipboard_paste_text()
  if not text then
    vim.notify(err, vim.log.levels.WARN)
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local mode = vim.api.nvim_get_mode().mode
  if mode:sub(1, 1) == "t" or vim.bo[bufnr].buftype == "terminal" then
    local ok_job, job_id = pcall(vim.api.nvim_buf_get_var, bufnr, "terminal_job_id")
    if not ok_job or type(job_id) ~= "number" then
      vim.notify("ターミナルのジョブIDを取得できません", vim.log.levels.WARN)
      return
    end

    vim.api.nvim_chan_send(job_id, text)
    return
  end

  vim.api.nvim_paste(text, true, -1)
end

local function copy_to_system_clipboard()
  local mode = vim.api.nvim_get_mode().mode
  local text = ""
  if mode == "v" or mode == "V" or mode == "\22" then
    local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
    vim.api.nvim_feedkeys(esc, "nx", false)
    text = table.concat(vim.fn.getregion(vim.fn.getpos("'<"), vim.fn.getpos("'>")), "\n")
  else
    text = vim.api.nvim_get_current_line()
  end

  local ok, err = clipboard_copy_text(text)
  if not ok then
    vim.notify(err, vim.log.levels.WARN)
  end
end

-- どこでも使えるクリップボード連携
-- <C-g>p は「Ctrl+g の後に p」を押す（同時押しではない）。
vim.keymap.set({ "n", "i", "t" }, "<C-g>p", paste_from_system_clipboard, {
  silent = true,
  desc = "Paste from system clipboard",
})
vim.keymap.set({ "n", "v" }, "<C-g>y", copy_to_system_clipboard, {
  silent = true,
  desc = "Copy to system clipboard",
})

-- 押し間違いを減らすための別名（Space リーダー）
vim.keymap.set({ "n", "i", "t" }, "<Leader>p", paste_from_system_clipboard, {
  silent = true,
  desc = "Paste from system clipboard",
})
vim.keymap.set({ "n", "v" }, "<Leader>y", copy_to_system_clipboard, {
  silent = true,
  desc = "Copy to system clipboard",
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
