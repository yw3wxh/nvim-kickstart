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
    end, { desc = '下一个改动 [h]' })

    map('n', '[h', function()
      if vim.wo.diff then
        vim.cmd.normal { '[c', bang = true }
      else
        gitsigns.nav_hunk 'prev'
      end
    end, { desc = '上一个改动 [h]' })

    -- 操作
    -- 可视模式
    map('v', '<leader>ghs', function() gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = '暂存这个改动' })
    map('v', '<leader>ghr', function() gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = '撤销这个改动' })
    -- 普通模式
    map('n', '<leader>ghs', gitsigns.stage_hunk, { desc = '暂存这个改动' })
    map('n', '<leader>ghr', gitsigns.reset_hunk, { desc = '撤销这个改动' })
    map('n', '<leader>ghS', gitsigns.stage_buffer, { desc = '暂存整个文件' })
    map('n', '<leader>ghR', gitsigns.reset_buffer, { desc = '撤销整个文件的改动' })
    map('n', '<leader>ghp', gitsigns.preview_hunk, { desc = '预览这个改动' })
    map('n', '<leader>ghi', gitsigns.preview_hunk_inline, { desc = '在行内预览这个改动' })
    map('n', '<leader>ghb', function() gitsigns.blame_line { full = true } end, { desc = '看这行是谁改的（blame）' })
    map('n', '<leader>ghd', gitsigns.diffthis, { desc = '和暂存区对比' })
    map('n', '<leader>ghD', function() gitsigns.diffthis '@' end, { desc = '和上次提交对比' })
    map('n', '<leader>ghQ', function() gitsigns.setqflist 'all' end, { desc = '整个仓库的改动进快速修复列表' })
    map('n', '<leader>ghq', gitsigns.setqflist, { desc = '本文件的改动进快速修复列表' })
    -- 开关
    map('n', '<leader>ghtb', gitsigns.toggle_current_line_blame, { desc = '开关行尾显示 blame' })
    map('n', '<leader>ghtw', gitsigns.toggle_word_diff, { desc = '开关词级 diff' })

    -- 文本对象
    map({ 'o', 'x' }, 'ih', gitsigns.select_hunk, { desc = '选中当前改动（文本对象）' })
  end,
}

-- vim: ts=2 sts=2 sw=2 et
