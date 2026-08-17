FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo
SHELL ["/bin/bash", "-c"]

# パッケージ一覧の更新、HTTPS 通信の証明書 curl git をインストール
RUN apt-get update && apt-get install -y ca-certificates curl git

# zsh をインストール
RUN apt-get update && apt-get install -y zsh

# tmux をインストール
RUN apt-get update && apt-get install -y tmux

# fzf（あいまい検索）（FZF_VERSION 固定）をインストール
RUN FZF_VERSION="$(curl -fsSL https://api.github.com/repos/junegunn/fzf/releases/latest | grep -Po '"tag_name": "\\K[^"]*' | sed 's/^v//')" \
 && curl -fsSL -o /tmp/fzf.tar.gz "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz" \
 && tar -xzf /tmp/fzf.tar.gz -C /tmp fzf \
 && install -m 0755 /tmp/fzf /usr/local/bin/fzf \
 && rm -f /tmp/fzf /tmp/fzf.tar.gz

# Sheldon（zsh プラグインマネージャ）をインストール（prebuilt binary を /usr/local/bin に導入）
RUN curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh \
  | bash -s -- --repo rossmacarthur/sheldon --to /usr/local/bin

# zoxide（ディレクトリ履歴の補助コマンド）をインストール（upstream installer で共有バイナリとして導入）
RUN curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh \
  | env BIN_DIR=/usr/local/bin sh

# Neovim のインストール（system-wide install）
RUN curl -fsSL -o /tmp/nvim-linux-x86_64.tar.gz https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz \
 && tar -xzf /tmp/nvim-linux-x86_64.tar.gz -C /opt \
 && ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim \
 && rm -f /tmp/nvim-linux-x86_64.tar.gz

# neovim-remote（シェルから nvim プロセスを制御するコマンド）をインストール
RUN apt-get update && apt-get install -y python3-pip \
 && pip3 install --no-cache-dir neovim-remote

# ripgrep（ファイル内キーワード検索、PCRE2 先読み対応版）をインストール
ARG RIPGREP_VERSION=14.1.1
RUN curl -fsSL "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl.tar.gz" -o /tmp/rg.tar.gz \
 && tar -xzf /tmp/rg.tar.gz -C /tmp \
 && install -m 0755 "/tmp/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl/rg" /usr/local/bin/rg \
 && rm -rf /tmp/rg.tar.gz "/tmp/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl"

# Neovim plugin 用の Node.js をインストール
RUN NODE_MAJOR=$(curl -fsSL https://resolve-node.vercel.app/lts | grep -oP '(?<=v)\d+') \
 && curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
 && apt-get install -y nodejs

# パッケージリストキャッシュの削除
RUN rm -rf /var/lib/apt/lists/*

# 最終的な開発ユーザーは child image 側で定義
