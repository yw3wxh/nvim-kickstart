local function gh(repo) return 'https://github.com/' .. repo end

-- [[ yanky.nvim —— 剪贴板历史 ]]
--
-- 解决什么问题：复制了 A，又复制了 B，然后想粘回 A —— 但 A 已经被覆盖了。
-- yanky 把每次复制的内容都存进一个"历史环"，随时能挑一个出来粘。
--
-- ⚠ 当前用法（2026-10-13 起）：**只有 y（复制）走 Yanky**，p/P/gp/gP 走原生。
--   原因见下面「接管复制 / 粘贴」那段长注释（clipboard=unnamedplus
--   会让 Yanky 从系统剪贴板 +取，而 x 只写 unnamed "，导致 xp 之类的技巧粘错内容）。
--   Yanky 独有的按缩进粘贴挪到了 <leader>pa / <leader>pA，带高亮的用 <leader>pp / <leader>ph。
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

  -- ⚠ 2026-10-15 关掉 yanky 的"焦点同步"（system_clipboard.sync_with_ring）：
  --   它在 FocusGained 时会把系统剪贴板内容灌进历史环；clipboard='' 下
  --   yanky 会去读 '*'（primary selection）—— 在终端里划选文字就会往
  --   历史环里塞垃圾。系统剪贴板的进出已由 options.lua 的 TextYankPost
  --   出站同步 + <leader>P 显式入站接管，这里不需要它了。
  system_clipboard = {
    sync_with_ring = false,
  },

  -- telescope 列表界面的行为（use_default_mappings = true 表示沿用 telescope 的操作键）
  picker = {
    telescope = { use_default_mappings = true },
  },
}

-- ---------------------------------------------------------------------------
-- 接管复制 / 粘贴
-- ---------------------------------------------------------------------------
-- ⚠ 为什么 p / P / gp / gP 不走 Yanky（2026-10-13 修的问题，勿轻易改回去）
--
-- 现象：在 C++ 里按xp 想交换相邻字符，结果粘出一整行、且是**新建的一行**。
--
-- 根因链条（每一步都实测过）：
--   options.lua 里无条件设了 vim.o.clipboard = 'unnamedplus'
--     → Yanky 的 utils.get_default_register() 看到 unnamedplus，
--       就把默认寄存器从 unnamed(") 换成系统剪贴板(+)
--     → 但 x（删除字符）只写 "，**不写 +**
--     → 于是 xp 里的 p 从 + 取到的是"上次复制的东西"（常常是 yy 的一整行）
--     → linewise内容粘出来自然就是新建一行
--
-- 对照实验（只改 clipboard 这一项，其余不变）：
--   clipboard=unnamedplus（现状） xp => {..., "int bc = 1;", "int cur", "}"}  多出一行 ❌
--   clipboard=""                      xp => {..., "int bac = 1;", "}"}正常交换 ✅
--
-- 注意：这在 Windows / WSL 下同样是坏的（options.lua:83 的 unnamedplus
--   不在任何平台分支里，三个平台都会中招），只是那边表现为"粘错内容"
--   而不一定表现为新建一行。所以改成原生是三个平台都受益。
--
-- ⚠ 2026-10-15 深化实测（nvim 0.12.4 + 本机 wl-clipboard provider，headless+真实合成器）：
--   1) `getreg('+')` 是**实时调 wl-paste 读系统剪贴板**（不是读内存）——所以谁在读 +，
--      谁就会粘到"别的程序里最后复制的东西"。
--   2) 系统剪贴板里"末尾带换行"的文本（终端里复制命令输出很典型）粘进 nvim
--      会被判为 **linewise** → 表现就是"粘出一整行/新建一行"。
--   3) **决定性实验（decide.lua）**：unnamedplus 下原生 p 并不总读内存 unnamed——
--      交互会话里 x/y 触发 provider copy 之后，p 改读 '+'：x 删 'b' 后
--      setreg('+','ZZ')、等 1.5s 再 p → 粘出 'ZZ' 新行 ❌。
--      ⇒ 连原生 p 都会被系统剪贴板坑，这是 x/y+p 粘错的终极根因。
--      headless 测不出来是因为 headless 下 x 不触发 provider copy。
--   ⇒ 2026-10-15 定案：options.lua 已把 clipboard 置空（勿改回 unnamedplus），
--      p/y/x 全走内存；y 经 TextYankPost 出站同步到系统剪贴板；
--      从外部粘贴用 <leader>P（即 "+p）。clipboard='' 下 Yanky 的默认寄存器
--      也自动回到 unnamed，<leader>pp 同样可靠了。
--   若"粘出一整行"复发，按顺序查：① 会话是不是旧的（:lua print(vim.fn.maparg('p','n'))
--      应输出纯 'p'；输出 <Plug>(YankyPutAfter) 就是没重载配置）；② yank 后
--      :lua print(vim.fn.getregtype('"')) 应输出 v；③ :set clipboard? 应为**空**
--      （输出 unnamedplus 就是改回了老配置）。
--
-- 代价（明确知道再改，2026-10-15 更新）：
--   - 失去 Yanky 的**粘贴高亮**（粘完不闪那一下）——要高亮用 <leader>pp
--   - 失去 p 之后直接 <C-p>/<C-n> 原地换内容
--     （因为历史环只在走 Yanky 的 put 时才建立）
--   - p 不再读系统剪贴板：从浏览器/终端拷东西进来要用 <leader>P（即 "+p）；
--     nvim 里 y 的内容会自动同步到系统剪贴板（外部粘贴不受影响），
--     且 x/dd 不再把系统剪贴板冲掉
--   换来的：xp / xP / ddp / ccp 这类"删完立刻粘"的小技巧全部恢复正常，
--   且不再受系统剪贴板里"上一份内容"的干扰。
--
-- 想用 Yanky 的按缩进粘贴时，走下面保留的 <leader> 系列键。
-- ---------------------------------------------------------------------------

