#!/usr/bin/env bash
# bash で実行する

set -euo pipefail
# 失敗・未定義変数・パイプ途中失敗を検出する

REPO_URL="${1:-https://github.com/sukenori/dotfiles.git}"
# 第1引数があればそれを使い、無ければ HTTPS URL を使う

# dotfiles を clone する
if [ ! -d "${HOME}/dotfiles/.git" ]; then
  git clone "${REPO_URL}" "${HOME}/dotfiles"
fi

# ホーム配下に必要なディレクトリを作る
mkdir -p "${HOME}/.config"

# dotfiles ディレクトリへ移動する
cd "${HOME}/dotfiles"

# zsh のリンクを張る
stow -t "${HOME}" zsh

# git のリンクを張る
stow -t "${HOME}" git

# nvim のリンクを張る
stow -t "${HOME}" nvim

# VSCode 設定のリンクを張る
mkdir -p "${HOME}/.config/Code/User"
VS_SETTINGS_SRC="${HOME}/dotfiles/vscode/.config/Code/User/settings.json"
VS_SETTINGS_DST="${HOME}/.config/Code/User/settings.json"

if [ "$(readlink -f "${VS_SETTINGS_SRC}")" != "$(readlink -f "${VS_SETTINGS_DST}" 2>/dev/null || true)" ]; then
  ln -sfn "${VS_SETTINGS_SRC}" "${VS_SETTINGS_DST}"
fi
