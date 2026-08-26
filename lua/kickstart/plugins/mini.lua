local function gh(repo) return 'https://github.com/' .. repo end

-- [[ mini.nvim ]]
--  各种小型、独立插件/模块的集合
vim.pack.add { gh 'nvim-mini/mini.nvim' }

-- 如果有 nerd font，则加载 icons 模块，为各种插件提供漂亮的图标。
if vim.g.have_nerd_font then
  require('mini.icons').setup()
  -- 用于与需要 `nvim-web-devicons` 的插件（例如 telescope.nvim）保持向后兼容
  MiniIcons.mock_nvim_web_devicons()
end

-- 更好的 Around/Inside 文本对象
--
-- 示例：
--  - va)  - [V]isual 选择 [A]round [)]括号
--  - yiiq - [Y]ank [I]nside [I]+1 [Q]quote
--  - ci'  - [C]hange [I]nside [']引号
require('mini.ai').setup {
  -- 注意：避免与 Neovim>=0.12 内置的增量选择映射冲突（参见 `:help treesitter-incremental-selection`）
  mappings = {
    around_next = 'aa',
    inside_next = 'ii',
  },
  n_lines = 500,
}

-- 添加/删除/替换环绕符号（括号、引号等）
--
-- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]括号
-- - sd'   - [S]urround [D]elete [']引号
-- - sr)'  - [S]urround [R]eplace [)] [']
require('mini.surround').setup()

-- 简单易用的状态栏。
--  如果你不喜欢它，可以移除这个 setup 调用，
--  并尝试其他状态栏插件
local statusline = require 'mini.statusline'
-- 如果你有 Nerd Font，请将 `use_icons` 设为 true
statusline.setup { use_icons = vim.g.have_nerd_font }

-- 你可以通过覆盖默认行为来配置状态栏中的各个部分。
-- 例如，这里我们把光标位置部分设置为 LINE:COLUMN
---@diagnostic disable-next-line: duplicate-set-field
statusline.section_location = function() return '%2l:%-2v' end

-- ... 还有更多！
--  查看：https://github.com/nvim-mini/mini.nvim

-- vim: ts=2 sts=2 sw=2 et
