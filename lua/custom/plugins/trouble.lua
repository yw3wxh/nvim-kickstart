local function gh(repo) return 'https://github.com/' .. repo end

-- [[ trouble.nvim —— 把诊断、引用、符号等列表统一到一个漂亮的面板里 ]]
--
-- 原生 Neovim 的 :lua vim.diagnostic.setloclist 打开的是 quickfix 窗口，
-- 比较丑也不好操作。trouble 把它换成一个可交互的列表：
-- 可以折叠、可以预览、可以直接跳转。
--
-- 它也能接管 LSP 的"查找引用"结果 —— 按下 grr 之后，
-- 引用列表会在 trouble 面板里列出，而不是塞进 quickfix。
vim.pack.add {
  gh 'folke/trouble.nvim',
  gh 'MunifTanjim/nui.nvim', -- trouble 的界面依赖（noice 也用它，装一次即可）
}

require('trouble').setup {
  -- trouble v3 的默认配置已经够用，这里只挑几项常用的改
  icons = {
    -- 没装 Nerd Font 就别用图标，否则会显示成乱码方块
    use = vim.g.have_nerd_font,
  },
  -- 打开 trouble 面板时自动聚焦到列表，可以直接用 j/k 选、回车跳转
  focus = true,
  -- 在列表里移动光标时，右侧自动预览对应位置的代码
  preview = { type = 'split' },
}

-- ---------------------------------------------------------------------------
-- 按键映射（统一放在 <leader>x 下，x = 问题/诊断）
-- ---------------------------------------------------------------------------
-- <leader>xx  整个项目的诊断（错误 + 警告）
-- <leader>xX  只看当前文件的诊断
-- <leader>cs  当前文件的符号大纲（函数、类、变量一览）
-- <leader>cl  LSP 相关列表（定义 / 引用 / 实现等）
vim.keymap.set('n', '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', { desc = '诊断列表 [X]' })
vim.keymap.set('n', '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', { desc = '当前文件诊断 [X]' })
vim.keymap.set('n', '<leader>cs', '<cmd>Trouble symbols toggle<cr>', { desc = '符号大纲 [S]' })
vim.keymap.set('n', '<leader>cl', '<cmd>Trouble lsp toggle<cr>', { desc = 'LSP 列表 [L]' })

-- 让 which-key 把上面这些按键归到一个分组里显示
-- （which-key 在 plugins.lua 里比本文件先加载，所以这里能直接拿到；
--   用 pcall 包一层是为了万一顺序变了也不至于报错）
pcall(
  function()
    require('which-key').add {
      { '<leader>x', group = '诊断/问题 [X]' },
      { '<leader>c', group = '代码 [C]' },
      { '<leader>n', group = '[N]oice 消息' },
    }
  end
)

-- vim: ts=2 sts=2 sw=2 et
