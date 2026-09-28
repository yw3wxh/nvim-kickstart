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
--
-- ⚠ 键位已按 LazyVim 官方表（https://www.lazyvim.org/keymaps）重排。
--   LazyVim 用的是 snacks picker，本机换算成 telescope 的等价功能。
--   原来 kickstart 那套键的变化：
--     <leader>sf（找文件）          → <leader>ff（<leader><space> 同）
--     <leader>s.（最近打开的文件）  → <leader>fr（<leader>fR 只看当前目录）
--     <leader>sn（nvim 配置文件）   → <leader>fc
--     <leader>sr（resume）          → <leader>sR（sr 让位给 grug-far 的搜索替换）
--     <leader>sc（命令列表）        → <leader>sC（sc 让位给命令历史）
--     <leader>/（本文件内模糊找）   → <leader>sb
--     <leader>s/（已打开的文件里搜）→ <leader>sB
--     <leader><leader>（buffer）    → <leader>,（<leader>fb 同）
--     <leader>ss（telescope 内置）  → 让位给「当前文件符号」
local builtin = require 'telescope.builtin'

-- ---- <leader>f：文件 ------------------------------------------------------
vim.keymap.set('n', '<leader><space>', builtin.find_files, { desc = '找文件（项目根）' })
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = '找文件（项目根）' })
vim.keymap.set('n', '<leader>fF', function() builtin.find_files { cwd = vim.fn.getcwd() } end, { desc = '找文件（当前目录）' })
vim.keymap.set('n', '<leader>fg', builtin.git_files, { desc = '找 git 里已跟踪的文件' })
vim.keymap.set('n', '<leader>fr', builtin.oldfiles, { desc = '最近打开的文件' })
vim.keymap.set('n', '<leader>fR', function() builtin.oldfiles { cwd = vim.fn.getcwd() } end, { desc = '最近打开的文件（当前目录）' })
vim.keymap.set('n', '<leader>fc', function() builtin.find_files { cwd = vim.fn.stdpath 'config', follow = true } end, { desc = '找 nvim 配置文件' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'buffer 列表' })
vim.keymap.set('n', '<leader>,', builtin.buffers, { desc = 'buffer 列表' })

-- ---- <leader>s：搜索 ------------------------------------------------------
vim.keymap.set('n', '<leader>/', builtin.live_grep, { desc = '搜内容（项目根）' })
vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '搜内容（项目根）' })
vim.keymap.set('n', '<leader>sG', function() builtin.live_grep { cwd = vim.fn.getcwd() } end, { desc = '搜内容（当前目录）' })
vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '搜光标下的词' })
vim.keymap.set({ 'n', 'v' }, '<leader>sW', function() builtin.grep_string { cwd = vim.fn.getcwd() } end, { desc = '搜光标下的词（当前目录）' })
vim.keymap.set('n', '<leader>sb', function()
  builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown { winblend = 10, previewer = false })
end, { desc = '本文件内模糊查找' })
vim.keymap.set('n', '<leader>sB', function()
  builtin.live_grep { grep_open_files = true, prompt_title = 'Live Grep in Open Files' }
end, { desc = '只在已打开的文件里搜' })
vim.keymap.set('n', '<leader>sR', builtin.resume, { desc = '接着上次搜索' })
vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '搜索诊断（全部）' })
vim.keymap.set('n', '<leader>sD', function() builtin.diagnostics { bufnr = 0 } end, { desc = '搜索诊断（当前文件）' })
vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '搜索帮助' })
vim.keymap.set('n', '<leader>sH', builtin.highlights, { desc = '搜索高亮组' })
vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '搜索按键' })
vim.keymap.set('n', '<leader>sC', builtin.commands, { desc = '命令列表' })
vim.keymap.set('n', '<leader>sc', builtin.command_history, { desc = '命令历史' })
vim.keymap.set('n', '<leader>s:', builtin.command_history, { desc = '命令历史' })
vim.keymap.set('n', '<leader>s/', builtin.search_history, { desc = '搜索历史' })
vim.keymap.set('n', '<leader>sj', builtin.jumplist, { desc = '跳转记录' })
vim.keymap.set('n', '<leader>sm', builtin.marks, { desc = '标记列表' })
vim.keymap.set('n', '<leader>sM', builtin.man_pages, { desc = 'man 手册' })
vim.keymap.set('n', '<leader>sl', builtin.loclist, { desc = 'Location List' })
vim.keymap.set('n', '<leader>sq', builtin.quickfix, { desc = 'Quickfix List' })
-- TODO 注释（todo-comments 插件）
vim.keymap.set('n', '<leader>st', '<cmd>TodoTelescope<cr>', { desc = '搜索 TODO 注释' })
vim.keymap.set('n', '<leader>sT', '<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>', { desc = '搜索 TODO/FIX/FIXME' })

-- 当 LSP 附加到缓冲区时，添加基于 Telescope 的 LSP 选择器。
-- 键位同样对齐 LazyVim：gd / gr / gI / gy / gD / gK，
-- 原来的 grr / gri / grd / grt / gO / gW 那套已废弃（gO、gW 换到 <leader>ss、<leader>sS）。
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
  callback = function(event)
    local buf = event.buf
    local opts = function(desc) return { buffer = buf, desc = desc } end

    vim.keymap.set('n', 'gd', builtin.lsp_definitions, opts '跳到定义')
    vim.keymap.set('n', 'gr', builtin.lsp_references, opts '查找引用')
    vim.keymap.set('n', 'gI', builtin.lsp_implementations, opts '跳到实现')
    vim.keymap.set('n', 'gy', builtin.lsp_type_definitions, opts '跳到类型定义')
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts '跳到声明')
    vim.keymap.set('n', '<leader>ss', builtin.lsp_document_symbols, opts '当前文件符号')
    vim.keymap.set('n', '<leader>sS', builtin.lsp_dynamic_workspace_symbols, opts '整个项目符号')
  end,
})

-- vim: ts=2 sts=2 sw=2 et
