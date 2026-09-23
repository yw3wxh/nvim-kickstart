local function gh(repo) return 'https://github.com/' .. repo end

-- [[ tabout —— 编辑时按 Tab 跳出一层括号/引号 ]]
--
-- 场景：输入 `foo()|` 后光标在括号里，再按 Tab 就跳到 `foo()|` 外面。
-- 支持 () [] {} 以及 ' " ` 引号。
--
-- 与补全/片段的 Tab 共存：
--   completion = true 时，tabout 把「补全菜单可见」时的 Tab 交还给原本的绑定
--   （这里是 blink.cmp 的片段跳转），其余情况 Tab 负责跳出括号。
--   ⚠ 代价：片段展开后占位符的 Tab 跳转会被 tabout 接管（不再用 Tab 跳占位符）。
--     若你更想要「Tab 优先跳片段占位符」，告诉我，我改用量身定制的 dispatcher。
vim.pack.add { gh 'abecodes/tabout.nvim' }

require('tabout').setup {
  tabkey = '<Tab>', -- 触发跳出的键
  backwards_tabkey = '<S-Tab>', -- 反向跳出
  act_as_tab = true, -- 跳不出去时照常插入 Tab（不丢 Tab 的本职）
  act_as_shift_tab = false,
  enable_backwards = true, -- 允许 <S-Tab> 反向
  completion = true, -- 补全菜单开着时把 Tab 让给补全插件
  ignore_beginning = true, -- 光标在字符串/对象开头也能直接跳出
  default_tab = '<C-t>', -- 行首且跳不出去时发送的默认键
  default_shift_tab = '<C-d>',
  tabouts = {
    { open = "'", close = "'" },
    { open = '"', close = '"' },
    { open = '`', close = '`' },
    { open = '(', close = ')' },
    { open = '[', close = ']' },
    { open = '{', close = '}' },
  },
  exclude = {}, -- 这些 filetype 不启用
}
