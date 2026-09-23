local function gh(repo) return 'https://github.com/' .. repo end

-- [[ flash.nvim —— 屏幕内任意位置快速跳转 ]]
--
-- 解决什么问题：想在屏幕上某个位置编辑时，原来只有三种办法 ——
--   1) 用 h/j/k/l 一路挪过去（慢）
--   2) 用 / 搜索再按 n（要输完整词，还容易跳过头）
--   3) 用鼠标（手要离开键盘）
-- flash 的做法：按一下键，屏幕上的候选位置直接**标上字母**，敲那个字母就跳过去了。
--
-- 和 noice.nvim / trouble.nvim 同一个作者（folke），风格统一。纯 Lua，无二进制依赖。
--
-- ⚠ 重要：flash 默认会占用 `s` 键，这和 mini.surround 的 `sa`（加括号）、
--   `sd`（删括号）、`sr`（换括号）冲突 —— 按 `s` 会被 flash 抢走，surround 就用不了了。
--   解决办法是把 mini.surround 的前缀整体改到了 `gs`
--   （见 lua/kickstart/plugins/mini.lua：sa→gsa、sd→gsd、sr→gsr）。
--   如果你更习惯原来的 `sa`，想要把 `s` 还给 surround，见本文件末尾的说明。
-- ---------------------------------------------------------------------------

vim.pack.add { gh 'folke/flash.nvim' }

require('flash').setup {
  -- 候选位置用哪些字符做标签。
  -- 默认已排除 f/F/t/T/;/',' 这些 vim 原生按键，不会打架
  labels = 'asdfghjklqwertyuiopzxcvbnm',

  jump = {
    -- 只有一个匹配时就直接跳过去，不用再敲标签（省一步）
    autojump = true,
    -- 跳转前把当前位置记进 jumplist，之后可以用 Ctrl-O 跳回原处
    history = true,
    -- 跳转后把光标挪到屏幕中间，避免跳到边缘看不清上下文
    offset = nil,
    -- 搜索串只输了一半时是否就实时跳转（关掉，避免误跳）
    autojump_on_partial = false,
  },

  -- 搜索时把屏幕其余部分变暗，让高亮的候选位置更醒目
  highlight = {
    backdrop = true,
    -- 所有匹配项都高亮（不只是打了标签的那些）
    matches = true,
  },

  -- 标签怎么画（注意：这一项在新版里是**顶层**的 label，不是 highlight.label）：
  --   style = 'overlay' → 标签字符盖在原文字上，不挤占版面
  --   before = true     → 标签画在匹配字符的前面
  label = { style = 'overlay', after = false, before = true },

  modes = {
    -- char 模式：给原生的 f/t 也加上标签功能，
    -- 比如 `fa` 之后屏幕上所有 a 都标上字母，再敲一下就能跳到第 N 个 a
    char = {
      enabled = true,
      jump_labels = true,
    },

    -- treesitter 模式（S 键）：按语法单元选，一步选中整个函数 / 整个字符串 / 整个参数。
    -- 比 `v` 之后手动扩选准得多，写 C++ / Python 时很好用
    treesitter = {
      labels = 'abcdefghijklmnopqrstuvwxyz',
    },

    -- search 模式：用 / 搜索时也给匹配项标上标签，
    -- 不用再反复按 n 找第几个
    search = {
      enabled = true,
    },
  },
}

-- ---------------------------------------------------------------------------
-- 按键映射
--
-- ⚠ 注意：新版 flash **不会再自动帮你设键位**，必须自己写下面这几行，
--   否则装完跟没装一样（我实测过：不写的话 s / S / r / R 一个都没绑上）。
--
-- ⚠ 还有个坑：这里必须用 **Lua 函数**（或 `<cmd>lua ...<cr>`）作为 rhs，
--   **不能**写成 `:lua require('flash').jump()<cr>` ——
--   用 `:lua` 会让 `.`（dot-repeat，重复上一次操作）失效。
-- ---------------------------------------------------------------------------

-- s：搜索 + 标签跳转，本插件的核心用法
vim.keymap.set({ 'n', 'x', 'o' }, 's', function() require('flash').jump() end, { desc = '[S] 跳转' })

-- S：一步选中光标处的语法单元（整个函数体 / 整个字符串 / 整个参数）
vim.keymap.set({ 'n', 'x', 'o' }, 'S', function() require('flash').treesitter() end, { desc = '选中语法单元' })

-- r：只在"待操作模式"（敲了 d / y / c 之后）生效 —— 远程操作。
--    例：`dr` 再选一个词，就能删掉屏幕远处那个词，光标不用先挪过去
vim.keymap.set('o', 'r', function() require('flash').remote() end, { desc = '远程操作' })

-- R：待操作/可视模式下，按语法单元远程选中
vim.keymap.set({ 'o', 'x' }, 'R', function() require('flash').treesitter_search() end, { desc = '远程选中语法单元' })

-- 命令行模式（输入 : 或 / 之后）里也用 flash 给匹配项打标签。
-- ⚠ 这一行**故意注释掉**：很多终端把 Ctrl-S 当成"冻结屏幕"（XOFF），
--   按下去整个终端会卡住不动（得按 Ctrl-Q 才能解）。
--   如果你的终端没这个问题，把下面两行的注释去掉即可：
-- vim.keymap.set('c', '<c-s>', function() require('flash').toggle() end, { desc = '切换 flash 搜索' })

-- ---------------------------------------------------------------------------
-- 想把 `s` 还给 vim 原生（或让给 mini.surround）？
-- 把下面两行的注释去掉，并把上面 `s` 那一行删掉：
--   vim.keymap.set({ 'n', 'x', 'o' }, '<leader>j', function() require('flash').jump() end, { desc = '[J]ump 跳转' })
-- 同时记得把 mini.surround 的前缀改回默认的 sa / sd / sr。
-- ---------------------------------------------------------------------------

-- vim: ts=2 sts=2 sw=2 et
