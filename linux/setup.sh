#!/bin/bash
set -e # エラーが発生した時点でスクリプトを停止する安全装置

# 1. パッケージの更新と必須ツールのインストール
sudo apt update && sudo apt upgrade -y
# nodejsとnpmは競合を避けるため後で公式から入れるので、ここからは外す
sudo apt install -y curl git neovim zsh ripgrep fzf openssh-server podman distrobox build-essential libssl-dev pkg-config

# Node.js と npm の確実なインストール（依存関係エラー回避）
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Zellij（画面分割ツール）のインストール
curl -L https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz | tar xz
sudo mv zellij /usr/local/bin/

# Rust と Cargo のインストール
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

# sheldon（プラグインマネージャー）と zoxide のインストール
cargo install sheldon
cargo install zoxide --locked

# pure プロンプトのインストール
sudo npm install --global pure-prompt

# 2. あなたのdotfilesリポジトリをホームディレクトリに丸ごとクローン
if [ ! -d "$HOME/dotfiles" ]; then
  git clone https://github.com/sukenori/dotfiles.git ~/dotfiles
fi

# 3. シンボリックリンクの作成
mkdir -p ~/.config/sheldon
mkdir -p ~/.config/zellij/layouts
mkdir -p ~/.config/nvim

ln -sf ~/dotfiles/zsh/.zshrc ~/.zshrc
ln -sf ~/dotfiles/git/.gitconfig ~/.gitconfig
ln -sf ~/dotfiles/sheldon/plugins.toml ~/.config/sheldon/plugins.toml
ln -sf ~/dotfiles/zellij/layouts/default.kdl ~/.config/zellij/layouts/default.kdl
ln -sf ~/dotfiles/nvim ~/.config/nvim

# 4. SSH設定の書き換え（変更なし）
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sudo sed -i 's/^#Port 22/Port 22/' /etc/ssh/sshd_config
sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo service ssh restart

# 5. デフォルトシェルの変更
sudo chsh -s $(which zsh) $USER

echo "WSLのセットアップが完了しました。ターミナルを再起動してください。"
