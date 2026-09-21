# neko-nixos

个人 NixOS 26.05 + Home Manager 配置（flake）。

- 主机 `ATRI` / 用户 `cookie`
- 桌面 **niri** + **Noctalia**，登录 **greetd**（Noctalia Greeter）
- 内核 **CachyOS RT-BORE**，AMD RX 6600，双系统（Windows + GRUB）

## 目录结构

```
.
├── flake.nix                    # 入口：inputs / hostname / username / nixosConfigurations
├── flake.lock                   # inputs 锁文件
├── install.sh                   # 安装与更新脚本
├── LICENSE                      # GPL-3.0
├── README.md
│
├── configuration/               # 所有声明式配置
│   ├── system.nix               # 系统配置聚合入口
│   ├── home.nix                  # Home Manager 聚合入口
│   ├── modules.nix               # 系统功能模块聚合入口
│   ├── device.nix                # 硬件配置聚合入口
│   │
│   ├── system/                  # ── 纯系统级配置
│   │   ├── nix.nix              # Nix 守护进程、二进制缓存、垃圾回收、zram
│   │   ├── boot.nix             # 内核、引导（GRUB/双系统）、休眠、内核参数
│   │   ├── networking.nix       # 主机名、防火墙开关、DNS（端口归各功能模块）
│   │   ├── i18n.nix             # 时区、locale、输入法（fcitx5 + rime-ice）
│   │   ├── audio-bluetooth.nix  # 音频、蓝牙、电源管理
│   │   ├── security-users.nix   # polkit 与用户账户
│   │   └── secrets.nix          # agenix 加密 secrets 声明
│   │
│   ├── device/                 # ── 硬件特定
│   │   ├── hardware-config.nix  # nixos-generate-config 产物（勿手改）
│   │   └── gpu.nix              # AMD GPU / ROCm
│   │
│   ├── modules/                 # ── 可复用 NixOS 模块
│   │   ├── desktop.nix           # niri、Noctalia Greeter、XDG 门户、字体、系统包
│   │   ├── flatpak.nix           # Flatpak remote、应用与权限
│   │   ├── minecraft.nix         # MC 联机端口 + 组播路由
│   │   ├── dsh.nix               # dsh web 端口
│   │   ├── services/
│   │   │   ├── openssh.nix      # SSH
│   │   │   ├── udisks2.nix      # USB 自动挂载
│   │   │   ├── gvfs.nix         # 虚拟文件系统（须系统层，polkit 用）
│   │   │   ├── snapper.nix      # btrfs 快照
│   │   │   ├── sunshine.nix     # Moonlight 串流
│   │   │   └── lact-smartd.nix  # 显卡控制 + 磁盘健康
│   │   └── virtualisation.nix    # Steam、libvirtd、Waydroid、Docker
│   │
│   ├── home/                    # ── Home Manager 用户配置
│   │   ├── lib.nix              # 共用 let 绑定（经 extraSpecialArgs 注入为 hmLib）
│   │   ├── session/             # 会话变量 + systemd user 服务
│   │   │   ├── default.nix      # PATH / PYTHONPATH / GIO / JAVA_HOME…
│   │   │   └── systemd.nix      # 随机壁纸等 user 服务
│   │   ├── packages/            # home.packages，按用途分类
│   │   │   ├── default.nix      # 聚合入口
│   │   │   ├── Terminal/        # shell、提示符、TUI、终端模拟器
│   │   │   ├── Develop/         # 编辑器、JDK、语言工具链、Git、AI agent
│   │   │   ├── Games/           # 启动器、性能监控、兼容层
│   │   │   ├── Entertain/       # 播放器、图像、办公、下载、浏览器
│   │   │   ├── Desktop/         # niri、主题图标、文件管理器、剪贴板
│   │   │   └── Utility/         # 系统信息、磁盘、代理、自建程序
│   │   ├── programs.nix          # HM 程序选项（git/starship/fish/noctalia…）
│   │   ├── desktop.nix           # polkit、GTK 主题、KDE Connect、OBS
│   │   ├── xdg.nix               # xdg.configFile / xdg.dataFile 部署
│   │   ├── files/               # home.file 部署
│   │   │   ├── default.nix      # JDK 链、图标、desktop 入口、镜像源
│   │   │   └── activation.nix   # activation 脚本（Noctalia seed、壁纸、mark-shot helper）
│   │   └── dotfiles/            # 被上面各模块 source 引用的实际配置文件
│   │       ├── config/          # → ~/.config（niri、noctalia、fish、kitty…）
│   │       ├── local/           # → ~/.local（bin 脚本、图标、fcitx5 主题）
│   │       ├── mpv/             # mpv（脚本、shader、VapourSynth）
│   │       ├── icons/           # hicolor 图标兜底
│   │       ├── Pictures/        # 壁纸种子
│   │       ├── scripts/         # 独立脚本
│   │       └── avatar.png       # → ~/.face
│   │
│   ├── pkgs/                    # ── 自构建派生（nix build .#<name>）
│   │   ├── default.nix          # 聚合，暴露为 flake packages
│   │   ├── desktop/             # niri-sidebar、pins、shorin-contrib、nyxniri-scratch-menu
│   │   ├── tools/networking/    # astral、ab-download-manager
│   │   ├── media/               # splayer-next、obs-vdoninja、purevox、vs-plugins
│   │   ├── games/               # bedrockboot
│   │   ├── terminal/            # tabby
│   │   ├── data/fonts/          # harmonyos-sans-sc
│   │   └── file-managers/       # nautilus-extensions
│   │
│   └── assets/grub-theme/       # GRUB 主题（aris/Alice）
│
├── docs/                        # 文档
│   ├── install-btrfs.md         # 实体机安装（btrfs + GRUB/UEFI + 休眠 + snapper）
│   ├── dual-boot.md             # Windows + NixOS 双系统
│   ├── keybindings.md           # 快捷键速查
│   └── notes.md                 # 踩坑与非显而易见的约束（改配置前建议先看）
│
├── secrets/                     # agenix
│   ├── secrets.nix              # 收件人公钥清单
│   └── mark-shot-sensitive.age  # 加密内容
│
└── skills/                      # AI agent skills（opencode 扫描）
```

