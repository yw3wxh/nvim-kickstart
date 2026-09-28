-- [[ telescope 补充：把搜索范围收窄到「当前文件所在目录」]]
--
-- 解决什么问题
-- ---------------------------------------------------------------------------
-- telescope 自带的搜索，全部从 **cwd** 开始（打开 nvim 的目录，通常是项目根）：
--     <leader>sg  搜内容        <leader>ff  找文件名
--
-- ⚠ 键位已按 LazyVim 重排：LazyVim 的 <leader>sD 是「当前 buffer 的诊断」，
--    所以「当前目录搜内容」挪到了 <leader>sz（z 在 LazyVim 里没被占用），
--    <leader>sF 那边 LazyVim 没定义，保留原样。
-- 项目一大，命中的绝大多数都在别的模块里，跟手头这份文件没关系，得自己在
-- 结果里再翻一遍。
--
-- 而日常最常见的需求其实是「只搜当前这份文件周围这一片」——
-- 比如人在 src/foo.cpp，只想搜 src/ 这一个目录。
--
-- 做法：把当前文件所在目录（**绝对路径**）传给 telescope
--     live_grep  → search_dirs：只限定 rg 的搜索路径，cwd 保持不变
--                  （telescope 支持这个参数，见 telescope/builtin/__files.lua:124）
--     find_files → cwd：直接把查找的根目录换过去
--
-- ⚠ 一个关键坑：判断「有没有文件名」不能用 vim.fn.expand '%:p:h'。
--   在无名 buffer（刚 :ene 出来的空文件、:terminal 等）上它会**退化成 nvim 的 cwd**，
--   那样「搜当前目录」会静默变成「搜整个项目」——正好是我们想避免的行为。
--   所以下面统一用 vim.api.nvim_buf_get_name(0) 先判断，拿不到就走兜底并提示。
--
-- 为什么放在 custom 而不是改 kickstart/plugins/telescope.lua：
--   不碰核心文件，保持「丢一个 .lua 进 custom/plugins 就生效」的约定
--   （自动加载逻辑见 custom/plugins/init.lua）。
-- ---------------------------------------------------------------------------

local builtin = require 'telescope.builtin'

-- 取当前文件所在目录的绝对路径；当前 buffer 没有文件名时返回 nil（见上面注释）
local function current_dir()
  local name = vim.api.nvim_buf_get_name(0)
  if name == '' then return nil end
  return vim.fn.fnamemodify(name, ':p:h')
end

-- 显示用的路径：把家目录缩写成 ~，免得 prompt 标题被超长路径撑爆
local function short(dir)
  return vim.fn.fnamemodify(dir, ':~')
end

-- ---------------------------------------------------------------------------
-- <leader>sz  只在当前文件所在目录里搜【内容】
--   z = 自定义补充（LazyVim 没这个键），不占官方键位
-- ---------------------------------------------------------------------------
vim.keymap.set('n', '<leader>sz', function()
  local dir = current_dir()
  if not dir then
    -- 无名 buffer：退回全项目搜，并提示一句，不静默扩大范围
    vim.notify('当前 buffer 没有文件名，退回在整个项目里搜', vim.log.levels.INFO)
    builtin.live_grep()
    return
  end
  builtin.live_grep {
    search_dirs = { dir },
    prompt_title = 'Grep in ' .. short(dir),
  }
end, { desc = '搜内容（当前文件所在目录）' })

-- ---------------------------------------------------------------------------
-- <leader>sF  只在当前文件所在目录里找【文件名】
--   大写 F，和小写的 <leader>ff（全项目找文件）区分开
-- ---------------------------------------------------------------------------
vim.keymap.set('n', '<leader>sF', function()
  local dir = current_dir()
  if not dir then
    vim.notify('当前 buffer 没有文件名，退回在整个项目里找', vim.log.levels.INFO)
    builtin.find_files()
    return
  end
  builtin.find_files {
    cwd = dir,
    prompt_title = 'Files in ' .. short(dir),
  }
end, { desc = '找文件（当前文件所在目录）' })

-- ---------------------------------------------------------------------------
-- 顺带：grug-far（<leader>sr）怎么限定目录
-- ---------------------------------------------------------------------------
-- grug-far 不用额外键位——它窗口里本来就有 Files 栏，填路径即可：
--     Files: src/          只搜 src/ 下面
--     Files: *.cpp         只搜 cpp 文件
--     Flags: -i            忽略大小写
-- 想以光标下的词起手，用 <leader>*（见 custom/plugins/grug-far.lua）。
-- ---------------------------------------------------------------------------

-- vim: ts=2 sts=2 sw=2 et
