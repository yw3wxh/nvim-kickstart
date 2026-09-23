-- 即使在空行上也显示缩进参考线

-- 启用 `lukas-reineke/indent-blankline.nvim`
-- 参见 `:help ibl`
vim.pack.add { 'https://github.com/lukas-reineke/indent-blankline.nvim' }

-- 彩虹缩进（indent-rainbow）：每一级缩进参考线按层级循环上色，
-- 比单色参考线更容易看清代码块的嵌套深度。
-- 配色组在 HIGHLIGHT_SETUP 钩子里定义，这样每次切换 colorscheme 都会自动重置。
local highlight = {
  'RainbowRed',
  'RainbowYellow',
  'RainbowBlue',
  'RainbowOrange',
  'RainbowGreen',
  'RainbowViolet',
  'RainbowCyan',
}

local hooks = require 'ibl.hooks'
hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
  vim.api.nvim_set_hl(0, 'RainbowRed', { fg = '#E06C75' })
  vim.api.nvim_set_hl(0, 'RainbowYellow', { fg = '#E5C07B' })
  vim.api.nvim_set_hl(0, 'RainbowBlue', { fg = '#61AFEF' })
  vim.api.nvim_set_hl(0, 'RainbowOrange', { fg = '#D19A66' })
  vim.api.nvim_set_hl(0, 'RainbowGreen', { fg = '#98C379' })
  vim.api.nvim_set_hl(0, 'RainbowViolet', { fg = '#C678DD' })
  vim.api.nvim_set_hl(0, 'RainbowCyan', { fg = '#56B6C2' })
end)

require('ibl').setup { indent = { highlight = highlight } }
