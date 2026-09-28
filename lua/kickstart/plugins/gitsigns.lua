local function gh(repo) return 'https://github.com/' .. repo end

-- [[ gitsigns.nvim —— 行号栏显示 git 改动 + 便捷操作 ]]
--
-- 在 gutter（行号旁）用符号标出每行的增/改/删，并提供一套 hunk 操作键。
--
-- ⚠ 键位已按 LazyVim 重排（原来那套 <leader>h* / ]c / [c 已废弃）：
--     ]c / [c（hunk 导航）      → ]h / [h
--     <leader>hs（暂存 hunk）   → <leader>ghs
--     <leader>hr（回退 hunk）   → <leader>ghr
--     <leader>hS / hR（整个文件）→ <leader>ghS / <leader>ghR
--     <leader>hp / hi（预览）   → <leader>ghp / <leader>ghi
--     <leader>hb（blame）       → <leader>ghb
--     <leader>hd / hD（diff）   → <leader>ghd / <leader>ghD
--     <leader>hq / hQ（quickfix）→ <leader>ghq / <leader>ghQ
--     <leader>tb / tw（开关）   → <leader>ghtb / <leader>ghtw
--   文本对象 ih（选一个 hunk）不变。
vim.pack.add { gh 'lewis6991/gitsigns.nvim' }
require('gitsigns').setup {
  signs = {
    add = { text = '+' }, ---@diagnostic disable-line: missing-fields
    change = { text = '~' }, ---@diagnostic disable-line: missing-fields
    delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
    topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
    changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
  },
  on_attach = function(bufnr)
    local gitsigns = require 'gitsigns'

    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    -- 导航
    map('n', ']h', function()
      if vim.wo.diff then
        vim.cmd.normal { ']c', bang = true }
      else
        gitsigns.nav_hunk 'next'
      end
    end, { desc = 'Jump to next git [c]hange' })

    map('n', '[h', function()
      if vim.wo.diff then
        vim.cmd.normal { '[c', bang = true }
      else
        gitsigns.nav_hunk 'prev'
      end
    end, { desc = 'Jump to previous git [c]hange' })

    -- 操作
    -- 可视模式
    map('v', '<leader>ghs', function() gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git [s]tage hunk' })
    map('v', '<leader>ghr', function() gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git [r]eset hunk' })
    -- 普通模式
    map('n', '<leader>ghs', gitsigns.stage_hunk, { desc = 'git [s]tage hunk' })
    map('n', '<leader>ghr', gitsigns.reset_hunk, { desc = 'git [r]eset hunk' })
    map('n', '<leader>ghS', gitsigns.stage_buffer, { desc = 'git [S]tage buffer' })
    map('n', '<leader>ghR', gitsigns.reset_buffer, { desc = 'git [R]eset buffer' })
    map('n', '<leader>ghp', gitsigns.preview_hunk, { desc = 'git [p]review hunk' })
    map('n', '<leader>ghi', gitsigns.preview_hunk_inline, { desc = 'git preview hunk [i]nline' })
    map('n', '<leader>ghb', function() gitsigns.blame_line { full = true } end, { desc = 'git [b]lame line' })
    map('n', '<leader>ghd', gitsigns.diffthis, { desc = 'git [d]iff against index' })
    map('n', '<leader>ghD', function() gitsigns.diffthis '@' end, { desc = 'git [D]iff against last commit' })
    map('n', '<leader>ghQ', function() gitsigns.setqflist 'all' end, { desc = 'git hunk [Q]uickfix list (all files in repo)' })
    map('n', '<leader>ghq', gitsigns.setqflist, { desc = 'git hunk [q]uickfix list (all changes in this file)' })
    -- 开关
    map('n', '<leader>ghtb', gitsigns.toggle_current_line_blame, { desc = '[T]oggle git show [b]lame line' })
    map('n', '<leader>ghtw', gitsigns.toggle_word_diff, { desc = '[T]oggle git intra-line [w]ord diff' })

    -- 文本对象
    map({ 'o', 'x' }, 'ih', gitsigns.select_hunk)
  end,
}

-- vim: ts=2 sts=2 sw=2 et
