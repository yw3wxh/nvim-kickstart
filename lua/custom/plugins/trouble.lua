local function gh(repo) return 'https://github.com/' .. repo end

-- [[ trouble.nvim —— 把诊断、引用、符号等列表统一到一个漂亮的面板里 ]]
--
-- 原生 Neovim 的 :lua vim.diagnostic.setloclist 打开的是 quickfix 窗口，
-- 比较丑也不好操作。trouble 把它换成一个可交互的列表：
-- 可以折叠、可以预览、可以直接跳转。
--
-- 它也能接管 LSP 的"查找引用"结果 —— 按下 grr 之后，
-- 引用列表会在 trouble 面板里列出，而不是塞进 quickfix。
vim.pack.add {
  gh 'folke/trouble.nvim',
  gh 'MunifTanjim/nui.nvim', -- trouble 的界面依赖（noice 也用它，装一次即可）
}

require('trouble').setup {
  -- trouble v3 的默认配置已经够用，这里只挑几项常用的改
  icons = {
    -- 没装 Nerd Font 就别用图标，否则会显示成乱码方块
    use = vim.g.have_nerd_font,
  },
  -- 打开 trouble 面板时自动聚焦到列表，可以直接用 j/k 选、回车跳转
  focus = true,
  -- 在列表里移动光标时，右侧自动预览对应位置的代码
  preview = { type = 'split' },
}

-- ---------------------------------------------------------------------------
-- 按键映射（统一放在 <leader>x 下，x = 问题/诊断）
-- ---------------------------------------------------------------------------
-- <leader>xx  整个项目的诊断（错误 + 警告）
-- <leader>xX  只看当前文件的诊断
-- <leader>cs  当前文件的符号大纲（函数、类、变量一览）
-- <leader>cS  光标下符号的定义 / 引用 / 实现 / 类型定义 / 调用层级
--              （⚠ 注意是**大写 S**；<leader>cl 在 LazyVim 里是「Lsp Info」，见 lsp-info.lua）
vim.keymap.set('n', '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', { desc = '诊断列表 [X]' })
vim.keymap.set('n', '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', { desc = '当前文件诊断 [X]' })
vim.keymap.set('n', '<leader>cs', '<cmd>Trouble symbols toggle<cr>', { desc = '符号大纲 [S]' })

-- [[ <leader>cS 为什么会显示 "no results for lsp" ]]
--
-- `Trouble lsp` 不是一个"把当前文件信息列出来"的列表，而是把
--   定义 / 引用 / 实现 / 类型定义 / 声明 / 调用层级
-- 这几个查询的结果合并在一起 —— 它们**全都以光标下的标识符为输入**。
-- 于是下面几种情况都会得到空结果，trouble 就提示 no results：
--   1. 光标停在空格、注释、字符串、括号上（压根没有符号）；
--   2. 光标停在关键字上（int / return / class 这些没有定义和引用）；
--   3. 符号确实没人引用、也不是虚函数（比如 main、没人调用的工具函数）；
--   4. 当前 buffer 压根没挂上 LSP（比如 C/C++ 但系统里没有 clangd）。
--
-- 光秃秃一句 "no results" 分不清是哪种，所以这里先做三道前置检查，
-- 把上面 1 / 2 / 4 直接说清楚，剩下的才是"这个符号真的没什么可查的"。
vim.keymap.set('n', '<leader>cS', function()
  -- 检查 1：当前 buffer 有没有语言服务器
  if #vim.lsp.get_clients { bufnr = vim.api.nvim_get_current_buf() } == 0 then
    vim.notify(
      '当前文件没有挂载 LSP（C/C++ 需要系统里能找到 clangd），所以查不到定义和引用',
      vim.log.levels.WARN,
      { title = 'Trouble LSP' }
    )
    return
  end

  -- 检查 2：光标下有没有单词（空行 / 纯标点上 expand('<cword>') 是空串）
  if vim.fn.expand '<cword>' == '' then
    vim.notify('光标没停在标识符上：先把光标移到函数名 / 变量名上再按', vim.log.levels.WARN, { title = 'Trouble LSP' })
    return
  end

  -- 检查 3：光标下是不是"标识符"而不是关键字。
  -- treesitter 判断最准：cpp 里函数名是 identifier，int 是 primitive_type、
  -- 行首缩进会拿到外层的 compound_statement —— 这些都不是标识符。
  -- 放行条件用模糊匹配 identifier / word / name，顺带兼容 bash 的 command_name
  -- 这种不叫 identifier 但同样能查定义的节点类型。
  -- parser 没装（get_node 返回 nil）时跳过这项检查，只按单词判断。
  local ok, node = pcall(vim.treesitter.get_node)
  local node_type = (ok and node) and node:type() or nil
  if node_type and not (node_type:find 'identifier' or node_type:find 'word' or node_type:find 'name') then
    vim.notify(
      ('光标所在位置是 %s，不是标识符：先把光标移到函数名 / 变量名上再按'):format(node_type),
      vim.log.levels.WARN,
      { title = 'Trouble LSP' }
    )
    return
  end

  vim.cmd 'Trouble lsp toggle'
end, { desc = '光标下符号：定义/引用/实现 [S]' })

-- 让 which-key 把上面这些按键归到一个分组里显示
-- （which-key 在 plugins.lua 里比本文件先加载，所以这里能直接拿到；
--   用 pcall 包一层是为了万一顺序变了也不至于报错）
pcall(
  function()
    require('which-key').add {
      { '<leader>x', group = '诊断/问题 [X]' },
      { '<leader>c', group = '代码 [C]' },
      { '<leader>sn', group = '[N]oice 消息' },
    }
  end
)

-- vim: ts=2 sts=2 sw=2 et
