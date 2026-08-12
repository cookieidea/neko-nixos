# 实体机安装指南（btrfs 根分区 + GRUB/UEFI）

本仓库是 NixOS 26.05 + Home Manager 的 flake 配置。本文件给**全新安装**用：
先把磁盘按 btrfs 子卷布局分好、挂载好，再让 `nixos-generate-config` 生成
`hardware-configuration.nix`，最后用 flake 装系统。

> 当前配置：引导 = GRUB(UEFI, `device="nodev"`)，所以 **EFI 分区挂在 `/boot`**，
> GRUB 和内核都在 vfat 的 `/boot` 上，根文件系统才是 btrfs —— 这样 GRUB 完全不读
> btrfs，规避了 GRUB 对 btrfs 子卷/压缩的兼容坑。

---

## 0. 启动 & 基础

用 **NixOS 26.05 最小 ISO（UEFI 模式）** 启动。进终端后先联网（有线一般自动；
无线用 `wpa_supplicant` 或 `nmcli`）。确认是 UEFI 启动：

```bash
ls /sys/firmware/efi/efivars   # 有内容就是 UEFI
```

---

## 1. 分区（btrfs 子卷方案）

> ⚠️ 下面会**清空整块盘**！把 `DISK` 换成你的盘：
> - SATA/USB：`/dev/sda`
> - NVMe：`/dev/nvme0n1`（分区会成 `nvme0n1p1` / `nvme0n1p2`）
>
> 想**全盘加密(LUKS)**见文末「LUKS 变体」。

```bash
set -e
DISK=/dev/sda          # ← 改成你的盘

# 建 GPT 分区表
parted -s $DISK mklabel gpt

# 1) EFI（vfat），挂 /boot，2GiB 够装多代内核
parted -s $DISK mkpart ESP fat32 1MiB 2GiB
parted -s $DISK set 1 esp on

# 2) 剩余全部给 btrfs（根）
parted -s $DISK mkpart nixos btrfs 2GiB 100%

EFI=${DISK}1
ROOT=${DISK}2

# 格式化
mkfs.vfat -F32 $EFI
mkfs.btrfs -L nixos $ROOT

# 建子卷（@ 根 / @home / @nix / @log / @snapshots）
mount $ROOT /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@snapshots
umount /mnt
```

子卷说明：
- `@` 根；`@home` 家目录；`@nix` 单独的 nix store（回滚根时不带 nix，省空间也更稳）；
- `@log` 日志独立（避免日志把快照撑爆）；`@snapshots` 挂到 `/.snapshots`，snapper 存快照用。

---

## 2. 挂载

```bash
ROOT=/dev/sda2   # ← 同上
EFI=/dev/sda1

# compress=zstd：zstd 压缩（btrfs 默认级别 3，可写 compress=zstd:1~:15 调档；
#   :1 最快体积略大，:15 最压但最慢。日常用默认或 zstd:1 即可）。
mount -o subvol=@,compress=zstd $ROOT /mnt
mkdir -p /mnt/{home,nix,var/log,.snapshots,boot}

mount -o subvol=@home,compress=zstd   $ROOT /mnt/home
mount -o subvol=@nix,compress=zstd     $ROOT /mnt/nix
mount -o subvol=@log,compress=zstd     $ROOT /mnt/var/log
# @snapshots 挂到 /.snapshots：snapper 默认把快照存在 /.snapshots，
# 用独立子卷装它，回滚 @ 时不会把快照一起滚掉，也更省空间。
mount -o subvol=@snapshots            $ROOT /mnt/.snapshots

mount $EFI /mnt/boot

# ── zstd 兜底：给每个子卷设 btrfs 默认压缩属性 ──
# 仅靠挂载选项的 compress 不够稳：nixos-generate-config 读 /proc/mounts 时
# 可能只保留 subvol、丢 compress；且一旦某次重挂漏了选项，新文件就不压缩。
# 给子卷打上默认压缩属性后，即使挂载选项丢失也照样压缩（不影响已存数据）。
for mp in /mnt /mnt/home /mnt/nix /mnt/var/log; do
  btrfs property set "$mp" compression zstd
done
```

确认（应看到 `compress=zstd` 且 `btrfs property get` 返回 zstd）：
```bash
mount | grep /mnt
btrfs property get /mnt compression
```

---

## 3. 生成 hardware-configuration.nix

```bash
nixos-generate-config --root /mnt
```
这会在 `/mnt/etc/nixos/` 下生成 `configuration.nix` 和 `hardware-configuration.nix`。
**保留 `hardware-configuration.nix`**（里面有你磁盘 UUID、btrfs 子卷挂载项）。

> ⚠️ **检查 `compress` 是否被正确捕获**：`nixos-generate-config` 读 `/proc/mounts`
> 生成的 `fileSystems."/".options` 里，确认有 `"compress=zstd"`（以及 `"subvol=@"`）。
> 由于它有时只保留 `subvol` 而丢 `compress`，若发现缺了 `compress=zstd`，
> 请手动补到 `hardware-configuration.nix` 对应每一项里，例如：
> ```nix
> fileSystems."/" = {
>   device = "/dev/disk/by-uuid/<你的UUID>";
>   fsType = "btrfs";
>   options = [ "subvol=@" "compress=zstd" "x-systemd.mount-timeout=30" ];
> };
> ```
> （因为上面已对子卷打了默认压缩属性，即便这里漏了也仍会压缩；补上只是让挂载选项表里一致。）

---

## 4. 放入本仓库的 flake

`hardware-configuration.nix` 已被 `configuration.nix` 用 `./hardware-configuration.nix`
引用，所以把 flake 文件放进同一目录即可。两种做法：

