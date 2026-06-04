# デフォルトエディタ
export EDITOR="nvim"

# プロンプトは一般的なシンプル表示にする
PROMPT='%n@%m %~ %# '

# ls の色表示を有効にする
if command -v dircolors >/dev/null 2>&1; then
  eval "$(dircolors -b)"
fi
# ls: 端末表示時だけ色付け（パイプ/リダイレクト時は色なし）
alias ls='ls --color=auto'
# ll: 詳細表示(-l) + 人間が読みやすいサイズ(-h) + 隠しファイル含む(-a)
alias ll='ls -lah --color=auto'
# la: . と .. 以外の隠しファイルを含めて表示(-A)
alias la='ls -A --color=auto'

# 補完システムを有効にし、候補一覧に色を付ける
autoload -Uz compinit
compinit
if [ -n "${LS_COLORS:-}" ]; then
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
fi

# fzf のキーバインドと補完を有効にする
# 主なキー：
#   Ctrl-T でファイル/ディレクトリを選んで現在のコマンドラインへ挿入
#   Ctrl-R で履歴をあいまい検索して再利用
#   Alt-C でディレクトリを選んでその場で移動（cd）
export PATH="$HOME/.nimble/bin:$HOME/.local/bin:$PATH"
if command -v fzf >/dev/null 2>&1; then
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
  elif [ -f /usr/share/fzf/key-bindings.zsh ]; then
    source /usr/share/fzf/key-bindings.zsh
    [ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh
  elif [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
    source /usr/share/doc/fzf/examples/key-bindings.zsh
    [ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
  fi
fi

# zoxide を zsh に統合する
# 主な使い方：
#   z <一部の名前> で履歴から最適なディレクトリへ移動
#   zi で候補を一覧選択して移動（fzf がある場合）
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# zsh 補助プラグイン（sheldon）を読み込む
export ZSH_AUTOSUGGEST_USE_ASYNC=0
if command -v sheldon >/dev/null 2>&1; then
  eval "$(sheldon source)"
fi

# zsh-autosuggestions が上書きする Ctrl+N/P を解除
bindkey "^P" up-line-or-history
bindkey "^N" down-line-or-history

# tmux 下ペインで NVIM_SOCKET_PATH が渡された場合は nvr 経由で上ペインの nvim を使う。
if [ -n "${NVIM_SOCKET_PATH:-}" ]; then
  nvim() {
    if command -v nvr >/dev/null 2>&1 && [ -S "${NVIM_SOCKET_PATH}" ]; then
      nvr --servername "${NVIM_SOCKET_PATH}" --remote "$@"
    else
      command nvim "$@"
    fi
  }
fi

# ブラウザは Windows 側で既定に設定されたブラウザを使用
export BROWSER='/mnt/c/Windows/explorer.exe'

# .zshrc.localがあれば読む
[ -f "${HOME}/.zshrc.local" ] && source "${HOME}/.zshrc.local"
