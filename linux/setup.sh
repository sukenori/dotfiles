#!/usr/bin/env bash
# bash で実行する

# パイプ途中も含めて失敗、未定義変数を検出
set -euo pipefail

# Docker Engine のインストール
sudo apt-get update && sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# dotfiles ディレクトリ内にある、基盤となる Dockerfile をビルド
sudo docker build -t base-image -f "$HOME/dotfiles/Dockerfile" "$HOME/dotfiles"

# Docker を普段 sudo なしで使えるよう、実行ユーザーを docker グループへ追加（反映は次回ログイン以降）
TARGET_USER="${SUDO_USER:-$USER}"
sudo usermod -aG docker "$TARGET_USER"
echo "$TARGET_USER を docker グループに追加しました。"
echo "スクリプト中の docker は sudo で実行するため、このままでも setup は継続できます。"
echo "手動で sudo なし docker を使う場合は、再ログインか 'newgrp docker' を実行してください。"

# dotfiles リポジトリの取得・更新
git -C "$HOME/dotfiles" pull --ff-only
