-- 按顺序加载插件模块。

require 'kickstart.plugins.guess-indent'
require 'kickstart.plugins.gitsigns'
require 'kickstart.plugins.which-key'
require 'kickstart.plugins.tokyonight'
require 'kickstart.plugins.todo-comments'
require 'kickstart.plugins.mini'
require 'kickstart.plugins.telescope'
require 'kickstart.plugins.lspconfig'
require 'kickstart.plugins.conform'
require 'kickstart.plugins.blink-cmp'
require 'kickstart.plugins.treesitter'

-- 以下注释只有在下载了完整的 kickstart 仓库（而不是只复制 init.lua）时才有效。
-- 如果你想要这些文件，它们就在仓库中，你可以直接下载并放到正确的位置。

-- 注意：你的 Neovim 之旅的下一步：为 Kickstart 添加/配置更多插件
--
--  以下是我在 Kickstart 仓库中包含的一些示例插件。
--  取消下面任意一行的注释即可启用它们（你需要重启 nvim）。
--
-- require 'kickstart.plugins.debug'
-- require 'kickstart.plugins.indent_line'
-- require 'kickstart.plugins.lint'
-- require 'kickstart.plugins.autopairs'
-- require 'kickstart.plugins.neo-tree'
-- require 'kickstart.plugins.gitsigns' -- 添加 gitsigns 推荐的按键映射

-- 注意：你可以从 `lua/custom/plugins/*.lua` 添加自己的插件、配置等
--
--  取消下面这行的注释并把你的插件添加到 `lua/custom/plugins/*.lua` 即可开始。
-- require 'custom.plugins'

-- vim: ts=2 sts=2 sw=2 et