**做法 A（推荐）：直接 clone 本仓库，保留生成的 hardware 文件**
```bash
cd /mnt/etc/nixos
rm -f configuration.nix          # 删掉 generate-config 的默认配置（我们要用 flake）
git clone https://github.com/cookieidea/neko-nixos.git repo
# 把仓库内容连同子目录一起放到当前目录，保留 hardware-configuration.nix：
cp -r repo/. . && rm -rf repo
ls                            # 应有 flake.nix / configuration.nix / home.nix / hardware-configuration.nix / pkgs / dotfiles
```

**做法 B：U 盘拷贝** —— 把仓库整目录拷到 `/mnt/etc/nixos/`，保留 `hardware-configuration.nix`。

---

## 5. 安装

flake 的 `nixosConfigurations` 名字是 `nixos`（见 flake.nix），hostname 也是 `nixos`：

```bash
cd /mnt/etc/nixos
nixos-install --flake .#nixos
```

装完设密码（配置里没设 `initialPassword`）：
```bash
# 安装过程中或重启后用 passwd 设；也可在 live 环境 chroot：
nixos-enter -c 'passwd cookie'
```

然后：
```bash
reboot
```

---

## 6. 装后检查

- 启动应进 GRUB → 选 NixOS → 进 greetd 自动登录 niri。
- 确认根真是 btrfs：`findmnt -n -o FSTYPE /` 应为 `btrfs`。
- 子卷：`sudo btrfs subvolume list /`。
- **确认 zstd 压缩在跑**（默认属性 + 挂载选项双保险）：
  ```bash
  btrfs property get / compression      # 应返回 compression=zstd
  mount | grep ' / '                    # 挂载项应含 compress=zstd
  sudo compsize / 2>/dev/null | head    # 看实际压缩比（/nix 占大头，压缩收益高）
  ```
- **确认快照在跑**：`sudo snapper -c root list` 应有按时线生成的快照；GRUB 菜单里
  应出现「Snapshots」子菜单（装后首次重启才会生成引导项）。
- 快照/回滚用法见文末「快照 / 回滚」一节。

---

## （本次不使用）LUKS 全盘加密变体 —— 留作备用

> 本次安装**不加密**（按需求）。以下仅保留以便将来需要时启用，当前无需执行。


仅把「格式化 + 挂载」换成加密层（其余分区/子卷/安装步骤不变）：

```bash
cryptsetup luksFormat $ROOT
cryptsetup open $ROOT cryptroot
# 之后所有 btrfs 操作都针对 /dev/mapper/cryptroot 而非 $ROOT
mkfs.btrfs -L nixos /dev/mapper/cryptroot
# 子卷创建/挂载同上，只是把 $ROOT 换成 /dev/mapper/cryptroot
# 并在 configuration.nix 打开：
#   boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/<ROOT-UUID>";
# （UUID 用 `blkid $ROOT` 查；注意是裸设备的 UUID，不是 mapper）
```

GRUB 解密：UEFI + LUKS 时 GRUB 读取 `/boot`（vfat，单独分区，不加密）即可，
initrd 负责解 LUKS 挂根，无需 GRUB 读加密盘。

---

## 快照 / 回滚（snapper + grub-btrfs，已默认启用）

`configuration.nix` 里已经配好，无需再改：

```nix
services.snapper = {
  snapshotRootOnSubvol = true;        # / 本身是 @ 子卷
  configs."root" = {
    subvolume = "/";
    timelineCreate = true;
    timelineLimitHourly = 24;
    timelineLimitDaily = 7;
    timelineLimitWeekly = 4;
    timelineLimitMonthly = 0;
    timelineLimitYearly = 0;
    emptyPrePostCleanup = true;
    numberLimit = 0;
  };
};
services.grub-btrfs = {                # 启动菜单加「Snapshots」子菜单
  enable = true;
  bootsToGrubMenu = true;              # 异常断电/崩溃后自动回 GRUB 菜单
};
```

> 快照存哪：snapper 的 `root` 配置把快照写到 `/.snapshots`，也就是前面独立挂载的
> `@snapshots` 子卷。这样回滚 `@` 时不会把快照一起滚掉，也更省空间。
> 也正因为 `snapshotRootOnSubvol = true`，snapper 会自己管理 `/.snapshots` 的权限与子卷。

**两种回滚场景（重点）**
- **系统配置回滚**：NixOS 自带 generation 机制——GRUB 菜单本就列出多个 NixOS
  generation（靠 `boot.loader.grub.configurationLimit = 20`），直接选旧 generation 启动即可；
  或进系统后 `sudo nixos-rebuild switch --rollback`。这条最稳，优先用。
- **数据 / dotfiles 回滚**：靠 snapper 快照。从 GRUB「Snapshots」子菜单选一个快照启动
  （它是只读的，仅用于**查看/抢救文件**）；要真正变成当前系统，启动后执行：
  ```bash
  sudo snapper -c root list                       # 看快照号
  sudo snapper -c root rollback <快照号>           # 基于快照生成一个可写的新根并设为默认
  sudo reboot                                      # 重启即回到该快照状态
  ```
  > ⚠️ 直接启动只读快照后**不要**长期在上面跑（根只读，服务会报错）。它只用于抢救，
  > 真正回退请用上面的 `snapper rollback` 或 NixOS generation。

**日常用法**
```bash
sudo snapper -c root list                         # 列快照
sudo snapper -c root create --description "手动快照"   # 手动打点
sudo snapper -c root delete <快照号>              # 删快照
```
偷装完第一把建议：`sudo snapper -c root create --description "fresh install"`。
