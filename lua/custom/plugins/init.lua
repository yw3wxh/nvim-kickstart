-- [[ custom/plugins/init.lua —— 自定义插件自动加载器 ]]
--
-- 作用：遍历本目录（lua/custom/plugins/）下所有 .lua 并逐个 require，
--   所以「新增一个插件 = 丢一个 .lua 进来」就能生效，不用改别处。
-- 由 lua/plugins.lua 末尾的 require 'custom.plugins' 触发执行。
-- 注意：本文件本身（init.lua）不会被加载，只负责加载同级的其他文件。

-- 遍历 plugins 目录下的所有 Lua 文件并加载它们
local plugins_dir = vim.fs.joinpath(vim.fn.stdpath 'config', 'lua', 'custom', 'plugins')
for file_name, type in vim.fs.dir(plugins_dir, { follow = true }) do
  if (type == 'file' or type == 'link') and file_name:match '%.lua$' and file_name ~= 'init.lua' then
    local module = file_name:gsub('%.lua$', '')
    require('custom.plugins.' .. module)
  end
end
