#!/usr/bin/env bash
# bash で実行する

# パイプ途中も含めて失敗、未定義変数を検出
set -euo pipefail

# パッケージ一覧の更新とアップグレード
sudo apt-get update && sudo apt-get upgrade -y
# HTTPS 通信の証明書 curl git と Rust ビルドに必要な依存をインストール
sudo apt-get install -y ca-certificates curl git build-essential pkg-config libssl-dev

# zsh をインストール
sudo apt-get install -y zsh

# fzf（あいまい検索）をインストール
mkdir -p "$HOME/.local/bin"
FZF_VERSION=$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest | grep -Po '"tag_name": "\K[^"]*' | sed 's/^v//')
curl -Lo /tmp/fzf.tar.gz "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz"
tar xzf /tmp/fzf.tar.gz -C "$HOME/.local/bin/" fzf
chmod +x "$HOME/.local/bin/fzf"
rm -f /tmp/fzf.tar.gz

# Rust をインストール
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
# sheldon（zsh プラグインマネージャ）をインストール
cargo install sheldon
# zoxide（ディレクトリ履歴の補助コマンド）をインストール
cargo install zoxide --locked

# Neovim のインストール
curl -Lo /tmp/nvim-linux-x86_64.tar.gz \
	https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo tar xzf /tmp/nvim-linux-x86_64.tar.gz -C /opt
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
rm -f /tmp/nvim-linux-x86_64.tar.gz

# ripgrep（ファイル内キーワード検索）を入れる
sudo apt-get install -y ripgrep

# Node.js のインストール
NODE_MAJOR=$(curl -fsSL https://resolve-node.vercel.app/lts | grep -oP '(?<=v)\d+')
curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | sudo -E bash -
sudo apt install -y nodejs

# Docker Engine のインストール
sudo apt-get install -y gpg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# OpenSSH client を入れる
sudo apt-get install -y openssh-client

# dotfiles リポジトリの取得・更新
if [ ! -e "$HOME/dotfiles" ]; then
  git clone https://github.com/sukenori/dotfiles.git "$HOME/dotfiles"
else
  git -C "$HOME/dotfiles" pull --ff-only
fi

# 各設定ファイルへのシンボリックリンク作成
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config/sheldon"
ln -sf "$HOME/dotfiles/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$HOME/dotfiles/sheldon/plugins.toml" "$HOME/.config/sheldon/plugins.toml"
ln -sf "$HOME/dotfiles/git/.gitconfig" "$HOME/.gitconfig"
rm -rf "$HOME/.config/nvim"
ln -s  "$HOME/dotfiles/nvim" "$HOME/.config/nvim"

# デフォルトシェルを zsh に変更
if [ "$SHELL" != "$(command -v zsh)" ]; then
  chsh -s "$(command -v zsh)"
fi
