-- [[ nvim-autopairs —— 自动补全括号/引号配对 ]]
--
-- 输入 ( 自动补 )，[ ] { } 和 ' " ` 同理；删左括号时把右括号一起删；
-- 在括号中间回车时自动把右括号搬到下一行。纯 Lua，无依赖，
-- 并和 blink.cmp 补全菜单配合（选中补全项后自动补上右配对）。默认配置已够用。

vim.pack.add { 'https://github.com/windwp/nvim-autopairs' }
require('nvim-autopairs').setup {}
