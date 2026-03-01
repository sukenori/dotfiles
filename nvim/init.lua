-- 行番号を表示する
vim.opt.number = true

-- クリップボードをOS（Windows）と共有する（ヤンクでWindows側にもコピーされる）
vim.opt.clipboard = "unnamedplus"

-- タブ入力を空白文字に置き換える
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4

-- 検索時に大文字小文字を区別しない（ただし大文字を含めた場合は区別する）
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- マウス操作を有効にする
vim.opt.mouse = "a"

