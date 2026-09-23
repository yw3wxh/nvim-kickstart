local function gh(repo) return 'https://github.com/' .. repo end

-- [[ snacks.nvim —— folke 的工具箱 ]]
--
-- 这是 folke（noice / trouble / flash 的作者）写的一堆小工具合集，
-- 一个插件顶十几个。可以按模块单独开关，开哪个就用哪个，不开的完全不占资源。
--
-- ⚠ 重点：**它跟我们已经装的东西有几处重叠，所以下面有一半模块是刻意关掉的**。
--   别看 README 里功能多就全开，会打架。
--
-- 开着的（都在下面 enabled = true 那一段）：
--   dashboard   启动时的欢迎页（最近文件、快捷键速查）
--   indent      缩进参考线（Python 靠缩进，这个很实用）
--   terminal    更好用的终端窗口
--   scratch     随手记的临时草稿 buffer
--   zen / dim   专注模式（写东西时把无关内容压暗）
--   bigfile     打开大文件（日志、数据集）时自动降级，不卡死
--   quickfile   加快启动
--   gitbrowse   把当前行链接在浏览器里打开
--   bufdelete   删 buffer 时不搞乱窗口布局
--   profiler    排查"nvim 怎么变慢了"
--
-- 关掉的及原因：
--   notifier / notify ← 和已装的 **noice.nvim** 是同一件事，开了会弹两遍消息
--   explorer          ← 和已装的 **mini.files** 是同一件事（文件管理器）
--   picker            ← 和已装的 **telescope** 是同一件事（文件/内容查找）
--   debug             ← 调试交给 nvim-dap + nvim-dap-ui（见 custom/plugins/debug.lua）
--   image / lazygit / gh ← 需要额外的二进制工具，这台机器能不装就不装
--   words             ← 它的 `]]` `[[` 键位会被 treesitter-textobjects 抢走，用不了
--   scroll / statuscolumn / rename ← 和现有键位或 LSP 功能重叠，没必要
-- ---------------------------------------------------------------------------

vim.pack.add { gh 'folke/snacks.nvim' }

require('snacks').setup {
  -- ============ 开着的 ============

  -- 启动页：显示最近打开的文件和常用快捷键，空 buffer 时的默认界面
  dashboard = {
    enabled = true,
  },

  -- 缩进参考线：用竖线标出每一级缩进，Python 里特别好认
  indent = {
    enabled = true,
    -- 只在有缩进的行画（空行不画，省得花）
    animate = { enabled = false },
  },

  -- 终端：在 nvim 里开一个更好用的终端窗口
  terminal = {
    enabled = true,
    win = { position = 'bottom', height = 15 },
  },

  -- 草稿本：一个随手记东西、关掉就丢的临时 buffer
  scratch = {
    enabled = true,
    win = { position = 'float', width = 0.8, height = 0.8 },
  },

  -- 专注模式：把当前窗口放大居中、无关 UI 全藏起来
  zen = { enabled = true },

  -- 变暗：把光标附近以外的内容调暗，注意力更集中
  dim = { enabled = true },

  -- 大文件保护：打开超大文件时自动关掉 treesitter / 折叠这些重功能
  bigfile = { enabled = true, size = 1.5 * 1024 * 1024 }, -- 超过 1.5MB 就算大文件

  -- 启动加速：延后加载一部分东西，让 nvim 起得更快
  quickfile = { enabled = true },

  -- 在浏览器里打开当前文件当前行（需要有 git 仓库，且已配好 remote）
  gitbrowse = { enabled = true },

  -- 删 buffer 时保持窗口布局不乱（原生 :bd 会把窗口一起关掉）
  bufdelete = { enabled = true },

  -- 性能分析：`:lua Snacks.profiler.scratch()` 看哪段配置拖慢了启动
  profiler = { enabled = true },

  -- ============ 关掉的（别改，会跟别的插件打架）============
  notifier = { enabled = false }, -- 和 noice.nvim 冲突
  notify = { enabled = false }, -- 和 noice.nvim 冲突
  explorer = { enabled = false }, -- 和 mini.files 冲突
  picker = { enabled = false }, -- 和 telescope 冲突
  debug = { enabled = false }, -- 调试统一交给 nvim-dap
  image = { enabled = false }, -- 需要额外二进制
  lazygit = { enabled = false }, -- 需要 lazygit 二进制
  words = { enabled = false }, -- 键位会被 treesitter-textobjects 抢
  scroll = { enabled = false }, -- 和默认滚动行为不一致
  statuscolumn = { enabled = false },
}

-- ---------------------------------------------------------------------------
-- 键位
-- ---------------------------------------------------------------------------
-- 上面这些模块 snacks 不自动绑键（除了 dashboard 的界面快捷键），
-- 所以这里统一配一下，都归到 <leader>z 这一组下面，好记。

vim.keymap.set('n', '<leader>zz', function() Snacks.zen() end, { desc = '[Z]en 专注模式' })
vim.keymap.set('n', '<leader>zd', function() Snacks.dim.toggle() end, { desc = '[Z] 变暗（[D]im）' })
vim.keymap.set('n', '<leader>zs', function() Snacks.scratch() end, { desc = '[Z] 草稿本（[S]cratch）' })
vim.keymap.set('n', '<leader>zt', function() Snacks.terminal() end, { desc = '[Z] 终端（[T]erminal）' })
vim.keymap.set('n', '<leader>zp', function() Snacks.profiler.scratch() end, { desc = '[Z] 性能分析（[P]rofiler）' })

-- 在浏览器里打开当前行（需要有 git remote）
vim.keymap.set('n', '<leader>gb', function() Snacks.gitbrowse() end, { desc = '[G]it 浏览器打开（[B]rowse）' })
-- 复制当前行的链接但不开浏览器
vim.keymap.set({ 'n', 'v' }, '<leader>gB', function() Snacks.gitbrowse.open { what = 'file' } end, { desc = '[G]it 打开整个文件' })

-- 删 buffer（比 :bd 聪明，不会把窗口搞乱）
vim.keymap.set('n', '<leader>bd', function() Snacks.bufdelete() end, { desc = '[B]uffer [D]elete' })

-- ---------------------------------------------------------------------------
-- 用法备注
-- ---------------------------------------------------------------------------
--   <leader>zz  专注模式：再按一次退出。写代码或看长文件时很好用
--   <leader>zs  草稿本：随手记东西，`:w` 才真存盘，不存关掉就没了
--   <leader>zt  终端：底部开一个终端，再按一次收起
--   <leader>zp  性能分析：会打开一个界面列出每个模块耗时，
--               哪天觉得 nvim 变慢了就用它查
--   <leader>gb  需要有 git 仓库且配了 remote，否则会提示没有 URL
-- ---------------------------------------------------------------------------

-- vim: ts=2 sts=2 sw=2 et
