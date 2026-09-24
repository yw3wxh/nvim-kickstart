#!/bin/sh
# 非阻塞读取系统剪贴板，防止 nvim 的 paste provider 卡死。
#
# 背景：clipboard='unnamedplus' 让普通 p（粘贴）也读 '+' 寄存器，
#   于是会调 wl-paste。而 wl-paste 在「剪贴板为空 / 还没内容」时会一直阻塞等待，
#   → nvim 主线程挂起、连 :qa 都退不出（老吴遇到的「经常性卡死」）。
# 修复：
#   1) 用 timeout 限死 1 秒，超时即返回空内容 —— nvim 绝不卡死；
#   2) 自动补 WAYLAND_DISPLAY（同 wl-copy-bg.sh）：某些启动方式下 nvim 进程没拿到它，
#      wl-paste 连不上合成器也会异常等待。
#   3) 无论成功/超时/出错都以退出码 0 结束，nvim 拿到（可能为空）的内容即可继续。
if [ -z "$WAYLAND_DISPLAY" ]; then
  uid=$(id -u)
  for d in "$XDG_RUNTIME_DIR" "/run/user/$uid"; do
    if [ -n "$d" ] && [ -S "$d/wayland-0" ]; then
      export WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR="$d"
      break
    fi
  done
fi

# 超时保护：1 秒内拿不到内容就放弃，避免 nvim 主线程被拖死
if command -v timeout >/dev/null 2>&1; then
  timeout 1 /usr/bin/wl-paste "$@" 2>/dev/null
else
  /usr/bin/wl-paste "$@" 2>/dev/null &
  bgpid=$!
  # 没 timeout 命令时的兜底：睡 1 秒后若还没结束就杀掉
  sleep 1
  if kill -0 "$bgpid" 2>/dev/null; then kill "$bgpid" 2>/dev/null; fi
  wait "$bgpid" 2>/dev/null
fi

# 关键：绝不以非 0 退出，否则 nvim 会以为读剪贴板出错而反复重试/卡顿
exit 0
