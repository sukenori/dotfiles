#!/bin/bash
set -e

# 改行コード問題（\rエラー）を自己修復する安全装置
sed -i 's/\r$//' "$0"

echo "=== 1. ホスト(WSL)の必須パッケージインストール ==="
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git neovim zsh ripgrep fzf openssh-server podman distrobox build-essential libssl-dev pkg-config

echo "=== 2. Node.js と npm の確実なインストール ==="
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

echo "=== 3. Zellij のインストール ==="
curl -L https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz | tar xz
sudo mv zellij /usr/local/bin/

echo "=== 4. Rust, Cargo, Sheldon, Zoxide のインストール ==="
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
cargo install sheldon
cargo install zoxide --locked

echo "=== 5. pure-prompt のインストール ==="
sudo npm install --global pure-prompt

echo "=== 6. dotfiles のクローンとシンボリックリンク作成 ==="
if [ ! -d "$HOME/dotfiles" ]; then
  git clone https://github.com/sukenori/dotfiles.git ~/dotfiles
fi

mkdir -p ~/.config/sheldon ~/.config/zellij/layouts ~/.config/nvim
ln -sf ~/dotfiles/zsh/.zshrc ~/.zshrc
ln -sf ~/dotfiles/git/.gitconfig ~/.gitconfig
ln -sf ~/dotfiles/sheldon/plugins.toml ~/.config/sheldon/plugins.toml
ln -sf ~/dotfiles/zellij/layouts/default.kdl ~/.config/zellij/layouts/default.kdl
ln -sf ~/dotfiles/nvim ~/.config/nvim

# SSH接続用にリモートURLを変更
cd ~/dotfiles && git remote set-url origin git@github.com:sukenori/dotfiles.git && cd ~

echo "=== 7. SSHサーバーの設定 (外部アクセス用) ==="
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sudo sed -i 's/^#Port 22/Port 22/' /etc/ssh/sshd_config
sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo service ssh restart

echo "=== 8. GitHub用のSSH鍵生成 ==="
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
  ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
  echo "鍵を生成しました。以下の公開鍵をGitHubに登録してください："
  echo "---------------------------------------------------"
  cat ~/.ssh/id_ed25519.pub
  echo "---------------------------------------------------"
fi

echo "=== 9. デフォルトシェルの変更 ==="
sudo chsh -s $(which zsh) $USER

echo "=== WSLインフラのセットアップが完了しました。 ==="
