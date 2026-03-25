return {
  "christoomey/vim-tmux-navigator",
  -- 必要コマンドが呼ばれるまで遅延ロードして起動コストを抑える。
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
  },
  -- tmux 側の同名キー設定と合わせて境界をまたいだ移動を実現する。
  keys = {
    { "<C-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
    { "<C-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
    { "<C-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
    { "<C-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
  },
}