-- 复制仍然走 Yanky：要进历史环（<leader>p 选历史就靠它）
vim.keymap.set({ 'n', 'x' }, 'y', '<Plug>(YankyYank)', { desc = '复制（记入剪贴板历史）' })

-- 粘贴走**原生**，让寄存器类型和来源都遵循 vim 标准行为
vim.keymap.set({ 'n', 'x' }, 'p', 'p', { desc = '粘贴到光标后' })
vim.keymap.set({ 'n', 'x' }, 'P', 'P', { desc = '粘贴到光标前' })
vim.keymap.set({ 'n', 'x' }, 'gp', 'gp', { desc = '按缩进粘贴到光标后' })
vim.keymap.set({ 'n', 'x' }, 'gP', 'gP', { desc = '按缩进粘贴到光标前' })

-- Yanky 的按缩进粘贴挪到 <leader> 系列：想要"自动对齐缩进 + 粘贴高亮"时用
vim.keymap.set('n', '<leader>pa', '<Plug>(YankyGPutAfter)', { desc = '[P]aste 按缩进(光标后, Yanky)' })
vim.keymap.set('n', '<leader>pA', '<Plug>(YankyGPutBefore)', { desc = '[P]aste 按缩进(光标前, Yanky)' })
vim.keymap.set('n', '<leader>pp', '<Plug>(YankyPutAfter)', { desc = '[P]aste Yanky 粘贴(带高亮)' })
vim.keymap.set('n', '<leader>ph', '<Plug>(YankyPutBefore)', { desc = '[P]aste Yanky 粘贴(光标前, 带高亮)' })

-- 入站专用键：粘贴**系统剪贴板**（浏览器/终端里拷的东西）。
-- clipboard='' 后普通 p 只读内存寄存器，跨程序粘贴走这里（等价 "+p）。
vim.keymap.set({ 'n', 'x' }, '<leader>P', '"+p', { desc = '[P]aste 粘贴系统剪贴板(外部拷入)' })

-- 刚粘完发现粘错了？换成历史里的上一条 / 下一条（需先走过 Yanky 的粘贴，
-- 见上面 <leader>pp / <leader>pP2 —— 原生 p 不建立历史环，这里会提示没有可替换的内容）
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
