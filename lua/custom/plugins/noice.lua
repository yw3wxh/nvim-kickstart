local function gh(repo) return 'https://github.com/' .. repo end

-- [[ noice.nvim —— 接管消息、命令行和弹出菜单的显示 ]]
--
-- 装了它之后：
--   - 命令行（:、/、?）会变成居中的浮动输入框，而不是挤在屏幕最底部一行
--   - :messages 之类的消息会以漂亮的弹窗形式出现
--   - LSP 的悬浮文档、补全菜单会有更好的边框和高亮
--   - :Noice 可以打开完整的消息历史，翻回之前被刷掉的信息
--
-- 依赖说明：
--   - MunifTanjim/nui.nvim  —— 必须装，noice 靠它做界面渲染
--   - rcarriga/nvim-notify  —— 可选，装了通知更好看；不装 noice 会退化用 mini
vim.pack.add {
  gh 'folke/noice.nvim',
  gh 'MunifTanjim/nui.nvim', -- noice 和 trouble 都会用到它
  gh 'rcarriga/nvim-notify', -- 通知视图
}

-- nvim-notify 要在 noice 之前 setup，否则 noice 找不到它
require('notify').setup {
  timeout = 3000, -- 通知 3 秒后自动消失
  max_width = 80, -- 通知窗口最大宽度，避免长消息占满屏幕
  stages = 'fade_in_slide_out', -- 淡入滑出的动画
}

require('noice').setup {
  -- 命令行相关配置
  cmdline = {
    enabled = true, -- 启用 noice 的命令行界面（设为 false 就用回原生命令行）
    view = 'cmdline_popup', -- 输入框显示在屏幕中央上方
  },

  -- LSP 相关
  lsp = {
    -- LSP 进度（"正在加载 clangd…"）交给 fidget 显示，
    -- 这里关掉，避免和 fidget 重复弹两次
    progress = { enabled = false },

    -- 用 treesitter 来渲染 markdown 文档，
    -- 这样 LSP 的悬浮说明、补全文档会有正确的语法高亮
    override = {
      ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
      ['vim.lsp.util.stylize_markdown'] = true,
    },
  },

  -- 预设：一组打包好的常用配置，省得一项项手写
  presets = {
    bottom_search = true, -- 搜索时（/ 和 ?）命令行回到屏幕底部，符合习惯
    command_palette = true, -- 命令行和补全菜单对齐显示
    long_message_to_split = true, -- 太长的消息用分屏显示，而不是截断
    inc_rename = false, -- 需要额外装 inc-rename.nvim，这里先不开
    lsp_doc_border = false, -- 给悬浮文档加边框（开了更好看，但会多占点地方）
  },

  -- 消息路由：决定哪些消息要被处理、怎么处理
  routes = {
    -- 保存文件时那句 "xxx 已写入" 太频繁，直接不看它
    {
      filter = { event = 'msg_show', kind = '', find = 'written' },
      opts = { skip = true },
    },
    -- 搜索时左下角的 "[1/5]" 这类计数也不显示
    {
      filter = { event = 'msg_show', kind = 'search_count' },
      opts = { skip = true },
    },
  },

  -- 消息历史最多保留多少条
  history = { max_entries = 200 },
}

-- 常用按键（都放在 <leader>n 下面，n = noice）
--   <leader>nh  打开消息历史（相当于更好用的 :messages）
--   <leader>nd  关掉当前所有弹出的提示
--   <leader>na  查看最近一条消息
vim.keymap.set('n', '<leader>nh', '<cmd>Noice history<cr>', { desc = '[N]oice 消息[H]历史' })
vim.keymap.set('n', '<leader>nd', '<cmd>Noice dismiss<cr>', { desc = '[N]oice 关闭[D]所有提示' })
vim.keymap.set('n', '<leader>na', '<cmd>Noice last<cr>', { desc = '[N]oice 最近一条[A]消息' })

-- vim: ts=2 sts=2 sw=2 et
