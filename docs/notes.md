# 维护说明与已知约束

这份文档不是“通用 NixOS 教程”，而是本仓库当前实现的维护手册。

## 1. 先理解目录边界

当前仓库采用“职责优先”的拆分方式：

```text
configuration/
├── system.nix       # 系统入口
├── home.nix         # Home Manager 入口
├── modules.nix      # 系统功能模块入口
├── device.nix       # 硬件入口
├── system/          # 系统基础
├── device/          # 本机硬件
├── modules/         # 功能 / 服务
├── home/            # Home Manager
└── pkgs/            # 自定义 packages
```

不要为了“模块化”把每一个软件都拆成一个文件。

当前规则：

- 一组纯包列表可以继续聚合
- 独立功能、独立生命周期或有明显副作用的功能单独成文件
- 复杂 derivation 使用目录
- 简单 derivation 可以使用单个 `.nix`
- Python / Rust / Java 等工具链不需要为了语言本身建立一层文件夹

## 2. hardware-config 是本机状态

文件：

```text
configuration/device/hardware-config.nix
```

来自 `nixos-generate-config` 的机器相关信息。

它包含文件系统设备、UUID、EFI、swap 等硬件绑定信息。

换机器时：

```bash
nixos-generate-config --root /mnt
```

然后保留新机器生成的 hardware configuration。

不要直接复制 ATRI 的 UUID。

## 3. flake 的数据源

当前 `flake.nix` 集中定义：

- username
- hostname
- target system
- flake inputs
- 自定义 packages
- Home Manager extraSpecialArgs
- NixOS configuration
- formatter
- static checks

用户名当前主要数据源：

```nix
username = "cookie";
```

安装脚本只修改这一处，不再做全仓库 `sed s/cookie/new/g`。

## 4. install.sh 不只是复制文件

安装脚本有两种模式。

### 新系统

```bash
sudo bash install.sh <用户名> /mnt
```

流程：

```text
检查环境
  ↓
读取 hostname
  ↓
修改 username
  ↓
预构建自定义 packages
  ↓
保留目标机 hardware config
  ↓
部署到 /mnt/etc/nixos
  ↓
nixos-install
```

### 已安装系统

```bash
sudo bash /etc/nixos/install.sh <用户名>
```

更新流程：

```text
准备 staging
  ↓
保留当前 hardware-config
  ↓
nix flake check
  ↓
nixos-rebuild dry-build
  ↓
替换 /etc/nixos
  ↓
nixos-rebuild switch
```

这样可以避免更新过程中先删除旧配置，失败后留下半套仓库。

## 5. 不要重新引入全局 LD_LIBRARY_PATH

以前曾经把部分运行库放进整个用户 session 的 `LD_LIBRARY_PATH`。

当前已经移除。

原因是一个程序需要的运行库不应该污染所有程序的动态链接环境。

现在采用：

```text
需要特殊库
    ↓
对应程序自己的 wrapper
```

Minecraft、ABDM 等需要的运行库由对应 wrapper 或启动配置提供。

如果新软件需要特殊库，优先给它做 wrapper，不要直接修改全局 session。

## 6. mark-shot Python 环境

mark-shot 的 OCR / 码识别后端过去在 activation 中：

```text
python -m venv
pip install ...
```

现在已经改成 Nix 构建的 Python 环境。

这样做是为了：

- 固定依赖
- 支持离线 switch
- 避免 activation 联网
- 避免同一配置在不同时间解析出不同版本

因此不要再把 `pip install` 塞回 Home Manager activation。

## 7. Flatpak

Flatpak 单独位于：

```text
configuration/modules/flatpak.nix
```

它负责：

- Flatpak enable
- Flathub remote
- remote mirror
- 应用集合
- QQ / 微信权限 override
- Open Orpheus session bus

这里的 Flatpak 应用不是像 Nix derivation 那样完全由 `flake.lock` 锁版本。

所以升级时应意识到：

```text
Nix 输入版本 ≠ Flatpak 应用版本
```

Flatpak remote 发生变化时，应用解析结果也可能变化。

## 8. Astral

Astral 当前通过 flake package 使用上游 Release：

```text
configuration/pkgs/tools/networking/astral/
```

不再依赖本机缓存 bundle 或额外的 Astral build script。

Astral core 由 GUI 管理。

如果需要 TUN 权限：

```bash
sudo setcap cap_net_admin=ep ~/.local/share/astral-core/app/astral-core
```

注意：core 更新后可能需要重新设置 capability。

当前设计没有为 Astral 增加常驻 systemd 服务或开机自启。

## 9. Noctalia 配置

Noctalia 在 Home Manager 中启用，但当前关闭其 systemd service：

```nix
programs.noctalia.systemd.enable = false;
```

桌面启动由 niri：

