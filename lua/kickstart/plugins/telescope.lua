local function gh(repo) return 'https://github.com/' .. repo end

-- [[ 模糊查找器（文件、LSP 等）]]
--
-- Telescope 是一个模糊查找器，内置了很多可以进行模糊查找的功能！
-- 它不仅仅是一个"文件查找器"，它还可以搜索
-- Neovim、你的工作区、LSP 等许多不同方面！
--
-- 还有很多其他的选择器插件（比如 snacks.picker 或 fzf-lua），
-- 所以可以随意尝试，看看你喜欢什么！
--
-- 使用 Telescope 最简单的方式，是从类似这样的命令开始：
--  :Telescope help_tags
--
-- 运行这个命令后，会打开一个窗口，你可以在提示窗口中输入内容。
-- 你会看到一个 `help_tags` 选项列表以及对应的帮助预览。
--
-- 在 Telescope 中需要记住的两个重要按键映射是：
--  - 插入模式：<c-/>
--  - 普通模式：?
--
-- 这会打开一个窗口，显示当前 Telescope 选择器的所有按键映射。
-- 这对于了解 Telescope 能做什么以及如何操作非常有用！

---@type (string|vim.pack.Spec)[]
local telescope_plugins = {
  gh 'nvim-lua/plenary.nvim',
  gh 'nvim-telescope/telescope.nvim',
  gh 'nvim-telescope/telescope-ui-select.nvim',
}
if vim.fn.executable 'make' == 1 then table.insert(telescope_plugins, gh 'nvim-telescope/telescope-fzf-native.nvim') end

-- 注意：你可以一次安装多个插件
vim.pack.add(telescope_plugins)

-- 参见 `:help telescope` 和 `:help telescope.setup()`
require('telescope').setup {
  -- 你可以在这里放入默认的映射 / 更新 / 等等
  --  你要找的所有信息都在 `:help telescope.setup()` 中
  --
  -- defaults = {
  --   mappings = {
  --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
  --   },
  -- },
  -- pickers = {}
  extensions = {
    ['ui-select'] = { require('telescope.themes').get_dropdown() },
  },
}

-- 如果已安装，则启用 Telescope 扩展
pcall(require('telescope').load_extension, 'fzf')
pcall(require('telescope').load_extension, 'ui-select')

-- 参见 `:help telescope.builtin`
local builtin = require 'telescope.builtin'
vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

-- 当 LSP 附加到缓冲区时，添加基于 Telescope 的 LSP 选择器。
-- 如果之后更换选择器插件，这里就是需要更新这些映射的地方。
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
  callback = function(event)
    local buf = event.buf

    -- 查找光标下单词的引用。
    vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })

    -- 跳转到光标下单词的实现。
    -- 当你的语言有声明类型但没有实际实现的方式时很有用。
    vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })

    -- 跳转到光标下单词的定义。
    -- 这是变量首次声明的地方，或者函数定义的地方，等等。
    -- 要跳回，按 <C-t>。
    vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })

    -- 模糊查找当前文档中的所有符号。
    -- 符号包括变量、函数、类型等。
    vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })

    -- 模糊查找当前工作区中的所有符号。
    -- 与文档符号类似，只是搜索范围覆盖整个项目。
    vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })

    -- 跳转到光标下单词的类型。
    -- 当你不确定某个变量的类型、想查看它的*类型*定义
    -- （而不是它在*哪里*被定义）时很有用。
    vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
  end,
})

-- 覆盖搜索时的默认行为和主题
vim.keymap.set('n', '<leader>/', function()
  -- 你可以向 Telescope 传递额外的配置来更改主题、布局等。
  builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, { desc = '[/] Fuzzily search in current buffer' })

-- 也可以传递额外的配置选项。
--  关于特定键的信息参见 `:help telescope.builtin.live_grep()`
vim.keymap.set(
  'n',
  '<leader>s/',
  function()
    builtin.live_grep {
      grep_open_files = true,
      prompt_title = 'Live Grep in Open Files',
    }
  end,
  { desc = '[S]earch [/] in Open Files' }
)

-- 搜索你的 Neovim 配置文件的快捷方式
vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config', follow = true } end, { desc = '[S]earch [N]eovim files' })

-- vim: ts=2 sts=2 sw=2 et
