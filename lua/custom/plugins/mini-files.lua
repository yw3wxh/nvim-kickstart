-- [[ mini.files —— 文件管理器 ]]
--
-- 为什么选它而不是 oil.nvim / neo-tree：
--   1) **不用再下载任何东西** —— mini.nvim 已经在本地了（见 kickstart/plugins/mini.lua），
--      这里只是把它自带的 files 模块启用起来。本机网络（GitHub 只通 443）能装但慢，
--      能用现成的就别再下一次。
--   2) 界面是"米勒列"（左边父目录、中间当前目录、右边预览），
--      上下级关系一眼看得清，比单栏树形更省地方。
--   3) 和已启用的 mini.ai / mini.surround / mini.icons 同一套风格。
--
-- 核心思路：**把目录当文本编辑**。
--   增删改名都只是在 buffer 里改文字，按 `=` 才真正落到磁盘。
--   所以改错了不保存就没事，有后悔药。
--
-- 如果以后觉得列式浏览不顺手，想换成 oil.nvim 那种"整个目录平铺成文本"的风格，
-- 删掉本文件、装 oil.nvim 即可，两者不要同时开。
-- ---------------------------------------------------------------------------

-- 注意：这里不需要 vim.pack.add，mini.nvim 已经在 kickstart/plugins/mini.lua 里装好了
local mini_files = require 'mini.files'

mini_files.setup {
  options = {
    -- 把 mini.files 设成默认文件浏览器：
    -- 这样 `nvim 某个目录` 或者 `:e .` 都会用它打开，而不是 vim 自带的 netrw
    use_as_default_explorer = true,

    -- 删除文件时**不**真的从磁盘删掉，而是挪到一个回收目录里
    -- （路径：stdpath('data')/mini.files/trash），误删还能捞回来。
    -- 想要干脆利落直接删，就把它改成 true
    permanent_delete = false,
  },

  windows = {
    -- 右侧显示预览窗口（目录就列子项，文件就显示内容）
    preview = true,
    -- 各列宽度：聚焦的那列宽一些，其余窄一些
    width_focus = 50,
    width_nofocus = 20,
    width_preview = 50,
  },

  mappings = {
    close = 'q', -- 关闭文件管理器
    go_in = 'l', -- 进入子目录 / 打开文件
    go_in_plus = 'L', -- 进入并关闭管理器
    go_out = 'h', -- 回到上一级目录
    go_out_plus = 'H', -- 回到上一级并关闭
    reset = '<BS>', -- 放弃所有改动，恢复原样
    reveal_cwd = '.', -- 定位到当前工作目录
    show_help = 'g?', -- 查看内置帮助
    synchronize = '=', -- 【关键】把 buffer 里的改动真正同步到磁盘
    trim_left = '<', -- 收窄当前列
    trim_right = '>', -- 加宽当前列
  },
}

-- ---------------------------------------------------------------------------
-- 打开方式
-- ---------------------------------------------------------------------------
--- 打开 mini.files，优先定位到当前文件所在的目录
local function open_at_current_file()
  local path = vim.api.nvim_buf_get_name(0)
  -- 没打开任何文件（比如刚启动的空 buffer）就退回当前工作目录
  if path == '' then path = vim.fn.getcwd() end
  mini_files.open(path)
end

vim.keymap.set('n', '<leader>e', open_at_current_file, { desc = '[E]xplorer 打开文件管理器' })
vim.keymap.set('n', '-', open_at_current_file, { desc = '打开当前文件所在目录' })

-- ---------------------------------------------------------------------------
-- 用法速查（进入管理器后）
-- ---------------------------------------------------------------------------
--   l / h      进入目录 / 回到上级（和 vim 的左右一致）
--   =          保存改动 —— 新建、删除、重命名、复制，全靠这一步才生效
--   <BS>       放弃全部改动，恢复原样
--   q          关闭
--   g?         查看完整按键说明
--   .          跳到当前工作目录
--
-- 常见操作：
--   新建文件   在 buffer 里新起一行，写上文件名（目录要以 / 结尾），按 =
--   重命名     直接改那一行文字，按 =
--   删除       直接删掉那一行，按 =（文件会被挪到回收目录，不是真删）
--   复制/移动  像普通文本一样 yank / put 到别的目录行下面，按 =
-- ---------------------------------------------------------------------------

-- vim: ts=2 sts=2 sw=2 et
