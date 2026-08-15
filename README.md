# neko-nixos

把 [SHORiN-KiWATA/shorin-arch-setup](https://github.com/SHORiN-KiWATA/shorin-arch-setup)（Arch Linux 一键配置脚本）转换成 **NixOS 26.05「Yarara」+ Home Manager** 的 flake 配置。

桌面沿用原项目的 **niri（Wayland 滚动平铺 compositor）+ Noctalia（桌面 shell）**，登录管理器用 **ly**（nixpkgs `services.displayManager.ly` 模块，登录界面选用户/会话），内核用 **CachyOS RT-BORE**（实时 + BORE 调度器，直播/推流低延迟）。

---

## 目标硬件

| 部件 | 型号 | 适配要点 |
| --- | --- | --- |
| 显卡 | AMD Radeon RX 6750 GRE 10G | `amdgpu` 驱动 + mesa + RADV(Vulkan) + libva(VA-API 硬解) |
| CPU | Intel i5-12400F | **无核显**，故不装 intel 驱动、不需要 NVIDIA Prime/offload |
| 架构 | x86_64-linux | — |

> 如果你的硬件不同（尤其是 NVIDIA 独显、Intel 核显、笔记本双显卡），需要改 `configuration.nix` 的 GPU 段与 `hardware.cpu.intel.updateMicrocode` 等。

---

## 已做的环境适配

- **minimal / 无图形界面 ISO 全新安装**：`configuration.nix` 顶部 `imports = [ ./hardware-configuration.nix ]`，配合 `nixos-generate-config --root /mnt` + `nixos-install --flake`（见安装脚本）。
- **CachyOS 内核**：`boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-rt-bore;`（flake 输入 `nix-cachyos-kernel` release 分支 + pinned overlay，二进制缓存 `attic.xuyh0120.win/lantian`）。
- **国内镜像源**（全部已配置，不可达时自动回退官方源，不会硬失败）：
  - Nix 二进制缓存：`nix.settings.extra-substituters` → 清华 TUNA + attic.xuyh0120.win/lantian（CachyOS 内核）
  - nixpkgs / home-manager 源码：flake 输入走清华 TUNA git 镜像
  - Flathub：官方 `dl.flathub.org`（国内 USTC/TUNA/阿里镜像 2026-08 起全部失效，见 docs 踩坑速查 18）
- **AMD 显卡**：开启 `hardware.graphics.enable`（26.05 由 `hardware.opengl` 改名）+ `vulkan-loader`(RADV) + `libva`(VA-API)，videoDriver 设为 `amdgpu`。
- **允许 unfree**：`qq` / `wechat` / `lunarclient` 等闭源包需要 `nixpkgs.config.allowUnfree = true;`（已在 `configuration.nix` 开启）。
- **输入法**：fcitx5 `waylandFrontend = true`（Wayland 原生 text-input），中文走 **rime + rime-ice（雾凇拼音，nixpkgs 自带词库）**，无日文输入法。

---

## 目录结构

```
neko-nixos/
├── flake.nix              # flake 入口：inputs（nixpkgs/home-manager/cooknixvim/opencode/bili-danmaku-tui/cachyos-kernel）、username/hostname/desktop 变量
├── configuration.nix      # 系统层：内核/显卡/网络/flatpak/登录管理器/桌面服务…
├── home.nix               # 用户层（Home Manager）：软件包、git/编辑器/主题等
├── pkgs/                 # 自构建程序派生（见下「自构建程序」一节）
├── install.sh             # 一键安装脚本（全新安装 / 已装系统更新 双模式）
├── docs/
│   ├── install-btrfs.md   # 全新安装教程（btrfs + GRUB + snapper + 休眠）
│   ├── dual-boot.md       # Windows + NixOS 双系统指南
│   └── keybindings.md     # 快捷键速查（niri + Noctalia + fcitx5）
├── dotfiles/              # 桌面与程序配置（niri、Noctalia、fcitx5、fish、kitty…）
│   ├── config/            # ~/.config 下内容（xdg.configFile 部署）
│   └── home/              # 家目录散文件（home.file 部署）
└── hardware-configuration.nix   # 全新安装时由 nixos-generate-config 生成（仓库不含）
```

---

## 包含的软件（home.packages 摘要）

按来源分组（括号内为原 Arch 包名）：

- **Standard（common-applist）**：`gdu` `baobab` `mission-center` `gnome-font-viewer` `google-chrome` `transmission_4-gtk` `localsend` `gnome-calendar` `gnome-clocks` `lutris` `steam` `mangohud` `mpv` `obs-studio` `upscaler` `yazi` `pavucontrol` `mousepad` `easyeffects`
- **Shell & Terminal（kde-applist）**：`fish` `starship` `eza` `zoxide` `fastfetch` `imagemagick` `jq` `timg` `bat` `btop`
- **编辑器**：`vscodium`（替代 AUR 的 `visual-studio-code-bin`，去遥测）
- **原 AUR 包（已在 nixpkgs 26.05 核实存在）**：`flclash` `discord` `ayugram-desktop` `gearlever` `lsfg-vk` `protonplus` `mangojuice`
- **游戏 / 影音客户端（用户新增）**：`hmcl` `kazumi`（替代 animeko）`lunar-client` `taterclient-ddnet`
- **原清单遗漏补回**：`virt-manager` `video-downloader`
- **niri 生态依赖**：`niri` `kitty` `fuzzel` `thunar` `nautilus` `satty` `cliphist` `wl-clipboard` `xsettingsd` `gpu-screen-recorder` `btrfs-assistant` `matugen` `imv`
- **主题/图标**：`adwaita-icon-theme` `papirus-icon-theme` `hicolor-icon-theme` `adw-gtk3` `breeze(kdePackages)`——图标主题由 home-manager `gtk` 模块写入（Papirus），settings.ini 不手写部署
- **flake 包（不在 nixpkgs 核心）**：`opencode`（AI 编程 Agent）、`bili-danmaku-tui`（B 站弹幕 TUI，自带 flake）、`cooknixvim`（模块化 Neovim 配置，基于 nixvim，取代原先直接用 nixvim）。桌面 shell 用 nixpkgs 自带的 `noctalia-shell`。
- **Flatpak 自动安装（flatpak-repo 服务）**：微信 / QQ / Flatseal / Bazaar 应用商店 / OpenOrpheus（网易云 Orpheus 宿主）
- **自构建程序（`./pkgs` 派生，对应原 Arch 的 AUR `-git` / 私有仓库）**：`niri-sidebar` `pins` `pywalfox` `shorin-contrib` `proton-wrapper` `splayer-next` `startlive` `ab-download-manager` `tabby-terminal` `obs-vdoninja` `purevox` `bedrockboot` `axolotl`
  - ⚠️ `splayer-next` 是 **SPlayer-Dev/SPlayer-Next**（Electron 音乐播放器），与 nixpkgs 里的 `splayer`（Simple Netease Cloud Music player）**不是同一个软件**，切勿混用。
  - ⚠️ `tabby-terminal` 是 **eugeny/tabby** 终端模拟器；nixpkgs 的 `tabby` 是 TabbyML AI 助手，同名不同项目。
  - ⚠️ MC 启动器用自构建 `bedrockboot`（基岩版，内嵌 Wine 沙箱）+ `axolotl`（Java 版）替代 `prismlauncher`；`purevox` 是 AI 音频降噪（AppImage 包装）。

---

## 关于 Flatpak

- `configuration.nix` 里 `services.flatpak.enable = true;`，Flathub 仓库先 add 官方
  （flatpakrepo 文件），再把仓库 URL 切到**中科大镜像** `https://mirrors.ustc.edu.cn/flathub`
  （2026-08 实测仓库根 200 可用；各镜像的 `.flatpakrepo` 文件本身 404，故不能直接 remote-add 镜像）。
- **微信 / QQ / Flatseal / Bazaar 应用商店 / OpenOrpheus** 由 `flatpak-repo` one-shot 服务在
  启动时自动安装（幂等，见 `configuration.nix` 的 `systemd.services.flatpak-repo`）：
  `com.tencent.WeChat`、`com.qq.QQ`、`com.github.tchx84.Flatseal`、`io.github.kolunmi.Bazaar`、
  `io.github.yucling.open-orpheus`。
- 想加其他 flatpak 应用，往该服务的 `flatpak install` 行追加 ID 即可。

## 关于 Noctalia（noctalia-shell / quickshell）

- 桌面 shell 用 **nixpkgs 自带的 `noctalia-shell`**（quickshell 配置 + `qs` 封装），由 `home.nix` 的 `pkgs.noctalia-shell` 安装、niri 的 `config.kdl` 用 `spawn-sh-at-startup "noctalia-shell"` 拉起。这还原了 SHORiN 原版「`qs -c noctalia-shell`」的 quickshell 写法。
- **IPC 驱动的交互已全部生效**：binds.kdl 里的启动器 / 设置 / 壁纸 / 电源菜单 / 锁屏 / 音量 / 亮度 / 剪贴板等绑定统一走 `noctalia-shell ipc call ...`（不再写 `qs -c noctalia-shell`）。
- `dotfiles/config/noctalia/*.json`（settings/plugins/colors）与 `user-templates.toml` 是**独立 noctalia v4 应用的配置**，已被 noctalia-shell 取代、不再被读取，保留仅作参考，可随时删除。
- ⚠️ 主题模板（pywalfox / fcitx5 / starship / gtk-folder / fastfetch）原本由 v4 的 `user-templates.toml` 生成；切换到 noctalia-shell 后**已装 `matugen`**（`random-anime-wallpaper-noctalia` 与 noctalia 主题模板直接调用，Mod+Shift+F10 随机壁纸会顺带重生成主题）。

---

## 自构建程序（`./pkgs` 派生）

原 Arch 脚本里一批软件走 AUR `-git` 或私有仓库，nixpkgs 26.05 没有等价包。它们在
Nix 里改用 **flake 内的 Nix 派生** 从源码/发布构建，集中在 `pkgs/`：

| 程序 | 上游 | 构建系统 | 对应原 Arch 包 |
| --- | --- | --- | --- |
| `niri-sidebar` | Vigintillionn/niri-sidebar | Rust / cargo | niri-sidebar-git |
| `pins` | fabrialberio/Pins | GTK4/libadwaita, meson | pins-git |
| `pywalfox` | Frewacom/pywalfox（PyPI `pywalfox`） | Python（buildPythonApplication） | python-pywalfox |
| `shorin-contrib` | SHORiN-KiWATA/shorin-contrib | Shell 脚本 | shorin-contrib-git |
| `proton-wrapper` | SHORiN-KiWATA/proton-wrapper | bash/Python + .desktop | shorin-proton-wrapper-git |
| `splayer-next` | SPlayer-Dev/SPlayer-Next | Electron（AppImage 包装） | splayer-next-git |
| `startlive` | Radekyspec/StartLive | Python + PySide6（wrapper，velopack stub） | startlive-git |
| `ab-download-manager` | amir1376/ab-download-manager | jpackage（makeWrapper + autoPatchelf） | abdownloadmanager-bin |
| `tabby-terminal` | eugeny/tabby | Electron（AppImage 包装） | — |
| `obs-vdoninja` | steveseguin/ninja-obs-plugin | 预编译 .so（autoPatchelf + libdatachannel override） | vdoninja（手动） |
| `purevox` | PureVox（AI 音频降噪） | AppImage 包装（AppRun 注入库路径） | — |
| `bedrockboot` | BedrockBoot（MC 基岩版启动器，Avalonia） | AppImage extract + buildFHSEnv（Wine 沙箱，注入 mesa/vulkan/gnutls 等）+ mkDerivation 补 desktop | — |
| `axolotl` | Axolotl（MC Java 版启动器） | AppImage extract + buildFHSEnv + mkDerivation 补 desktop（替代 prismlauncher） | — |

- 这些包通过 `packages.<system>` 暴露成 flake 包，可单独构建：
  ```bash
  nix build .#splayer-next  # 拉取官方 AppImage 并包装
  ```
- 它们也已加入 `home.nix` 的 `home.packages`，`nixos-rebuild switch` 时会自动构建并安装。
- `install.sh` 在跑 `nixos-install` / `nixos-rebuild` **之前** 会先逐个预构建这些包，提前暴露错误。

> ⚠️ **SPlayer-Next ≠ nixpkgs 的 `splayer`**：nixpkgs 里的 `splayer`（meta 写的是「Simple Netease Cloud Music player」）和上游 `SPlayer-Dev/SPlayer-Next` 是**两个不同软件**。本配置用的是真正的 SPlayer-Next，通过官方发布 AppImage + `appimage-run` 包装（从源码在 Nix 里构建 Electron 应用很脆弱，故采用此可靠方式；要从源码构建可参考 AUR `splayer-next-git` 的 PKGBUILD）。
>
> ⚠️ **`shorin-contrib` 没有 `shorin` 元命令**：原 Arch 脚本里的 `shorin link` 不在本仓库中；请直接调用各脚本（如 `clean`、`sysup`、`pac`、`pacd`、`mirror-update` 等）。
>
> ℹ️ **`miyu` 已移除**：按需求从自构建清单、`./pkgs`、home.nix、`install.sh` 中删除，不再构建。

---

## 安装

### 前置

- 已装好 NixOS（minimal / 无图形界面 ISO 也可），且 `/etc/nix/nix.conf` 含 `experimental-features = nix-command flakes`。
- 全新安装需先分区、格式化并挂载到某个挂载点（如 `/mnt`），再生成硬件配置：
  ```bash
  nixos-generate-config --root /mnt   # 生成 /mnt/etc/nixos/hardware-configuration.nix
  ```

### 方式一：一键脚本（推荐）

从仓库根目录运行 `install.sh`，支持两种模式：

```bash
# 1) 全新安装（minimal ISO）：用户名 + 挂载点
sudo bash install.sh <用户名> /mnt
#   例：sudo bash install.sh cookie /mnt

# 2) 已装系统更新 / 应用配置：
sudo bash install.sh [用户名]
#   例：sudo bash install.sh cookie
```

脚本会：
- 把配置里的硬编码用户名 `cookie` 替换成你的用户名（含 `flake.nix` 与 `dotfiles/` 下的路径）；
- 全新安装模式跑 `nixos-install --flake <挂载点>/etc/nixos/#ATRI`；
- 更新模式跑 `nixos-rebuild switch --flake /etc/nixos/#ATRI`；
- 复制后清理 `.git`，不覆盖你 `generate` 出来的 `hardware-configuration.nix`；
- **预构建自构建程序**（`pkgs/` 里的派生，对应原 Arch 的 AUR `-git` / 私有仓库），逐个 `nix build .#<name>`，提前暴露错误。

一行安装（从 GitHub 拉取并执行）：

```bash
sudo -E bash -c "$(curl -fsSL https://raw.githubusercontent.com/cookieidea/neko-nixos/main/install.sh)"
```

### 方式二：手动

```bash
# 全新安装
sudo nixos-install --flake /mnt/etc/nixos/#ATRI

# 已装系统
sudo nixos-rebuild switch --flake /etc/nixos/#ATRI
```

> 主机名默认 `ATRI`，flake 输出名与之对应（`#ATRI`）。要改主机名需同时改 `flake.nix` 的 `hostname` 与 `nixosConfigurations.${hostname}`。

---

## 部署前需要改的地方

1. **用户名**：改 `flake.nix` 的 `username`（或用 `install.sh` 传入自动替换）。
2. **Git 身份**：`home.nix` 中 `programs.git.userName` / `userEmail` 已设为 `cookieidea` / `jhbhyvv@outlook.com`，按需自行替换。
3. **首次登录密码**：全新安装时 `install.sh` 会交互提示设置 `initialPassword`；留空则装后用 `passwd <用户名>` 手动设。
4. **硬件差异**：NVIDIA / Intel 核显 / 笔记本双显卡用户需调整 `configuration.nix` 的 GPU 段。

---

## 常用维护命令

```bash
# 改完配置后重新构建
sudo nixos-rebuild switch --flake /etc/nixos/#ATRI

# 仅更新用户层（Home Manager）
home-manager switch --flake /etc/nixos/#ATRI

# 更新 flake 输入（nixpkgs / home-manager 等）
nix flake update

# 回滚到上一版本
sudo nixos-rebuild switch --rollback
```

---

## 与原 Arch 脚本的差异

- 包管理器从 `pacman`/`yay`(AUR) 换成 Nix flake + Home Manager，所有软件声明式管理、可复现。
- 编辑器用 `vscodium` 替代 AUR 的 `visual-studio-code-bin`（去遥测）。
- 壁纸/主题/启动器等桌面交互走 noctalia-shell（nixpkgs 自带，quickshell 封装）。
- 配置文件从「散装 dotfiles + 私有脚本」改为 Home Manager 托管（`xdg.configFile` / `home.file` / `programs.*`）。Arch 专属的 `/usr/lib/...` 路径已改写；SHORiN 私有 niri 脚本（`niri-binds` / `niri-pick` / `niri-force-kill-window` / `screenshot-sound.sh`）已通过本次配置迁移部署到 `~/.config/niri/scripts/`，截图音效守护也已接回 `config.kdl`，对应绑定（快捷键菜单、取窗口信息、强杀窗口、截图音效）现可用。仍依赖 AUR、本仓库未纳入的脚本（`shorin-screenrec-menu` / `quicksave` / `quickload`）对应的绑定（Mod+F3/F5/F8）会静默失败，需要时可自行补充。此外，启动器/设置/壁纸/电源菜单/锁屏/音量/亮度/剪贴板等 IPC 绑定现已通过 noctalia-shell 生效（binds.kdl 统一用 `noctalia-shell ipc call`）。

---

## License

配置脚本与 dotfiles 遵循原项目 [shorin-arch-setup](https://github.com/SHORiN-KiWATA/shorin-arch-setup) 的许可证（见其 `LICENSE`）。Noctalia / CookNixvim / opencode 等上游项目各自遵循其自身许可证。
