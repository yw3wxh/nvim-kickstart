-- 通过缓存编译后的 Lua 模块来加快启动速度
vim.loader.enable()

-- 将 <space> 设置为 leader 键
-- 参见 `:help mapleader`
--  注意：必须在插件加载之前设置（否则会使用错误的 leader 键）
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- 如果你在终端中安装并选择了 Nerd Font，请设为 true
vim.g.have_nerd_font = false

-- [[ 设置选项 ]]
--  参见 `:help vim.o`
-- 注意：你可以随意修改这些选项！
--  更多选项参见 `:help option-list`

-- 默认显示行号
vim.o.number = true
-- 你也可以启用相对行号，有助于跳转。
--  可以自己试试看是否喜欢！
-- vim.o.relativenumber = true

-- 启用鼠标模式，例如调整分屏大小时会很有用！
vim.o.mouse = 'a'

-- 不显示模式，因为状态栏中已经显示了
vim.o.showmode = false

-- 在操作系统和 Neovim 之间同步剪贴板。
--  把设置安排在 `UiEnter` 之后，因为这可能会增加启动时间。
--  如果你希望操作系统剪贴板保持独立，请移除该选项。
--  参见 `:help 'clipboard'`
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

-- 启用断行缩进
vim.o.breakindent = true

-- 即使在关闭并重新打开文件后，也保留撤销/重做记录
vim.o.undofile = true

-- 搜索时忽略大小写，除非搜索词中包含 \C 或一个或多个大写字母
vim.o.ignorecase = true
vim.o.smartcase = true

-- 默认保持符号列开启
vim.o.signcolumn = 'yes'

-- 减少更新时间
vim.o.updatetime = 250

-- 减少映射序列等待时间
vim.o.timeoutlen = 300

-- 配置新分屏的打开方式
vim.o.splitright = true
vim.o.splitbelow = true

-- 设置 Neovim 在编辑器中如何显示某些空白字符。
--  参见 `:help 'list'`
--  和 `:help 'listchars'`
--
--  注意 listchars 是使用 `vim.opt` 而不是 `vim.o` 设置的。
--  它与 `vim.o` 非常相似，但提供了方便操作表格的接口。
--   参见 `:help lua-options`
--   和 `:help lua-guide-options`
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- 输入时实时预览替换！
vim.o.inccommand = 'split'

-- 显示光标所在的行
vim.o.cursorline = true

-- 光标上方和下方保留的最少屏幕行数。
vim.o.scrolloff = 10

-- 如果执行的操作会因缓冲区中有未保存的更改而失败（如 `:q`），
-- 则弹出一个对话框，询问你是否希望保存当前文件
-- 参见 `:help 'confirm'`
vim.o.confirm = true

-- vim: ts=2 sts=2 sw=2 et
