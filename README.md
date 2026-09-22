# neko-nixos

个人 NixOS + Home Manager 桌面配置，以 Flake 管理单机系统。

## 概览

| 项目 | 当前值 |
|---|---|
| 主机 | **ATRI** |
| 架构 | **x86_64-linux** |
| 桌面 | **niri + Noctalia** |
| 会话 | **Wayland** |
| 内核 | **CachyOS RT-BORE** |
| GPU | **AMD** |
| 系统版本 | **NixOS 26.05** |

这个仓库更偏向一套长期维护的个人桌面系统，而不是通用 NixOS 模板。配置、Home Manager、硬件、模块、自定义 packages 和安装脚本都集中在 Flake 中管理。

## 特性

- Wayland / niri / Noctalia / PipeWire / Fcitx5
- Steam / Proton-GE / GameMode / Minecraft
- Waydroid / libvirt / Docker / distrobox
- AMD Mesa / Vulkan / OpenCL / ROCm / Ollama
- Flatpak / Home Manager / agenix / XDG desktop portal
- Sunshine / OBS / KDE Connect / Nautilus
- mpv + VapourSynth / RIFE、Anime4K、FSRCNNX、RAVU 等视频处理
- 多个自定义 Nix packages 和上游预编译软件封装
- 声明式安装、更新、回滚与本机 hardware-config 保留

## 设计

### Flake

`flake.nix` 是唯一入口，主机配置为：

```text
flake.nix
└── nixosConfigurations.ATRI
    ├── configuration/system.nix
    └── configuration/home.nix
```

系统和用户配置使用同一套 `pkgs`，减少 Home Manager 与 NixOS 之间的包版本漂移。

### 目录

```text
.
├── flake.nix              # Flake 入口、inputs、NixOS 输出
├── flake.lock             # 锁定所有 inputs
├── install.sh             # 新装 / 已安装系统更新入口
├── scripts/               # 安装、更新和维护脚本
├── configuration/
│   ├── system.nix         # NixOS 主入口
│   ├── home.nix           # Home Manager 主入口
│   ├── modules/           # 功能模块
│   ├── system/            # 系统级基础配置
│   ├── device/            # 硬件、GPU、休眠等
│   ├── home/              # 用户环境、dotfiles、session
│   └── pkgs/              # 自定义 Nix packages
├── docs/                  # 安装、维护和快捷键文档
├── secrets/               # agenix 加密数据
└── skills/                # 本仓库维护/开发辅助资料
```

硬件配置位于 `configuration/device/hardware-config.nix`，只应该使用目标机器自己生成的版本。

## 安装

当前系统按 UEFI + GPT、Btrfs、独立 swap 和 GRUB 的单机布局编写。

先在安装环境完成分区、挂载，并生成目标机硬件配置：

```bash
nixos-generate-config --root /mnt
```

然后获取仓库并执行安装：

```bash
git clone https://github.com/cookieidea/neko-nixos.git
cd neko-nixos
sudo bash install.sh cookie /mnt
```

安装脚本会检查参数、准备源码与 hostname、保留目标机 `hardware-config.nix`、预构建 `system.build.toplevel`，然后执行 `nixos-install`，最后设置用户密码。

安装阶段通过 `NIX_CONFIG` 临时追加仓库需要的 Nix mirror、Attic 和 Cachix，不修改 live environment 的 `/etc/nix/nix.conf`。

## 更新

已安装系统可以直接执行：

```bash
sudo bash /etc/nixos/install.sh cookie
```

更新流程会先创建 staging 目录，保留当前机器的 hardware-config，然后依次执行预构建、`nix flake check`、dry-build，确认通过后替换 `/etc/nixos` 并执行 switch。

如果 switch 失败，更新脚本会恢复旧配置源。

## 缓存

正式系统保留官方 `cache.nixos.org`，并通过 `extra-substituters` 追加国内 mirror、Attic 以及多个项目 Cachix。

当前缓存包括：

- USTC
- TUNA
- Lantian Attic
- Noctalia Cachix
- NekoBox Cachix
- Numtide
- CookNixvim Cachix
- nix-community Cachix

这些缓存不是重复配置。不同项目会发布不同构建产物，因此按项目保留多个 cache 是有意设计。

## NyxNiri Dunder Protocol

仓库兼容 NyxNiri 的 **Dunder Protocol**，用于保护个人桌面配置覆盖，避免 Home Manager 更新时把用户配置重新指向 `/nix/store`。

当前受保护的配置根目录：

```text
~/.config/niri/
~/.config/kitty/
~/.config/fish/
```

