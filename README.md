# neko-nixos

个人 NixOS + Home Manager 桌面配置，基于 Flake 管理。

| 项目 | 当前值 |
|---|---|
| 主机 | **ATRI** |
| 架构 | **x86_64-linux** |
| 桌面 | **niri + Noctalia** |
| 内核 | **CachyOS RT-BORE** |
| GPU | **AMD** |

## 特性

- Wayland / niri / Noctalia / PipeWire
- Steam、Proton-GE、GameMode、Minecraft
- Waydroid、libvirt、Docker、distrobox
- AMD Mesa / OpenCL / ROCm / Ollama
- Flatpak、agenix、Home Manager
- 自定义 Nix packages
- 安装、更新与回滚

## 结构

```text
.
├── flake.nix
├── flake.lock
├── install.sh
├── scripts/
├── configuration/
│   ├── system.nix
│   ├── home.nix
│   ├── modules/
│   ├── system/
│   ├── device/
│   ├── home/
│   └── pkgs/
└── docs/
```

入口：

```text
flake.nix
└── nixosConfigurations.ATRI
    ├── configuration/system.nix
    └── configuration/home.nix
```

## 安装

目标机器先完成 UEFI/GPT、Btrfs、swap 和挂载，并生成硬件配置：

```bash
nixos-generate-config --root /mnt
git clone https://github.com/cookieidea/neko-nixos.git
cd neko-nixos
sudo bash install.sh cookie /mnt
```

安装脚本会保留目标机的 `hardware-config.nix`，预构建系统闭包后执行 `nixos-install`。

## 更新

已安装系统：

```bash
sudo bash /etc/nixos/install.sh cookie
```

更新会先 staging、保留本机硬件配置、执行检查和 dry-build，最后切换系统；切换失败会恢复旧配置源。

## 缓存

正式系统保留 `cache.nixos.org`，并通过 `extra-substituters` 追加仓库使用的国内 mirror、Attic 和多个项目 Cachix。

不同 Cachix 提供不同项目的构建产物，因此不会为了“减少数量”合并或删除它们。

## 常用命令

```bash
sudo nixos-rebuild switch --flake /etc/nixos#ATRI
sudo nixos-rebuild dry-build --flake /etc/nixos#ATRI
nix flake check
nix fmt
nix flake update
nix build .#niri-sidebar
sudo nixos-rebuild switch --rollback
```

## 文档

- [Btrfs 安装](docs/install-btrfs.md)
- [双系统](docs/dual-boot.md)
- [快捷键](docs/keybindings.md)
- [维护说明](docs/notes.md)

## 许可

MIT License。详见 [LICENSE](LICENSE).