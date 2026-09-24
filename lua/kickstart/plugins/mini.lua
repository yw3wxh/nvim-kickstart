local function gh(repo) return 'https://github.com/' .. repo end

-- [[ mini.nvim ]]
--  各种小型、独立插件/模块的集合
vim.pack.add { gh 'nvim-mini/mini.nvim' }

-- 如果有 nerd font，则加载 icons 模块，为各种插件提供漂亮的图标。
if vim.g.have_nerd_font then
  require('mini.icons').setup()
  -- 用于与需要 `nvim-web-devicons` 的插件（例如 telescope.nvim）保持向后兼容
  MiniIcons.mock_nvim_web_devicons()
end

-- 更好的 Around/Inside 文本对象
--
-- 示例：
--  - va)  - [V]isual 选择 [A]round [)]括号
--  - yiiq - [Y]ank [I]nside [I]+1 [Q]quote
--  - ci'  - [C]hange [I]nside [']引号
require('mini.ai').setup {
  -- 注意：避免与 Neovim>=0.12 内置的增量选择映射冲突（参见 `:help treesitter-incremental-selection`）
  mappings = {
    around_next = 'aa',
    inside_next = 'ii',
  },
  n_lines = 500,
}

-- 添加/删除/替换环绕符号（括号、引号等）
--
-- - gsaiw) - [S]urround [A]dd [I]nner [W]ord [)]括号
-- - gsd'   - [S]urround [D]elete [']引号
-- - gsr)'  - [S]urround [R]eplace [)] [']
--
-- ⚠ 注意前缀为什么是 `gs` 而不是默认的 `s`：
--   `s` 已经被 flash.nvim 占用（见 custom/plugins/flash.lua）——
--   flash 按 `s` 就进入搜索跳转，会直接吃掉 `sa` / `sd` / `sr`。
--   两者都要用的话，只能让其中一个换前缀。这里让 surround 换。
--   如果你没装 flash（把 flash.lua 删了），可以把下面的 `gs` 前缀改回 `s`。
require('mini.surround').setup {
  mappings = {
    add = 'gsa', -- 加环绕符号
    delete = 'gsd', -- 删环绕符号
    replace = 'gsr', -- 换环绕符号
    find = 'gsf', -- 跳到下一个环绕符号
    find_left = 'gsF', -- 跳到上一个环绕符号
    highlight = 'gsh', -- 临时高亮当前环绕范围
    update_n_lines = 'gsn', -- 修改搜索范围（行数）
  },
}

-- 简单易用的状态栏。
--  如果你不喜欢它，可以移除这个 setup 调用，
--  并尝试其他状态栏插件
local statusline = require 'mini.statusline'
-- 如果你有 Nerd Font，请将 `use_icons` 设为 true
statusline.setup { use_icons = vim.g.have_nerd_font }

-- 你可以通过覆盖默认行为来配置状态栏中的各个部分。
-- 例如，这里我们把光标位置部分设置为 LINE:COLUMN
---@diagnostic disable-next-line: duplicate-set-field
statusline.section_location = function() return '%2l:%-2v' end

-- 会话管理：每个「启动 nvim 的目录」自动存一份会话，启动页按 s 一键恢复当前目录的会话
--
-- 会话名 = 当前工作目录（cwd）的编码（把 / 等非文件名字符转成 %XX，保证唯一且合法）。
--   例如 /home/user/proj  →  会话文件 %2Fhome%2Fuser%2Fproj.vim，放在 stdpath('data')/session/。
--
-- 自动保存：nvim 退出时（VimLeavePre）自动把「当前目录」的会话写盘（覆盖写，无则创建）。
--   - 只在确实打开了文件时才存（纯启动页、只开着 dashboard 时不存，避免把空页存进去）。
--   - 带了文件名启动（nvim foo.cpp）时不自动存，避免污染目录会话。
--
-- 启动页按 s：直接加载「当前目录」对应的会话（有则恢复，无则提示「还没有会话」），
--   不再弹列表选（见 custom/plugins/snacks.lua 里 dashboard 的 s 键）。
--
-- 手动用法：
--   :lua MiniSessions.write('名字')   —— 按名字保存
--   MiniSessions.select()             —— 弹出列表手动选/加载一个会话
local MiniSessions = require('mini.sessions')

-- 把任意目录路径编码成合法且唯一的会话文件名（不含 /，避免和目录分隔符混淆）
local function session_name_for_cwd()
  local cwd = vim.fn.getcwd()
  return cwd:gsub('[^A-Za-z0-9._-]', function(c)
    return string.format('%%%02X', string.byte(c))
  end)
end

MiniSessions.setup {
  -- 会话目录：默认就在 data/session，这里写明确认一下
  directory = vim.fn.stdpath 'data' .. '/session',
  -- 自动保存交给我们自己的 VimLeavePre（按 cwd 存），这里关掉内置 autowrite
  autowrite = false,
  -- 自动存/读都别刷消息，保持安静
  verbose = { read = false, write = false, delete = false },
}

-- 退出 nvim 时，把「当前目录」的会话自动写盘
vim.api.nvim_create_autocmd('VimLeavePre', {
  desc = '自动保存当前目录的会话（mini.sessions）',
  callback = function()
    -- 带了文件名启动时不自动存（nvim foo.cpp 这种），避免污染目录会话
    if vim.fn.argc() > 0 then return end
    -- 只有真正打开了文件才存：纯启动页（只有 dashboard 缓冲）不存，免得把空页存进去
    local has_file = false
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if vim.bo[b].buflisted and vim.api.nvim_buf_get_name(b) ~= '' then
        has_file = true
        break
      end
    end
    if not has_file then return end
    pcall(MiniSessions.write, session_name_for_cwd(), { force = true })
  end,
})

-- 供启动页 s 键调用：打开「当前目录」的会话（有则加载，无则提示）
function _G.load_cwd_session()
  local name = session_name_for_cwd()
  local path = MiniSessions.config.directory .. '/' .. name .. '.vim'
  if MiniSessions.detected[name] ~= nil or vim.fn.filereadable(path) == 1 then
    MiniSessions.read(name, { force = true })
  else
    vim.notify('当前目录还没有会话：' .. vim.fn.getcwd(), vim.log.levels.INFO)
  end
end

-- ... 还有更多！
--  查看：https://github.com/nvim-mini/mini.nvim

-- vim: ts=2 sts=2 sw=2 et
