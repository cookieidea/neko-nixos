# neko-nixos

个人 **NixOS 26.05「Yarara」+ Home Manager** 桌面配置（flake）。

- 桌面：**niri**（Wayland 滚动平铺 compositor）+ **Noctalia**（桌面 shell）+ ly 登录管理器
- 内核：**CachyOS RT-BORE**（实时 + BORE 调度器，低延迟）
- 硬件：AMD RX 6750 GRE + Intel i5-12400F（详见「目标硬件」）

---

## 目标硬件

| 部件 | 型号 | 适配要点 |
| --- | --- | --- |
| 显卡 | AMD Radeon RX 6750 GRE 10G | `amdgpu` + mesa + RADV(Vulkan) + libva(VA-API 硬解) |
| CPU | Intel i5-12400F | 无核显，无需 intel 驱动 / Prime |
| 架构 | x86_64-linux | — |

---

## 目录结构

```
neko-nixos/
├── flake.nix              # 入口：inputs、username/hostname/desktop 变量
├── configuration.nix      # 系统层：内核/显卡/网络/flatpak/登录/桌面服务…
├── home.nix               # 用户层（Home Manager）：软件包、dotfiles 托管
├── pkgs/                  # 自构建程序派生
├── install.sh             # 一键安装 / 更新脚本
├── docs/
│   ├── install-btrfs.md   # 全新安装教程（btrfs + GRUB + snapper + 休眠）
│   ├── dual-boot.md       # Windows + NixOS 双系统指南
│   └── keybindings.md     # 快捷键速查
└── dotfiles/              # 桌面与程序配置（niri、Noctalia、fcitx5、fish、kitty…）
```

---

## 包含的软件（home.packages 摘要）

- **工具 / 终端**：`fish` `starship` `eza` `zoxide` `fastfetch` `imagemagick` `jq` `timg` `bat` `btop` `gdu` `baobab` `mission-center` `yazi`
- **桌面 / 编辑器**：`google-chrome` `transmission_4-gtk` `localsend` `gnome-clocks` `lutris` `steam` `mangohud` `mpv` `obs-studio` `upscaler` `pavucontrol` `easyeffects` `libreoffice` `vscodium`
- **游戏 / 影音**：`hmcl` `kazumi` `lunar-client` `taterclient-ddnet` `protonplus` `mangojuice`
- **niri 生态**：`niri` `kitty` `fuzzel` `thunar` `nautilus` `satty` `cliphist` `wl-clipboard` `xsettingsd` `gpu-screen-recorder` `btrfs-assistant` `matugen` `imv`
- **主题 / 图标**：`adwaita-icon-theme` `papirus-icon-theme` `adw-gtk3` `breeze` —— 图标主题由 home-manager `gtk` 模块写入
- **flake 包**：`opencode`、`bili-danmaku-tui`、`cooknixvim`、`noctalia-shell`
- **Flatpak（flatpak-repo 服务自动装）**：微信 / QQ / Flatseal / Bazaar / OpenOrpheus
- **自构建程序（`./pkgs`）**：`niri-sidebar` `nyxniri-scratch-menu` `pins` `pywalfox` `shorin-contrib` `splayer-next` `ab-download-manager` `tabby-terminal` `obs-vdoninja` `purevox` `bedrockboot` `axolotl` `astral`

> ⚠️ `splayer-next` / `tabby-terminal` / `bedrockboot` / `axolotl` 与 nixpkgs 同名包不是同一个软件，勿混用。

---

## 关于 Flatpak

`services.flatpak.enable = true;`，Flathub 仓库切到**中科大镜像**（`mirrors.ustc.edu.cn/flathub`）。
微信 / QQ / Flatseal / Bazaar / OpenOrpheus 由 `flatpak-repo` one-shot 服务在启动时自动安装（幂等，见 `configuration.nix`）。想加其他应用往该服务的 `flatpak install` 行追加 ID 即可。

---

## 自构建程序（`./pkgs`）

| 程序 | 上游 | 构建系统 |
| --- | --- | --- |
| `niri-sidebar` | Vigintillionn/niri-sidebar | Rust / cargo |
| `nyxniri-scratch-menu` | — | Python + GTK3 / LayerShell |
| `pins` | fabrialberio/Pins | GTK4/libadwaita, meson |
| `pywalfox` | Frewacom/pywalfox | Python |
| `shorin-contrib` | shorin-contrib | Shell 脚本 |
| `splayer-next` | SPlayer-Dev/SPlayer-Next | Electron（AppImage 包装） |
| `ab-download-manager` | amir1376/ab-download-manager | jpackage |
| `tabby-terminal` | eugeny/tabby | Electron（AppImage 包装） |
| `obs-vdoninja` | steveseguin/ninja-obs-plugin | 预编译 .so |
| `purevox` | a2heng/PureVox | AppImage 包装 |
| `bedrockboot` | BedrockBoot | AppImage + buildFHSEnv（Wine 沙箱） |
| `axolotl` | Axolotl（MC Java 启动器） | 源码构建（Rust/Tauri + pnpm） |
| `astral` | AstralNext/Astral | 联网构建 bundle（本地 path 输入） |

- 通过 `packages.<system>` 暴露，可 `nix build .#<name>` 单独构建；已加入 `home.packages`。
- `install.sh` 在 `nixos-install` / `nixos-rebuild` 前会预构建，提前暴露错误。
- `astral` 的 bundle 是本地路径输入（`~/.cache/astral/bundle`），升级需先跑 `pkgs/astral/build.sh`。

---

## 运维

- **更新**：`sudo nix flake update --flake /etc/nixos && sudo nixos-rebuild switch --flake /etc/nixos`
- **清理**：`sudo nix-collect-garbage -d`；系统已配置 zram 压缩内存 + 每周代际自动清理
- **回滚**：`sudo nixos-rebuild switch --flake /etc/nixos --rollback`（或 snapper 快照）

---

## License

Noctalia / CookNixvim / opencode 等上游项目各自遵循其自身许可证。
