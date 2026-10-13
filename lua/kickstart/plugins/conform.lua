local function gh(repo) return 'https://github.com/' .. repo end

-- [[ conform.nvim —— 代码格式化（保存时/手动触发）]]
--
-- 把外部格式化器统一管起来，按文件类型派发：
--   python → ruff（**只 format，不 fix**）、c/cpp → clang-format、lua → stylua
--   （只用本机已装好的工具，不靠 Mason，避免 aarch64/glibc 兼容问题）
-- 保存即格式化：对 enabled_filetypes 里列出的类型生效（老吴 2026-09-28 要求全开）。
--   ⚠ 这就是之前「按 <C-s> 不自动格式化」的原因 —— 原来的白名单是**空表**（两行都被注释掉了），
--     所以任何类型保存时都不会触发格式化。现在把已配好格式化器的四种类型都打开。
-- 注意：这里的类型必须在下面 formatters_by_ft 里配了对应工具，否则会报 "formatter not found"。
-- 手动格式化按 <leader>cf（LazyVim 键位，异步、不等）。
--
-- ⚠⚠ Python 为什么**不能**用 ruff_fix（2026-10-13 修的数据丢失问题）
--
--   现象：保存 .py 时，文件里"警告过的那些行"（其实是未使用的 import）被自动删掉，
--        甚至把 `from typing import List` 也删了并改成 `list[int]`。
--
--   实测（ruff check --fix 的真实破坏力）：
--     保存前: from collections import defaultdict / from typing import List
--             import os / import sys / import json ... nums: List[int]
--     保存后: from collections import defaultdict      ← os/sys/json 全没了
--             ...nums: list[int]        ← 还被改成了 3.9+ 才有的写法
--
--   两个原因叠加：
--     1) `ruff check --fix` 会**自动删除它认为未使用的 import**（F401）——
--        这是**改代码**的操作，不该在"保存"这种无感知时机发生。
--     2) ruff 没配 target-version，默认按 3.10 判断语法/API，
--        于是把 `typing.List` 判成 UP035 过时并自动改成 `list[int]`——
--        而内置泛型是 Python 3.9+ (PEP 585)，本机 3.8 上直接崩
--        （TypeError: 'type' object is not subscriptable）。
--        ⚠ 这与 basedpyright 那个"typing.List is deprecated"是**同一个病根**：
--          诊断工具的版本比运行环境高时，建议方向是反的。
--
--   所以现在的做法：
--     - 保存时**只跑 ruff_format**（纯排版，不动代码内容）
--     - 把 target-version 钉到**探测到的真实版本**（见下），消除版本错配
--     - 需要"整理 import / 修 lint"时手动按 <leader>cf（那时你看得见）
local pydetect = require 'python-detect'
local py_exe, py_version, _, py_ruff_target = pydetect.get()

--⚠ target-version 怎么传给 ruff（踩了两轮才搞清，记下来别再踩）
--
--   1. ❌ 写在 formatters_by_ft 的元素里：
--        python = { 'ruff_format', options = { extra_args = {...} } }
--      conform 的 formatters_by_ft 元素**只接受 name / id / filter 三个键**
--      （见 init.lua: allowed_default_filetype_opts），options 会被**静默忽略**。
--      表现：配置看着对，`--target-version` 却根本没下发，ruff 仍按默认 3.10 判断。
--
--   2. ❌ 覆盖 conform.setup 的 `formatters = { ruff_format = {...} }`：
--      实测也没生效（require('conform.formatters').ruff_format 拿到的仍是原始 args），
--      内部结构不透明，不可靠。
--
--   3. ❌ 环境变量 RUFF_TARGET_VERSION：ruff **不认**（实测无效）。
--
--   ✅ 正解：**ruff.toml 配置文件**（ruff 官方机制，最稳）。
--      实测：项目根放 ruff.toml 写 target-version = "py38"，
--           UP035 `typing.List is deprecated` 立刻消失（All checks passed）。
--      写在项目根即可，conform 的 ruff_format 会自动读它
--      （它的 cwd 本来就设为root_file('ruff.toml')）。
--
--   → 若本机探测到的版本变了，改 ruff.toml 里的 target-version 即可，
--     不需要动这里。保存时格式化不会删行了（因为已去掉 ruff_fix）。
if not py_ruff_target then
  vim.notify(
    '未探测到 Python 3 版本，ruff 会按内置默认（较新版本）判断语法，\n'
      .. '可能给出对老吴环境不利的建议（如把 typing.List 改成 list）。\n'
      .. '建议在项目根放 ruff.toml：target-version = "py38"（按你的实际版本改）',
    vim.log.levels.WARN
  )
end

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
    -- Python：**只格式化，不fix**（2026-10-13）
    --   ⚠ 绝不要在这里加回 'ruff_fix' —— 它会在保存时静默删掉未使用的 import，
    --     还会把 typing.List 改成 list[int]（3.8 上直接崩），详见文件头注释。
    --   --target-version 已在上面的 formatters = { ruff_format = ... } 里钉住。
    --   需要整理 import / 修 lint 时，手动按 <leader>cf（看得见才敢跑）。
    python = { 'ruff_format' },

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
