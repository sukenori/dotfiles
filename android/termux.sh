#!/bin/bash
# SSHのインストール
pkg update -y
pkg install -y openssh

# 鍵の保存場所を作成
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# スマホ用の鍵（パスフレーズなし）を作成
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

# Windowsへ鍵を送信するための準備
echo "Windowsのユーザー名を入力してください:"
read WIN_USER
echo "WindowsのTailscale IPアドレス (100.x.y.z) を入力してください:"
read WIN_IP

echo "Windowsのログインパスワードを求められたら入力してください"
ssh-copy-id ${WIN_USER}@${WIN_IP}
