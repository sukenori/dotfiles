#!/usr/bin/env bash
set -euo pipefail

# Tailscale SSH 前提の Termux セットアップ
# SSH鍵の生成・配達は不要（TailscaleがGoogleアカウントで認証を肩代わりする）

pkg update -y
pkg install -y openssh termux-api tailscale

# Tailscale を起動してログイン（初回のみ）
# ブラウザが開くのでGoogleアカウントでログインする
tailscale up

printf "Windows Tailscale IP (100.xx.xx.xx) を確認してください: tailscale ip -4\n"
printf "接続確認: ssh <WindowsUser>@<TailscaleIP>\n"
echo ""
echo "完了。次: bash ~/dotfiles/android/atcoder.sh"