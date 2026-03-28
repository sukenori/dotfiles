# デフォルトエディタ
export EDITOR="nvim"

# プロンプトは一般的なシンプル表示にする（Pure を使う場合はこの設定を外す）
PROMPT='%n@%m %~ %# '

# ls の色表示を有効にする
if command -v dircolors >/dev/null 2>&1; then
  eval "$(dircolors -b)"
fi
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'

# 補完システムを有効にし、候補一覧に色を付ける
autoload -Uz compinit
compinit
if [ -n "${LS_COLORS:-}" ]; then
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
fi

# fzf のキーバインドと補完を有効にする
# 主なキー:
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

  # 配布差分で Ctrl-T が未設定になるケースの保険。
  if typeset -f fzf-file-widget >/dev/null 2>&1; then
    bindkey '^T' fzf-file-widget
  fi
fi

# zoxide を zsh に統合する
# 主な使い方:
#   z <一部の名前> で履歴から最適なディレクトリへ移動
#   zi で候補を一覧選択して移動（fzf がある場合）
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# zsh 補助プラグインを読み込む（sheldon 管理）
export ZSH_AUTOSUGGEST_USE_ASYNC=1
if command -v sheldon >/dev/null 2>&1; then
  eval "$(sheldon source)"
else
  # sheldon が使えないときのみシステム配置をフォールバックで読む
  [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Neovim リモート連携に使う既定ソケット。
# ここでは export せず、必要時だけ子プロセスへ渡して起動警告を防ぐ。
typeset -g NVIM_SOCKET_PATH="${NVIM_SOCKET_PATH:-/tmp/nvimsocket}"
nvim() {
  local socket="${NVIM_SOCKET_PATH:-/tmp/nvimsocket}"

  if [ "${NVIM_REMOTE_ENABLE:-0}" = "1" ] \
    && command -v nvr >/dev/null 2>&1 \
    && [ -S "${socket}" ] \
    && [ -n "${TMUX:-}" ]; then
    nvr --server "${socket}" --remote "$@"
  else
    # リモート連携モード時は、この起動でのみソケットを渡す。
    if [ "${NVIM_REMOTE_ENABLE:-0}" = "1" ] && [ -n "${TMUX:-}" ]; then
      NVIM_LISTEN_ADDRESS="${socket}" command nvim "$@"
    else
      command nvim "$@"
    fi
  fi
}

# ブラウザは Windows 側で既定に設定されたブラウザを使用
export BROWSER='/mnt/c/Windows/explorer.exe'
