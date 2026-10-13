local function gh(repo) return 'https://github.com/' .. repo end

-- 平台判断集中在 lua/platform.lua（is_win_like = WSL 或原生 Windows），此处直接引用。
-- 这些环境能用 Mason 下发预编译二进制，与 Linux/Kylin(aarch64) 不同，所以 LSP 安装策略按环境分流：
--   true  → Windows / WSL，用 Mason 装 clangd / basedpyright / ruff / lua_ls
--   false → Linux/Kylin，改用系统自带 + npm 装的纯 JS 实现（见上方说明）
local platform = require('platform')

-- [[ LSP 配置 ]]
-- 先简单说明一下：**什么是 LSP？**
--
-- LSP 是一个你可能听说过、但不一定理解它是什么的缩写。
--
-- LSP 代表 Language Server Protocol（语言服务器协议）。它是一种协议，
-- 帮助编辑器和语言工具以标准化的方式进行通信。
--
-- 通常，你有一个"服务器"，它是为理解特定语言而构建的工具
-- （比如 `gopls`、`lua_ls`、`rust_analyzer` 等）。这些语言服务器
-- （有时也叫 LSP 服务器，但这有点像"ATM 取款机"）是独立的
-- 进程，与某个"客户端"通信——在这里就是 Neovim！
--
-- LSP 为 Neovim 提供了如下功能：
--  - 跳转到定义
--  - 查找引用
--  - 自动补全
--  - 符号搜索
--  - 以及更多！
--
-- 因此，语言服务器是需要独立于 Neovim 安装的外部工具，
-- 需要先在机器上装好，Neovim 才能连上它们。
--
-- 如果你想知道 lsp 和 treesitter 的区别，可以查看一个编写得非常
-- 出色的帮助章节：`:help lsp-vs-treesitter`
--
-- ---------------------------------------------------------------------------
-- ⚠ 本文件与官方 kickstart 最大的不同：默认不用 Mason（在 Linux/Kylin 上）
--
-- 本机是 aarch64(ARM64) + glibc 2.31，Mason 下发的预编译二进制
-- 多半是 x86_64 或要求更高的 glibc 版本，装完直接跑不起来。
-- 所以 Linux/Kylin 上**不用 Mason**，改用本机已装好的服务：
--
--   C/C++   → clangd        （系统自带，/usr/bin/clangd）
--   Python  → basedpyright  （npm 装到 stdpath data，纯 JS，无 glibc 依赖）
--           → ruff          （~/.local/bin/ruff，负责 lint 与格式化）
--   Lua     → lua_ls        （本机没装，装了才启用）
--
-- 但**在 Windows / WSL 下 Mason 可用**，这里改为让 Mason 负责安装这些
-- 语言服务器（见文件末尾 `platform.is_win_like` 分支的 mason-lspconfig.ensure_installed）：
--   clangd / basedpyright / ruff / lua-language-server
-- 二进制装好后走 PATH 被下面的可执行检测自动接管，其余逻辑无需改动。
--
-- 每个服务器都先检测可执行文件在不在，不存在就跳过，
-- 这样缺哪个都不会在启动时报错刷屏。
-- ---------------------------------------------------------------------------

-- 实用的 LSP 状态更新（右下角显示"正在加载 clangd…"这类提示）
vim.pack.add { gh 'j-hui/fidget.nvim' }
require('fidget').setup {}

