# Windows + NixOS 双系统安装指南

> 适用：**UEFI + GPT** 分区（Win10/11 默认）、与当前仓库配置（btrfs + GRUB + 休眠）配合。
> 目标布局：保留 Windows 不动，用空闲空间装 NixOS，GRUB 引导双系统。

## 0. 前提检查

- 主板 UEFI 模式（不是 Legacy BIOS）+ Windows 以 UEFI/GPT 安装
  （Windows 安装时若已用 GPT，即满足）
- 预留至少 **50GB** 空闲空间（NixOS 根分区；`/nix` 会随包增长）
- 关掉 **Windows 快速启动**（Fast Startup），否则 NTFS 分区未正常卸载：
  `控制面板 → 电源选项 → 选择电源按钮功能 → 取消勾选「启用快速启动」`
- 若 C 盘开了 **BitLocker**：NixOS 无法读取 C 盘（不影响启动，正常现象）；建议数据盘不加密或导出恢复密钥

## 1. 分区方案

在 Windows 里压缩卷腾空间（磁盘管理 → C 盘右键 → 压缩卷），得到未分配空间后，NixOS 分三块：

| 分区 | 大小 | 类型 | 挂载点 | 说明 |
|---|---|---|---|---|
| ESP（Windows 已有，**共用**） | — | EFI | `/boot` | 已有分区，不新建；GRUB 装进同一 ESP |
| 根分区 | ≥50GB | btrfs | `/` | 子卷 `@` / `@home` / `@nix` / `@snapshots` |
| SWAP | = 内存大小 | linux-swap | — | 休眠用（`boot.resumeDevice`） |

> ⚠️ **不新建 ESP**：Windows 的 ESP 直接复用（约 100MB 的 EFI 分区），GRUB 与 Windows 引导器共存。
> 卷标随意（如 `nixos` / `SWAP`），hardware-configuration.nix 用 UUID 引用，与卷标无关。

## 2. 安装步骤

### 2.1 启动 NixOS minimal ISO

