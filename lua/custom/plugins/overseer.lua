local function gh(repo) return 'https://github.com/' .. repo end

-- [[ overseer.nvim —— 任务运行器 ]]
--
-- 解决什么问题：写代码时总要反复"编译 → 看报错 → 改 → 再编译"。
-- 原来的做法是按 `:!g++ ...` 或者开个终端手动敲，输出一闪而过，报错也跳不回代码。
--
-- overseer 把这些变成"任务"：
--   - 后台跑，输出实时显示在底部的任务列表里
--   - 编译报错能直接跳到对应文件的对应行（走 quickfix）
--   - 任务的历史都留着，改一行代码想重跑，一个键就行
--
-- 纯 Lua，依赖已装的 plenary。
-- ---------------------------------------------------------------------------

vim.pack.add { gh 'stevearc/overseer.nvim' }

require('overseer').setup {
  -- 任务列表窗口（底部）
  task_list = {
    direction = 'bottom',
    min_height = 12,
    max_height = 20,
    -- 列表里的按键
    bindings = {
      ['<CR>'] = 'RunAction', -- 回车：对这个任务做点什么（重启/停止/看输出…）
      ['q'] = 'Close',
      ['<Esc>'] = 'Close',
      ['r'] = '<CMD>OverseerQuickAction restart<CR>', -- 重跑
    },
  },

  -- 内置模板：make / npm / cargo 这些常见构建系统
  templates = { 'builtin' },
}

-- ---------------------------------------------------------------------------
-- 键位（都归在 <leader>o 下面）
-- ---------------------------------------------------------------------------
vim.keymap.set('n', '<leader>or', '<cmd>OverseerRun<CR>', { desc = '[O]verseer [R]un 选择任务' })
vim.keymap.set('n', '<leader>ot', '<cmd>OverseerToggle<CR>', { desc = '[O]verseer [T]oggle 任务列表' })
vim.keymap.set('n', '<leader>oa', '<cmd>OverseerQuickAction<CR>', { desc = '[O]verseer 快速[A]操作（重跑/停止）' })
-- 编译当前文件（不运行）—— 只想看看有没有语法错误时用
vim.keymap.set('n', '<leader>ob', '<cmd>OverseerRun 编译当前文件<CR>', { desc = '[O]verseer [B]uild 只编译' })

-- ---------------------------------------------------------------------------
-- 自建模板
--
-- 内置的模板（make / cmake / cargo…）都是给有构建系统的项目用的。
-- 但你刷题是**单个 .cpp 文件**，没有 Makefile，所以下面自己写几个：
-- ---------------------------------------------------------------------------
local overseer = require 'overseer'

-- C++：编译 + 运行（刷题最常用的一条）
overseer.register_template {
  name = 'C++ 编译并运行当前文件',
  -- 只在 cpp / c 文件里出现
  condition = { filetype = { 'cpp', 'c' } },
  tags = { overseer.TAG.BUILD },
  priority = 60,
  builder = function()
    local file = vim.fn.expand '%:p' -- 当前文件完整路径
    local out = vim.fn.expand '%:p:r' -- 去掉扩展名，作为可执行文件名
    local std = vim.g.cpp_standard or 'c++17'
    return {
      -- 用 bash -c 串起来：编译成功才运行（&&）
      cmd = 'bash',
      args = {
        '-c',
        string.format('g++ -std=%s -Wall -Wextra -g -o %s %s && %s', std, out, file, out),
      },
      -- 把编译输出接进 quickfix，有报错能直接跳过去
      components = { 'on_output_quickfix', 'default' },
    }
  end,
}

-- C++：只编译不运行（看有没有语法错误）
overseer.register_template {
  name = '编译当前文件',
  condition = { filetype = { 'cpp', 'c' } },
  tags = { overseer.TAG.BUILD },
  priority = 50,
  builder = function()
    local file = vim.fn.expand '%:p'
    local out = vim.fn.expand '%:p:r'
    local std = vim.g.cpp_standard or 'c++17'
    return {
      cmd = 'g++',
      args = { '-std=' .. std, '-Wall', '-Wextra', '-g', '-o', out, file },
      components = { 'on_output_quickfix', 'default' },
    }
  end,
}

-- C++：用 gdb 调试当前文件编出来的程序
--
-- ⚠ 说明：本机 gdb 是 9.2，**不支持 DAP 协议**（要 gdb 14+ 才有 `--interpreter=dap`），
--   所以暂时没法接进 nvim-dap 用图形化断点调试。
--   这个模板是降级方案：开一个终端跑 gdb 的 TUI 界面（代码 + 命令同屏），
--   断点靠敲命令（`b 行号`、`r`、`n`、`s`、`p 变量名`），对刷题够用。
--   想换成图形化的断点调试，跑一次 `bash scripts/install-codelldb.sh`
--   装上 CodeLLDB 就行了（见 custom/plugins/debug.lua）。
overseer.register_template {
  name = 'C++ 用 gdb 调试（终端界面）',
  condition = { filetype = { 'cpp', 'c' } },
  priority = 40,
  builder = function()
    local out = vim.fn.expand '%:p:r'
    return {
      cmd = 'bash',
      args = {
        '-c',
        string.format('g++ -std=%s -Wall -Wextra -g -o %s %s && gdb -tui %s', vim.g.cpp_standard or 'c++17', out, vim.fn.expand '%:p', out),
      },
      -- 这种交互式任务不要用 quickfix 组件（会卡），用 on_exit 就够
      components = { 'on_exit_set_status', 'default' },
    }
  end,
}

-- Python：运行当前文件
overseer.register_template {
  name = 'Python 运行当前文件',
  condition = { filetype = 'python' },
  priority = 60,
  builder = function()
    local python3 = vim.fn.exepath 'python3'
    if python3 == '' then python3 = 'python3' end
    return {
      cmd = python3,
      args = { vim.fn.expand '%:p' },
      components = { 'on_output_quickfix', 'default' },
    }
  end,
}

-- ---------------------------------------------------------------------------
-- 怎么用
-- ---------------------------------------------------------------------------
--   <leader>or          弹出任务列表让你挑（比如"编译并运行当前文件"）
--   <leader>ob          一步到位：直接编译（不用每次都挑）
--   <leader>ot          打开/关闭底部的任务列表窗口
--   <leader>oa          对最近一次任务做操作：重跑 / 停止 / 看输出
--
--   任务列表窗口里：
--     回车   对这个任务做操作（重启 / 停止 / 打开输出…）
--     r      重跑
--     q      关闭窗口
--
--   编译报错的话，输出会进 quickfix，用 :copen 能看到并跳过去，
--   或者用已装的 trouble：`<leader>xx`
-- ---------------------------------------------------------------------------

-- vim: ts=2 sts=2 sw=2 et
