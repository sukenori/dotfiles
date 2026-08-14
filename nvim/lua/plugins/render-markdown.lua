-- dotfiles/nvim/lua/plugins/render-markdown.lua
return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
  ft = { "markdown" },
  opts = {
    file_types = { "markdown" },
    latex = { enabled = true }, -- $ / $$ のLaTeX表現を扱う
    bullet = { enabled = true },
    heading = { enabled = true },
  },
}