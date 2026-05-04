#!/bin/bash
# コンテナ内なので、このシェバンでよし

# 各設定ファイルへのシンボリックリンク作成
# ln -s（link）で、シンボリックリンク、-f で上書き
ln -sf "$HOME/dotfiles/git/.gitconfig" "$HOME/.gitconfig"
ln -sf "$HOME/dotfiles/tmux/.tmux.conf" "$HOME/.tmux.conf"
ln -sf "$HOME/dotfiles/zsh/.zshrc" "$HOME/.zshrc"
# mkdir -p で、sheldon に対して親の .config がなくても、一緒に作ってくれる
mkdir -p "$HOME/.config/sheldon"
ln -sf "$HOME/dotfiles/sheldon/plugins.toml" "$HOME/.config/sheldon/plugins.toml"
# nvim はファイルでなくディレクトリ丸々で -f できないので、一旦削除の上、リンクを張る
rm -rf "$HOME/.config/nvim"
ln -s "$HOME/dotfiles/nvim" "$HOME/.config/nvim"

# docker run の引数や、docker-compose.yaml の command:、Dockefile の CMD で渡されたコマンドを実行する（今回は、docker-compose.yaml の command:）
exec "$@"
