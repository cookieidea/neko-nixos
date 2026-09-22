# neko-nixos

个人 NixOS 26.05 + Home Manager 配置，以 flake 为核心，面向单机桌面使用场景。

当前目标主机为 **ATRI**，系统架构为 **x86_64-linux**，默认用户名为 **cookie**。桌面采用 **niri + Noctalia**，登录使用 **Noctalia Greeter**，内核使用 **CachyOS RT-BORE**，GPU 为 AMD。

## 这套配置做什么

这不是一套通用发行版模板，而是一份完整的个人工作站配置。主要覆盖：

- Wayland 桌面：niri、Noctalia、Noctalia Greeter
- 音频与输入法：PipeWire、Bluetooth、fcitx5 + Rime
- 游戏：Steam、Proton-GE、GameMode、Minecraft、MangoHud
- Android / 虚拟化：Waydroid、libvirt、Docker、distrobox
- AMD GPU：Mesa / RADV、OpenCL / ROCm、Ollama、DDC/CI
- 桌面集成：Nautilus、KDE Connect、OBS、XDG portal、AppImage
- 自建软件：通过 `configuration/pkgs` 打包并暴露为 flake package
- Secrets：agenix
- 文件与 dotfiles：由 Home Manager 统一部署
- 安装与升级：`install.sh` 提供新装和现有系统更新流程

仓库更关注**可维护的个人配置**，而不是把每个选项拆成独立文件。目录划分遵循“按职责组织”，不追求文件数量最少，也不追求模块化过度。

## 目录结构

```
.
├── flake.nix                    # flake 入口：inputs / 主机 / 用户 / package / checks
├── flake.lock                   # 所有 flake inputs 的锁定版本
├── install.sh                   # 入口：参数校验 + 环境检查 + 分发
├── scripts/                     # 安装/更新子脚本
│   ├── lib.sh                   #   共用函数（源码准备、用户名、预构建包）
│   ├── bootstrap.sh             #   全新安装（挂载点 → nixos-install）
│   └── update.sh                #   已装系统更新（staging → 原子替换 → switch）
├── LICENSE
├── README.md
│
├── configuration/
│   ├── system.nix               # NixOS 系统入口
│   ├── home.nix                 # Home Manager 用户入口
│   ├── modules.nix              # 系统功能模块入口
│   ├── device.nix               # 硬件相关模块入口
│   │
│   ├── system/                  # 机器通用的系统级配置
│   │   ├── nix.nix              # Nix、缓存、GC、zram
│   │   ├── boot.nix             # 内核、GRUB、休眠、内核参数
│   │   ├── networking.nix       # NetworkManager、DNS、防火墙基础开关
│   │   ├── i18n.nix             # 时区、locale、fcitx5
│   │   ├── audio-bluetooth.nix  # PipeWire、蓝牙、电源管理
│   │   ├── security-users.nix   # polkit、用户和基础用户组
│   │   ├── secrets.nix          # agenix secret 声明
│   │   └── packages.nix         # 系统功能依赖与跨用户工具
│   │
│   ├── device/
│   │   ├── hardware-config.nix  # 本机生成的硬件/文件系统配置
│   │   └── gpu.nix              # AMD GPU、ROCm、Ollama、I2C
│   │
│   ├── modules/                 # 按功能划分的系统模块
│   │   ├── desktop.nix          # niri、Greeter、portal、桌面集成
│   │   ├── flatpak.nix          # Flatpak remote、应用与权限策略
│   │   ├── minecraft.nix        # Minecraft 联机端口与组播路由
│   │   ├── dsh.nix              # dsh Web 端口
│   │   ├── virtualisation.nix   # Steam、libvirt、Waydroid、Docker、distrobox
│   │   └── services/
│   │       ├── openssh.nix
│   │       ├── udisks2.nix
│   │       ├── gvfs.nix
│   │       ├── snapper.nix
│   │       ├── sunshine.nix
│   │       ├── lact-smartd.nix
│   │       └── kdeconnect.nix
│   │
│   ├── home/                    # Home Manager
│   │   ├── lib.nix              # 共享变量、开发环境、wrapper 辅助定义
│   │   ├── session/
│   │   │   ├── default.nix      # 用户身份、PATH、会话变量
│   │   │   └── systemd.nix      # systemd --user 服务
│   │   ├── packages/            # home.packages，按用途分类
│   │   │   ├── default.nix
│   │   │   ├── Terminal/
│   │   │   ├── Develop/
│   │   │   ├── Games/
│   │   │   ├── Entertain/
│   │   │   ├── Desktop/
│   │   │   └── Utility/
│   │   ├── programs.nix         # git、fish、starship、Noctalia 等程序选项
│   │   ├── desktop.nix          # GTK、OBS、KDE Connect、polkit
│   │   ├── xdg.nix              # xdg.configFile / xdg.dataFile
│   │   ├── files/
│   │   │   ├── default.nix      # home.file
│   │   │   └── activation.nix   # 可写种子、helper、激活脚本
│   │   └── dotfiles/            # 实际的 niri / kitty / fish / mpv 等配置
│   │
│   ├── pkgs/                    # 自定义 Nix package / derivation
│   │   ├── default.nix
│   │   ├── desktop/
│   │   ├── tools/networking/
│   │   ├── media/
│   │   ├── games/
│   │   ├── terminal/
│   │   ├── data/fonts/
│   │   └── file-managers/
│   │
│   └── assets/
│       └── grub-theme/
│
├── docs/                        # 使用、安装与维护文档
│   ├── install-btrfs.md
│   ├── dual-boot.md
│   ├── keybindings.md
│   └── notes.md
│
├── secrets/                     # agenix 文件与配置
└── skills/                      # AI agent skills
```

