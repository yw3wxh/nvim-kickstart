local function gh(repo) return 'https://github.com/' .. repo end

-- [[ conform.nvim —— 代码格式化（保存时/手动触发）]]
--
-- 把外部格式化器统一管起来，按文件类型派发：
--   python → ruff（先 fix 再 format）、c/cpp → clang-format、lua → stylua
--   （只用本机已装好的工具，不靠 Mason，避免 aarch64/glibc 兼容问题）
-- 默认不开启「保存即格式化」：format_on_save 只对 enabled_filetypes 里的类型生效，
--   目前列表留空；要开自动格式化，把对应类型填进 enabled_filetypes 即可。
-- 手动格式化按 <leader>f（异步）。
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
  --  这里只填本机确实装好了的工具（不用 Mason 装，避免 glibc 兼容问题）。
  --  没装的工具不要写进来，否则格式化时会报 "formatter not found"。
  formatters_by_ft = {
    -- Python：ruff 既能 lint 也能 format（~/.local/bin/ruff）
    --   按 <leader>f 会先整理 import 再格式化
    python = { 'ruff_fix', 'ruff_format' },

    -- C/C++：clang-format（/usr/bin/clang-format，随 clang 一起装的）
    c = { 'clang-format' },
    cpp = { 'clang-format' },

    -- Lua：stylua（/usr/local/bin/stylua），用来格式化 nvim 配置本身
    lua = { 'stylua' },

    -- Conform 也可以顺序运行多个格式化器
    -- python = { "isort", "black" },
    --
    -- 你可以使用 'stop_after_first' 来运行列表中第一个可用的格式化器
    -- javascript = { "prettierd", "prettier", stop_after_first = true },
  },
}

vim.keymap.set({ 'n', 'v' }, '<leader>f', function() require('conform').format { async = true } end, { desc = '[F]ormat buffer' })

-- vim: ts=2 sts=2 sw=2 et
