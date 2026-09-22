# neko-nixos

个人 NixOS 26.05 + Home Manager 配置，以 Flake 管理单机桌面系统。

| 项目 | 当前值 |
|---|---|
| 主机 | **ATRI** |
| 架构 | **x86_64-linux** |
| 用户 | **cookie** |
| 桌面 | **niri + Noctalia + Noctalia Greeter** |
| 内核 | **CachyOS RT-BORE** |
| GPU | **AMD** |

## 功能

- Wayland 桌面、输入法、PipeWire、Bluetooth
- Steam、Proton-GE、GameMode、Minecraft
- Waydroid、libvirt、Docker、distrobox
- AMD 图形栈、OpenCL、ROCm、Ollama
- Nautilus、KDE Connect、OBS、XDG portal、AppImage
- Flatpak、agenix、Home Manager
- 自定义 Nix package
- 全新安装与已安装系统更新

## 目录

```text
.
├── flake.nix
├── flake.lock
├── install.sh
├── scripts/
├── configuration/
│   ├── system.nix
│   ├── home.nix
│   ├── modules.nix
│   ├── device.nix
│   ├── system/
│   ├── device/
│   ├── modules/
│   ├── home/
│   └── pkgs/
├── docs/
├── secrets/
└── skills/
```

入口：

```text
flake.nix
└── nixosConfigurations.ATRI
    ├── configuration/system.nix
    └── configuration/home.nix
```

`configuration/device/hardware-config.nix` 只保存目标机硬件配置。换机器或全新安装时必须重新生成。

## 全新安装

当前配置按 UEFI + GPT、Btrfs、独立 swap、GRUB 编写。

先完成分区、挂载，并生成目标机硬件配置：

```bash
nixos-generate-config --root /mnt
```

然后：

```bash
git clone https://github.com/cookieidea/neko-nixos.git
cd neko-nixos
sudo bash install.sh cookie /mnt
```

安装流程：

```text
检查参数
  ↓
准备源码与 hostname
  ↓
设置 username
  ↓
注入目标 hardware-config
  ↓
预构建 system.build.toplevel
  ↓
nixos-install
  ↓
设置用户密码
```

安装阶段通过 `NIX_CONFIG` 临时追加国内 Nix mirror 和项目 Cachix，不修改 live environment 的 `/etc/nix/nix.conf`。正式系统的缓存由 `configuration/system/nix.nix` 管理。

## 已安装系统更新

```bash
sudo bash /etc/nixos/install.sh cookie
```

更新流程：

```text
staging
  ↓
保留本机 hardware-config
  ↓
预构建 system.build.toplevel
  ↓
flake check
  ↓
dry-build
  ↓
替换 /etc/nixos
  ↓
switch
```

`switch` 失败时会恢复旧配置源。

## Nix 缓存

正式系统保留 Nix 默认的 `cache.nixos.org`，并通过 `extra-substituters` 追加：

- USTC
- TUNA
- Lantian Attic
- Noctalia Cachix
- NekoBox Cachix
- Numtide
- CookNixvim Cachix
- nix-community Cachix

这样不会因为配置国内镜像而移除官方缓存。

## Docker

Docker 的 `registry-mirrors` 只作用于 Docker Hub。当前配置使用：

```text
https://docker.1ms.run
https://docker.m.daocloud.io
```

GHCR 等其他 registry 仍使用自己的 registry 地址，不会自动经过 Docker Hub mirror。

## Flatpak

Flatpak 由 `configuration/modules/flatpak.nix` 管理。

当前 Flathub remote 使用 USTC 缓存。它不是完整 Flathub 镜像，缓存未命中时仍可能访问 Flathub 源站。

NixOS generation 可以恢复声明的应用集合、remote 和 override；Flatpak 实际内容位于 `/var/lib/flatpak`，未固定 commit 时回滚 generation 不保证恢复旧应用版本。

当前启用 `uninstallUnmanaged = true`，未声明的 Flatpak 应用会在 activation 时被清理。

## 回滚与清理

系统每周清理一次旧 generation，当前保留最近 **10 个 system / Home Manager generations**。

Snapper 独立管理 `/` 和 `/home` 的 Btrfs 快照，两套机制互不替代。

## 休眠

当前 `configuration/device/resume.nix` 只自动处理一个直接块设备 swap。

swapfile、多个 swap、LUKS/LVM 映射等情况不要使用自动推导，应显式设置 `boot.resumeDevice`；swapfile 还需要对应 offset。

## SSH

SSH 只允许 public key authentication，并禁止 root 直接登录。

公钥通过：

```nix
users.users.<name>.openssh.authorizedKeys.keys
```

声明。

## GPU

AMD GPU 使用 amdgpu + Mesa/RADV、OpenCL 和 ROCm。Ollama 使用 ROCm 包，并保留 LACT Overdrive 所需的 `amdgpu.ppfeaturemask`。

系统不再额外关闭 split-lock mitigation 或通过 `clearcpuid` 禁用 CPU 特性。

## 常用命令

应用：

```bash
sudo nixos-rebuild switch --flake /etc/nixos#ATRI
```

试构建：

```bash
sudo nixos-rebuild dry-build --flake /etc/nixos#ATRI
```

检查：

```bash
nix flake check
```

格式化：

```bash
nix fmt
```

更新 inputs：

```bash
nix flake update
```

构建自定义 package：

```bash
nix build .#niri-sidebar
```

回滚 generation：

```bash
sudo nixos-rebuild switch --rollback
```

## 文档

| 文档 | 内容 |
|---|---|
| [install-btrfs.md](docs/install-btrfs.md) | NixOS ISO、Btrfs、swap、休眠、Snapper、安装 |
| [dual-boot.md](docs/dual-boot.md) | Windows + NixOS、UEFI/GPT、GRUB |
| [keybindings.md](docs/keybindings.md) | niri 快捷键 |
| [notes.md](docs/notes.md) | 维护约定 |

## 参考

- [NixOS Installation Guide](https://wiki.nixos.org/wiki/NixOS_Installation_Guide)
- [nixos-generate-config](https://wiki.nixos.org/wiki/Nixos-generate-config)
- [Power Management](https://wiki.nixos.org/wiki/Power_Management)
- [SSH](https://wiki.nixos.org/wiki/SSH)
- [Flatpak](https://wiki.nixos.org/wiki/Flatpak)
