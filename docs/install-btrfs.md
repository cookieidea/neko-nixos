# 实体机安装指南（NixOS 26.05 + btrfs 子卷 + GRUB/UEFI + 独立 SWAP 分区(休眠) + snapper）

本仓库是 NixOS 26.05 + Home Manager 的 flake 配置。本指南给**全新安装**用，流程对齐
[官方 NixOS Wiki 的 Btrfs 安装章节](https://wiki.nixos.org/wiki/Btrfs#Installation_of_NixOS_on_btrfs)，
并结合本仓库实际：

- 引导用 **GRUB (UEFI)**（非 systemd-boot）
- 桌面用 **niri + noctalia-shell**
- 已默认启用 **snapper** 按时线快照
- 配置通过 **flake** 安装（`nixos-install --flake .#ATRI`）
- **休眠用独立 SWAP 分区**：btrfs 上的 swapfile 官方不支持休眠恢复，故休眠走独立分区
- ⚠️ NixOS 26.05 已**移除 `services.grub-btrfs` 模块**，GRUB 菜单不再列出快照子菜单；
  回滚走 NixOS generation（GRUB 本就列出多代）+ snapper 手动回滚（见第 10 节）

> 本指南**不使用 by-label 手动改 `hardware-configuration.nix` 的方法**。挂载统一用设备路径
> （如 `/dev/nvme0n1p3`），硬件配置由 `nixos-generate-config` 自动生成（by-uuid），**不要手动改
> `fileSystems."/".device`**——重定义会报 `attribute 'fileSystems."/".device' already defined`。

---

## 目标布局

- 分区表：GPT
- EFI 分区：`1G`，FAT32，卷标 `BOOT` → 挂 `/boot`（GRUB 与内核都在这里）
- SWAP 分区：`建议 ≥ 物理内存`，linux-swap，卷标 `SWAP` → swap + 休眠镜像
  （flake 的 `boot.resumeDevice` 指向 `/dev/disk/by-label/SWAP`）
- Root 分区：剩余空间，Btrfs，卷标 `nixos`
- 子卷：`@`（根）/ `@home` / `@nix` / `@snapshots`（snapper 用）

```text
/dev/nvme0n1p1  1G        vfat       BOOT   → /boot
/dev/nvme0n1p2  ≥RAM      linux-swap SWAP   → swap + 休眠（label=SWAP）
/dev/nvme0n1p3  剩余      btrfs      nixos  → /（子卷 @ / @home / @nix / @snapshots）
```

> SWAP 分区大小：休眠镜像约等于当前**已用内存**，所以 SWAP 分区建议 **≥ 物理内存**
> （如 32G 内存就给 32G+）。日常 swap 也用它，不必另开 btrfs swapfile。
> 下面命令里的 `/dev/nvme0n1` 只是示例，实际操作前必须用 `lsblk` 确认目标磁盘。
> EFI 用 1G（参考笔记值）；若想保留很多 generation，可加到 2G 更稳。

---

## 0. 启动 & 基础

用 **NixOS 26.05 最小 ISO（UEFI 模式）** 启动。进终端后先联网（有线一般自动；
无线用 `nmcli` 或 `wpa_supplicant`）。确认是 UEFI 启动：

```bash
ls /sys/firmware/efi/efivars   # 有内容就是 UEFI
```

---

## 1. 分区

```bash
sudo -i
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL,LABEL   # 确认目标磁盘，下面用 /dev/nvme0n1 举例
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
mkswap -L SWAP /dev/nvme0n1p2        # 格式化并打卷标 SWAP（休眠分区；flake 靠 label 找它）
mkfs.btrfs -f -L nixos /dev/nvme0n1p3
```

---

## 3. 创建 Btrfs 子卷

临时挂载 **Root 分区设备路径**（不用 by-label，避免软链未就绪导致静默失败），建好子卷再卸载：

```bash
mount /dev/nvme0n1p3 /mnt
# 防坑：确认 /mnt 真是 btrfs 再建子卷，否则报
#   "Could not create subvolume: Inappropriate ioctl for device" (ENOTTY)
# 常见原因：mount 静默失败（by-label 软链没就绪 / 挂错成 EFI vfat）/ mkfs.btrfs 没成功。
findmnt -n -o FSTYPE /mnt        # 必须输出 btrfs；不是就先 umount /mnt 重挂
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@snapshots
umount /mnt
```

> 若 `findmnt` 看不到 `/mnt` 或输出不是 `btrfs`：
> ```bash
> umount /mnt 2>/dev/null
> mount /dev/nvme0n1p3 /mnt            # 用真实设备路径（替换成你的 Root 分区）
> findmnt -n -o FSTYPE /mnt            # 再确认是 btrfs 后才继续
> ```

---

## 4. 安装前挂载

挂 root 子卷，启用 `compress=zstd` + `noatime`：

```bash
mount -o subvol=@,compress=zstd,noatime        /dev/nvme0n1p3 /mnt
mkdir -p /mnt/{boot,home,nix,.snapshots}

mount -o subvol=@home,compress=zstd,noatime    /dev/nvme0n1p3 /mnt/home
mount -o subvol=@nix,compress=zstd,noatime     /dev/nvme0n1p3 /mnt/nix
# @snapshots 挂到 /.snapshots：snapper 默认把快照写在 /.snapshots，
# 用独立子卷装它，回滚 @ 时不会把快照一起卷走，也更省空间。
mount -o subvol=@snapshots,noatime             /dev/nvme0n1p3 /mnt/.snapshots

mount /dev/nvme0n1p1 /mnt/boot
# SWAP 分区无需手动挂载，nixos-generate-config 会自动识别并启用（见第 5 步）。
```

### zstd 压缩双保险（推荐）

`nixos-generate-config` 生成的挂载项有时只保留 `subvol`、丢 `compress`。给数据子卷打上
btrfs 默认压缩属性，即使挂载选项丢失也照样压缩（属性持久，子卷不删就一直在）：

```bash
for mp in /mnt /mnt/home /mnt/nix; do
  btrfs property set "$mp" compression zstd
done
btrfs property get /mnt compression      # 应返回 compression=zstd
```

> 如果你更想要「声明式」压缩（写进 configuration.nix 而非靠运行时属性），可在 flake 的
> `configuration.nix` 追加（**只加 options，不要碰 device**，否则会和硬件配置冲突）：
> ```nix
> fileSystems."/".options          = [ "compress=zstd" "noatime" ];
> fileSystems."/home".options      = [ "compress=zstd" "noatime" ];
> fileSystems."/nix".options       = [ "compress=zstd" "noatime" ];
> fileSystems."/.snapshots".options = [ "noatime" ];
> ```

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

> 第 2 步已 `mkswap`，这里再 `swapon` 一下，generate-config 才会把 SWAP 分区
> 自动写进 `hardware-configuration.nix` 的 `swapDevices`（partition 类型）。否则要手动加。

---

## 6. ⚠️ 不要手动改 hardware-configuration.nix

**这是 26.05 安装最容易踩的坑。** `nixos-generate-config` 生成的
`hardware-configuration.nix` 已经是正确可用的（设备用 by-uuid，子卷/挂载/SWAP 都在）。
**不要**去改写 `fileSystems."/".device`，也不要追加 by-label 块。

- 如果你只想要压缩 / noatime：第 4 步的 `btrfs property set` 已经搞定，无需碰硬件配置。
- 如果你要写进 configuration.nix：只写 `.options`（见第 4 步注释），千万不要重定义 `.device`。
  一旦在硬件配置里出现两份 `fileSystems."/"`（生成版 + 你加的版），`nixos-install` 会报
  `attribute 'fileSystems."/".device' already defined`，安装直接卡死。

一句话：**硬件配置保持原样，flake 的 configuration.nix 也不要重定义 device 路径。**

---

## 7. 放入本仓库 flake

`hardware-configuration.nix` 已被 flake 的 `configuration.nix` 用 `./hardware-configuration.nix`
引用，所以把 flake 文件放进同一目录、保留生成的硬件文件即可：

```bash
cd /mnt/etc/nixos
rm -f configuration.nix          # 删掉 generate-config 的默认配置（我们用 flake）
git clone https://github.com/cookieidea/neko-nixos.git repo
cp -r repo/. . && rm -rf repo
ls                            # 应有 flake.nix / configuration.nix / home.nix / hardware-configuration.nix / pkgs / dotfiles
```

**关键**：flake 只认 git 跟踪的文件。生成的 `hardware-configuration.nix` 必须让 git 看见，否则
`nixos-install` 报 `hardware-configuration.nix does not exist` / `not tracked by Git`：

```bash
git add hardware-configuration.nix     # 无需 commit，脏树含暂存文件即可
```

> flake 里引导已是 **GRUB（UEFI，`device="nodev"`）**，SWAP 休眠、snapper 都已默认启用；
> hostname 固定 `ATRI`，用户 `cookie`。Live ISO 里临时要 git：`nix-shell -p git` 再 clone。
> flake 输入已配好：nixpkgs 走 TUNA nix-channels tarball、home-manager/cooknixvim/opencode 走 github、
> 二进制缓存 attic（CachyOS 内核）+ USTC + TUNA + 官方（见下条安装命令，安装期必须显式传）。

---

## 8. 安装

```bash
cd /mnt/etc/nixos
nixos-install --flake .#ATRI --max-jobs 1 \
  --option substituters "https://attic.xuyh0120.win/lantian https://mirrors.ustc.edu.cn/nix-channels/store https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://cache.nixos.org" \
  --option trusted-public-keys "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
```

> ⚠️ 必须带 `--option substituters` 把二进制缓存显式传进去：26.05 的 `nixos-install`
> 守护进程会**忽略** flake 内的 `accept-flake-config`（甚至不认 `--accept-flake-config` 这个
> flag，给了直接 `unknown option`）。不传的话包下载直连官方源，国内很慢。
> - **attic 放最前面**（CachyOS 内核缓存，命中直接拉二进制，跳过本地编译；`configuration.nix`
>   里的 substituters 配置安装期不生效，必须显式传）。
> - **lantian 公钥必须一起传**：substituter 没有对应信任公钥时签名校验不过、等于白配
>   （flake.nix 的 `nixConfig` 已补该公钥，但安装期同样需要显式传）。
> - flake 源码拉取若遇 GitHub 403（共享 IP 限流），属正常，官方 `git+https` 会重试 / 走代理即可。
> - **Go 包（如 bili-danmaku-tui）构建失败、日志报 `proxy.golang.org ... connection refused`**：
>   Go 模块代理被墙。nixpkgs `buildGoModule` 的 go-modules 固定输出派生把 `GOPROXY` 列为
>   impureEnvVars，**构建命令前 export 即可透传进沙箱**（无需改配置）：
>   ```bash
>   export GOPROXY="https://goproxy.cn,direct"
>   ```
>   （备选：`https://mirrors.aliyun.com/goproxy/,direct`）
>
> **⚠️ 评估阶段 OOM（进程被 `Killed` 无任何报错）**：本配置（home-manager + cooknixvim + opencode
> 同评）的 flake 评估峰值约 **6.6GB 匿名内存**，内存 <8G 的机器会被内核 OOM 杀掉（dmesg 可见
> `Out of memory: Killed process ... (nix)`）。`--max-jobs` 只管构建期、对评估无效。兜底：
> ```bash
> modprobe zram && zramctl -f -s 16G && mkswap /dev/zram0 && swapon -p 100 /dev/zram0 && free -h
> ```
> 或把内存加到 12G+。**注意 live ISO 的 `/` 是 tmpfs（内存盘），swapfile 不能建在 `/` 上**。

装完设密码（配置没设 `initialPassword`）：

```bash
nixos-enter -c 'passwd cookie'
```

重启：

```bash
reboot
```

---

## 9. 装后验证

- 启动应进 GRUB（BlueArchive 主题）→ 选 NixOS → **ly 登录界面**（左右选用户、回车输密码，
  默认会话 niri；`configuration.nix` 里 `autoLogin` 被注释，想恢复自动登录取消注释即可）。
- **内核**：`uname -r` 应显示 `cachyos`（CachyOS **RT-BORE**：实时调度 + BORE 调度器，
  直播/推流低延迟）。内核由 flake 输入 `nix-cachyos-kernel`（release 分支 + pinned overlay）
  提供，二进制缓存 `attic.xuyh0120.win/lantian` 已在 `nix.settings` 配好。
- 根真是 btrfs：`findmnt -n -o FSTYPE /` 应为 `btrfs`。
- 子卷：`sudo btrfs subvolume list /`。
- **zstd 压缩**：
  ```bash
  btrfs property get / compression      # 应返回 compression=zstd
  mount | grep ' / '                    # 挂载项含 compress=zstd（或属性已生效）
  sudo compsize / 2>/dev/null | head    # /nix 占大头，压缩收益高
  ```
- **SWAP 分区 + 休眠**：
  ```bash
  swapon --show                                   # 应见 SWAP 分区，类型 partition
  cat /sys/power/resume                           # 应显示 SWAP 分区的设备路径
  ```
- **快照**：`sudo snapper -c root list` 应有按时线快照。
- **应用图标**（noctalia 启动器/GTK 应用图标正常，不是紫黑棋盘格）：
  ```bash
  ls /run/current-system/sw/share/icons/          # 应含 hicolor、Adwaita、Papirus
  # GTK 图标主题应为 Papirus（home-manager gtk 模块写入，见踩坑速查 21/25/27）
  ```
  > ⚠️ 图标主题由 **home-manager `gtk` 模块**写入 settings.ini（不要用 xdg.configFile 部署
  > settings.ini，只读 symlink 会挡住模块写入导致图标失效——见踩坑速查 27）。
- **壁纸 / MangoHud**：
  ```bash
  ls ~/Pictures/Wallpapers             # 应有 2 张默认壁纸（noctalia 壁纸轮播依赖）
  ls ~/.config/MangoHud                # 应有 MangoHud.conf
  ```
- **输入法**：`fcitx5-diagnose` 不应再出现「推荐取消 GTK_IM_MODULE」提示
  （`waylandFrontend = true` + GTK settings 已清理）；中文走 **rime + rime-ice（雾凇拼音）**，
  日文 mozc 已移除。
- **微信/QQ/Discord/Flatseal/OpenOrpheus**：`flatpak list --system 2>/dev/null | grep -iE "wechat|qq|discord|flatseal|orpheus"`——由
  `flatpak-repo.service` 启动时自动从官方 `dl.flathub.org` 安装（国内 flathub 镜像已全部失效，见踩坑速查 18）。
  ⚠️ discord 走 Flatpak 而非 nixpkgs 包（nixpkgs 包需从 `stable.dl*.discordapp.net` 下载客户端，国内不可达，见踩坑速查 35）。

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

## 10. 快照 / 回滚（snapper）

`configuration.nix` 已配好（无需再改）：

```nix
services.snapper = {
  snapshotRootOnBoot = true;         # / 本身是 @ 子卷：开机时对根子卷打快照（26.05 由 snapshotRootOnSubvol 改名）
  # 26.05 起 configs.<名> 选项全部用 snapper 配置键名（全大写，见 man snapper-configs）
  configs."root" = {
    SUBVOLUME = "/";               # 26.05 由 subvolume 改名（全大写 SUBVOLUME）
    TIMELINE_CREATE = true;
    TIMELINE_LIMIT_HOURLY = 24;
    TIMELINE_LIMIT_DAILY = 7;
    TIMELINE_LIMIT_WEEKLY = 4;
    TIMELINE_LIMIT_MONTHLY = 0;
    TIMELINE_LIMIT_YEARLY = 0;
    EMPTY_PRE_POST_CLEANUP = true;
    NUMBER_LIMIT = 0;
  };
};
```

> ⚠️ 26.05 已移除 `services.grub-btrfs`，**GRUB 菜单不再有「Snapshots」子菜单**。
> 快照仍由 snapper 按时线创建（写在 `/.snapshots`，即独立 `@snapshots` 子卷）。
> ⚠️ 26.05 起 `configs.<名>` 里**必须用全大写键名**（对齐 snapper 配置文件）。旧 camelCase 键
> （`timelineCreate` 等）已被移除：其中 `subvolume`/`fstype` 会直接报 assertion
> （"has been renamed to ...SUBVOLUME"），其余旧键会被 freeform 静默收下、写出无效小写键，
> **snapper 不认 → 快照静默不生效**。若装完 `sudo snapper -c root list` 一直是空的，先检查
> `/etc/snapper/configs/root` 里键是不是全大写。

**两种回滚场景（重点）**
- **系统配置回滚（最稳，优先用）**：NixOS 自带 generation 机制 —— GRUB 菜单本就列出多个
  NixOS generation（靠 `boot.loader.grub.configurationLimit = 20`），直接选旧 generation 启动即可；
  或进系统后 `sudo nixos-rebuild switch --rollback`。这条最稳，优先用。
- **数据 / dotfiles 回滚**：靠 snapper 快照。启动后执行：
  ```bash
  sudo snapper -c root list                       # 看快照号
  sudo snapper -c root rollback <快照号>           # 基于快照生成可写新根并设为默认
  sudo reboot                                      # 重启即回到该快照状态
  ```
  > 真要「从 GRUB 进某个快照只读查看」在 26.05 需另行接 grub-btrfsd（grub-btrfs 包）的
  > systemd 服务，且**不能**让它覆盖 NixOS 生成的 `/boot/grub/grub.cfg`（否则丢 generation
  > 启动项）。非必需，本指南不默认启用。

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
> ⚠️ 若启用 LUKS，SWAP 分区也要纳入 LUKS 或单独处理，休眠配置会复杂化。

```bash
cryptsetup luksFormat /dev/nvme0n1p3
cryptsetup open /dev/nvme0n1p3 cryptroot
mkfs.btrfs -f -L nixos /dev/mapper/cryptroot
# 子卷创建/挂载同上，只是把 /dev/nvme0n1p3 换成 /dev/mapper/cryptroot
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

---

## 附：26.05 安装已知坑（踩坑速查）

1. **`btrfs subvolume create: Inappropriate ioctl for device` (ENOTTY)**：`/mnt` 不是 btrfs
   （mount 静默失败）。第 3 步用 `findmnt -n -o FSTYPE /mnt` 校验后再建子卷。
2. **`mount: /mnt/.snapshots: No such file or directory`**：`@snapshots` 子卷没建出来（上一步
   被打断漏建）。重跑第 3 步建全 4 个子卷再挂。
3. **flake 拉取 404**：TUNA git 镜像只镜像 nixpkgs（`git/nixpkgs.git`，无 owner 别名），
   home-manager 等未镜像；现 flake 已改官方 `git+https://github.com/...`。
4. **GitHub 403 API 限流**：`github:` scheme 走 REST API 被限流；已改 `git+https` 绕过。
5. **`hardware-configuration.nix does not exist` / `not tracked by Git`**：flake 只认 git
   跟踪文件，`git add hardware-configuration.nix` 即可（见第 7 步）。
6. **`fileSystems."/".device' already defined`**：硬件配置里 `fileSystems."/"` 重复定义。
   **永远不要手动改/追加 device 路径**（第 6 步）。
7. **`services.flatpak.remotes does not exist`**：26.05 移除该声明式 option，已改
   `systemd.services.flatpak-repo` one-shot 服务（仓库已修）。
8. **`services.grub-btrfs does not exist`**：26.05 移除该模块（停止维护），GRUB 不再列快照
   子菜单；回滚走 generation + snapper（第 10 步，仓库已移除该块）。
9. **`services.snapper.snapshotRootOnSubvol does not exist`**：26.05 把该 option
   **改名**为 `services.snapper.snapshotRootOnBoot`（根在 @ 子卷时改成开机对根子卷打快照）。
   仓库 `configuration.nix` 与本文第 10 节已同步改。
10. **`services.snapper.configs.root.subvolume' has been renamed to ...SUBVOLUME`**：
    26.05 把 `configs.<名>` 里的小写选项全部改成**全大写键名**（对齐 `man snapper-configs`：
    `subvolume`→`SUBVOLUME`、`fstype`→`FSTYPE`；`timelineCreate`→`TIMELINE_CREATE`、
    `timelineLimitHourly`→`TIMELINE_LIMIT_HOURLY`、`emptyPrePostCleanup`→`EMPTY_PRE_POST_CLEANUP`、
    `numberLimit`→`NUMBER_LIMIT` …）。`subvolume`/`fstype` 残留会报 assertion；
    其余旧 camelCase 键不报错但写出无效小写键，snapper 不认 → 快照静默不生效。
    仓库已全部改成大写键（第 10 节）。
11. **`git pull` 报 `TLS connect error: error:0A000126:SSL routines::unexpected eof`**：
    github 直连 + HTTP/2 在部分网络环境会被掐。先强制 HTTP/1.1 再拉：
    `git config --global http.version HTTP/1.1 && git pull origin main`；
    仍失败就换镜像拉：`git pull https://gitclone.com/github.com/<owner>/<repo>.git main`
    或 gh 代理 `https://ghfast.top/https://github.com/<owner>/<repo>.git`。
12. **`git pull` 被本地改动挡住（"Your local changes would be overwritten"）**：安装中手动 sed
    改过 `configuration.nix`（如 snapper 大写键）时，远端提交已包含相同修复 → 直接
    `git checkout -- configuration.nix` 丢弃本地改动再 pull（**不要** `git reset --hard`，
    会连 staged 的 `hardware-configuration.nix` 一起清掉）。
13. **`nerdfonts` 不存在（26.05 已删）**：改名 `nerd-fonts` 且改为每字体一属性
    （`nerd-fonts.jetbrains-mono`），不接受 `override { fonts = [...] }`；MapleMono 不在其
    manifest，nixpkgs 也无独立包。仓库已改。
14. **自构建包报 `invalid hash` / hash mismatch**：`pkgs/*/default.nix` 的 sha256 必须是
    SRI 格式（`sha256-` + 44 位 base64，`nix-prefetch-url` / `nix store prefetch-file` 生成），
    不能手写 64 位 hex。⚠️ 且 **GitHub codeload 的 tar.gz 对不同网络/客户端会生成不同字节**
    （同一 rev 宿主机与 VM 实测哈希不同）——GitHub 仓库源一律改用 `builtins.fetchGit`
    （按 commit 内容寻址、免哈希、确定性）；GitHub release 静态资源与 PyPI sdist 哈希稳定，
    可继续用 fetchurl/fetchPypi。仓库已按此处理。
15. **`nixos-install` 评估阶段进程被 `Killed`（无报错）**：OOM 实锤（见第 8 节）——
    flake 评估峰值 ~6.6GB，内存不足被杀。解法：zram 16G 兜底 或 VM 内存加到 12G+。
    **live ISO 的 `/` 是 tmpfs**，swapfile 建在 `/` 上无效；要建磁盘 swapfile 得在 `/mnt`
    （btrfs 需先 `truncate -s 0` + `chattr +C` 设 NoCOW 再写零/mkswap/swapon）。
16. **`git+file` flake 的 dirty 树源缓存坑**：`git pull` 后配置改动"不生效"（构建仍用旧文件，
    连 drv 名都不变）。dirty 树的源复制/缓存不可靠。解法：
    - 提交使树干净：`git add -A && git commit -m sync`（nix 用 HEAD rev 确定性内容）；
    - 或绕过 git：`nixos-install --flake path:/mnt/etc/nixos#ATRI`（直读文件系统）。
    - merge 卡在 vi：live ISO 无 vi，先 `git config core.editor true` 再 `git commit --no-edit`。
17. **分叉分支 pull 被拒（divergent branches）**：本地提交过 hardware-configuration.nix 后与
    origin 分叉。`git config pull.rebase false && git pull origin main`（无冲突会直接 merge）。
18. **flathub 国内镜像：`.flatpakrepo` 文件 404，但仓库 URL 可用**：USTC/TUNA/阿里的
    `flathub.flatpakrepo` 均返回 404（2026-08 实测），但仓库根 URL 本身 200 可用
    （`https://mirrors.ustc.edu.cn/flathub/` 实测 OK）。所以正确姿势是
    **先 `remote-add` 官方 flatpakrepo，再 `remote-modify flathub --url=https://mirrors.ustc.edu.cn/flathub`**
    （仓库已如此配置；不能直接 remote-add 镜像的 flatpakrepo 路径）。
19. **QQ 在 flathub 的 ID 是 `com.qq.QQ`**（不是 `org.tencent.qq`，后者 404）。
    微信是 `com.tencent.WeChat`。
20. **home-manager 激活报 `The name is not activatable`（dconfSettings 步骤）**：
    home-manager 26.05 的 **gtk 模块（iconTheme/theme）内部用 dconf 写 GTK 设置**，
    NixOS 必须配套 `programs.dconf.enable = true`（提供 dconf 的 DBus 激活服务）。
21. **进桌面后应用图标全是紫黑棋盘格**：系统只装了 hicolor，缺 freedesktop 图标主题。
    装 `adwaita-icon-theme` + `papirus-icon-theme`，并用 home-manager `gtk` 模块设
    `iconTheme`。注意 `gtk.gtk2.extraConfig` 是 **lines 类型（多行字符串）不是 attrset**；
    启用 gtk 模块后不要再手动部署 `.gtkrc-2.0`（冲突），fcitx 输入法配置并入
    `gtk2.extraConfig`。
22. **`tabler-icons` 不存在（26.05）**：nixpkgs 无此包，noctalia 的 UI 图标由包自带。
23. **装完系统后 `/etc/nixos` 是空的**：需重新 clone 仓库 + 生成硬件配置再 rebuild：
    ```bash
    sudo rm -rf /etc/nixos && sudo git clone https://github.com/cookieidea/neko-nixos /etc/nixos
    cd /etc/nixos
    sudo nixos-generate-config
    sudo git add -A && sudo git config user.email "you@example.com" && sudo git config user.name "you"
    sudo git commit -m "hardware-configuration"     # flake 只认 tracked 文件！
    sudo nixos-rebuild switch --flake .#ATRI --option substituters "..."
    ```
    之后日常更新：`sudo nixos-rebuild switch --flake github:cookieidea/neko-nixos#ATRI`。
24. **`services.displayManager.session does not exist`（26.05）**：该选项已移除。注册 niri 会话
    改用系统级 `programs.niri.enable = true`（自动挂 wayland-sessions desktop 文件 +
    portal/gnome-keyring 推荐配置）。仓库已改。
25. **包名踩坑（26.05）**：`noto-fonts-emoji`→`noto-fonts-color-emoji`；
    `wineWowPackages`→`wineWow64Packages`；`fcitx5-configtool`→`qt6Packages.fcitx5-configtool`；
    `adw-gtk-theme`→`adw-gtk3`；无独立 `breeze-cursors` 属性（光标主题 Breeze_Cursors 由
    `kdePackages.breeze` 提供）；xorg 包集整体移到顶层（`xprop`/`xhost`）。
26. **`gtk.gtk3.extraConfig` 类型错误**：26.05 home-manager 的 `gtk3/gtk4.extraConfig` 是
    **attrset（`{ key = "value"; }`）不是多行字符串**；`gtk2.extraConfig` 才是 lines。
27. **图标还是消失（软件/软件内）**：根因常是 `xdg.configFile` 部署 `gtk-3.0/settings.ini`
    为只读 symlink，**挡住 home-manager gtk 模块写入** → `iconTheme` 从未生效。解法：
    settings.ini 交给 gtk 模块写（不部署），`iconTheme = Papirus`（覆盖 Steam/Flatpak/Electron），
    并装 `hicolor-icon-theme`（flatpak 应用图标兜底扫描）。
28. **`git reset --hard` 会删本机独有文件**：`hardware-configuration.nix` 只在本地 git 跟踪
    （不进远程），reset 后会丢失 → flake 报 `hardware-configuration.nix does not exist`。
    恢复：`sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix`
    （重定向需 `sudo sh -c '... > file'`，普通 `sudo cmd > file` 的重定向仍是用户权限）+
    `sudo git add`。日常对齐远程用 `git merge --ff-only origin/main` 或 `git stash -u`。
29. **`/home` 只读（git config / 写文件报只读文件系统）**：btrfs 子卷被标记只读（常见于
    quickload/snapper 快照恢复后，快照挂载只读）。修复：
    `sudo btrfs property set /home ro false && sudo mount -o remount,rw /home`。
30. **StartLive 构建报 `sphinx-9.1.0 not supported for interpreter python3.11`**：
    `python311` 下 keyring→secretstorage 依赖链的 sphinx-9 不支持 py311 → 用 `python312`。
31. **GRUB 主题目录避免中文名**：跨平台 git + Nix 路径解析对中文目录名会报
    `path has a trailing slash`；Windows 上 `git mv` 中文路径还会错位合并文件。
    主题目录用 ASCII（本仓库：yuzu/tao/nagisa/aris/midori），换配色改
    `configuration.nix` 的 `boot.loader.grub.theme`。
32. **CachyOS 内核（`nix-cachyos-kernel`）**：flake 输入**不要 follows nixpkgs**（官方要求
    补丁匹配其 pin 的 nixpkgs）；overlay 用 `pinned` 以命中 `attic.xuyh0120.win/lantian`
    缓存（否则本地编译内核极慢/VM 易 OOM）；rebuild 命令的 `--option substituters`
    记得加 `https://attic.xuyh0120.win/lantian`。
33. **`nixos-install` 报 `mismatch in field 'narHash'`（TUNA tarball 输入）**：nixpkgs 输入
    指向镜像站的**可变 tarball**（`nix-channels/nixos-26.05/nixexprs.tar.xz`），镜像一同步
    内容就变，`flake.lock` 里缓存的旧 narHash 对不上。修复（live ISO 的 `nix` 命令默认没开
    实验特性，必须显式带 flag）：
    ```bash
    cd /mnt/etc/nixos
    nix --extra-experimental-features "nix-command flakes" flake update
    nixos-install --flake .#ATRI --max-jobs 1
    ```
    根治方向：把 nixpkgs 输入改为 GitHub 固定 rev（`github:NixOS/nixpkgs/nixos-26.05`），
    镜像只作 substituters 用（源码哈希就不再受镜像同步影响）。
    > live ISO 上 `git commit` 可能报 `Author identity unknown`：先
    > `git config user.name "cookie" && git config user.email "cookie@nixos"` 再提交。
    > ⚠️ lock 更新后要 `git add flake.lock && git commit`（flake 只认 git 跟踪内容，dirty
    > 树虽能构建但 rev 不含改动）；装完把新 lock push 回远程，否则下次装机又踩。
34. **Go 包构建失败，日志 `proxy.golang.org ... connection refused`（被墙）**：如
    `bili-danmaku-tui`（Go/bubbletea 弹幕 TUI）。nixpkgs `buildGoModule` 的 go-modules
    固定输出派生把 `GOPROXY` 列入 `impureEnvVars` → **构建命令前 `export GOPROXY="https://goproxy.cn,direct"`
    即可透传进沙箱**（备选 `https://mirrors.aliyun.com/goproxy/,direct`），无需改配置。
    这是构建期行为、不持久，以后 rebuild 遇 Go 包都要带。
35. **`discord`（nixpkgs 包）构建失败，日志 `cannot download full.distro`**：nixpkgs 的
    discord 构建时必须从 `stable.dl1/2/3.discordapp.net` 下载客户端文件（`full.distro`），
    国内**必现**连不上（curl 重试 3 次全败），与网络抖动无关。仓库已改走 **Flatpak**
    （`home.nix` 删 `discord`，`flatpak-repo` 服务装 `com.discordapp.Discord`，走 USTC
    flathub 镜像，构建期零下载）。类似地，凡是「nixpkgs 包构建期从境外 CDN 拉二进制」
    的包在国内都会挂，优先查包的下游 URL 是否可达，不可达就换 Flatpak 或自构建。
36. **安装重跑仍用旧 rev**（日志 `building the flake ... rev=<旧 hash>`）：live USB 上
    `git pull` 因**分叉分支**被拒（本地提交过 flake.lock/hardware 与 origin 分叉）后直接
    install，会继续用本地旧提交构建。先解决分叉再装：
    ```bash
    git config pull.rebase false && git pull origin main   # 无冲突直接 merge
    git log --oneline -3                                    # 确认拉到目标 commit
    ```
    判断安装用的对不对：看 `rev=` 是否是预期 hash、日志里是否还有已修包的报错。
