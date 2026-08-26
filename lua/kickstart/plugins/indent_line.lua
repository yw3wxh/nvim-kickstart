-- 即使在空行上也显示缩进参考线

-- 启用 `lukas-reineke/indent-blankline.nvim`
-- 参见 `:help ibl`
vim.pack.add { 'https://github.com/lukas-reineke/indent-blankline.nvim' }
require('ibl').setup {}
