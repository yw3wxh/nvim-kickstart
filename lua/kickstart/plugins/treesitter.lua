local function gh(repo) return 'https://github.com/' .. repo end

-- [[ 配置 Treesitter ]]
--  用于代码的高亮、编辑和导航
--
--  参见 `:help nvim-treesitter-intro`

-- 注意：你也可以指定分支或特定提交
vim.pack.add { { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' } }

-- 确保安装了基础解析器
local parsers = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' }
require('nvim-treesitter').install(parsers)

---@param buf integer
---@param language string
local function treesitter_try_attach(buf, language)
  -- 检查解析器是否存在并加载它
  if not vim.treesitter.language.add(language) then return end
  -- 启用语法高亮和其他 treesitter 功能
  vim.treesitter.start(buf, language)

  -- 启用基于 treesitter 的折叠
  -- 更多关于折叠的信息参见 `:help folds`
  -- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
  -- vim.wo.foldmethod = 'expr'

  -- 检查该语言是否支持 treesitter 缩进，如果支持则启用它
  -- 如果没有缩进查询，indentexpr 会回退到 vim 内置的实现
  local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil

  -- 启用基于 treesitter 的缩进
  if has_indent_query then vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
end

local available_parsers = require('nvim-treesitter').get_available()
vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local buf, filetype = args.buf, args.match

    local language = vim.treesitter.language.get_lang(filetype)
    if not language then return end

    local installed_parsers = require('nvim-treesitter').get_installed 'parsers'

    if vim.tbl_contains(installed_parsers, language) then
      -- 如果解析器已安装，则启用它
      treesitter_try_attach(buf, language)
    elseif vim.tbl_contains(available_parsers, language) then
      -- 如果 `nvim-treesitter` 中提供该解析器，则自动安装它，并在安装完成后启用
      require('nvim-treesitter').install(language):await(function() treesitter_try_attach(buf, language) end)
    else
      -- 尝试启用 treesitter 功能，以防解析器存在但不来自 `nvim-treesitter`
      treesitter_try_attach(buf, language)
    end
  end,
})

-- vim: ts=2 sts=2 sw=2 et
