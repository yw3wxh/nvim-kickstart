local function gh(repo) return 'https://github.com/' .. repo end

-- [[ nvim-treesitter-textobjects —— 按语法单元来操作代码 ]]
--
-- 解决什么问题：vim 原生的文本对象只有"单词""句子""段落""括号"这几种，
-- 它**不懂代码结构**。想选中一个函数体，只能手动数括号。
--
-- 装上之后就多了这些：
--   af / if   整个函数 / 函数体内部     →  `vaf` 选整个函数，`dif` 删掉函数体
--   ac / ic   整个类 / 类内部
--   aP / iP   一个参数 / 参数内部       →  `daP` 删掉一个参数（写 C++ 很常用）
--
-- 以及按语法单元跳转：
--   ]m / [m   跳到下一个 / 上一个函数
--   ]C / [C   跳到下一个 / 上一个类
--
-- 依赖已装的 nvim-treesitter，本身是纯 Lua，无二进制。
--
-- ⚠ 重要（踩过的坑）：**新版这个插件不再自己绑定按键了**。
--   只调 setup() 的话，装完一个键都绑不上（我实测：af/if/ac/ic 全是"未绑定"）。
--   它现在只提供函数，按键必须自己用 vim.keymap.set 绑 —— 就是下面这一大段。
-- ---------------------------------------------------------------------------

vim.pack.add { gh 'nvim-treesitter/nvim-treesitter-textobjects' }

-- setup 只是把配置写进去；按键还得自己绑，见下面
require('nvim-treesitter-textobjects').setup {
  select = { lookahead = true }, -- 当前位置没目标时往后找一个
  move = { set_jumps = true }, -- 跳转前记进 jumplist，能用 Ctrl-O 跳回来
}

local ts_select = require 'nvim-treesitter-textobjects.select'
local ts_move = require 'nvim-treesitter-textobjects.move'
local ts_swap = require 'nvim-treesitter-textobjects.swap'

-- 第二个参数 "textobjects" 指的是去 queries/<语言>/textobjects.scm 里找规则。
-- 用 pcall 包起来：万一这个语言没装解析器，按下去也只是没反应，
-- 不会弹一堆红色报错。
---@param query string
local function select_textobject(query)
  return function() pcall(ts_select.select_textobject, query, 'textobjects') end
end

---@param query string
local function goto_next(query)
  return function() pcall(ts_move.goto_next_start, query, 'textobjects') end
end

---@param query string
local function goto_prev(query)
  return function() pcall(ts_move.goto_previous_start, query, 'textobjects') end
end

-- ---------------------------------------------------------------------------
-- 选中（在 visual 模式，或者 d / c / y 之后用）
--
-- 模式说明：
--   x = visual 模式（先按 v 再按 af）
--   o = operator-pending 模式（先按 d / c / y 再按 af）
-- ---------------------------------------------------------------------------
vim.keymap.set({ 'x', 'o' }, 'af', select_textobject '@function.outer', { desc = '整个函数（含签名）' })
vim.keymap.set({ 'x', 'o' }, 'if', select_textobject '@function.inner', { desc = '函数体内部' })
vim.keymap.set({ 'x', 'o' }, 'ac', select_textobject '@class.outer', { desc = '整个类 / 结构体' })
vim.keymap.set({ 'x', 'o' }, 'ic', select_textobject '@class.inner', { desc = '类 / 结构体内部' })

-- 参数：这里刻意用 `aP` / `iP`，不用插件默认的 `aa` / `ia`，原因有两个：
--   1) `aa` 已经被 mini.ai 占用（见 kickstart/plugins/mini.lua 的 around_next = 'aa'）
--   2) `ap` / `ip` 是 vim 原生的"段落"，绝对不能抢
-- 换成大写 P 就都不冲突了。
vim.keymap.set({ 'x', 'o' }, 'aP', select_textobject '@parameter.outer', { desc = '一个函数参数' })
vim.keymap.set({ 'x', 'o' }, 'iP', select_textobject '@parameter.inner', { desc = '函数参数内部' })

-- ---------------------------------------------------------------------------
-- 跳转
-- ---------------------------------------------------------------------------
vim.keymap.set({ 'n', 'x', 'o' }, ']m', goto_next '@function.outer', { desc = '下一个函数开头' })
vim.keymap.set({ 'n', 'x', 'o' }, '[m', goto_prev '@function.outer', { desc = '上一个函数开头' })

-- ⚠ 类的跳转这里**故意不用** `]]` / `[[`（虽然插件官方示例就是这两个）。
--   原因：nvim 0.12 自带了一组全局映射，`]]` / `[[` 已经被占去做
--   "Jump to next/previous section"（启动时后设置的，会把我设的覆盖掉）。
--   我实测过：设了 `]]` 之后按下去，走的仍然是 nvim 自带的跳转，类跳转根本不生效。
--   所以换大写 `C`（Class）：既避开冲突，又能和上面的 `m`（函数）成对记。
vim.keymap.set({ 'n', 'x', 'o' }, ']C', goto_next '@class.outer', { desc = '下一个类开头' })
vim.keymap.set({ 'n', 'x', 'o' }, '[C', goto_prev '@class.outer', { desc = '上一个类开头' })

-- ---------------------------------------------------------------------------
-- 交换：把当前参数跟前一个 / 后一个对调，改函数签名顺序时不用删了重敲
-- ---------------------------------------------------------------------------
vim.keymap.set('n', '<leader>a', function() pcall(ts_swap.swap_next, '@parameter.inner') end, { desc = '参数往后挪一位' })

vim.keymap.set('n', '<leader>A', function() pcall(ts_swap.swap_previous, '@parameter.inner') end, { desc = '参数往前挪一位' })

-- ---------------------------------------------------------------------------
-- 使用示例（以 C++ 为例）
-- ---------------------------------------------------------------------------
--   vaf         选中整个函数（含 int foo(int a, int b) { ... }）
--   dif         删掉函数体里的所有内容，留下 {} 空壳
--   vac         选中整个 class / struct
--   daP         删掉光标所在的那个参数
--   <leader>a   把当前参数往后挪一位
--   ]m          跳到下一个函数开头
--   ]C          跳到下一个类开头
-- ---------------------------------------------------------------------------

-- vim: ts=2 sts=2 sw=2 et
