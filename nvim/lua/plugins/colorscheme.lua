-- colorscheme.lua — VSCode に近い配色
return {
  {
    "Mofiqul/vscode.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("vscode").setup({
        italic_comments = false,
        transparent = false,
      })
      vim.cmd.colorscheme("vscode")
    end,
  },
}
