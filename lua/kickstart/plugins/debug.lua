local function gh(repo) return 'https://github.com/' .. repo end

-- [[ 调试：nvim-dap + nvim-dap-ui（+ Mason，手动模式）]]
--
-- 这份配置从 custom/plugins/debug.lua 搬到了 kickstart/plugins/debug.lua（更贴近"原版"位置）。
-- 功能：Python / C++ 调试，键位全用 <leader>d 前缀（不用功能键 F1~F12）。
--
-- 调试器现状（实测结论）：
--   ✅ Python  → debugpy 已装好（pip），**开箱可用**
--   ⚠ C++     → 需要额外的 DAP 后端（gdb 9.2 不支持 DAP、系统也没 lldb）。
--               这里选 **CodeLLDB**（基于 LLVM 的 lldb，Rust 静态链接，对 aarch64 + glibc 2.31
--               比微软 cpptools 更稳）。装法：bash scripts/install-codelldb.sh，装好自动生效。
--
-- Mason：装好但【手动模式】，不会自动下载/更新任何调试器（避免这台 aarch64/glibc 2.31
--   机器上自动拉二进制翻车）。想用 Mason 里的调试器时，自己 :Mason 里点装即可。
-- ---------------------------------------------------------------------------

vim.pack.add {
  gh 'mfussenegger/nvim-dap',
  gh 'rcarriga/nvim-dap-ui',
  gh 'nvim-neotest/nvim-nio', -- nvim-dap-ui 的依赖（异步库），不装会报错
  gh 'mason-org/mason.nvim',
  gh 'jay-babu/mason-nvim-dap.nvim',
}

local dap = require 'dap'
local dapui = require 'dapui'

-- ---------------------------------------------------------------------------
-- Mason（手动模式）
-- ---------------------------------------------------------------------------
--   automatic_installation = false  → 不自动拉取/安装调试器
--   ensure_installed       = {}     → 也不预装 delve / go 等
--   :Mason 仍可打开，想装什么自己手动装（只有你手动操作时才下载）
require('mason').setup {}
require('mason-nvim-dap').setup {
  automatic_installation = false,
  handlers = {},
  ensure_installed = {},
}

-- ---------------------------------------------------------------------------
-- 调试界面
-- ---------------------------------------------------------------------------
dapui.setup {
  -- 用更可能在各种终端正常显示的图标字符（本机已装 Nerd Font，渲染没问题）
  icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },

  -- 布局：左侧看变量/调用栈，底部看终端输出和断点
  layouts = {
    {
      elements = {
        { id = 'scopes', size = 0.35 }, -- 变量
        { id = 'stacks', size = 0.35 }, -- 调用栈
        { id = 'watches', size = 0.15 }, -- 监视
        { id = 'breakpoints', size = 0.15 }, -- 断点列表
      },
      size = 45,
      position = 'left',
    },
    {
      elements = { 'repl', 'console' }, -- 调试器的输入输出
      size = 12,
      position = 'bottom',
    },
  },

  controls = {
    icons = {
      pause = '⏸',
      play = '▶',
      step_into = '⏎',
      step_over = '⏭',
      step_out = '⏮',
      step_back = 'b',
      run_last = '▶▶',
      terminate = '⏹',
      disconnect = '⏏',
    },
  },
}

