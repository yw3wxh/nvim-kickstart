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
      if vim.fn.has 'win32' ~= 1 and vim.fn.executable 'make' == 1 then run_build(name, { 'make', 'install_jsregexp' }, ev.data.path) end
      return
    end

    if name == 'nvim-treesitter' then
      if not ev.data.active then vim.cmd.packadd 'nvim-treesitter' end
      vim.cmd 'TSUpdate'
      return
    end
  end,
})

-- vim: ts=2 sts=2 sw=2 et
