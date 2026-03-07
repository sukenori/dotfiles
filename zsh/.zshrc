# プロンプト（コマンド入力行）の見た目設定
PROMPT="%F{cyan}%~%f %# "

# コマンド履歴の設定
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt share_history        # 複数のターミナル間で履歴を共有する
setopt hist_ignore_dups     # 直前と同じコマンドは履歴に追加しない

# cdした後に自動でlsを実行する（好みに応じて）
function chpwd() { ls -la }

# --- プラグインの読み込み（必須） ---
# 過去の履歴から薄いグレーで予測表示
source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
# コマンドの文法チェック（正しければ緑、間違っていれば赤）
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

alias archive='make -C /workspace/env archive'

source /usr/share/doc/fzf/examples/completion.zsh
source /usr/share/doc/fzf/examples/key-bindings.zsh

export PATH="$HOME/.local/bin:$PATH"
#fzfの設定（以前のものを維持）
export FZF_CTRL_T_COMMAND='find . -name ".git" -prune -o -print'

#sheldonとzoxideの読み込み
eval "$(sheldon source)"
eval "$(zoxide init zsh)"

#pureプロンプトの有効化
autoload -U promptinit; promptinit
prompt pure

#WSL起動時にZellijを自動起動する設定（一番下に書きます）
if [[ -z "$ZELLIJ" ]]; then
exec zellij attach -c main
fi
