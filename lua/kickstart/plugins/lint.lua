-- [[ nvim-lint —— 代码语法/风格检查（Lint）]]
--
-- 在 BufEnter / BufWritePost / InsertLeave 时自动跑对应语言的 linter。
-- 当前只给 markdown 配了 markdownlint（工具需单独装好，否则会报 "not found"）。
-- 想加别的语言：往 linters_by_ft 里加即可（注意对应工具得先装好）。

vim.pack.add { 'https://github.com/mfussenegger/nvim-lint' }

local lint = require 'lint'
lint.linters_by_ft = {
  markdown = { 'markdownlint' }, -- 请确保通过 mason / npm 安装 `markdownlint`
}

-- 要允许其他插件向 require('lint').linters_by_ft 添加 linter，
-- 请像这样设置 linters_by_ft：
-- lint.linters_by_ft = lint.linters_by_ft or {}
-- lint.linters_by_ft['markdown'] = { 'markdownlint' }
--
-- 但请注意，这会启用一组默认的 linter，
-- 除非这些工具可用，否则会导致错误：
-- {
--   clojure = { "clj-kondo" },
--   dockerfile = { "hadolint" },
--   inko = { "inko" },
--   janet = { "janet" },
--   json = { "jsonlint" },
--   markdown = { "vale" },
--   rst = { "vale" },
--   ruby = { "ruby" },
--   terraform = { "tflint" },
--   text = { "vale" }
-- }
--
-- 你可以通过把它们的文件类型设为 nil 来禁用默认 linter：
-- lint.linters_by_ft['clojure'] = nil
-- lint.linters_by_ft['dockerfile'] = nil
-- lint.linters_by_ft['inko'] = nil
-- lint.linters_by_ft['janet'] = nil
-- lint.linters_by_ft['json'] = nil
-- lint.linters_by_ft['markdown'] = nil
-- lint.linters_by_ft['rst'] = nil
-- lint.linters_by_ft['ruby'] = nil
-- lint.linters_by_ft['terraform'] = nil
-- lint.linters_by_ft['text'] = nil

-- 创建在指定事件上执行实际 linting 的自动命令
local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
  group = lint_augroup,
  callback = function()
    -- 只在你可以修改的缓冲区中运行 linter，以免产生多余的噪音，
    -- 尤其是在那些用 Markdown 描述悬停符号的 LSP 弹出窗口中。
    if vim.bo.modifiable then lint.try_lint() end
  end,
})
