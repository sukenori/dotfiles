-- treesitter.lua — Tree-sitter の共通設定（LSP/formatter と併用）

return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      -- nvim-treesitter の API 変更に備えて、旧/新の setup 入口を両対応にする。
      local ts_setup
      do
        local ok_configs, configs = pcall(require, "nvim-treesitter.configs")
        if ok_configs and type(configs.setup) == "function" then
          ts_setup = configs.setup
        else
          local ok_main, main = pcall(require, "nvim-treesitter")
          if ok_main and type(main.setup) == "function" then
            ts_setup = main.setup
          end
        end
      end

      if type(ts_setup) ~= "function" then
        vim.schedule(function()
          vim.notify("nvim-treesitter の setup 関数を読み込めませんでした", vim.log.levels.ERROR)
        end)
        return
      end

      ts_setup({
        -- 汎用言語 + Nim を導入。必要なものは :TSInstall で追加可能。
        ensure_installed = {
          "bash",
          "lua",
          "markdown",
          "markdown_inline",
          "nim",
          "query",
          "vim",
          "vimdoc",
        },
        auto_install = true,

        highlight = {
          enable = true,
          -- LSP semantic token と競合させず、Tree-sitter は土台の色付けを担当する。
          additional_vim_regex_highlighting = false,
        },

        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "gnn",
            node_incremental = "grn",
            scope_incremental = "grc",
            node_decremental = "grm",
          },
        },

        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",
              ["as"] = "@statement.outer",
              ["is"] = "@statement.inner",
            },
          },
          swap = {
            enable = true,
            swap_next = {
              ["]a"] = "@parameter.inner",
            },
            swap_previous = {
              ["[a"] = "@parameter.inner",
            },
          },
          move = {
            enable = true,
            set_jumps = true,
            goto_next_start = {
              ["]f"] = "@function.outer",
              ["]c"] = "@class.outer",
            },
            goto_previous_start = {
              ["[f"] = "@function.outer",
              ["[c"] = "@class.outer",
            },
          },
        },
      })
    end,
  },
}
