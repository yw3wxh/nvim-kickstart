local function gh(repo) return 'https://github.com/' .. repo end

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
-- ⚠ 本文件与官方 kickstart 最大的不同：不用 Mason
--
-- 官方版本会用 Mason 自动下载安装语言服务器。但本机是
-- aarch64(ARM64) + glibc 2.31，Mason 下发的预编译二进制
-- 多半是 x86_64 或要求更高的 glibc 版本，装完直接跑不起来。
--
-- 所以这里**完全移除 Mason**，改用本机已经装好的服务：
--
--   C/C++   → clangd        （系统自带，/usr/bin/clangd）
--   Python  → basedpyright  （npm 装到 ~/.local/share/nvim-lsp，纯 JS，无 glibc 依赖）
--           → ruff          （~/.local/bin/ruff，负责 lint 与格式化）
--   Lua     → lua_ls        （本机没装，装了才会启用）
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

    -- 重命名光标下的变量。
    --  大多数语言服务器支持跨文件重命名等。
    map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

    -- 执行代码操作，通常需要把光标放在错误或
    -- LSP 的某个建议上才能触发。
    map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

    -- 警告：这不是"跳转到定义"，这是"跳转到声明"。
    --  例如，在 C 语言中这会带你到头文件。
    map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

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

    -- 下面的代码创建了一个按键映射，用于切换代码中的 inlay hints
    -- （如果所使用的语言服务器支持的话）
    --
    -- 这可能不是你想要的功能，因为它们会挤占你的一些代码
    if client and client:supports_method('textDocument/inlayHint', event.buf) then
      map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
    end
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
-- 注意：clangd 靠项目里的 compile_commands.json 才知道编译选项。
-- 单文件刷题时没有这个文件，clangd 也能用，但可能找不到自定义头文件。
-- 需要的话可以按 <leader>cm 生成一个（见 custom/plugins/cpp.lua）。
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
-- basedpyright：类型检查 + 补全 + 悬浮文档。
-- 它是 pyright 的增强版，用 npm 装的纯 JS 实现，
-- 所以完全没有 aarch64 / glibc 的兼容问题。
local basedpyright_langserver = vim.fn.expand '~/.local/share/nvim-lsp/node_modules/basedpyright/langserver.index.js'
if vim.fn.executable 'node' == 1 and vim.uv.fs_stat(basedpyright_langserver) then
  -- basedpyright 得知道用哪个 Python 解释器，才能找到第三方库的类型信息。
  -- 项目里有 .venv 时它会优先用虚拟环境，这里给的是兜底值。
  local python3 = vim.fn.exepath 'python3'
  if python3 == '' then python3 = 'python3' end

  servers.basedpyright = {
    -- 直接让 node 去跑 langserver 的入口脚本（basedpyright 本身没有可执行二进制）
    cmd = { 'node', basedpyright_langserver, '--stdio' },
    settings = {
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
          },
        },
      },
      -- pyright 系列通用的设置（注意是 python.*，不是 basedpyright.*）
      python = {
        pythonPath = python3,
      },
    },
  }
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
-- 只装 nvim-lspconfig（提供各语言服务器的默认配置），不再装 Mason 三件套
-- ---------------------------------------------------------------------------
vim.pack.add { gh 'neovim/nvim-lspconfig' }

for name, server in pairs(servers) do
  vim.lsp.config(name, server)
  vim.lsp.enable(name)
end

-- vim: ts=2 sts=2 sw=2 et
