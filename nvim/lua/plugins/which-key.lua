-- which-key.lua — キー操作の候補をポップアップ表示する

return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      -- 既存の keymap desc をそのまま表示し、不足分だけ補助する
      -- notify = false で未登録キー時の通知を減らし、ノイズを抑える
      notify = false,

      -- Leader 押下後の表示を少し待ってから出す（誤爆を減らす）
      delay = function(ctx)
        if ctx.plugin then
          return 0
        end
        return 200
      end,

      -- 画面下のコマンドラインを隠しすぎないよう最小限表示にする
      preset = "classic",
      win = {
        border = "rounded",
      },
    },
  },
}