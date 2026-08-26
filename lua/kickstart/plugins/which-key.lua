local function gh(repo) return 'https://github.com/' .. repo end

-- 用于显示待处理按键绑定的实用插件。
vim.pack.add { gh 'folke/which-key.nvim' }
require('which-key').setup {
  -- 按下按键到打开 which-key 之间的延迟（毫秒）
  delay = 0,
  icons = { mappings = vim.g.have_nerd_font },
  -- 记录现有的按键链
  spec = {
    { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
    { '<leader>t', group = '[T]oggle' },
    { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } }, -- 先启用 gitsigns 推荐的按键映射
    { 'gr', group = 'LSP Actions', mode = { 'n' } },
  },
}

-- vim: ts=2 sts=2 sw=2 et
