#!/usr/bin/env bash
# bash で実行する

# パイプ途中も含めて失敗、未定義変数を検出
set -euo pipefail

# 配下のファイルの所有者を自分自身に強制的に揃える
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

fix_ownership() {
  local target_path="$1"
  local target_user
  local target_group

  target_user="$(id -un)"
  target_group="$(id -gn)"

  find "$target_path" \
    \( ! -user "$target_user" -o ! -group "$target_group" \) \
    -exec sudo chown "$target_user:$target_group" {} +
}

# まず dotfiles の所有権を回復し、最新化する
fix_ownership "$SCRIPT_DIR"
git -C "$SCRIPT_DIR" pull --ff-only
fix_ownership "$SCRIPT_DIR"

# host の .gitconfig（credential.helper = store が含まれている）は dotfiles の管理対象へ戻す
ln -sfn "$SCRIPT_DIR/git/.gitconfig" "$HOME/.gitconfig"

#WSL 側でコアダンプファイル（core.数字）が作られないようにする
sudo tee /etc/security/limits.d/99-disable-coredump.conf > /dev/null <<'EOF'
{
  soft core 0
  hard core 0
}
EOF

# Docker が未インストールの場合だけ、Engine を入れる
if ! command -v docker >/dev/null 2>&1; then

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

fi

# 最新化済み dotfiles から base image を通常 user として build する。
sudo docker build -t base-image -f "$SCRIPT_DIR/Dockerfile" "$SCRIPT_DIR"
