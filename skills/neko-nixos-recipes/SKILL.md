---
name: neko-nixos-recipes
description: cookieidea/neko-nixos 主机 ATRI 的实战经验库。Use when working on the neko-nixos flake, packaging self-built packages, fixing NixOS runtime library issues (nix-ld, FHS, SDL/Wayland, java), configuring binary caches/substituters, mirrors, flatpak, agenix secrets, or debugging nixos-rebuild failures on this machine.
---

# neko-nixos 实战经验（ATRI / NixOS 26.05）

本机上下文：flake 在 `/etc/nixos`（root 所有，改动需 sudo；`home.nix`/`flake.nix`/`configuration.nix` 不可直接编辑——先 cp 到 /tmp 改完 parse 校验再 sudo cp 回）。用户 `cookie`。niri + Noctalia 桌面，AMD RX 6600，双系统 GRUB。

## 构建/部署铁律

- **改任何 .nix 后**：`nix-instantiate --parse <file>` 校验 → `sudo nixos-rebuild switch --flake /etc/nixos` → 用户验证 → `sudo git add -A && commit && push` → `cachix push nekobox $(nix path-info ...)` 推自构建闭包
- **nix build 卡 hash**：FOD（fetchurl/fetchFromGitHub）hash 错误信息里有 `got: sha256-...`，抄回去重试；`nix flake prefetch github:owner/repo/rev` 可预取（⚠️ 不带子模块！fetchFromGitHub 需要子模块时必须用构建报错法）
- **`nix flake prefetch` 陷阱**：不带 submodules，hash 与 `fetchSubmodules = true` 不匹配。正确做法：sha256 填全 A 占位，让 `nix build` 报错给 got
- **npm -g 不可用**：nodejs 在只读 store → `.npmrc` 设 `prefix=/home/cookie/.npm-global` + `home.sessionPath` 加 `$HOME/.npm-global/bin`（已配置，2026-09）

## 镜像/缓存（国内环境）

- nixpkgs 源：`git+https://mirrors.nju.edu.cn/git/nixpkgs.git?ref=nixos-26.05&shallow=1`；home-manager：GitCode
- substituters：USTC 优先 + TUNA（TUNA 的 `nix-cache-info` 常年 403，warning 无害）+ nekobox.cachix.org（自建）
- cachix 推送：`cachix push nekobox <store-path>`；nixpkgs 标准包（如 zulu JDK）官方缓存已有，**不要重复推**
- builtins.fetchGit 优于 fetchFromGitHub codeload：tar.gz 哈希环境相关（VM 与宿主机不一致），git 协议按 commit 寻址确定
- maven/gradle：GDK-Proton 的 wine 版本 json 在 installer jar 里（`unzip installer.jar version.json`）

## 打包模式（pkgs/ 目录）

| 模式 | 适用 | 实例 |
|---|---|---|
| wrapType2 AppImage | Electron/预编译 | tabby、splayer-next |
| extract + FHS | 需要系统库闭包 | bedrockboot、purevox |
| 源码 buildRustPackage | 上游有 nix 方案 | axolotl（已弃用换 hmcl） |
| path 输入 bundle | 沙箱内无法联网构建 | astral（build.sh 联网构建 + flake 输入引用） |

- **AppImage 的 FHS**：`appimageTools.extract` + `buildFHSEnv`；wrapType2 的 init 硬编码 extracted 路径，extraInstallCommands 改 AppRun 不生效（purevox 踩坑）
- **buildEnv 冲突**：多个同类包（多个 JDK）顶层同名文件冲突 → `lib.setPrio` 逐级递减（**数值越小优先级越高**，方向别搞反：zulu25=-20 > 21=-15 > 17=-10 > 8=-5）
- **autoPatchelfHook**：预编译 .so 的 RPATH 指向构建机 → 自动修到 store；插件类包记得 `dontWrapQtApps = true`
- **makeWrapper 位置**：jpackage 应用须在**原始二进制路径**包装（真二进制移 .bin + 配套 .bin.cfg），否则应用重写的 autostart 绕过 wrapper（ABDM 托盘坑）
- **HMCL 类外部启动器**：writeShellScriptBin 无 desktop → `runCommand` 补 `share/applications` + `share/icons` 进 profile

