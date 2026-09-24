local function gh(repo) return 'https://github.com/' .. repo end

-- [[ bufferline.nvim —— 顶部多文件标签页（LazyVim 同款 UI）]]
--
-- 这就是你在 LazyVim 里看到的「顶部一排、每个打开的文件一个标签」的实现。
--   - 普通模式下用普通 buffer 模式（每个打开的文件一个标签，不是 tab page）
--   - 左上角显示 LSP 诊断数量（红=错误 / 黄=警告）
--   - 文件类型图标走 mini.icons（已在 mini.lua 里 mock 成 nvim-web-devicons 接口）
--   - 自动跟随当前 colorscheme（gruvbox / tokyonight）重新上色（监听 ColorScheme 事件）
--
-- ⚠ 注意：本机**没有持久左侧文件树**（neo-tree 被关、mini.files 是浮动的），
--   所以这里**不需要**给 bufferline 设左边偏移（offsets）。

vim.pack.add { gh 'akinsho/bufferline.nvim' }

require('bufferline').setup {
  -- 延迟到 UI 就绪后再建，避免启动早期抢资源（LazyVim 同款 event）
  -- vim.pack 没有 lazy 的 event 字段，这里直接 setup 即可，bufferline 自身很轻。
  options = {
    -- 每个打开的文件一个标签（而不是 Neovim 的 tab page）
    mode = 'buffers',
    -- 始终显示标签栏，哪怕只开了一个文件（和 LazyVim 一致）
    always_show_bufferline = true,

    -- ===== 外观 =====
    separator_style = 'slant', -- LazyVim 默认：斜角分隔，配 Nerd Font 好看
    show_buffer_icons = true, -- 显示文件类型图标（依赖 mini.icons mock 的 devicons）
    show_buffer_close_icons = true,
    show_close_icon = true,
    show_tab_indicators = true,
    show_duplicate_prefix = true,
    duplicates_across_groups = true,
    persist_buffer_sort = true,
    -- 鼠标操作：左键切、右键关、中键关
    left_mouse_command = 'buffer %d',
    right_mouse_command = 'bdelete! %d',
    middle_mouse_command = 'bdelete! %d',
    -- 悬停标签时显示完整路径（很实用）
    hover = { enabled = true, delay = 200, reveal = {'close'}},
    -- 数字角标关掉，保持 LazyVim 那种干净风格
    numbers = 'none',

    -- ===== LSP 诊断 =====
    diagnostics = 'nvim_lsp',
    diagnostics_update_in_insert = false,
    -- 用纯文本计数，避免依赖特定字体图标（本机 snacks 那边也刻意用了 ASCII）
    diagnostics_indicator = function(count, level, diagnostics_dict, context)
      local out = {}
      if diagnostics_dict.error then
        table.insert(out, 'E' .. diagnostics_dict.error)
      end
      if diagnostics_dict.warning then
        table.insert(out, 'W' .. diagnostics_dict.warning)
      end
      if diagnostics_dict.info then
        table.insert(out, 'I' .. diagnostics_dict.info)
      end
      if diagnostics_dict.hint then
        table.insert(out, 'H' .. diagnostics_dict.hint)
      end
      return #out > 0 and table.concat(out, ' ') or ''
    end,
  },
  -- 自定义高亮分组：让当前标签用下划线指示（更显眼）
  highlights = {
    indicator_selected = { underline = true },
  },
}

-- [[ 与 bufferline 配套的按键（对齐 LazyVim 习惯）]]
-- 注意：<leader>bd 已经在 snacks.lua 里绑成 Snacks.bufdelete（删当前 buffer 不乱布局），这里不再重复。
local map = vim.keymap.set

-- Shift+H / Shift+L：左右切 buffer（LazyVim 默认，和 <C-h>/<C-l> 切窗口不冲突）
map('n', '<S-h>', '<cmd>bprevious<cr>', { desc = '上一个 buffer' })
map('n', '<S-l>', '<cmd>bnext<cr>', { desc = '下一个 buffer' })

-- <leader>b 前缀：buffer 操作组（which-key 会自动归类）
map('n', '<leader>bb', '<cmd>b#<cr>', { desc = '切到另一个 buffer' })
map('n', '<leader>bn', '<cmd>bnext<cr>', { desc = '下一个 buffer' })
map('n', '<leader>bp', '<cmd>bprevious<cr>', { desc = '上一个 buffer' })
map('n', '<leader>bl', '<cmd>buffer #<cr>', { desc = '上一个访问的 buffer' })
map('n', '<leader>bD', function() vim.cmd 'bdelete! %' end, { desc = '强制删除当前 buffer' })
map('n', '<leader>bs', '<cmd>BufferLinePick<cr>', { desc = '按字母选 buffer' })