从 [nixos.org](https://nixos.org/download) 下载 minimal ISO 写入 U 盘，开机进 Live 环境，联网。

### 2.2 分区（以 /dev/nvme0n1 为例）

```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT   # 先看清磁盘和未分配空间
sudo fdisk /dev/nvme0n1
#   p                   查看分区表（应看到 Windows 的 nvme0n1p1=ESP, p2=C:…）
#   n → 默认起始 → 大小 +50G → 类型 Linux filesystem
#   n → 剩余空间 → 大小 +16G（=内存）→ 类型 Linux swap
#   t → 选 swap 分区 → 82（Linux swap）
#   w                   写入
```

### 2.3 格式化 + 建子卷 + 挂载

```bash
# 根分区 btrfs（假设新分区为 nvme0n1p3）
sudo mkfs.btrfs -f -L nixos /dev/nvme0n1p3

# swap
sudo mkswap -L SWAP /dev/nvme0n1p4
sudo swapon /dev/nvme0n1p4

# 建子卷（与仓库 install-btrfs.md 一致）
sudo mount /dev/nvme0n1p3 /mnt
sudo btrfs subvolume create /mnt/@
sudo btrfs subvolume create /mnt/@home
sudo btrfs subvolume create /mnt/@nix
sudo btrfs subvolume create /mnt/@snapshots
sudo umount /mnt

# 挂载子卷（注意顺序：先 @ 再子卷）
sudo mount -o subvol=@,compress=zstd /dev/nvme0n1p3 /mnt
sudo mkdir -p /mnt/{boot,home,nix,.snapshots}
sudo mount -o subvol=@home,compress=zstd /dev/nvme0n1p3 /mnt/home
sudo mount -o subvol=@nix,compress=zstd,noatime /dev/nvme0n1p3 /mnt/nix
sudo mount -o subvol=@snapshots,compress=zstd /dev/nvme0n1p3 /mnt/.snapshots

# ESP（Windows 的 EFI 分区，假设 nvme0n1p1）
sudo mount --mkdir /dev/nvme0n1p1 /mnt/boot
```

### 2.4 拉配置 + 生成硬件配置

```bash
cd /tmp && sudo git clone https://github.com/cookieidea/neko-nixos.git /mnt/etc/nixos
sudo nixos-generate-config --root /mnt

# 编辑 hardware-configuration.nix，确认/补充：
sudo nano /mnt/etc/nixos/hardware-configuration.nix
#   fileSystems "/" 的 subvol=@、"/home" subvol=@home、"/nix" subvol=@nix
#   "/boot" = ESP（device 应为 ESP 的 UUID）
#   swapDevices = [ { device = "/dev/disk/by-uuid/<SWAP-UUID>"; } ]
```

### 2.5 双系统菜单（二选一）

**方式 A：os-prober 自动检测（推荐）**——在仓库 `configuration.nix` 加：

```nix
  # 双系统：GRUB 检测 Windows（装 os-prober 包即可，rebuild 时自动扫描）
  boot.loader.grub.extraConfig = ''
    GRUB_DISABLE_OS_PROBER=false
  '';
  environment.systemPackages = [ pkgs.os-prober ];
```

**方式 B：手动 chainload（不依赖 os-prober，最稳）**——在 `configuration.nix` 加：

```nix
  boot.loader.grub.extraConfig = ''
    menuentry "Windows 11" {
      search --fs-uuid --set=root <ESP-UUID>   # 用 `blkid` 查 ESP 的 UUID
      chainloader /EFI/Microsoft/Boot/bootmgfw.efi
    }
  '';
```

> 仓库当前 GRUB 配置（`efiSupport` + `efiInstallAsRemovable`）已就绪，直接加上述片段即可。

### 2.6 时间同步（关键，防 Windows 时间错乱）

Windows 用本地时间，Linux 默认 UTC → 会差 8 小时。在 `configuration.nix` 加：

```nix
  time.hardwareClockInLocalTime = true;   # 让 Linux 使用本地时间，与 Windows 一致
```

### 2.7 安装

```bash
cd /mnt/etc/nixos
sudo git add hardware-configuration.nix
sudo nixos-install --flake .#ATRI \
  --option substituters "https://mirrors.ustc.edu.cn/nix-channels/store https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://cache.nixos.org https://attic.xuyh0120.win/lantian"
```

装完 `reboot`，拔 U 盘。

## 3. 引导与日常切换

- 开机 → 主板自检 → **GRUB 菜单**：默认 NixOS，第二项 Windows（os-prober 或手动菜单）
- 若直接进 Windows：进 BIOS（Del/F2）→ Boot 顺序把 **GRUB**（盘名或 `EFI/grub`/`EFI/BOOT`）调到 Windows Boot Manager 前面
- 想默认进 Windows：GRUB 菜单按 `↑/↓` 选 Windows 回车（不改默认项）

## 4. 常见问题

| 问题 | 处理 |
|---|---|
| GRUB 里没有 Windows 项 | 确认 `os-prober` 已装 + `GRUB_DISABLE_OS_PROBER=false`，或改用手动 chainload（方式 B）；rebuild 后 `sudo update-grub`（NixOS 用 `nixos-rebuild switch` 自动更新） |
| 双系统时间差 8 小时 | 已配 `time.hardwareClockInLocalTime = true`（2.6 节） |
| 休眠后无法恢复 | hardware-configuration.nix 的 `swapDevices` 正确 + `boot.resumeDevice` 指向 SWAP 分区 |
| 读不了 Windows C 盘 | BitLocker 加密（正常）；未加密的话 `ntfs3` 内核驱动可读（CachyOS 内核已含） |
| Windows 更新后 GRUB 消失 | Windows 覆盖了引导；进 U 盘 Live 重装 GRUB：`nixos-install` 或 chroot 后 `nixos-rebuild switch` |
| 内存不够（VM/小内存） | 参考 install-btrfs.md 的 zram 配置 |

## 5. 与仓库现状的差异清单

实体机双系统相比当前配置只需两处新改动（2.5 + 2.6 节的片段），其余（GRUB 主题、CachyOS 内核、ly、noctalia、输入法等）原样生效。

**改动的文件夹**：`docs/dual-boot.md` 新增。
