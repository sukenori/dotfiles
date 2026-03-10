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

# 上ペインの Neovim でファイルを開く（tmux の下ペインから使う）
# tmux + Neovim server mode で実現。Neovim が起動していなければ普通に開く
function e() {
  local target="${1:?ファイル名を指定してください}"
  local abs
  abs="$(realpath -m -- "$target")"
  local pane
  pane=""

  # tmux の main:editor で「上側にある nvim ペイン」を探して :edit を送り込む
  # pane index の 0/1 始まり差異に依存しないため、環境差で壊れにくい
  if tmux has-session -t main:editor 2>/dev/null; then
    pane="$(tmux list-panes -t main:editor -F '#{pane_id} #{pane_top} #{pane_current_command}' \
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

  # tmux 外では、ソケットがあれば remote を試す（長く待たない）
  if [[ -S /tmp/nvim-main.sock ]] && timeout 1 nvim --server /tmp/nvim-main.sock --remote "$abs" >/dev/null 2>&1; then
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
