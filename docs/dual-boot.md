# Windows + NixOS 双系统（UEFI + GPT）

## 前提

- Windows 为 UEFI/GPT
- 预留 ≥50GB 空闲空间
- 关闭 Windows 快速启动

## 分区

复用 Windows 的 ESP，新建根分区和 SWAP：

| 分区 | 大小 | 类型 | 挂载 |
|------|------|------|------|
| ESP（已有） | — | EFI | /boot |
| 根 | ≥50G | btrfs | /（子卷 @ @home @nix @snapshots） |
| SWAP | = 内存 | linux-swap | 休眠 |

## 安装差异

```bash
# 只新建根 + swap，ESP 复用
sudo mount --mkdir /dev/nvme0n1p1 /mnt/boot
```

其余步骤与 `install-btrfs.md` 相同。

## 双系统菜单

仓库已启用 `boot.loader.grub.useOSProber = true`，rebuild 后自动检测 Windows。

手动 chainload（备用）：

```nix
boot.loader.grub.extraConfig = ''
  menuentry "Windows 11" {
    search --fs-uuid --set=root <ESP-UUID>
    chainloader /EFI/Microsoft/Boot/bootmgfw.efi
  }
'';
```

## 时间同步

已配置 `time.hardwareClockInLocalTime = true`，无需额外处理。

## 常见问题

| 问题 | 处理 |
|------|------|
| GRUB 无 Windows 项 | 确认 os-prober 启用；或用手动 chainload |
| 时间差 8 小时 | 已处理 |
| 休眠无法恢复 | 见 install-btrfs.md |
| 读不了 C 盘 | BitLocker 正常现象 |
