-- [[ 基础按键映射 ]]
--  参见 `:help vim.keymap.set()`

-- 在普通模式下按 <Esc> 时清除搜索高亮
--  参见 `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- 全局 <C-s> 保存当前文件（普通 / 插入 / 可视 / 选择 模式都生效）
--  用 <cmd>write!<cr> 而不是 :w<CR>，好处是插入模式下保存后**不会退出插入态**，手不用挪。
--  ⚠ 为什么用 write!（强制写）：本机编辑的文件经常被外部进程改动（另一个编辑器/终端会话、
--     同步盘、grug-far 批量替换、shell 里的 sed -i 等）。这时普通 :w 会在写盘前比对时间戳、
--     弹 "W12: The file has been changed since reading it" 并要求 y/n 才能继续。
--     既然要保存的就是你自己的 buffer，就用 ! 跳过该检查、直接以 buffer 内容覆盖磁盘。
--     代价：若另一程序确实写入了不同内容，会被静默覆盖。想恢复「有冲突时先问一声」，
--     把下面的 write! 改回 write 即可。详见文件末尾「外部改动」一节。
--  ⚠ 坑：很多终端里 Ctrl+S 默认是 XOFF 流控（按下会"冻结"屏幕输出）。
--     Neovim 进 TUI 时会把终端设为原始模式、已禁用 IXON，所以能正常收到这个键；
--     万一你在某终端按 Ctrl+S 屏幕卡住不动、按 Ctrl+Q 才恢复，那是终端流控，不是这里的问题。
vim.keymap.set({ 'n', 'i', 'v', 's' }, '<C-s>', '<cmd>write!<cr>', { desc = '保存当前文件 [C-s]' })

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

-- [[ 外部改动处理：消除反复弹出的 W12 ]]
-- 背景：编辑期间若有外部进程改了磁盘上的文件，Neovim 有两道独立检查：
--   ① 察觉到改动时（:checktime / 切回终端焦点 / 跑完 shell 命令后）→ 触发 FileChangedShell，
--      默认会弹「file has changed, read again?」。**只要定义了 FileChangedShell 自动命令，
--      这条提示就不再弹出**，改由 v:fcs_choice 决定怎么办。
--   ② 保存时比对文件时间戳 → 弹 W12（就是截图那条），**只有 :write! 能跳过**，
--      所以上面的 <C-s> 用的是 write!。
-- 下面这套策略 = 尽早察觉 + 静默处理：
--   · 有未保存改动 → 保留 buffer（以你的编辑为准），保存时 <C-s> 强制写回；
--   · 没有本地改动 → 直接采纳磁盘上的新版本（autoread 下由 Neovim 自动完成）。
vim.o.autoread = true
vim.api.nvim_create_autocmd('FileChangedShell', {
  desc = '磁盘文件被外部改动时：有本地改动保留 buffer，无改动则重载',
  group = vim.api.nvim_create_augroup('kickstart-external-change', { clear = true }),
  pattern = '*',
  callback = function()
    -- 注意：此时当前 buffer 未必是被改的那个文件，要用 <abuf> 拿到目标 buffer
    local buf = tonumber(vim.fn.expand '<abuf>')
    if buf and vim.bo[buf].modified then
      vim.v.fcs_choice = '' -- 保留 buffer，不重载（你的编辑优先）
    else
      vim.v.fcs_choice = 'reload' -- 没有本地改动 → 采纳磁盘版本
    end
  end,
})
-- 在获得焦点 / 空闲时主动 checktime，好让上面的逻辑尽早介入
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI' }, {
  desc = '尽早察觉外部文件改动',
  group = 'kickstart-external-change',
  pattern = '*',
  command = "if mode() != 'c' | checktime | endif",
})

-- vim: ts=2 sts=2 sw=2 et
