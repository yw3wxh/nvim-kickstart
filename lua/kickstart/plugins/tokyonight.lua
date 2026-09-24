local function gh(repo) return 'https://github.com/' .. repo end

-- [[ tokyonight —— 默认配色方案（实际被 gruvbox 覆盖）]]
--
-- 这是 kickstart 自带的默认主题。我们后来装了 gruvbox
--   （见 custom/plugins/gruvbox.lua），它在 custom 目录加载、比本文件晚，
--   会用 gruvbox 覆盖掉这里的 tokyonight-night。
-- 其它风格：tokyonight-storm / -moon / -day，把下面 colorscheme 改掉即可；
-- 想换回 tokyonight：把 gruvbox.lua 末尾的 colorscheme 注释掉即可。
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