--  这个函数会在 LSP 附加到特定缓冲区时运行。
--   也就是说，每当你打开一个与某个 LSP 关联的新文件时
--    （例如，打开 `main.rs` 与 `rust_analyzer` 关联），
--    这个函数就会被执行，用来配置当前的缓冲区
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
  callback = function(event)
    -- 注意：请记住，Lua 是一门真正的编程语言，因此可以定义
    -- 小的辅助和工具函数，这样就不必重复自己了。
    --
    -- 在这里，我们创建了一个函数，让我们可以更方便地定义
    -- 与 LSP 相关的映射。它每次都为我们设置好模式、缓冲区和描述。
    local map = function(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    -- ⚠ 这一组键位已按 LazyVim 官方表重排（原来 kickstart 的 grn / gra / grD / <leader>th 已废弃）：
    --     grn（重命名）      → <leader>cr
    --     gra（代码操作）    → <leader>ca
    --     grD（跳到声明）    → gD（在 telescope.lua 里）
    --     <leader>th（inlay） → <leader>uh（snacks 的 toggle，见 custom/plugins/snacks.lua）
    --   跳转类（gd / gr / gI / gy / gD / <leader>ss / <leader>sS）都在 telescope.lua 里。

    -- 重命名光标下的变量（大多数语言服务器支持跨文件重命名）
    map('<leader>cr', vim.lsp.buf.rename, '重命名符号')

    -- 代码操作（quick fix）：通常要把光标放在报错或 LSP 建议上才有内容
    map('<leader>ca', vim.lsp.buf.code_action, '代码操作（快速修复）', { 'n', 'x' })

    -- 悬浮文档 / 函数签名
    map('K', function() return vim.lsp.buf.hover() end, '悬浮显示文档')
    map('gK', function() return vim.lsp.buf.signature_help() end, '函数签名帮助')
    map('<c-k>', function() return vim.lsp.buf.signature_help() end, '函数签名帮助', 'i')

    -- CodeLens（clangd 这类服务器不一定支持，没有就什么都不做）
    map('<leader>cc', vim.lsp.codelens.run, '运行 CodeLens', { 'n', 'x' })
    map('<leader>cC', vim.lsp.codelens.refresh, '刷新 CodeLens')

    -- 下面两个自动命令用于在你把光标停留在某个单词上片刻时，
    -- 高亮该单词的引用。
    --   关于何时执行的信息参见 `:help CursorHold`
    --
    -- 当你移动光标时，高亮会被清除（第二个自动命令）。
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client:supports_method('textDocument/documentHighlight', event.buf) then
      local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
        end,
      })
    end

    -- inlay hints（类型提示等）的开关统一放在 <leader>uh，
    -- 见 custom/plugins/lazyvim-keymaps.lua（snacks 的 toggle，带状态提示）。
  end,
})

-- ---------------------------------------------------------------------------
-- 诊断信息的显示方式
-- ---------------------------------------------------------------------------
vim.diagnostic.config {
  -- 只把诊断文字显示在当前行末尾，而不是所有有问题的行都显示，
  -- 否则满屏都是红色小字，很吵
  virtual_text = { current_line = true },
  -- 行号栏的标记符号：就用朴素的字母 E/W/I/H。
  -- （虽然已装 Nerd Font，但诊断级别用字母反而更一目了然；
  --   想换成图标的话把 text 改成对应的 Nerd Font 字符即可）
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = 'E',
      [vim.diagnostic.severity.WARN] = 'W',
      [vim.diagnostic.severity.INFO] = 'I',
      [vim.diagnostic.severity.HINT] = 'H',
    },
  },
  -- 输入模式下不实时刷新诊断，避免边打字边跳
  update_in_insert = false,
  -- 按严重程度排序，错误排在最前面
  severity_sort = true,
  float = {
    border = 'rounded',
    -- 悬浮窗口里显示诊断来源（比如 "basedpyright"），便于知道是谁报的
    source = true,
  },
}

-- ---------------------------------------------------------------------------
-- 语言服务器清单
-- ---------------------------------------------------------------------------
---@type table<string, vim.lsp.Config>
local servers = {}

-- C/C++ ----------------------------------------------------------------------
-- 直接用系统自带的 clangd（本机是 clangd 10.0.0）。
-- clangd 默认按 C++14 解析。单文件刷题没有 compile_commands.json，
-- C++17+ 特性（std::optional 等）会报红 —— 老吴确认 C++14 够用，
-- 所以不自动维护编译数据库（之前那套自动生成已按老吴要求撤掉）。
-- 你若自己某目录放了 compile_commands.json，clangd 仍会向上找到它。
if vim.fn.executable 'clangd' == 1 then
  servers.clangd = {
    cmd = {
      'clangd',
      '--background-index', -- 后台建索引，跳转定义更快
      '--clang-tidy', -- 顺带跑 clang-tidy 静态检查
      '--header-insertion=never', -- 不要自动插入 #include，避免乱加头文件
      '--completion-style=detailed', -- 补全时附带函数签名等信息
    },
  }
end

