-- multicursor.lua — VSCode 風の複数カーソル編集

return {
  "mg979/vim-visual-multi",
  init = function()
    -- Ctrl+D で現在語の次一致を選択する（VSCode ライク）。
    vim.g.VM_maps = {
      ["Find Under"] = "<C-d>",
    }
  end,
}
