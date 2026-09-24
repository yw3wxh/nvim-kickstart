-- 通过缓存编译后的 Lua 模块来加快启动速度
vim.loader.enable()

-- 将 <space> 设置为 leader 键
-- 参见 `:help mapleader`
--  注意：必须在插件加载之前设置（否则会使用错误的 leader 键）
vim.g.mapleader = ' '
-- localleader 用反斜杠（vim 惯例），**不要**跟上面设成同一个键。
-- 原因：装了 grug-far 之后，它的窗口内开关走的是 <localleader>xxx，
-- 如果 localleader 也是空格，就会和全局的 <leader>f（格式化）这类按键撞车。
vim.g.maplocalleader = '\\'

-- 你已在终端里装了 JetBrainsMono Nerd Font，设为 true：
-- which-key 的按键图标、mini 状态栏的模式图标、trouble 的诊断图标都会用上。
vim.g.have_nerd_font = true

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
--  参见 `:help 'clipboard'
--
-- 操作系统判断：WSL 里 Neovim 同样跑在 Linux 用户态（has('linux') 也是 true），
-- 必须单独识别 WSL——WSL 没有 Wayland/X，剪贴板要走和 Windows 互通的方案。
local is_wsl = (vim.fn.has('wsl') == 1)
  or (vim.fn.filereadable('/proc/version') == 1
    and (vim.fn.readfile('/proc/version')[1] or ''):lower():match('microsoft') ~= nil)
local is_linux = vim.fn.has('linux') == 1 and not is_wsl

if is_wsl then
  -- WSL：没有 Wayland/X，剪贴板和 Windows 互通，交给 PowerShell。
  --   copy 让 Neovim 把文本从 stdin 喂给 Set-Clipboard；paste 用 Get-Clipboard 读回来。
  --   优先 powershell.exe，没有就退而用 pwsh.exe（PowerShell 7）。
  local win_clip = (vim.fn.executable 'powershell.exe' == 1 and 'powershell.exe')
    or (vim.fn.executable 'pwsh.exe' == 1 and 'pwsh.exe')
    or 'powershell.exe'
  vim.g.clipboard = {
    name = 'WSL → Windows 剪贴板',
    copy = {
      ['+'] = { win_clip, '-NoProfile', '-Command', 'Set-Clipboard -Value $input' },
      ['*'] = { win_clip, '-NoProfile', '-Command', 'Set-Clipboard -Value $input' },
    },
    paste = {
      ['+'] = { win_clip, '-NoProfile', '-Command', 'Get-Clipboard' },
      ['*'] = { win_clip, '-NoProfile', '-Command', 'Get-Clipboard' },
    },
  }
elseif is_linux then
  -- ⚠ 本机没装 xclip/xsel，桌面是 **Wayland**（UKUI on Wayland，合成器 ukui-kwin_wayland）。
  --   老吴实测 OSC 52 在他的终端不生效，所以走原生 wl-copy / wl-paste 剪贴板。
  --   卡死坑：Wayland 下 wl-copy 拷完默认 fork 到后台持有剪贴板，Neovim 的 clipboard
  --   provider 有时仍会等它的进程树 → "+y 卡死。所以 copy 走 scripts/wl-copy-bg.sh，
  --   里面用 `&` 再后台化一次，脚本立即退出、Neovim 不再等待；paste 用 wl-paste（读完即退，不卡）。
  --   前提：nvim 进程带 WAYLAND_DISPLAY（在 UKUI 终端里启动默认就有）。
  local cfgdir = vim.fn.stdpath 'config'
  vim.g.clipboard = {
    name = 'wl-clipboard (backgrounded copy)',
    copy = {
      ['+'] = { cfgdir .. '/scripts/wl-copy-bg.sh', '--type', 'text/plain' },
      ['*'] = { cfgdir .. '/scripts/wl-copy-bg.sh', '--type', 'text/plain', '--primary' },
    },
    paste = {
      -- 用带超时+自动补 WAYLAND_DISPLAY 的包装脚本：剪贴板为空时 wl-paste 会一直阻塞，
      -- 那样普通 p 粘贴就会把 nvim 主线程拖死、连 :qa 都退不出。脚本 1 秒超时即返回空，绝不卡死。
      ['+'] = { cfgdir .. '/scripts/wl-paste-bg.sh', '--type', 'text/plain' },
      ['*'] = { cfgdir .. '/scripts/wl-paste-bg.sh', '--type', 'text/plain', '--primary' },
    },
  }
end
-- Windows / macOS 不设置 vim.g.clipboard，交给 Neovim 自带实现
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
-- ⚠ 故意不标 tab：老吴嫌 Tab 显示成 `»`（字体里像 `>>`）太碍眼。
--   注意：listchars 里**完全删掉 tab 项**会回退成默认显示 `^I`，更难看；
--   所以用「两个空格」占位，Tab 渲染出来跟普通空格一样、肉眼看不见，
--   同时 list 仍开着、行尾空格(trail)和不间断空格(nbsp)照常标。
--   代价：用 Tab 缩进的老文件肉眼看不出它用的是 Tab——
--   要查缩进混用，用 `:set list!` 临时开一下，或看状态栏/`:retab` 报错。
vim.opt.listchars = { tab = '  ', trail = '·', nbsp = '␣' }

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

-- [[ 缩进：统一 4 个空格 ]]
-- 全局默认 4 空格，避免不同文件出现 8 空格或 Tab 混用。
-- 新行、>> / <<、自动缩进都按 4 空格。下面的 guess-indent 配置会
-- 把「已有文件」的宽度也强制成 4（只保留它识别 Tab/空格的能力）。
vim.o.tabstop = 4 -- 一个 Tab 在屏幕上占 4 列
vim.o.shiftwidth = 4 -- 每次缩进/反缩进、自动缩进的空格数
vim.o.softtabstop = 4 -- 编辑时按一次 Tab / Backspace 移动 4 列
vim.o.expandtab = true -- 用空格代替真正的 Tab 字符

-- vim: ts=2 sts=2 sw=2 et
