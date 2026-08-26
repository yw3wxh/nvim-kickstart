local function gh(repo) return 'https://github.com/' .. repo end

-- [[ 安装和配置插件 ]]
--
-- 要安装插件，只需用它的 git 地址调用 `vim.pack.add`。
-- 这会下载插件的默认分支，通常是 `main` 或 `master`。
-- 你也可以使用更高级的配置（spec），我们稍后会讲到。
--
-- 对大多数插件来说，仅仅安装是不够的，你还需要调用它们的 `.setup()` 来启用它们。
--
-- 例如，假设我们要安装 `guess-indent.nvim` —— 一个用于
-- 自动检测和设置缩进的插件。
--
-- 我们首先从 https://github.com/NMAC427/guess-indent.nvim 安装它，
-- 然后调用它的 `setup()` 函数，用默认设置启用它。
vim.pack.add { gh 'NMAC427/guess-indent.nvim' }
require('guess-indent').setup {}

-- vim: ts=2 sts=2 sw=2 et
