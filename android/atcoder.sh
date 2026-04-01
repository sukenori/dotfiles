#!/usr/bin/env bash
# bash で実行する

set -euo pipefail

# 生成先（既定: ~/.bashrc）
TARGET_FILE="${1:-$HOME/.bashrc}"
touch "$TARGET_FILE"

# 接続先 host（user@host 形式）
HOST_VALUE="${ATCODER_HOST:-}"
if [ -z "$HOST_VALUE" ]; then
  echo "CPDEV_HOST を入力してください（例: itosu@100.65.96.6）:"
  read -r HOST_VALUE
fi
HOST_VALUE="$(printf '%s' "$HOST_VALUE" | tr -d '[:space:]')"
if [[ ! "$HOST_VALUE" =~ ^[A-Za-z0-9._-]+@[A-Za-z0-9._-]+$ ]]; then
  echo "エラー: CPDEV_HOST は user@host 形式で入力してください（例: itosu@100.65.96.6）" >&2
  exit 1
fi

# WSL 側 atcoder-nim-env パス
ENV_DIR_VALUE="${ATCODER_ENV_DIR:-~/atcoder-nim-env}"

START_MARK="# >>> atcoder >>>"
END_MARK="# <<< atcoder <<<"

# 既存 managed block を消して再生成（重複防止）
TMP_FILE="$(mktemp)"
awk -v s="$START_MARK" -v e="$END_MARK" '
  $0 == s { in_block=1; next }
  $0 == e { in_block=0; next }
  !in_block { print }
' "$TARGET_FILE" > "$TMP_FILE"
mv "$TMP_FILE" "$TARGET_FILE"

cat >> "$TARGET_FILE" <<'BLOCK'

# >>> atcoder >>>
# Termux -> SSH(Windows/WSL) -> atcoder-nim-env
atcoder_host="__ATCODER_HOST__"
atcoder_env_dir="__ATCODER_ENV_DIR__"
atcoder_auto_copy="${ATCODER_AUTO_COPY:-1}"

_atcoder_ssh() {
  ssh -i "$HOME/.ssh/id_ed25519" -o ServerAliveInterval=15 -o ServerAliveCountMax=3 "$@"
}

atcoder_copy_impl() {
  if ! command -v termux-clipboard-set >/dev/null 2>&1; then
    echo "エラー: termux-clipboard-set が見つかりません（Termux:API を確認してください）" >&2
    return 1
  fi

  local tmp_file
  tmp_file="$(mktemp)"

  if ! _atcoder_ssh "$atcoder_host" "wsl bash -lc 'set -euo pipefail; test -s ${atcoder_env_dir}/bundled.txt; cat ${atcoder_env_dir}/bundled.txt'" > "$tmp_file"; then
    rm -f "$tmp_file"
    echo "エラー: bundled.txt の取得に失敗しました（先に ,b を実行してください）" >&2
    return 1
  fi

  if [ ! -s "$tmp_file" ]; then
    rm -f "$tmp_file"
    echo "エラー: bundled.txt が空です（先に ,b を実行してください）" >&2
    return 1
  fi

  if ! termux-clipboard-set < "$tmp_file"; then
    rm -f "$tmp_file"
    echo "エラー: termux-clipboard-set へのコピーに失敗しました" >&2
    return 1
  fi

  rm -f "$tmp_file"
  echo "Android クリップボードへコピーしました。"
  return 0
}

atcoder_watch_copy_impl() {
  local interval="${1:-1}"
  local last_mtime=""

  while :; do
    local mtime
    mtime="$(_atcoder_ssh "$atcoder_host" "wsl bash -lc 'if [ -s ${atcoder_env_dir}/bundled.txt ]; then stat -c %Y ${atcoder_env_dir}/bundled.txt; fi'" 2>/dev/null || true)"

    if [ -n "$mtime" ] && [ "$mtime" != "$last_mtime" ]; then
      last_mtime="$mtime"
      if atcoder_copy_impl >/dev/null 2>&1; then
        echo "[auto-copy] Android clipboard updated" >&2
      else
        echo "[auto-copy] copy failed (run atcoder-copy for details)" >&2
      fi
    fi

    sleep "$interval"
  done
}

atcoder() {
  local watcher_pid=""

  if [ "$atcoder_auto_copy" = "1" ] && command -v termux-clipboard-set >/dev/null 2>&1; then
    atcoder_watch_copy_impl 1 &
    watcher_pid=$!
  fi

  _atcoder_ssh -t "$atcoder_host" "wsl bash -lc 'cd ${atcoder_env_dir} && ./setup.sh attach'"
  local exit_code=$?

  if [ -n "$watcher_pid" ]; then
    kill "$watcher_pid" >/dev/null 2>&1 || true
    wait "$watcher_pid" 2>/dev/null || true
  fi

  return "$exit_code"
}

alias atcoder-copy='atcoder_copy_impl'
alias atcoder-watch-copy='atcoder_watch_copy_impl'
# <<< atcoder <<<
BLOCK

sed -i "s|__ATCODER_HOST__|${HOST_VALUE}|g; s|__ATCODER_ENV_DIR__|${ENV_DIR_VALUE}|g" "$TARGET_FILE"

echo "atcoder 設定を ${TARGET_FILE} に更新しました。"
echo "source ${TARGET_FILE} 後に atcoder で接続できます。"
echo "接続中は ,b 後の bundled 更新で自動コピーが動作します（ATCODER_AUTO_COPY=1）。"
