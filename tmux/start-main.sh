#!/bin/bash
# ===========================================================================
# start-main.sh — AtCoder 作業用の tmux セッションを起動するスクリプト
#
# レイアウト:
#   ┌──────────────────────────┐
#   │  ペイン1: Neovim         │  ← ここで .nim ファイルを編集する
#   │  (~/atcoder-nim-env)     │
#   ├──────────────────────────┤
#   │  ペイン2: シェル (8行)   │  ← Neovim から make コマンドがここに飛ぶ
#   └──────────────────────────┘
#
# 使い方:
#   bash ~/dotfiles/tmux/start-main.sh
#   （既にセッションがあれば再接続する）
# ===========================================================================
set -eu

SESSION="main"

# 既にセッションが存在していたら、そこに接続するだけ
if tmux has-session -t "$SESSION" 2>/dev/null; then
  exec tmux attach -t "$SESSION"
fi

# 新しいセッションを作成（ウィンドウ名: editor）
tmux new-session -d -s "$SESSION" -n editor

# 上ペイン: atcoder-nim-env に移動して Neovim を起動
# --listen でソケットを開き、下ペインからファイルを開けるようにする
tmux send-keys -t "$SESSION":editor.1 "cd ~/atcoder-nim-env && nvim --listen /tmp/nvim-main.sock" C-m

# 下ペイン: シェルを8行分の高さで分割（make コマンドの出力先）
tmux split-window -v -l 8 -t "$SESSION":editor

# カーソルを上ペイン（Neovim）に戻す
tmux select-pane -t "$SESSION":editor.1

# セッションに接続
exec tmux attach -t "$SESSION"
