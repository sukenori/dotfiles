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
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = { enabled = true, auto_trigger = true }, -- 入力中に自動で候補を表示する
        panel = { enabled = false },                          -- サイドパネルは使わない
      })
    end,
  },
  -- CopilotChat（Copilot とチャットで対話）
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "zbirenbaum/copilot.lua" },
      { "nvim-lua/plenary.nvim" },
    },
    opts = {
      system_prompt = "あなたは優秀なアシスタントです。簡潔に回答してください。マークダウンの強調記号やLaTeX表記は絶対に使用しないでください。",
      window = {
        layout = "vertical",  -- 縦分割（右側に表示される — splitright が有効のため）
        width = 0.3,           -- 画面幅の30%
      },
    },
  },
}
