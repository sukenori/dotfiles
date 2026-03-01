#!/bin/bash

# 1. パッケージの更新と必須ツールのインストール
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git neovim zsh build-essential

# 2. あなたのdotfilesリポジトリをホームディレクトリに丸ごとクローン
# （※このスクリプト自体が ~/dotfiles の中にある場合は、すでにクローン済みなのでスキップされます）
if [ ! -d "$HOME/dotfiles" ]; then
  git clone https://github.com/sukenori/dotfiles.git ~/dotfiles
fi

# 3. Zshプラグインのダウンロード
mkdir -p ~/.zsh/plugins
if [ ! -d "$HOME/.zsh/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/plugins/zsh-autosuggestions
fi
if [ ! -d "$HOME/.zsh/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/plugins/zsh-syntax-highlighting
fi

# 4. シンボリックリンク（ショートカット）の作成
# ここで、ホームディレクトリの各設定ファイルの向き先を、dotfilesフォルダの中身に向けます
ln -sf ~/dotfiles/zsh/.zshrc ~/.zshrc
ln -sf ~/dotfiles/git/.gitconfig ~/.gitconfig

# Neovim用の設定フォルダもリンクを張る
mkdir -p ~/.config
ln -sf ~/dotfiles/nvim ~/.config/nvim

# 5. デフォルトシェルの変更
sudo chsh -s $(which zsh) $USER

echo "WSLのセットアップとdotfilesの展開が完了しました。ターミナルを再起動してください。"