-- Python ---------------------------------------------------------------------
-- 类型检查 + 补全 + 悬浮文档由 basedpyright 负责；ruff 负责代码风格（lint + format），
-- 二者分工：basedpyright 管类型，ruff 管风格（见下方 ruff 段）。
--
-- 安装来源按环境分流：
--   - Windows / WSL：用 Mason 装的 `basedpyright` 可执行文件，直接 `--stdio` 即可，
--     无需 node/npm 路径（Mason 已把它放进 PATH，见文件末尾 platform.is_win_like 分支）。
--   - Linux/Kylin：没有 Mason，退回 npm 装的纯 JS 实现（node + langserver.index.js），
--     完全避开 aarch64 / glibc 兼容问题。
-- settings 两份 cmd 共用同一份，避免重复。
-- Python 解释器探测（2026-10-13）
--
-- 为什么必须实探、不能写死：
--   1) 本机 `/usr/bin/python` 指向 **Python 2.7**（发行版历史包袱），
--      而 Python 2 根本没有 typing 模块。认错解释器会让补全/类型全废。
--   2) 系统的 `python3` 是 3.8，老吴终端 PATH 里可能还有别的版本；
--      basedpyright 报什么语法/API 结论，全看喂给它的 pythonVersion。
--   3) Windows 上解释器可能叫 `python` 而不是 `python3`。
--
-- 所以按"python3 优先 → 常见位置兜底"逐个试，并用 `--version` 实测，
-- 只认 **Python 3.x**（2.x 直接跳过），把版本号一并取出来。
local function detect_python()
  local candidates = {
    vim.fn.exepath 'python3',
    vim.fn.exepath 'python',
    '/usr/bin/python3',
    '/usr/local/bin/python3',
    vim.fn.expand '~/dev/python/bin/python3',
    '/opt/python/bin/python3',
    'python3',
  }
  local fallback = nil
  for _, exe in ipairs(candidates) do
    if exe ~= '' and vim.uv.fs_stat(exe) then
      local out = vim.fn.system({ exe, '-c', 'import sys;print("%d.%d.%d" % sys.version_info[:3])' })
      if vim.v.shell_error == 0 then
        local ver = vim.trim(out)
        local maj, min = ver:match '^(%d+)%.(%d+)'
        maj, min = tonumber(maj), tonumber(min)
        if maj and maj >= 3 then return exe, ver end -- 只认 Python 3+
        fallback = fallback or { exe, ver } -- 记住 python2 以便后面报错说清
      end
    end
  end
  return (fallback and fallback[1]) or nil, (fallback and fallback[2]) or nil
end

local py_exe, py_version = detect_python()
-- basedpyright 认的版本字符串只到"主.次"（如 '3.8'），传 '3.13' 这种也可以，
-- 但传两位更稳，也更贴近它内部对语法特性的判断粒度。
local py_version_short = py_version and (py_version:match '^%d+%.%d+' or py_version) or nil

if not py_exe then
  vim.notify(
    'Python LSP（basedpyright）未配置：找不到 Python 3 解释器。\n'
      .. '  装一个（如 apt install python3），或设 vim.g.python_bin 指向你的解释器。',
    vim.log.levels.WARN
  )
end

local basedpyright_settings = {
  basedpyright = {
    analysis = {
      -- basic   ：只报明显的错误
      -- standard：默认，报类型不匹配等（推荐）
      -- strict  ：最严格，连隐式 Any 都报
      typeCheckingMode = 'standard',
      autoSearchPaths = true, -- 自动推测项目根目录
      useLibraryCodeForTypes = true, -- 从第三方库源码里推断类型
      diagnosticSeverityOverrides = {
        -- 未使用的 import 交给 ruff（F401）来报，
        -- 不然 basedpyright 和 ruff 会重复提示同一件事
        reportUnusedImport = 'none',
        -- ⚠ 关键：把"类型弃用"类提示关掉。
        --   不钉住 pythonVersion 时，basedpyright 会按它内置的**最新版本**标准判断，
        --   于是把 `from typing import List` 标成 deprecated、建议改成 `list[int]`。
        --   但内置泛型 list[int] 是 **Python 3.9+ (PEP 585)** 才有的，
        --   本机是 3.8 —— 实测照它改会直接崩：
        --     TypeError: 'type' object is not subscriptable
        --   即"诊断版本 > 运行环境版本"时，建议方向是反的。
        --   真正治本的是下面的 pythonVersion，但这里再压一层，避免漏网。
        reportDeprecated = 'none',
      },
    },
  },
  -- pyright 系列通用的设置（注意是 python.*，不是 basedpyright.*）
  -- basedpyright 需要 Python 解释器路径才能找到第三方库类型；
  -- 有 .venv 时它会优先用虚拟环境，这里给兜底值。
  python = {
    -- 实测出来的解释器路径；找不到时回落到 'python3' 让它自己去 PATH 找
    pythonPath = py_exe or vim.g.python_bin or 'python3',
    -- ⚠ 钉住版本，让所有语法/API 结论都按你**真实运行**的版本给。
    --   不设这一项 → basedpyright 用内置默认（最新）版本，
    --   会把 3.8 的合法写法判成 deprecated（见上面 reportDeprecated 的说明）。
    --   探测不到时留空，不瞎猜一个版本号。
    pythonVersion = py_version_short,
  },
}

