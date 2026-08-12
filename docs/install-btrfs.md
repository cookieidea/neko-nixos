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
- `@log` 日志独立（避免日志把快照撑爆）；`@snapshots` 给 snapper 存快照。

---

## 2. 挂载

```bash
ROOT=/dev/sda2   # ← 同上
EFI=/dev/sda1

mount -o subvol=@,compress=zstd $ROOT /mnt
mkdir -p /mnt/{home,nix,var/log,snapshots,boot}

mount -o subvol=@home,compress=zstd   $ROOT /mnt/home
mount -o subvol=@nix,compress=zstd     $ROOT /mnt/nix
mount -o subvol=@log,compress=zstd     $ROOT /mnt/var/log
mount -o subvol=@snapshots            $ROOT /mnt/snapshots

mount $EFI /mnt/boot
```

确认：
```bash
mount | grep /mnt
```

---

## 3. 生成 hardware-configuration.nix

```bash
nixos-generate-config --root /mnt
```
这会在 `/mnt/etc/nixos/` 下生成 `configuration.nix` 和 `hardware-configuration.nix`。
**保留 `hardware-configuration.nix`**（里面有你磁盘 UUID、btrfs 子卷挂载项）。

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
- 后续想加**快照/回滚**（snapper + grub-btrfs）见 README「可选」与下方说明。

---

## 可选：LUKS 全盘加密变体（第 1 步替换）

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

## 可选：snapper 快照 + grub-btrfs 回滚菜单

1. 在 `configuration.nix` 启用（子卷 `@snapshots` 已预留）：
   ```nix
   services.snapper.snapshotRootOnSubvol = true;
   services.snapper.configs."root" = {
     inherit (config.fileSystems."/".options) subvol;  # 指向 @
     timely = [ { Interval = "hourly"; Limit = 24; }
                { Interval = "daily";  Limit = 7;  }
                { Interval = "weekly"; Limit = 4;  } ];
   };
   boot.loader.grub = { ...; configurationLimit = 20; };  # 已有
   # 启动菜单显示快照（需装 grub-btrfs，nixpkgs 有）：
   #   environment.systemPackages += [ pkgs.grub-btrfs ];
   #   services.grub-btrfs.enable = true;   # 若 nixpkgs 提供该选项
   ```
2. 重启后 `sudo snapper -c root create --description "after install"` 试一把。

> 注：本仓库当前未启用 snapper；按需开启，开启后建议配套 grub-btrfs 才能在
> 启动菜单选快照回滚。
