-- colorscheme.lua — カラースキームに対する設定

return {
  {
    -- treesitter / LSP の各ハイライトグループに対応したテーマが同梱された folke 製のカラースキーム
    "folke/tokyonight.nvim",
    -- 起動時に即座に読み込む
    lazy = false,
    -- 他のプラグインより先に読み込まれるように設定（数字が大きいほど優先度が高い）
    priority = 1000,
    opts = {
      -- tokyonight のスタイルバリアントのうち、最も暗い night
      style = "night",
      -- 背景を透過しない
      transparent = false,
      -- カラー変数を上書き（コントラストを高めるため、tokyonight の内部カラー変数をデフォルトより少し暗く、明るくする）
      on_colors = function(colors)
        -- bg は通常の背景色
        colors.bg = "#0b0f14"
        -- bg_dark はサイドバーや非アクティブウィンドウの背景色
        colors.bg_dark = "#0b0f14"
        -- fg は基本テキスト色
        colors.fg = "#e6edf3"
      end,
    },
    -- lazy.nvim config 関数（第1引数はプラグインの名前やパスといったメタ情報テーブル、第2引数は opts テーブル）
    config = function(_, opts)
      -- opts で組み立てた設定をそのまま setup に渡してテーマを初期化
      require("tokyonight").setup(opts)
      -- colorscheme コマンドで適用
      vim.cmd.colorscheme("tokyonight")
    end,
  },
}