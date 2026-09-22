# Btrfs + GRUB/UEFI 安装

本文针对本仓库的 NixOS 单机配置：UEFI + GPT、Btrfs、独立 swap、GRUB。

## 适用范围

当前 flake 提供：

```text
nixosConfigurations.ATRI
system: x86_64-linux
default user: cookie
```

这是个人配置，不是通用硬件模板。换机器时必须重新生成 hardware configuration。

## 分区

推荐布局：

| 分区 | 文件系统 | 挂载/用途 |
|---|---|---|
| ESP | FAT32 | `/boot` |
| SWAP | linux-swap | swap / 休眠 |
| 根分区 | Btrfs | `/` |

Btrfs 子卷：

```text
@           → /
@home       → /home
@nix        → /nix
@snapshots  → /.snapshots
```

休眠需要可用于保存内存镜像的 swap。当前仓库的自动 `resumeDevice` 逻辑仅支持一个直接块设备 swap；swapfile、多个 swap、LUKS/LVM 映射需要手动处理。

## 1. 启动安装介质

检查网络和磁盘：

```bash
ping -c 3 nixos.org
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINTS
```

Wi-Fi 可使用：

```bash
nmtui
```

## 2. 创建文件系统

以下仅为示例，执行前确认设备名。

```bash
cfdisk /dev/nvme0n1

mkfs.fat -F32 -n BOOT /dev/nvme0n1p1
mkswap -L SWAP /dev/nvme0n1p2
mkfs.btrfs -f -L nixos /dev/nvme0n1p3
```

创建子卷：

```bash
mount /dev/nvme0n1p3 /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@snapshots

umount /mnt
```

## 3. 挂载

```bash
mount -o subvol=@,compress=zstd,noatime /dev/nvme0n1p3 /mnt
mkdir -p /mnt/{boot,home,nix,.snapshots}

mount -o subvol=@home,compress=zstd,noatime /dev/nvme0n1p3 /mnt/home
mount -o subvol=@nix,compress=zstd,noatime /dev/nvme0n1p3 /mnt/nix
mount -o subvol=@snapshots,noatime /dev/nvme0n1p3 /mnt/.snapshots
mount /dev/nvme0n1p1 /mnt/boot

swapon /dev/disk/by-label/SWAP
```

检查：

```bash
findmnt /mnt
findmnt /mnt/boot
findmnt /mnt/home
findmnt /mnt/nix
findmnt /mnt/.snapshots
swapon --show
```

## 4. 生成硬件配置

```bash
nixos-generate-config --root /mnt
```

生成：

```text
/mnt/etc/nixos/hardware-configuration.nix
```

该文件记录目标机的文件系统、swap 和硬件模块。

**不要复制其他机器的 hardware configuration。**

本仓库安装脚本会把目标机生成的文件保存为：

```text
/mnt/etc/nixos/configuration/device/hardware-config.nix
```

## 5. 安装仓库

```bash
cd /tmp
git clone https://github.com/cookieidea/neko-nixos.git
cd neko-nixos

sudo bash install.sh cookie /mnt
```

新装流程：

```text
校验参数
  ↓
读取 hostname
  ↓
更新 username
  ↓
保留目标 hardware-config
  ↓
复制仓库到 /mnt/etc/nixos
  ↓
构建目标 system.build.toplevel
  ↓
nixos-install
  ↓
设置用户密码
```

完整闭包构建失败时，脚本会再单独构建 flake 暴露的自定义 package 用于定位失败范围。

## 6. 首次启动

```bash
reboot
```

检查：

```bash
uname -r
findmnt /
findmnt /home
findmnt /nix
swapon --show
```

检查 generation：

```bash
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```

检查 Snapper：

```bash
sudo snapper -c root list
sudo snapper -c home list
```

## 7. 密码与 SSH

安装脚本会在 `nixos-install` 后交互执行：

```bash
passwd <用户名>
```

用户密码不会写入 Nix 配置。

SSH 只允许 public key authentication，并禁止 root 直接登录。

## 8. 休眠

当前自动配置要求 `swapDevices` 中存在且仅存在一个直接块设备 swap。

检查：

```bash
swapon --show
cat /sys/power/resume
cat /proc/cmdline
```

休眠：

```bash
systemctl hibernate
```

`boot.resumeDevice` 应对应实际用于保存休眠镜像的 swap 设备。swapfile 需要 offset；LUKS/LVM 等映射设备通常需要显式指定 resume 设备。

## 9. Snapper

查看快照：

```bash
sudo snapper -c root list
sudo snapper -c home list
```

手动创建：

```bash
sudo snapper -c root create -d "before-change"
sudo snapper -c home create -d "before-change"
```

NixOS generation 和 Btrfs snapshot 是两套不同的回滚机制。

## 10. 常见问题

### hardware-config 不正确

重新生成：

```bash
nixos-generate-config --root /mnt
```

然后重新运行安装脚本。

### 安装时内存不足

可在 live environment 中启用临时 zram，再运行安装脚本。

### 找不到根分区

检查：

```bash
findmnt /mnt
findmnt /mnt/home
findmnt /mnt/nix
```

并检查生成的 hardware configuration 中的 UUID 与 subvolume。

### 休眠失败

检查：

```bash
swapon --show
cat /sys/power/resume
cat /proc/cmdline
```

确认 swap 足够、resume 设备正确且内核命令行包含对应配置。

## 11. 安装后的结构

```text
/etc/nixos/
├── flake.nix
├── flake.lock
├── install.sh
├── configuration/
│   ├── system.nix
│   ├── home.nix
│   ├── modules.nix
│   ├── device.nix
│   └── device/
│       └── hardware-config.nix
├── docs/
└── secrets/
```

### 参考

- https://wiki.nixos.org/wiki/NixOS_Installation_Guide
- https://wiki.nixos.org/wiki/Nixos-generate-config
- https://wiki.nixos.org/wiki/Power_Management
- https://wiki.nixos.org/wiki/SSH
