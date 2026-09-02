# 实体机安装指南（btrfs + GRUB/UEFI + 休眠 + snapper）

面向本仓库 flake（`.#ATRI`）的全新安装。参考 [NixOS Wiki: Btrfs](https://wiki.nixos.org/wiki/Btrfs)。

要点：GRUB(UEFI)、btrfs 子卷（`@/@home/@nix/@snapshots`）、独立 SWAP 分区（休眠用）、snapper 快照、flake 安装、国内源（USTC/TUNA/attic）。

## 目标布局

```
nvme0n1p1  1G        vfat       BOOT  → /boot（GRUB + 内核）
nvme0n1p2  ≥ 物理内存 linux-swap SWAP → swap + 休眠
nvme0n1p3  剩余      btrfs      nixos → /（子卷 @ @home @nix @snapshots）
```

> `/dev/nvme0n1` 仅示例，动手前先 `lsblk` 确认。SWAP ≥ 内存（休眠镜像≈已用内存）。

## 1. 分区 / 格式化 / 子卷

```bash
sudo -i
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL,LABEL
cfdisk /dev/nvme0n1        # GPT: 1G EFI + ≥RAM swap + 剩余 Linux filesystem

mkfs.fat -F32 -n BOOT /dev/nvme0n1p1
mkswap -L SWAP /dev/nvme0n1p2
mkfs.btrfs -f -L nixos /dev/nvme0n1p3

mount /dev/nvme0n1p3 /mnt
findmnt -n -o FSTYPE /mnt              # 必须是 btrfs 再继续（防 mount 静默失败 ENOTTY）
btrfs subvolume create /mnt/@{,@home,@nix,@snapshots}   # bash 花括号展开建 4 个
umount /mnt
```

## 2. 挂载（含 zstd 双保险）

```bash
mount -o subvol=@,compress=zstd,noatime     /dev/nvme0n1p3 /mnt
mkdir -p /mnt/{boot,home,nix,.snapshots}
mount -o subvol=@home,compress=zstd,noatime /dev/nvme0n1p3 /mnt/home
mount -o subvol=@nix,compress=zstd,noatime  /dev/nvme0n1p3 /mnt/nix
mount -o subvol=@snapshots,noatime          /dev/nvme0n1p3 /mnt/.snapshots
mount /dev/nvme0n1p1 /mnt/boot

# 压缩属性写入子卷（挂载选项即使丢了也照样压缩；勿再手动改 hardware 的 device）
for mp in /mnt /mnt/home /mnt/nix; do btrfs property set "$mp" compression zstd; done
```

## 3. 生成配置 + 放入 flake

```bash
swapon /dev/disk/by-label/SWAP         # 让 generate-config 识别 swap
nixos-generate-config --root /mnt

cd /mnt/etc/nixos
rm -f configuration.nix                # 用仓库 flake，删默认配置
git clone https://github.com/cookieidea/neko-nixos.git repo
cp -r repo/. . && rm -rf repo
git add hardware-configuration.nix     # ⚠️ flake 只认 git 跟踪文件，必须 add
```

> **不要手动改 `hardware-configuration.nix` 的 `fileSystems."/".device`**（by-uuid 已正确；
> 重定义会报 `attribute ... already defined` 安装卡死）。要加压缩就靠第 2 步的 btrfs 属性。

## 4. 安装

```bash
cd /mnt/etc/nixos
nixos-install --flake .#ATRI --max-jobs 1 \
  --option substituters "https://attic.xuyh0120.win/lantian https://mirrors.ustc.edu.cn/nix-channels/store https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://cache.nixos.org" \
  --option trusted-public-keys "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
```

坑：
- **必须显式传 substituters**：26.05 的 `nixos-install` 忽略 flake 内配置。attic 放最前（CachyOS 内核缓存）+ 公钥一起传。
- **OOM**：flake 评估峰值 ~6.6G 内存，<8G 机器加 `--max-jobs 1` 仍会被杀；live ISO 的 `/` 是 tmpfs 建不了 swapfile → 用 zram 兜底：`modprobe zram && zramctl -f -s 16G && mkswap /dev/zram0 && swapon -p 100 /dev/zram0`。
- **Go 包（bili-danmaku-tui）构建连不上 proxy.golang.org**：构建前 `export GOPROXY="https://goproxy.cn,direct"`。

装完设密码、重启：

```bash
nixos-enter -c 'passwd cookie'
reboot
```

## 5. 装后验证

```bash
uname -r                                  # 应含 cachyos（CachyOS 内核）
findmnt -n -o FSTYPE /                    # btrfs
btrfs property get / compression          # zstd
swapon --show                              # SWAP 分区
cat /sys/power/resume                      # SWAP 设备路径
sudo snapper -c root list                  # 应有时间线快照
```

应用图标 / 壁纸 / 输入法等验证细节见仓库 `home.nix` 注释与下方踩坑速查。

**休眠测试**（先存盘）：`systemctl hibernate`，恢复黑屏则查 `journalctl -b -1 | grep -i resume`。

## 6. 快照与回滚

- **系统回滚（最稳，优先）**：GRUB 里选旧 NixOS generation（`configurationLimit=20`），或 `sudo nixos-rebuild switch --rollback`。
- **数据回滚**（snapper）：`sudo snapper -c root list` → `sudo snapper -c root rollback <号>` → `reboot`。
- 日常：`sudo snapper -c root create --description "xxx"` / `delete <号>` / `list`。
- 26.05 移除 `grub-btrfs`，GRUB 无快照子菜单，正常现象。

## 踩坑速查（按 26.05 实测）

| # | 症状 | 处理 |
|---|---|---|
| 1 | `btrfs subvolume create: Inappropriate ioctl` (ENOTTY) | `/mnt` 没挂上 btrfs（mount 静默失败/挂错设备）。先 `findmnt` 校验 |
| 2 | 安装后 `/etc/nixos` 是空的 | clone 仓库 + `nixos-generate-config` + `git add -A` + commit + `nixos-rebuild switch --flake .#ATRI`（flake 只认 tracked 文件） |
| 3 | `hardware-configuration.nix does not exist / not tracked` | 第 3 步没 `git add hardware-configuration.nix` |
| 4 | `fileSystems."/".device already defined` | 手动改了/追加了 device 路径（永远不要） |
| 5 | flake 拉取 403 / GitHub API 限流 | flake 已用 `git+https://github.com`（不走 REST API）；仍失败 `git config --global http.version HTTP/1.1` 或走代理 |
| 6 | 安装 OOM 被杀（无报错） | 评估 ~6.6G：zram 16G 兜底或加内存（见第 4 节）；**live ISO 根是 tmpfs，swapfile 无效** |
| 7 | `git pull` 分叉被拒 | 本地提交过 hardware/lock 文件：`git config pull.rebase false && git pull origin main` |
| 8 | `git reset --hard` 后 flake 报 hardware 不存在 | 该文件只在本地跟踪；恢复：`sudo sh -c 'nixos-generate-config --show-hardware-config > hardware-configuration.nix'` + add |
| 9 | 改配置"不生效"（drv 名不变） | dirty 树源缓存坑：commit 使树干净或 `--flake path:/etc/nixos#ATRI` |
| 10 | 图标紫黑棋盘格 | 缺图标主题：装 `hicolor/adwaita/papirus-icon-theme`，home-manager `gtk` 模块设 iconTheme=Papirus；**不要**用 xdg.configFile 部署 settings.ini（只读 symlink 挡住模块写入） |
| 11 | 快照列表一直是空的 | snapper 配置键须全大写（`SUBVOLUME/TIMELINE_CREATE/...`），旧 camelCase 被静默吞掉 |
| 12 | flathub 国内镜像 404 | 先 remote-add 官方 repo 再 `remote-modify flathub --url=https://mirrors.ustc.edu.cn/flathub`（仓库已配）；QQ=`com.qq.QQ`，微信=`com.tencent.WeChat`，Discord 走 Flatpak（nixpkgs 包下载 discordapp.net 必挂） |
| 13 | 休眠后黑屏 | SWAP ≥ 内存、`boot.resumeDevice=/dev/disk/by-label/SWAP`（已配）；`journalctl -b -1` 查 resume |
| 14 | `/home` 只读 | 快照恢复后子卷只读：`sudo btrfs property set /home ro false && mount -o remount,rw /home` |
| 15 | TUNA tarball 输入 `narHash mismatch` | 镜像同步变了 tarball：`nix flake update` 后重装（根治：nixpkgs 输入改 GitHub 固定 rev） |
| 16 | home-manager 报 `The name is not activatable` | 需 `programs.dconf.enable = true`（已配） |

## 变更

26.05 已移除/改名（仓库均已适配，装完无需手动处理）：`services.grub-btrfs`（移除）、`services.snapper.snapshotRootOnSubvol`→`snapshotRootOnBoot`、`configs.<名>` 键全大写、`programs.niri.enable` 注册会话、`displayManager.session` 移除、`nerdfonts`→`nerd-fonts.名称`。
