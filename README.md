# neko-nixos

把 [SHORiN-KiWATA/shorin-arch-setup](https://github.com/SHORiN-KiWATA/shorin-arch-setup)（Arch Linux 一键配置脚本）转换成 **NixOS 26.05「Yarara」+ Home Manager** 的 flake 配置。

桌面沿用原项目的 **niri（Wayland 滚动平铺 compositor）+ Noctalia（桌面 shell）**，登录管理器用 **greetd + tuigreet**，登录后直接进入 niri。

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
- **最新内核**：`boot.kernelPackages = pkgs.linuxPackages_latest;`。
- **国内镜像源**（全部已配置，不可达时自动回退官方源，不会硬失败）：
  - Nix 二进制缓存：`nix.settings.extra-substituters` → 清华 TUNA（`mirrors.tuna.tsinghua.edu.cn/nix-channels/store`）
  - nixpkgs / home-manager 源码：flake 输入走清华 TUNA git 镜像
  - Flathub 远程：中科大 USTC 镜像（`mirrors.ustc.edu.cn/flathub`）
- **AMD 显卡**：开启 `hardware.opengl.enable` + `vulkan-loader`(RADV) + `libva`(VA-API)，videoDriver 设为 `amdgpu`。
- **允许 unfree**：`qq` / `wechat` / `lunarclient` 等闭源包需要 `nixpkgs.config.allowUnfree = true;`（已在 `configuration.nix` 开启）。

---

## 目录结构

```
neko-nixos/
├── flake.nix              # flake 入口：inputs（含国内镜像）、username/hostname/desktop 变量
├── configuration.nix      # 系统层：内核/显卡/网络/flatpak/登录管理器/桌面服务…
├── home.nix               # 用户层（Home Manager）：软件包、git/编辑器/主题等
├── pkgs/                 # 自构建程序派生（见下「自构建程序」一节）
├── install.sh             # 一键安装脚本（全新安装 / 已装系统更新 双模式）
├── dotfiles/              # 桌面与程序配置（niri、Noctalia、fcitx5、fish、kitty…）
│   ├── config/            # ~/.config 下内容（xdg.configFile 部署）
│   └── home/              # 家目录散文件（.vimrc、.gtkrc-2.0 等，home.file 部署）
└── hardware-configuration.nix   # 全新安装时由 nixos-generate-config 生成（仓库不含）
```

---

## 包含的软件（home.packages 摘要）

按来源分组（括号内为原 Arch 包名）：

- **Standard（common-applist）**：`gdu` `baobab` `mission-center` `gnome-font-viewer` `google-chrome` `transmission-gtk` `localsend` `gnome-calendar` `gnome-clocks` `lutris` `steam` `mangohud` `mpv` `obs-studio` `upscaler` `yazi` `flatseal` `pavucontrol` `mousepad` `easyeffects` `fcitx5-mozc` `rime-wubi`
- **Shell & Terminal（kde-applist）**：`fish` `starship` `eza` `zoxide` `fastfetch` `imagemagick` `jq` `timg` `bat` `btop`
- **编辑器**：`vscodium`（替代 AUR 的 `visual-studio-code-bin`，去遥测）
- **原 AUR 包（已在 nixpkgs 26.05 核实存在）**：`flclash` `wechat` `qq` `gearlever` `lsfg-vk` `protonplus` `mangojuice` `rime-wanxiang`
- **游戏 / 影音客户端（用户新增）**：`hmcl` `animeko`(替代 kazumi) `lunarclient` `taterclient-ddnet`
- **原清单遗漏补回**：`virt-manager` `video-downloader`
- **niri 生态依赖**：`niri` `kitty` `fuzzel` `thunar` `satty` `cliphist` `wl-clipboard` `xsettingsd`
- **flake 包（不在 nixpkgs 核心）**：`opencode`（AI 编程 Agent）。桌面 shell 改用 nixpkgs 自带的 `noctalia-shell`（quickshell 配置封装），不再用独立 `noctalia` v4 应用。
- **自构建程序（`./pkgs` 派生，对应原 Arch 的 AUR `-git` / 私有仓库）**：`niri-sidebar` `pins` `pywalfox` `shorin-contrib` `proton-wrapper` `splayer-next`
  - ⚠️ `splayer-next` 是 **SPlayer-Dev/SPlayer-Next**（Electron 音乐播放器），与 nixpkgs 里的 `splayer`（Simple Netease Cloud Music player）**不是同一个软件**，切勿混用。

> `flatseal` 在此是以 **nixpkgs 原生包** 形式安装（AUR/官方源同名），不是走 flatpak 运行时。

---

## 关于 Flatpak

- `configuration.nix` 里 `services.flatpak.enable = true;`，并把手 Flathub 远程指向中科大镜像。
- **默认没有声明任何 Flatpak 包**——`qq`/`wechat` 都用 nixpkgs 原生版，无需 flatpak。
- 想用 flatpak 装闭源 App，取消 `home.nix` 末尾 `services.flatpak.packages` 注释并填入包名即可，例如：
  ```nix
  services.flatpak.packages = [
    "flathub:com.qq.QQ"
  ];
  ```

> 说明：原 Arch 脚本（shorin-arch-setup）同样只 **启用 flatpak 服务 + 注册 Flathub 远程**，其应用清单里没有任何 `flatpak:` 前缀条目，因此并不会通过 flatpak 实际安装任何软件；本转换保持了这一行为。

## 关于 Noctalia（noctalia-shell / quickshell）

- 桌面 shell 用 **nixpkgs 自带的 `noctalia-shell`**（quickshell 配置 + `qs` 封装），由 `home.nix` 的 `pkgs.noctalia-shell` 安装、niri 的 `config.kdl` 用 `spawn-sh-at-startup "noctalia-shell"` 拉起。这还原了 SHORiN 原版「`qs -c noctalia-shell`」的 quickshell 写法。
- **IPC 驱动的交互已全部生效**：binds.kdl 里的启动器 / 设置 / 壁纸 / 电源菜单 / 锁屏 / 音量 / 亮度 / 剪贴板等绑定统一走 `noctalia-shell ipc call ...`（不再写 `qs -c noctalia-shell`）。
- `dotfiles/config/noctalia/*.json`（settings/plugins/colors）与 `user-templates.toml` 是**独立 noctalia v4 应用的配置**，已被 noctalia-shell 取代、不再被读取，保留仅作参考，可随时删除。
- ⚠️ 主题模板（pywalfox / fcitx5 / starship / gtk-folder / fastfetch）原本由 v4 的 `user-templates.toml` 生成；切换到 noctalia-shell 后这套模板机制需要另行接线（例如直接跑 matugen），暂未处理，属已知待办。

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
- 全新安装模式跑 `nixos-install --flake <挂载点>/etc/nixos/#nixos`；
- 更新模式跑 `nixos-rebuild switch --flake /etc/nixos/#nixos`；
- 复制后清理 `.git`，不覆盖你 `generate` 出来的 `hardware-configuration.nix`；
- **预构建自构建程序**（`pkgs/` 里的派生，对应原 Arch 的 AUR `-git` / 私有仓库），逐个 `nix build .#<name>`，提前暴露错误。

一行安装（从 GitHub 拉取并执行）：

```bash
sudo -E bash -c "$(curl -fsSL https://raw.githubusercontent.com/cookieidea/neko-nixos/main/install.sh)"
```

### 方式二：手动

```bash
# 全新安装
sudo nixos-install --flake /mnt/etc/nixos/#nixos

# 已装系统
sudo nixos-rebuild switch --flake /etc/nixos/#nixos
```

> 主机名默认 `nixos`，flake 输出名与之对应（`#nixos`）。要改主机名需同时改 `flake.nix` 的 `hostname` 与 `nixosConfigurations.${hostname}`。

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
sudo nixos-rebuild switch --flake /etc/nixos/#nixos

# 仅更新用户层（Home Manager）
home-manager switch --flake /etc/nixos/#nixos

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

配置脚本与 dotfiles 遵循原项目 [shorin-arch-setup](https://github.com/SHORiN-KiWATA/shorin-arch-setup) 的许可证（见其 `LICENSE`）。Noctalia / nixvim / opencode 等上游项目各自遵循其自身许可证。