## 运行时库问题（核心难点）

- **nix-ld**：跑预编译二进制（游戏/工具）的兜底；`programs.nix-ld.enable = true`，库注入用 **`NIX_LD_LIBRARY_PATH` 前缀**（`--prefix` 语义，shim 在 exec 时拼回）
- **32 位陷阱**：store 里有 multilib 副本（wayland/xkbcommon/libdecor），glibc **静默跳过 ELF class 不符**的候选 → dlopen 失败但 error=null。`makeLibraryPath` 取的是 64 位，别手动指错
- **LD_LIBRARY_PATH 被重置**：外部启动器（HMCL）给子进程设自己的库清单 → 注入失效 → **LD_PRELOAD** 强制全局可见（HMCL libstdc++ 终极解法）
- **LD_PRELOAD 链**：sessionVariables 会被 HM/desktop 继承，但子进程重置 LD_LIBRARY_PATH 时 preload 不受影响
- **SDL3/Wayland**：niri 缺 fifo-v1 → SDL 默认回退 XWayland 锁帧 → `SDL_VIDEO_DRIVER=wayland` 强制原生（Vulkan 自管 vsync）；配套 natives 依赖 libstdc++/libudev 要注入
- **wine/XWayland 相对指针**：xwayland-satellite 的 XGrabPointer/EnterNotify 路径有 bug（上游 #482），wine 游戏（UWP/GDK）输入失效无解，等上游重写
- **dlopen 报错 error=null**（LWJGL/Minecraft）：要么缺依赖（ldd 查），要么 .so 无执行权限（HMCL 每次重解压会重置，需 chmod +x）

## 桌面/输入

- niri 配置在 dotfiles/config/niri/*.kdl（HM 管理）；**Alt+Tab 默认绑了启动器**，窗口切换是 recent-windows 块
- 熄屏/挂起：Noctalia config.toml `[idle]` 行为链（lock 300s / screen-off 360s / lock_and_suspend 900s）
- HMCL Java 列表：扫 `~/.jdks`（home.file 软链各 zulu）
- 组播路由：cachyos 内核需显式 `ip route add 224.0.0.0/4 dev lo`（MC 局域网联机）

## 系统维护

- **flatpak-repo 依赖 DNS 就绪**：`NetworkManager-wait-online` 别禁用（禁用后开机 flathub 解析失败 → degraded）
- **snapper/journal/coredump 定期清**：`snapper -c root cleanup timeline`、`journalctl --vacuum-time=1week`、`/var/lib/systemd/coredump` 手动删
- **nix profile 残留**：`nix-collect-garbage -d`（注意 booted-system 钉住的旧路径要重启才释放）
- **lact fd 泄漏**：显示器热插拔事件积累 EMFILE → GPU 控制失效，重启 lactd 恢复
- **flatpak 权限**：QQ/微信要 `--nosocket=fallback-x11 --socket=x11`，托盘应用要 `--socket=session-bus`

## agenix（2026-10 配置）

- 私钥 `/etc/age/key`（root 600，**不入 git**，重装需备份）；公钥在 `secrets.nix`
- **agenix CLI 的 EDITOR 交互在无终端环境不可用**（cp 方式加密空文件陷阱）→ 直接 `age -r <公钥> -o secrets/foo.age <明文>` 等效
- 部署：`age.secrets.<name>.file = ./secrets/<name>.age` → `/run/agenix/<name>`（root 600，tmpfs）
- 改密钥后要 `sudo nix run github:ryantm/agenix -- -r`（rekey）或手动重加密

## Git 工作流

- 提交信息中文，格式 `类型(范围): 描述`（feat/fix/chore/revert）
- **错误提交撤回**：内容级 revert 会留两个提交；彻底抹除用 `git reset --hard <good> + push --force-with-lease`（先确认工作树与目标提交零 diff）
- fork 的实验 patch 没验证过不要推
