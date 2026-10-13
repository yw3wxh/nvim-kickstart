-- [[ python-detect.lua —— 探测真实的 Python 解释器与版本 ]]
--
-- 为什么必须实探、不能写死：
--   1) 本机 `/usr/bin/python` 指向 **Python 2.7**（发行版历史包袱），
--      而 Python 2 连 typing 模块都没有。认错解释器 → 补全/类型全废。
--   2) 不同环境下`python3` 可能是 3.8 / 3.13 不同版本；
--      **basedpyright 和 ruff 报什么语法/API 结论，全看喂给它们的版本号**。
--      不喂 → 它们用各自内置的**最新版本**标准判断，
--      于是把 3.8 的合法写法判成过时（如`from typing import List` → 建议改`list`），
--      而内置泛型 `list[int]` 是 Python 3.9+ 才有的，**照改直接崩**。
--   3) Windows 上解释器可能叫 `python` 而不是 `python3`。
--
-- ⚠ 被谁用：
--   - kickstart/plugins/lspconfig.lua → basedpyright 的 pythonPath / pythonVersion
--   - kickstart/plugins/conform.lua     → ruff 的 --target-version
--   两边共用同一个探测结果，保证 LSP 和格式化器对"这是哪个 Python"的判断一致。
--   （若各探各的，可能一边认3.13、一边认 3.8，诊断和修复就会打架）
-- ---------------------------------------------------------------------------

local M = {}

---探测 Python 解释器
---@return string|nil exe 可执行文件路径
---@return string|nil version 完整版本号，如 '3.8.10'
---@return string|nil short 主次版本，如 '3.8'（直接给 basedpyright 用）
---@return string|nil ruff_target ruff 的 target-version 值，如 'py38'
function M.detect()
  local candidates = {
    vim.fn.exepath 'python3',
    vim.fn.exepath 'python',
    '/usr/bin/python3',
    '/usr/local/bin/python3',
    vim.fn.expand '~/dev/python/bin/python3',
    '/opt/python/bin/python3',
    'python3',
  }

  local python2 = nil -- 记住 python2 以便报错时说清
  for _, exe in ipairs(candidates) do
    if exe ~= '' and vim.uv.fs_stat(exe) then
      local out = vim.fn.system({ exe, '-c', 'import sys;print("%d.%d.%d" % sys.version_info[:3])' })
      if vim.v.shell_error == 0 then
        local ver = vim.trim(out)
        local maj, min = ver:match '^(%d+)%.(%d+)'
        maj, min = tonumber(maj), tonumber(min)
        if maj and maj >= 3 then -- 只认 Python 3+
          local short = string.format('%d.%d', maj, min)
          -- ruff 的 target-version 用 py38 这种格式（去掉点）
          local ruff_target = string.format('py%d%d', maj, min)
          return exe, ver, short, ruff_target
        end
        python2 = python2 or { exe, ver }
      end
    end
  end

  return (python2 and python2[1]) or nil, (python2 and python2[2]) or nil, nil, nil
end

---便捷入口：拿到探测结果（带缓存，避免多次调用重复 fork 进程）
---@return string|nil exe, string|nil version, string|nil short, string|nil ruff_target
function M.get()
  if M._cached == nil then
    M._exe, M._ver, M._short, M._ruff = M.detect()
    M._cached = true
  end
  return M._exe, M._ver, M._short, M._ruff
end

---人类可读的一行摘要，供 notify / 排查用
function M.summary()
  local exe, ver = M.get()
  if not exe then return '未找到 Python 3 解释器' end
  return string.format('%s (Python %s)', exe, ver or '?')
end

return M
