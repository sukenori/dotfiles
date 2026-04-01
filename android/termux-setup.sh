#!/usr/bin/env bash

set -euo pipefail

# SSHのインストール
pkg update -y
pkg install -y openssh termux-api

# /.ssh にパスフレーズなしの鍵を作成
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/config
chmod 600 ~/.ssh/config

KEY_PATH="$HOME/.ssh/id_ed25519"
if [ -f "$KEY_PATH" ]; then
	echo "既存の鍵が見つかりました: $KEY_PATH"
	echo "上書きして再生成しますか? [y/N]"
	read -r REPLY </dev/tty || REPLY="n"
	if [[ "$REPLY" =~ ^[Yy]$ ]]; then
		rm -f "$KEY_PATH" "$KEY_PATH.pub"
		ssh-keygen -t ed25519 -f "$KEY_PATH" -N ""
	else
		echo "既存鍵をそのまま使います。"
	fi
else
	ssh-keygen -t ed25519 -f "$KEY_PATH" -N ""
fi

# Windows へ鍵を送信するための準備
echo "Windows のユーザー名を入力してください："
read WIN_USER
echo "Windows の Tailscale IP アドレス (100.xx.xx.xx) を入力してください："
read WIN_IP

echo "Windows のログインパスワードを求められたら入力してください"
ssh-copy-id "${WIN_USER}@${WIN_IP}"
