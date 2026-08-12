# 实体机安装指南（NixOS 26.05 + btrfs 子卷 + GRUB/UEFI + 独立 SWAP 分区(休眠) + snapper）

本仓库是 NixOS 26.05 + Home Manager 的 flake 配置。本指南给**全新安装**用，
分区/子卷步骤参考社区 btrfs 安装笔记（fcsha/nixos-config），并结合本仓库实际：

- 引导用 **GRUB (UEFI)**（非 systemd-boot）
- 桌面用 **niri + noctalia-shell**
- 已默认启用 **snapper + grub-btrfs** 快照回滚
- 配置通过 **flake** 安装（`nixos-install --flake .#nixos`）
- **休眠用独立 SWAP 分区**：btrfs 上的 swapfile 官方不支持休眠恢复，故休眠走独立分区

---

## 目标布局

- 分区表：GPT
- EFI 分区：`1G`，FAT32，卷标 `BOOT` → 挂 `/boot`（GRUB 与内核都在这里）
- SWAP 分区：`建议 ≥ 物理内存`（如 16G），linux-swap，卷标 `SWAP` → 作 swap + 休眠镜像
- Root 分区：剩余空间，Btrfs，卷标 `nixos`
- 子卷：`@`（根）/ `@home` / `@nix` / `@snapshots`（snapper 用）

```text
/dev/nvme0n1p1  1G      vfat       BOOT   → /boot
/dev/nvme0n1p2  ≥RAM    linux-swap SWAP   → swap + 休眠（label=SWAP）
/dev/nvme0n1p3  剩余    btrfs      nixos  → /（子卷 @ / @home / @nix / @snapshots）
```

> SWAP 分区大小：休眠镜像约等于当前**已用内存**，所以 SWAP 分区建议 **≥ 物理内存**
> （如 32G 内存就给 32G+）。日常 swap 也用它，不必另开 btrfs swapfile。
> 下面命令里的 `/dev/nvme0n1` 只是示例，实际操作前必须用 `lsblk` 确认目标磁盘。
> EFI 用 1G（参考笔记值）；若想保留很多 generation，可加到 2G 更稳。

---

## 0. 启动 & 基础

用 **NixOS 26.05 最小 ISO（UEFI 模式）** 启动。进终端后先联网（有线一般自动；
无线用 `wpa_supplicant` 或 `nmcli`）。确认是 UEFI 启动：

```bash
ls /sys/firmware/efi/efivars   # 有内容就是 UEFI
```

---

## 1. 分区

进入 root shell 并查看磁盘：

```bash
sudo -i
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL,LABEL
```

用 `cfdisk` 分区：

```bash
cfdisk /dev/nvme0n1
```

在 `cfdisk` 中选择：

```text
Label type: gpt
New 1G     -> Type: EFI System
New 16G    -> Type: Linux swap        # ← 休眠分区，大小建议 ≥ 物理内存
New rest   -> Type: Linux filesystem
Write -> yes
Quit
```

---

## 2. 格式化

```bash
mkfs.fat -F32 -n BOOT /dev/nvme0n1p1
mkswap -L SWAP /dev/nvme0n1p2        # 格式化并打卷标 SWAP（休眠分区）
mkfs.btrfs -f -L nixos /dev/nvme0n1p3
```

---

## 3. 创建 Btrfs 子卷

先临时挂载 Btrfs 顶层卷，建好子卷再卸载：

```bash
mount /dev/disk/by-label/nixos /mnt
# ↓ 防坑：确认 /mnt 真是 btrfs 再建子卷，否则会报
#   "Could not create subvolume: Inappropriate ioctl for device"
#   常见原因：① by-label 软链尚未就绪导致 mount 静默失败；
#            ② 挂错分区（如把 EFI 的 vfat 挂到 /mnt）；
#            ③ mkfs.btrfs 没成功（分区被占用/设备错）。
findmnt -n -o FSTYPE /mnt        # 必须输出 btrfs；为空或 vfat 就先 umount /mnt 重挂
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@snapshots
umount /mnt
```

> 若 `findmnt` 看不到 /mnt，或输出不是 `btrfs`：
> ```bash
> umount /mnt 2>/dev/null
> ls -l /dev/disk/by-label/ | grep nixos   # 确认 by-label 软链存在；不存在就直接用设备路径
> mount /dev/nvme0n1p3 /mnt               # 用真实设备路径兜底（替换成你的 Root 分区）
> findmnt -n -o FSTYPE /mnt               # 再确认是 btrfs 后才继续
> ```

---

## 4. 安装前挂载

挂载 root 子卷，启用 `compress=zstd` 和 `noatime`：

