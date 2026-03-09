#!/bin/bash
set -eu

SESSION=main

if tmux has-session -t "$SESSION" 2>/dev/null; then
  exec tmux attach -t "$SESSION"
fi

tmux new-session -d -s "$SESSION" -n editor
tmux send-keys -t "$SESSION":editor.1 "cd ~/atcoder-nim-env && nvim" C-m
tmux split-window -v -l 8 -t "$SESSION":editor
tmux select-pane -t "$SESSION":editor.1
exec tmux attach -t "$SESSION"