- 名称包含 `__custom__` 的文件和目录，在 Home Manager 更新前自动快照，更新完成后恢复。
- 旧 generation 中如果是指向 `/nix/store` 的 `__custom__` symlink，会在首次迁移时自动物化为用户可编辑的真实文件。
- Niri 的 `monitor.kdl` / `effects.kdl` 是固定文件名保留项，也会跨 generation 保留。
- 协议只负责“保留”，具体加载仍由应用自身负责：Niri / Kitty 使用 include，Fish 使用 `conf.d`。

因此覆盖关系为：

```text
默认配置 → __custom__ 用户覆盖
```

普通非 `__custom__` 配置仍由 Home Manager 声明式管理。

## 运行时与 Wrapper

仓库采用“最小作用域”的运行时环境原则：

```text
原始程序
   │
   ├─ 不需要运行时修正 → 直接使用
   │
   └─ 需要修正 → 一个最终 wrapper
                         │
                         └─ 原始程序
```

程序专属的 `PYTHONPATH`、VapourSynth 插件路径和动态库路径尽量只注入对应程序，不污染整个用户 session。

复杂的预编译软件使用 `buildFHSEnv` 或专用运行时；不会为了简单环境变量层层套 wrapper。

## 自定义 Packages

自定义包统一位于 `configuration/pkgs/`，分为 `public` 和 `internal` 两组。

部分代表性包：

- `niri-sidebar` / `nyxniri-scratch-menu`
- `ab-download-manager` / `astral`
- `purevox` / `splayer-next` / `tabby-terminal`
- `bedrockboot`
- `vapoursynth-with-plugins`
- Nautilus 扩展及相关工具

预编译 Linux 软件通常采用 `autoPatchelfHook`、AppImage 提取、`buildFHSEnv` 或单层 wrapper 处理运行时差异。

## Secrets

敏感配置使用 agenix 管理。加密文件提交到仓库，运行时由系统 secret 配置解密到受控路径。

例如 mark-shot 的敏感配置不会直接写入 Nix store；需要可写配置时，会先将只读模板物化到用户目录，再注入 secret。

## Flatpak

Flatpak 由 `configuration/modules/flatpak.nix` 声明式管理。

Flathub remote 使用 USTC 缓存地址；缓存未命中时仍可能访问上游源站。

`uninstallUnmanaged = true` 与 override pruning 用于让声明配置保持为实际应用集合的来源。

需要注意：NixOS generation 回滚的是声明状态，不等价于恢复 `/var/lib/flatpak` 中某个旧应用版本。

## GPU / ROCm

AMD GPU 使用 Mesa/RADV、OpenCL 与 ROCm。Ollama 使用 ROCm 运行时，并保留 LACT 所需的 `amdgpu.ppfeaturemask` 配置。

## SSH

SSH 默认只允许公钥认证，并禁止 root 直接登录。用户公钥由 NixOS 配置声明。

## 休眠

`configuration/device/resume.nix` 自动处理单个 `/dev/...` 块设备 swap。

swapfile、多个 swap、LUKS/LVM 等场景需要显式配置 `boot.resumeDevice`；swapfile 还需要对应 offset。

## 回滚与维护

常用命令：

```bash
# 应用当前配置
sudo nixos-rebuild switch --flake /etc/nixos#ATRI

# 试构建
sudo nixos-rebuild dry-build --flake /etc/nixos#ATRI

# Flake 检查
nix flake check

# 格式化
nix fmt

# 更新 inputs
nix flake update

# 构建单个自定义 package
nix build .#niri-sidebar

# 回滚到上一代
sudo nixos-rebuild switch --rollback
```

系统 generation 定期清理，但会保留最近若干代用于回滚；Snapper 单独管理 Btrfs 快照。

## 文档

| 文档 | 内容 |
|---|---|
| [install-btrfs.md](docs/install-btrfs.md) | NixOS ISO、Btrfs、swap、休眠、Snapper、安装 |
| [dual-boot.md](docs/dual-boot.md) | Windows + NixOS 双系统 |
| [keybindings.md](docs/keybindings.md) | niri 快捷键 |
| [notes.md](docs/notes.md) | 维护约定和已知事项 |
| [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md) | 第三方代码与许可证边界 |

## 许可

本仓库由作者创作的配置、脚本和代码采用 **GPL-3.0-only**。仓库中复制、修改或随配置分发的第三方文件不因顶层许可证变化而自动转为 MIT；它们继续遵循各自文件中的原始版权与许可证声明。

详见 [LICENSE](LICENSE) 与 [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md)。