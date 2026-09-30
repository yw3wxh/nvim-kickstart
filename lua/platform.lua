-- [[ platform.lua —— 统一平台识别，避免各处重复写 vim.fn.has 判断 ]]
--
-- 用法（任何 lua 文件里）：
--   local platform = require('platform')
--   if platform.is_win_like then ... end   -- WSL 或原生 Windows（可用 Mason / im-select.exe）
--   if platform.is_wsl      then ... end    -- 仅 WSL
--   if platform.is_win32    then ... end    -- 仅原生 Windows
--   if platform.is_linux    then ... end    -- 纯 Linux（排除 WSL）
--   if platform.is_mac      then ... end    -- macOS（如有需要）
--
-- 所有平台判断集中在此，插件与配置统一 require 本模块，不要再各自写 vim.fn.has。

-- 读 /proc/version 判断是否包含某关键字（忽略大小写）。
-- 用于在 has('wsl')==0 的旧版本 nvim / 特殊环境下仍能识别 WSL。
local function proc_version_has(needle)
  if vim.fn.filereadable '/proc/version' ~= 1 then return false end
  local ok, lines = pcall(vim.fn.readfile, '/proc/version')
  if not ok or not lines or #lines == 0 then return false end
  return (lines[1] or ''):lower():find(needle) ~= nil
end

local M = {}

-- 原生 Windows
M.is_win32 = vim.fn.has 'win32' == 1

-- WSL（Windows Subsystem for Linux）：has('wsl') 或 /proc/version 含 microsoft
M.is_wsl = vim.fn.has 'wsl' == 1 or proc_version_has 'microsoft'

-- 类 Windows 环境：WSL 与 原生 Windows 走同一套策略
-- （Mason 下发预编译二进制 / 输入法在 Windows 侧要用 im-select.exe）
M.is_win_like = M.is_win32 or M.is_wsl

-- 纯 Linux（排除 WSL）。用于剪贴板、输入法框架等原生 Linux 分支
M.is_linux = vim.fn.has 'linux' == 1 and not M.is_wsl

-- macOS（如有需要）
M.is_mac = vim.fn.has 'macunix' == 1 or vim.fn.has 'mac' == 1

return M
