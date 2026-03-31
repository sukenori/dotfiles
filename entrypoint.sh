#!/bin/bash
# 各設定ファイルへのシンボリックリンク作成
mkdir -p "$HOME/.config/sheldon"
ln -sf "$HOME/dotfiles/git/.gitconfig" "$HOME/.gitconfig"
ln -sf "$HOME/dotfiles/tmux/.tmux.conf" "$HOME/.tmux.conf"
ln -sf "$HOME/dotfiles/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$HOME/dotfiles/sheldon/plugins.toml" "$HOME/.config/sheldon/plugins.toml"
rm -rf "$HOME/.config/nvim"
ln -s "$HOME/dotfiles/nvim" "$HOME/.config/nvim"

# 本来のコマンド（zshなど）に処理を引き継ぐ
exec "$@"