## 数据流

```
flake.nix
  └─ nixosConfigurations.ATRI
       ├─ configuration/system.nix   → system/ + device/ + modules/
       └─ configuration/home.nix     → home/（Home Manager）
```

`configuration/*.nix` 中的入口文件负责聚合；实际内容都在对应目录里。
新增模块时在对应聚合文件加一行 `imports` 即可。

## 常用命令

```bash
# 应用配置
sudo nixos-rebuild switch --flake /etc/nixos

# 先试构建不切换
sudo nixos-rebuild dry-build --flake /etc/nixos

# 更新依赖
nix flake update && sudo nixos-rebuild switch --flake /etc/nixos

# 单独构建自构建包
nix build .#niri-sidebar

# 清理
sudo nix-collect-garbage -d

# 回滚
sudo nixos-rebuild switch --flake /etc/nixos --rollback
```

## 致谢

本仓库的桌面配置派生自以下项目，版权归各原作者所有：

- **[ech678/NyxNiri](https://github.com/ech678/NyxNiri)** — GPL-3.0
  星环菜单（`niri-scratch-menu.py`）及 niri / kitty / fish / Noctalia 的
  部分配置改写自该项目，已针对 NixOS 适配。上游版权归原作者所有。
- **[SHORiN-KiWATA/shorin-contrib](https://github.com/SHORiN-KiWATA/shorin-contrib)**
  — 无明确许可证声明；`configuration/pkgs/desktop/shorin-contrib` 打包其通用脚本子集，
  版权归原作者所有。

完整许可证见 [LICENSE](LICENSE)。
