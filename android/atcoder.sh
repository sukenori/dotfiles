#!/usr/bin/env bash
# bash で実行する

# パイプ途中も含めて失敗、未定義変数を検出
set -euo pipefail

# 起動するたびに自動的に読み込まれて実行される隠しファイル .bashrc にエイリアス atcoder を設定する
# スクリプトの第1引数が指定されていなければ、.bashrc をターゲットに
TARGET_FILE="${1:-$HOME/.bashrc}"
touch "$TARGET_FILE"

# Termux 側は最小構成、SSH して PC 側の atcoder-nim-env/setup.sh attach を呼ぶだけ
HOST_VALUE="${ATCODER_HOST:-}"
if [ -z "${HOST_VALUE}" ]; then
  echo "CPDEV_HOST を入力してください（例: itosu@100.65.96.6）:"
  read -r HOST_VALUE
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
# <<< atcoder <<<
EOF

sed -i "s|__ATCODER_HOST__|${HOST_VALUE}|g; s|__ATCODER_ENV_DIR__|${ENV_DIR_VALUE}|g" "$TARGET_FILE"

# ~/.bashrc の反映を促す。
echo "atcoder エイリアスを ${TARGET_FILE} に設定しました。"
echo "source ${TARGET_FILE} 後に atcoder で接続できます。"
