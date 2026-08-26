local function gh(repo) return 'https://github.com/' .. repo end

-- [[ 代码片段引擎 ]]

-- 注意：你也可以使用 git 标签的版本范围来指定插件。
--  更多信息参见 `:help vim.version.range()`
vim.pack.add { { src = gh 'L3MON4D3/LuaSnip', version = vim.version.range '2.*' } }
require('luasnip').setup {}

-- `friendly-snippets` 包含各种预制的代码片段。
--   关于各语言/框架/插件片段的 README：
--    https://github.com/rafamadriz/friendly-snippets
--
-- vim.pack.add { gh 'rafamadriz/friendly-snippets' }
-- require('luasnip.loaders.from_vscode').lazy_load()

-- [[ 自动补全引擎 ]]
vim.pack.add { { src = gh 'saghen/blink.cmp', version = vim.version.range '1.*' } }
require('blink.cmp').setup {
  keymap = {
    -- 'default'（推荐）提供与内置补全类似的映射
    --   <c-y> 接受（[y]es）补全。
    --    如果你的 LSP 支持，这会自动导入。
    --    如果 LSP 发送了代码片段，这会展开片段。
    -- 'super-tab' 用 tab 接受
    -- 'enter' 用回车接受
    -- 'none' 不使用映射
    --
    -- 要理解为什么推荐 'default' 预设，
    -- 你需要阅读 `:help ins-completion`
    --
    -- 不，说真的。请阅读 `:help ins-completion`，它真的很好！
    --
    -- 所有预设都有以下映射：
    -- <tab>/<s-tab>：在片段展开中向左/向右移动
    -- <c-space>：打开菜单，如果已打开则打开文档
    -- <c-n>/<c-p> 或 <up>/<down>：选择上一个/下一个项目
    -- <c-e>：隐藏菜单
    -- <c-k>：切换签名帮助
    --
    -- 要定义自己的按键映射，参见 `:help blink-cmp-config-keymap`
    preset = 'default',

    -- 更高级的 Luasnip 按键映射（例如选择 choice 节点、展开），参见：
    --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
  },

  appearance = {
    -- 'mono'（默认）用于 'Nerd Font Mono'，'normal' 用于 'Nerd Font'
    -- 调整间距以确保图标对齐
    nerd_font_variant = 'mono',
  },

  completion = {
    -- 默认情况下，你可以按 `<c-space>` 显示文档。
    -- 可选地，设置 `auto_show = true` 可以在延迟后自动显示文档。
    documentation = { auto_show = false, auto_show_delay_ms = 500 },
  },

  sources = {
    default = { 'lsp', 'path', 'snippets' },
  },

  snippets = { preset = 'luasnip' },

  -- Blink.cmp 包含一个可选的、推荐的 rust 模糊匹配器，
  -- 启用时会自动下载预编译的二进制文件。
  --
  -- 默认情况下，我们使用 Lua 实现，但你可以通过
  -- `'prefer_rust_with_warning'` 启用 rust 实现
  --
  -- 更多信息参见 `:help blink-cmp-config-fuzzy`
  fuzzy = { implementation = 'lua' },

  -- 在输入函数参数时显示签名帮助窗口
  signature = { enabled = true },
}

-- vim: ts=2 sts=2 sw=2 et
