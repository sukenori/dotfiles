#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------
# android/atcoder.sh
# ~/.ssh/config と ~/.bashrc に atcoder 接続設定を書き込む
#
# 使い方:
#   bash ~/dotfiles/android/atcoder.sh
#   ATCODER_HOST=itosu@100.65.96.6 bash ~/dotfiles/android/atcoder.sh
# -----------------------------------------------------------------------

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_BASHRC="${1:-$HOME/.bashrc}"
RUNTIME_FILE="$HOME/.config/atcoder-termux.sh"
SSH_CONFIG="$HOME/.ssh/config"

mkdir -p "$HOME/.config" "$HOME/.ssh"
touch "$TARGET_BASHRC" "$SSH_CONFIG"
chmod 700 "$HOME/.ssh" && chmod 600 "$SSH_CONFIG"

# --- 接続先の入力 ---
HOST="${ATCODER_HOST:-}"
if [ -z "$HOST" ]; then
  printf "接続先を入力してください（例: itosu@100.65.96.6）: "
  read -r HOST </dev/tty
fi
HOST="$(printf '%s' "$HOST" | tr -d '[:space:]')"
[[ "$HOST" =~ ^[A-Za-z0-9._-]+@[A-Za-z0-9._-]+$ ]] || {
  echo "エラー: user@host 形式で入力してください" >&2; exit 1
}

ATCODER_USER="${HOST%@*}"
ATCODER_HOSTNAME="${HOST#*@}"
ENV_DIR="${ATCODER_ENV_DIR:-~/atcoder-nim-env}"

# --- ~/.ssh/config: テンプレートからプレースホルダを置換して書き込む ---
TEMPLATE="$DOTFILES_DIR/android/.ssh/config"
SSH_BLOCK="$(sed \
  -e "s|ATCODER_HOSTNAME|${ATCODER_HOSTNAME}|g" \
  -e "s|ATCODER_USER|${ATCODER_USER}|g" \
  -e "s|ATCODER_ENV_DIR|${ENV_DIR}|g" \
  "$TEMPLATE")"

# 既存の atcoder-ssh ブロックを削除して再追記
{
  awk '/^# >>> atcoder-ssh >>>/{skip=1} /^# <<< atcoder-ssh <<</{skip=0;next} !skip{print}' "$SSH_CONFIG"
  echo ""
  echo "# >>> atcoder-ssh >>>"
  echo "$SSH_BLOCK"
  echo "# <<< atcoder-ssh <<<"
} > "${SSH_CONFIG}.tmp" && mv "${SSH_CONFIG}.tmp" "$SSH_CONFIG"

# --- ~/.config/atcoder-termux.sh: ランタイム関数 ---
cat > "$RUNTIME_FILE" << RUNTIME
#!/usr/bin/env bash
# atcoder 接続・コピー関数

_AC_HOST="${ATCODER_HOSTNAME}"
_AC_USER="${ATCODER_USER}"
_AC_DIR="${ENV_DIR}"

# コンテナへ接続（ワンタッチ）
atcoder() { ssh atcoder; }

# bundled.txt を Android クリップボードへコピー
atcoder-copy() {
  local txt
  txt="\$(ssh -o RequestTTY=no -i ~/.ssh/id_ed25519 "\${_AC_USER}@\${_AC_HOST}" \
    "wsl bash -lc 'cat \${_AC_DIR}/bundled.txt'" 2>/dev/null)" || {
    echo "取得失敗（先に ,b を実行してください）" >&2; return 1
  }
  [ -n "\$txt" ] || { echo "bundled.txt が空です" >&2; return 1; }
  printf '%s' "\$txt" | termux-clipboard-set
  echo "コピー完了（\$(printf '%s' "\$txt" | wc -c | tr -d ' ') bytes）"
}

# ,b のたびに自動コピー（Ctrl-C で停止）
atcoder-watch() {
  local last="" mtime interval="\${1:-2}"
  echo "監視中... Ctrl-C で停止"
  while :; do
    mtime="\$(ssh -o RequestTTY=no -i ~/.ssh/id_ed25519 "\${_AC_USER}@\${_AC_HOST}" \
      "wsl bash -lc 'stat -c %Y \${_AC_DIR}/bundled.txt'" 2>/dev/null || true)"
    [ "\$mtime" != "\$last" ] && [ -n "\$mtime" ] && {
      last="\$mtime"; atcoder-copy && echo "  [auto \$(date +%H:%M:%S)]"
    }
    sleep "\$interval"
  done
}
RUNTIME
chmod 600 "$RUNTIME_FILE"

# --- ~/.bashrc への source 行（冪等） ---
MARKER="# >>> atcoder >>>"
if ! grep -qF "$MARKER" "$TARGET_BASHRC"; then
  cat >> "$TARGET_BASHRC" << 'BASHRC'

# >>> atcoder >>>
[ -f "$HOME/.config/atcoder-termux.sh" ] && source "$HOME/.config/atcoder-termux.sh"
# <<< atcoder <<<
BASHRC
fi

echo ""
echo "設定完了。"
echo "  source ${TARGET_BASHRC}  で即時反映"
echo ""
echo "使い方:"
echo "  atcoder        ... コンテナに接続"
echo "  atcoder-copy   ... bundled.txt をクリップボードにコピー"
echo "  atcoder-watch  ... ,b のたびに自動コピー（常駐）"