```bash
mount -o subvol=@,compress=zstd,noatime /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/{boot,home,nix,.snapshots}

mount -o subvol=@home,compress=zstd,noatime /dev/disk/by-label/nixos /mnt/home
mount -o subvol=@nix,compress=zstd,noatime   /dev/disk/by-label/nixos /mnt/nix
# @snapshots 挂到 /.snapshots：snapper 默认把快照写在 /.snapshots，
# 用独立子卷装它，回滚 @ 时不会把快照一起卷走，也更省空间。
mount -o subvol=@snapshots,noatime           /dev/disk/by-label/nixos /mnt/.snapshots

mount /dev/disk/by-label/BOOT /mnt/boot
# SWAP 分区无需手动挂载，nixos-generate-config 会自动识别并启用（见第 6 步）。
```

### zstd 双保险（推荐）

仅靠挂载选项的 `compress` 不够稳（`nixos-generate-config` 有时只保留 `subvol`、
丢 `compress`）。给数据子卷打上 btrfs 默认压缩属性，即使挂载选项丢失也照样压缩：

```bash
for mp in /mnt /mnt/home /mnt/nix; do
  btrfs property set "$mp" compression zstd
done
```

确认：
```bash
mount | grep /mnt
btrfs property get /mnt compression      # 应返回 compression=zstd
```

---

## 5. 生成 NixOS 配置

```bash
swapon /dev/disk/by-label/SWAP          # 先启用 swap，确保 generate-config 能识别并写入
nixos-generate-config --root /mnt
```

生成的文件：

```text
/mnt/etc/nixos/configuration.nix
/mnt/etc/nixos/hardware-configuration.nix
```

> 关键点：第 2 步已 `mkswap`，这里再 `swapon` 一下，generate-config 才会把 SWAP 分区
> 自动写进 `hardware-configuration.nix` 的 `swapDevices`（partition 类型）。否则要手动加。

---

## 6. 修改硬件配置（关键）

编辑 `/mnt/etc/nixos/hardware-configuration.nix`，把 `fileSystems` 改成 **by-label 挂载 +
显式子卷选项**（SWAP 分区已由 generate-config 自动加入 `swapDevices`，**无需在此配置**）。
把 `fileSystems` 相关部分替换为：

```nix
fileSystems."/" = {
  device = "/dev/disk/by-label/nixos";
  fsType = "btrfs";
  options = [ "subvol=@" "compress=zstd" "noatime" ];
};

fileSystems."/home" = {
  device = "/dev/disk/by-label/nixos";
  fsType = "btrfs";
  options = [ "subvol=@home" "compress=zstd" "noatime" ];
};

fileSystems."/nix" = {
  device = "/dev/disk/by-label/nixos";
  fsType = "btrfs";
  options = [ "subvol=@nix" "compress=zstd" "noatime" ];
};

fileSystems."/.snapshots" = {
  device = "/dev/disk/by-label/nixos";
  fsType = "btrfs";
  options = [ "subvol=@snapshots" "noatime" ];
};

fileSystems."/boot" = {
  device = "/dev/disk/by-label/BOOT";
  fsType = "vfat";
  options = [ "umask=0077" ];                 # EFI 分区仅 root 可访问
};

# 注意：SWAP 分区（/dev/disk/by-label/SWAP）由 nixos-generate-config 自动写入
# swapDevices（partition 类型），此处无需配置。
# 休眠的 boot.resumeDevice 已写在 flake 的 configuration.nix（指向 /dev/disk/by-label/SWAP）。
```

> 说明：
> - `compress=zstd` + `noatime` 是 btrfs root/home/nix 的常见组合；`noatime` 减少元数据写入。
> - 若 generate-config **没**捕获 SWAP 分区（例如装完系统后才补的），在 hardware 文件手动加：
>   `swapDevices = [ { device = "/dev/disk/by-label/SWAP"; } ];`

---

## 7. 放入本仓库 flake

`hardware-configuration.nix` 已被 `configuration.nix` 用 `./hardware-configuration.nix` 引用，
所以把 flake 文件放进同一目录即可（保留生成的 hardware 文件）：

**做法 A（推荐）：clone 本仓库**
```bash
cd /mnt/etc/nixos
rm -f configuration.nix          # 删掉 generate-config 的默认配置（我们用 flake）
git clone https://github.com/cookieidea/neko-nixos.git repo
cp -r repo/. . && rm -rf repo
ls                            # 应有 flake.nix / configuration.nix / home.nix / hardware-configuration.nix / pkgs / dotfiles
```

