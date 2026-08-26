# kickstart-modular.nvim

## 简介

*这是 [nvim-lua/kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) 的一个分支，把原来单一文件配置改成了多文件配置。*

一个作为 Neovim 起点的配置，特点是：

* 小巧
* 模块化
* 文档完整

它**不是** Neovim 发行版，而是你个人配置的起点。

## 安装

### 安装 Neovim

Kickstart.nvim 只支持最新版
['stable'](https://github.com/neovim/neovim/releases/tag/stable) 和最新
['nightly'](https://github.com/neovim/neovim/releases/tag/nightly) 的 Neovim。
如果遇到问题，请确保你至少使用的是最新的稳定版。大多数情况下，你可能希望通过[包管理器](https://github.com/neovim/neovim/blob/master/INSTALL.md#install-from-package)来安装 Neovim。
要检查你的 Neovim 版本，请运行 `nvim --version`，并确认版本不低于最新的
['stable'](https://github.com/neovim/neovim/releases/tag/stable) 版本。如果
你选择的安装方式只能得到过时的 Neovim 版本，请参考
[下方介绍的备选安装方式](#备选-neovim-安装方式)。

### 安装外部依赖

外部依赖：
- 基础工具：`git`、`make`、`unzip`、C 编译器（`gcc`）
- [ripgrep](https://github.com/BurntSushi/ripgrep#installation)、
  [fd-find](https://github.com/sharkdp/fd#installation)
- [tree-sitter CLI](https://github.com/tree-sitter/tree-sitter/blob/master/crates/cli/README.md#installation)
- 剪贴板工具（xclip/xsel/win32yank 或其他，视平台而定）
- [Nerd Font](https://www.nerdfonts.com/)：可选，用于提供各种图标
  - 如果你安装了它，请在 `init.lua` 中把 `vim.g.have_nerd_font` 设为 true
- Emoji 字体（仅 Ubuntu 需要，而且只在你想用 emoji 时才需要！）`sudo apt install fonts-noto-color-emoji`
- 语言环境配置：
  - 如果你想写 Typescript，需要 `npm`
  - 如果你想写 Golang，需要 `go`
  - 等等

> [!NOTE]
> 参见[安装配方](#分平台安装说明)获取额外的 Windows 和 Linux 专属说明
> 以及快速安装片段

### 安装 Kickstart

> [!NOTE]
> 请先[备份](#常见问题)你之前的配置（如果有的话）

Neovim 的配置位于以下路径，具体取决于你的操作系统：

| 操作系统 | 路径 |
| :- | :--- |
| Linux、MacOS | `$XDG_CONFIG_HOME/nvim`、`~/.config/nvim` |
| Windows（cmd）| `%localappdata%\nvim\` |
| Windows（powershell）| `$env:LOCALAPPDATA\nvim\` |

#### 推荐步骤

使用 GitHub 的
["Use this template"](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template)
按钮创建你自己的仓库副本，这样你就拥有一个可以自行修改的副本，然后根据你的操作系统，
使用下面的命令之一把新仓库克隆到你的机器上即可完成安装。

或者，如果你希望有更便捷的上游同步路径（例如，把你的配置放在单独的分支上，
并从上游对 `master` 进行 fast-forward），你也可以[fork](https://docs.github.com/en/get-started/quickstart/fork-a-repo)
这个仓库。参见 [#1740 的讨论](https://github.com/nvim-lua/kickstart.nvim/issues/1740)
了解两种方式的取舍。

> [!NOTE]
> 你的仓库 URL 看起来会像这样：
> `https://github.com/<your_github_username>/kickstart-modular.nvim.git`

你可能还希望把 `nvim-pack-lock.json` 从仓库的 `.gitignore` 文件中移除——
在 kickstart 仓库中忽略它是为了方便维护，但建议把它纳入版本控制（参见 `:help vim.pack-lockfile`）。

#### 克隆 kickstart.nvim

> [!NOTE]
> 如果你遵循了上面的推荐步骤（即从模板创建自己的仓库或 fork），
> 请把下面命令中的 `dam9000` 替换成 `<your_github_username>`

<details><summary> Linux 和 Mac </summary>

```sh
git clone https://github.com/dam9000/kickstart-modular.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
```

</details>

<details><summary> Windows </summary>

如果你使用 `cmd.exe`：

```
git clone https://github.com/dam9000/kickstart-modular.nvim.git "%localappdata%\nvim"
```

如果你使用 `powershell.exe`：

```
git clone https://github.com/dam9000/kickstart-modular.nvim.git "${env:LOCALAPPDATA}\nvim"
```

</details>

### 安装后配置

启动 Neovim

```sh
nvim
```

就这样！`vim.pack` 会从你的配置中安装所有插件。使用
`:lua vim.pack.update(nil, { offline = true })` 检查插件状态，
`:lua vim.pack.update()` 拉取更新（`:write` 应用更新，`:quit`
取消更新）。

#### 阅读友好的文档

请通读配置文件夹中的 `init.lua` 文件，了解更多
扩展和探索 Neovim 的信息。其中还包含
添加热门插件的一些示例。

> [!NOTE]
> 关于某个特定插件的更多信息，请查看其仓库的文档。


### 快速上手

[上手 Neovim 你唯一需要看的视频](https://youtu.be/m8C0Cq9Uv9o)

### 常见问题

* 如果我已经有了一份现有的 Neovim 配置该怎么办？
  * 你应该先备份它，然后删除所有相关文件。
  * 这包括你现有的 init.lua 以及 `~/.local` 中的 Neovim 文件，
    可以通过 `rm -rf ~/.local/share/nvim/` 删除。
* 我能否让现有配置与 kickstart 并行保留？
  * 可以！你可以使用 [NVIM_APPNAME](https://neovim.io/doc/user/starting.html#%24NVIM_APPNAME)`=nvim-NAME`
    来维护多个配置。例如，你可以把 kickstart 配置安装到 `~/.config/nvim-kickstart` 并创建一个别名：
    ```
    alias nvim-kickstart='NVIM_APPNAME="nvim-kickstart" nvim'
    ```
    当你使用 `nvim-kickstart` 别名运行 Neovim 时，它会使用这个替代的
    配置目录以及对应的本地目录
    `~/.local/share/nvim-kickstart`。你可以把这种方法应用到任何你想尝试的 Neovim
    发行版上。
* 如果我想"卸载"这套配置该怎么办：
  * 删除你的配置目录和本地数据目录（例如，
    `~/.config/nvim` 和 `~/.local/share/nvim`）。
* 为什么 kickstart 的 `init.lua` 是单个文件？把它拆分成多个文件不是更合理吗？
  * kickstart 的主要目的是作为教学工具和参考
    配置，让用户可以轻松地 `git clone` 作为自己配置的基础。
    随着你对 Neovim 和 Lua 的学习深入，你可以考虑把 `init.lua` 拆分成更小的部分。
    这里有一个在保持相同功能的同时完成拆分的 kickstart 分支：
    * [kickstart-modular.nvim](https://github.com/dam9000/kickstart-modular.nvim)
  * *注意：这正是把配置拆分成更小部分的那个分支。*
    原始的单一 `init.lua` 文件仓库在这里：
    * [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)
  * 关于这个话题的讨论可以在这里找到：
    * [Restructure the configuration](https://github.com/nvim-lua/kickstart.nvim/issues/218)
    * [Reorganize init.lua into a multi-file setup](https://github.com/nvim-lua/kickstart.nvim/pull/473)

### 分平台安装说明

下面你可以找到 Neovim 及其依赖的、按操作系统区分的安装说明。

安装完所有依赖后，继续执行[安装 Kickstart](#安装-kickstart) 步骤。

#### Windows 安装

<details><summary>Windows（使用 Microsoft C++ 生成工具和 CMake）</summary>
Kickstart 的默认配置对 `telescope-fzf-native.nvim` 仅使用 make。
如果 `make` 不可用，该插件会被跳过。

推荐：安装 `make`（参见下面的 chocolatey 部分）。

如果你想要纯 CMake 的方案，需要在两个地方自定义 `init.lua`：

1. 当 `cmake` 可用时包含 `telescope-fzf-native.nvim`：

```lua
if vim.fn.executable 'make' == 1 or vim.fn.executable 'cmake' == 1 then
  table.insert(plugins, gh 'nvim-telescope/telescope-fzf-native.nvim')
end
```

2. 在 `PackChanged` 钩子中，当 `make` 不可用时使用 CMake：

```lua
if name == 'telescope-fzf-native.nvim' then
  if vim.fn.executable 'make' == 1 then
    run_build(name, { 'make' }, ev.data.path)
  elseif vim.fn.executable 'cmake' == 1 then
    run_build(name, { 'cmake', '-S.', '-Bbuild', '-DCMAKE_BUILD_TYPE=Release' }, ev.data.path)
    run_build(name, { 'cmake', '--build', 'build', '--config', 'Release', '--target', 'install' }, ev.data.path)
  end
  return
end
```

关于构建细节参见 `telescope-fzf-native` 的文档：[构建说明](https://github.com/nvim-telescope/telescope-fzf-native.nvim#installation)。
</details>
<details><summary>Windows（使用 chocolatey 安装 gcc/make）</summary>
另外，你也可以安装不需要改动配置的 gcc 和 make，
最简单的方式是使用 choco：

1. 安装 [chocolatey](https://chocolatey.org/install)
既可以按照页面上的说明操作，也可以使用 winget，
在 **管理员** 身份的 cmd 中运行：
```
winget install --accept-source-agreements chocolatey.chocolatey
```

2. 使用 choco 安装所有依赖，先退出之前的 cmd，
打开一个新的（这样 choco 的路径才会生效），然后在 **管理员** 身份的 cmd 中运行：
```
choco install -y neovim git ripgrep wget fd unzip gzip mingw make tree-sitter
```
</details>
<details><summary>WSL（适用于 Linux 的 Windows 子系统）</summary>

```
wsl --install
wsl
sudo add-apt-repository ppa:neovim-ppa/unstable -y
sudo apt update
sudo apt install make gcc ripgrep fd-find tree-sitter-cli unzip git xclip neovim
```
</details>

#### Linux 安装
<details><summary>Ubuntu 安装步骤</summary>

```
sudo add-apt-repository ppa:neovim-ppa/unstable -y
sudo apt update
sudo apt install make gcc ripgrep fd-find tree-sitter-cli unzip git xclip neovim
```
</details>
<details><summary>Debian 安装步骤</summary>

```
sudo apt update
sudo apt install make gcc ripgrep fd-find tree-sitter-cli unzip git xclip curl

# 现在安装 nvim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo mkdir -p /opt/nvim-linux-x86_64
sudo chmod a+rX /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz

# 使其在 /usr/local/bin 中可用（发行版默认安装到 /usr/bin）
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/
```
</details>
<details><summary>Fedora 安装步骤</summary>

```
sudo dnf install -y gcc make git ripgrep fd-find tree-sitter-cli unzip neovim
```
</details>

<details><summary>Arch 安装步骤</summary>

```
sudo pacman -S --noconfirm --needed gcc make git ripgrep fd tree-sitter-cli unzip neovim
```
</details>

### 备选 Neovim 安装方式

在某些系统上，Neovim 官方推荐的[包管理器安装
方式](https://github.com/neovim/neovim/blob/master/INSTALL.md#install-from-package)
明显落后于最新版本，这并不罕见。如果是你的情况，
可以从下面这些已知能快速提供新版本 Neovim 的方式中挑选一种。
选择它们是因为它们很流行，而且让安装和更新
Neovim 到最新版本变得很容易。你还可以在
[这里](https://github.com/nvim-lua/kickstart.nvim/issues/1583)找到关于
可用方式的更多讨论。


<details><summary>Bob</summary>

[Bob](https://github.com/MordechaiHadad/bob) 是一个适用于
所有平台的 Neovim 版本管理器。只需安装
[rustup](https://rust-lang.github.io/rustup/installation/other.html)，
然后运行以下命令：

```bash
rustup default stable
rustup update stable
cargo install bob-nvim
bob use stable
```

</details>

<details><summary>Homebrew</summary>

[Homebrew](https://brew.sh) 是在 Mac 和 Linux 上很流行的包管理器。
只需使用 [`brew install`](https://formulae.brew.sh/formula/neovim) 安装即可。

</details>

<details><summary>Flatpak</summary>

Flatpak 是一个应用程序包管理器，允许开发者只打包一次，
即可在所有 Linux 系统上使用。只需[安装 flatpak](https://flatpak.org/setup/)
并配置[flathub](https://flathub.org/setup)，即可[安装 neovim](https://flathub.org/apps/io.neovim.nvim)。

</details>

<details><summary>asdf 和 mise</summary>

[asdf](https://asdf-vm.com/) 和 [mise](https://mise.jdx.dev/) 是工具版本管理器，
主要面向项目级的工具版本管理。不过两者也都支持在用户空间中
全局管理工具：

<details><summary>mise</summary>

[安装 mise](https://mise.jdx.dev/getting-started.html)，然后运行：

```bash
mise plugins install neovim
mise use neovim@stable
```

</details>

<details><summary>asdf</summary>

[安装 asdf](https://asdf-vm.com/guide/getting-started.html)，然后运行：

```bash
asdf plugin add neovim
asdf install neovim stable
asdf set neovim stable --home
asdf reshim neovim
```

</details>

</details>
