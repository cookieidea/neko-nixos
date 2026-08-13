# Shorin Arch Setup → Home Manager user config
# 包来源：
#   common-applist.txt          (GNOME 基线)
#   kde-applist.txt             (shell/终端 + KDE 应用)
#   kde-common-applist.txt      (KDE 系统工具/磁盘/媒体)
# 桌面：niri (Wayland 滚动平铺 compositor) + Noctalia (桌面 shell)
# 编辑器：nixvim（替代 neovim + lazyvim）
# AUR-only 与 nixpkgs 差异见底部注释。

{ config, pkgs, lib, desktop, username, nixvim, opencode, bili-danmaku-tui, selfPackages, ... }:

{
  imports = [
    nixvim.homeModules.nixvim        # nixvim（Neovim 配置框架）
    # Noctalia 改用 flake 包（见 home.packages）+ settings.json（见 xdg.configFile），
    # 不再加载它的 HM 模块，避免 programs.noctalia.settings 和手写文件冲突。
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.05";

  # ============================================================
  #  软件包（home.packages）
  #  左 = Nixpkgs 属性名，括号内 = 原 Arch 包名
  # ============================================================
  home.packages = with pkgs; [
    # --- Standard (common-applist.txt) ---
    gdu                                       # gdu
    baobab                                    # baobab
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
    obs-studio                                # obs-studio
    upscaler                                  # upscaler
    yazi                                      # yazi
    # flatseal 已在 nixpkgs 26.05 移除 → 需要时用 flatpak 装：
    #   flatpak install flathub com.github.tchx84.Flatseal
    pavucontrol                               # pavucontrol
    mousepad                                  # mousepad
    easyeffects                               # easyeffects
    # 日文输入法 fcitx5-mozc 已移除；输入法本体由 i18n.inputMethod 系统级配置
    # rime-wubi 已在 26.05 移除 → 中文输入回滚用 fcitx5-rime 默认词库（万象已不用）

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

    # --- 编辑器（替代 visual-studio-code-bin，AUR）---
    vscodium                                  # visual-studio-code-bin → 用 vscodium 去遥测

    # --- 已确认在 nixpkgs 26.05 存在的原 AUR 包 ---
    flclash                                   # flclash（代理 GUI）
    discord                                   # discord（语音/文字聊天，unfree）
    ayugram-desktop                           # ayugram-desktop（Telegram 第三方客户端，unfree）
    # wechat / qq —— nixpkgs 26.05 的 src 分别走 web.archive.org（429 限流）与腾讯 CDN
    # 旧版本链接（404），且 wechat 的 src 深埋在 appimageTools.extract 内部无法 override，
    # 故改走 Flatpak（flathub 官方维护），由 configuration.nix 的 flatpak-repo 服务启动时自动安装。
    gearlever                                 # gearlever（管理 AppImage/flatpak）
    lsfg-vk                                   # lsfg-vk（FSR 帧生成 vulkan 层）
    protonplus                                # protonplus（Proton 管理）
    mangojuice                                # mangojuice（GTK 文件管理器）

    # --- 游戏 / 影音客户端（用户新增，已在 nixpkgs 26.05 核实存在）---
    hmcl                                      # hmcl（Minecraft 启动器，开源 GPL）
    kazumi                                     # kazumi（B 站第三方客户端，Flutter；替代构建失败的 animeko）
    lunar-client                               # lunar-client（Minecraft 客户端，unfree；26.05 由 lunarclient 改名）
    taterclient-ddnet                         # taterclient-ddnet（DDNet Teeworlds 修改版客户端，Apache-2.0）

    # --- 原清单里有、之前漏加的 ---
    virt-manager                              # virt-manager（KVM 虚拟机 GUI，libvirtd 已在 configuration.nix 开）
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

    # ── 全量脚本审查补漏（04j-minimal-niri / 04k-noctalia 核对结果）──
    matugen                                    # 主题生成器（random-anime-wallpaper-noctalia 与 noctalia-shell 模板直接调用）
    imv                                        # 图片查看器（mimeapps.list 的 image/* 默认打开器）
    kdePackages.breeze                           # 光标主题 Breeze_Cursors（cursor.kdl 指定；breeze 包含光标，非独立 breeze-cursors 属性）
    xhost                                      # XWayland 授权（config.kdl spawn-at-startup "xhost"；26.05 xorg 包集移到顶层）
    pipewire                                   # 提供 pw-play（截图/强杀音效脚本依赖；服务已在 configuration.nix 开启）
    qt6Packages.fcitx5-configtool              # fcitx5 配置 GUI（原 fcitx5-configtool；26.05 移到 qt6Packages）
    tumbler                                    # thunar 缩略图后端（图片/文档缩略图，原 04j/04k 必装）
    xdg-terminal-exec                          # 终端选择器（xdg-open 按 xdg-terminials.list 选 kitty）
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
    # 走 flake 输入的包（不在 nixpkgs 核心，直接引用其 flake 构建产物）
    bili-danmaku-tui.packages.${pkgs.stdenv.hostPlatform.system}.default  # B 站直播间弹幕 TUI
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

    # ── nixvim：替代 neovim + lazyvim ─────────────────────
    # 在这里用 Nix 写 Neovim 配置（插件/配色/按键），不再需要 lazyvim。
    nixvim = {
      enable = true;
      # 示例：catppuccin 配色 + lualine 状态栏
      colorschemes.catppuccin.enable = true;
      plugins.lualine.enable = true;
      opts = {
        number = true;
        relativenumber = true;
        shiftwidth = 2;
        tabstop = 2;
      };
      # 想加插件：plugins.<name>.enable = true；
      # 想加原生 lua：extraConfigLua = '' ... '';
    };

    # ── niri：Wayland 滚动平铺 compositor ────────────────
    # 配置改用 dotfiles/niri/*.kdl，通过文件末尾的 xdg.configFile 部署，
    # 不再用 programs.niri.settings 生成，以免和手写的拆分 kdl 冲突。
  };

  # ============================================================
  #  Noctalia 桌面 shell（niri 之上的一层）
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
    "fish/fish_variables".source = ./dotfiles/config/fish/fish_variables;
    "fish/functions/apt.fish".source = ./dotfiles/config/fish/functions/apt.fish;
    "fish/functions/f.fish".source = ./dotfiles/config/fish/functions/f.fish;
    "fish/functions/fwatch.fish".source = ./dotfiles/config/fish/functions/fwatch.fish;
    "fontconfig/fonts.conf".source = ./dotfiles/config/fontconfig/fonts.conf;
    "fuzzel/fuzzel.ini".source = ./dotfiles/config/fuzzel/fuzzel.ini;
    # fuzzel/themes/noctalia 由 noctalia-shell 模板系统生成（matugen 写色），不可 home-manager 只读部署
    "gtk-3.0/bookmarks".source = ./dotfiles/config/gtk-3.0/bookmarks;
    "gtk-3.0/gtk.css".source = ./dotfiles/config/gtk-3.0/gtk.css;
    # gtk-3.0/noctalia.css 由 noctalia 模板生成（matugen 写色），不部署
    # gtk-3.0/settings.ini 不部署：由下方 gtk 模块（home-manager）全权写入，避免只读 symlink 冲突
    "gtk-4.0/gtk.css".source = ./dotfiles/config/gtk-4.0/gtk.css;
    # gtk-4.0/noctalia.css 由 noctalia 模板生成（matugen 写色），不部署
    # gtk-4.0/settings.ini 同上，由 gtk 模块写入
    "kitty/current-theme.conf".source = ./dotfiles/config/kitty/current-theme.conf;
    "kitty/kitty.conf".source = ./dotfiles/config/kitty/kitty.conf;
    "kitty/themes/kitty.conf".source = ./dotfiles/config/kitty/themes/kitty.conf;
    # kitty/themes/noctalia.conf 由 noctalia 模板生成（matugen 写色），不部署
    "mimeapps.list".source = ./dotfiles/config/mimeapps.list;
    "mpv/config".source = ./dotfiles/config/mpv/config;
    "niri/animations.kdl".source = ./dotfiles/config/niri/animations.kdl;
    "niri/binds.kdl".source = ./dotfiles/config/niri/binds.kdl;
    "niri/blur.kdl".source = ./dotfiles/config/niri/blur.kdl;
    "niri/config.kdl".source = ./dotfiles/config/niri/config.kdl;
    "niri/cursor.kdl".source = ./dotfiles/config/niri/cursor.kdl;
    "niri/layout.kdl".source = ./dotfiles/config/niri/layout.kdl;
    "niri/noctalia.kdl".source = ./dotfiles/config/niri/noctalia.kdl;
    "niri/outputs.kdl".source = ./dotfiles/config/niri/outputs.kdl;
    "niri/supertab.kdl".source = ./dotfiles/config/niri/supertab.kdl;
    "niri/windowrules.kdl".source = ./dotfiles/config/niri/windowrules.kdl;
    # v4 版 noctalia 配置（settings/plugins/colors/user-templates/templates/*）已全部移除：
    # 不读取且 colors.json 等与 noctalia-shell 模板输出冲突（只读 symlink 无法写入）；
    # 配色/主题模板由 noctalia-shell 的 matugen 模板系统生成（可写真实文件）。
    # v4 配置（JSON）：settings.json / plugins.json / colors.json / user-templates.toml
    # user-templates.toml 随上方 4 个 v4 JSON 一起部署（不再塞进 v5 的 config.toml）
    "qq-flags.conf".source = ./dotfiles/config/qq-flags.conf;
    "satty/config.toml".source = ./dotfiles/config/satty/config.toml;
    "starship.toml".source = ./dotfiles/config/starship.toml;
    "xdg-desktop-portal/niri-portals.conf".source = ./dotfiles/config/xdg-desktop-portal/niri-portals.conf;
    "xdg-terminials.list".source = ./dotfiles/config/xdg-terminials.list;
    "xfce4/helpers.rc".source = ./dotfiles/config/xfce4/helpers.rc;
    "xfce4/xfconf/xfce-perchannel-xml/thunar-volman.xml".source = ./dotfiles/config/xfce4/xfconf/xfce-perchannel-xml/thunar-volman.xml;
    "xfce4/xfconf/xfce-perchannel-xml/thunar.xml".source = ./dotfiles/config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml;
    "xsettingsd/xsettingsd.conf".source = ./dotfiles/config/xsettingsd/xsettingsd.conf;
  };

  home.file = {
    # ── 用户头像（freedesktop 标准 ~/.face，ly 登录管理器 + noctalia 控制中心读取）──
    ".face".source = ./dotfiles/avatar.png;
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
    ".config/obs-studio/plugins/obs-vdoninja/bin/64bit".source =
      selfPackages.obs-vdoninja + "/lib/obs-plugins";
    ".config/obs-studio/plugins/obs-vdoninja/data".source =
      selfPackages.obs-vdoninja + "/share/obs/obs-plugins/obs-vdoninja/locale";
    # ── 壁纸（原 resources/Wallpapers，noctalia 壁纸轮播/随机切换依赖 ~/Pictures/Wallpapers）──
    "Pictures/Wallpapers/wallhaven-d88d53.png".source = ./dotfiles/Pictures/Wallpapers/wallhaven-d88d53.png;
    "Pictures/Wallpapers/wallhaven-yq8w67.jpg".source = ./dotfiles/Pictures/Wallpapers/wallhaven-yq8w67.jpg;
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
    ".vimrc".source = ./dotfiles/home/.vimrc;

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
      gtk-application-prefer-dark-theme = "1";
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
