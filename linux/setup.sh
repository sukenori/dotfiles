#!/usr/bin/env bash
# bash で実行する

# パイプ途中も含めて失敗、未定義変数を検出
set -euo pipefail

# SSH 鍵の生成（なければ）
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
  ssh-keygen -t ed25519 -C "sukenori@coo.net" -N "" -f "$HOME/.ssh/id_ed25519"
fi
# 公開鍵を表示して登録を促す
echo "GitHubにSSH鍵を登録してください："
cat "$HOME/.ssh/id_ed25519.pub"
echo "https://github.com/settings/ssh/new"
echo "登録後、Enterを押してください"
read -r
# 疎通確認
ssh -T git@github.com || true
# dotfiles の remote を SSH に切り替え
git -C "$HOME/dotfiles" remote set-url origin git@github.com:sukenori/dotfiles.git

# Docker Engine のインストール
sudo apt-get update && sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg
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

# dotfiles リポジトリの取得・更新
git -C "$HOME/dotfiles" pull --ff-only
