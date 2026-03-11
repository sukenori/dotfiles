# ===========================================================================
# .zshrc — zsh の設定ファイル
#
# 読み込み順: sheldon (プラグイン) → zoxide (賢い cd) → pure (プロンプト)
# ===========================================================================

# ---------------------------------------------------------------------------
# コマンド履歴の設定
# ---------------------------------------------------------------------------
HISTFILE=~/.zsh_history    # 履歴の保存先
HISTSIZE=10000             # メモリ上に保持する履歴の件数
SAVEHIST=10000             # ファイルに保存する履歴の件数
setopt share_history       # 複数のターミナル間で履歴を共有する
setopt hist_ignore_dups    # 直前と同じコマンドは履歴に追加しない

# ---------------------------------------------------------------------------
# 便利設定
# ---------------------------------------------------------------------------
# cd した直後に ls -la を自動実行する
function chpwd() { ls -la }

# AtCoder の解答コードを日付フォルダに整理するショートカット
alias archive='make -C ~/atcoder-nim-env archive'

# Git コマンドの入力を短くする
alias g='git'

# 現在のディレクトリから親をたどって repo ローカル launcher を探して実行する
# まず bin/dev、次に bin/dev-tmux を探す
function dev() {
  local dir launcher
  dir="$PWD"

  while [[ -n "$dir" ]]; do
    for launcher in "$dir/bin/dev" "$dir/bin/dev-tmux"; do
      if [[ -x "$launcher" ]]; then
        (cd "$dir" && exec "$launcher" "$@")
        return
      fi
    done

    if [[ "$dir" == "$HOME" || "$dir" == "/" ]]; then
      break
    fi
    dir="${dir:h}"
  done

  print -u2 "dev: repo ローカル launcher が見つかりません（bin/dev または bin/dev-tmux）"
  return 1
}

# 上ペインの Neovim でファイルを開く（tmux の下ペインから使う）
# tmux 内では「今いるウィンドウの nvim ペイン」を探して :edit を送り込む。
# 見つからなければ普通に nvim を起動する。
function e() {
  local target="${1:?ファイル名を指定してください}"
  local abs
  abs="$(realpath -m -- "$target")"
  local pane
  pane=""

  # 現在の tmux ウィンドウで「上側にある nvim ペイン」を探して :edit を送り込む
  # これなら session 名や window 名を固定しなくてよい
  if [[ -n "${TMUX:-}" ]]; then
    pane="$(tmux list-panes -F '#{pane_id} #{pane_top} #{pane_current_command}' \
      | awk '$3=="nvim"{print $1, $2}' \
      | sort -k2,2n \
      | head -n1 \
      | awk '{print $1}')"
  fi

  if [[ -n "$pane" ]]; then
    local escaped="${abs// /\\ }"
    tmux send-keys -t "$pane" Escape ":edit $escaped" Enter
    return
  fi

  # tmux 内だが nvim ペインが見つからない場合は誤って別 pane で remote しない
  if [[ -n "${TMUX:-}" ]]; then
    print -u2 "e: 現在の tmux ウィンドウに nvim ペインが見つかりません"
    return 1
  fi

  # tmux 外では、明示されたソケットがあれば remote を試す（長く待たない）
  if [[ -n "${NVIM_LISTEN_ADDRESS:-}" ]] && [[ -S "${NVIM_LISTEN_ADDRESS}" ]] \
    && timeout 1 nvim --server "$NVIM_LISTEN_ADDRESS" --remote "$abs" >/dev/null 2>&1; then
    return
  fi

  nvim "$@"
}

# ---------------------------------------------------------------------------
# PATH の設定
# ---------------------------------------------------------------------------
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# ---------------------------------------------------------------------------
# fzf（あいまい検索ツール）の設定
# ---------------------------------------------------------------------------
if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)"
fi
# Ctrl+T でファイルを検索するとき、.git フォルダを除外する
export FZF_CTRL_T_COMMAND='find . -name ".git" -prune -o -print'

# ---------------------------------------------------------------------------
# sheldon（zsh プラグインマネージャ）の読み込み
# → plugins.toml に書かれたプラグインを自動でダウンロード・適用する
# ---------------------------------------------------------------------------
eval "$(sheldon source)"

# ---------------------------------------------------------------------------
# zoxide（賢い cd コマンド）の読み込み
# → "z foo" と打つだけで、過去に訪れた foo を含むディレクトリに飛べる
# ---------------------------------------------------------------------------
eval "$(zoxide init zsh)"

# ---------------------------------------------------------------------------
# pure プロンプトの有効化
# → sheldon 経由でインストール済みの pure テーマを起動する
# ---------------------------------------------------------------------------
autoload -U promptinit; promptinit
prompt pure
