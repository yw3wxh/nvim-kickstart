-- [[ 基础按键映射 ]]
--  参见 `:help vim.keymap.set()`

-- 在普通模式下按 <Esc> 时清除搜索高亮
--  参见 `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- 诊断配置与按键映射
--  参见 `:help vim.diagnostic.Opts`
vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },

  -- 你可以根据自己的偏好切换以下选项
  virtual_text = true, -- 文本显示在行末
  virtual_lines = false, -- 文本显示在行下方（使用虚拟行）

  -- 自动打开浮动窗口，方便使用 `[d` 和 `]d` 跳转时阅读错误
  jump = {
    on_jump = function(_, bufnr)
      vim.diagnostic.open_float {
        bufnr = bufnr,
        scope = 'cursor',
        focus = false,
      }
    end,
  },
}

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- 用一个更容易被发现的快捷键来退出内置终端模式。
-- 否则，你通常需要按 <C-\><C-n>，
-- 这在没有一定经验的情况下不太容易猜到。
--
-- 注意：这在所有终端模拟器/tmux 等中可能不生效。请尝试自己的映射，
-- 或者直接使用 <C-\><C-n> 退出终端模式
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- 提示：在普通模式下禁用方向键
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- 让分屏导航更方便的按键绑定。
--  使用 CTRL+<hjkl> 在窗口之间切换
--
--  参见 `:help wincmd` 获取所有窗口命令的列表
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- 注意：某些终端存在按键冲突，或无法发送不同的按键码
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

-- [[ 基础自动命令 ]]
--  参见 `:help lua-guide-autocommands`

-- 复制（yank）文本时高亮
--  在普通模式下试试 `yap`
--  参见 `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

-- vim: ts=2 sts=2 sw=2 et
