# 维护说明

本文只记录本仓库的实现约定。

## 目录边界

```text
configuration/
├── system/    # 系统基础
├── device/    # 本机硬件
├── modules/   # 系统功能与服务
├── home/      # Home Manager
└── pkgs/      # 自定义 package
```

按职责拆分。简单包列表不拆成独立模块；复杂 derivation 再使用目录。

## hardware-config

`configuration/device/hardware-config.nix` 来自目标机的 `nixos-generate-config`。

全新安装：

```bash
nixos-generate-config --root /mnt
```

安装脚本会把目标机生成的 `hardware-configuration.nix` 保存到仓库结构中的 `configuration/device/hardware-config.nix`。

不要复制其他机器的 UUID。

## flake

`flake.nix` 是以下数据的入口：

- username
- hostname
- system
- inputs
- NixOS configuration
- Home Manager
- 自定义 packages
- formatter
- checks

安装脚本只修改 `username`。

## 安装脚本

### 全新安装

```text
检查
↓
读取 hostname
↓
更新 username
↓
注入 hardware-config
↓
构建目标 system.build.toplevel
↓
nixos-install
↓
设置用户密码
```

完整闭包失败时，再单独构建 flake 暴露的自定义 package 定位问题。

### 系统更新

```text
staging
↓
保留本机 hardware-config
↓
构建目标 system.build.toplevel
↓
flake check
↓
dry-build
↓
替换 /etc/nixos
↓
switch
```

switch 失败时恢复原配置源。

## 运行时库

不要在整个用户 session 设置 `LD_LIBRARY_PATH`。

程序需要额外库时优先使用专用 wrapper。

## Flatpak

Flatpak 由 `configuration/modules/flatpak.nix` 管理。

`flake.lock` 不锁定 Flatpak 应用版本，除非配置明确指定 commit。

当前使用 `uninstallUnmanaged = true`，未声明应用会在 activation 时被移除。

Flatpak 数据位于 `/var/lib/flatpak` 和用户目录，不等同于 Nix store。

## Snapper

当前分别对 `/` 和 `/home` 建立 Snapper 配置：

```text
root → /
home → /home
```

`NUMBER_LIMIT` 与 `NUMBER_MIN_AGE` 控制快照清理。

## 休眠

当前 `configuration/device/resume.nix` 只自动处理一个直接块设备 swap。

不适用：

- swapfile
- 多个 swap
- 需要映射后的 LUKS/LVM swap

这些情况显式设置 `boot.resumeDevice`。swapfile 还需要 offset。

## SSH

当前只允许 public key authentication，并禁止 root 直接登录。

公钥使用：

```nix
users.users.<name>.openssh.authorizedKeys.keys
```

声明。

## Wayland

桌面主环境是 Wayland，niri 使用 xwayland-satellite 提供 X11 兼容。

## GPU

GPU 配置位于 `configuration/device/gpu.nix`，包括：

- amdgpu
- Vulkan
- 32 位图形
- OpenCL
- ROCm
- Ollama
- I2C / DDC

## 网络端口

`configuration/system/networking.nix` 只设置基础防火墙。

服务端口由对应模块声明：

```text
Minecraft → modules/minecraft.nix
dsh → modules/dsh.nix
KDE Connect → modules/services/kdeconnect.nix
```

## systemd --user

systemd user 会话与 login shell 的环境可能不同。

需要特殊环境变量的 user service，应确认 session environment 是否包含所需变量。

## Home Manager

当前同时使用：

```text
home.file
xdg.configFile
xdg.dataFile
home.activation
```

静态配置使用 HM；运行时需要写入的配置使用可写副本。

## 自定义 package

统一入口：

```text
configuration/pkgs/default.nix
```

独立构建：

```bash
nix build .#niri-sidebar
```

简单 wrapper 不建立深层目录。

## Cache

当前使用 nixpkgs mirror 和多个 Cachix。

新增 cache 时记录 URL、用途和 public key。

## 更新

```bash
nix flake update
git diff -- flake.lock
sudo nixos-rebuild dry-build --flake /etc/nixos#ATRI
```

确认后再 switch。

## 检查

```bash
nix flake check
nix fmt
```

当前 flake check 主要执行 deadnix。

## 排障

systemd：

```bash
systemctl --user status <unit>
journalctl --user -u <unit> -b
```

niri：

```bash
niri msg layers
niri msg --json windows
```

GPU：

```bash
radeontop
vainfo
```

先看日志和实际状态，再改配置。
