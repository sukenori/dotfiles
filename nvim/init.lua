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

-- <Leader>b: バンドルを実行し、結果をクリップボードにコピー
vim.keymap.set('n', '<Leader>b', function()
  vim.cmd('!make -C .. bundle FILE=work/' .. vim.fn.expand('%'))
  
  -- Neovimから見て一つ上の階層を指定
  local target_file = '../bundled.txt'
  
  -- バンドル失敗時のエラー落ちを防ぐためのチェック
  if vim.fn.filereadable(target_file) == 1 then
    local lines = vim.fn.readfile(target_file)
    vim.fn.setreg('+', table.concat(lines, '\n') .. '\n')
    print('バンドル結果をクリップボードにコピーしました')
  else
    print('エラー: ' .. target_file .. ' が見つかりません。バンドルが失敗した可能性があります')
  end
end, { noremap = true, silent = true })

-- <Leader>s: ファイル名類推でテスト・提出 (Submit)
vim.api.nvim_set_keymap('n', '<Leader>s', ':!make -C .. submit-auto FILE=work/%<CR>', { noremap = true, silent = false })

-- <Leader>u: クリップボードのURLでテスト・提出 (Url)
vim.api.nvim_set_keymap('n', '<Leader>u', ':!make -C .. submit-url FILE=work/% URL=<C-r>+<CR>', { noremap = true, silent = false })

