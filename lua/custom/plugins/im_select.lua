-- [[ im-select —— 退出插入模式时自动把输入法切回英文；插入模式也默认英文 ]]
--
-- 作用：普通模式和插入模式都默认用英文输入法；只有在你手动切到中文、打完字退出
--       到普通模式时，才自动切回英文，避免普通模式下中文输入法挡着 h/j/k/l 等按键。
--       进入插入模式时【不再恢复】上次用过的输入法，所以一进插入就是英文，不会跳中文。
--
-- 依赖（按运行环境不同，无需改下面的代码，程序会自动判断）：
--   - WSL / 原生 Windows：需要 Windows 侧 `im-select.exe` 在 PATH 里
--     （下载自 https://github.com/daipeihust/im-select ，x64 选 64-bit 版本）。
--   - Linux（银河麒麟等）：不需要额外二进制，直接用输入法框架自带的远程工具
--     fcitx5-remote / fcitx-remote / ibus 之一（取决于本机装的是哪个）。
--     ⚠ 本机是 aarch64，没有现成预编译的 im-select 二进制，走框架自带工具正好避开这个坑。
--
-- 英文输入法名（default_im_select）若不对，可按本机实际改：
--   fcitx5 -> 'keyboard-us'   用 `fcitx5-remote` 可查当前名
--   fcitx   -> '1'            用 `fcitx-remote` 可查
--   ibus    -> 'xkb:us::eng'  用 `ibus engine` 可查
--   WSL     -> '1033'         英文(美国)键盘 LCID
--
-- ⚠ WSL 前置条件（2026-10-02 排查实测）：Windows 必须【已安装 en-US 键盘布局】，
--   否则 `im-select.exe 1033` 会 exit=0 但静默不切换（没有任何报错！本机最初只有
--   zh-Hans-CN + 微软拼音，正是这个原因导致 InsertLeave 不生效）。
--   添加方法：Windows 设置 → 时间和语言 → 语言和区域 → 添加语言 English (United States)，
--   或 PowerShell: `Get-WinUserLanguageList` 后 `$l.Add('en-US'); Set-WinUserLanguageList $l -Force`。
--   排查手法：终端里直接跑 `im-select.exe 1033` 后 `im-select.exe` 读回，若仍返回 2052
--   即目标布局缺失，与 nvim 配置无关。

local function gh(repo) return 'https://github.com/' .. repo end

-- 平台判断集中在 lua/platform.lua（is_win_like = WSL 或原生 Windows，输入法在 Windows 侧要用 im-select.exe）
local platform = require('platform')

local cfg

if platform.is_win_like then
  -- WSL / 原生 Windows：调用 Windows 的 im-select.exe，切回英文(美国)键盘
  cfg = {
    default_command = 'im-select.exe',
    default_im_select = '1033',
  }
else
  -- Linux：按本机实际装了的输入法框架自动选对应工具和英文输入法名
  if vim.fn.executable('fcitx5-remote') == 1 then
    cfg = { default_command = 'fcitx5-remote', default_im_select = 'keyboard-us' }
  elseif vim.fn.executable('fcitx-remote') == 1 then
    cfg = { default_command = 'fcitx-remote', default_im_select = '1' }
  elseif vim.fn.executable('ibus') == 1 then
    cfg = { default_command = 'ibus', default_im_select = 'xkb:us::eng' }
  else
    vim.notify('im-select: 未检测到 fcitx5/fcitx/ibus，跳过输入法自动切换', vim.log.levels.WARN)
    return
  end
end

vim.pack.add { gh 'keaising/im-select.nvim' }

require('im_select').setup(vim.tbl_extend('force', {
  -- 触发切回英文的事件：离开插入模式、离开命令行
  set_default_events = { 'InsertLeave', 'CmdlineLeave' },
  -- 进入插入模式时【不恢复】上次用过的输入法（保持英文）。
  -- 设为空表，正是 im-select 官方推荐的“插入模式也默认英文”做法；
  -- 之前填 'InsertEnter' 会记住并恢复上次的输入法，导致一进插入就跳中文。
  set_previous_events = {},
  -- 没装二进制时别刷屏报错
  keep_quiet_on_no_binary = true,
  -- 异步切换，不卡界面
  async_switch_im = true,
}, cfg))
