-- colorscheme.lua — コード可読性のため、落ち着いた配色テーマを有効化する
return {
  {
    "Mofiqul/vscode.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("vscode").setup({
        style = "dark",
        transparent = false,
        italic_comments = false,
        color_overrides = {
          vscLineNumber = "#667081",
          vscSelection = "#264f78",
        },
        group_overrides = {
          Normal = { fg = "#e6edf3" },
          Comment = { fg = "#7f8793", italic = false },
          Keyword = { fg = "#c678dd" },
          Statement = { fg = "#c678dd" },
          Function = { fg = "#61afef" },
          Identifier = { fg = "#d0d7de" },
          Type = { fg = "#56b6c2" },
          String = { fg = "#98c379" },
          Number = { fg = "#d19a66" },
          Boolean = { fg = "#d19a66" },
          Special = { fg = "#e5c07b" },
          Constant = { fg = "#e5c07b" },
        },
      })
      vim.cmd.colorscheme("vscode")
    end,
  },
}
