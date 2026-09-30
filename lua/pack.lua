-- [[ `vim.pack` 简介 ]]
-- `vim.pack` 是 Neovim 内置的新插件管理器，
--  它提供了一个用于安装和管理插件的 Lua 接口。
--
--  参见 `:help vim.pack`、`:help vim.pack-examples` 或
--  vim.pack 和 mini.nvim 的作者写的优秀博客文章：
--  https://echasnovski.com/blog/2026-03-13-a-guide-to-vim-pack
--
--  要检查插件状态和待处理的更新，请运行
--    :lua vim.pack.update(nil, { offline = true })
--
--  要更新插件，请运行
--    :lua vim.pack.update()
--
--
--  在配置的其余部分中，会有如何使用 `vim.pack` 安装和配置插件的示例。
--
--  在本节中，我们设置了一些自动命令，用于在特定插件安装或更新后
--  执行其构建步骤。

local platform = require('platform')

local function run_build(name, cmd, cwd)
  local result = vim.system(cmd, { cwd = cwd }):wait()
  if result.code ~= 0 then
    local stderr = result.stderr or ''
    local stdout = result.stdout or ''
    local output = stderr ~= '' and stderr or stdout
    if output == '' then output = 'No output from build command.' end
    vim.notify(('Build failed for %s:\n%s'):format(name, output), vim.log.levels.ERROR)
  end
end

-- ---------------------------------------------------------------------------
-- ⚠ 本机的特殊麻烦：有些二进制"装不回来"
--
-- 下面这两个东西，正常途径在本机都拿不到：
--   - 联网下载：GitHub 被代理挡死（502 / 连接被掐）
--   - 本地编译：需要的编译器/工具链没有（cargo 没装）
-- 所以它们是**手动放进去**的，位于插件自己的目录里。而 `:packupdate` 重装插件时
-- 会把整个插件目录换掉，这些文件就跟着没了。
--
-- 对策：把副本存在 **pack 目录之外** 的地方（vim.pack 管不到、不会被清），
-- 插件一安装/更新就自动拷回去。纯本地文件复制、不联网，所以网络再差也能自愈。
--
--   - `nvim-treesitter/parser/regex.so`               —— noice 用它高亮命令行的正则
--   - `blink.cmp/target/release/libblink_cmp_fuzzy.so` —— blink.cmp 的 rust 模糊匹配器
--
-- 备份目录：~/.local/share/nvim/prebuilt/（见 stdpath('data')）
-- ---------------------------------------------------------------------------
local prebuilt_dir = vim.fn.stdpath 'data' .. '/prebuilt'

-- 备份的是 aarch64 版二进制，只在同架构上恢复。
-- 换机器/换架构时直接跳过，免得把错的 .so 拷进去导致插件加载失败。
local function arch_matches()
  local machine = (vim.uv.os_uname().machine or ''):lower()
  return machine:match 'aarch64' ~= nil or machine:match 'arm64' ~= nil
end

--- 把备份的预编译二进制拷回插件目录
---@param name string 插件名（仅用于提示）
---@param plugin_path string 插件安装目录
---@param filename string 备份目录里的文件名
---@param dest_rel string 相对插件目录的目标路径
local function restore_prebuilt(name, plugin_path, filename, dest_rel)
  if not arch_matches() then return end
  local src = prebuilt_dir .. '/' .. filename
  if not vim.uv.fs_stat(src) then return end -- 没备份过就什么都不做，不打扰用户
  local dest = plugin_path .. '/' .. dest_rel
  vim.fn.mkdir(vim.fn.fnamemodify(dest, ':h'), 'p')
  -- fs_copyfile 的返回值约定不好依赖，这里直接拷完再验目标是否存在，最稳
  pcall(vim.uv.fs_copyfile, src, dest)
  if vim.uv.fs_stat(dest) then
    vim.notify(('已从备份恢复 %s 的 %s'):format(name, dest_rel), vim.log.levels.INFO)
  else
    vim.notify(('恢复 %s 的 %s 失败，备份文件：%s'):format(name, dest_rel, src), vim.log.levels.WARN)
  end
end

-- 这个自动命令会在插件安装或更新后运行，
--  并在必要时为该插件执行相应的构建命令。
--
-- 参见 `:help vim.pack-events`
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local name = ev.data.spec.name
    local kind = ev.data.kind
    if kind ~= 'install' and kind ~= 'update' then return end

    if name == 'telescope-fzf-native.nvim' and vim.fn.executable 'make' == 1 then
      run_build(name, { 'make' }, ev.data.path)
      return
    end

    if name == 'LuaSnip' then
      if not platform.is_win32 and vim.fn.executable 'make' == 1 then run_build(name, { 'make', 'install_jsregexp' }, ev.data.path) end
      return
    end

    if name == 'nvim-treesitter' then
      if not ev.data.active then vim.cmd.packadd 'nvim-treesitter' end
      -- ⚠ 不调用 TSUpdate：本机解析器是本地预编译好的 .so（见 treesitter.lua），
      --   这里一旦联网去 GitHub 下载，在受限网络下会被卡住；而且外面包着同步
      --   的 vim.system(...):wait()，会直接把 nvim 主线程冻死。更新 treesitter
      --   后想重编译解析器，手动按 treesitter.lua 注释里的办法本地 gcc 编即可。
      --
      -- 重装会把 parser/ 目录换掉，所以顺手把 regex 解析器从备份拷回来（noice 用）。
      restore_prebuilt(name, ev.data.path, 'regex.so', 'parser/regex.so')
      return
    end

    if name == 'blink.cmp' then
      -- 重装会清掉 target/，rust 模糊匹配器就没了。这里从备份恢复，
      -- 否则 blink.cmp 会静默回退到 Lua 实现（并弹一条告警）。
      restore_prebuilt(name, ev.data.path, 'libblink_cmp_fuzzy.so', 'target/release/libblink_cmp_fuzzy.so')
      -- ⚠ 关键一步：顺手删掉残留的 `version` 文件，否则恢复了也白搭。
      --
      --   原因：blink.cmp 一旦发现库不在，就会尝试联网下载；而 download() 的第一步是
      --   `set_version('v0.0.0')`，先写个假的 version 文件（注释说是为了避免失败后
      --   二进制被误判成"本地构建"）。下载在本机必然失败（GitHub 被代理挡），
      --   但这个 version 文件会**残留下来**。
      --
      --   之后哪怕把 .so 放回去也没用：blink.cmp 判断"用户手动放置"的分支要求
      --   **version 文件缺失**（`version.current.missing`），有这个文件它就认为
      --   版本对不上（v0.0.0 ≠ 实际的 git tag），于是继续尝试下载 → 失败 → 回退 Lua。
      --
      --   所以恢复之后必须清掉它，让 blink.cmp 重新识别成"手动放置的库"。
      pcall(vim.uv.fs_unlink, ev.data.path .. '/target/release/version')
      return
    end
  end,
})

-- vim: ts=2 sts=2 sw=2 et
