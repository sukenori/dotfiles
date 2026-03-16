-- ===========================================================================
-- copilot.lua — GitHub Copilot（AI コード補完 + チャット）の設定
--
-- InsertEnter（入力モードに入ったタイミング）で自動的に読み込まれ、
-- コードを書いているときに AI が候補を提案してくれる。
-- ===========================================================================
return {
  -- Copilot 本体（AI によるインライン補完）
  {
    "zbirenbaum/copilot.lua",
    cmd = {
      "Copilot",
      "CopilotSelectModel",
      "CopilotToggleCompletion",
      "CopilotToggleAutoTrigger",
    },
    keys = {
      {
        "<Leader>ae",
        function()
          vim.cmd("CopilotToggleCompletion")
        end,
        desc = "Copilot 補完を切替",
      },
      {
        "<Leader>ac",
        function()
          vim.cmd("CopilotSelectModel")
        end,
        desc = "Copilot 補完モデルを選択",
      },
      {
        "<Leader>at",
        function()
          vim.cmd("CopilotToggleAutoTrigger")
        end,
        desc = "Copilot 自動補完を切替",
      },
    },
    config = function()
      local command = require("copilot.command")
      local client = require("copilot.client")
      local suggestion = require("copilot.suggestion")
      local model = require("copilot.model")
      local api = require("copilot.api")

      local function toggle_completion()
        if client.is_disabled() then
          command.enable()
          vim.notify("Copilot 補完: ON")
        else
          suggestion.dismiss()
          command.disable()
          vim.notify("Copilot 補完: OFF")
        end
      end

      local function toggle_auto_trigger()
        suggestion.toggle_auto_trigger()
        vim.notify(
          "Copilot 自動補完(現在バッファ): "
            .. (vim.b.copilot_suggestion_auto_trigger and "ON" or "OFF")
        )
      end

      local function select_completion_model()
        local was_disabled = client.is_disabled()

        if was_disabled then
          command.enable()
        end

        client.ensure_client_started()
        if not vim.wait(3000, function()
          return client.get() ~= nil
        end, 50) then
          if was_disabled then
            command.disable()
          end
          vim.notify("Copilot の補完モデル一覧を取得できませんでした", vim.log.levels.ERROR)
          return
        end

        coroutine.wrap(function()
          local err, models = api.get_models(client.get())
          if err then
            if was_disabled then
              command.disable()
            end
            vim.notify("Copilot の補完モデル取得に失敗しました", vim.log.levels.ERROR)
            return
          end

          local completion_models = vim.tbl_filter(function(item)
            return vim.tbl_contains(item.scopes or {}, "completion")
          end, models or {})

          if #completion_models == 0 then
            if was_disabled then
              command.disable()
            end
            vim.notify("利用可能な Copilot 補完モデルがありません", vim.log.levels.WARN)
            return
          end

          table.sort(completion_models, function(left, right)
            if left.default and not right.default then
              return true
            end
            if right.default and not left.default then
              return false
            end
            return left.modelName < right.modelName
          end)

          local current_model = model.get_current_model()
          vim.ui.select(completion_models, {
            prompt = "Select Copilot completion model:",
            format_item = function(item)
              local display = item.modelName
              local tags = {}

              if item.default then
                table.insert(tags, "default")
              end
              if item.preview then
                table.insert(tags, "preview")
              end
              if #tags > 0 then
                display = display .. " (" .. table.concat(tags, ", ") .. ")"
              end
              if item.id == current_model then
                display = display .. " [current]"
              end

              return display
            end,
          }, function(selected)
            if selected then
              model.set({ model = selected.id })
            end

            if was_disabled then
              suggestion.dismiss()
              command.disable()
            end
          end)
        end)()
      end

      require("copilot").setup({
        suggestion = { enabled = true, auto_trigger = true }, -- 入力中に自動で候補を表示する
        panel = { enabled = false },                          -- サイドパネルは使わない
      })

      -- 補完は明示的に有効化するまで OFF にしておく
      command.disable()

      vim.api.nvim_create_user_command("CopilotSelectModel", select_completion_model, {
        desc = "Copilot の補完モデルを選択する",
      })

      vim.api.nvim_create_user_command("CopilotToggleCompletion", toggle_completion, {
        desc = "Copilot 補完の有効/無効を切り替える",
      })

      vim.api.nvim_create_user_command("CopilotToggleAutoTrigger", toggle_auto_trigger, {
        desc = "Copilot 自動補完のトリガーを切り替える",
      })
    end,
  },
  -- CopilotChat（Copilot とチャットで対話）
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    cmd = {
      "CopilotChat",
      "CopilotChatOpen",
      "CopilotChatClose",
      "CopilotChatToggle",
      "CopilotChatReset",
      "CopilotChatModels",
    },
    keys = {
      { "<Leader>ao", "<Cmd>CopilotChatOpen<CR>", desc = "CopilotChat を開く" },
      { "<Leader>aa", "<Cmd>CopilotChatToggle<CR>", desc = "CopilotChat を開閉" },
      { "<Leader>ax", "<Cmd>CopilotChatClose<CR>", desc = "CopilotChat を閉じる" },
      { "<Leader>am", "<Cmd>CopilotChatModels<CR>", desc = "CopilotChat のモデル選択" },
    },
    dependencies = {
      { "zbirenbaum/copilot.lua" },
      { "nvim-lua/plenary.nvim" },
    },
    opts = {
      system_prompt = "あなたは競技プログラミングのコーチ兼システム構築アシスタントです。簡潔に回答してください。マークダウンの強調記号やLaTeX表記は絶対に使用しないでください。",
      model = "gpt-4.1",      -- 既定モデル。使えるモデルは :CopilotChatModels で切り替えられる
      temperature = 0.1,       -- 低めにして、コード寄りの安定した応答にする
      auto_insert_mode = true, -- 開いたらすぐ入力できるようにする
      window = {
        layout = "vertical",  -- 縦分割（右側に表示される — splitright が有効のため）
        width = 0.3,           -- 画面幅の30%
      },
    },
  },
}