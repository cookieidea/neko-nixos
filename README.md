# neko-nixos

个人 NixOS 26.05 + Home Manager 配置，以 flake 管理单机桌面系统。

当前主机：**ATRI**  
架构：**x86_64-linux**  
默认用户：**cookie**  
桌面：**niri + Noctalia + Noctalia Greeter**  
内核：**CachyOS RT-BORE**  
GPU：**AMD**

## 功能

- Wayland 桌面、输入法、PipeWire、Bluetooth
- Steam、Proton-GE、GameMode、Minecraft
- Waydroid、libvirt、Docker、distrobox
- AMD 图形栈、OpenCL、ROCm、Ollama
- Nautilus、KDE Connect、OBS、XDG portal、AppImage
- Flatpak、agenix、Home Manager
- 自定义 Nix package
- 全新安装与现有系统更新

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

系统入口：

```text
flake.nix
└── nixosConfigurations.ATRI
    ├── configuration/system.nix
    └── configuration/home.nix
```

`configuration/device/hardware-config.nix` 只保存机器相关配置。全新安装时使用目标机的 `nixos-generate-config` 生成结果。

## 全新安装

本仓库按 UEFI + GPT、Btrfs、独立 swap、GRUB 的方案编写。

先完成分区、挂载和目标机硬件配置：

```bash
nixos-generate-config --root /mnt
```

再运行：

```bash
git clone https://github.com/cookieidea/neko-nixos.git
cd neko-nixos
sudo bash install.sh cookie /mnt
```

新装流程：

```text
检查参数
  ↓
读取 hostname
  ↓
更新 username
  ↓
注入目标 hardware-config
  ↓
构建目标 system.build.toplevel
  ↓
nixos-install
  ↓
设置用户密码
```

完整闭包构建失败时，脚本会再单独构建 flake 暴露的自定义 package 用于定位失败范围。

## 已安装系统更新

```bash
sudo bash /etc/nixos/install.sh cookie
```

更新流程：

```text
准备 staging
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

switch 失败时会尝试恢复旧配置源。

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

## 休眠

当前 `configuration/device/resume.nix` 只自动处理**一个直接块设备 swap**。

swapfile、多个 swap、LUKS/LVM 映射等情况不要使用自动推导，应显式设置 `boot.resumeDevice`；swapfile 还需要对应的 offset。

## Snapper

当前分别对 `/` 和 `/home` 建立 Snapper 配置：

```text
root → /
home → /home
```

查看：

```bash
sudo snapper -c root list
sudo snapper -c home list
```

Snapper 回滚和 NixOS generation 回滚是两套独立机制。

## SSH

SSH 只允许 public key authentication，并禁止 root 直接登录。

公钥通过：

```nix
users.users.<name>.openssh.authorizedKeys.keys
```

声明。

## Flatpak

Flatpak 由 `configuration/modules/flatpak.nix` 管理。

NixOS generation 可以恢复声明的应用集合、remote 和 override；Flatpak 实际内容位于 `/var/lib/flatpak`，未固定 commit 时回滚 generation 不保证恢复旧应用版本。

当前启用 `uninstallUnmanaged = true`，未声明的 Flatpak 应用会被 activation 清理。

## 自定义 package

自定义 derivation 统一位于：

```text
configuration/pkgs/
```

由 `configuration/pkgs/default.nix` 暴露给 flake。

## 文档

| 文档 | 内容 |
|---|---|
| [install-btrfs.md](docs/install-btrfs.md) | NixOS ISO、Btrfs、swap、休眠、Snapper、安装 |
| [dual-boot.md](docs/dual-boot.md) | Windows + NixOS、UEFI/GPT、GRUB |
| [keybindings.md](docs/keybindings.md) | niri 快捷键 |
| [notes.md](docs/notes.md) | 维护约定 |

## 官方参考

- [NixOS Installation Guide](https://wiki.nixos.org/wiki/NixOS_Installation_Guide)
- [nixos-generate-config](https://wiki.nixos.org/wiki/Nixos-generate-config)
- [Power Management](https://wiki.nixos.org/wiki/Power_Management)
- [SSH](https://wiki.nixos.org/wiki/SSH)
- [Flatpak](https://wiki.nixos.org/wiki/Flatpak)
