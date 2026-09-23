local function gh(repo) return 'https://github.com/' .. repo end

-- [[ 配置 Treesitter ]]
--  用于代码的高亮、编辑和导航
--
--  参见 `:help nvim-treesitter-intro`
--
-- ---------------------------------------------------------------------------
-- ⚠ 本文件与官方 kickstart 的差异：解析器是预先编译好的，不联网下载
--
-- 原版会在启动时调用 install() 去下载缺失的解析器。但本机有两个硬伤：
--   1) tree-sitter CLI 是 0.20.8，而新版 nvim-treesitter 需要 0.21+ 的
--      `tree-sitter build` 子命令，装完也编译不了；
--   2) HTTPS 访问 GitHub 经常被拦，下载直接 curl 502。
-- 结果是每次开 nvim 都刷一屏报错，但其实解析器本身是好的。
--
-- 所以这里改成：解析器用 gcc 提前编译成 .so，放在
--   ~/.local/share/nvim/site/pack/core/opt/nvim-treesitter/parser/
-- 配置启动时**不联网**，只把已装好的解析器挂上去，安静且快。
--
-- 以后要新增一门语言，两条路：
--   A. 网络通：直接 :TSInstall <语言>
--   B. 网络不通：自己编译，把 .so 丢进上面的 parser 目录即可
--        git clone --depth 1 https://github.com/tree-sitter/tree-sitter-<语言>
--        cd tree-sitter-<语言>
--        gcc -fPIC -shared -I src -o <语言>.so src/parser.c src/scanner.c
--      （注意：C++ 的 parser.c 有 25MB，编译时 /tmp 可能不够，
--        需要 export TMPDIR=/一个有空间的目录）
-- ---------------------------------------------------------------------------

vim.pack.add { { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' } }

-- 本机已编译好的解析器（缺哪个就高亮不了哪门语言，但不会报错）
-- markdown / markdown_inline 是给 grug-far 补的（它的界面是 markdown 写的），
-- 顺带你自己的笔记在 nvim 里也能有高亮。
-- 注意：markdown 的高亮规则（queries）nvim 运行时自带，所以只编译 .so 就够了。
local installed = {
  'bash',
  'c',
  'cpp',
  'diff',
  'html',
  'json',
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'python',
  'query',
  'vim',
}

---@param buf integer
---@param language string
local function treesitter_try_attach(buf, language)
  -- 检查解析器是否存在并加载它；装不了的语言直接跳过，不打扰用户
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

-- 打开文件时就地挂载解析器。
-- 这里刻意**不**调用 install()：装不上的语言静默跳过，
-- 不去联网重试，避免每次启动都弹一堆 502。
vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local buf, filetype = args.buf, args.match

    local language = vim.treesitter.language.get_lang(filetype)
    if not language then return end
    if not vim.tbl_contains(installed, language) then return end

    treesitter_try_attach(buf, language)
  end,
})

-- vim: ts=2 sts=2 sw=2 et
