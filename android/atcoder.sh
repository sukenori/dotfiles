#!/usr/bin/env bash
# bash で実行する

# パイプ途中も含めて失敗、未定義変数を検出
set -euo pipefail

# 起動するたびに自動的に読み込まれて実行される隠しファイル .bashrc にエイリアス atcoder を設定する
# スクリプトの第1引数が指定されていなければ、.bashrc をターゲットに
TARGET_FILE="${1:-$HOME/.bashrc}"
touch "$TARGET_FILE"

# Termux 側は最小限、SSH して PC 側の atcoder-nim-env/setup.sh attach を呼ぶだけ
HOST_VALUE="${ATCODER_HOST:-}"
if [ -z "${HOST_VALUE}" ]; then
  echo "CPDEV_HOST を入力してください（例: itosu@100.65.96.6）:"
  read -r HOST_VALUE
fi

# 余計な空白を除去してから、user@host 形式のみ許可する。
HOST_VALUE="$(printf '%s' "${HOST_VALUE}" | tr -d '[:space:]')"
if [[ ! "${HOST_VALUE}" =~ ^[A-Za-z0-9._-]+@[A-Za-z0-9._-]+$ ]]; then
  echo "エラー: CPDEV_HOST は user@host 形式で入力してください（例: itosu@100.65.96.6）" >&2
  exit 1
fi

ENV_DIR_VALUE="${ATCODER_ENV_DIR:-~/atcoder-nim-env}"

START_MARK="# >>> atcoder >>>"
END_MARK="# <<< atcoder <<<"

# 既存の managed block を消してから再生成する（重複防止）
TMP_FILE="$(mktemp)"
awk -v s="$START_MARK" -v e="$END_MARK" '
  $0 == s { in_block=1; next }
  $0 == e { in_block=0; next }
  !in_block { print }
' "$TARGET_FILE" > "$TMP_FILE"
mv "$TMP_FILE" "$TARGET_FILE"

cat >> "$TARGET_FILE" <<'EOF'

# >>> atcoder >>>
# Termux から PC の atcoder 開発環境へ一発接続する。
# 2ペイン化の判断は PC 側 setup.sh attach が担当する。
alias atcoder='ssh -i "$HOME/.ssh/id_ed25519" -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -t __ATCODER_HOST__ "wsl bash -lc '\''cd __ATCODER_ENV_DIR__ && ./setup.sh attach'\''"'

# Android 端末側で bundled.txt を確実にクリップボードへ取り込む。
atcoder-copy() {
  if ! command -v termux-clipboard-set >/dev/null 2>&1; then
    echo "エラー: termux-clipboard-set が見つかりません（Termux:API を確認してください）" >&2
    return 1
  fi

  local bundled_text
  if ! bundled_text="$(ssh -i "$HOME/.ssh/id_ed25519" -o ServerAliveInterval=15 -o ServerAliveCountMax=3 __ATCODER_HOST__ "wsl bash -lc '\''cat __ATCODER_ENV_DIR__/bundled.txt'\''" 2>/dev/null)"; then
    echo "エラー: bundled.txt の取得に失敗しました（先に ,b を実行してください）" >&2
    return 1
  fi

  if [ -z "$bundled_text" ]; then
    echo "エラー: bundled.txt が空です（先に ,b を実行してください）" >&2
    return 1
  fi

  if printf '%s' "$bundled_text" | termux-clipboard-set; then
    echo "Android クリップボードへコピーしました。"
    return 0
  fi

  if termux-clipboard-set "$bundled_text"; then
    echo "Android クリップボードへコピーしました。"
    return 0
  fi

  echo "エラー: termux-clipboard-set へのコピーに失敗しました" >&2
  return 1
}
# <<< atcoder <<<
EOF

sed -i "s|__ATCODER_HOST__|${HOST_VALUE}|g; s|__ATCODER_ENV_DIR__|${ENV_DIR_VALUE}|g" "$TARGET_FILE"

# ~/.bashrc の反映を促す。
echo "atcoder エイリアスを ${TARGET_FILE} に設定しました。"
echo "source ${TARGET_FILE} 後に atcoder で接続できます。"
echo "bundle 後に Android へ確実コピーするには atcoder-copy を使えます。"
