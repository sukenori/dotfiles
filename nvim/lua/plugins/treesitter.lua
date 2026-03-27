-- treesitter.lua — Tree-sitter の共通設定（LSP/formatter と併用）

return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      local ts = require("nvim-treesitter.configs")

      ts.setup({
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
