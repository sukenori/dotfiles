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

alias archive='make -C /workspace/env archive'

# fzfの設定
source /usr/share/doc/fzf/examples/completion.zsh 2>/dev/null || true
source /usr/share/doc/fzf/examples/key-bindings.zsh 2>/dev/null || true
export FZF_CTRL_T_COMMAND='find . -name ".git" -prune -o -print'

# パスの設定 (Cargoのパスも追加しておくことでRustツールが確実に動きます)
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# sheldonとzoxideの読み込み
# （※プラグインはすべてSheldonが管理し、自動でダウンロード・適用してくれます）
eval "$(sheldon source)"
eval "$(zoxide init zsh)"

# pureプロンプトの有効化
autoload -U promptinit; promptinit
prompt pure

# --- WSL起動時にZellijを自動起動する設定（安全装置付き） ---
# ZELLIJの中ではなく、かつNeovimの中（ターミナルペイン）でもない場合のみ起動する
if [[ -z "$ZELLIJ" && -z "$NVIM" ]]; then
  exec zellij attach -c main
fi
