-- quickfix_session.lua — Telescopeのquickfix閲覧セッション管理（プロジェクト非依存）
--
-- <C-q> でquickfixへ送って複数ファイルを覗いた後、
-- q 一発で「一覧を閉じる＋閲覧のために新規に開いたバッファを掃除する
-- ＋検索を始める前のバッファ・カーソル位置へ戻る」をまとめて行う。

local M = {}

local session = { win = nil, buf = nil, view = nil, bufs_before = nil }

function M.save()
  session.win = vim.api.nvim_get_current_win()
  session.buf = vim.api.nvim_get_current_buf()
  session.view = vim.fn.winsaveview()

  session.bufs_before = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    session.bufs_before[bufnr] = true
  end
end

function M.close()
  pcall(vim.cmd, "cclose")

  if session.bufs_before then
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if not session.bufs_before[bufnr] and vim.api.nvim_buf_is_valid(bufnr) then
        if not vim.bo[bufnr].modified then
          pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
        end
      end
    end
  end

  if session.win and vim.api.nvim_win_is_valid(session.win)
      and session.buf and vim.api.nvim_buf_is_valid(session.buf) then
    vim.api.nvim_win_set_buf(session.win, session.buf)
    vim.fn.winrestview(session.view)
  end
end

-- quickfix window (filetype=qf) 内でだけ q に割り当てる。
-- どのプロジェクトでも一度だけ呼べばよい。
function M.setup_qf_quit_key()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "qf",
    group = vim.api.nvim_create_augroup("QuickfixBrowseQuit", { clear = true }),
    callback = function(ev)
      vim.api.nvim_win_set_height(0, 6)
      vim.keymap.set("n", "q", M.close, { buffer = ev.buf, desc = "閲覧を終えて元のバッファへ戻る" })
    end,
  })
end

return M