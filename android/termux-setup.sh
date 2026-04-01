#!/usr/bin/env bash
set -euo pipefail

pkg install -y openssh termux-api

mkdir -p ~/.ssh && chmod 700 ~/.ssh

KEY="$HOME/.ssh/id_ed25519"
if [ -f "$KEY" ]; then
  printf "既存の鍵があります。上書きしますか? [y/N]: "
  read -r r </dev/tty || r=n
  [[ "$r" =~ ^[Yy]$ ]] && rm -f "$KEY" "${KEY}.pub" && ssh-keygen -t ed25519 -f "$KEY" -N ""
else
  ssh-keygen -t ed25519 -f "$KEY" -N ""
fi

printf "Windows ユーザー名: "
read -r WIN_USER </dev/tty
printf "Windows Tailscale IP (100.xx.xx.xx): "
read -r WIN_IP </dev/tty

ssh-copy-id "${WIN_USER}@${WIN_IP}"
echo "完了。次: bash ~/dotfiles/android/atcoder.sh"