```text
spawn-at-startup "noctalia"
```

负责。

部分 Noctalia 配置需要由 activation 转成用户可写文件，因为 Noctalia 会修改主题、palette 等内容。

因此看到：

```text
~/.config/noctalia/config.toml
```

不是普通的只读 HM symlink，而是刻意保留可写副本。

## 10. niri 配置

主入口：

```text
configuration/home/dotfiles/config/niri/config.kdl
```

其他设置拆成：

```text
monitor.kdl
effects.kdl
input__custom__.kdl
layout.kdl
animations.kdl
rules.kdl
binds.kdl
cursor.kdl
__custom__.kdl
```

其中 __custom__ 文件属于用户可保留的扩展点。

更新时不要随便删除它们。

## 11. Wayland 与 XWayland

当前桌面以 Wayland 为主。

niri 配置使用：

```text
xwayland-satellite
```

为部分只支持 X11 的程序提供兼容层。

QQ / 微信的 Flatpak 配置还显式处理了 X11 socket。

不要为了兼容个别应用，把整个桌面强行切换回 X11。

## 12. GPU

当前设备是 AMD。

GPU 模块同时处理：

- amdgpu
- Mesa / Vulkan
- 32 位图形
- OpenCL
- ROCm
- Ollama
- I2C / DDC
- /opt/rocm

修改 GPU 设置时要注意这些配置互相有依赖，不要只删掉其中一段而留下其他路径。

## 13. 防火墙端口归属

基础网络模块只负责防火墙开关。

功能模块自己声明自己的端口，例如：

```text
Minecraft → modules/minecraft.nix
dsh       → modules/dsh.nix
KDE Connect → modules/services/kdeconnect.nix
```

这样删除功能时不会把孤立的端口规则留在 `networking.nix`。

新增网络服务时优先遵循这个模式。

## 14. systemd --user

niri 会通过 systemd user session 启动，因此：

```text
登录 shell 能看到的环境变量
```

不一定等于：

```text
systemd --user 服务能看到的环境变量
```

当前开发工具链环境集中在：

```text
configuration/home/lib.nix
```

并同时用于 session 与 user systemd。

如果新增一个需要 PATH / JAVA_HOME / PYTHONPATH 的 user service，先检查它是否真的继承了对应变量。

## 15. Home Manager 的两个世界

不要把所有文件都当成普通 symlink。

当前仓库同时使用：

```text
home.file
xdg.configFile
xdg.dataFile
home.activation
```

大原则：

- 静态、只读配置 → HM source
- 程序运行时会修改的文件 → activation 建立可写副本
- 与 GC 生命周期无关的实际用户数据 → 不要强制由 Nix 托管

## 16. 自定义 packages

统一入口：

```text
configuration/pkgs/default.nix
```

flake 暴露后可以：

```bash
nix build .#niri-sidebar
```

维护时不要为了一个简单 wrapper 建立非常深的目录。

复杂 package 可以使用：

```text
configuration/pkgs/<category>/<name>/
```

并在里面维护 patch、资源、src 等辅助文件。

## 17. Nix cache

当前配置使用多个 substituter / Cachix。

不要随意增加第三方 binary cache。

新增 cache 时至少记录：

```text
来源
用途
trusted public key
```

最好让 cache 和某个 flake input / 项目存在明确对应关系。

## 18. 更新依赖

普通更新：

```bash
nix flake update
```

然后检查：

```bash
git diff -- flake.lock
```

再：

```bash
sudo nixos-rebuild dry-build --flake /etc/nixos#ATRI
```

确认没有问题后再 switch。

不要在没有检查 lockfile 变化的情况下连续大范围更新。

## 19. 格式化与检查

格式化：

```bash
nix fmt
```

检查：

```bash
nix flake check
```

当前仓库的 flake check 重点是 deadnix。

statix 可以手动执行：

```bash
nix run nixpkgs#statix -- check .
```

不要把第三方 package 源码的风格问题当成仓库自身配置问题。

## 20. 排障命令

### systemd user

```bash
systemctl --user status <unit>
journalctl --user -u <unit> -b
```

### niri

```bash
niri msg layers
niri msg --json windows
```

### Noctalia

```bash
noctalia msg wallpaper-get
```

### polkit

```bash
pkaction --action-id org.gtk.vfs.file-operations
```

### GPU

```bash
radeontop
vainfo
```

需要进一步判断时，优先看：

```text
journalctl
systemctl
niri msg
```

而不是先大改配置。

## 21. 一个重要原则

修改本仓库前先问：

> 这个问题属于系统基础、硬件、功能模块、Home Manager、dotfiles，还是自定义 package？

找到正确边界后再改。

宁可保持一个 150 行的功能模块，也不要为了追求“一文件一软件”把配置拆成二三十个只有几行内容的文件。
