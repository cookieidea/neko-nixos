# Windows + NixOS 双系统

本文针对 UEFI + GPT 的 Windows + NixOS 双系统，并配合本仓库当前的 GRUB、Btrfs 与独立 SWAP 设计。

## 目标

Windows 保留原有 EFI System Partition（ESP），NixOS 使用独立的 Btrfs 根分区和独立 SWAP：

```text
Windows ESP
└── /boot  ← NixOS 复用，不格式化

NixOS Btrfs
├── @
├── @home
├── @nix
└── @snapshots

SWAP
└── 休眠恢复
```

仓库当前 GRUB 配置启用 EFI、os-prober，并把 Windows 作为双系统扫描目标。

## 安装前检查

Windows 端建议确认：

- 使用 UEFI 启动
- 磁盘分区表为 GPT
- 关闭 Fast Startup（快速启动）
- 已为 NixOS 腾出未分配空间
- 开启 BitLocker 时确认恢复密钥可用

可以在 Windows 中使用：

```text
msinfo32
```

检查 BIOS 模式是否为 UEFI。

磁盘管理中确认系统磁盘使用 GPT。

## 分区

双系统安装时通常只需要新建 NixOS 所需分区：

| 分区 | 文件系统 | 用途 |
|------|----------|------|
| 现有 ESP | FAT32 | 复用为 /boot |
| 新建 SWAP | linux-swap | swap / 休眠 |
| 新建根分区 | Btrfs | NixOS |

当前仓库按 SWAP 至少接近或不小于物理内存的休眠方案设计。

**不要格式化 Windows 已有的 ESP。**

## 挂载示例

假设：

- Windows ESP：`/dev/nvme0n1p1`
- NixOS SWAP：`/dev/nvme0n1p6`
- NixOS Btrfs：`/dev/nvme0n1p7`

请先用 `lsblk` 确认真实设备名。

```bash
sudo -i

mkfs.btrfs -f -L nixos /dev/nvme0n1p7
mkswap -L SWAP /dev/nvme0n1p6

mount /dev/nvme0n1p7 /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@snapshots

umount /mnt

mount -o subvol=@,compress=zstd,noatime /dev/nvme0n1p7 /mnt
mkdir -p /mnt/{boot,home,nix,.snapshots}

mount -o subvol=@home,compress=zstd,noatime /dev/nvme0n1p7 /mnt/home
mount -o subvol=@nix,compress=zstd,noatime /dev/nvme0n1p7 /mnt/nix
mount -o subvol=@snapshots,noatime /dev/nvme0n1p7 /mnt/.snapshots

mount --mkdir /dev/nvme0n1p1 /mnt/boot
swapon /dev/disk/by-label/SWAP
```

检查：

```bash
findmnt /mnt
findmnt /mnt/boot
findmnt /mnt/home
findmnt /mnt/nix
swapon --show
```

## 生成硬件配置

生成当前机器的硬件配置：

```bash
nixos-generate-config --root /mnt
```

目标机器生成的：

```text
/mnt/etc/nixos/hardware-configuration.nix
```

必须保留。

本仓库的目录结构会把它放到：

```text
/mnt/etc/nixos/configuration/device/hardware-config.nix
```

不要直接复制另一台机器的 UUID 或文件系统信息。

## 安装仓库

推荐：

```bash
cd /tmp
git clone https://github.com/cookieidea/neko-nixos.git
cd neko-nixos

sudo bash install.sh cookie /mnt
```

脚本会自动：

1. 检查用户名
2. 从 `flake.nix` 读取 hostname
3. 只修改用户名数据源
4. 预构建自定义 packages
5. 保留目标机硬件配置
6. 部署仓库到 `/mnt/etc/nixos`
7. 执行 `nixos-install --flake`

自定义 package 预构建失败会直接终止安装。

## GRUB 与 Windows

本仓库使用 GRUB，并启用 os-prober。安装完成后运行一次 rebuild：

```bash
sudo nixos-rebuild switch --flake /etc/nixos#ATRI
```

然后检查 GRUB 菜单。

如果 Windows 项目没有出现，先确认 ESP：

```bash
findmnt /boot
ls /boot/EFI/Microsoft/Boot/bootmgfw.efi
```

再检查 os-prober 是否能看到 Windows。

## 手动 chainload

os-prober 不工作时，可以作为备用方案：

```nix
boot.loader.grub.extraConfig = ''
  menuentry "Windows 11" {
    search --fs-uuid --set=root <ESP-UUID>
    chainloader /EFI/Microsoft/Boot/bootmgfw.efi
  }
'';
```

把 <ESP-UUID> 换成真实 ESP UUID。

## Windows 快速启动

双系统下建议关闭 Windows Fast Startup。

原因不是“Linux 无法识别 NTFS”，而是 Windows 快速启动会让系统卷处于类似休眠的状态。此时不要在 Linux 中修改 Windows 系统分区。

尤其不要对处于休眠状态的 Windows 系统分区执行写操作。

## BitLocker

BitLocker 本身不会阻止 NixOS 安装到另一分区，但访问加密 Windows 数据需要对应恢复密钥或在 Windows 环境中处理。

安装、重分区和修复启动项前建议确认恢复密钥已经备份。

## 时间问题

双系统常见现象是 Windows 与 Linux 时间相差数小时。

检查：

```bash
timedatectl
timedatectl status
```

统一硬件时钟策略即可。不要让两个系统长期使用互相矛盾的 RTC 解释方式。

## 休眠

当前仓库使用独立 SWAP，并设置：

```nix
boot.resumeDevice = "/dev/disk/by-label/SWAP";
```

检查：

```bash
ls -l /dev/disk/by-label/SWAP
swapon --show
cat /sys/power/resume
```

如果休眠恢复失败，优先检查 SWAP 标签、SWAP 大小和 resume 配置。

## Windows 分区读取

Linux 读取 NTFS 时注意：

- Windows 已经休眠或启用 Fast Startup 时，不要写入系统分区
- BitLocker 分区可能无法直接访问
- Windows 更新期间避免修改其 EFI / 系统分区
- 重要数据先备份

## 重装 Windows 后

Windows 重装可能重建 EFI 启动项或把 Windows Boot Manager 设置为默认启动项。

这种情况下通常不需要重新安装 NixOS，只需要：

1. 确认 NixOS 分区没有被删除
2. 重新从 UEFI 进入 NixOS
3. 检查 ESP 挂载
4. 重新安装或生成 GRUB 配置

## 常见问题

| 问题 | 优先检查 |
|------|----------|
| GRUB 没有 Windows | ESP、os-prober、UEFI 模式 |
| Windows 与 Linux 时间不一致 | `timedatectl`、RTC 策略 |
| Windows C 盘只读 | Fast Startup / 休眠状态 |
| BitLocker 分区打不开 | 恢复密钥 / Windows 环境 |
| NixOS 找不到根分区 | Btrfs UUID、subvol、hardware-config |
| 休眠无法恢复 | SWAP、SWAP 标签、resume |
| 重装 Windows 后 NixOS 消失 | EFI 启动项与 GRUB |

## 维护

日常更新：

```bash
sudo bash /etc/nixos/install.sh cookie
```

或者手动：

```bash
sudo nixos-rebuild switch --flake /etc/nixos#ATRI
```

不要因为一次 Windows 更新就格式化整个 ESP。
