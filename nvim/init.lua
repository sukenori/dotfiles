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

-- <Leader>c: 単純コンパイル (Compile)
vim.api.nvim_set_keymap('n', '<Leader>c', ':!make -C .. build FILE=work/%<CR>', { noremap = true, silent = false })

-- <Leader>b: バンドルのみ実行 (Bundle)
vim.api.nvim_set_keymap('n', '<Leader>b', ':!make -C .. bundle FILE=work/%<CR>', { noremap = true, silent = false })

-- <Leader>s: ファイル名類推でテスト・提出 (Submit)
vim.api.nvim_set_keymap('n', '<Leader>s', ':!make -C .. submit-auto FILE=work/%<CR>', { noremap = true, silent = false })

-- <Leader>u: クリップボードのURLでテスト・提出 (Url)
vim.api.nvim_set_keymap('n', '<Leader>u', ':!make -C .. submit-url FILE=work/% URL=<C-r>+<CR>', { noremap = true, silent = false })

-- <Leader>a: 机の上の片付け (Archive)
vim.api.nvim_set_keymap('n', '<Leader>a', ':!make -C .. archive<CR>', { noremap = true, silent = false })

