# Shorin Arch Setup → Home Manager user config
# 包来源：
#   common-applist.txt          (GNOME 基线)
#   kde-applist.txt             (shell/终端 + KDE 应用)
#   kde-common-applist.txt      (KDE 系统工具/磁盘/媒体)
# 桌面：niri (Wayland 滚动平铺 compositor) + Noctalia (桌面 shell)
# 编辑器：CookNixvim（Youthdreamer/CookNixvim，模块化 Neovim 配置框架产物，
#        基于 nix-community/nixvim；用其 flake 构建的 nvim 替代裸 nixvim 配置）
# AUR-only 与 nixpkgs 差异见底部注释。

{ config, pkgs, lib, desktop, username, cooknixvim, opencode, bili-danmaku-tui, selfPackages, ... }:

{
  imports = [
    # Noctalia 改用 flake 包（见 home.packages）+ settings.json（见 xdg.configFile），
    # 不再加载它的 HM 模块，避免 programs.noctalia.settings 和手写文件冲突。
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.05";

  # kitty 终端 terminfo：kitty 设 TERM=xterm-kitty，NixOS 上 ncurses 找不到该
  # terminfo 文件 → nvim 等 ncurses 应用吐转义码乱码（^[[?69…）。指向 kitty 包自带的
  # share/terminfo 即可（xterm 等其余条目用 ncurses 内建 fallback）。
  # ~/.local/bin 进 PATH：shorin-screenrec-menu / quicksave / quickload 等
  # 私有脚本部署在这里（binds.kdl 裸命令调用靠 PATH 查找）。
  home.sessionPath = [ "$HOME/.local/bin" ];
  home.sessionVariables = {
    TERMINFO_DIRS = "${pkgs.kitty}/share/terminfo";
    # ABDM 托盘兜底：ABDM 应用会把自己的 autostart 重写为 bin/ABDownloadManager.bin
    # （/proc/self/exe 检测实际二进制）→ 绕过 makeWrapper → 无 systemdLibs →
    # ComposeNativeTray 的 libLinuxTray.so 解析不到 libsystemd.so.0 → 托盘消失。
    # 会话级 LD_LIBRARY_PATH 让任何入口（autostart/菜单/浏览器）都带该路径。
    # 注意：sessionVariables 是覆盖语义，须保留用户会话原有的
    # pipewire-jack 路径（JACK 音频应用依赖）。
    LD_LIBRARY_PATH = "${pkgs.systemdLibs}/lib:/nix/store/zcqp398mxlw62jl02sx0rsc7gvcl1qhc-pipewire-1.6.6-jack/lib";
  };

  # ============================================================
  #  软件包（home.packages）
  #  左 = Nixpkgs 属性名，括号内 = 原 Arch 包名
  # ============================================================
  home.packages = with pkgs; [
    # --- Standard (common-applist.txt) ---
    gdu                                       # gdu
    baobab                                    # baobab
    file                                      # file 命令（random-anime-wallpaper-noctalia 壁纸脚本依赖）
    mission-center                            # mission-center
    gnome-font-viewer                         # gnome-font-viewer
    google-chrome                             # google-chrome (替代 firefox; unfree 已开启)
    transmission_4-gtk                        # transmission_4-gtk（26.05 移除 transmission_3-gtk / transmission-gtk）
    localsend                                 # localsend
    gnome-calendar                            # gnome-calendar
    gnome-clocks                              # gnome-clocks
    lutris                                    # lutris
    steam                                     # steam (系统服务在 configuration.nix)
    mangohud                                  # mangohud
    mpv                                       # mpv
    opencc                                    # opencc（mpv opencc.lua 字幕繁简转换）
    p7zip                                     # 7z（mpv auto_sub_fonts_dir 解压字幕字体包）
    ffmpeg                                    # ffmpeg（mpv opencc.lua 提取字幕轨道）
    yt-dlp                                    # yt-dlp（mpv 在线视频下载/播放）
    obs-studio                                # obs-studio
    kdePackages.kdenlive                         # kdenlive（KDE 视频剪辑；26.05 属 kdePackages 不在顶层）
    kdePackages.kcalc                            # kcalc（KDE 计算器；26.05 属 kdePackages，gear 区）
    upscaler                                  # upscaler
    yazi                                      # yazi
    # flatseal 已在 nixpkgs 26.05 移除 → 需要时用 flatpak 装：
    #   flatpak install flathub com.github.tchx84.Flatseal
    pavucontrol                               # pavucontrol
    mousepad                                  # mousepad
    easyeffects                               # easyeffects
    libreoffice                               # libreoffice（办公套件；默认 27 种语言含 zh-CN。⚠️ 不要对它 .override { langs=... }——pkgs.libreoffice 是带 unwrapped 的 wrapper，直接 override 会返回函数导致 home.packages 类型错误；真要减语言包需 override unwrapped）
    # 日文输入法 fcitx5-mozc 已移除；输入法本体由 i18n.inputMethod 系统级配置
    # rime-wubi 已在 26.05 移除 → 中文输入走 rime + rime-ice（雾凇，见 configuration.nix）

    # --- Shell & Terminal (kde-applist.txt) ---
    fish                                      # fish
    starship                                  # starship
    eza                                       # eza
    zoxide                                    # zoxide
    fastfetch                                 # fastfetch
    imagemagick                               # imagemagick
    jq                                        # jq
    timg                                      # timg
    bat                                       # bat
    btop                                      # btop（DE 无关，常驻）
    ripgrep                                   # ripgrep（原 LazyVim/neovim 生态搜索工具）
    fd                                        # fd（find 替代，neovim/telescope 生态常用）

    # --- 编辑器（替代 visual-studio-code-bin，AUR）---
    vscodium                                  # visual-studio-code-bin → 用 vscodium 去遥测

    # --- 已确认在 nixpkgs 26.05 存在的原 AUR 包 ---
    flclash                                   # flclash（代理 GUI）
    # discord —— 改走 Flatpak（nixpkgs 构建需从 stable.dl.discordapp.net 下载，国内不可达）
    ayugram-desktop                           # ayugram-desktop（Telegram 第三方客户端，unfree）
    # wechat / qq —— nixpkgs 26.05 的 src 分别走 web.archive.org（429 限流）与腾讯 CDN
    # 旧版本链接（404），且 wechat 的 src 深埋在 appimageTools.extract 内部无法 override，
    # 故改走 Flatpak（flathub 官方维护），由 configuration.nix 的 flatpak-repo 服务启动时自动安装。
    gearlever                                 # gearlever（管理 AppImage/flatpak）
    lsfg-vk                                   # lsfg-vk（FSR 帧生成 vulkan 层）
    protonplus                                # protonplus（Proton 管理）
    mangojuice                                # mangojuice（GTK 文件管理器）

    # --- 游戏 / 影音客户端（用户新增，已在 nixpkgs 26.05 核实存在）---
    # prismlauncher 已替换为 Axolotl（selfPackages，AppImage+FHS；见 pkgs/axolotl）
    kazumi                                     # kazumi（B 站第三方客户端，Flutter；替代构建失败的 animeko）
    lunar-client                               # lunar-client（Minecraft 客户端，unfree；26.05 由 lunarclient 改名）
    taterclient-ddnet                         # taterclient-ddnet（DDNet Teeworlds 修改版客户端，Apache-2.0）

    # --- 原清单里有、之前漏加的 ---
    virt-manager                              # virt-manager（KVM 虚拟机 GUI，libvirtd 已在 configuration.nix 开）
    virt-viewer                               # virt-viewer（QEMU/SPICE 客户端，virt-manager 配套）
    gnome-disk-utility                        # gnome-disk-utility（磁盘管理 GUI，mainProgram=gnome-disks；原 kde-common-applist）
    # ksystemlog —— nixpkgs 26.05 已移除（KDE 上游停止维护，KDE Gear 不再打包）；
    # 系统日志用 journalctl / journalctl -f，或 GNOME 系可用 flatpak 的 org.gnome.Logs
    video-downloader                          # video-downloader（yt-dlp 图形前端）

    # --- niri 桌面生态依赖（config.kdl / binds.kdl 里用到的程序）---
    niri                                       # niri 合成器本体（ly 直接调，也放这里保持 PATH 一致）
    kitty                                      # 终端（binds: Mod+Return / Mod+T / Mod+Slash / opencode）
    fuzzel                                     # 启动器兜底（binds: Mod+Z 失败回退 fuzzel）
    # 系统图标主题（noctalia 应用启动器/GTK 应用图标解析依赖 freedesktop 主题）
    adwaita-icon-theme                          # Adwaita 基底图标（默认 freedesktop 标准）
    papirus-icon-theme                          # Papirus（丰富的应用图标，覆盖 Steam/Flatpak 等）
    hicolor-icon-theme                          # hicolor 兜底主题（Flatpak 应用图标/桌面文件图标扫描依赖）
    thunar                                     # 文件管理器（binds: Mod+E 优先）
    nautilus                                    # nautilus（GNOME Files，binds: Mod+Alt+E / Mod+E 兜底）
    # ── 原 04k 脚本的文件管理器生态（全量迁移）──
    gnome-keyring                             # 密钥环（登录钥匙串，nautilus/远程/应用依赖）
    gvfs                                      # 虚拟文件系统（smb/mtp/gphoto2 挂载）
    ffmpegthumbnailer                         # 视频缩略图（thunar/nautilus）
    file-roller                               # 归档 GUI（= ark 的 GNOME 版）
    thunar-archive-plugin                     # thunar 归档插件
    thunar-volman                             # thunar 卷管理
    webp-pixbuf-loader                        # webp 缩略图
    poppler                                   # PDF 缩略图（libpoppler-glib）
    gst_all_1.gst-plugins-base                # GStreamer 基础插件
    gst_all_1.gst-plugins-good                # GStreamer 常规插件
    gst_all_1.gst-libav                       # GStreamer libav（解码）
    usbutils                                  # lsusb
    pciutils                                  # lspci
    font-awesome                              # Font Awesome 图标字体（原 otf-font-awesome）
    satty                                      # 截图标注（binds: Mod+Shift+S）
    cliphist                                   # 剪贴板历史（noctalia config.toml 的 clipboard watch 命令）
    wl-clipboard                               # wl-paste / wl-copy（剪贴板 + 截图管道）
    libnotify                                 # notify-send（niri-pick / niri-force-kill-window / screenshot-sound.sh 的通知依赖）
    xsettingsd                                 # GTK 主题/字体经 XSETTINGS 注入应用（niri 无 DE 时需要）
    xprop                                       # xprop（26.05 起 xorg 属性集弃用，xorg.xprop 改为顶层 xprop；niri-force-kill-window 依赖）
    gpu-screen-recorder                        # 录屏（shorin-screenrec-menu Mod+F3 用，noctalia-shell 也依赖）
    btrfs-assistant                            # btrfs 快照管理 CLI（quickload Mod+F8 的回滚后端）
    # ── 原 02b/99-apps 补充 ──
    power-profiles-daemon                      # 电源模式（平衡/省电/性能）
    cmatrix lolcat sl                          # 彩蛋趣味命令（原 02b 安装）
    wineWow64Packages.stable                   # wine（原 99-apps 的 wine 全家；26.05 弃用 wineWowPackages）
    # bottles（Wine 容器管理 GUI；FHS 封装含 32 位支持）
    # removeWarningPopup=true：Bottles 官方只支持 Flatpak 沙箱，nixpkgs FHS 封装
    # 启动会弹 "Unsupported Environment" 警告，官方提供此 override 关闭。
    # （bottles 是可 override 的派生参数，非 wrapper，不会像 libreoffice 那样返回函数）
    (bottles.override { removeWarningPopup = true; })

    # ── 全量脚本审查补漏（04j-minimal-niri / 04k-noctalia 核对结果）──
    matugen                                    # 主题生成器（random-anime-wallpaper-noctalia 与 noctalia-shell 模板直接调用）
    mpvpaper                                   # 视频壁纸（mpv 渲染 wlr-layer-shell，niri 启动项播放 hatsune-miku.mp4）
    imv                                        # 图片查看器（mimeapps.list 的 image/* 默认打开器）
    kdePackages.breeze                           # 光标主题 Breeze_Cursors（cursor.kdl 指定；breeze 包含光标，非独立 breeze-cursors 属性）
    xhost                                      # XWayland 授权（config.kdl spawn-at-startup "xhost"；26.05 xorg 包集移到顶层）
    pipewire                                   # 提供 pw-play（截图/强杀音效脚本依赖；服务已在 configuration.nix 开启）
    qt6Packages.fcitx5-configtool              # fcitx5 配置 GUI（原 fcitx5-configtool；26.05 移到 qt6Packages）
    tumbler                                    # thunar 缩略图后端（图片/文档缩略图，原 04j/04k 必装）
    xdg-terminal-exec                          # 终端选择器（xdg-open 按 xdg-terminals.list 选 kitty）
    adw-gtk3                                     # libadwaita 主题 adw-gtk3-dark（nixpkgs 属性名 adw-gtk3，非 adw-gtk-theme）
    nwg-look                                   # GTK 主题设置（原脚本 + dotfiles 已部署 nwg-look/gsettings）
    libgsf                                     # ODF/Office 文档缩略图（thunar，原 FM_PKGS2）
    icoextract                                 # Windows exe/ico 图标缩略图（原 FM_PKGS1）
    cava                                       # 音频可视化（终端彩蛋，原 04k TERM_PKGS）
  ] ++ [

  # opencode（AI 编程 Agent）走 flake 装，拿最新版（不在 nixpkgs 核心）。
  # noctalia-shell（桌面 shell，quickshell 配置 + qs 封装）直接用 nixpkgs 自带的
  # `noctalia-shell` 包，不再用独立的 noctalia v4 应用（见文末注释）。

    opencode.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.noctalia-shell
  ]

  # 自构建程序（flake 包，见 ./pkgs；对应原 Arch 的 AUR `-git` / 私有仓库）
  ++ [
    selfPackages.niri-sidebar     # niri-sidebar-git
    selfPackages.pins             # pins-git
    selfPackages.pywalfox         # python-pywalfox
    selfPackages.shorin-contrib   # shorin-contrib-git
    selfPackages.proton-wrapper   # shorin-proton-wrapper-git
    selfPackages.splayer-next     # SPlayer-Dev/SPlayer-Next（非 nixpkgs 的 splayer）
    selfPackages.startlive        # StartLive（B 站推流地址获取，PySide6 GUI；自构建）
    selfPackages.ab-download-manager  # AB Download Manager（多线程下载器，Compose Desktop；自构建）
    selfPackages.tabby-terminal       # Tabby 终端（eugeny/tabby，Electron；自构建，nixpkgs 的 tabby 是 TabbyML AI 助手）
    selfPackages.purevox              # PureVox（实时 AI 音频降噪，AppImage 捆绑内嵌 Python，PipeWire 直用）
    selfPackages.bedrockboot          # BedrockBoot（MC 基岩版启动器，Avalonia；AppImage+FHS）
    selfPackages.axolotl              # Axolotl（MC Java 版启动器，替代 Prism/HMCL；AppImage+FHS）
    # 走 flake 输入的包（不在 nixpkgs 核心，直接引用其 flake 构建产物）
    bili-danmaku-tui.packages.${pkgs.stdenv.hostPlatform.system}.default  # B 站直播间弹幕 TUI
    # CookNixvim：模块化 Neovim 配置（基于 nix-community/nixvim 的完整配置），
    # 产物 packages.<sys>.default 提供 nvim 命令（替代原 programs.nixvim 简易配置）
    cooknixvim.packages.${pkgs.stdenv.hostPlatform.system}.default        # nvim（CookNixvim）
  ];

  # ============================================================
  #  Home Manager 托管的程序（自动写 dotfiles，替代手写配置）
  # ============================================================
  programs = {
    git = {
      enable = true;
      settings = {
        user.name = "cookieidea";
        user.email = "jhbhyvv@outlook.com";
        # /etc/nixos 仓库是 root 所有，普通用户 git 操作会报 dubious ownership；
        # ~/.config/git/config 是只读 store 链接没法 --add，必须写进托管配置
        safe.directory = "/etc/nixos";
      };
    };
    starship.enable = true;       # starship
    zoxide.enable = true;         # zoxide
    eza.enable = true;            # eza
    bat.enable = true;            # bat
    fzf.enable = true;            # fzf（脚本里也装了）
    fish = {
      enable = true;
    };

    # ── niri：Wayland 滚动平铺 compositor ────────────────
    # 配置改用 dotfiles/niri/*.kdl，通过文件末尾的 xdg.configFile 部署，
    # 不再用 programs.niri.settings 生成，以免和手写的拆分 kdl 冲突。
  };

  # ============================================================
  #  systemd user 服务（登录图形会话后自启）
  # ============================================================
  # ⚠️ ABDM 不自启在此定义（原 systemd.user.services.abdm 已移除）：
  # ABDM 应用自身有开机自启机制（设置 autoStartOnBoot=true 默认），启动时会
  # 自动写 ~/.config/autostart/com.abdownloadmanager.desktop（Exec 指向
  # bin/ABDownloadManager.bin --background）。若再配 systemd 服务会双重启动，
  # 第二次实例经单实例转发唤醒聚焦第一个实例的窗口 → 开机弹窗。
  # 托盘环境问题由下方 xdg.configFile 的 systemd drop-in 兜底。

  # 开机随机壁纸（noctalia IPC）：等 noctalia-shell 就绪后跑一次下载脚本
  systemd.user.services.noctalia-wallpaper = {
    Unit = {
      Description = "Set random anime wallpaper via noctalia";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "%h/.config/scripts/noctalia-wallpaper-autostart.sh";
      TimeoutStartSec = 300;
      Restart = "on-failure";
      RestartSec = 15;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  #  运行方式：nixpkgs 自带的 `noctalia-shell`（quickshell 配置 + qs 封装），
  #  由 config.kdl 的 `spawn-sh-at-startup "noctalia-shell"` 拉起。
  #  下方 ~/.config/noctalia/*.json 等 v4 配置现已不再被 noctalia-shell 读取
  #  （那是独立 noctalia v4 应用的配置，已弃用）；保留仅作参考，可随时删除。
  #  IPC 绑定见 binds.kdl：统一用 `noctalia-shell ipc call ...`（见文末说明）。
  # ============================================================

  # ============================================================
  #  dotfiles（对应原仓库 noctalia-dotfiles 的 rice 配置）
  #  通过 xdg.configFile 部署到 ~/.config/
  # ============================================================

  xdg.configFile = {
    # ABDM 托盘兜底（systemd user unit drop-in）：ABDM 应用会把自己的
    # autostart 重写为 bin/ABDownloadManager.bin（/proc/self/exe）→ 绕过
    # makeWrapper → 无 systemdLibs → ComposeNativeTray 的 libLinuxTray.so
    # 解析不到 libsystemd.so.0 → 开机自启的 ABDM 无托盘。
    # systemd user 服务不经过 login shell（hm-session-vars.sh 不生效），
    # 且本机 environment.d generator 缺失 → 用 unit drop-in 最可靠。
    # ExecStartPre 补建 ~/.abdm/system/log/（ABDM 启动要写 crash.log，
    # 目录缺失会 FileNotFoundException 崩溃退出，开机时序下不自动创建）。
    # 注：LD_LIBRARY_PATH 为覆盖语义，保留 pipewire-jack 路径。
    "systemd/user/app-com.abdownloadmanager@autostart.service.d/10-abdm-tray.conf".text = ''
      [Service]
      Environment=LD_LIBRARY_PATH=${pkgs.systemdLibs}/lib:/nix/store/zcqp398mxlw62jl02sx0rsc7gvcl1qhc-pipewire-1.6.6-jack/lib
      ExecStartPre=${pkgs.coreutils}/bin/mkdir -p %h/.abdm/system/log
    '';
    # ── noctalia-shell 4.7.6 用户配置（quickshell 惯例路径）──
    # 完整默认 settings（取自官方 Assets/settings-default.json）只改
    # wallpaper.enabled=false + 默认 disableWallpaper=true → 壁纸组件不渲染，
    # mpvpaper 独占背景层。完整结构部署避免最小化 JSON 导致 QML 崩溃。
    "quickshell/noctalia/settings.json".source = ./dotfiles/config/noctalia/settings.json;
    "MangoHud/MangoHud.conf".source = ./dotfiles/config/MangoHud/MangoHud.conf;
    "Thunar/accels.scm".source = ./dotfiles/config/Thunar/accels.scm;
    "Thunar/uca.xml".source = ./dotfiles/config/Thunar/uca.xml;
    "fcitx5/conf/cached_layouts".source = ./dotfiles/config/fcitx5/conf/cached_layouts;
    "fcitx5/conf/chttrans.conf".source = ./dotfiles/config/fcitx5/conf/chttrans.conf;
    "fcitx5/conf/classicui.conf".source = ./dotfiles/config/fcitx5/conf/classicui.conf;
    "fcitx5/conf/notifications.conf".source = ./dotfiles/config/fcitx5/conf/notifications.conf;
    "fcitx5/conf/pinyin.conf".source = ./dotfiles/config/fcitx5/conf/pinyin.conf;
    "fcitx5/conf/punctuation.conf".source = ./dotfiles/config/fcitx5/conf/punctuation.conf;
    "fcitx5/config".source = ./dotfiles/config/fcitx5/config;
    "fcitx5/profile".source = ./dotfiles/config/fcitx5/profile;
    "fish/conf.d/shorin.fish".source = ./dotfiles/config/fish/conf.d/shorin.fish;
    # ⚠️ fish/fish_variables 不能部署成 store 只读符号链接——fish 运行时写通用变量会
    #   报 "无法创建临时文件 /nix/store/... (os error 30 EROFS)"。让 fish 自己生成
    #   （原文件只是默认空壳，无重要变量）。
    "fish/functions/apt.fish".source = ./dotfiles/config/fish/functions/apt.fish;
    "fish/functions/f.fish".source = ./dotfiles/config/fish/functions/f.fish;
    "fish/functions/fwatch.fish".source = ./dotfiles/config/fish/functions/fwatch.fish;
    "fontconfig/fonts.conf".source = ./dotfiles/config/fontconfig/fonts.conf;
    "fuzzel/fuzzel.ini".source = ./dotfiles/config/fuzzel/fuzzel.ini;
    # fuzzel/themes/noctalia 由 noctalia-shell 模板系统生成（matugen 写色），不可 home-manager 只读部署
    "gtk-3.0/bookmarks".source = ./dotfiles/config/gtk-3.0/bookmarks;
    "gtk-3.0/gtk.css".source = ./dotfiles/config/gtk-3.0/gtk.css;
    # ⚠️ gtk-3.0/noctalia.css 不部署：由 Noctalia 配色模板生成（template-processor
    # 写色）。若部署成只读 symlink → 模板写入 PermissionError → "配色方案模板
    # 处理失败"（toast.theming-processor-failed）。生成失败时才临时部署静态快照。
    # gtk-3.0/settings.ini 不部署：由下方 gtk 模块（home-manager）全权写入，避免只读 symlink 冲突
    "gtk-4.0/gtk.css".source = ./dotfiles/config/gtk-4.0/gtk.css;
    # gtk-4.0/noctalia.css 同上：由 Noctalia 模板生成，不部署只读版本。
    # gtk-4.0/settings.ini 同上，由 gtk 模块写入
    "kitty/current-theme.conf".source = ./dotfiles/config/kitty/current-theme.conf;
    "kitty/kitty.conf".source = ./dotfiles/config/kitty/kitty.conf;
    "kitty/themes/kitty.conf".source = ./dotfiles/config/kitty/themes/kitty.conf;
    # kitty/themes/noctalia.conf 由 noctalia 模板生成（matugen 写色），不部署
    "mimeapps.list".source = ./dotfiles/config/mimeapps.list;
    # ── mpv（从 Windows mpv.lite portable_config 迁移；Linux 适配：去 nvidia、
    #    opencc 路径改 ~/.config/mpv、TMPDIR、mkdir -p；并入原 hwdec=auto-safe）──
    # 目录级（scripts/uosc 等只读内容）用目录 symlink；文件级 mpv 只读文件逐条链接，
    # ~/.config/mpv 本体是真实目录（mpv 写 watch_later 需要）。
    "mpv/mpv.conf".source = ./dotfiles/mpv/mpv.conf;
    "mpv/input.conf".source = ./dotfiles/mpv/input.conf;
    "mpv/contextmenu.conf".source = ./dotfiles/mpv/contextmenu.conf;
    "mpv/t2s.json".source = ./dotfiles/mpv/t2s.json;
    "mpv/s2t.json".source = ./dotfiles/mpv/s2t.json;
    "mpv/script-opts/check_settings.conf".source = ./dotfiles/mpv/script-opts/check_settings.conf;
    "mpv/script-opts/input_plus.conf".source = ./dotfiles/mpv/script-opts/input_plus.conf;
    "mpv/script-opts/playlist_osd.conf".source = ./dotfiles/mpv/script-opts/playlist_osd.conf;
    "mpv/script-opts/thumbfast.conf".source = ./dotfiles/mpv/script-opts/thumbfast.conf;
    "mpv/script-opts/uosc.conf".source = ./dotfiles/mpv/script-opts/uosc.conf;
    "mpv/script-opts/uosc_danmaku.conf".source = ./dotfiles/mpv/script-opts/uosc_danmaku.conf;
    "mpv/scripts/auto_itm.lua".source = ./dotfiles/mpv/scripts/auto_itm.lua;
    "mpv/scripts/auto_sub_fonts_dir.lua".source = ./dotfiles/mpv/scripts/auto_sub_fonts_dir.lua;
    "mpv/scripts/check_settings.lua".source = ./dotfiles/mpv/scripts/check_settings.lua;
    "mpv/scripts/contextmenu.lua".source = ./dotfiles/mpv/scripts/contextmenu.lua;
    "mpv/scripts/input_plus.lua".source = ./dotfiles/mpv/scripts/input_plus.lua;
    "mpv/scripts/opencc.lua".source = ./dotfiles/mpv/scripts/opencc.lua;
    "mpv/scripts/playlist_osd.lua".source = ./dotfiles/mpv/scripts/playlist_osd.lua;
    "mpv/scripts/shaders.lua".source = ./dotfiles/mpv/scripts/shaders.lua;
    "mpv/scripts/ssdm.lua".source = ./dotfiles/mpv/scripts/ssdm.lua;
    "mpv/scripts/thumbfast.lua".source = ./dotfiles/mpv/scripts/thumbfast.lua;
    "mpv/scripts/vapoursynth.lua".source = ./dotfiles/mpv/scripts/vapoursynth.lua;
    "mpv/scripts/uosc".source = ./dotfiles/mpv/scripts/uosc;
    "mpv/scripts/uosc_danmaku".source = ./dotfiles/mpv/scripts/uosc_danmaku;
    "mpv/shaders".source = ./dotfiles/mpv/shaders;
    "mpv/vs".source = ./dotfiles/mpv/vs;
    "mpv/fonts".source = ./dotfiles/mpv/fonts;
    "niri/animations.kdl".source = ./dotfiles/config/niri/animations.kdl;
    # binds.kdl 实体机上存在非 HM 管理的旧文件（此前手动 sed 修过 Mod+P），
    # HM 部署会报 "would be clobbered" → force = true 强制接管为 HM 链接。
    "niri/binds.kdl" = {
      source = ./dotfiles/config/niri/binds.kdl;
      force = true;
    };
    "niri/blur.kdl".source = ./dotfiles/config/niri/blur.kdl;
    # config.kdl 实体机上存在非 HM 管理的旧文件（此前手动/脚本写入），
    # HM 部署会报 "would be clobbered" → force = true 强制接管为 HM 链接。
    "niri/config.kdl" = {
      source = ./dotfiles/config/niri/config.kdl;
      force = true;
    };
    "niri/cursor.kdl".source = ./dotfiles/config/niri/cursor.kdl;
    "niri/layout.kdl".source = ./dotfiles/config/niri/layout.kdl;
    # ⚠️ niri/noctalia.kdl 不部署：由 Noctalia 配色模板生成（niri.kdl 模板写色）。
    # 部署成只读 symlink → 模板写入 Read-only file system → 配色模板处理失败。
    # 注意：config.kdl 里的 `include "./noctalia.kdl"` 在文件缺失时是**致命**的——
    # niri 整个配置解析失败（并非"可容忍"），spawn-at-startup 全部不执行 →
    # noctalia-shell 永远起不来 → 模板永远不生成 → 死锁。
    # 因此由下方 home.activation.noctaliaKdlSeed 首次部署一个可写占位 seed，
    # 保证 include 首次启动即可解析；noctalia-shell 起来后自行覆盖为真实配色。
    "niri/outputs.kdl".source = ./dotfiles/config/niri/outputs.kdl;
    "niri/supertab.kdl".source = ./dotfiles/config/niri/supertab.kdl;
    "niri/windowrules.kdl".source = ./dotfiles/config/niri/windowrules.kdl;
    # v4 版 noctalia 配置（settings/plugins/colors/user-templates/templates/*）已全部移除：
    # 不读取且 colors.json 等与 noctalia-shell 模板输出冲突（只读 symlink 无法写入）；
    # 配色/主题模板由 noctalia-shell 的 matugen 模板系统生成（可写真实文件）。
    # v4 配置（JSON）：settings.json / plugins.json / colors.json / user-templates.toml
    # user-templates.toml 随上方 4 个 v4 JSON 一起部署（不再塞进 v5 的 config.toml）
    # （qq-flags.conf 已删：linuxqq 未装，QQ 走 flatpak 沙箱不读）
    "satty/config.toml".source = ./dotfiles/config/satty/config.toml;
    "starship.toml".source = ./dotfiles/config/starship.toml;
    "xdg-desktop-portal/niri-portals.conf".source = ./dotfiles/config/xdg-desktop-portal/niri-portals.conf;
    "xdg-terminals.list".source = ./dotfiles/config/xdg-terminals.list;
    "xfce4/helpers.rc".source = ./dotfiles/config/xfce4/helpers.rc;
    "xfce4/xfconf/xfce-perchannel-xml/thunar-volman.xml".source = ./dotfiles/config/xfce4/xfconf/xfce-perchannel-xml/thunar-volman.xml;
    "xfce4/xfconf/xfce-perchannel-xml/thunar.xml".source = ./dotfiles/config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml;
    "xsettingsd/xsettingsd.conf".source = ./dotfiles/config/xsettingsd/xsettingsd.conf;
  };

  # ============================================================
  #  niri/noctalia.kdl 可写 seed（修复"启动项全部不启动"死锁）
  # ============================================================
  # config.kdl 预写了 `include "./noctalia.kdl"`，而该文件由 noctalia-shell
  # 模板系统生成（matugen 写色）。首次登录时文件尚不存在 → niri include 失败
  # → 整个配置解析失败 → 以默认配置运行 → spawn-at-startup 全部失效 →
  # noctalia-shell 起不来 → 模板永不生成（死锁）。见上方 xdg.configFile 注释。
  # 这里在 activation 时仅当文件缺失才写入一个可写占位 seed（真实文件而非
  # 只读 symlink），保证首次启动 include 可解析；noctalia-shell 起来后
  # 覆盖为真实配色，后续 activation 不再动它。
  home.activation.noctaliaKdlSeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SEED="$HOME/.config/niri/noctalia.kdl"
    if [ ! -f "$SEED" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.config/niri"
      $DRY_RUN_CMD cat > "$SEED" <<'EOF'
// 占位配色（Tokyo Night 色值），noctalia-shell 模板系统首次运行后会覆盖。
layout {
    focus-ring {
        active-color   "#7aa2f7"
        inactive-color "#1f2335"
        urgent-color   "#f7768e"
    }
    border {
        active-color   "#7aa2f7"
        inactive-color "#1f2335"
        urgent-color   "#f7768e"
    }
    shadow {
        color "#00000070"
    }
    tab-indicator {
        active-color   "#7aa2f7"
        inactive-color "#414868"
        urgent-color   "#f7768e"
    }
    insert-hint {
        color "#7aa2f780"
    }
}

recent-windows {
    highlight {
        active-color "#7aa2f7"
        urgent-color "#f7768e"
    }
}
EOF
    fi
  '';

  home.file = {
    # ── 用户头像（freedesktop 标准 ~/.face，ly 登录管理器 + noctalia 控制中心读取）──
    ".face".source = ./dotfiles/avatar.png;
    # ── Neovim wrapper 菜单条目修复 ──
    # nixvim 构建的 neovim 自带 nvim.desktop（Terminal=true，图形启动器打不开）。
    # flake overlay 覆盖不到 nixvim（它用自己 pin 的 nixpkgs 构建）→ 用用户级
    # ~/.local/share/applications 覆盖（freedesktop 优先级最高，启动器优先读这里）。
    ".local/share/applications/nvim.desktop".text = ''
      [Desktop Entry]
      Name=Neovim wrapper
      GenericName=Text Editor
      Comment=Edit text files
      TryExec=nvim
      Exec=kitty -e nvim %F
      Icon=nvim
      Type=Application
      Terminal=false
      Categories=Utility;TextEditor;Development;
      MimeType=text/plain;text/x-makefile;application/x-shellscript;text/x-c;text/x-c++src;
      StartupNotify=false
    '';
    # ── fcitx5 托盘/菜单图标 hicolor 兜底 ──
    # fcitx5 SNI 图标名（notificationitem.cpp）：托盘=input-keyboard-symbolic、
    # 菜单「重启」=view-refresh、「退出」=application-exit。Papirus 有这些图标，
    # 但若宿主/Qt 对 Papirus 查找失败，hicolor 是 XDG 最终兜底主题必查。
    # 不写用户级 index.theme（避免遮蔽系统 hicolor 的完整目录定义）。
    # 逐文件部署（目录级 source 在目标目录已存在时 ln 无法覆盖目录，即使 force=true）；
    # 文件级 force=true 覆盖手动复制过的同名文件。
    ".local/share/icons/hicolor/scalable/apps/input-keyboard-symbolic.svg" = {
      source = ./dotfiles/icons/hicolor/scalable/apps/input-keyboard-symbolic.svg;
      force = true;
    };
    ".local/share/icons/hicolor/scalable/apps/view-refresh.svg" = {
      source = ./dotfiles/icons/hicolor/scalable/apps/view-refresh.svg;
      force = true;
    };
    ".local/share/icons/hicolor/scalable/apps/application-exit.svg" = {
      source = ./dotfiles/icons/hicolor/scalable/apps/application-exit.svg;
      force = true;
    };
    # ── 应用图标 hicolor 兜底（256x256）──
    # tabby/splayer-next（AppImage wrap 包自带 desktop 但图标不在标准路径）、
    # lunarclient（nixpkgs 包 desktop Icon=lunarclient 但无对应图标文件）。
    # 之前 VM 手动复制未固化 → 实体机重装后图标消失，收进仓库声明式部署。
    ".local/share/icons/hicolor/256x256/apps/tabby.png" = {
      source = ./dotfiles/icons/hicolor/256x256/apps/tabby.png;
      force = true;
    };
    ".local/share/icons/hicolor/256x256/apps/splayer-next.png" = {
      source = ./dotfiles/icons/hicolor/256x256/apps/splayer-next.png;
      force = true;
    };
    ".local/share/icons/hicolor/256x256/apps/lunarclient.png" = {
      source = ./dotfiles/icons/hicolor/256x256/apps/lunarclient.png;
      force = true;
    };
    # ── AppImage wrap 包（tabby/splayer-next）的 desktop 入口 ──
    # wrapType2 26.05 FHS 输出不带标准路径 desktop；xdg.desktopEntries 在
    # useUserPackages 下未落到 ~/.local/share/applications → 用 home.file 强制写文件
    # force=true：更早的 xdg.desktopEntries 生成过普通文件，HM 拒绝覆盖
    ".local/share/applications/tabby.desktop" = {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=Tabby
        Comment=Terminal emulator
        Exec=tabby-terminal
        Icon=tabby
        Terminal=false
        Categories=System;TerminalEmulator;
      '';
      force = true;
    };
    ".local/share/applications/splayer-next.desktop" = {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=SPlayer-Next
        Comment=Cross-platform desktop music player
        Exec=splayer-next
        Icon=splayer-next
        Terminal=false
        Categories=AudioVideo;Audio;Player;
      '';
      force = true;
    };
    # ── OBS VDO.Ninja 插件（pkgs/obs-vdoninja，autoPatchelf 修好依赖）──
    # ⚠️ 不能裸拷 .so（RPATH 指向构建机，依赖全丢）；链接 Nix 包产物，
    #    autoPatchelf 后 .so 的 RPATH 指向 store 里的 libobs/libdatachannel/ffmpeg 等
    ".config/scripts/noctalia-wallpaper-autostart.sh" = {
      source = ./dotfiles/scripts/noctalia-wallpaper-autostart.sh;
      executable = true;
    };
    ".config/obs-studio/plugins/obs-vdoninja/bin/64bit".source =
      selfPackages.obs-vdoninja + "/lib/obs-plugins";
    ".config/obs-studio/plugins/obs-vdoninja/data".source =
      selfPackages.obs-vdoninja + "/share/obs/obs-plugins/obs-vdoninja/locale";
    # ── 壁纸（原 resources/Wallpapers，noctalia 壁纸轮播/随机切换依赖 ~/Pictures/Wallpapers）──
    "Pictures/Wallpapers/wallhaven-d88d53.png".source = ./dotfiles/Pictures/Wallpapers/wallhaven-d88d53.png;
    "Pictures/Wallpapers/wallhaven-yq8w67.jpg".source = ./dotfiles/Pictures/Wallpapers/wallhaven-yq8w67.jpg;
    # 视频壁纸（mpvpaper 播放；noctalia 壁纸组件已禁用，背景层由 mpvpaper 接管）
    "Pictures/Wallpapers/hatsune-miku.mp4".source = ./dotfiles/Pictures/Wallpapers/hatsune-miku.mp4;
    # 原 .gtkrc-2.0 内容已并入 gtk.gtk2.extraConfig（fcitx 输入法），不再手动部署避免模块冲突
    ".local/bin/random-anime-wallpaper-noctalia" = {
      source = ./dotfiles/local/bin/random-anime-wallpaper-noctalia;
      executable = true;
    };
    # SHORiN 私有脚本迁移（对应 binds.kdl：Mod+F3 录屏菜单、Mod+F5 快存、Mod+F8 快读）
    ".local/bin/shorin-screenrec-menu" = {
      source = ./dotfiles/local/bin/shorin-screenrec-menu;
      executable = true;
    };
    ".local/bin/quicksave" = {
      source = ./dotfiles/local/bin/quicksave;
      executable = true;
    };
    ".local/bin/quickload" = {
      source = ./dotfiles/local/bin/quickload;
      executable = true;
    };
    ".local/share/fcitx5/rime/default.custom.yaml".source = ./dotfiles/local/share/fcitx5/rime/default.custom.yaml;
    ".local/share/fcitx5/rime/rime_ice.custom.yaml".source = ./dotfiles/local/share/fcitx5/rime/rime_ice.custom.yaml;
    ".local/share/fcitx5/themes/Matugen/theme.conf".source = ./dotfiles/local/share/fcitx5/themes/Matugen/theme.conf;
    ".local/share/fcitx5/themes/default/theme.conf".source = ./dotfiles/local/share/fcitx5/themes/default/theme.conf;
    ".local/share/icons/Adwaita-Matugen-B/index.theme".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/index.theme;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/application-x-addon.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/application-x-addon.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/application-x-executable.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/application-x-executable.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/audio-x-generic.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/audio-x-generic.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/font-x-generic.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/font-x-generic.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/inode-directory.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/inode-directory.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/text-html.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/text-html.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/text-x-script.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/text-x-script.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/x-office-document.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/x-office-document.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/x-office-presentation.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/x-office-presentation.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-documents.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-documents.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-download.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-download.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-drag-accept.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-drag-accept.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-music.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-music.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-pictures.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-pictures.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-publicshare.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-publicshare.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-remote.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-remote.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-templates.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-templates.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-videos.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-videos.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/network-server.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/network-server.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/network-workgroup.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/network-workgroup.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/user-bookmarks.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/user-bookmarks.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/user-desktop.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/user-desktop.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/user-home.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/user-home.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/user-trash.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/user-trash.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/status/folder-open.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/status/folder-open.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/status/user-trash-full.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/status/user-trash-full.svg;
    ".local/share/nwg-look/gsettings".source = ./dotfiles/local/share/nwg-look/gsettings;
    # （.vimrc 已删：vim 未安装，编辑器 nvim=CookNixvim 不读 .vimrc）

    # ── SHORiN 私有 niri 脚本（配置迁移：从上游 noctalia-dotfiles 引入）──
    # 对应 binds.kdl 里直接调用 ~/.config/niri/scripts/* 的绑定：
    #   niri-binds（Mod+Shift+Slash 快捷键菜单）、niri-pick（Mod+P 取窗口/颜色信息）、
    #   niri-force-kill-window（Alt+F4 强杀窗口）、screenshot-sound.sh（截图音效守护，见 config.kdl）。
    # random-anime-wallpaper-noctalia 已在上面 .local/bin 部署；niri-sidebar 走 selfPackages。
    ".config/niri/scripts/niri-binds" = {
      source = ./dotfiles/config/niri/scripts/niri-binds;
      executable = true;
    };
    ".config/niri/scripts/niri-pick" = {
      source = ./dotfiles/config/niri/scripts/niri-pick;
      executable = true;
    };
    ".config/niri/scripts/niri-force-kill-window" = {
      source = ./dotfiles/config/niri/scripts/niri-force-kill-window;
      executable = true;
    };
    ".config/niri/scripts/screenshot-sound.sh" = {
      source = ./dotfiles/config/niri/scripts/screenshot-sound.sh;
      executable = true;
    };
  };

  # polkit 认证代理：NixOS 上没有 Arch 的 /usr/lib/polkit-gnome，
  # 改用 Home Manager 的 polkit-gnome 用户服务拉起。
  services.polkit-gnome.enable = true;

  # ── GTK 主题/图标（noctalia launcher、GTK 应用图标解析依赖 freedesktop 主题）──
  # 由 home-manager gtk 模块全权写 settings.ini（不部署 dotfiles 的 settings.ini，
  # 避免只读 symlink 挡住模块写入导致图标主题失效）。
  # 图标用 Papirus（覆盖最广：Steam/Flatpak/Electron/GTK），Adwaita 兜底由包提供；
  # 主题 adw-gtk3-dark（libadwaita 风格，flatpak 应用 GTK_THEME 也指向它）。
  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    cursorTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    font = {
      name = "Adwaita Sans";
      size = 11;
    };
    # 原 dotfiles/home/.gtkrc-2.0 的 fcitx 输入法配置合并进模块（避免 .gtkrc-2.0 管理冲突）
    gtk2.extraConfig = ''
      gtk-im-module="fcitx"
    '';
    # 原 dotfiles gtk-3.0/settings.ini 的其余设置（去掉 gtk-im-module，Wayland 前端不需要；
    # 26.05 HM 的 gtk3.extraConfig 是 attrset 类型）
    gtk3.extraConfig = {
      gtk-toolbar-style = "GTK_TOOLBAR_ICONS";
      gtk-toolbar-icon-size = "GTK_ICON_SIZE_LARGE_TOOLBAR";
      gtk-button-images = "0";
      gtk-menu-images = "0";
      gtk-enable-event-sounds = "1";
      gtk-enable-input-feedback-sounds = "0";
      gtk-xft-antialias = "1";
      gtk-xft-hinting = "1";
      gtk-xft-hintstyle = "hintslight";
      gtk-xft-rgba = "rgb";
      gtk-application-prefer-dark-theme = "1";
    };
    gtk4.extraConfig = {
      # 注：不再设 gtk-application-prefer-dark-theme —— libadwaita 不支持该
      # 设置（启动报 "Using GtkSettings:gtk-application-prefer-dark-theme with
      # libadwaita is unsupported" 警告），暗色由 noctalia 主题/GTK3 处理。
    };
  };

  # ============================================================
  #  不在 nixpkgs 的包 → 走 flake / 自行打包
  #  （原脚本靠 shorin-arch 自建仓库与 AUR 提供，NixOS 无等价）
  # ============================================================
  # Flatpak 服务已在 configuration.nix 开启，flatpak-repo 服务启动时自动安装：
  #   com.tencent.WeChat（微信）/ com.qq.QQ（QQ）/ com.github.tchx84.Flatseal（Flatpak 管理）
  # 其他缺失的闭源 App 同样可走 Flatpak（flathub 已配 USTC 镜像），手动：
  #   flatpak install flathub <应用ID>
  #   services.flatpak.packages = [
  #     "flathub:com.qq.QQ"
  #   ];
  #
  # niri / Noctalia 以及其余 SHORiN rice 配置已落到 dotfiles/ 并通过 xdg.configFile / home.file 部署：
  #   - dotfiles/config/niri/*.kdl   （config.kdl + 9 个 include 拆分文件）
  #   - dotfiles/config/noctalia/{settings,plugins,colors}.json + user-templates.toml   （独立 v4 应用配置，已被 noctalia-shell 取代、不再被读取，保留作参考）
  # 已针对 NixOS 适配：桌面 shell 用 nixpkgs 自带的 noctalia-shell（quickshell 配置封装），
  # 由 config.kdl 的 `spawn-sh-at-startup "noctalia-shell"` 拉起，还原了 SHORiN 原版
  # `qs -c noctalia-shell` 的写法；注释掉了 Arch 专用的 /usr/lib/polkit-gnome、
  # /usr/lib/xdg-desktop-portal-gnome，以及依赖私有脚本的 linuxqq-clipsync 等。
  # polkit 代理改用 services.polkit-gnome.enable。
  #
  # ⚠️ 关于 SHORiN 原版交互的还原程度（配置迁移结果）：
  #  • 私有 niri 脚本已迁移（见上面 home.file 的 ~/.config/niri/scripts/*）：
  #    niri-binds / niri-pick / niri-force-kill-window / screenshot-sound.sh
  #    —— 对应 binds.kdl 的快捷键菜单(Mod+Shift+Slash)、取窗口信息(Mod+P)、
  #       强杀窗口(Alt+F4)、截图音效等绑定现已可用；截图音效需 config.kdl 里
  #       的 `spawn-at-startup "~/.config/niri/scripts/screenshot-sound.sh"` 已启用。
  #    random-anime-wallpaper-noctalia 已在 .local/bin 部署；niri-sidebar 走 selfPackages。
  #  • 仍依赖 AUR、本仓库未纳入的脚本（shorin-screenrec-menu / quicksave / quickload，
  #    来自 AUR noctalia-shell / shorin-contrib）对应的绑定（Mod+F3/F5/F8）会静默失败，
  #    需要时可自行补充或打包。
  #  • 启动器/设置/壁纸/电源菜单/锁屏/音量/亮度等绑定现在走
  #    `noctalia-shell ipc call ...`（binds.kdl 已全部改用 nixpkgs 的
  #    noctalia-shell 封装，不再写 `qs -c noctalia-shell`）。桌面 shell 由
  #    config.kdl 的 `spawn-sh-at-startup "noctalia-shell"` 拉起，这些 IPC 绑定现已生效。
  #
  # 不在 nixpkgs 的包，已用 ./pkgs 自构建派生解决（见 README「自构建程序」一节）：
  #   niri-sidebar-git / pins-git / python-pywalfox / shorin-contrib-git /
  #   shorin-proton-wrapper-git / splayer-next
  # （miyu 已按需求移除。）flake 安装：opencode；桌面 shell 改为 nixpkgs 的 noctalia-shell（替代独立 noctalia v4.7.7 应用）。
}
