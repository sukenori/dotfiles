FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
SHELL ["/bin/bash", "-c"]

# パッケージ一覧の更新、HTTPS 通信の証明書 curl git をインストール
RUN apt-get update && apt-get install -y ca-certificates curl git

# zsh をインストール
RUN apt-get install -y zsh

# fzf（あいまい検索）をインストール
RUN mkdir -p /root/.local/bin \
 && FZF_VERSION=$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest | grep -Po '"tag_name": "\K[^"]*' | sed 's/^v//') \
 && curl -Lo /tmp/fzf.tar.gz "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz" \
 && tar xzf /tmp/fzf.tar.gz -C "$HOME/.local/bin/" fzf \
 && chmod +x /root/.local/bin/fzf \
 && rm -f /tmp/fzf.tar.gz
ENV PATH="/root/.local/bin:${PATH}"

# Rust をインストール
RUN apt-get install -y build-essential pkg-config libssl-dev
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y \
 && echo 'source "$HOME/.cargo/env"' >> /root/.bashrc
ENV PATH="/root/.cargo/bin:/root/.local/bin:${PATH}"
# sheldon（zsh プラグインマネージャ）をインストール
RUN cargo install sheldon
# zoxide（ディレクトリ履歴の補助コマンド）をインストール
RUN cargo install zoxide --locked

# Neovim のインストール
RUN curl -Lo /tmp/nvim-linux-x86_64.tar.gz https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz \
 && tar xzf /tmp/nvim-linux-x86_64.tar.gz -C /opt \
 && ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim \
 && rm -f /tmp/nvim-linux-x86_64.tar.gz

# ripgrep（ファイル内キーワード検索）を入れる
RUN apt-get install -y ripgrep

# Node.js のインストール
RUN NODE_MAJOR=$(curl -fsSL https://resolve-node.vercel.app/lts | grep -oP '(?<=v)\d+') \
 && curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
 && apt-get install -y nodejs \
 && rm -rf /var/lib/apt/lists/*

# デフォルトシェルをZshに設定
CMD ["/bin/zsh"]

# パッケージリストキャッシュの削除
RUN rm -rf /var/lib/apt/lists/*
