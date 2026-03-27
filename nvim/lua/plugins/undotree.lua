-- undotree.lua — Undo 履歴をツリー表示して分岐復元を可能にする

return {
  "mbbill/undotree",
  init = function()
    local undo_dir = vim.fn.stdpath("state") .. "/undo"
    if vim.fn.isdirectory(undo_dir) == 0 then
      vim.fn.mkdir(undo_dir, "p")
    end

    -- 端末再起動後も Undo 履歴を復元できるようにする。
    vim.opt.undofile = true
    vim.opt.undodir = undo_dir

    -- Undo ツリーを開閉する。
    vim.keymap.set("n", "<Leader>u", "<Cmd>UndotreeToggle<CR>", {
      silent = true,
      desc = "UndoTree: 開閉",
    })
  end,
}
