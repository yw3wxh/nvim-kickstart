local function gh(repo) return 'https://github.com/' .. repo end

-- [[ grug-far.nvim —— 整个项目的搜索与替换 ]]
--
-- 解决什么问题：
--   - `:s/a/b/g`  只能改**当前文件**
--   - telescope 的 grep 只能**看**不能改
--   - `:cdo` / `:cfdo`  能全局改，但要先想好命令，看不见改了什么、也没法挑着改
--
-- grug-far 的做法：开一个能编辑的 buffer，左边填"要找什么"、右边填"换成什么"，
-- 下面实时列出所有匹配，**你可以逐条删掉不想改的**，按 `:w` 才真正写入文件。
--
-- 纯 Lua。底层调用本机已有的 rg（ripgrep）。
-- ⚠ 它自己的界面是用 markdown 写的，所以**需要 markdown 解析器**
--   （已手动编译放好，见 kickstart/plugins/treesitter.lua 的说明）。
-- ---------------------------------------------------------------------------

vim.pack.add { gh 'MagicDuck/grug-far.nvim' }

require('grug-far').setup {
  -- 最多显示多少条匹配。再多就没意义了，而且会把搜索窗口卡住
  maxSearchMatches = 2000,

  -- 超过这个长度的匹配行会被截断显示，避免超长行拖慢 nvim
  maxLineLength = 1000,

  -- 只用 ripgrep 一种引擎。
  -- grug-far 还支持 ast-grep（按语法搜索），但那要额外装二进制，
  -- 这台机器能不装就不装，所以这里只留 ripgrep
  enabledEngines = { 'ripgrep' },
}

-- ---------------------------------------------------------------------------
-- 打开方式
-- ---------------------------------------------------------------------------
-- <leader>sR  打开一个空的搜索替换窗口（在当前工作目录里搜）
--
-- ⚠ 这里**故意不用** `<leader>/`：那个键是 kickstart 自带的 telescope
--   "在当前文件里模糊搜索"（见 kickstart/plugins/telescope.lua），
--   我一开始抢了它，实测下来 telescope 那个功能就失效了，所以让回去。
--   `<leader>s` 本来就是 telescope 的搜索前缀组（sf 找文件、sw 搜词、sg 搜 git…），
--   大写 R = Replace，正好和 `sw`（只搜不改）区分开。
vim.keymap.set('n', '<leader>sR', function() require('grug-far').open() end, { desc = '[S]earch & [R]eplace 全局搜索替换' })

-- <leader>*   直接以光标下的单词作为搜索词打开（比手打快）
-- 用法：把光标放在变量名上，按 <leader>*
vim.keymap.set(
  { 'n', 'v' },
  '<leader>*',
  function() require('grug-far').open { prefills = { search = vim.fn.expand '<cword>' } } end,
  { desc = '全局搜索光标下的词' }
)

-- ---------------------------------------------------------------------------
-- 窗口里怎么用
-- ---------------------------------------------------------------------------
--   Search:     填要找什么（支持正则）
--   Replace:    填换成什么（留空 = 只搜索不替换）
--   Files:      限定范围，比如 *.cpp 或者 src/（留空 = 全项目）
--   Flags:      额外参数，比如 -i 忽略大小写
--
--   填完之后按 :w 就执行替换（左下角会提示改了几个文件几处）
--
--   常用开关（在窗口里用 <localleader> 开头的键切换）：
--     \r  打开/关闭替换栏
--     \f  打开/关闭文件过滤栏
--     \x  打开/关闭 flags 栏
--     \s  切换搜索方式（这里只开了 ripgrep，所以基本用不到）
--
--   ⚠ <localleader> 我改成了反斜杠 `\`（见 lua/options.lua）。
--     原来它和 <leader> 一样是空格 —— 那样 `\f` 就会变成 `<空格>f`，
--     和格式化的 <leader>f 直接撞车，所以必须分开。
-- ---------------------------------------------------------------------------

-- vim: ts=2 sts=2 sw=2 et
