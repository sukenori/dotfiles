#!/usr/bin/env bash

set -euo pipefail

TARGET_FILE="${1:-$HOME/.bashrc}"
touch "$TARGET_FILE"

# Termux 側は最小構成にする。
# cpdev は「SSH して PC 側の atcoder-nim-env/setup.sh attach を呼ぶだけ」に固定する。
HOST_VALUE="${CPDEV_HOST:-}"
if [ -z "${HOST_VALUE}" ]; then
  echo "CPDEV_HOST を入力してください（例: itosu@100.65.96.6）:"
  read -r HOST_VALUE
fi

ENV_DIR_VALUE="${CPDEV_ENV_DIR:-~/atcoder-nim-env}"

START_MARK="# >>> cpdev >>>"
END_MARK="# <<< cpdev <<<"

# 既存の managed block を消してから再生成する（重複防止）。
TMP_FILE="$(mktemp)"
awk -v s="$START_MARK" -v e="$END_MARK" '
  $0 == s { in_block=1; next }
  $0 == e { in_block=0; next }
  !in_block { print }
' "$TARGET_FILE" > "$TMP_FILE"
mv "$TMP_FILE" "$TARGET_FILE"

cat >> "$TARGET_FILE" <<'EOF'

# >>> cpdev >>>
# Termux から PC の atcoder 開発環境へ一発接続する。
# 2ペイン化の判断は PC 側 setup.sh attach が担当する。
alias cpdev='ssh -i "$HOME/.ssh/id_ed25519" -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -t __CPDEV_HOST__ "wsl bash -lc '\''cd __CPDEV_ENV_DIR__ && ./setup.sh attach'\''"'
# <<< cpdev <<<
EOF

sed -i "s|__CPDEV_HOST__|${HOST_VALUE}|g; s|__CPDEV_ENV_DIR__|${ENV_DIR_VALUE}|g" "$TARGET_FILE"

# ~/.bashrc の反映を促す。
echo "cpdev エイリアスを ${TARGET_FILE} に設定しました。"
echo "source ${TARGET_FILE} 後に cpdev で接続できます。"