-- 便于排查：启动后想知道 nvim 到底认了哪个 python，直接 :lua print(vim.g.detected_python)
vim.g.detected_python = py_exe and string.format('%s (Python %s)', py_exe, py_version or '?') or '未找到'

if platform.is_win_like then
  -- Windows / WSL：Mason 装好的 basedpyright 可执行文件
  if vim.fn.executable 'basedpyright' == 1 then
    servers.basedpyright = {
      cmd = { 'basedpyright-langserver', '--stdio' },  -- ⚠ basedpyright 是 CLI 检查器不认 --stdio，服务器入口是 langserver
      settings = basedpyright_settings,
    }
  end
else
  -- Linux/Kylin：npm 装好的纯 JS 实现，用 node 跑入口脚本
  -- 用 stdpath('data') 而不是写死的 ~/.local/share，native Linux / WSL 都能正确定位
  local basedpyright_langserver = vim.fn.stdpath('data') .. '/nvim-lsp/node_modules/basedpyright/langserver.index.js'

  -- ⚠ node 显式探测，不只靠 PATH（2026-10-13）
  --
  --   本次故障的**真正原因是 basedpyright 没装**（stdpath('data')/nvim-lsp 整个目录不存在），
  --   node 一直是好的：老吴在 ~/.bashrc:120 有
  --     export PATH="$HOME/dev/node/bin:$PATH"     → /home/user/dev/node/bin/node (v26.8.1)
  --   所以从终端启动 nvim 时 executable('node') 本来就是 1。
  --
  --   但仍保留显式探测，因为 PATH 并非所有启动方式都可靠：
  --     - 从桌面图标/应用启动器拉起 nvim（不经过登录 shell）→ 读不到 .bashrc
  --     - 未来 node 换版本 / 装到别的位置 → PATH 可能滞后
  --   探测顺序：PATH → 老吴的 dev/node → 常见系统位置 → nvm/volta → WorkBuddy 托管目录。
  local function find_node()
    local p = vim.fn.exepath 'node'
    if p ~= '' and vim.uv.fs_stat(p) then return p end
    for _, cand in ipairs {
      vim.fn.expand '~/dev/node/bin/node', -- 本机实际安装位置（.bashrc:120 加入 PATH）
      vim.fn.expand '~/.local/bin/node',
      '/usr/local/bin/node',
      '/usr/bin/node',
      '/opt/node/bin/node',
      vim.fn.expand '~/.nvm/current/bin/node',
      vim.fn.expand '~/.volta/bin/node',
    } do
      if vim.uv.fs_stat(cand) then return cand end
    end
    -- glob 兜底：WorkBuddy 托管的 node 版本目录
    local g = vim.fn.glob(vim.fn.expand '~/.workbuddy/binaries/node/versions/*/bin/node', false, true)
    if g and #g > 0 then return g[#g] end -- 取最后一个（通常是最高版本）
    return nil
  end

  local node = find_node()
  if node and vim.uv.fs_stat(basedpyright_langserver) then
    servers.basedpyright = {
      -- 直接让 node 去跑 langserver 的入口脚本（basedpyright 本身没有可执行二进制）
      cmd = { node, basedpyright_langserver, '--stdio' },
      settings = basedpyright_settings,
    }
  else
    -- 缺东西就**报出来**，别再静默跳过（本仓库反复踩的静默失效坑：
    -- basedpyright 当年就是因为路径差一层而从未启用，却毫无提示）
    local missing = {}
    if not node then table.insert(missing, 'node 解释器找不到') end
    if not vim.uv.fs_stat(basedpyright_langserver) then
      table.insert(missing, 'basedpyright 未安装（' .. basedpyright_langserver .. '）')
    end
    vim.notify(
      'Python 语言服务 basedpyright 未启用：' .. table.concat(missing, '；') .. '。\n'
        .. '装法：cd ' .. vim.fn.stdpath('data') .. '/nvim-lsp && npm install basedpyright',
      vim.log.levels.WARN
    )
  end