**做法 B：U 盘拷贝** —— 把仓库整目录拷到 `/mnt/etc/nixos/`，保留 `hardware-configuration.nix`。

> flake 里引导已是 **GRUB（UEFI，`device="nodev"`）**，无需改；
> snapper + grub-btrfs 也已默认启用；hostname 固定为 `nixos`，用户为 `cookie`（见 flake 参数）。
> 在 Live ISO 里临时要 git，可 `nix-shell -p git` 再 `git clone`。

---

## 8. 安装

```bash
cd /mnt/etc/nixos
nixos-install --flake .#nixos
```

装完设密码（配置里没设 `initialPassword`）：
```bash
nixos-enter --root /mnt -c 'passwd cookie'
```

然后重启：
```bash
reboot
```

---

## 9. 装后验证

- 启动应进 GRUB → 选 NixOS → 进 greetd 自动登录 niri。
- 根真是 btrfs：`findmnt -n -o FSTYPE /` 应为 `btrfs`。
- 子卷：`sudo btrfs subvolume list /`。
- **zstd 压缩**：
  ```bash
  btrfs property get / compression      # 应返回 compression=zstd
  mount | grep ' / '                    # 挂载项含 compress=zstd
  sudo compsize / 2>/dev/null | head    # /nix 占大头，压缩收益高
  ```
- **SWAP 分区 + 休眠**：
  ```bash
  swapon --show                                   # 应见 /dev/disk/by-label/SWAP，类型 partition
  cat /sys/power/resume                           # 应显示 SWAP 分区的设备路径
  ```
- **快照**（snapper 已默认启用）：`sudo snapper -c root list` 应有按时线快照；
  GRUB 菜单应出现「Snapshots」子菜单（首次重启后生成）。

### 测试休眠

> ⚠️ 测试前先保存所有工作。`systemctl hibernate` 会把内存写入 SWAP 分区并断电，
> 下次开机自动从 SWAP 恢复（回到休眠前的桌面状态）。

```bash
systemctl hibernate
```

若恢复后黑屏/卡住，先确认 SWAP 分区 ≥ 内存、`boot.resumeDevice` 指向正确，并查日志
`journalctl -b -1 | grep -i "resume\|hiber"`。

> **可选：resume 后自动锁屏**
> 休眠恢复后内存原样恢复，若休眠前未锁屏，他人可直接操作。可在 systemd
> `post-resume.target` 上加一个服务触发 noctalia-shell 锁屏，或用
> `powerManagement.resumeCommands` 调 `noctalia-shell ipc call ...`（需 noctalia-shell
> 已运行）。可按需自行补充，本指南不默认启用。

---

## 10. 快照 / 回滚（snapper + grub-btrfs）

`configuration.nix` 已配好（无需再改）：

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
> `@snapshots` 子卷。回滚 `@` 时不会把快照一起卷掉，也更省空间。

**两种回滚场景（重点）**
- **系统配置回滚**：NixOS 自带 generation 机制 —— GRUB 菜单本就列出多个 NixOS
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
sudo snapper -c root list                              # 列快照
sudo snapper -c root create --description "手动快照"    # 手动打点
sudo snapper -c root delete <快照号>                   # 删快照
```
装完第一把建议：`sudo snapper -c root create --description "fresh install"`。

---

## （本次不使用）LUKS 全盘加密变体 —— 留作备用

> 本次安装**不加密**（按需求）。以下仅保留以便将来需要时启用，当前无需执行。
> ⚠️ 若启用 LUKS，SWAP 分区也要纳入 LUKS 或单独处理，休眠配置会复杂化；本配置当前
> 未加密，LUKS 变体仅作参考。

```bash
cryptsetup luksFormat /dev/nvme0n1p3
cryptsetup open /dev/nvme0n1p3 cryptroot
mkfs.btrfs -f -L nixos /dev/mapper/cryptroot
# 子卷创建/挂载同上，只是把 /dev/disk/by-label/nixos 换成 /dev/mapper/cryptroot
# 并在 hardware-configuration.nix 打开：
#   boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/<裸设备UUID>";
# （UUID 用 `blkid /dev/nvme0n1p3` 查；注意是裸设备的 UUID，不是 mapper）
# SWAP 分区若要也加密，需额外把 /dev/nvme0n1p2 纳入 LUKS，休眠恢复逻辑更复杂。
```

GRUB 解密：UEFI + LUKS 时 GRUB 读取 `/boot`（vfat，单独分区，不加密）即可，
initrd 负责解 LUKS 挂根，无需 GRUB 读加密盘。

---

## 安装后修改配置

进入安装好的系统后，修改配置并应用：

```bash
sudo nixos-rebuild switch
```