-- 断点图标：本机已装 Nerd Font，用原版图标字形（不再是字符占位）
vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
local breakpoint_icons = vim.g.have_nerd_font
    and { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
  or { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
for type, icon in pairs(breakpoint_icons) do
  local tp = 'Dap' .. type
  local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
  vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
end

-- 调试开始/结束时自动开合界面（省得手动开关）
dap.listeners.after.event_initialized['dapui_config'] = dapui.open
dap.listeners.before.event_terminated['dapui_config'] = dapui.close
dap.listeners.before.event_exited['dapui_config'] = dapui.close

-- ---------------------------------------------------------------------------
-- Python 调试器（已装，直接可用）
-- ---------------------------------------------------------------------------
local python3 = vim.fn.exepath 'python3'
if python3 == '' then python3 = 'python3' end

dap.adapters.python = {
  type = 'executable',
  command = python3,
  args = {
    -- Python 3.13 默认会"冻结"一部分标准库模块，debugpy 会警告：
    -- "frozen modules are being used, which may make the debugger miss breakpoints"
    -- 加上这个参数就关掉了，免得断点莫名其妙不生效
    '-Xfrozen_modules=off',
    '-m',
    'debugpy.adapter',
  },
}

dap.configurations.python = {
  {
    type = 'python',
    request = 'launch',
    name = '调试当前 Python 文件',
    program = '${file}', -- 当前文件
    cwd = '${workspaceFolder}',
    console = 'integratedTerminal', -- 程序输出显示在 nvim 的终端里
    -- 不加这个的话，标准库报的错会看到一堆 debugpy 自己的调用栈
    justMyCode = false,
  },
  {
    type = 'python',
    request = 'launch',
    name = '调试当前文件（带命令行参数）',
    program = '${file}',
    cwd = '${workspaceFolder}',
    console = 'integratedTerminal',
    justMyCode = false,
    -- 运行时会弹个输入框让你填参数，空格分隔
    args = function()
      local input = vim.fn.input '命令行参数（空格分隔，可留空）: '
      return vim.split(input, ' ', { trimempty = true })
    end,
  },
  {
    type = 'python',
    request = 'attach',
    name = '连接到已经在跑的 debugpy（端口 5678）',
    -- 用途：调试在 nvim 外面启动的程序，比如 Flask / pytest
    -- 程序里要写：import debugpy; debugpy.listen(5678); debugpy.wait_for_client()
    connect = { host = '127.0.0.1', port = 5678 },
  },
}

-- ---------------------------------------------------------------------------
-- C++ 调试器
--
-- 按优先级探测两个后端，哪个装了用哪个，都没装就静默跳过（不报错）：
--   1) **CodeLLDB**（首选）—— 基于 LLVM 的 lldb，自带整套 lldb，不依赖系统 LLVM
--   2) **cpptools**（备选）—— 微软给 VS Code 做的，走 gdb 的 MI
--
-- 两个都是二进制，都得额外装。装 CodeLLDB 用仓库里的脚本：
--     bash scripts/install-codelldb.sh
--   （它会下载 codelldb-linux-arm64.vsix 并解压到下面这个路径）
-- 装好之后重启 nvim 就自动生效，不用改这个文件。
-- ---------------------------------------------------------------------------
local codelldb = vim.fn.expand '~/.local/share/nvim-dap/codelldb/extension/adapter/codelldb'
local cpptools = vim.fn.expand '~/.local/share/nvim-dap/cpptools/extension/debugAdapters/bin/OpenDebugAD7'

-- 调试前先把当前文件编译出来（保证调试的是最新代码），返回可执行文件路径
---@return string
local function build_current_file()
  local out = vim.fn.expand '%:p:r'
  local src = vim.fn.expand '%:p'
  local std = vim.g.cpp_standard or 'c++17'
  local compiler = vim.bo.filetype == 'c' and 'gcc' or 'g++'
  local cmd = string.format('%s -std=%s -Wall -Wextra -g -o %s %s', compiler, std, out, src)
  vim.fn.system(cmd)
  -- 编译失败了直接把错误显示出来，别让你对着一个旧的可执行文件调试
  if vim.v.shell_error ~= 0 then vim.notify('编译失败，调试已中止', vim.log.levels.ERROR) end
  return out
end

if vim.uv.fs_stat(codelldb) then
  -- ---- CodeLLDB（推荐）----
  -- 它是"服务器"模式：nvim 先启动 codelldb 进程，再连到它开的端口上
  dap.adapters.codelldb = {
    type = 'server',
    port = '${port}',
    executable = {
      command = codelldb,
      args = { '--port', '${port}' },
    },
  }

  dap.configurations.cpp = {
    {
      name = '调试当前 C++ 文件（先编译再调试）',
      type = 'codelldb',
      request = 'launch',
      program = build_current_file,
      cwd = '${workspaceFolder}',
      stopOnEntry = false, -- true 的话一进来就停在 main 第一行
      -- 程序的输入输出走 nvim 的终端（能交互输入）
      terminal = 'integrated',
    },
    {
      name = '调试一个已编译好的程序',
      type = 'codelldb',
      request = 'launch',
      program = function() return vim.fn.input('可执行文件路径: ', vim.fn.expand '%:p:r', 'file') end,
      cwd = '${workspaceFolder}',
      stopOnEntry = false,
      terminal = 'integrated',
    },
  }
  dap.configurations.c = dap.configurations.cpp -- C 共用同一套

  vim.g.dap_cpp_backend = 'codelldb'
elseif vim.uv.fs_stat(cpptools) then
  -- ---- cpptools（备选，走 gdb 的 MI）----
  dap.adapters.cppdbg = {
    id = 'cppdbg',
    type = 'executable',
    command = cpptools,
  }

  dap.configurations.cpp = {
    {
      name = '调试当前 C++ 文件（先编译再调试）',
      type = 'cppdbg',
      request = 'launch',
      program = build_current_file,
      cwd = '${workspaceFolder}',
      stopAtEntry = false,
      externalConsole = false,
      MIMode = 'gdb',
      miDebuggerPath = '/usr/bin/gdb',
      setupCommands = {
        {
          text = '-enable-pretty-printing',
          description = '让 gdb 把 STL 容器（vector/map 等）打印成人能看的样子',
          ignoreFailures = true,
        },
      },
    },
  }
  dap.configurations.c = dap.configurations.cpp

  vim.g.dap_cpp_backend = 'cpptools'
