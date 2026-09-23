local function gh(repo) return 'https://github.com/' .. repo end

-- [[ rainbow-delimiters —— 彩虹括号（按嵌套层数交替上色）]]
--
-- 基于 tree-sitter，给 () [] {} 以及各类分隔符按嵌套深度循环配色，
-- 多层括号嵌套时一眼就能数对。需要对应语言的 treesitter 解析器（已装）。
-- 插件自带 RainbowDelimiter* 高亮组与 strategy，无需自己定义。
vim.pack.add { gh 'HiPhish/rainbow-delimiters.nvim' }

local rainbow_delimiters = require 'rainbow-delimiters'

require('rainbow-delimiters.setup').setup {
  -- 全局用 global 策略；lua 用 local 策略（只高亮当前作用域，长文件不至于太花）
  strategy = {
    [''] = rainbow_delimiters.strategy['global'],
    lua = rainbow_delimiters.strategy['local'],
  },
  -- 默认查询叫 rainbow-delimiters；lua 额外用 rainbow-blocks 把 function/if/end 也上色
  query = {
    [''] = 'rainbow-delimiters',
    lua = 'rainbow-blocks',
  },
  -- 优先级要高于 treesitter 默认高亮，括号颜色才盖得住
  priority = {
    [''] = 110,
    lua = 210,
  },
  -- 7 色循环（gruvbox 深色背景下也清晰）
  highlight = {
    'RainbowDelimiterRed',
    'RainbowDelimiterYellow',
    'RainbowDelimiterBlue',
    'RainbowDelimiterOrange',
    'RainbowDelimiterGreen',
    'RainbowDelimiterViolet',
    'RainbowDelimiterCyan',
  },
}
