-- luasnip.lua — cmp.lua の dependencies から参照される LuaSnip の本体設定

local M = {
  "L3MON4D3/LuaSnip",
  config = function()
  -- プロジェクト側から load() を都度呼ぶ運用にて、特に何もしない
  end,
}

-- 呼び出し側の各プロジェクトの .nvim.lua でパスを渡す
function M.load(paths)
  paths = paths or {}

  if paths.lua then -- paths.lua： Lua形式スニペットのディレクトリ（複数可）
    local ok, loader = pcall(require, "luasnip.loaders.from_lua")
    if ok then
      for _, dir in ipairs(paths.lua) do
        if vim.fn.isdirectory(dir) == 1 then
          loader.load({ paths = { dir } })
        end
      end
    end
  end

  if paths.vscode then-- paths.vscode： VS Code形式スニペットのディレクトリ（複数可）
    local ok, loader = pcall(require, "luasnip.loaders.from_vscode")
    if ok then
      for _, dir in ipairs(paths.vscode) do
        if vim.fn.isdirectory(dir) == 1 then
          loader.lazy_load({ paths = { dir } })
        end
      end
    end
  end
end

return M