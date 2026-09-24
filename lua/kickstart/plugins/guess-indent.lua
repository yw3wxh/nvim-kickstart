local function gh(repo) return 'https://github.com/' .. repo end

-- [[ guess-indent.nvim —— 打开文件时自动识别缩进风格 ]]
--
-- 作用：根据文件已有内容判断用 Tab 还是空格、每级几列，并自动设好对应选项。
-- 本机额外约束：识别到空格 / Tab 后**都强制锁成 4 空格**
--   （on_space_options / on_tab_options 全部写死 4），
--   否则它会把已有 8 空格的 cpp 又设回 8，缩进就变 8 了。
vim.pack.add { gh 'NMAC427/guess-indent.nvim' }

-- 保留「识别 Tab / 空格」的能力，但把缩进宽度强制锁成 4 空格，
-- 否则它会把已有 8 空格的文件（比如 cpp）又设回 8，缩进就变成 8 了。
--   on_space_options：检测到空格时 → 用空格、宽度 4
--   on_tab_options  ：检测到 Tab 时 → 也转成 4 空格（不要真 Tab）
require('guess-indent').setup {
  on_space_options = {
    expandtab = true,
    tabstop = 4,
    softtabstop = 4,
    shiftwidth = 4,
  },
  on_tab_options = {
    expandtab = true,
    tabstop = 4,
    softtabstop = 4,
    shiftwidth = 4,
  },
}

-- vim: ts=2 sts=2 sw=2 et
