#!/usr/bin/env bash
# bash で実行する

set -euo pipefail
# 失敗・未定義変数・パイプ途中失敗を検出する

# APT の索引を更新する
sudo apt-get update

# HTTPS 通信の証明書を入れる
sudo apt-get install -y ca-certificates

# curl を入れる（zoxide インストーラ取得で使う）
sudo apt-get install -y curl

# git を入れる（dotfiles clone と plugin 更新で使う）
sudo apt-get install -y git

# GNU Stow を入れる（dotfiles のリンク展開で使う）
sudo apt-get install -y stow

# zsh を入れる
sudo apt-get install -y zsh

# zsh の補助プラグインを入れる
sudo apt-get install -y zsh-autosuggestions zsh-syntax-highlighting

# ripgrep を入れる
sudo apt-get install -y ripgrep

# fzf を入れる
sudo apt-get install -y fzf

# xz-utils を入れる（AtCoder 提出時の bundle 圧縮で使う）
sudo apt-get install -y xz-utils

# build-essential を入れる（Nim の C++ バックエンドで g++ が必要）
sudo apt-get install -y build-essential

# unzip を入れる
sudo apt-get install -y unzip

# 最新版 Neovim を入れる（vscode-neovim バックエンドは新しめの版が必要）
curl -Lo /tmp/nvim-linux-x86_64.tar.gz \
	https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo tar xzf /tmp/nvim-linux-x86_64.tar.gz -C /opt
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
rm -f /tmp/nvim-linux-x86_64.tar.gz

# podman を入れる
sudo apt-get install -y podman

# distrobox を入れる
sudo apt-get install -y distrobox

# OpenSSH client を入れる
sudo apt-get install -y openssh-client

# zoxide を cargo なしで最新版導入する
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# nvim-cmp と LSP プラグインを入れる（あれば更新、なければ clone）
mkdir -p "$HOME/.local/share/nvim/site/pack/cp/start"

if [ -d "$HOME/.local/share/nvim/site/pack/cp/start/nvim-cmp/.git" ]; then
	git -C "$HOME/.local/share/nvim/site/pack/cp/start/nvim-cmp" pull --ff-only
else
	git clone --depth 1 https://github.com/hrsh7th/nvim-cmp.git \
		"$HOME/.local/share/nvim/site/pack/cp/start/nvim-cmp"
fi

if [ -d "$HOME/.local/share/nvim/site/pack/cp/start/cmp-nvim-lsp/.git" ]; then
	git -C "$HOME/.local/share/nvim/site/pack/cp/start/cmp-nvim-lsp" pull --ff-only
else
	git clone --depth 1 https://github.com/hrsh7th/cmp-nvim-lsp.git \
		"$HOME/.local/share/nvim/site/pack/cp/start/cmp-nvim-lsp"
fi

if [ -d "$HOME/.local/share/nvim/site/pack/cp/start/cmp-buffer/.git" ]; then
	git -C "$HOME/.local/share/nvim/site/pack/cp/start/cmp-buffer" pull --ff-only
else
	git clone --depth 1 https://github.com/hrsh7th/cmp-buffer.git \
		"$HOME/.local/share/nvim/site/pack/cp/start/cmp-buffer"
fi

if [ -d "$HOME/.local/share/nvim/site/pack/cp/start/cmp-path/.git" ]; then
	git -C "$HOME/.local/share/nvim/site/pack/cp/start/cmp-path" pull --ff-only
else
	git clone --depth 1 https://github.com/hrsh7th/cmp-path.git \
		"$HOME/.local/share/nvim/site/pack/cp/start/cmp-path"
fi

if [ -d "$HOME/.local/share/nvim/site/pack/cp/start/nvim-lspconfig/.git" ]; then
	git -C "$HOME/.local/share/nvim/site/pack/cp/start/nvim-lspconfig" pull --ff-only
else
	git clone --depth 1 https://github.com/neovim/nvim-lspconfig.git \
		"$HOME/.local/share/nvim/site/pack/cp/start/nvim-lspconfig"
fi

# dotfiles のリンク展開を実行する（実行権限に依存しない）
bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/bootstrap.sh"
