local function gh(repo) return 'https://github.com/' .. repo end

-- [[ 配色方案 ]]
-- 你可以轻松更换成其他配色方案。
-- 修改下面配色方案插件的名称，然后把下面的命令改成
-- 加载对应名称的配色方案。
--
-- 如果你想查看已安装的配色方案，可以使用 `:Telescope colorscheme`。
vim.pack.add { gh 'folke/tokyonight.nvim' }
---@diagnostic disable-next-line: missing-fields
require('tokyonight').setup {
  styles = {
    comments = { italic = false }, -- 在注释中禁用斜体
  },
}

-- 在这里加载配色方案。
-- 和许多其他主题一样，这个主题有不同的风格，你也可以加载
-- 其他风格，比如 'tokyonight-storm'、'tokyonight-moon' 或 'tokyonight-day'。
vim.cmd.colorscheme 'tokyonight-night'

-- vim: ts=2 sts=2 sw=2 et
