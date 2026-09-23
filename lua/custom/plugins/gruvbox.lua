local function gh(repo) return 'https://github.com/' .. repo end

-- [[ gruvbox —— 护眼的复古暖色配色方案 ]]
--
-- 用来替代默认的 tokyonight。本文件在 kickstart/plugins 之后加载，
-- 所以这里的 colorscheme 会覆盖 tokyonight-night。
-- 想换回 tokyonight：把最后一行注释掉（或改成 vim.cmd.colorscheme 'tokyonight-night'）。
vim.pack.add { gh 'ellisonleao/gruvbox.nvim' }

---@diagnostic disable-next-line: missing-fields
require('gruvbox').setup {
  terminal_colors = true, -- 终端也用 gruvbox 配色
  underline = true,
  bold = true,
  italic = { comments = true, strings = true, operators = false },
  invert_selection = false,
  invert_signs = false,
  invert_tabline = false,
  inverse = true, -- 搜索/差异/状态栏用反色背景
  contrast = '', -- '' 默认；'hard' 更暗、'soft' 略亮
  dim_inactive = false,
  transparent_mode = false,
}

-- 必须在 setup() 之后调用，自定义配置才会生效
vim.opt.background = 'dark' -- gruvbox 默认深色；想要浅色改成 'light'
vim.cmd.colorscheme 'gruvbox'
