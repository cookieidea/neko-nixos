# Windows + NixOS 双系统指南（UEFI + GPT）

> 与仓库配置配合（btrfs + GRUB + 休眠）。假设已有 Windows（UEFI/GPT），用空闲空间装 NixOS。

## 0. 前提

- Windows 为 **UEFI/GPT** 安装
- 预留 **≥50GB** 空闲空间
- 关 **Windows 快速启动**（否则 NTFS 未正常卸载）：控制面板 → 电源选项 → 选择电源按钮功能 → 取消「启用快速启动」
- C 盘开 BitLocker 不影响引导（NixOS 读不了 C 盘是正常现象）

## 1. 分区

Windows 磁盘管理 → C 盘压缩卷腾空间。NixOS 分两块（ESP 复用 Windows 的）：

| 分区 | 大小 | 类型 | 挂载 |
|---|---|---|---|
| ESP（Windows 已有，**复用不新建**） | — | EFI | `/boot` |
| 根 | ≥50G | btrfs | `/`（子卷 @ @home @nix @snapshots） |
| SWAP | = 内存 | linux-swap | 休眠（`resumeDevice`） |

## 2. 安装 NixOS

流程与 `install-btrfs.md` 相同，仅两处差异：

```bash
# 分区：只建根 + swap，ESP 用 Windows 现有的（假设 nvme0n1p1）
sudo fdisk /dev/nvme0n1      # 已有 p1=ESP；新加 根(btrfs) + swap

# 格式化/子卷/挂载：见 install-btrfs.md 第 1-2 节
# 差异：ESP 挂载
sudo mount --mkdir /dev/nvme0n1p1 /mnt/boot

# 其余（generate-config / clone 仓库 / 安装）见 install-btrfs.md 第 3-4 节
```

## 3. 双系统菜单（仓库已启用 os-prober）

仓库 `configuration.nix` 已配 `boot.loader.grub.useOSProber = true`，rebuild 时自动检测 Windows，**无需再改配置**。

若检测不到，备选：手动 chainload（改 `configuration.nix` 加）：

```nix
boot.loader.grub.extraConfig = ''
  menuentry "Windows 11" {
    search --fs-uuid --set=root <ESP-UUID>   # blkid 查 ESP
    chainloader /EFI/Microsoft/Boot/bootmgfw.efi
  }
'';
```

## 4. 时间同步（防 Windows 时间错乱）

仓库已配 `time.hardwareClockInLocalTime = true`（Linux 用本地时间，与 Windows 一致），无需处理。

## 5. 引导与日常

- 开机进 **GRUB**：默认 NixOS，第二项 Windows（os-prober）
- 直接进 Windows：BIOS（Del/F2）→ 把 GRUB 调到 Windows Boot Manager 前面
- Windows 更新后 GRUB 消失：进 U 盘 Live 重装（chroot 后 `nixos-rebuild switch` 或重跑 `nixos-install`）

## 6. 常见问题

| 问题 | 处理 |
|---|---|
| GRUB 无 Windows 项 | 确认 os-prober 已启用 + 能读 NTFS（CachyOS 内核已含 ntfs3）；或改手动 chainload |
| 时间差 8 小时 | 已配 `hardwareClockInLocalTime` |
| 休眠后无法恢复 | SWAP 分区 ≥ 内存 + `resumeDevice` 正确（见 install-btrfs.md） |
| 读不了 C 盘 | BitLocker 加密（正常） |
