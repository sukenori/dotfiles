#!/bin/bash
set -euo pipefail

# 1) Windows改行(CRLF)で /bin/bash^M になる事故を自己修復
sed -i 's/\r$//' "$0" || true

echo "=== 1. apt packages ==="
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
  curl git neovim zsh ripgrep fzf tmux \
  openssh-client \
  podman distrobox build-essential libssl-dev pkg-config

echo "=== 2. Node.js (for tools) ==="
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

echo "=== 3. Rust/Cargo + sheldon + zoxide ==="
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
# shellcheck disable=SC1091
source "$HOME/.cargo/env"
cargo install sheldon
cargo install zoxide --locked

echo "=== 4. pure-prompt ==="
sudo npm install --global pure-prompt

echo "=== 5. Clone dotfiles ==="
if [ ! -d "$HOME/dotfiles" ]; then
  git clone https://github.com/sukenori/dotfiles.git "$HOME/dotfiles"
fi

echo "=== 6. Symlinks ==="
mkdir -p "$HOME/.config/sheldon" "$HOME/.config/nvim"
ln -sf "$HOME/dotfiles/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$HOME/dotfiles/git/.gitconfig" "$HOME/.gitconfig"
ln -sf "$HOME/dotfiles/sheldon/plugins.toml" "$HOME/.config/sheldon/plugins.toml"
ln -sf "$HOME/dotfiles/nvim" "$HOME/.config/nvim"
ln -sf "$HOME/dotfiles/tmux/.tmux.conf" "$HOME/.tmux.conf"
chmod +x "$HOME/dotfiles/tmux/start-main.sh" || true

echo "=== 7. Disable zellij autostart (if exists) and enable tmux autostart ==="
# 既に ~/.zshrc に zellij 起動行があれば無効化（保険）
if grep -q "zellij" "$HOME/.zshrc"; then
  sed -i 's/^\(.*zellij.*\)$/# disabled-by-setup: \1/' "$HOME/.zshrc" || true
fi

# tmux自動起動ブロックを末尾に追記（重複追記しない）
if ! grep -q "tmux-start-main-sh" "$HOME/.zshrc"; then
  cat >> "$HOME/.zshrc" <<'EOF'

# tmux-start-main-sh
# interactive shell で tmux 未接続なら main を起動/復帰
if command -v tmux >/dev/null 2>&1; then
  if [ -z "${TMUX:-}" ] && [ -n "${PS1:-}" ]; then
    exec "$HOME/dotfiles/tmux/start-main.sh"
  fi
fi
EOF
fi

echo "=== 8. Git CRLF safety ==="
git config --global core.autocrlf false || true

echo "=== 9. Default shell to zsh ==="
sudo chsh -s "$(which zsh)" "$USER" || true
echo "=== Install Tailscale ==="
curl -fsSL https://tailscale.com/install.sh | sh
echo "=== DONE ==="
echo "Next: Android側でTermuxのsshdを起動し、WSLから ssh -p 8022 で接続します。"
