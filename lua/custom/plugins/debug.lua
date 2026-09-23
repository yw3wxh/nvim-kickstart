local function gh(repo) return 'https://github.com/' .. repo end

-- [[ 调试：nvim-dap + nvim-dap-ui ]]
--
-- 注意：kickstart 自带的 kickstart/plugins/debug.lua **没有启用**，
--   因为它用的是 Mason 自动下载调试器（就是你这台机器出问题的那套），
--   而且配的是 Go 语言。这里重新写一个 Python / C++ 版本。
--
-- 调试器现状（实测结论，不粉饰）：
--   ✅ Python  → debugpy 已装好（pip），**开箱可用**
--   ❌ C++     → 本机 gdb 是 9.2，**不支持 DAP 协议**（要 gdb 14+ 才有
--                `--interpreter=dap`），而 nvim-dap 的 C++ 适配器用的是
--                微软的 cpptools，那个是二进制，需要下载但被网络挡住了
--                （GitHub release 资产走不通）。
--                → 所以 C++ 这里只**预留**配置：装了 cpptools 就自动生效，
--                  没装则用 overseer 的 gdb 终端方案（见 custom/plugins/overseer.lua）。
-- ---------------------------------------------------------------------------

vim.pack.add {
  gh 'mfussenegger/nvim-dap',
  gh 'rcarriga/nvim-dap-ui',
  gh 'nvim-neotest/nvim-nio', -- nvim-dap-ui 的依赖（异步库），不装会报错
}

local dap = require 'dap'
local dapui = require 'dapui'

-- ---------------------------------------------------------------------------
-- 调试界面
-- ---------------------------------------------------------------------------
dapui.setup {
  -- 用普通字符做图标，避免没装 Nerd Font 时显示成一堆方框
  icons = { expanded = '-', collapsed = '+', current_frame = '*' },

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
    -- 底部那排播放/暂停按钮，同样用朴素字符
    icons = {
      pause = 'II',
      play = '>',
      step_into = '>',
      step_over = '>>',
      step_out = '<',
      step_back = '<<',
      run_last = '>>|',
      terminate = 'X',
      disconnect = 'x',
    },
  },
}

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
-- C++ 调试器（预留：装了 cpptools 才会启用，没装就不出现，不报错）
-- ---------------------------------------------------------------------------
-- cpptools 是微软给 VS Code 做的 C++ 调试后端，nvim-dap 的 cppdbg 适配器要用它。
-- 有 linux-arm64 版本，但这台机器下不下来（GitHub release 资产被网络挡）。
--
-- 什么时候想装，两步：
--   1) 下载：https://github.com/microsoft/vscode-cpptools/releases
--      选文件名带 linux-arm64 的 .vsix
--   2) 解压放到下面这个路径，让 OpenDebugAD7 出现在指定位置：
--        mkdir -p ~/.local/share/nvim-dap/cpptools && cd ~/.local/share/nvim-dap/cpptools
--        unzip cpptools-linux-arm64.vsix
--        chmod +x extension/debugAdapters/bin/OpenDebugAD7
--   放好之后重启 nvim，下面这段就会自动生效（不需要改这个文件）。
local cpptools = vim.fn.expand '~/.local/share/nvim-dap/cpptools/extension/debugAdapters/bin/OpenDebugAD7'

if vim.uv.fs_stat(cpptools) then
  dap.adapters.cppdbg = {
    id = 'cppdbg',
    type = 'executable',
    command = cpptools,
  }

  dap.configurations.cpp = {
    {
      name = '调试当前 C++ 文件（会先编译）',
      type = 'cppdbg',
      request = 'launch',
      -- 启动前先编译，保证调试的是最新代码
      preLaunchTask = 'build',
      program = function()
        -- 先用 g++ 编出可执行文件，再调试它
        local out = vim.fn.expand '%:p:r'
        local src = vim.fn.expand '%:p'
        local std = vim.g.cpp_standard or 'c++17'
        vim.fn.system(string.format('g++ -std=%s -Wall -Wextra -g -o %s %s', std, out, src))
        return out
      end,
      cwd = '${workspaceFolder}',
      stopAtEntry = false, -- 是否一进来就停在 main 的第一行
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
  -- C 语言共用同一套配置
  dap.configurations.c = dap.configurations.cpp

  vim.g.dap_cpp_ready = true
else
  -- 没装 cpptools：给个提示，但不打扰（只在你要调试 C++ 时才说）
  vim.g.dap_cpp_ready = false
end

-- ---------------------------------------------------------------------------
-- 键位
-- ---------------------------------------------------------------------------
-- 沿用 kickstart 那套功能键（F1/F2/F3/F5/F7），再补个 F9 打断点。
-- 注意：这些键在有些终端里会被占用（比如 F1 触发终端帮助），
--      如果按了没反应，先检查终端设置。

vim.keymap.set('n', '<F5>', function() dap.continue() end, { desc = 'Debug: 启动 / 继续' })
vim.keymap.set('n', '<F1>', function() dap.step_into() end, { desc = 'Debug: 步入（进函数）' })
vim.keymap.set('n', '<F2>', function() dap.step_over() end, { desc = 'Debug: 步过（不进函数）' })
vim.keymap.set('n', '<F3>', function() dap.step_out() end, { desc = 'Debug: 步出（跳出当前函数）' })
vim.keymap.set('n', '<F4>', function() dap.terminate() end, { desc = 'Debug: 结束调试' })
vim.keymap.set('n', '<F7>', function() dapui.toggle() end, { desc = 'Debug: 开关调试界面' })
vim.keymap.set('n', '<F9>', function() dap.toggle_breakpoint() end, { desc = 'Debug: 打/取消断点' })

-- 条件断点：只有表达式为真时才停（比如循环里 i == 50）
vim.keymap.set(
  'n',
  '<leader>dB',
  function() dap.set_breakpoint(vim.fn.input '断点条件（比如 i == 10，可留空）: ') end,
  { desc = '[D]ebug 条件[B]断点' }
)

-- 监视变量：把光标下的变量加进调试界面右侧的监视列表
vim.keymap.set('n', '<leader>dw', function() dapui.elements.watches.add() end, { desc = '[D]ebug 加监视([W]atch)' })
-- 悬浮看当前变量的值（不用加到监视列表）
vim.keymap.set('n', '<leader>dh', function() dapui.eval() end, { desc = '[D]ebug 悬浮看值([H]over)' })

-- ---------------------------------------------------------------------------
-- 怎么用（Python 为例，这个是现在就能跑的）
-- ---------------------------------------------------------------------------
--   1) 打开一个 .py 文件，把光标放到想停的那行，按 <F9> 打个红点
--   2) 按 <F5> 启动 → 会让你选"调试当前 Python 文件"，回车
--   3) 程序会停在断点那行，左边自动弹出变量、调用栈
--      F1 进函数 / F2 不进函数往下走 / F3 跳出当前函数 / F5 继续跑到下一个断点
--   4) 调试完按 F4 结束
--
-- C++ 现在按 <F5> 会提示没有配置 —— 要先用 overseer 的 gdb 终端方案
--（<leader>or 里选"C++ 用 gdb 调试（终端界面）"），等 cpptools 装好再说。
-- ---------------------------------------------------------------------------

-- vim: ts=2 sts=2 sw=2 et
