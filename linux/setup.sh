#!/usr/bin/env bash
# bash で実行する

# パイプ途中も含めて失敗、未定義変数を検出
set -euo pipefail

# 配下のファイルの所有者を自分自身に強制的に揃える
fix_ownership() {
  local target_path="$1"
  local target_user="$(id -un)"
  local target_group="$(id -gn)"
  find "$target_path" \( ! -user "$target_user" -o ! -group "$target_group" \) \
    -exec sudo chown "$target_user:$target_group" {} +
}

# .gitconfig を配置（credential.helper = store が含まれている）
fix_ownership "$HOME/dotfiles"
ln -sf "$HOME/dotfiles/git/.gitconfig" "$HOME/.gitconfig"

# Docker Engine のインストール
sudo apt-get update && sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# WSL 上で Tailscale や AdGuard 等のローカル DNS によるコンテナ内の名前解決失敗を防ぐため、Docker コンテナのアウトバウンド DNS を Google DNS 等に固定する
# コンテナ内で github からの clone やインストールをするのに必要
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<'EOF'
{
  "dns": ["8.8.8.8", "8.8.4.4"]
}
EOF

# 設定反映のため Docker サービスを再起動
sudo service docker restart || sudo systemctl restart docker

# dotfiles ディレクトリ内にある、基盤となる Dockerfile をビルド
sudo docker build -t base-image -f "$HOME/dotfiles/Dockerfile" "$HOME/dotfiles"

# Docker を普段 sudo なしで使えるよう、実行ユーザーを docker グループへ追加（反映は次回ログイン以降）
TARGET_USER="${SUDO_USER:-$USER}"
sudo usermod -aG docker "$TARGET_USER"

# dotfiles リポジトリの取得・更新
fix_ownership "$HOME/dotfiles"
git -C "$HOME/dotfiles" pull --ff-only
