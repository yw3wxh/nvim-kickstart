local function gh(repo) return 'https://github.com/' .. repo end

-- [[ conform.nvim —— 代码格式化（保存时/手动触发）]]
--
-- 把外部格式化器统一管起来，按文件类型派发：
--   python → ruff（先 fix 再 format）、c/cpp → clang-format、lua → stylua
--   （只用本机已装好的工具，不靠 Mason，避免 aarch64/glibc 兼容问题）
-- 保存即格式化：对 enabled_filetypes 里列出的类型生效（老吴 2026-09-28 要求全开）。
--   ⚠ 这就是之前「按 <C-s> 不自动格式化」的原因 —— 原来的白名单是**空表**（两行都被注释掉了），
--     所以任何类型保存时都不会触发格式化。现在把已配好格式化器的四种类型都打开。
-- 注意：这里的类型必须在下面 formatters_by_ft 里配了对应工具，否则会报 "formatter not found"。
-- 手动格式化按 <leader>cf（LazyVim 键位，异步、不等）。
vim.pack.add { gh 'stevearc/conform.nvim' }
require('conform').setup {
  notify_on_error = false,
  format_on_save = function(bufnr)
    -- 两个「暂停自动格式化」开关，配合 <leader>uf（全局）/ <leader>uF（仅当前文件）
    -- 的 snacks toggle 使用，见 custom/plugins/lazyvim-keymaps.lua
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then return nil end
    -- 保存时自动格式化的文件类型白名单（注释掉某一行即可单独关掉它）
    local enabled_filetypes = {
      lua = true, -- stylua
      python = true, -- ruff_fix → ruff_format（ruff_fix 会自动整理 import，等于改动代码）
      c = true, -- clang-format
      cpp = true, -- clang-format
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

-- ⚠ 键位按 LazyVim 改了：<leader>f → <leader>cf（f 组让给「文件」）
vim.keymap.set({ 'n', 'v' }, '<leader>cf', function() require('conform').format { async = true } end, { desc = '格式化代码' })

-- vim: ts=2 sts=2 sw=2 et
