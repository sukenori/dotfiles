#!/bin/bash

# 1. パッケージの更新と必須ツールのインストール
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git neovim zsh ripgrep fzf nodejs npm openssh-server podman distrobox build-essential

#Zellij（画面分割ツール）のインストール
curl -L https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz | tar xz
sudo mv zellij /usr/local/bin/

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

#sheldon（プラグインマネージャー）のインストール
curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh | bash -s -- --repo rossmacarthur/sheldon --to ~/.local/bin

#zoxide（高速移動ツール）のインストール
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

# 2. あなたのdotfilesリポジトリをホームディレクトリに丸ごとクローン
# （※このスクリプト自体が ~/dotfiles の中にある場合は、すでにクローン済みなのでスキップされます）
if [ ! -d "$HOME/dotfiles" ]; then
  git clone https://github.com/sukenori/dotfiles.git ~/dotfiles
fi

# 4. シンボリックリンク（ショートカット）の作成
# ここで、ホームディレクトリの各設定ファイルの向き先を、dotfilesフォルダの中身に向けます
ln -sf ~/dotfiles/zsh/.zshrc ~/.zshrc
ln -sf ~/dotfiles/git/.gitconfig ~/.gitconfig
ln -s ~/dotfiles/sheldon/plugins.toml ~/.config/sheldon/plugins.toml
ln -s ~/dotfiles/zellij/layouts/default.kdl ~/.config/zellij/layouts/default.kdl

# Neovim用の設定フォルダもリンクを張る
mkdir -p ~/.config
ln -sf ~/dotfiles/nvim ~/.config/nvim

# 5. デフォルトシェルの変更
sudo chsh -s $(which zsh) $USER

# 念のため設定ファイルのバックアップを作成
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Port 22のコメントアウトを外す
sudo sed -i 's/^#Port 22/Port 22/' /etc/ssh/sshd_config

# 公開鍵認証を有効化
sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# パスワード認証を有効化（デフォルトがnoになっている場合も考慮）
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 設定を反映させてSSHサービスを起動（または再起動）
sudo service ssh restart

echo "WSLのセットアップとdotfilesの展開が完了しました。ターミナルを再起動してください。"

