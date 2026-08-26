local function gh(repo) return 'https://github.com/' .. repo end

-- 在注释中高亮 todo、notes 等
vim.pack.add { gh 'folke/todo-comments.nvim' }
require('todo-comments').setup { signs = false }

-- vim: ts=2 sts=2 sw=2 et
