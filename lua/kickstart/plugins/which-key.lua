local function gh(repo) return 'https://github.com/' .. repo end

-- 用于显示待处理按键绑定的实用插件。
vim.pack.add { gh 'folke/which-key.nvim' }
require('which-key').setup {
  -- 按下按键到打开 which-key 之间的延迟（毫秒）
  delay = 0,
  icons = { mappings = vim.g.have_nerd_font },
  -- 记录现有的按键链
  --
  -- 这里登记的是"按键组的名字"。按下 <leader> 之后 which-key 会弹出提示框，
  -- **没登记过的组会显示成一堆没有说明的散键**，看不出哪个键属于哪个功能。
  -- 所以后面自己加的每个 <leader>x 组，都要在这儿补一行。
  spec = {
    { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
    { '<leader>t', group = '[T]oggle' },
    { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } }, -- 先启用 gitsigns 推荐的按键映射
    { 'gr', group = 'LSP Actions', mode = { 'n' } },

    -- ↓↓↓ 自己加的插件（见 lua/custom/plugins/），每个组登记一行 ↓↓↓
    { '<leader>c', group = '[C]++ 工具' }, -- custom/plugins/cpp.lua：生成编译数据库
    { '<leader>d', group = '[D]ebug 调试' }, -- custom/plugins/debug.lua：断点、监视
    { '<leader>n', group = '[N]oice 消息' }, -- custom/plugins/noice.lua：消息历史
    { '<leader>o', group = '[O]verseer 任务' }, -- custom/plugins/overseer.lua：编译运行
    { '<leader>x', group = '诊断 [X]' }, -- custom/plugins/trouble.lua：诊断列表
    { '<leader>z', group = '[Z] 杂项工具箱' }, -- custom/plugins/snacks.lua：专注/草稿/终端
    { '<leader>g', group = '[G]it' }, -- gitsigns：在浏览器里打开当前行
  },
}

-- vim: ts=2 sts=2 sw=2 et
