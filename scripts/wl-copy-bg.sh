#!/bin/sh
# 背景化运行 wl-copy，避免 Neovim 的 clipboard provider 死等子进程退出而卡死。
#
# 做法：先把 Neovim 通过 stdin 传来的内容收进临时文件，再后台启动 wl-copy 读该文件。
#   - 用临时文件而非直接管道：避免「脚本退出导致管道读端被关、wl-copy 丢内容」的竞态。
#   - 脚本自身立即退出：Neovim 不再等待，"+y 不卡死。
#   - 1 秒后删临时文件：此时 wl-copy 早已读走内容。
#
# 兼容：某些启动方式（如从 Electron 终端 / 启动器拉起）下 nvim 进程没拿到
#   WAYLAND_DISPLAY，导致 wl-copy 连不上合成器、拷出来是空的。这里补上默认值。
if [ -z "$WAYLAND_DISPLAY" ]; then
  uid=$(id -u)
  for d in "$XDG_RUNTIME_DIR" "/run/user/$uid"; do
    if [ -n "$d" ] && [ -S "$d/wayland-0" ]; then
      export WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR="$d"
      break
    fi
  done
fi
tmp=$(mktemp)
cat > "$tmp"
/usr/bin/wl-copy "$@" < "$tmp" >/dev/null 2>&1 &
( sleep 1; rm -f "$tmp" ) >/dev/null 2>&1 &
