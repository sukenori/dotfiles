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
      -- 背景を透過する
      transparent = true,
      -- サイドバー・浮動ウィンドウもテーマ側では背景を塗らない
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
      
      -- カラー変数を上書き（コントラストを高めるため、tokyonight の内部カラー変数をデフォルトより少し暗く、明るくする）
      on_colors = function(colors)
        -- bg は通常の背景色（透過させるので、コメントアウト）
        -- colors.bg = "#0b0f14"
        -- bg_dark はサイドバーや非アクティブウィンドウの背景色（透過させるので、コメントアウト）
        -- colors.bg_dark = "#0b0f14"
        -- fg は基本テキスト色
        colors.fg = "#e6edf3"
        -- コメント・行番号もデフォルトより明るく、少し青寄り
        colors.comment = "#8b9bb4"
        -- コード上のハイライトも若干くっきりさせる
        colors.blue = "#82aaff"
        colors.cyan = "#89ddff"
        colors.green = "#c3e88d"
        colors.magenta = "#c792ea"
        colors.orange = "#ffcb6b"
        colors.yellow = "#ffe082"
        colors.red = "#ff757f"
      end,

      -- 通常の編集領域・左端のサイン列は完全透過のままにする
      on_highlights = function(hl, _)
        hl.Normal = { bg = "NONE" }
        hl.NormalNC = { bg = "NONE" }
        hl.SignColumn = { bg = "NONE" }
        hl.EndOfBuffer = { bg = "NONE" }
        -- 行番号
        hl.LineNr = {
          fg = "#8b9bb4",
          bg = "NONE",
        }
        -- 現在行の番号は背景を使わず、色と太字で認識する
        hl.CursorLineNr = {
          fg = "#ffcb6b",
          bg = "NONE",
          bold = true,
        }
        -- 現在行の行全体も塗らない
        hl.CursorLine = {
          bg = "NONE",
        }

        -- 補完候補一覧も背景を完全透過する
        hl.Pmenu = {
          fg = "#e6edf3",
          bg = "NONE",
        }
        -- 選択候補も背景を塗らずに、白字・太字・下線で現在の候補を示す
        hl.PmenuSel = {
          fg = "#ffffff",
          bg = "NONE",
          bold = true,
          underline = true,
        }
        hl.PmenuSbar = {
          bg = "NONE",
        }
        hl.PmenuThumb = {
          fg = "#82aaff",
          bg = "NONE",
        }

        -- cmp の候補文字
        hl.CmpItemAbbrMatch = {
          fg = "#89ddff",
          bold = true,
        }
        hl.CmpItemAbbrMatchFuzzy = {
          fg = "#82aaff",
          bold = true,
        }
        hl.CmpItemKind = {
          fg = "#c792ea",
        }
        hl.CmpItemMenu = {
          fg = "#8b9bb4",
        }

        -- LSP hover、signature help、rename などの float
        hl.NormalFloat = {
          fg = "#e6edf3",
          bg = "NONE",
        }
        -- float は背景でなく（設定があれば）枠線で領域を示す
        hl.FloatBorder = {
          fg = "#82aaff",
          bg = "NONE",
        }
        hl.FloatTitle = {
          fg = "#c0caf5",
          bg = "NONE",
          bold = true,
        }

        -- 標準 LSP 診断の inline / virtual text
        hl.DiagnosticVirtualTextError = {
          fg = "#ff757f",
          bg = "NONE",
        }
        hl.DiagnosticVirtualTextWarn = {
          fg = "#ffcb6b",
          bg = "NONE",
        }
        hl.DiagnosticVirtualTextInfo = {
          fg = "#89ddff",
          bg = "NONE",
        }
        hl.DiagnosticVirtualTextHint = {
          fg = "#c3e88d",
          bg = "NONE",
        }
      end,
    },
    -- lazy.nvim の config 関数（第1引数はプラグインの名前やパスといったメタ情報テーブル、第2引数は opts テーブル）
    config = function(_, opts)
      -- opts で組み立てた設定をそのまま setup に渡してテーマを初期化
      require("tokyonight").setup(opts)
      -- colorscheme コマンドで適用
      vim.cmd.colorscheme("tokyonight")
    end,
  },
}