#!/usr/bin/env bash
set -euo pipefail

TARGET_FILE="${1:-$HOME/.bashrc}"
SSH_CONFIG_FILE="$HOME/.ssh/config"

touch "$TARGET_FILE"
mkdir -p "$HOME/.ssh"
touch "$SSH_CONFIG_FILE"
chmod 700 "$HOME/.ssh"
chmod 600 "$SSH_CONFIG_FILE"

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

ATCODER_USER="${HOST_VALUE%@*}"
ATCODER_HOSTNAME="${HOST_VALUE#*@}"
ENV_DIR_VALUE="${ATCODER_ENV_DIR:-~/atcoder-nim-env}"

SHELL_START="# >>> atcoder >>>"
SHELL_END="# <<< atcoder <<<"
SSH_START="# >>> atcoder-ssh >>>"
SSH_END="# <<< atcoder-ssh <<<"

rewrite_block() {
  local file="$1"
  local start="$2"
  local end="$3"
  local content_file="$4"

  local tmp_file
  tmp_file="$(mktemp)"
  awk -v s="$start" -v e="$end" '
    $0 == s { in_block=1; next }
    $0 == e { in_block=0; next }
    !in_block { print }
  ' "$file" > "$tmp_file"
  cat "$content_file" >> "$tmp_file"
  mv "$tmp_file" "$file"
}

SHELL_BLOCK_FILE="$(mktemp)"
cat > "$SHELL_BLOCK_FILE" <<'BLOCK'

# >>> atcoder >>>
# Termux -> SSH(Windows/WSL) -> atcoder-nim-env
atcoder_env_dir="__ATCODER_ENV_DIR__"
atcoder_auto_copy="${ATCODER_AUTO_COPY:-1}"

atcoder_copy_impl() {
  if ! command -v termux-clipboard-set >/dev/null 2>&1; then
    echo "エラー: termux-clipboard-set が見つかりません（Termux:API を確認してください）" >&2
    return 1
  fi

  local tmp_file
  tmp_file="$(mktemp)"

  if ! ssh cpdev "wsl bash -lc 'set -euo pipefail; test -s ${atcoder_env_dir}/bundled.txt; cat ${atcoder_env_dir}/bundled.txt'" > "$tmp_file"; then
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
}

atcoder_watch_copy_impl() {
  local interval="${1:-1}"
  local last_mtime=""

  while :; do
    local mtime
    mtime="$(ssh cpdev "wsl bash -lc 'if [ -s ${atcoder_env_dir}/bundled.txt ]; then stat -c %Y ${atcoder_env_dir}/bundled.txt; fi'" 2>/dev/null || true)"

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

atcoder_impl() {
  local watcher_pid=""

  if [ "$atcoder_auto_copy" = "1" ] && command -v termux-clipboard-set >/dev/null 2>&1; then
    atcoder_watch_copy_impl 1 &
    watcher_pid=$!
  fi

  ssh atcoder
  local exit_code=$?

  if [ -n "$watcher_pid" ]; then
    kill "$watcher_pid" >/dev/null 2>&1 || true
    wait "$watcher_pid" 2>/dev/null || true
  fi

  return "$exit_code"
}

alias atcoder='atcoder_impl'
alias atcoder-copy='atcoder_copy_impl'
alias atcoder-watch-copy='atcoder_watch_copy_impl'
# <<< atcoder <<<
BLOCK

SSH_BLOCK_FILE="$(mktemp)"
cat > "$SSH_BLOCK_FILE" <<'BLOCK'

# >>> atcoder-ssh >>>
Host cpdev
  HostName __ATCODER_HOSTNAME__
  User __ATCODER_USER__
  IdentityFile ~/.ssh/id_ed25519
  ServerAliveInterval 15
  ServerAliveCountMax 3

Host atcoder
  HostName __ATCODER_HOSTNAME__
  User __ATCODER_USER__
  IdentityFile ~/.ssh/id_ed25519
  ServerAliveInterval 15
  ServerAliveCountMax 3
  RequestTTY yes
  RemoteCommand wsl bash -lc "cd __ATCODER_ENV_DIR__ && ./setup.sh attach"
# <<< atcoder-ssh <<<
BLOCK

sed -i "s|__ATCODER_ENV_DIR__|${ENV_DIR_VALUE}|g" "$SHELL_BLOCK_FILE"
sed -i "s|__ATCODER_HOSTNAME__|${ATCODER_HOSTNAME}|g; s|__ATCODER_USER__|${ATCODER_USER}|g; s|__ATCODER_ENV_DIR__|${ENV_DIR_VALUE}|g" "$SSH_BLOCK_FILE"

rewrite_block "$TARGET_FILE" "$SHELL_START" "$SHELL_END" "$SHELL_BLOCK_FILE"
rewrite_block "$SSH_CONFIG_FILE" "$SSH_START" "$SSH_END" "$SSH_BLOCK_FILE"

rm -f "$SHELL_BLOCK_FILE" "$SSH_BLOCK_FILE"

echo "atcoder 設定を ${TARGET_FILE} に更新しました。"
echo "SSH 設定を ${SSH_CONFIG_FILE} に更新しました。"
echo "source ${TARGET_FILE} 後に atcoder で接続できます。"
echo "接続中は ,b 後の bundled 更新で自動コピーが動作します（ATCODER_AUTO_COPY=1）。"
