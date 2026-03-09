#!/bin/bash
# ===========================================================================
# setup.sh — WSL (Ubuntu) 上のホスト環境を一発で構築するスクリプト
#
# 実行順序:
#   1. Windows 側: windows/setup.ps1 を実行（WSL / フォントなど）
#   2. WSL 側  : このスクリプトを実行（開発ツール一式）
#   3. WSL 側  : ~/atcoder-nim-env/setup.sh を実行（競プロ用コンテナ）
#
# このスクリプトが行うこと:
#   - apt で基本パッケージをインストール（git, zsh, tmux, ripgrep, fzf, ...）
#   - Neovim 最新版をインストール
#   - Node.js (最新 LTS) をインストール
#   - Rust / Cargo と、Cargo 製ツール (sheldon, zoxide) をインストール
#   - dotfiles リポジトリをクローンし、各設定ファイルのシンボリックリンクを張る
#   - atcoder-nim-env リポジトリをクローンする
#   - デフォルトシェルを zsh に変更する
# ===========================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# 1. apt パッケージのインストール
# ---------------------------------------------------------------------------
echo "=== 1/8 apt パッケージのインストール ==="
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
  curl git zsh ripgrep tmux \
  openssh-client \
  podman distrobox build-essential libssl-dev pkg-config

# fzf は apt 版だとバージョンが古く --zsh オプションが使えないため、
# GitHub Release からバイナリを直接取得する
echo "--- fzf (GitHub Release) のインストール ---"
mkdir -p "$HOME/.local/bin"
FZF_VERSION=$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest | grep -Po '"tag_name": "\K[^"]*' | sed 's/^v//')
curl -Lo /tmp/fzf.tar.gz "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz"
tar xzf /tmp/fzf.tar.gz -C "$HOME/.local/bin/" fzf
chmod +x "$HOME/.local/bin/fzf"
rm -f /tmp/fzf.tar.gz

# ---------------------------------------------------------------------------
# 2. Neovim 最新版のインストール
#    WSL では AppImage (FUSE) が使えないため、tarball を展開して配置する
# ---------------------------------------------------------------------------
echo "=== 2/8 Neovim のインストール ==="
cd /tmp
curl -LO https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
rm -f nvim-linux-x86_64.tar.gz

# ---------------------------------------------------------------------------
# 3. Node.js (最新 LTS) のインストール
# ---------------------------------------------------------------------------
echo "=== 3/8 Node.js のインストール ==="
NODE_MAJOR=$(curl -fsSL https://resolve-node.vercel.app/lts | grep -oP '(?<=v)\d+')
curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | sudo -E bash -
sudo apt install -y nodejs

# ---------------------------------------------------------------------------
# 4. Rust / Cargo と Cargo 製ツールのインストール
#    sheldon = zsh プラグインマネージャ、zoxide = 賢い cd コマンド
# ---------------------------------------------------------------------------
echo "=== 4/8 Rust / sheldon / zoxide のインストール ==="
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
# shellcheck disable=SC1091
source "$HOME/.cargo/env"
cargo install sheldon
cargo install zoxide --locked

# ---------------------------------------------------------------------------
# 5. dotfiles リポジトリのクローン
# ---------------------------------------------------------------------------
echo "=== 5/8 dotfiles のクローン ==="
if [ ! -d "$HOME/dotfiles" ]; then
  git clone https://github.com/sukenori/dotfiles.git "$HOME/dotfiles"
else
  echo "  → dotfiles は取得済みです。"
fi

# ---------------------------------------------------------------------------
# 6. シンボリックリンクの作成
#    各設定ファイルを dotfiles 内の本体にリンクすることで、
#    dotfiles を git pull するだけで設定が更新される
# ---------------------------------------------------------------------------
echo "=== 6/8 シンボリックリンクの作成 ==="
mkdir -p "$HOME/.config/sheldon"
mkdir -p "$HOME/.local/bin"

ln -sf "$HOME/dotfiles/zsh/.zshrc"                        "$HOME/.zshrc"
ln -sf "$HOME/dotfiles/git/.gitconfig"                     "$HOME/.gitconfig"
ln -sf "$HOME/dotfiles/sheldon/plugins.toml"               "$HOME/.config/sheldon/plugins.toml"
ln -sf "$HOME/dotfiles/tmux/.tmux.conf"                    "$HOME/.tmux.conf"

# Neovim の設定ディレクトリ丸ごとリンク
rm -rf "$HOME/.config/nvim"
ln -s  "$HOME/dotfiles/nvim" "$HOME/.config/nvim"

# tmux 起動スクリプトに実行権限を付与
chmod +x "$HOME/dotfiles/tmux/start-main.sh"

# ---------------------------------------------------------------------------
# 7. atcoder-nim-env リポジトリのクローン
#    （コンテナの構築は ~/atcoder-nim-env/setup.sh で別途行う）
# ---------------------------------------------------------------------------
echo "=== 7/8 atcoder-nim-env のクローン ==="
if [ ! -d "$HOME/atcoder-nim-env" ]; then
  git clone https://github.com/sukenori/AtCoder-Nim-Codespace.git "$HOME/atcoder-nim-env"
else
  echo "  → atcoder-nim-env は取得済みです。"
fi

# ---------------------------------------------------------------------------
# 8. デフォルトシェルを zsh に変更
# ---------------------------------------------------------------------------
echo "=== 8/8 デフォルトシェルを zsh に変更 ==="
if [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s "$(which zsh)"
  echo "  → 次回ログインから zsh がデフォルトになります。"
else
  echo "  → 既に zsh です。"
fi

echo ""
echo "=== ホスト環境のセットアップが完了しました ==="
echo ""
echo "次のステップ:"
echo "  cd ~/atcoder-nim-env && bash setup.sh"
echo "  → Distrobox コンテナ内に Nim 環境を構築します"
