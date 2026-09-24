# neko-nixos

个人 NixOS + Home Manager 桌面配置，以 Flake 管理单机系统。

## 概览

| 项目 | 当前值 |
|---|---|
| 架构 | **x86_64-linux** |
| 桌面 | **niri + Noctalia** |
| 内核 | **CachyOS RT-BORE** |
| GPU | **AMD** |
| 系统版本 | **NixOS 26.05** |


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


## 安装/更新

安装看[docs](docs/install-btrfs.md)

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


## 文档

| 文档 | 内容 |
|---|---|
| [install-btrfs.md](docs/install-btrfs.md) | NixOS ISO、Btrfs、swap、休眠、Snapper、安装 |
| [dual-boot.md](docs/dual-boot.md) | Windows + NixOS 双系统 |
| [keybindings.md](docs/keybindings.md) | niri 快捷键 |
| [notes.md](docs/notes.md) | 维护约定和已知事项 |
| [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md) | 第三方代码与许可证边界 |

## 许可

本仓库由作者创作的配置、脚本和代码采用 **MIT License**。仓库中复制、修改或随配置分发的第三方文件不因顶层许可证变化而自动转为 MIT；它们继续遵循各自文件中的原始版权与许可证声明。

详见 [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md)。
