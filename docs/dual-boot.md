# Windows + NixOS 双系统

本文针对 UEFI + GPT、Windows + NixOS、GRUB、Btrfs 和独立 swap。

## 布局

```text
Windows ESP
└── /boot   ← 复用，不格式化

NixOS Btrfs
├── @
├── @home
├── @nix
└── @snapshots

独立 SWAP
└── swap / 休眠
```

当前仓库的 GRUB 配置启用 EFI、os-prober 和 removable EFI 安装路径。

## 安装前

Windows 中确认：

- BIOS 模式为 UEFI
- 磁盘为 GPT
- 已关闭 Fast Startup
- NixOS 有可用的未分配空间
- BitLocker 恢复密钥已备份（如启用）

检查 BIOS 模式：

```text
msinfo32
```

## 分区

双系统通常只新建：

| 分区 | 文件系统 | 用途 |
|---|---|---|
| 现有 ESP | FAT32 | `/boot` |
| 新 SWAP | linux-swap | swap / 休眠 |
| 新根分区 | Btrfs | NixOS |

**不要格式化 Windows 正在使用的 ESP。**

SWAP 大小应按实际休眠需求规划；本仓库使用独立 swap。

## 挂载

设备名只是示例，执行前用 `lsblk` 确认。

```bash
sudo -i

mount /dev/nvme0n1p7 /mnt
# 按 install-btrfs.md 创建并挂载 Btrfs 子卷
mount --mkdir /dev/nvme0n1p1 /mnt/boot

swapon /dev/disk/by-label/SWAP
```

完整分区和 Btrfs 流程见 [install-btrfs.md](install-btrfs.md)。

## 生成目标硬件配置

挂载完成后：

```bash
nixos-generate-config --root /mnt
```

生成：

```text
/mnt/etc/nixos/hardware-configuration.nix
```

安装脚本会保留目标机配置，并部署到：

```text
/etc/nixos/configuration/device/hardware-config.nix
```

不要复制 ATRI 的 UUID 到其他机器。

## 安装

```bash
cd /tmp
git clone https://github.com/cookieidea/neko-nixos.git
cd neko-nixos

sudo bash install.sh cookie /mnt
```

新装时，脚本会先注入目标 hardware-config，再构建目标机完整 `system.build.toplevel`，最后运行 `nixos-install`。

## GRUB 和 Windows

当前配置：

- GRUB UEFI
- `useOSProber = true`
- `efiInstallAsRemovable = true`

检查 ESP：

```bash
findmnt /boot
ls /boot/EFI/Microsoft/Boot/bootmgfw.efi
```

如果 os-prober 没有发现 Windows，可使用 GRUB chainload：

```nix
boot.loader.grub.extraConfig = ''
  menuentry "Windows 11" {
    search --fs-uuid --set=root <ESP-UUID>
    chainloader /EFI/Microsoft/Boot/bootmgfw.efi
  }
'';
```

将 `<ESP-UUID>` 换成真实值。

## Windows Fast Startup

Fast Startup 会让 Windows 系统卷处于休眠状态。Linux 中不要对这种状态的 Windows 系统卷执行写操作。

## BitLocker

BitLocker 不影响把 NixOS 安装到其他分区，但访问加密 Windows 数据需要恢复密钥或在 Windows 中操作。

## 时间

检查：

```bash
timedatectl
```

双系统应统一 RTC 解释方式。

## 休眠

当前 `device/resume.nix` 只对单个直接块设备 swap 自动设置 `boot.resumeDevice`。

不要手动添加旧的固定路径配置。

检查：

```bash
swapon --show
cat /sys/power/resume
cat /proc/cmdline
```

swapfile 需要 offset；LUKS/LVM 等映射设备通常需要显式配置 resume 设备，因此不使用仓库的自动推导。

## Windows 分区

- Windows 休眠或启用 Fast Startup 时不要写 Windows 系统分区
- BitLocker 分区可能无法直接访问
- 修改 EFI 前先备份重要数据

## 重装 Windows 后

如果 Windows 重装覆盖 EFI 启动项：

1. 确认 NixOS 分区没有被删除。
2. 从 UEFI 启动 NixOS。
3. 确认 ESP 挂载到 `/boot`。
4. 重新安装或生成 GRUB 启动配置。

## 常见问题

| 问题 | 检查 |
|---|---|
| GRUB 没有 Windows | UEFI、ESP、os-prober |
| Windows 时间错误 | `timedatectl`、RTC 设置 |
| Windows 分区只读 | Fast Startup / 休眠 |
| BitLocker 数据不可访问 | 恢复密钥 |
| NixOS 找不到根分区 | UUID、Btrfs subvolume、hardware-config |
| 休眠失败 | `swapon --show`、`resumeDevice`、`/proc/cmdline` |
| 重装 Windows 后 NixOS 消失 | EFI 启动项、GRUB |

## 日常更新

```bash
sudo bash /etc/nixos/install.sh cookie
```

或者：

```bash
sudo nixos-rebuild switch --flake /etc/nixos#ATRI
```

不要因为 Windows 更新而重新格式化整个 ESP。

### 参考

- https://wiki.nixos.org/wiki/NixOS_Installation_Guide
- https://wiki.nixos.org/wiki/Power_Management
- https://wiki.nixos.org/wiki/SSH