end

-- ruff：极快的 linter + formatter，负责代码风格类问题。
-- 它和 basedpyright 是分工关系：basedpyright 管类型，ruff 管风格。
if vim.fn.executable 'ruff' == 1 then servers.ruff = {
  cmd = { 'ruff', 'server' },
} end

-- Lua ------------------------------------------------------------------------
-- 本机没装 lua-language-server（官方版本是靠 Mason 装的）。
-- 这里做成"装了就启用"：如果你以后经常改 nvim 配置、想要 Lua 补全，
-- 自己装上 lua-language-server 后这段会自动生效，没装也不会报错。
if vim.fn.executable 'lua-language-server' == 1 then
  servers.lua_ls = {
    on_init = function(client)
      -- 格式化交给 stylua（本机 /usr/local/bin/stylua），不让 lua_ls 插手
      client.server_capabilities.documentFormattingProvider = false

      if client.workspace_folders then
        local path = client.workspace_folders[1].name
        if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
      end

      client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
        runtime = {
          version = 'LuaJIT',
          path = { 'lua/?.lua', 'lua/?/init.lua' },
        },
        workspace = {
          checkThirdParty = false,
          -- 注意：这会慢很多，并且在配置你自己的配置时会引起问题。
          --  参见 https://github.com/neovim/nvim-lspconfig/issues/3189
          library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
            '${3rd}/luv/library',
            '${3rd}/busted/library',
          }),
        },
      })
    end,
    ---@type lspconfig.settings.lua_ls
    settings = {
      Lua = {
        format = { enable = false }, -- 同样交给 stylua
      },
    },
  }
end

-- ---------------------------------------------------------------------------
-- 只装 nvim-lspconfig（提供各语言服务器的默认配置）。
-- Mason 三件套里，mason 核心已在 debug.lua 装好；这里再补 mason-lspconfig，
-- 但**只在 Windows/WSL 下才真正启用**（见文件末尾 platform.is_win_like 分支）。
-- ---------------------------------------------------------------------------
vim.pack.add { gh 'neovim/nvim-lspconfig' }
-- mason-lspconfig：把 Mason 装的二进制接到 lspconfig 上。
-- 这里只是登记进 pack；真正的 setup 在下方 platform.is_win_like 分支里（Linux 不调用，避免 aarch64 拉二进制）。
vim.pack.add { gh 'williamboman/mason-lspconfig.nvim' }

for name, server in pairs(servers) do
  vim.lsp.config(name, server)
  vim.lsp.enable(name)
end

-- ---------------------------------------------------------------------------
-- Windows / WSL：用 Mason 负责安装 C++ / Python 相关语言服务器
-- （Linux/Kylin 跳过整段，避免 aarch64 拉预编译二进制翻车）
-- ---------------------------------------------------------------------------
if platform.is_win_like then
  -- mason 核心已在 debug.lua 设好；这里只让 mason-lspconfig 把包装好的二进制接到 lspconfig。
  -- 用 pcall 防止首次运行插件尚未克隆到本地时 require 失败（下一次启动就好了）。
  local ok, mlsp = pcall(require, 'mason-lspconfig')
  if ok then
    mlsp.setup {
      -- 开机自动装好这些；装完后它们在 PATH 里，上面的可执行检测会自动接管
      -- （clangd / basedpyright / ruff 见各段，lua_ls 用于编辑 nvim 配置时补全）。
      ensure_installed = { 'clangd', 'basedpyright', 'ruff', 'lua-language-server' },
      -- 不自动启用：server 的详细配置/启用由本文件上面的 servers 表负责，
      -- 避免和 vim.lsp.enable 重复或冲突。
      automatic_enable = false,
    }
  end
end

-- vim: ts=2 sts=2 sw=2 et
