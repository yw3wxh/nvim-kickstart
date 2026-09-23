#!/usr/bin/env bash
#
# 装 CodeLLDB —— 给 nvim-dap 用的 C++/C 调试后端（基于 LLVM 的 lldb）
#
# 为什么需要这个脚本：
#   本机 gdb 是 9.2，不支持 DAP 协议（要 gdb 14+ 才有 --interpreter=dap）；
#   系统里也**没有 lldb**（只有 clang 10，没装 lldb 组件）。
#   所以要在 nvim 里图形化调试 C++，只能额外装一个 DAP 后端。
#
#   选 CodeLLDB 而不是微软的 cpptools，原因：
#     - CodeLLDB 是 Rust 写的，静态链接程度高，要求 glibc 2.18+
#       本机是 aarch64 + glibc 2.31，比 cpptools 更稳
#     - 自带整套 lldb，不依赖系统里有没有装 LLVM
#     - nvim-dap 对它的支持很成熟
#
# 为什么不能全自动：
#   GitHub 的 release 资源（release-assets.githubusercontent.com）在这台机器上
#   被网络挡住了 —— 走代理 502，直连超时，换 Gitee 镜像也没有，GitHub API 下载
#   也是 302 到同一个域名。所以下载这一步得在网络好的时候做。
#
# 怎么用（任选一种）：
#   A. 网络好的时候直接跑：
#        bash scripts/install-codelldb.sh
#   B. 自己用浏览器 / 别的机器下好 vsix，放到当前目录，再跑：
#        bash scripts/install-codelldb.sh          # 会自动发现当前目录的 vsix
#   C. 指定版本：
#        bash scripts/install-codelldb.sh 1.12.3
#
# 装完之后重启 nvim 就能用，配置会自动生效（见 lua/custom/plugins/debug.lua）。
#
set -euo pipefail

VERSION="${1:-1.12.3}"
ARCH="$(uname -m)"

case "$ARCH" in
aarch64 | arm64) PLATFORM="arm64" ;;
x86_64) PLATFORM="x64" ;;
*)
  echo "不支持的架构: $ARCH（这台机器应该是 aarch64）"
  exit 1
  ;;
esac

VSIX_NAME="codelldb-linux-${PLATFORM}.vsix"
URL="https://github.com/vadimcn/codelldb/releases/download/v${VERSION}/${VSIX_NAME}"
DEST="${HOME}/.local/share/nvim-dap/codelldb"

echo "架构: ${ARCH}  版本: ${VERSION}  目标: ${DEST}"

# 当前目录已经有下载好的 vsix 就直接用，不再去联网
LOCAL_VSIX="./${VSIX_NAME}"
if [ -f "$LOCAL_VSIX" ]; then
  echo "发现当前目录已有 ${VSIX_NAME}，直接用它"
  VSIX="$LOCAL_VSIX"
else
  VSIX="$(mktemp -d)/${VSIX_NAME}"
  echo "下载 ${URL}"
  echo "（如果这一步卡住或报 502，说明网络还是不通，"
  echo "  就自己想办法把 ${VSIX_NAME} 弄到当前目录，再重跑本脚本）"
  curl -fL --progress-bar "$URL" -o "$VSIX"
fi

echo "解压到 ${DEST} ..."
mkdir -p "$DEST"
unzip -q -o "$VSIX" -d "$DEST"

# CodeLLDB 的适配器可执行文件
ADAPTER="${DEST}/extension/adapter/codelldb"
if [ ! -f "$ADAPTER" ]; then
  echo "解压完了但没找到 ${ADAPTER}"
  echo "vsix 里的内容："
  ls -R "$DEST" | head -30
  exit 1
fi

chmod +x "$ADAPTER"
chmod +x "${DEST}/extension/lldb/bin/"* 2>/dev/null || true

echo
echo "装好了：${ADAPTER}"
"$ADAPTER" --version 2>&1 | head -2 || true
echo
echo "现在重启 nvim，打开一个 .cpp 文件按 <F9> 打断点、<F5> 启动调试即可。"
