local function gh(repo) return 'https://github.com/' .. repo end

-- [[ Comment.nvim —— 快速注释（LazyVim 同款）]]
--
-- 默认按键（和现有的 mini.surround `gs` 前缀、mini.operators 的 `g=`/`gr`/`gS` 都不冲突）：
--   gcc    注释 / 取消注释当前行
--   gc     接文本对象或可视选区，如 `gcap` 注释整个段落、`gc}` 注释花括号块
--   gbc    强制按整行注释（linewise）当前行
--   gb     接文本对象的整行版，如 `gbip`
--   gco    在光标下方插入一行注释占位；`gcO` 上方；`gcA` 行尾追加注释
--
-- 注释符号取自各文件类型的 `commentstring`（c/cpp 的 // 、python 的 # 等），无需额外依赖。

vim.pack.add { gh 'numToStr/Comment.nvim' }

require('Comment').setup {
  -- 多行注释时，对其中连续的空行也一并注释（更整齐）
  padding = true,
  --  sticky 注释：在已注释行上按 gcc 会沿用同样的缩进层级
  sticky = true,
  -- 忽略空白行的注释（gc 选区内纯空行不注释）
  ignore = '^$',
}
