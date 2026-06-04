-- tmux.lua — vim-tmux-navigator の設定
-- Neovim のウィンドウから tmux のペインに同じキーバインドでシームレスに移動できるようにするプラグイン

return {
  "christoomey/vim-tmux-navigator", -- プラグインマネージャの lazy.nvim に以下の設定をした vim-tmux-navigator を渡す
  -- 起動時間を短縮する目的で、cmd に列挙したコマンドが呼ばれたときに初めてプラグインをロードする（lazy load）
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
  },

  keys = {
    -- Ctrl+h/j/k/l でそれぞれの方向へ移動
    -- <C-U> はコマンドライン上の余分な入力をクリアするための記法
    -- 反対となる tmux のペインからの（Neovim への）ペイン移動は .tmux.conf で規定している
    { "<C-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
    { "<C-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
    { "<C-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
    { "<C-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
  },
}