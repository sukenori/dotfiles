#!/usr/bin/env bash
set -euo pipefail

# 事前準備
# pkg update -y
# pkg install -y git
# git clone https://github.com/sukenori/dotfiles
# bash ~/dotfiles/android/setup.sh

# パッケージのインストール
pkg update -y
pkg install -y openssh termux-api make

# ディレクトリの準備
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SSH_CONFIG="$HOME/.ssh/config"
CONF_FILE="$HOME/.config/atcoder.conf"
mkdir -p "$HOME/.ssh" "$HOME/.config"
chmod 700 "$HOME/.ssh"

# 接続情報の入力
printf "PC 側のユーザー名を入力してください: "
read -r WIN_USER </dev/tty
printf "PC 側の Tailscale IP を入力してください: "
read -r TS_IP </dev/tty

# SSH config の生成
cat > "$SSH_CONFIG" << EOF
Host host
    HostName ${TS_IP}
    User ${WIN_USER}
EOF
chmod 600 "$SSH_CONFIG"

# Makefile用設定ファイルの生成
cat > "$CONF_FILE" << EOF
# Makefile用設定
HOST=host
CONTAINER=atcoder-nim
WORKSPACE=/atcoder-nim-env
EOF

# Makefileのリンク
ln -sf "$DOTFILES_DIR/android/Makefile" "$HOME/Makefile"

echo ""
echo "設定完了"
echo "Termuxでのコマンド："
echo "  make attach ... PC のコンテナに接続"
echo "  make copy   ... bundled.txt をクリップボードにコピー"
echo "  make watch  ... bundled.txt を監視して自動コピー"