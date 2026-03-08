#!/bin/bash
set -euo pipefail

echo "=== 1. apt packages ==="
sudo apt update && sudo apt upgrade -y
# neovimをaptリストから削除し、他の必須パッケージをインストール
sudo apt install -y \
  curl git zsh ripgrep fzf tmux \
  openssh-client \
  podman distrobox build-essential libssl-dev pkg-config

echo "=== Install Latest Neovim (v0.11+ nightly) ==="
# WSL環境などでFUSE依存のAppImageが動かないケースを考慮し、tarballを展開して配置します
cd /tmp
curl -LO https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
# パスを通すためにシンボリックリンクを張る
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
rm -f nvim-linux-x86_64.tar.gz

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
mkdir -p "$HOME/.config/sheldon"
mkdir -p "$HOME/.local/bin"

ln -sf "$HOME/dotfiles/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$HOME/dotfiles/git/.gitconfig" "$HOME/.gitconfig"
ln -sf "$HOME/dotfiles/sheldon/plugins.toml" "$HOME/.config/sheldon/plugins.toml"

rm -rf "$HOME/.config/nvim"
ln -s "$HOME/dotfiles/nvim" "$HOME/.config/nvim"

ln -sf "$HOME/dotfiles/tmux/.tmux.conf" "$HOME/.tmux.conf"
chmod +x "$HOME/dotfiles/tmux/start-main.sh" || true

echo "=== 7. Disable zellij autostart (if exists) and enable tmux autostart ==="
if grep -q "zellij" "$HOME/.zshrc"; then
  sed -i 's/^\\(.*zellij.*\\)$/# disabled-by-setup: \\1/' "$HOME/.zshrc" || true
fi

if ! grep -q "tmux-start-main-sh" "$HOME/.zshrc"; then
  cat >> "$HOME/.zshrc" <<'EOF'
# tmux-start-main-sh
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