## 配置数据流

系统入口关系很简单：

```
flake.nix
  │
  └── nixosConfigurations.ATRI
       │
       ├── configuration/system.nix
       │    ├── system/
       │    ├── device.nix
       │    └── modules.nix
       │         ├── modules/*.nix
       │         └── modules/services/*.nix
       │
       └── Home Manager
            └── configuration/home.nix
                 ├── home/session
                 ├── home/packages
                 ├── home/programs.nix
                 ├── home/desktop.nix
                 ├── home/xdg.nix
                 └── home/files
```

入口文件只负责聚合。实际配置按职责下沉到对应目录。

新增系统功能时，通常只需要：

1. 在 `configuration/modules/` 新增或选择一个功能文件。
2. 在 `configuration/modules.nix` 加入对应 `imports`。
3. Home Manager 功能则在 `configuration/home.nix` 或现有 Home 模块中加入。

## 安装

完整流程见 [docs/install-btrfs.md](docs/install-btrfs.md)。

### 全新安装

先在 NixOS minimal ISO 中完成分区、挂载，并生成目标机硬件配置：

```bash
nixos-generate-config --root /mnt
```

然后从仓库运行安装脚本：

```bash
git clone https://github.com/cookieidea/neko-nixos.git
cd neko-nixos
sudo bash install.sh cookie /mnt
```

安装脚本会：

- 读取 flake 中的主机名
- 根据参数更新用户名这一处数据源
- 预构建仓库中的自定义 package
- 保留目标机器生成的 `hardware-configuration.nix`
- 将配置部署到 `/mnt/etc/nixos`
- 执行 `nixos-install --flake`
- 提示交互式设置登录密码（`nixos-enter --root /mnt -c 'passwd <用户名>'`）

密码不会被写进配置——安装过程中即时输入，以交互方式设置。
若该步骤失败，可在重启前手动重跑上面那条命令。

### 已安装系统更新

在仓库目录中：

```bash
sudo bash install.sh cookie
```

省略用户名时脚本会提示。

更新采用 staging → `flake check` → `dry-build` → 替换配置源 → `nixos-rebuild switch` 的流程，切换失败时会尝试恢复原来的配置源。

## 手动管理

### 应用配置

```bash
sudo nixos-rebuild switch --flake /etc/nixos#ATRI
```

### 试构建

```bash
sudo nixos-rebuild dry-build --flake /etc/nixos#ATRI
```

### 静态检查

```bash
nix flake check
```

当前 flake 的 check 主要包含 deadnix 检查；格式化器使用 nixfmt。

```bash
nix fmt
```

### 更新 inputs

```bash
nix flake update
sudo nixos-rebuild switch --flake /etc/nixos#ATRI
```

更新前建议先确认 `flake.lock` 的变化范围。

### 单独构建自定义包

```bash
nix build .#niri-sidebar
```

所有 `configuration/pkgs` 中暴露出来的 package 都可以按这个形式单独构建。

### 回滚

```bash
sudo nixos-rebuild switch --rollback
```

也可以在 GRUB 中直接选择旧的 NixOS generation。

### 清理旧代际

```bash
sudo nix-collect-garbage -d
```

仓库本身还配置了周期性的 generation cleanup 与 Nix GC。

## 自定义与维护原则

### 用户名

`flake.nix` 中的：

```nix
username = "cookie";
```

是主要用户名数据源。安装脚本只修改这一处，而不是做全仓库字符串替换。

不过仓库仍包含部分面向本机环境的 dotfiles，例如某些 niri / Noctalia 路径可能带有 `cookie` 或本机 store 路径。换成其他用户名后，应重点复核 `configuration/home/dotfiles`。

### hardware-config

`configuration/device/hardware-config.nix` 是本机硬件与文件系统信息，不应该拿一台机器的 UUID 直接覆盖另一台机器。

全新安装时应优先使用：

```bash
nixos-generate-config --root /mnt
```

安装脚本会保留目标机器生成的硬件配置。

### 自定义软件

自构建程序统一进入 `configuration/pkgs`：

```
configuration/pkgs
   │
   └── default.nix
        └── flake packages
```

简单 derivation 可以保持单文件；依赖复杂、包含资源或多个辅助文件的程序再使用独立目录。

### Flatpak

Flatpak 配置已经独立到：

```
configuration/modules/flatpak.nix
```

这里统一管理 Flathub remote、应用集合以及需要的权限 override。是否生效由 `configuration/modules.nix` 是否引入该模块决定。

## 文档

| 文档 | 内容 |
|------|------|
| [install-btrfs.md](docs/install-btrfs.md) | 从 NixOS ISO 安装、Btrfs 子卷、swap、休眠、快照 |
| [dual-boot.md](docs/dual-boot.md) | Windows + NixOS、UEFI/GPT、GRUB/os-prober |
| [keybindings.md](docs/keybindings.md) | niri + Noctalia 常用快捷键 |
| [notes.md](docs/notes.md) | 维护原则、Home Manager 行为、已知坑点 |

## 致谢

本仓库的部分桌面配置来自或参考以下项目：

- **[ech678/NyxNiri](https://github.com/ech678/NyxNiri)** — GPL-3.0  
  星环菜单以及部分 niri / kitty / fish / Noctalia 配置基于该项目改写。

具体第三方文件与许可证以各自上游仓库为准；本仓库整体许可证见 [LICENSE](LICENSE)。
