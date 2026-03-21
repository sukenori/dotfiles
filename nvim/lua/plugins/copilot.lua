-- copilot.lua — GitHub Copilot（CopilotChat）の設定

return {
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
      model = "GPT-5.3-Codex",      -- 既定モデル。使えるモデルは :CopilotChatModels で切り替えられる
      temperature = 0.1,       -- 低めにして、コード寄りの安定した応答にする
      auto_insert_mode = true, -- 開いたらすぐ入力できるようにする
      window = {
        layout = "vertical",  -- 縦分割（右側に表示される — splitright が有効のため）
        width = 0.3,           -- 画面幅の30%
      },
    },
  },
}