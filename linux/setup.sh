#!/bin/bash
# ===========================================================================
# setup.sh — WSL (Ubuntu) 上のホスト環境を一発で構築するスクリプト
#
# 実行順序:
#   1. Windows 側: windows/setup.ps1 を実行（WSL / フォントなど）
#   2. WSL 側  : このスクリプトを実行（シェル・エディタ・コンテナ基盤）
#
# このスクリプトが行うこと:
#   - Git / curl / OpenSSH client を入れ、設定取得の土台を作る
#   - zsh / tmux / ripgrep / fzf を入れ、日常のターミナル操作を整える
#   - Neovim と Node.js を入れ、エディタとプラグインの実行基盤を整える
#   - Rust / Cargo と sheldon / zoxide を入れ、zsh 周辺ツールを整える
#   - podman / distrobox とビルド用パッケージを入れ、コンテナ開発の土台を作る
#   - dotfiles リポジトリをクローンし、各設定ファイルへリンクを張る
#   - デフォルトシェルを zsh に変更する
# ===========================================================================

# 安全側に倒す:
#   -e        途中のコマンドが失敗したらその場で終了する
#   -u        未定義変数の参照をエラーにする
#   -o pipefail
#             パイプラインの途中で失敗したコマンドも見逃さない
set -euo pipefail

# ---------------------------------------------------------------------------
# 1. 基本パッケージのインストール
# ---------------------------------------------------------------------------
echo "=== 1/7 基本パッケージのインストール ==="
sudo apt update && sudo apt upgrade -y

echo "--- 取得・同期に使う基本ツール ---"
# curl: GitHub Release や各種セットアップスクリプトを取得する
# git: dotfiles を clone / update する
# openssh-client: GitHub を SSH で使う場合やリモート接続に使う
sudo apt install -y \
  curl git openssh-client

echo "--- シェルとターミナル操作を整えるツール ---"
# zsh: 以後の標準シェル
# tmux: ペイン分割やセッション復帰に使う
# ripgrep: CLI や Neovim/Telescope で高速検索する
sudo apt install -y \
  zsh tmux ripgrep

echo "--- コンテナ開発の土台 ---"
# podman: コンテナエンジン本体
# distrobox: コンテナを普段使いの開発環境として扱いやすくする
sudo apt install -y \
  podman distrobox

echo "--- ビルドに必要な開発ツールとヘッダ ---"
# build-essential: gcc / g++ / make などの基本ビルドツール
# libssl-dev: TLS/SSL を使う Rust crate やネイティブ依存のビルドに必要
# pkg-config: ネイティブライブラリの場所を検出する
sudo apt install -y \
  build-essential libssl-dev pkg-config

# ---------------------------------------------------------------------------
# 2. fzf のインストール
#    履歴・ファイル・候補を対話的に絞り込むあいまい検索ツール
#    この dotfiles では `.zshrc` から `fzf --zsh` を呼ぶため、
#    Ubuntu の apt 版ではなく GitHub Release のバイナリを入れる
# ---------------------------------------------------------------------------
echo "=== 2/7 fzf のインストール ==="
mkdir -p "$HOME/.local/bin"
FZF_VERSION=$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest | grep -Po '"tag_name": "\K[^"]*' | sed 's/^v//')
curl -Lo /tmp/fzf.tar.gz "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz"
tar xzf /tmp/fzf.tar.gz -C "$HOME/.local/bin/" fzf
chmod +x "$HOME/.local/bin/fzf"
rm -f /tmp/fzf.tar.gz

# ---------------------------------------------------------------------------
# 3. Neovim 最新版のインストール
#    メインのエディタとして使う
#    WSL では AppImage (FUSE) より tarball 展開の方が扱いやすいため、
#    その形で配置する
# ---------------------------------------------------------------------------
echo "=== 3/7 Neovim のインストール ==="
cd /tmp
curl -LO https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
rm -f nvim-linux-x86_64.tar.gz

# ---------------------------------------------------------------------------
# 4. Node.js (最新 LTS) のインストール
#    GitHub Copilot 系プラグインや Node ベースのツールの実行基盤
#    最新 LTS を NodeSource から導入する
# ---------------------------------------------------------------------------
echo "=== 4/7 Node.js のインストール ==="
NODE_MAJOR=$(curl -fsSL https://resolve-node.vercel.app/lts | grep -oP '(?<=v)\d+')
curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | sudo -E bash -
sudo apt install -y nodejs

# ---------------------------------------------------------------------------
# 5. Rust / Cargo と Cargo 製ツールのインストール
#    Rust / Cargo: sheldon と zoxide を cargo install するための基盤
#    sheldon = zsh プラグインマネージャ
#    zoxide = `z foo` で履歴からディレクトリ移動できる補助コマンド
# ---------------------------------------------------------------------------
echo "=== 5/7 Rust / sheldon / zoxide のインストール ==="
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
# shellcheck disable=SC1091
source "$HOME/.cargo/env"
cargo install sheldon
cargo install zoxide --locked

# ---------------------------------------------------------------------------
# 6. dotfiles の配置
# ---------------------------------------------------------------------------
echo "=== 6/7 dotfiles の配置 ==="

echo "--- dotfiles リポジトリの取得・更新 ---"
if [ ! -e "$HOME/dotfiles" ]; then
  git clone https://github.com/sukenori/dotfiles.git "$HOME/dotfiles"
elif [ -d "$HOME/dotfiles/.git" ]; then
  git -C "$HOME/dotfiles" pull --ff-only
else
  echo "エラー: $HOME/dotfiles が Git リポジトリではありません" >&2
  exit 1
fi

echo "--- 各設定ファイルへのシンボリックリンク作成 ---"
# dotfiles 内の実体にリンクすることで、dotfiles を更新すれば設定も追随する
mkdir -p "$HOME/.config/sheldon"
mkdir -p "$HOME/.local/bin"

ln -sf "$HOME/dotfiles/zsh/.zshrc"                        "$HOME/.zshrc"
ln -sf "$HOME/dotfiles/git/.gitconfig"                     "$HOME/.gitconfig"
ln -sf "$HOME/dotfiles/sheldon/plugins.toml"               "$HOME/.config/sheldon/plugins.toml"
ln -sf "$HOME/dotfiles/tmux/.tmux.conf"                    "$HOME/.tmux.conf"

# Neovim は複数ファイルで構成しているため、ディレクトリごと差し替える
rm -rf "$HOME/.config/nvim"
ln -s  "$HOME/dotfiles/nvim" "$HOME/.config/nvim"

# ---------------------------------------------------------------------------
# 7. デフォルトシェルを zsh に変更
# ---------------------------------------------------------------------------
echo "=== 7/7 デフォルトシェルを zsh に変更 ==="
if [ "$SHELL" != "$(command -v zsh)" ]; then
  chsh -s "$(command -v zsh)"
  echo "  → 次回ログインから zsh がデフォルトになります。"
fi

echo ""
echo "=== ホスト環境のセットアップが完了しました ==="
echo "新しいシェルを開くと zsh 設定が反映されます"
