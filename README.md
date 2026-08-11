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
- **flake 包（不在 nixpkgs 核心）**：`opencode`（AI 编程 Agent）、`noctalia`（桌面 shell）

> `flatseal` 在此是以 **nixpkgs 原生包** 形式安装（AUR/官方源同名），不是走 flatpak 运行时。

---

## 关于 Flatpak

- `configuration.nix` 里 `services.flatpak.enable = true;`，并把手 Flathub 远程指向中科大镜像。
- **默认没有声明任何 Flatpak 包**——`qq`/`wechat` 都用 nixpkgs 原生版，无需 flatpak。
- 想用 flatpak 装闭源 App，取消 `home.nix` 末尾 `services.flatpak.packages` 注释并填入包名即可，例如：
  ```nix
  services.flatpak.packages = [
    "flathub:org.tencent.qq"
  ];
  ```

> 说明：原 Arch 脚本（shorin-arch-setup）同样只 **启用 flatpak 服务 + 注册 Flathub 远程**，其应用清单里没有任何 `flatpak:` 前缀条目，因此并不会通过 flatpak 实际安装任何软件；本转换保持了这一行为。

## 关于 Noctalia（已固定 v5）

- `flake.nix` 的 noctalia 输入固定为 `github:noctalia-dev/noctalia/v5.0.0-beta.8`（v5 目前处于 Beta）。
- **v5 配置是单一 TOML 文件**：`dotfiles/config/noctalia/config.toml`，部署到 `~/.config/noctalia/config.toml`。
- ⚠️ v5 与 v4 **不兼容**：v4 用的是 `settings.json` / `plugins.json` / `colors.json`（JSON），v5 一律不读。本仓库已删除这些 v4 文件，整套配置改为 `config.toml`（基于官方 `example.toml` 默认值 + 移植的自定义项）。
- 已移植的自定义项：`dock` 开启、`avatar` 路径、5 个用户模板（pywalfox / fcitx5 / starship / gtk-folder / fastfetch，写在 `[theme.templates.user.*]`）、以及内置模板 id（kitty / niri / fuzzel / btop / cava / gtk，写在 `builtin_ids`）。
- 仍建议上机后用 `noctalia theme --list-templates` 核对 `builtin_ids` 的实际 id，并按需在 GUI 里微调（v5 大量细节样式走 GUI 覆盖，不在 `config.toml` 里）。

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
- 复制后清理 `.git`，不覆盖你 `generate` 出来的 `hardware-configuration.nix`。

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
2. **Git 身份**：`home.nix` 中 `programs.git.userName` / `userEmail` 目前是占位符 `yourname` / `you@example.com`，部署前换成你的真实信息。
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
- 壁纸/主题/启动器等桌面交互走 Noctalia（nixpkgs 无，用 flake 引入）。
- 配置文件从「散装 dotfiles + 私有脚本」改为 Home Manager 托管（`xdg.configFile` / `home.file` / `programs.*`），并去掉了 Arch 专属的 `/usr/lib/...` 路径与依赖私有脚本的绑定（截图音效、linuxqq-clipsync 等）。

---

## License

配置脚本与 dotfiles 遵循原项目 [shorin-arch-setup](https://github.com/SHORiN-KiWATA/shorin-arch-setup) 的许可证（见其 `LICENSE`）。Noctalia / nixvim / opencode 等上游项目各自遵循其自身许可证。
