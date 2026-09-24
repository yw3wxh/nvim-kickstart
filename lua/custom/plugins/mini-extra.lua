-- [[ mini.operators + mini.move —— 文本运算符 / 行与块移动 ]]
--
-- 这两个都是已经装好的 mini.nvim 里的模块，这里只管 setup 启用（零额外下载）。
-- 放在 custom 目录而不是 kickstart/plugins/mini.lua，是为了不碰核心文件、保持「丢一个 .lua 就生效」。

-- ===== mini.operators：把常见文本操作做成 operator =====
-- 默认前缀（除 sort 外都保持默认）：
--   g=   求值并把结果替换进去（如 `g=ip` 把选中段落当表达式算；支持 lua/vim 等）
--   gr   替换（operator，如 `griw` 用寄存器内容替换 inner word；`grr` 替换当前行）
--   gx   交换两段文本（先 `gxx` 标记当前行，移到目标再 `gxx` 即交换）
--   gm   复制（multiply，如 `gmiw` 把 word 再复制一份）
--   g@   注释（operator 版，如 `g@ip` 注释整段）
-- ⚠ 关键：默认 sort 前缀是 `gs`，和 mini.surround 的 `gs` 前缀撞（surround 用 gsa/gsd/gsr…），
--   所以这里把 sort 改成 `gS`（大写 S），如 `gSip` 段落排序、`gS%` 排序当前括号内容。
require('mini.operators').setup {
  sort = { prefix = 'gS' },
}

-- ===== mini.move：用按键上下/左右移动整行或选中块 =====
-- 默认按键（mini 自带，无需改）：
--   普通模式  <M-j>/<M-k> 上下移动当前行；<M-h>/<M-l> 按列左右移动
--   可视模式  选中后 <M-j>/<M-k>/<M-h>/<M-l> 移动选中内容（行/字符/块都行）
--   ⚠ 如果你的终端收不到 Alt 组合键（按了没反应），把对应键改成 <A-j> 等或直接改键位即可。
require('mini.move').setup()
