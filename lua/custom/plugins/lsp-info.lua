-- [[ 查看"当前文件挂了哪个语言服务器" ]]
--
-- ⚠ 别和 <leader>cl 搞混：
--    <leader>cl → Trouble 的 lsp 模式，列的是**光标下符号**的定义 / 引用 / 实现
--    <leader>ci → 本文件，**当前 buffer 上挂了哪些语言服务器**（这个才是"看 LSP 程序"）
--
-- 为什么不用 :LspInfo：新版 nvim-lspconfig 已经把这个命令删掉了，
-- Neovim 0.12 本身也没有内置它（实测 exists(':LspInfo') == 0）。
-- 能用的只有 Lua 接口 vim.lsp.get_clients()，所以这里包一层：
--   :LspClients   手动敲命令
--   <leader>ci    按键，弹一条多行通知

--- 收集某个 buffer 上语言服务器的摘要
---@param bufnr integer
---@return string[] 每行一条，直接 concat 成通知正文
local function client_lines(bufnr)
  local clients = vim.lsp.get_clients { bufnr = bufnr }
  local ft = vim.bo[bufnr].filetype

  if #clients == 0 then
    local lines = { ('buffer %d（filetype=%s）当前没有挂载任何语言服务器'):format(bufnr, ft) }
    -- 常见的几种语言顺手提示该装什么，省得再去翻配置
    local expected = {
      c = 'clangd',
      cpp = 'clangd',
      python = 'basedpyright',
      lua = 'lua_ls',
      rust = 'rust_analyzer',
      go = 'gopls',
    }
    if expected[ft] then
      lines[#lines + 1] = ('%s 需要 %s，命令行里用 `which %s` 检查装没装'):format(ft, expected[ft], expected[ft])
      lines[#lines + 1] = 'lspconfig.lua 里是条件启用的：可执行文件不存在就整个跳过'
    end
    return lines
  end

  local lines = {}
  for _, c in ipairs(clients) do
    lines[#lines + 1] = ('● %s  (id=%d)'):format(c.name, c.id)
    lines[#lines + 1] = ('   根目录: %s'):format(c.root_dir or '（无）')
    local cmd = c.config and c.config.cmd
    lines[#lines + 1] = ('   启动命令: %s'):format(cmd and table.concat(cmd, ' ') or '（未知）')

    -- 能力列表：capabilities 里既可能是 true 也可能是表，都当成"支持"
    local caps = c.server_capabilities or {}
    local feats = {}
    if caps.completionProvider then feats[#feats + 1] = '补全' end
    if caps.definitionProvider then feats[#feats + 1] = '跳转定义' end
    if caps.referencesProvider then feats[#feats + 1] = '查找引用' end
    if caps.hoverProvider then feats[#feats + 1] = '悬浮文档' end
    if caps.renameProvider then feats[#feats + 1] = '重命名' end
    if caps.documentFormattingProvider then feats[#feats + 1] = '格式化' end
    lines[#lines + 1] = ('   支持: %s'):format(#feats > 0 and table.concat(feats, '、') or '（无）')
  end
  return lines
end

vim.api.nvim_create_user_command('LspClients', function()
  -- 用 get_current_buf() 而不是字面 0：client_lines 里要拿 filetype，0 号 buffer 未必是当前这个
  vim.notify(table.concat(client_lines(vim.api.nvim_get_current_buf()), '\n'), vim.log.levels.INFO, { title = '当前文件的 LSP' })
end, { desc = '查看当前 buffer 挂了哪些语言服务器' })

vim.keymap.set('n', '<leader>ci', '<cmd>LspClients<cr>', { desc = '当前文件的 LSP 信息 [I]' })

-- vim: ts=2 sts=2 sw=2 et
