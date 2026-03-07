-- =========================================================================
-- 0. 基本設定（行番号・タブ幅など）
-- =========================================================================
vim.opt.number = true           -- 絶対行番号を表示
vim.opt.relativenumber = true   -- 相対行番号を表示（不要なら false に）
vim.opt.tabstop = 2             -- Tab文字の幅を2に設定
vim.opt.shiftwidth = 2          -- 自動インデントの幅を2に設定
vim.opt.expandtab = true        -- Tabをスペースに変換する
vim.opt.smartindent = true      -- 改行時に自動でインデントを下げる

-- =========================================================================
-- 1. lazy.nvim の自動インストールと読み込み
-- =========================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- =========================================================================
-- 2. 既存の設定（ターミナル操作やAtCoder用キーマップ）
-- =========================================================================
local term_buf = nil
local term_chan = nil

-- 下部に分割してターミナルを開く関数
local function init_terminal()
  vim.cmd('botright 15split | terminal')
  term_buf = vim.api.nvim_get_current_buf()
  term_chan = vim.b.terminal_job_id
  vim.cmd('setlocal nonumber norelativenumber signcolumn=no')
  vim.cmd('wincmd p') -- カーソルを上のコード画面に戻す
end

-- Neovim起動時に自動でターミナルを開く
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function() init_terminal() end
})

-- 下部ターミナルにコマンドを送り込む関数
local function run_in_term(cmd)
  vim.cmd('w') -- 実行前に必ず保存

  if not term_buf or not vim.api.nvim_buf_is_valid(term_buf) then
    init_terminal()
  else
    local win_found = false
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == term_buf then
        win_found = true
        break
      end
    end
    if not win_found then
      vim.cmd('botright 15split')
      vim.api.nvim_win_set_buf(0, term_buf)
      vim.cmd('wincmd p')
    end
  end

  vim.api.nvim_chan_send(term_chan, cmd .. "\n")
  vim.fn.win_execute(vim.fn.bufwinid(term_buf), 'normal! G')
end

-- AtCoder実行環境の設定
local env_dir = vim.fn.expand('~/atcoder-nim-env')

local function get_make_file()
  local abs_path = vim.fn.expand('%:p')
  return abs_path:sub(#env_dir + 2)
end

-- キーマップ
vim.keymap.set('n', '<Leader>c', function() run_in_term('make -C ' .. env_dir .. ' build FILE=' .. get_make_file()) end, { silent = true })
vim.keymap.set('n', '<Leader>s', function() run_in_term('make -C ' .. env_dir .. ' submit-auto FILE=' .. get_make_file()) end, { silent = true })
vim.keymap.set('n', '<Leader>u', function()
  local url = vim.fn.getreg('+'):gsub('%s+', '')
  run_in_term('make -C ' .. env_dir .. ' submit-url FILE=' .. get_make_file() .. ' URL=' .. url)
end, { silent = true })
vim.keymap.set('n', '<Leader>b', function()
  vim.cmd('w')
  vim.cmd('!make -C ' .. env_dir .. ' bundle FILE=' .. get_make_file())
  local target_file = env_dir .. '/bundled.txt'
  if vim.fn.filereadable(target_file) == 1 then
    local lines = vim.fn.readfile(target_file)
    vim.fn.setreg('+', table.concat(lines, '\n') .. '\n')
    print('バンドル結果をクリップボードにコピーしました')
  else
    print('エラー: ' .. target_file .. ' が見つかりません。')
  end
end, { silent = true })

-- =========================================================================
-- 3. プラグインの設定 (Copilot, Telescope, LSP, 補完)
-- =========================================================================
require("lazy").setup({
  -- Copilot本体とCopilotChat
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = { enabled = true, auto_trigger = true }, -- 補完を有効化
        panel = { enabled = false },
      })
    end,
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = { { "zbirenbaum/copilot.lua" }, { "nvim-lua/plenary.nvim" } },
    opts = {
      system_prompt = "あなたは優秀なアシスタントです。簡潔に回答してください。マークダウンの強調記号やLaTeX表記は絶対に使用しないでください。",
    },
  },

  -- Telescope
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.8',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' }
    },
    config = function()
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<Space>f', builtin.find_files, {})
      vim.keymap.set('n', '<Space>g', builtin.live_grep, {})
    end
  },

  -- LSP (nimlangserver) と 自動補完 (nvim-cmp)
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "hrsh7th/nvim-cmp",         -- 補完エンジン
      "hrsh7th/cmp-nvim-lsp",     -- LSPソース
      "L3MON4D3/LuaSnip",         -- スニペットエンジン
      "saadparwaiz1/cmp_luasnip", -- スニペットソース
    },

    config = function()
      -- 新しいLSP APIでの設定 (v0.11以降)
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      vim.lsp.config('nim_langserver', {
        -- cmdを「docker exec」に変更し、-i (インタラクティブ) オプションで標準入出力を繋ぐ
        -- ※ -t (tty) はLSPの通信プロトコルを壊すので絶対に入れないでください
        cmd = { "docker", "exec", "-i", "atcoder-nim", "nimlangserver" },
        filetypes = { "nim" },
        -- ワークスペースの判定基準
        root_markers = { "nim.cfg", ".git" },
        capabilities = capabilities,
      })
      vim.lsp.enable('nim_langserver')
      
      -- 補完ポップアップの設定
      local cmp = require('cmp')
      local luasnip = require('luasnip')
      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Enterで補完を確定
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' }, -- LSPからの候補
          { name = 'luasnip' },  -- スニペット
        })
      })
    end
  }
})

