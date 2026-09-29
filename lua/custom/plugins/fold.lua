-- [[ 折叠模式切换（补齐手工折叠命令） ]]
--
-- 配置用 treesitter 的 foldmethod=expr 做语法树折叠，绝大多数 z 开头原生折叠命令
-- （za / zc / zo / zC / zO / zM / zR / zm / zr / zn / zN / zi / zv / zx / zX /
--   zj / zk / [z / ]z）都能直接用，已逐一实测通过。
--
-- 但「手工折叠」命令（zf / zF / zd / zE）和 expr 折叠互斥：
--   Neovim 一个窗口同一时刻只能有一种 foldmethod，expr 下建不了手工折叠
--   （会报 E350: Cannot create fold / E351: Cannot delete fold）。
-- 下面两个键用于在「语法树折叠」和「手工折叠」之间切换【当前窗口】：
--   <leader>zf  切到 manual → 之后就能用 zf / zd / zE 对任意区域做手工折叠
--   <leader>ze  切回 expr（treesitter 语法树折叠，默认行为）
-- 注：切到 manual 会丢掉该窗口现有的语法树折叠，纯属临时需要手工折叠时才用。

local map = vim.keymap.set

local function fold_manual()
  vim.wo.foldmethod = 'manual'
  vim.notify('折叠模式 → manual（现可用 zf / zd / zE 手工折叠）', vim.log.levels.INFO)
end

local function fold_expr()
  vim.wo.foldmethod = 'expr'
  vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
  vim.wo.foldlevel = 99
  vim.notify('折叠模式 → expr（treesitter 语法树折叠）', vim.log.levels.INFO)
end

map('n', '<leader>zf', fold_manual, { desc = '切到手工折叠模式(manual)' })
map('n', '<leader>ze', fold_expr, { desc = '切回语法树折叠(expr)' })

-- vim: ts=2 sts=2 sw=2 et
