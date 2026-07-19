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

# 3. 接続情報の入力
echo "PCへの接続設定を行います。"
printf "PC側のユーザー名を入力してください (例: itosu): "
read -r WIN_USER </dev/tty
printf "PC側のTailscale IPを入力してください (100.x.x.x): "
read -r TS_IP </dev/tty
printf "アタッチするDockerコンテナ名を入力してください: "
read -r CONTAINER </dev/tty

# 4. SSH config の生成
cat > "$SSH_CONFIG" << EOF
Host atcoder
    HostName ${TS_IP}
    User ${WIN_USER}
EOF
chmod 600 "$SSH_CONFIG"

# 5. Makefile用設定ファイルの生成
cat > "$CONF_FILE" << EOF
# Makefile用設定
ATCODER_HOST=atcoder
CONTAINER=${CONTAINER}
WORKSPACE=/work  # コンテナ内の適切なパスに書き換えてください
EOF

# Makefileのリンク
ln -sf "$DOTFILES_DIR/android/Makefile" "$HOME/Makefile"

echo ""
echo "設定完了しました。"
echo "Tailscale AndroidアプリでVPNが接続されていることを確認してください。"
echo "以降はTermux起動後、以下のコマンドだけで操作できます："
echo "  make attach  ... PCのコンテナに接続"
echo "  make copy    ... bundled.txt をクリップボードにコピー"
echo "  make watch   ... bundled.txt を監視して自動コピー"