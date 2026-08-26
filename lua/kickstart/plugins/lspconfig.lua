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
-- 因此，语言服务器是需要独立于 Neovim 安装的外部工具。
-- 这就是 `mason` 及相关插件发挥作用的地方。
--
-- 如果你想知道 lsp 和 treesitter 的区别，可以查看一个编写得非常
-- 出色的帮助章节：`:help lsp-vs-treesitter`

-- 实用的 LSP 状态更新。
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

-- 启用以下语言服务器
--  可以随意在这里添加/删除任何你想要的 LSP。它们会被自动安装。
--  关于键及其配置方法的信息参见 `:help lsp-config`
---@type table<string, vim.lsp.Config>
local servers = {
  -- clangd = {},
  -- gopls = {},
  -- pyright = {},
  -- rust_analyzer = {},
  --
  -- 有些语言（如 typescript）有完整独立的语言插件，可能很有用：
  --    https://github.com/pmizio/typescript-tools.nvim
  --
  -- 但对很多配置来说，LSP（`ts_ls`）就足够好了
  -- ts_ls = {},

  stylua = {}, -- 用于格式化 Lua 代码

  -- 特殊的 Lua 配置，按照 neovim 帮助文档的建议
  lua_ls = {
    on_init = function(client)
      client.server_capabilities.documentFormattingProvider = false -- 禁用格式化（格式化由 stylua 完成）

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
        format = { enable = false }, -- 禁用格式化（格式化由 stylua 完成）
      },
    },
  },
}

vim.pack.add {
  gh 'neovim/nvim-lspconfig',
  gh 'mason-org/mason.nvim',
  gh 'mason-org/mason-lspconfig.nvim',
  gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
}

-- 自动为 Neovim 安装 LSP 和相关工具到 stdpath
require('mason').setup {}

-- 在 nvim-lspconfig 服务器名称和 mason.nvim 包名称之间进行转换（例如 lua_ls <-> lua-language-server）
require('mason-lspconfig').setup {
  automatic_enable = false, -- 如果你希望自动启用手动安装的服务器（例如通过 :Mason / :MasonInstall 安装的），请改为 true
}

-- 确保上面列出的服务器和工具已安装
--
-- 要检查已安装工具的当前状态和/或手动安装
-- 其他工具，可以运行
--    :Mason
--
-- 你可以在该菜单中按 `g?` 获取帮助。
local ensure_installed = vim.tbl_keys(servers or {})
vim.list_extend(ensure_installed, {
  -- 你可以在这里添加其他希望 Mason 安装的工具
})

require('mason-tool-installer').setup { ensure_installed = ensure_installed }

for name, server in pairs(servers) do
  vim.lsp.config(name, server)
  vim.lsp.enable(name)
end

-- vim: ts=2 sts=2 sw=2 et
