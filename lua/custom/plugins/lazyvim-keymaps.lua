-- [[ 对齐 LazyVim 的通用键位 ]]
--
-- 老吴以前用 LazyVim，这里把 LazyVim `lua/lazyvim/config/keymaps.lua` 里的
-- **通用键**照搬过来（官方表：https://www.lazyvim.org/keymaps）。
-- 凡是有插件差异的地方都用本机已有的插件实现，注释里标了「本机换算」。
--
-- 只放"和具体插件无关"的键；telescope / gitsigns / dap / trouble 各自的键
-- 还留在各自的文件里，那里也按 LazyVim 改过了。
--
-- ⚠ 一个顺手修掉的 bug：snacks 的 `Snacks.toggle.xxx()` **只是创建 toggle 对象**，
--   真正切换要调用 `toggle:toggle()`（源码 snacks/toggle.lua:97）。
--   以前在 snacks.lua 里写成 `function() Snacks.toggle.diagnostics() end` —— 只创建、
--   不切换，按了没反应。这里统一用 snacks 自带的 `:map()`（它内部就是 toggle，
--   还会自动往 which-key 里登记带状态图标的说明）。

local map = vim.keymap.set

-- ---------------------------------------------------------------------------
-- 移动
-- ---------------------------------------------------------------------------
-- 长行被 wrap 成多行时，j/k 按"屏幕行"走而不是"物理行"
map({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { desc = '下（按屏幕行）', expr = true, silent = true })
map({ 'n', 'x' }, '<Down>', "v:count == 0 ? 'gj' : 'j'", { desc = '下（按屏幕行）', expr = true, silent = true })
map({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { desc = '上（按屏幕行）', expr = true, silent = true })
map({ 'n', 'x' }, '<Up>', "v:count == 0 ? 'gk' : 'k'", { desc = '上（按屏幕行）', expr = true, silent = true })

-- Alt+j / Alt+k 上下搬动当前行（带 count 可以一次搬多行），搬完自动重缩进
map('n', '<A-j>', "<cmd>execute 'move .+' . v:count1<cr>==", { desc = '本行下移' })
map('n', '<A-k>', "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = '本行上移' })
map('i', '<A-j>', '<esc><cmd>m .+1<cr>==gi', { desc = '本行下移' })
map('i', '<A-k>', '<esc><cmd>m .-2<cr>==gi', { desc = '本行上移' })
map('v', '<A-j>', ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = '选中行下移' })
map('v', '<A-k>', ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = '选中行上移' })

-- 搜索时 n/N 永远朝同一个方向（n 向下、N 向上），并展开折叠
map('n', 'n', "'Nn'[v:searchforward].'zv'", { expr = true, desc = '下一个搜索结果' })
map('x', 'n', "'Nn'[v:searchforward]", { expr = true, desc = '下一个搜索结果' })
map('o', 'n', "'Nn'[v:searchforward]", { expr = true, desc = '下一个搜索结果' })
map('n', 'N', "'nN'[v:searchforward].'zv'", { expr = true, desc = '上一个搜索结果' })
map('x', 'N', "'nN'[v:searchforward]", { expr = true, desc = '上一个搜索结果' })
map('o', 'N', "'nN'[v:searchforward]", { expr = true, desc = '上一个搜索结果' })

-- ---------------------------------------------------------------------------
-- 窗口
-- ---------------------------------------------------------------------------
map('n', '<C-Up>', '<cmd>resize +2<cr>', { desc = '窗口增高' })
map('n', '<C-Down>', '<cmd>resize -2<cr>', { desc = '窗口变矮' })
map('n', '<C-Left>', '<cmd>vertical resize -2<cr>', { desc = '窗口变窄' })
map('n', '<C-Right>', '<cmd>vertical resize +2<cr>', { desc = '窗口变宽' })

map('n', '<leader>-', '<C-W>s', { desc = '上下分屏', remap = true })
map('n', '<leader>|', '<C-W>v', { desc = '左右分屏', remap = true })
map('n', '<leader>wd', '<C-W>c', { desc = '关闭当前窗口', remap = true })

-- ---------------------------------------------------------------------------
-- Buffer
-- ---------------------------------------------------------------------------
map('n', '[b', '<cmd>bprevious<cr>', { desc = '上一个 buffer' })
map('n', ']b', '<cmd>bnext<cr>', { desc = '下一个 buffer' })
map('n', '<leader>bo', function() require('snacks').bufdelete.other() end, { desc = '关闭其它 buffer' })
map('n', '<leader>bi', function() require('snacks').bufdelete.invisible() end, { desc = '关闭不可见 buffer' })
map('n', '<leader>bD', '<cmd>:bd<cr>', { desc = '关闭 buffer 和窗口' })

-- ---------------------------------------------------------------------------
-- Tab（LazyVim 的 <leader><tab> 组）
-- ---------------------------------------------------------------------------
map('n', '<leader><tab>l', '<cmd>tablast<cr>', { desc = '最后一个标签页' })
map('n', '<leader><tab>o', '<cmd>tabonly<cr>', { desc = '只留当前标签页' })
map('n', '<leader><tab>f', '<cmd>tabfirst<cr>', { desc = '第一个标签页' })
map('n', '<leader><tab><tab>', '<cmd>tabnew<cr>', { desc = '新建标签页' })
map('n', '<leader><tab>]', '<cmd>tabnext<cr>', { desc = '下一个标签页' })
map('n', '<leader><tab>d', '<cmd>tabclose<cr>', { desc = '关闭标签页' })
map('n', '<leader><tab>[', '<cmd>tabprevious<cr>', { desc = '上一个标签页' })

-- ---------------------------------------------------------------------------
-- 诊断 / quickfix / location list
-- ---------------------------------------------------------------------------
local function diagnostic_goto(next, severity)
  return function()
    vim.diagnostic.jump {
      count = (next and 1 or -1) * vim.v.count1,
      severity = severity and vim.diagnostic.severity[severity] or nil,
      float = true,
    }
  end
end
map('n', '<leader>cd', vim.diagnostic.open_float, { desc = '当前行诊断' })
map('n', ']d', diagnostic_goto(true), { desc = '下一个诊断' })
map('n', '[d', diagnostic_goto(false), { desc = '上一个诊断' })
map('n', ']e', diagnostic_goto(true, 'ERROR'), { desc = '下一个错误' })
map('n', '[e', diagnostic_goto(false, 'ERROR'), { desc = '上一个错误' })
map('n', ']w', diagnostic_goto(true, 'WARN'), { desc = '下一个警告' })
map('n', '[w', diagnostic_goto(false, 'WARN'), { desc = '上一个警告' })

map('n', '<leader>xl', function()
  local ok, err = pcall(function()
    if vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 then
      vim.cmd.lclose()
    else
      vim.cmd.lopen()
    end
  end)
  if not ok and err then vim.notify(err, vim.log.levels.ERROR) end
end, { desc = 'Location List' })

map('n', '<leader>xq', function()
  local ok, err = pcall(function()
    if vim.fn.getqflist({ winid = 0 }).winid ~= 0 then
      vim.cmd.cclose()
    else
      vim.cmd.copen()
    end
  end)
  if not ok and err then vim.notify(err, vim.log.levels.ERROR) end
end, { desc = 'Quickfix List' })

map('n', '[q', vim.cmd.cprev, { desc = '上一个 quickfix 项' })
map('n', ']q', vim.cmd.cnext, { desc = '下一个 quickfix 项' })

-- ---------------------------------------------------------------------------
-- 其它
-- ---------------------------------------------------------------------------
-- 清屏三连：清搜索高亮 + 刷新 diff + 重绘
map('n', '<leader>ur', '<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>', { desc = '重绘 / 清高亮 / 刷新 diff' })

-- K 被 LSP 的悬浮文档占了，用 <leader>K 触发原生 K（keywordprg）
map('n', '<leader>K', '<cmd>norm! K<cr>', { desc = 'Keywordprg（查 man/帮助）' })

-- 注释：gco / gcO / gcA 由 Comment.nvim 自带（见 custom/plugins/comment.lua），
-- 和 LazyVim 一致，这里不用再绑一遍。

map('n', '<leader>fn', '<cmd>enew<cr>', { desc = '新建文件' })
map('n', '<leader>qq', '<cmd>qa<cr>', { desc = '全部退出' })

-- 草稿本 / 终端这两组要用 snacks，放在 custom/plugins/snacks.lua 里
-- （本文件按字母序排在 snacks.lua **之前**加载，那时 snacks 还没进 runtimepath）

-- 光标下的高亮组 / treesitter 节点
map('n', '<leader>ui', vim.show_pos, { desc = '查看光标下的高亮' })
map('n', '<leader>uI', function()
  vim.treesitter.inspect_tree()
  vim.api.nvim_input 'I'
end, { desc = '查看语法树' })

-- 只看当前 buffer 的按键（which-key 的本地模式）
map('n', '<leader>?', function() require('which-key').show { global = false } end, { desc = '本文件的按键' })

-- Mason（装 LSP / DAP 后端的界面）。mason 在 debug.lua 里 setup，
-- 没装任何东西之前按下去也能用（会打开空的界面）。
map('n', '<leader>cm', '<cmd>Mason<cr>', { desc = 'Mason（装 LSP/调试器）' })

-- 配色：LazyVim 用 snacks picker，本机换算成 telescope
map('n', '<leader>uC', function() require('telescope.builtin').colorscheme { enable_preview = true } end, { desc = '选配色' })

-- ⚠ 下面这些 snacks 的 toggle（<leader>u* 那一整组、zen/zoom、草稿本、终端、性能分析）
--   都放在 custom/plugins/snacks.lua 里，原因是加载顺序：
--   本文件按字母序排在 snacks.lua 之前，那时 snacks.nvim 还没被 vim.pack.add，
--   直接 require('snacks') 会失败。

-- ---------------------------------------------------------------------------
-- which-key 分组名（不写的话面板上就是一串裸按键）
-- ---------------------------------------------------------------------------
pcall(function()
  require('which-key').add {
    { '<leader>b', group = 'Buffer [B]' },
    { '<leader>c', group = '代码 [C]' },
    { '<leader>d', group = '调试 [D]' },
    { '<leader>f', group = '文件/查找 [F]' },
    { '<leader>g', group = 'Git [G]' },
    { '<leader>q', group = '会话/退出 [Q]' },
    { '<leader>s', group = '搜索 [S]' },
    { '<leader>u', group = '开关 [U]' },
    { '<leader>x', group = '诊断/问题 [X]' },
    { '<leader><tab>', group = '标签页 [TAB]' },
    { '[', group = '上一个' },
    { ']', group = '下一个' },
  }
end)

-- vim: ts=2 sts=2 sw=2 et
