# 维护说明

本文记录本仓库的实现约定。

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

安装脚本会把目标机生成的硬件配置部署到：

```text
configuration/device/hardware-config.nix
```

不要复制其他机器的 UUID。

## flake

`flake.nix` 统一管理：

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
准备源码
↓
设置 username
↓
注入 hardware-config
↓
预构建
↓
nixos-install
↓
设置密码
```

### 系统更新

```text
staging
↓
保留 hardware-config
↓
预构建
↓
flake check
↓
dry-build
↓
替换 /etc/nixos
↓
switch
```

`switch` 失败时恢复旧配置源。

引导阶段通过 `NIX_CONFIG` 临时追加缓存；正式系统由 `system/nix.nix` 管理。引导配置不会写入 live environment 的 `/etc/nix/nix.conf`。

## Nix 缓存

正式系统使用 Nix 默认的 `cache.nixos.org`，并通过 `extra-substituters` 追加国内 mirror 和项目 Cachix。

新增缓存时记录：

- URL
- 用途
- public key

不要把未验证的第三方镜像当作官方源替代品。

## Docker

`registry-mirrors` 只影响 Docker Hub。GHCR 等其他 registry 不会自动经过 Docker Hub mirror。

当前只保留两个实际使用的国内 Docker Hub mirror，避免堆积过多公共服务依赖。

## Flatpak

Flatpak 由 `configuration/modules/flatpak.nix` 管理。

当前 Flathub remote 使用 USTC 缓存；它不是完整镜像，缓存未命中时仍可能访问 Flathub 源站。

`flake.lock` 不锁定 Flatpak 应用版本，除非配置明确指定 commit。

当前使用 `uninstallUnmanaged = true`，未声明应用会在 activation 时被移除。

## Snapper

当前分别对 `/` 和 `/home` 建立 Snapper 配置：

```text
root → /
home → /home
```

`NUMBER_LIMIT` 与 `NUMBER_MIN_AGE` 控制快照清理。

## Generation

系统每周执行一次 generation 清理，当前保留最近 10 个 system / Home Manager generations。

generation 回滚：

```bash
sudo nixos-rebuild switch --rollback
```

## 休眠

当前 `configuration/device/resume.nix` 只自动处理一个直接块设备 swap。

swapfile、多 swap、LUKS/LVM 映射设备需要显式设置 `boot.resumeDevice`；swapfile 还需要 offset。

## SSH

当前只允许 public key authentication，并禁止 root 直接登录。

公钥使用：

```nix
users.users.<name>.openssh.authorizedKeys.keys
```

声明。

## Wayland

桌面主环境是 Wayland，niri 使用 xwayland-satellite 提供 X11 应用兼容。

## GPU

GPU 配置位于 `configuration/device/gpu.nix`，包括：

- amdgpu
- Vulkan
- 32 位图形
- OpenCL
- ROCm
- Ollama
- I2C / DDC

`configuration/system/boot.nix` 保留 `amdgpu.ppfeaturemask=0xffffffff`，因为本机 LACT Overdrive 依赖该 power feature mask。

不再使用 `split_lock_mitigate=0` 或 `clearcpuid=514` 这类全局内核参数。

## 网络端口

`configuration/system/networking.nix` 只设置基础防火墙。

服务端口由对应模块声明：

```text
Minecraft → modules/minecraft.nix
SSH → modules/services/openssh.nix
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

CI 主要执行静态检查和 NixOS 配置求值，不等同于完整桌面闭包构建；完整构建由安装/更新脚本在目标机执行。

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
