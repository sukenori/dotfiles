#!/bin/bash
# SSHのインストール
pkg update -y
pkg install -y openssh

# /.ssh にパスフレーズなしの鍵を作成
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

# Windows へ鍵を送信するための準備
echo "Windows のユーザー名を入力してください："
read WIN_USER
echo "Windows の Tailscale IP アドレス (100.xx.xx.xx) を入力してください："
read WIN_IP

echo "Windows のログインパスワードを求められたら入力してください"
ssh-copy-id ${WIN_USER}@${WIN_IP}
