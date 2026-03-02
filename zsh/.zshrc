# プロンプト（コマンド入力行）の見た目設定
# 左側に「ユーザー名@マシン名 現在地 % 」を色付きで表示する
PROMPT="%F{green}%n@%m%f %F{cyan}%~%f %# "

# コマンド履歴の設定
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt share_history        # 複数のターミナル間で履歴を共有する
setopt hist_ignore_dups     # 直前と同じコマンドは履歴に追加しない

# cdした後に自動でlsを実行する（好みに応じて）
function chpwd() { ls -l }

# --- プラグインの読み込み（必須） ---
# 過去の履歴から薄いグレーで予測表示
source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
# コマンドの文法チェック（正しければ緑、間違っていれば赤）
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

function cnim() {
  # プロジェクトのディレクトリに移動
  cd ~/atcoder-nim-env

  # コンテナ "atcoder-nim" が実行中(running)かどうか確認
  if [ "$(docker inspect -f '{{.State.Running}}' atcoder-nim 2>/dev/null)" != "true" ]; then
    echo "コンテナが起動していません。起動します..."
    docker compose up -d
  fi

  # コンテナの中に入る
  echo "Nim環境に入ります..."
  docker exec -it atcoder-nim bash
}
