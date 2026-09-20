# 安装指南（btrfs + GRUB/UEFI + 休眠 + snapper）

## 分区布局

```
nvme0n1p1  1G        vfat       BOOT  → /boot
nvme0n1p2  ≥ 内存    linux-swap SWAP  → swap + 休眠
nvme0n1p3  剩余      btrfs      nixos → /（子卷 @ @home @nix @snapshots）
```

## 1. 分区与格式化

```bash
sudo -i
lsblk
cfdisk /dev/nvme0n1

mkfs.fat -F32 -n BOOT /dev/nvme0n1p1
mkswap -L SWAP /dev/nvme0n1p2
mkfs.btrfs -f -L nixos /dev/nvme0n1p3

mount /dev/nvme0n1p3 /mnt
findmnt -n -o FSTYPE /mnt   # 必须是 btrfs
btrfs subvolume create /mnt/@{,@home,@nix,@snapshots}
umount /mnt
```

## 2. 挂载

```bash
mount -o subvol=@,compress=zstd,noatime     /dev/nvme0n1p3 /mnt
mkdir -p /mnt/{boot,home,nix,.snapshots}
mount -o subvol=@home,compress=zstd,noatime /dev/nvme0n1p3 /mnt/home
mount -o subvol=@nix,compress=zstd,noatime  /dev/nvme0n1p3 /mnt/nix
mount -o subvol=@snapshots,noatime          /dev/nvme0n1p3 /mnt/.snapshots
mount /dev/nvme0n1p1 /mnt/boot

for mp in /mnt /mnt/home /mnt/nix; do
  btrfs property set "$mp" compression zstd
done
```

## 3. 生成配置

```bash
swapon /dev/disk/by-label/SWAP
nixos-generate-config --root /mnt

cd /mnt/etc/nixos
rm -f configuration.nix
git clone https://github.com/cookieidea/neko-nixos.git repo
cp -r repo/. . && rm -rf repo
git add hardware-configuration.nix   # 必须 git add
```

**不要手动改 `hardware-configuration.nix` 的 device 路径。**

## 4. 安装

```bash
cd /mnt/etc/nixos
nixos-install --flake .#ATRI --max-jobs 1 \
  --option substituters "https://attic.xuyh0120.win/lantian https://mirrors.ustc.edu.cn/nix-channels/store https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://cache.nixos.org" \
  --option trusted-public-keys "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
```

内存不足时启用 zram：
```bash
modprobe zram && zramctl -f -s 16G && mkswap /dev/zram0 && swapon -p 100 /dev/zram0
```

```bash
nixos-enter -c 'passwd cookie'
reboot
```

## 5. 验证

```bash
uname -r                          # 应含 cachyos
findmnt -n -o FSTYPE /            # btrfs
btrfs property get / compression  # zstd
swapon --show
cat /sys/power/resume
sudo snapper -c root list
```

## 6. 快照与回滚

- 系统回滚：GRUB 选旧 generation 或 `sudo nixos-rebuild switch --rollback`
- 数据回滚：`sudo snapper -c root list` → `sudo snapper -c root rollback <号>` → `reboot`

## 常见问题

| 症状 | 处理 |
|------|------|
| btrfs subvolume create ENOTTY | 确认 /mnt 已挂载为 btrfs |
| hardware-configuration.nix 不存在 | 必须 `git add` |
| fileSystems."/".device already defined | 不要手动改 device |
| 安装 OOM | 用 zram 兜底 |
| 休眠后黑屏 | SWAP ≥ 内存，检查 resumeDevice |
| /home 只读 | `sudo btrfs property set /home ro false && mount -o remount,rw /home` |
| 快照为空 | snapper 键名必须全大写 |
