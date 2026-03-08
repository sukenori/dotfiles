#!/bin/sh
set -eu

SESSION=main

if tmux has-session -t "$SESSION" 2>/dev/null; then
  exec tmux attach -t "$SESSION"
fi

tmux new-session -d -s "$SESSION" -n editor
tmux send-keys -t "$SESSION":editor.1 "nvim" C-m
tmux split-window -v -l 12 -t "$SESSION":editor
tmux select-pane -t "$SESSION":editor.1
exec tmux attach -t "$SESSION"
