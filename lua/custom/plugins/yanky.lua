local function gh(repo) return 'https://github.com/' .. repo end

-- [[ yanky.nvim —— 剪贴板历史 ]]
--
-- 解决什么问题：复制了 A，又复制了 B，然后想粘回 A —— 但 A 已经被覆盖了。
-- yanky 把每次复制的内容都存进一个"历史环"，随时能挑一个出来粘。
--
-- 顺手还增加了几种粘贴方式，最实用的是"按缩进粘贴"：
-- 粘贴一段缩进不对的代码时，自动对齐到当前行的缩进，不用手动 `>G` 调。
--
-- 纯 Lua，无二进制依赖。依赖已装的 telescope 提供一个历史列表界面（可选，不装也能用）。
-- ---------------------------------------------------------------------------

vim.pack.add { gh 'gbprod/yanky.nvim' }

require('yanky').setup {
  ring = {
    -- 最多记 100 条，够用了（太大会拖慢启动）
    history_length = 100,
    -- storage 有两个选择：
    --   'shada'  —— 存进 vim 的 shada 文件，**退出重开 nvim 历史还在**（推荐）
    --   'memory' —— 只活在当前这次会话，关掉就没了
    storage = 'shada',
    -- 和 vim 的编号寄存器 "0 ~ "9 同步：
    -- 也就是说 `"0p` 这种老写法依然能拿到上一次复制的内容
    sync_with_numbered_registers = true,
  },

  -- 复制 / 粘贴后把刚操作的那段高亮一下，一眼看清粘到哪了
  highlight = {
    on_put = true,
    on_yank = true,
    -- 高亮持续 300 毫秒
    timer = 300,
  },

  -- telescope 列表界面的行为（use_default_mappings = true 表示沿用 telescope 的操作键）
  picker = {
    telescope = { use_default_mappings = true },
  },
}

-- ---------------------------------------------------------------------------
-- 接管复制 / 粘贴
-- ---------------------------------------------------------------------------
-- 注意：这里必须把 y / p / P 显式映射到 yanky 的 <Plug>，
-- 否则复制的内容不会进历史环，插件等于没生效。

vim.keymap.set({ 'n', 'x' }, 'y', '<Plug>(YankyYank)', { desc = '复制（记入剪贴板历史）' })
vim.keymap.set({ 'n', 'x' }, 'p', '<Plug>(YankyPutAfter)', { desc = '粘贴到光标后' })
vim.keymap.set({ 'n', 'x' }, 'P', '<Plug>(YankyPutBefore)', { desc = '粘贴到光标前' })

-- gp / gP：按当前行的缩进自动对齐后再粘贴。
-- 粘一段 Python / C++ 代码块时特别省事，不用粘完再手动调缩进
vim.keymap.set({ 'n', 'x' }, 'gp', '<Plug>(YankyGPutAfter)', { desc = '按缩进粘贴到光标后' })
vim.keymap.set({ 'n', 'x' }, 'gP', '<Plug>(YankyGPutBefore)', { desc = '按缩进粘贴到光标前' })

-- 刚粘完发现粘错了？不用撤销重粘，直接切换历史里的上一条 / 下一条，
-- 粘好的那段会被**原地替换**成历史里的另一条内容
--
-- ⚠ 踩过的坑：这里必须用 PreviousEntry / NextEntry，不能用 CycleBackward / CycleForward。
--   后两者的方向和"历史顺序"是反的 —— 实测过：粘完刚复制的最新一条之后按
--   CycleBackward 会提示 "Reached first item"（已经在头了），根本换不动。
vim.keymap.set('n', '<c-p>', '<Plug>(YankyPreviousEntry)', { desc = '换成历史里更早的一条' })
vim.keymap.set('n', '<c-n>', '<Plug>(YankyNextEntry)', { desc = '换回历史里更新的一条' })

-- ---------------------------------------------------------------------------
-- 弹出剪贴板历史列表（用 telescope 界面，可以边看边搜）
-- ---------------------------------------------------------------------------
-- telescope 需要先加载 yanky 提供的扩展才能用，这里注册一下。
-- 用 pcall 包起来：万一 telescope 没装上，也只是少了这个列表，不会导致启动报错。
pcall(function() require('telescope').load_extension 'yank_history' end)

vim.keymap.set('n', '<leader>p', function() require('telescope').extensions.yank_history.yank_history {} end, { desc = '[P] 剪贴板历史' })

-- vim: ts=2 sts=2 sw=2 et
