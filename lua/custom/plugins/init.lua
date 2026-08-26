-- 你可以在这里或本目录的其他文件中添加你自己的插件！
--  我保证不会在这个目录里制造任何合并冲突 :)
--
-- 更多信息参见 kickstart.nvim 的 README

-- 遍历 plugins 目录下的所有 Lua 文件并加载它们
local plugins_dir = vim.fs.joinpath(vim.fn.stdpath 'config', 'lua', 'custom', 'plugins')
for file_name, type in vim.fs.dir(plugins_dir, { follow = true }) do
  if (type == 'file' or type == 'link') and file_name:match '%.lua$' and file_name ~= 'init.lua' then
    local module = file_name:gsub('%.lua$', '')
    require('custom.plugins.' .. module)
  end
end
