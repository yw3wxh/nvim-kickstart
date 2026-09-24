local function gh(repo) return 'https://github.com/' .. repo end

-- [[ todo-comments.nvim —— 高亮注释里的 TODO/FIXME/XXX 等标记 ]]
--
-- 扫描注释和字符串里的 TODO / FIXME / HACK / NOTE / XXX 等关键字并高亮，
-- 配合 trouble 可一键列出全部待办（:TodoTrouble）。
-- 这里关掉行号栏的 sign（signs = false），避免和 gitsigns 的改动标记挤在一起。
vim.pack.add { gh 'folke/todo-comments.nvim' }
require('todo-comments').setup { signs = false }

-- vim: ts=2 sts=2 sw=2 et
