#!/bin/sh
# 后台运行 wl-copy，避免 Neovim 的 clipboard provider 死等子进程退出而卡死。
#
# 背景：本机是 Wayland（UKUI on Wayland，合成器 ukui-kwin_wayland）。
#   wl-copy 拷完默认会 fork 到后台持有剪贴板；但 Neovim 的 clipboard provider
#   有时仍会等它的进程树 → 表现为 "+y 卡死。这里再显式用 & 后台化，
#   让本脚本立即退出，Neovim 不再等待，剪贴板由后台的 wl-copy 继续持有。
#
# 前提：nvim 进程带 WAYLAND_DISPLAY（在 UKUI 终端里启动默认就有）。
#   老吴实测 OSC 52 在他的终端不生效，所以改用这个原生 Wayland 剪贴板方案。
/usr/bin/wl-copy "$@" >/dev/null 2>&1 &
