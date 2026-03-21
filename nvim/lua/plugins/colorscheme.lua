-- colorscheme.lua -- 黒背景で読みやすい配色
return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "night",
      transparent = false,
      terminal_colors = true,
      on_colors = function(colors)
        colors.bg = "#0b0f14"
        colors.bg_dark = "#0b0f14"
        colors.fg = "#e6edf3"
      end,
      on_highlights = function(hl, _)
        hl.Normal = { fg = "#e6edf3", bg = "#0b0f14" }
        hl.NormalFloat = { fg = "#e6edf3", bg = "#111722" }

        -- ここで定義するのは言語非依存の標準ハイライトグループ。
        -- syntax / Tree-sitter / LSP がこれらへリンクすれば同じ配色が適用される。
        hl.Comment = { fg = "#7f8793", italic = false }
        hl.Keyword = { fg = "#c678dd" }
        hl.Function = { fg = "#61afef" }
        hl.Conditional = { fg = "#e5c07b" }
        hl.Repeat = { fg = "#d19a66" }
        hl.String = { fg = "#98c379" }
        hl.Boolean = { fg = "#56b6c2" }
        hl.Special = { fg = "#e5c07b" }
        hl.Operator = { fg = "#abb2bf" }
        hl.PreCondit = { fg = "#d19a66" }
        hl.Todo = { fg = "#0b0f14", bg = "#e5c07b", bold = true }
        hl.Define = { fg = "#56b6c2" }
        hl.Identifier = { fg = "#d0d7de" }
      end,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
    end,
  },
}
