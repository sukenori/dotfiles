#!/bin/bash
# コンテナ内なので、このシェバンでよし
set -euo pipefail

# Compose が read-only mount する dotfiles のディレクトリ
DOTFILES_DIR="${DOTFILES_DIR:-/opt/dotfiles}"

# 各設定ファイルへのシンボリックリンク作成
# ln -s（link）で、シンボリックリンク、-f で上書き
ln -sfn "${DOTFILES_DIR}/git/.gitconfig" "$HOME/.gitconfig"
ln -sfn "${DOTFILES_DIR}/tmux/.tmux.conf" "$HOME/.tmux.conf"
ln -sfn "${DOTFILES_DIR}/zsh/.zshrc" "$HOME/.zshrc"
# mkdir -p で、sheldon に対して親の .config がなくても、一緒に作ってくれる
mkdir -p "$HOME/.config/sheldon"
ln -sfn "${DOTFILES_DIR}/sheldon/plugins.toml" "$HOME/.config/sheldon/plugins.toml"
# nvim: ディレクトリ全体を symlink するのではなく、
# ~/.config/nvim 自体は書き込み可能な実ディレクトリのまま、
# 中の設定ファイルだけを個別に symlink する。
# これで lazy-lock.json は read-only な dotfiles を経由せず、
# dev-home 側に直接書き込める。
mkdir -p "$HOME/.config/nvim"
find "${DOTFILES_DIR}/nvim" -maxdepth 1 -mindepth 1 -exec ln -sfn {} "$HOME/.config/nvim/" \;

# docker run の引数や、docker-compose.yaml の command:、Dockefile の CMD で渡されたコマンドを実行する（今回は、docker-compose.yaml の command:）
exec "$@"
