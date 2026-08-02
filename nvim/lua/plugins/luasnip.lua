-- nvim/lua/plugins/luasnip.lua
-- LuaSnip本体の設定。cmp.lua の dependencies から参照される
-- "L3MON4D3/LuaSnip" スペックと lazy.nvim 側で自動的にマージされる。

local M = {
  "L3MON4D3/LuaSnip",
  config = function()
    -- 特に何もしない（プロジェクト側から load() を都度呼ぶ運用）
  end,
}

-- paths.lua    : LuaSnip Lua形式スニペットのディレクトリ（複数可）
-- paths.vscode : VS Code形式(*.code-snippets)スニペットのディレクトリ（複数可）
-- どんな構造にするか（lua/とvscode/を分けるかどうか等）はここでは決めない。
-- 呼び出し側（各プロジェクトの .nvim.lua）が、渡すパスで構造を決める。
function M.load(paths)
  paths = paths or {}

  if paths.lua then
    local ok, loader = pcall(require, "luasnip.loaders.from_lua")
    if ok then
      for _, dir in ipairs(paths.lua) do
        if vim.fn.isdirectory(dir) == 1 then
          loader.load({ paths = { dir } })
        end
      end
    end
  end

  if paths.vscode then
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