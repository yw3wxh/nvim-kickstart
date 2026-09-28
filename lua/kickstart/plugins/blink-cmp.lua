-- [[ 自动补全 + 代码片段引擎（blink.cmp + LuaSnip）]]
--
-- 本文件装两样东西：
--   1) blink.cmp —— 自动补全（LSP / 路径 / 代码片段三路来源）。模糊匹配用 **rust** 实现：
--      rust 匹配器需要 `libblink_cmp_fuzzy.so`，而本机（aarch64）自动下载走 curl 直连
--      github releases 被代理 502 挡死、也没装 cargo，所以是**手动放置**的预编译二进制
--      （详见下方 fuzzy 配置的注释）。
--   2) LuaSnip   —— 代码片段引擎（个人片段放 ~/.config 下；friendly-snippets 暂未启用）。
-- 基本配置：补全预设 'default'（<c-y> 接受、<tab> 在片段里移动占位符），
--   签名帮助开启，文档悬浮窗不自动弹（<c-space> 手动开），外观用 Nerd Font mono 变体。

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

    -- ⚠ 回车接受补全 —— 'default' 预设**没有**这条，所以不补的话按回车只是换行。
    --
    --   现象：敲 usnam 弹出候选项，按回车却只是换行，补全没被接受。
    --   原因：blink.cmp 的 'default' 预设压根没给 <CR> 绑命令
    --         （见插件源码 lua/blink/cmp/keymap/presets.lua 里 default 那一段：
    --          接受补全的是 <C-y>，回车不在其中）。
    --
    --   这里补一条：菜单开着且有选中项 → 接受；否则 fallback（走原本的回车行为）。
    --   fallback 很关键：它把键**交还给原本的映射**，也就是 nvim-autopairs 的 <CR>
    --   （在括号中间回车时把右括号挪到下一行），而不是退化成干巴巴的换行。
    --
    --   为什么用 'accept' 而不是 'select_and_accept'：
    --     accept             = 接受当前选中项；没选中就什么都不做 → 交给 fallback
    --     select_and_accept  = 没选中时**强制**选第一项再接受
    --   本机默认 preselect = true（自动预选第一项），所以 accept 够用。
    --   改 select_and_accept 的代价：只要菜单开着，你想换行也会被塞进第一项。
    --
    --   其它接受方式不受影响：<C-y> 接受；<Tab> 在片段占位符之间前进。
    ['<CR>'] = { 'accept', 'fallback' },

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
  -- ⚠ 本机（aarch64 / 银河麒麟）特殊：rust 版是**手动放置**的，不是自动下载的。
  --
  --   1) 自动下载走 `curl` 直连 github releases
  --      （https://github.com/saghen/blink.cmp/releases/download/<tag>/<triple>.so），
  --      本机代理对该域名一律 502 / 连接被掐，拉不到；
  --   2) 本机也没装 cargo/rustc，本地编译同样走不通。
  --
  -- 所以做法是：手动下载 `aarch64-unknown-linux-gnu.so`（对应本机 aarch64 + glibc），
  -- **改名为 `libblink_cmp_fuzzy.so`**，放进
  --   ~/.local/share/nvim/site/pack/core/opt/blink.cmp/target/release/
  --
  -- 关键细节：**故意不要放 `version` 文件**。blink.cmp 的 download/init.lua 里有这么一段：
  --   `if version.current.missing and pcall(require, 'blink.cmp.fuzzy.rust') then return end`
  -- 没有 version 文件 + rust 库能加载 → 判定为"用户手动放置的 .so"，直接用 rust 实现，
  -- **不会每次启动去联网下载**（正好避开本机被挡的网络）。
  --
  -- `prefer_rust_with_warning`：rust 库万一加载失败，会优雅回退到 Lua 并告警，不会硬崩。
  --
  -- ⚠ 注意：如果 `:packupdate` 重装了 blink.cmp，`target/` 目录会被清掉，
  --    需要重新按上面的步骤放一次 .so（届时若网络通了，也可设
  --    `fuzzy.prebuilt_binaries.download = true` 让它自动拉）。
  --
  -- 更多信息参见 `:help blink-cmp-config-fuzzy`
  fuzzy = { implementation = 'prefer_rust_with_warning' },

  -- 在输入函数参数时显示签名帮助窗口
  signature = { enabled = true },
}

-- vim: ts=2 sts=2 sw=2 et