else
  -- 两个都没有：不报错，C++ 调试暂不可用（降级到 overseer 的 gdb 终端方案）
  vim.g.dap_cpp_backend = nil
end

-- ---------------------------------------------------------------------------
-- 键位
-- ---------------------------------------------------------------------------
-- 调试控制键全部用 <leader>d 前缀（d = Debug），**不用功能键 F1~F12**。
--   原因：很多终端会把 F1 抢去做帮助，不同终端对功能键的行为还不一致，
--   而且功能键在笔记本上往往还得先按 Fn，麻烦。
--   nvim-dap 本身不绑定任何键，这里用 d 组前缀是社区里一套常见约定。
--
-- 控制：
--   dr  启动 / 继续              di  步入（进函数）
--   do  步过（不进函数）        dO  步出（跳出当前函数）
--   dq  结束调试                dU  开关调试界面
vim.keymap.set('n', '<leader>dr', function() dap.continue() end, { desc = '[D]ebug 启动/继续([R]un)' })
vim.keymap.set('n', '<leader>di', function() dap.step_into() end, { desc = '[D]ebug 步入([I]nto)' })
vim.keymap.set('n', '<leader>do', function() dap.step_over() end, { desc = '[D]ebug 步过([O]ver)' })
vim.keymap.set('n', '<leader>dO', function() dap.step_out() end, { desc = '[D]ebug 步出([O]ut)' })
vim.keymap.set('n', '<leader>dq', function() dap.terminate() end, { desc = '[D]ebug 结束调试([Q]uit)' })
vim.keymap.set('n', '<leader>dU', function() dapui.toggle() end, { desc = '[D]ebug 开关界面([U]I)' })

-- ---------------------------------------------------------------------------
-- 断点类键也都在 <leader>d 组下（上面的控制键也是）：
--   db  普通断点（切换：再按一次取消，也就是清当前行）
--   dc  条件断点（只有条件为真才停，比如 i == 10）
--   dl  日志断点（不停下，只在控制台打印一行，适合看循环里的值）
--   dA  清除所有断点
-- （注意和 snacks 的 <leader>bd 不冲突：那是删 buffer，字母顺序反过来。
--   想清单个断点，用 db 在当前行再按一次即可——nvim-dap 没有"单行清除"的 API）
-- ---------------------------------------------------------------------------
vim.keymap.set('n', '<leader>db', function() dap.toggle_breakpoint() end, { desc = '[D]ebug 普通断点([B]reakpoint)' })
vim.keymap.set(
  'n',
  '<leader>dc',
  function() dap.set_breakpoint(vim.fn.input '断点条件（比如 i == 10，可留空）: ') end,
  { desc = '[D]ebug 条件断点([C]onditional)' }
)
vim.keymap.set(
  'n',
  '<leader>dl',
  function() dap.set_breakpoint(nil, nil, vim.fn.input '日志内容（打印到调试控制台、不暂停）: ') end,
  { desc = '[D]ebug 日志断点([L]og)' }
)
vim.keymap.set('n', '<leader>dA', function() dap.clear_breakpoints() end, { desc = '[D]ebug 清除所有断点([A]ll)' })

-- 监视变量：把光标下的变量加进调试界面右侧的监视列表
vim.keymap.set('n', '<leader>dw', function() dapui.elements.watches.add() end, { desc = '[D]ebug 加监视([W]atch)' })
-- 悬浮看当前变量的值（不用加到监视列表）
vim.keymap.set('n', '<leader>dh', function() dapui.eval() end, { desc = '[D]ebug 悬浮看值([H]over)' })

-- ---------------------------------------------------------------------------
-- 怎么用（Python 为例，这个是现在就能跑的）
-- ---------------------------------------------------------------------------
--   1) 打开一个 .py 文件，把光标放到想停的那行，按 <leader>db 打个红点（再按一次取消）
--   2) 按 <leader>dr 启动 → 会让你选"调试当前 Python 文件"，回车
--   3) 程序会停在断点那行，左边自动弹出变量、调用栈
--      <leader>di 进函数 / <leader>do 不进函数往下走 / <leader>dO 跳出当前函数 / <leader>dr 继续跑到下一个断点
--   4) 调试完按 <leader>dq 结束
--
-- C++ / C 现在还不能用（缺 DAP 后端），按 <leader>dr 会提示没有配置。
--   先用 overseer 的 gdb 终端方案顶着（<leader>or 里选"C++ 用 gdb 调试（终端界面）"）；
--   想用图形化的断点调试，跑一次：
--       bash scripts/install-codelldb.sh
--   装好重启 nvim，<leader>dr 就能用了。
-- ---------------------------------------------------------------------------

-- vim: ts=2 sts=2 sw=2 et
