-- dap.lua — DAP（デバッガをエディタで使えるようにするアダプタ）の共通設定

local function setup_dapui_lifecycle(dap, dapui)
  -- デバッグ開始時に UI を開く。変数・コールスタックを即確認できる
  dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open()
  end

  -- 正常終了・停止時はいずれも UI を閉じる
  dap.listeners.before.event_terminated["dapui_config"] = function()
    dapui.close()
  end
  dap.listeners.before.event_exited["dapui_config"] = function()
    dapui.close()
  end
end

local function setup_dap_virtual_text()
  local ok_vt, dap_virtual_text = pcall(require, "nvim-dap-virtual-text")
  if not ok_vt then
    return
  end

  -- 変数値を行末へ表示して、ステップ実行中の視線移動を減らす
  dap_virtual_text.setup({
    commented = true,
    virt_text_pos = "eol",
  })
end

local function setup_persistent_breakpoints()
  local ok_bp, persistent_breakpoints = pcall(require, "persistent-breakpoints")
  if not ok_bp then
    return false, nil
  end

  -- バッファ読み込み時に保存済みブレークポイントを復元する。
  persistent_breakpoints.setup({
    load_breakpoints_event = { "BufReadPost" },
  })

  return true, persistent_breakpoints
end

local function set_dap_keymaps(dap, dapui, has_persistent_breakpoints, persistent_breakpoints)
  -- Fキーは他言語にも共通で使えるデバッグ基本操作に固定する。
  vim.keymap.set("n", "<F5>", dap.continue, { silent = true, desc = "DAP: Continue/Start" })
  vim.keymap.set("n", "<F10>", dap.step_over, { silent = true, desc = "DAP: Step Over" })
  vim.keymap.set("n", "<F11>", dap.step_into, { silent = true, desc = "DAP: Step Into" })
  vim.keymap.set("n", "<F12>", dap.step_out, { silent = true, desc = "DAP: Step Out" })
  vim.keymap.set("n", "<Leader>db", dap.toggle_breakpoint, { silent = true, desc = "DAP: Toggle Breakpoint" })
  vim.keymap.set("n", "<Leader>dB", function()
    if has_persistent_breakpoints then
      persistent_breakpoints.clear_all_breakpoints()
    else
      dap.clear_breakpoints()
    end
  end, { silent = true, desc = "DAP: Clear All Breakpoints" })
  vim.keymap.set("n", "<Leader>dr", dap.repl.open, { silent = true, desc = "DAP: Open REPL" })
  vim.keymap.set("n", "<Leader>du", dapui.toggle, { silent = true, desc = "DAP-UI: Toggle" })
end

local function setup_codelldb_adapter(dap)
  -- codelldb は 多くの言語で共通利用できるため global 側で用意する
  dap.adapters.codelldb = {
    type = "server",
    port = "${port}",
    executable = {
      command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
      args = { "--port", "${port}" },
    },
  }
end

return {
  {
    "williamboman/mason.nvim",
    opts = {},
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = {
      "williamboman/mason.nvim",
      "mfussenegger/nvim-dap",
    },
    opts = {
      ensure_installed = { "codelldb" },
      automatic_installation = false,
    },
    config = function(_, opts)
      local ok_mason_dap, mason_dap = pcall(require, "mason-nvim-dap")
      if not ok_mason_dap then
        return
      end

      -- 再読込や複数起動時の setup 再入で "already installing" を起こさない。
      if vim.g.user_mason_nvim_dap_setup_done then
        return
      end
      vim.g.user_mason_nvim_dap_setup_done = true

      local ok_setup, err = pcall(mason_dap.setup, opts)
      if ok_setup then
        return
      end

      local msg = tostring(err)
      if msg:find("Package is already installing", 1, true) then
        vim.schedule(function()
          vim.notify("mason-nvim-dap: codelldb install is already running", vim.log.levels.INFO)
        end)
        return
      end

      error(err)
    end,
  },
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "jay-babu/mason-nvim-dap.nvim",
      "theHamsta/nvim-dap-virtual-text",
      "Weissle/persistent-breakpoints.nvim",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup({})

      setup_dapui_lifecycle(dap, dapui)
      setup_dap_virtual_text()
      local has_persistent_breakpoints, persistent_breakpoints = setup_persistent_breakpoints()
      setup_codelldb_adapter(dap)
      set_dap_keymaps(dap, dapui, has_persistent_breakpoints, persistent_breakpoints)
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
  },
}
