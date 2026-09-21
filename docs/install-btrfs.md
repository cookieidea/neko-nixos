# Btrfs + GRUB/UEFI 安装指南

这份文档描述在 UEFI 机器上使用本仓库进行全新安装的流程。当前配置使用 Btrfs、独立 SWAP、GRUB，并为休眠与 Snapper 预留了结构。

## 适用场景

当前仓库的 flake 只有一个 NixOS 配置：

```text
nixosConfigurations.ATRI
system: x86_64-linux
default user: cookie
```

安装脚本允许传入其他合法用户名，但这是一个以个人机器为中心的配置。更换用户名或硬件后，应检查 dotfiles 与硬件相关路径。

## 分区建议

当前系统按下面的布局设计：

| 分区 | 建议 | 文件系统 | 挂载 |
|------|------|----------|------|
| ESP | ≥ 512 MiB | FAT32 | `/boot` |
| SWAP | ≥ 内存容量 | swap | swap / 休眠 |
| 根分区 | 其余空间 | Btrfs | `/` |

Btrfs 根分区使用这些子卷：

```text
@            → /
@home        → /home
@nix         → /nix
@snapshots   → /.snapshots
```

当前 `boot.resumeDevice` 指向标签为 `SWAP` 的交换分区，因此需要给 SWAP 使用这个标签：

```text
SWAP
```

> 设备名不一定是 `/dev/nvme0n1p1`。执行前请先用 `lsblk` 确认。

## 1. 从 NixOS ISO 启动

进入 minimal ISO 后先确认网络和磁盘：

```bash
ping -c 3 nixos.org
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINTS
```

如果使用 Wi-Fi，可以用 `nmtui` 建立连接。

## 2. 分区与格式化

以下示例假定：

- EFI：`/dev/nvme0n1p1`
- SWAP：`/dev/nvme0n1p2`
- Btrfs：`/dev/nvme0n1p3`

请替换成实际设备。

```bash
sudo -i

cfdisk /dev/nvme0n1

mkfs.fat -F32 -n BOOT /dev/nvme0n1p1
mkswap -L SWAP /dev/nvme0n1p2
mkfs.btrfs -f -L nixos /dev/nvme0n1p3
```

创建 Btrfs 子卷：

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
findmnt /mnt/home
findmnt /mnt/nix
findmnt /mnt/.snapshots
swapon --show
```

## 4. 生成目标机硬件配置

这是新机器安装时最重要的一步：

```bash
nixos-generate-config --root /mnt
```

它会生成：

```text
/mnt/etc/nixos/hardware-configuration.nix
```

这个文件包含当前机器的文件系统 UUID、EFI、swap 等信息。

**不要用仓库里另一台机器的硬件配置覆盖它。**

本仓库的安装脚本会把它转换到：

```text
/mnt/etc/nixos/configuration/device/hardware-config.nix
```

并优先保留目标机生成的版本。

## 5. 使用安装脚本

推荐直接让仓库的 `install.sh` 完成部署，而不是手工复制整个配置树。

例如：

```bash
cd /tmp
git clone https://github.com/cookieidea/neko-nixos.git
cd neko-nixos

sudo bash install.sh cookie /mnt
```

本仓库的脚本参数顺序固定为：第一个参数是用户名，第二个参数是挂载点。

推荐始终显式写成：

```bash
sudo bash install.sh <用户名> /mnt
```

不传用户名时，脚本会交互式询问用户名；在新装模式下仍需把挂载点作为第二个参数传入。

安装脚本会：

1. 校验用户名。
2. 读取仓库里的 hostname。
3. 只修改 `flake.nix` 的用户名数据源。
4. 预构建仓库自定义 package。
5. 保留目标机的硬件配置。
6. 部署仓库到 `/mnt/etc/nixos`。
7. 执行 `nixos-install --flake`。

任何自定义 package 预构建失败都会中止安装。

## 6. 安装完成后的第一次启动

安装结束后：

```bash
reboot
```

进入系统后检查：

```bash
uname -r
findmnt /
findmnt /home
findmnt /nix
swapon --show
```

检查 NixOS generation：

```sudo nix-env --list-generations --profile /nix/var/nix/profiles/system```

检查 Snapper：

```bash
sudo snapper -c root list
```

## 7. 设置用户密码

仓库配置不会把普通用户密码硬编码进 flake。

安装完成后可以在 TTY 中设置：

```bash
passwd cookie
```

换成其他用户名时使用实际用户名。

## 8. 休眠

当前配置使用：

```nix
boot.resumeDevice = "/dev/disk/by-label/SWAP";
```

所以休眠恢复依赖独立的 SWAP 分区，并且当前文档按“SWAP 至少与内存容量相当”设计。

检查：

```bash
cat /sys/power/resume
swapon --show
systemctl hibernate
```

如果休眠无法恢复，优先检查：

- SWAP 是否正常启用
- `/dev/disk/by-label/SWAP` 是否存在
- 内核 resume 参数是否正确
- 实际 SWAP 是否足够

## 9. Snapper

根文件系统的快照位于：

```text
/.snapshots
```

查看：

```bash
sudo snapper -c root list
```

建立快照：

```bash
sudo snapper -c root create -d "before-change"
```

实际回滚前先确认快照内容和当前挂载状态，不要把 Snapper 回滚与 NixOS generation 回滚混为一谈。

- NixOS generation：回滚系统声明配置和系统闭包。
- Snapper：回滚 Btrfs 文件系统快照。

## 常见问题

### `nixos-generate-config` 后硬件配置不见了

先检查：

```bash
ls -l /mnt/etc/nixos/hardware-configuration.nix
```

然后重新运行：

```bash
nixos-generate-config --root /mnt
```

安装脚本会负责把生成结果放到仓库要求的位置。

### 安装时 OOM

本仓库包含多个自构建 package，minimal ISO 上可能比较吃内存。可以先启用临时 zram：

```bash
modprobe zram
zramctl -f -s 16G
mkswap /dev/zram0
swapon -p 100 /dev/zram0
```

### Btrfs 子卷挂载失败

确认根分区确实是 Btrfs：

```bash
findmnt -n -o FSTYPE /mnt
```

应该得到：

```text
btrfs
```

### 安装后进入旧系统或没有 GRUB

确认机器以 UEFI 模式启动，并检查 ESP 是否挂载到 `/boot`。当前配置由 GRUB 负责启动管理。

## 完成后的结构

一个正常的新装系统最终应类似：

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
│   └── ...
├── docs/
└── secrets/
```

硬件信息位于：

```text
/etc/nixos/configuration/device/hardware-config.nix
```

它属于**当前机器**，后续换机时不要直接复制旧值。
