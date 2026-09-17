# neko-nixos

个人 NixOS 26.05 + Home Manager 配置（flake）。

- 主机 `ATRI` / 用户 `cookie`
- 桌面 **niri** + **Noctalia**，登录 **greetd**（Noctalia Greeter）
- 内核 **CachyOS RT-BORE**
- 硬件：AMD RX 6600（gfx1032）+ Intel i5-12400F

## 目录

```
flake.nix            # 入口：inputs + username/hostname
configuration.nix    # 系统层：内核/显卡/网络/防火墙/flatpak/登录
home.nix             # 用户层：软件包 + dotfiles 托管
pkgs/                # 自构建派生（nix build .#<name>）
dotfiles/            # 桌面与程序配置（niri/Noctalia/fish/kitty/mpv…）
secrets/             # agenix 加密 secrets（公钥清单 secrets/secrets.nix）
docs/                # 安装与快捷键文档
install.sh           # 安装/更新脚本
skills/              # AI agent skills（opencode 扫描）
```

## 常用命令

```bash
# 更新
nix flake update && sudo nixos-rebuild switch --flake /etc/nixos

# 清理
sudo nix-collect-garbage -d

# 回滚
sudo nixos-rebuild switch --flake /etc/nixos --rollback
```
