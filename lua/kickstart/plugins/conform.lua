local function gh(repo) return 'https://github.com/' .. repo end

-- [[ 格式化 ]]
vim.pack.add { gh 'stevearc/conform.nvim' }
require('conform').setup {
  notify_on_error = false,
  format_on_save = function(bufnr)
    -- 你可以在这里指定保存时自动格式化的文件类型：
    local enabled_filetypes = {
      -- lua = true,
      -- python = true,
    }
    if enabled_filetypes[vim.bo[bufnr].filetype] then
      return { timeout_ms = 500 }
    else
      return nil
    end
  end,
  default_format_opts = {
    lsp_format = 'fallback', -- 如果下面配置了外部格式化器则使用它们，否则使用 LSP 格式化。设为 `false` 可完全禁用 LSP 格式化。
  },
  -- 你也可以在这里指定外部格式化器。
  formatters_by_ft = {
    -- rust = { 'rustfmt' },
    -- Conform 也可以顺序运行多个格式化器
    -- python = { "isort", "black" },
    --
    -- 你可以使用 'stop_after_first' 来运行列表中第一个可用的格式化器
    -- javascript = { "prettierd", "prettier", stop_after_first = true },
  },
}

vim.keymap.set({ 'n', 'v' }, '<leader>f', function() require('conform').format { async = true } end, { desc = '[F]ormat buffer' })

-- vim: ts=2 sts=2 sw=2 et
