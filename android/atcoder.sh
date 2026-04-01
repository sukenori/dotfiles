#!/usr/bin/env bash
set -euo pipefail

TARGET_BASHRC="${1:-$HOME/.bashrc}"
RUNTIME_FILE="$HOME/.config/atcoder-termux.sh"
SSH_CONFIG_FILE="$HOME/.ssh/config"

mkdir -p "$HOME/.config" "$HOME/.ssh"
touch "$TARGET_BASHRC" "$SSH_CONFIG_FILE"
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

RUNTIME_TMP="$(mktemp)"
cat > "$RUNTIME_TMP" <<'RUNTIME_BLOCK'
#!/usr/bin/env bash

atcoder_env_dir="__ATCODER_ENV_DIR__"
atcoder_auto_copy="${ATCODER_AUTO_COPY:-1}"

atcoder_copy_impl() {
  if ! command -v termux-clipboard-set >/dev/null 2>&1; then
    echo "エラー: termux-clipboard-set が見つかりません（Termux:API を確認してください）" >&2
    return 1
  fi

  local tmp_file
  tmp_file="$(mktemp)"

  if ! ssh cpdev "wsl bash -lc \"set -euo pipefail; test -s ${atcoder_env_dir}/bundled.txt; cat ${atcoder_env_dir}/bundled.txt\"" > "$tmp_file"; then
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
    # 一部環境で stdin 経路が不安定な場合に備えて引数経路も試す。
    if ! termux-clipboard-set "$(cat "$tmp_file")"; then
      rm -f "$tmp_file"
      echo "エラー: termux-clipboard-set へのコピーに失敗しました" >&2
      return 1
    fi
  fi

  local copied_bytes
  copied_bytes="$(wc -c < "$tmp_file" | tr -d '[:space:]')"

  if command -v termux-clipboard-get >/dev/null 2>&1 && command -v sha256sum >/dev/null 2>&1; then
    local src_sha dst_sha
    src_sha="$(sha256sum "$tmp_file" | awk '{print $1}')"
    dst_sha="$(termux-clipboard-get | sha256sum | awk '{print $1}')"
    rm -f "$tmp_file"

    if [ "$src_sha" != "$dst_sha" ]; then
      echo "エラー: Android クリップボード反映の検証に失敗しました（${copied_bytes} bytes）" >&2
      return 1
    fi

    echo "Android クリップボードへコピーしました（検証OK, ${copied_bytes} bytes）。"
    return 0
  fi

  rm -f "$tmp_file"
  echo "Android クリップボードへコピーしました（${copied_bytes} bytes）。"
}

atcoder_watch_copy_impl() {
  local interval="${1:-1}"
  local last_mtime=""

  while :; do
    local mtime
    mtime="$(ssh cpdev "wsl bash -lc \"if [ -s ${atcoder_env_dir}/bundled.txt ]; then stat -c %Y ${atcoder_env_dir}/bundled.txt; fi\"" 2>/dev/null || true)"

    if [ -n "$mtime" ] && [ "$mtime" != "$last_mtime" ]; then
      last_mtime="$mtime"
      local copy_msg
      if copy_msg="$(atcoder_copy_impl 2>&1)"; then
        echo "[auto-copy] ${copy_msg}" >&2
      else
        echo "[auto-copy] FAILED: ${copy_msg}" >&2
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
RUNTIME_BLOCK

sed -i "s|__ATCODER_ENV_DIR__|${ENV_DIR_VALUE}|g" "$RUNTIME_TMP"
bash -n "$RUNTIME_TMP"
mv "$RUNTIME_TMP" "$RUNTIME_FILE"
chmod 600 "$RUNTIME_FILE"

SHELL_BLOCK_FILE="$(mktemp)"
cat > "$SHELL_BLOCK_FILE" <<SHELL_BLOCK

$SHELL_START
[ -f "\$HOME/.config/atcoder-termux.sh" ] && source "\$HOME/.config/atcoder-termux.sh"
$SHELL_END
SHELL_BLOCK

SSH_BLOCK_FILE="$(mktemp)"
cat > "$SSH_BLOCK_FILE" <<'SSH_BLOCK'

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
SSH_BLOCK

sed -i "s|__ATCODER_HOSTNAME__|${ATCODER_HOSTNAME}|g; s|__ATCODER_USER__|${ATCODER_USER}|g; s|__ATCODER_ENV_DIR__|${ENV_DIR_VALUE}|g" "$SSH_BLOCK_FILE"

rewrite_block "$TARGET_BASHRC" "$SHELL_START" "$SHELL_END" "$SHELL_BLOCK_FILE"
rewrite_block "$SSH_CONFIG_FILE" "$SSH_START" "$SSH_END" "$SSH_BLOCK_FILE"

rm -f "$SHELL_BLOCK_FILE" "$SSH_BLOCK_FILE"

echo "atcoder 設定を ${TARGET_BASHRC} と ${RUNTIME_FILE} に更新しました。"
echo "SSH 設定を ${SSH_CONFIG_FILE} に更新しました。"
echo "source ${TARGET_BASHRC} 後に atcoder で接続できます。"
