# Home Manager 用户配置（桌面 niri + Noctalia；编辑器 CookNixvim）
{ config, pkgs, lib, desktop, username, cooknixvim, opencode, bili-danmaku-tui, selfPackages, noctalia, bestclient, mark-shot, llm-agents-nix, ... }:

let
  mpvRife = pkgs.mpv.override {
    mpv-unwrapped = pkgs.mpv-unwrapped.override {
      lua = pkgs.luajit;
      vapoursynthSupport = true;
    };
  };
  mpvRifeWrapped = pkgs.symlinkJoin {
    name = "mpv-rife";
    paths = [ mpvRife ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm -f "$out/bin/mpv"
      makeWrapper "${mpvRife}/bin/mpv" "$out/bin/mpv" \
        --prefix PYTHONPATH : "${selfPackages.k7sfunc}/lib/python3.13/site-packages:${pkgs.python3Packages.vapoursynth}/lib/python3.13/site-packages" \
        --set VAPOURSYNTH_EXTRA_PLUGIN_PATH "${selfPackages.vapoursynth-with-plugins}/lib/vapoursynth"
    '';
  };
  # 可写种子源（store 路径，供 activation 脚本复制出可写真实文件）
  seedKittyTheme    = builtins.toString ./dotfiles/config/kitty/themes/noctalia.conf;
  seedNoctaliaConfig = builtins.toString ./dotfiles/config/noctalia/config.toml;
  seedStarship      = builtins.toString ./dotfiles/config/starship.toml;
  seedMangoHud      = builtins.toString ./dotfiles/config/MangoHud/MangoHud.conf;
  seedWallpaperDir   = builtins.toString ./dotfiles/Pictures/Wallpapers;
  seedWallpaperVideo = builtins.toString ./dotfiles/Pictures/Wallpapers/video/hatsune-miku.mp4;
  xdgOpenWithGio = pkgs.writeShellScriptBin "xdg-open" ''
    for arg in "$@"; do
      case "$arg" in
        trash://*|computer://*|network://*|smb://*|sftp://*|ftp://*|mtp://*|gphoto2://*)
          exec ${pkgs.glib}/bin/gio open "$arg"
          ;;
      esac
    done
    exec ${pkgs.xdg-utils}/bin/xdg-open "$@"
  '';
in

{
  imports = [
    # Noctalia V5（原生 C++ shell）HM 模块：提供 programs.noctalia 声明式配置
    # （设置/壁纸/主题模板等），替代 v4 noctalia-shell。
    noctalia.homeModules.default
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.05";

  # kitty terminfo（TERM=xterm-kitty 需指向 kitty 自带 share/terminfo 防乱码）
  # ~/.local/bin 进 PATH（quicksave/quickload 等私有脚本，binds.kdl 裸命令调用）
  home.sessionPath = [ "${selfPackages.vapoursynth-with-plugins}/bin" "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/.npm-global/bin" ];
  home.sessionVariables = {
    TERMINFO_DIRS = "${pkgs.kitty}/share/terminfo";
    GIO_EXTRA_MODULES = "${pkgs.gvfs}/lib/gio/modules:${pkgs.dconf}/lib/gio/modules";   # gvfs URI（trash:// 等）
    # nautilus 扩展 + mpv RIFE（k7sfunc）共用 Python 模块路径
    PYTHONPATH = "${pkgs.python3Packages.pygobject3}/lib/python3.13/site-packages:${selfPackages.k7sfunc}/lib/python3.13/site-packages:${pkgs.python3Packages.vapoursynth}/lib/python3.13/site-packages";
    # VapourSynth R73 插件：lsmas / akarin / RIFE-ncnn / mvtools
    VAPOURSYNTH_EXTRA_PLUGIN_PATH = "${selfPackages.vapoursynth-with-plugins}/lib/vapoursynth";
    # 覆盖语义，须拼接：ABDM 托盘需 systemdLibs/pipewire-jack；MC natives（shaderc/
    # SDL3 等 dlopen）需 libstdc++（gcc.lib）——见 hmcl wrapper 注释
    LD_LIBRARY_PATH = "${pkgs.systemdLibs}/lib:/nix/store/zcqp398mxlw62jl02sx0rsc7gvcl1qhc-pipewire-1.6.6-jack/lib:${pkgs.stdenv.cc.cc.lib}/lib";
    JAVA_HOME = "${pkgs.zulu25}";
    # gsettings schema 路径（冒号分隔多目录）：
    # - gtk3：否则 kdenlive 等 GTK 选择器 abort
    # - gsettings-desktop-schemas：org.gnome.desktop.interface 等（gsettings CLI 查询需要）
    GSETTINGS_SCHEMA_DIR = "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}/glib-2.0/schemas:${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";
    CARGO_HOME = "$HOME/.cargo";
  };
  home.packages = with pkgs; [
    # --- Standard ---
    gdu
    baobab
    file                                      # file 命令（random-anime-wallpaper-noctalia 壁纸脚本依赖）
    mission-center                            # mission-center
    gnome-font-viewer                         # gnome-font-viewer
    google-chrome                             # google-chrome (替代 firefox; unfree 已开启)
    transmission_4-gtk                        # transmission_4-gtk（26.05 移除 transmission_3-gtk / transmission-gtk）
    localsend
    gnome-clocks                              # gnome-clocks
    lutris
    mangohud
    mpvRifeWrapped
    opencc                                    # mpv 字幕繁简转换
    p7zip                                     # mpv 解压字幕字体包
    ffmpeg                                    # mpv 提取字幕轨道
    yt-dlp                                    # mpv 在线视频
    vapoursynth                                # mpv VapourSynth（vspipe）
    obs-studio                                # obs-studio
    kdePackages.kdenlive                         # kdenlive（KDE 视频剪辑；26.05 属 kdePackages 不在顶层）
    kdePackages.kcalc                            # kcalc（KDE 计算器；26.05 属 kdePackages，gear 区）
    upscaler
    gimp                                      # gimp（图像编辑；3.x GTK3）
    yazi
    pavucontrol
    easyeffects
    libreoffice                               # ⚠️ 勿 .override langs（wrapper 直接 override 返回函数报错）

    # --- Shell & Terminal ---
    fish
    starship
    eza
    zoxide
    fastfetch
    imagemagick
    jpegoptim                                   # nautilus-image-converter 按目标大小压缩 JPEG
    pngquant                                    # nautilus-image-converter 按目标大小压缩 PNG
    jq
    timg
    bat
    btop                                      # btop（DE 无关，常驻）
    fd                                        # fd（find 替代，neovim/telescope 生态常用）

    # --- 编辑器 ---
    vscodium

    # --- 开发工具链 ---
    # Zulu JDK：25 默认（JAVA_HOME，26.x MC 需 25）；21/17/8 供 HMCL 按需选择。
    # 多个 JDK 顶层同名文件（Welcome.html/conf/...）buildEnv 冲突 → 逐级 HiPrio
    (pkgs.lib.setPrio (-20) pkgs.zulu25)
    (pkgs.lib.setPrio (-15) pkgs.zulu21)
    (pkgs.lib.setPrio (-10) pkgs.zulu17)
    (pkgs.lib.setPrio (-5) pkgs.zulu8)
    (python3.withPackages (ps: [ ps.pip ]))   # python3 + pip
    uv                                        # uv（现代 Python 包/虚拟环境管理器）
    rustc                                     # rust 编译器
    cargo                                     # cargo 构建系统（CARGO_HOME=~/.cargo）
    rustfmt                                   # rust 格式化（cargo fmt 调用）
    go                                        # go 工具链（含 gofmt）
    gcc                                       # gcc/g++/ld/as/ar/nm/objdump/strip 等
    gnumake                                   # make
    pkg-config                                # 编译时查找库的 Cflags/Libs
    patchelf                                  # 改 ELF 的 interpreter/rpath（Nix 生态常用）
    gh                                        # GitHub CLI（推送流程靠它取 token）
    glib                                      # gio/gsettings/gdbus (CLI 工具)
    nodejs_22                                 # Node.js 22 LTS（含 npm）
    pnpm                                      # pnpm（dsh 插件管理）
    llm-agents-nix.packages.${system}.dsh      # DeepSeek Harness（AI agent 框架）
    docker-compose                            # docker compose（配合 virtualisation.docker）

    # --- 原 AUR 包 ---
    flclash                                   # 代理 GUI
    # discord/wechat/qq 改走 Flatpak（nixpkgs 源国内不可达）
    ayugram-desktop                           # Telegram 第三方客户端
    distrobox                                 # distrobox（容器化发行版环境，需 docker/podman 后端）
    protonplus                                # protonplus（Proton 管理）
    mangojuice                                # mangojuice（GTK 文件管理器）

    # --- 游戏 / 影音客户端 ---
    # prismlauncher → hmcl（nixpkgs）
    lunar-client
    # BestClient（DDNet fork，官方 flake 预编译包；nixpkgs 的 ddnet/无此包）
    bestclient.packages.${pkgs.stdenv.hostPlatform.system}.default

    # mark-shot 截图+标注（Wayland 原生，支持 OCR/贴纸/录屏）
    mark-shot.packages.${pkgs.stdenv.hostPlatform.system}.default

    # --- 补漏 ---
    virt-manager virt-viewer                  # KVM 虚拟机 GUI
    gnome-disk-utility                        # 磁盘管理 GUI
    # ksystemlog 已移除 → journalctl
    video-downloader                          # yt-dlp 图形前端

    # --- niri 桌面生态 ---
    niri                                       # niri 合成器本体（greetd/Noctalia Greeter 会话拉起，也放这里保持 PATH 一致）
    kitty                                      # 终端（binds: Mod+Return / Mod+T / Mod+Slash / opencode）
    fuzzel                                     # 启动器兜底（binds: Mod+Z 失败回退 fuzzel）
    # 系统图标主题（noctalia 应用启动器/GTK 应用图标解析依赖 freedesktop 主题）
    adwaita-icon-theme                          # Adwaita 基底图标（默认 freedesktop 标准）
    papirus-icon-theme                          # Papirus（丰富的应用图标，覆盖 Steam/Flatpak 等）
    hicolor-icon-theme                          # hicolor 兜底主题（Flatpak 应用图标/桌面文件图标扫描依赖）
    # nautilus 包装器：强制注入 NAUTILUS_4_EXTENSION_DIR（systemd user session 有旧值缓存）
    # + PATH 前缀保证 image-converter（jpegoptim/pngquant/cp）和 video-to-audio（ffmpeg/ffprobe）
    # 调用的外部命令不依赖 ambient PATH
    (pkgs.runCommand "nautilus-wrapper" { buildInputs = [ pkgs.makeWrapper ]; } ''
      makeWrapper ${pkgs.nautilus}/bin/nautilus $out/bin/nautilus \
        --set NAUTILUS_4_EXTENSION_DIR "${selfPackages.nautilus-extensions.nautilus-with-extensions}/lib/nautilus/extensions-4" \
        --prefix PATH : "${pkgs.lib.makeBinPath [ pkgs.imagemagick pkgs.jpegoptim pkgs.pngquant pkgs.ffmpeg pkgs.coreutils ]}"
    '')                                              # nautilus + image-converter + video-to-audio（binds: Mod+E）
    nautilus-python                             # nautilus Python 扩展加载器
    localsearch                                 # nautilus 全文搜索后端（Tracker3/LocalSearch3）
                                                # 只作为 nautilus 构建期依赖存在时，其 D-Bus service
                                                # 文件与 systemd user unit 不在搜索路径上 → 点
                                                # 「搜索所有位置」报 ServiceUnknown: not activatable
    zenity                                      # zenity（mpv input_plus 打开文件对话框，Linux 替代 openfile.exe）
    # 文件管理器生态
    gnome-keyring                             # 密钥环（登录钥匙串，nautilus/远程/应用依赖）
    gvfs                                      # 虚拟文件系统（smb/mtp/gphoto2 挂载）
    ffmpegthumbnailer                         # 视频缩略图（nautilus）
    file-roller                               # 归档 GUI（= ark 的 GNOME 版）
    webp-pixbuf-loader                        # webp 缩略图
    poppler                                   # PDF 缩略图（libpoppler-glib）
    gst_all_1.gst-plugins-base                # GStreamer 基础插件
    gst_all_1.gst-plugins-good                # GStreamer 常规插件
    gst_all_1.gst-libav                       # GStreamer libav（解码）
    usbutils
    pciutils
    font-awesome                              # Font Awesome 图标字体（原 otf-font-awesome）
    cliphist                                   # 剪贴板历史（noctalia config.toml 的 clipboard watch 命令）
    libnotify                                 # notify-send（niri-pick / niri-force-kill-window 依赖）
    xsettingsd                                 # GTK 主题/字体经 XSETTINGS 注入应用（niri 无 DE 时需要）
    xprop                                       # xprop（26.05 起 xorg 属性集弃用，xorg.xprop 改为顶层 xprop；niri-force-kill-window 依赖）
    btrfs-assistant                            # btrfs 快照管理 CLI（quickload Mod+F8 的回滚后端）
    # 02b/99-apps 补充
    cmatrix lolcat sl                          # 彩蛋趣味命令（原 02b 安装）
    wineWow64Packages.stable                   # wine（原 99-apps 的 wine 全家；26.05 弃用 wineWowPackages）
    # bottles 改走 Flatpak（nixpkgs FHS 版连接检测端点失效无法下载 runner）

    # 脚本审查补漏
    matugen                                    # 主题生成器（random-anime-wallpaper-noctalia 与 noctalia-shell 模板直接调用）
    mpvpaper                                   # 视频壁纸（mpv 渲染 wlr-layer-shell，niri 启动项播放 hatsune-miku.mp4）
    # NyxNiri 新增
    imv                                        # 图片查看器（mimeapps.list 的 image/* 默认打开器）
    kdePackages.breeze                           # 光标主题 Breeze_Cursors（cursor.kdl 指定；breeze 包含光标，非独立 breeze-cursors 属性）
    xhost                                      # XWayland 授权（config.kdl spawn-at-startup "xhost"；26.05 xorg 包集移到顶层）
    pipewire                                   # 提供 pw-play（截图/强杀音效脚本依赖；服务已在 configuration.nix 开启）
    qt6Packages.fcitx5-configtool              # fcitx5 配置 GUI（原 fcitx5-configtool；26.05 移到 qt6Packages）
    xdg-terminal-exec                          # 终端选择器（xdg-open 按 xdg-terminals.list 选 kitty）
    xdgOpenWithGio                             # trash:// 等 gvfs URI 正确交给 gio
    adw-gtk3                                     # libadwaita 主题 adw-gtk3-dark（nixpkgs 属性名 adw-gtk3，非 adw-gtk-theme）
    nwg-look                                   # GTK 主题设置（原脚本 + dotfiles 已部署 nwg-look/gsettings）
    icoextract                                 # Windows exe/ico 图标缩略图（原 FM_PKGS1）
    cava                                       # 音频可视化（终端彩蛋，原 04k TERM_PKGS）
  ] ++ [

  # opencode（AI 编程 Agent）走 flake 装，拿最新版（不在 nixpkgs 核心）。
  # noctalia-shell（桌面 shell，quickshell 配置 + qs 封装）直接用 nixpkgs 自带的
  # `noctalia-shell` 包，不再用独立的 noctalia v4 应用（见文末注释）。

    opencode.packages.${pkgs.stdenv.hostPlatform.system}.default
  ]

  # 自构建程序（flake 包，见 ./pkgs；对应原 Arch 的 AUR `-git` / 私有仓库）
  ++ [
    selfPackages.niri-sidebar     # niri-sidebar-git
    selfPackages.nyxniri-scratch-menu  # NyxNiri 星环菜单（GTK3+LayerShell，Super+A）
    selfPackages.pins
    selfPackages.shorin-contrib   # shorin-contrib-git
    selfPackages.splayer-next     # SPlayer-Dev/SPlayer-Next（非 nixpkgs 的 splayer）
    selfPackages.ab-download-manager  # AB Download Manager（多线程下载器，Compose Desktop；自构建）
    selfPackages.tabby-terminal       # Tabby 终端（eugeny/tabby，Electron；自构建，nixpkgs 的 tabby 是 TabbyML AI 助手）
    selfPackages.purevox              # PureVox（实时 AI 音频降噪，AppImage 捆绑内嵌 Python，PipeWire 直用）
    selfPackages.bedrockboot          # BedrockBoot（MC 基岩版启动器，Avalonia；AppImage+FHS）
    # HMCL wrapper：SDL 强制原生 Wayland——niri 缺 fifo-v1 时 SDL3 回退 XWayland
    # 锁帧 60fps；游戏继承此环境解锁帧率。natives 的 shaderc/spirv-cross 等 dlopen
    # 依赖 libstdc++——HMCL 会重置游戏 LD_LIBRARY_PATH（自己的 NixOS 适配清单，
    # 不含 gcc lib）→ 注入不进去，改用 LD_PRELOAD 强制全局可见
    (pkgs.writeShellScriptBin "hmcl" ''
      export SDL_VIDEO_DRIVER=wayland
      export LD_PRELOAD="${pkgs.stdenv.cc.cc.lib}/lib/libstdc++.so.6''${LD_PRELOAD:+:$LD_PRELOAD}"
      exec ${pkgs.hmcl}/bin/hmcl "$@"
    '')
    (pkgs.runCommand "hmcl-assets" { } ''
      mkdir -p $out/share
      cp -r ${pkgs.hmcl}/share/applications $out/share/
      cp -r ${pkgs.hmcl}/share/icons $out/share/
    '')
    selfPackages.astral               # Astral 组网客户端（Flutter+Rust；bundle 由 pkgs/astral/build.sh 联网构建）
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

    # ── Noctalia V5（原生 C++ Wayland 桌面 shell，替代 v4 noctalia-shell）──
    # settings 指向 NyxNiri 移植的 config.toml（见 xdg.configFile 部署注释）。
    # 不启用 systemd 服务：由 config.kdl 的 spawn-at-startup "noctalia" 拉起。
    noctalia = {
      enable = true;
      systemd.enable = false;
      settings = ./dotfiles/config/noctalia/config.toml;
    };

    # ── niri：Wayland 滚动平铺 compositor ────────────────
    # 配置改用 dotfiles/niri/*.kdl，通过文件末尾的 xdg.configFile 部署，
    # 不再用 programs.niri.settings 生成，以免和手写的拆分 kdl 冲突。
  };

  # ============================================================
  #  systemd user 服务（登录图形会话后自启）
  # ============================================================
  # ABDM 不自启（其自身有 autostart 机制，双启会弹窗）；托盘由下方 drop-in 兜底

  # nautilus-open-any-terminal：nautilus 由 niri（systemd 服务）spawn，只继承
  # systemd 用户环境 → 注入 gi/typelib，"打开终端"才不消失
  systemd.user.sessionVariables = {
    PYTHONPATH = "${pkgs.python3Packages.pygobject3}/lib/python3.13/site-packages:${selfPackages.k7sfunc}/lib/python3.13/site-packages:${pkgs.python3Packages.vapoursynth}/lib/python3.13/site-packages";
    GI_TYPELIB_PATH = "${pkgs.nautilus}/lib/girepository-1.0";
    NAUTILUS_4_EXTENSION_DIR = "${selfPackages.nautilus-extensions.nautilus-with-extensions}/lib/nautilus/extensions-4";
    VAPOURSYNTH_EXTRA_PLUGIN_PATH = "${selfPackages.vapoursynth-with-plugins}/lib/vapoursynth";
  };

  # 关机时 astral handshake 超时导致 user@1000 等待90s；不等待优雅退出，
  # SIGTERM 后 100ms 未退出即 SIGKILL（注意 TimeoutStopSec=0 表示禁用超时）
  xdg.configFile."systemd/user/astral-core.service.d/10-timeout.conf" = {
    force = true;
    text = ''
      [Service]
      TimeoutStopSec=100ms
    '';
  };

  # 开机随机壁纸（noctalia IPC）
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

  # dotfiles 部署到 ~/.config/（原 noctalia-dotfiles rice 配置）
  # ── nautilus Python 扩展部署（nautilus-python 扫描 ~/.local/share/nautilus-python/extensions）──
  xdg.dataFile = {
    "nautilus-python/extensions/video-to-audio.py".source = ./dotfiles/config/nautilus-python/video-to-audio.py;
    # lunarclient 覆盖：原包 Exec 无 %u（discord-RPC 邀请链接丢参数只开启动器不进服），
    # 且未声明 discord-562286213059444737 scheme；用户级覆盖优先级最高
    "applications/lunarclient.desktop".text = ''
      [Desktop Entry]
      Name=Lunar Client
      Exec=lunarclient %u
      Terminal=false
      Type=Application
      Icon=lunarclient
      StartupWMClass=Lunar Client
      Comment=Electron launcher for Lunar Client
      MimeType=application/x-lcpack;x-scheme-handler/lunarclient;x-scheme-handler/discord-562286213059444737;
      Categories=Game;
    '';
  };

  xdg.configFile = {
    # ABDM 托盘：autostart 重写绕过 makeWrapper → 无 systemdLibs → 托盘消失；
    # systemd user 服务不经过 login shell → 用 unit drop-in 注入 + 建 log 目录
    "systemd/user/app-com.abdownloadmanager@autostart.service.d/10-abdm-tray.conf".text = ''
      [Service]
      Environment=LD_LIBRARY_PATH=${pkgs.systemdLibs}/lib:/nix/store/zcqp398mxlw62jl02sx0rsc7gvcl1qhc-pipewire-1.6.6-jack/lib
      ExecStartPre=${pkgs.coreutils}/bin/mkdir -p %h/.abdm/system/log
    '';
    "fcitx5/conf/cached_layouts".source = ./dotfiles/config/fcitx5/conf/cached_layouts;
    "fcitx5/conf/chttrans.conf".source = ./dotfiles/config/fcitx5/conf/chttrans.conf;
    "fcitx5/conf/classicui.conf".source = ./dotfiles/config/fcitx5/conf/classicui.conf;
    "fcitx5/conf/notifications.conf".source = ./dotfiles/config/fcitx5/conf/notifications.conf;
    "fcitx5/conf/pinyin.conf".source = ./dotfiles/config/fcitx5/conf/pinyin.conf;
    "fcitx5/conf/punctuation.conf".source = ./dotfiles/config/fcitx5/conf/punctuation.conf;
    "fcitx5/config".source = ./dotfiles/config/fcitx5/config;
    "fcitx5/profile".source = ./dotfiles/config/fcitx5/profile;
    # ⚠️ fish/fish_variables 不部署（store 只读链接，fish 运行时写会 EROFS），让 fish 自己生成
    "fish/functions/apt.fish".source = ./dotfiles/config/fish/functions/apt.fish;
    "fish/functions/f.fish".source = ./dotfiles/config/fish/functions/f.fish;
    "fish/functions/fwatch.fish".source = ./dotfiles/config/fish/functions/fwatch.fish;
    "fontconfig/fonts.conf".source = ./dotfiles/config/fontconfig/fonts.conf;
    "fuzzel/fuzzel.ini".source = ./dotfiles/config/fuzzel/fuzzel.ini;
    # fuzzel/themes/noctalia 由模板生成，不部署
    "gtk-3.0/bookmarks".source = ./dotfiles/config/gtk-3.0/bookmarks;
    "gtk-3.0/gtk.css".source = ./dotfiles/config/gtk-3.0/gtk.css;
    # gtk-3.0/noctalia.css 与 settings.ini 不部署（Noctalia 模板生成 / gtk 模块写入）
    "gtk-4.0/gtk.css".source = ./dotfiles/config/gtk-4.0/gtk.css;
    # gtk-4.0/noctalia.css、settings.ini 同上不部署
    "mimeapps.list".source = ./dotfiles/config/mimeapps.list;
    # mpv（自 Windows mpv.lite 迁移并 Linux 适配）；目录级只读内容用 symlink，
    # ~/.config/mpv 本体是真实目录（watch_later 需写入）
    "mpv/mpv.conf" = {
      source = ./dotfiles/mpv/mpv.conf;
      force = true;
    };
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
    # ziggy 辅助二进制：目录 symlink 到 store 会丢执行位 → 单独部署补 executable
    ".config/mpv/scripts/uosc/bin/ziggy-linux" = {
      source = ./dotfiles/mpv/scripts/uosc/bin/ziggy-linux;
      force = true;
    };
    "mpv/scripts/uosc_danmaku".source = ./dotfiles/mpv/scripts/uosc_danmaku;
    "mpv/shaders".source = ./dotfiles/mpv/shaders;
    "mpv/vs".source = ./dotfiles/mpv/vs;
    "mpv/fonts".source = ./dotfiles/mpv/fonts;
    # niri 配置（迁移自 NyxNiri）；effects.kdl 为软链由 toggle-eyecare.sh 维护
    "niri/animations.kdl".source = ./dotfiles/config/niri/animations.kdl;
    "niri/binds.kdl" = {
      source = ./dotfiles/config/niri/binds.kdl;
      force = true;
    };
    "niri/config.kdl" = {
      source = ./dotfiles/config/niri/config.kdl;
      force = true;
    };
    "niri/cursor.kdl".source = ./dotfiles/config/niri/cursor.kdl;
    "niri/layout.kdl".source = ./dotfiles/config/niri/layout.kdl;
    "niri/monitor.kdl".source = ./dotfiles/config/niri/monitor.kdl;
    "niri/rules.kdl".source = ./dotfiles/config/niri/rules.kdl;
    "niri/effects_normal.kdl".source = ./dotfiles/config/niri/effects_normal.kdl;
    "niri/effects_eyecare.kdl".source = ./dotfiles/config/niri/effects_eyecare.kdl;
    "niri/__custom__.kdl".source = ./dotfiles/config/niri/__custom__.kdl;
    "niri/input__custom__.kdl".source = ./dotfiles/config/niri/input__custom__.kdl;
    "niri/scratchpad-items__custom__.toml".source = ./dotfiles/config/niri/scratchpad-items__custom__.toml;
    # noctalia hook 脚本；mpv-hook.lua 缺失会致 mpvpaper 视频壁纸失败
    # config.toml 由 programs.noctalia.settings 部署为 symlink，activation 会复制为
    # 可写真实文件（V5 面板回写）→ 配置变更时 force 覆盖避免 clobber
    "noctalia/config.toml".force = true;
    "noctalia/theme-sync.sh".source = ./dotfiles/config/noctalia/theme-sync.sh;
    "noctalia/wallpaper-hook.sh".source = ./dotfiles/config/noctalia/wallpaper-hook.sh;
    "noctalia/mpv-hook.lua".source = ./dotfiles/config/noctalia/mpv-hook.lua;
    # kitty（current-theme.conf 由 Noctalia 模板生成，首次 activation 种子写入）
    "kitty/kitty.conf".source = ./dotfiles/config/kitty/kitty.conf;
    "kitty/__custom__.conf".source = ./dotfiles/config/kitty/__custom__.conf;
    "kitty/themes/noctalia.conf" = {
      source = ./dotfiles/config/kitty/themes/noctalia.conf;
      force = true;
    };
    "fish/conf.d/nyxniri-path.fish".source = ./dotfiles/config/fish/conf.d/nyxniri-path.fish;
    "fish/conf.d/nyxniri.fish".source = ./dotfiles/config/fish/conf.d/nyxniri.fish;
    "fish/conf.d/__custom__.fish".source = ./dotfiles/config/fish/conf.d/__custom__.fish;
    "fish/conf.d/shorin.fish".source = ./dotfiles/config/fish/conf.d/shorin.fish;
    "fish/completions/nyxniri.fish".source = ./dotfiles/config/fish/completions/nyxniri.fish;
    # fastfetch / starship（starship.toml 的 palette 段由 Noctalia 生成，只读部署 base 版）
    "fastfetch/config.jsonc".source = ./dotfiles/config/fastfetch/config.jsonc;
    "starship.toml".source = ./dotfiles/config/starship.toml;
    # v4 版 noctalia 配置已全部移除（V5 用 config.toml，见 programs.noctalia 与上方 noctalia 部署）
    "xdg-desktop-portal/niri-portals.conf".source = ./dotfiles/config/xdg-desktop-portal/niri-portals.conf;
    ".local/share/applications/qq.desktop" = {
      force = true;
      text = ''
[Desktop Entry]
Type=Application
Name=QQ
Exec=env PULSE_LATENCY_MSEC=30 PIPEWIRE_LATENCY=512/48000 flatpak run --branch=stable --arch=x86_64 --command=qq --file-forwarding com.qq.QQ --enable-features=UseOzonePlatform --ozone-platform=wayland @@u %U
Icon=com.qq.QQ
Terminal=false
Categories=Network;InstantMessaging;
MimeType=x-scheme-handler/tencent;
X-Flatpak=com.qq.QQ
      '';
    };
    "xdg-terminals.list".source = ./dotfiles/config/xdg-terminals.list;
    "xsettingsd/xsettingsd.conf".source = ./dotfiles/config/xsettingsd/xsettingsd.conf;
  };

  # ============================================================
  #  Noctalia V5 迁移所需的可写 seed
  # ============================================================
  # 1) niri/effects.kdl 软链接：config.kdl `include "effects.kdl"`，由
  #    toggle-eyecare.sh 在普通/护眼模式间切换。首次缺失时建为 Normal。
  # 2) kitty/current-theme.conf：由 Noctalia kitty 模板生成（写色），只读
  #    symlink 会挡住写入 → 首次缺失时种子写入一个可写真实文件。
# 3) noctalia-config.toml（V5 读 ~/.config/noctalia/config.toml）：programs.noctalia.settings
    #    部署的是只读 store symlink，而 V5 设置面板会回写该文件 → 复制为可写真实文件。
  # 4) starship.toml：palette 段由 Noctalia starship 模板重写 → 复制为可写。
  # 均仅在文件缺失/是 store 链接时执行，不覆盖用户运行期修改。
  home.activation.noctaliaV5Seed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    NIRI_DIR="$HOME/.config/niri"
    KITTY_DIR="$HOME/.config/kitty"
    NOCT_DIR="$HOME/.config/noctalia"

    # effects.kdl 软链接（指向 Normal 效果）
    if [ ! -e "$NIRI_DIR/effects.kdl" ]; then
      $DRY_RUN_CMD mkdir -p "$NIRI_DIR"
      $DRY_RUN_CMD ln -sfn "effects_normal.kdl" "$NIRI_DIR/effects.kdl"
    fi

    # kitty current-theme.conf：Noctalia kitty 模板生成，缺失时种子写入 NyxNiri 主题
    if [ ! -e "$KITTY_DIR/current-theme.conf" ]; then
      $DRY_RUN_CMD mkdir -p "$KITTY_DIR"
      $DRY_RUN_CMD cp -f "${seedKittyTheme}" "$KITTY_DIR/current-theme.conf"
    fi

    # noctalia-config.toml：覆盖 HM 的只读 symlink 为可写真实文件
    if [ -L "$NOCT_DIR/config.toml" ] || [ ! -e "$NOCT_DIR/config.toml" ]; then
      $DRY_RUN_CMD mkdir -p "$NOCT_DIR"
      $DRY_RUN_CMD rm -f "$NOCT_DIR/config.toml" "$NOCT_DIR/noctalia-config.toml"
      $DRY_RUN_CMD cp -f "${seedNoctaliaConfig}" "$NOCT_DIR/config.toml"
    fi

    # starship.toml：覆盖只读 symlink 为可写真实文件（Noctalia 会重写 palette 段）
    if [ -L "$HOME/.config/starship.toml" ] || [ ! -e "$HOME/.config/starship.toml" ]; then
      $DRY_RUN_CMD rm -f "$HOME/.config/starship.toml"
      $DRY_RUN_CMD cp -f "${seedStarship}" "$HOME/.config/starship.toml"
    fi

    # MangoHud.conf：mangojuice/GOverlay 保存设置时会写此文件 → 覆盖只读 symlink 为可写副本
    if [ -L "$HOME/.config/MangoHud/MangoHud.conf" ] || [ ! -e "$HOME/.config/MangoHud/MangoHud.conf" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.config/MangoHud"
      $DRY_RUN_CMD rm -f "$HOME/.config/MangoHud/MangoHud.conf"
      $DRY_RUN_CMD cp -f "${seedMangoHud}" "$HOME/.config/MangoHud/MangoHud.conf"
      $DRY_RUN_CMD chmod 644 "$HOME/.config/MangoHud/MangoHud.conf"
    fi
  '';

  # ── 壁纸真实文件（不用软链：GC 会删旧 store 路径导致断链）──
  home.activation.wallpaperRealFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    WP="$HOME/Pictures/Wallpapers"
    for f in wallhaven-d88d53.png wallhaven-yq8w67.jpg; do
      if [ -L "$WP/$f" ] || [ ! -e "$WP/$f" ]; then
        $DRY_RUN_CMD mkdir -p "$WP"
        $DRY_RUN_CMD rm -f "$WP/$f"
        $DRY_RUN_CMD cp -f "${seedWallpaperDir}/$f" "$WP/$f"
      fi
    done
    # 视频壁纸本体 + mpvpaper 插件赋值路径（assignments.json 指向 ~/Videos/wallpaper/）
    for dest in "$WP/video/hatsune-miku.mp4" "$HOME/Videos/wallpaper/hatsune-miku.mp4"; do
      if [ -L "$dest" ] || [ ! -e "$dest" ]; then
        $DRY_RUN_CMD mkdir -p "$(dirname "$dest")"
        $DRY_RUN_CMD rm -f "$dest"
        $DRY_RUN_CMD cp -f "${seedWallpaperVideo}" "$dest"
      fi
    done
  '';

  # mark-shot OCR + 扫码 venv 自动初始化
  home.activation.markShotSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    MARK="$HOME/.local/share/mark-shot"
    OCR_VENV="$MARK/ocr-venv"
    SCAN_VENV="$MARK/code-scan-venv"
    PYTHON="${pkgs.python3}/bin/python3"
    LD_PATH="${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib.out}/lib:${pkgs.libgcc.lib}/lib:${pkgs.libxcb}/lib:${pkgs.libglvnd}/lib:${pkgs.glib.out}/lib"

    # OCR venv
    if [ ! -f "$OCR_VENV/bin/python" ] || ! env LD_LIBRARY_PATH="$LD_PATH" "$OCR_VENV/bin/python" -c "import rapidocr" 2>/dev/null; then
      $DRY_RUN_CMD rm -rf "$OCR_VENV"
      $DRY_RUN_CMD $PYTHON -m venv "$OCR_VENV"
      $DRY_RUN_CMD env LD_LIBRARY_PATH="$LD_PATH" "$OCR_VENV/bin/pip" install rapidocr onnxruntime
    fi

    # code-scan venv
    if [ ! -f "$SCAN_VENV/bin/python" ] || ! env LD_LIBRARY_PATH="$LD_PATH" "$SCAN_VENV/bin/python" -c "import zxingcpp" 2>/dev/null; then
      $DRY_RUN_CMD rm -rf "$SCAN_VENV"
      $DRY_RUN_CMD $PYTHON -m venv "$SCAN_VENV"
      $DRY_RUN_CMD env LD_LIBRARY_PATH="$LD_PATH" "$SCAN_VENV/bin/pip" install zxing-cpp pillow numpy
    fi

    # OCR helper script（mark-shot 调用入口，读图片路径 → rapidocr）
    $DRY_RUN_CMD cat > "$MARK/ocr-helper.sh" << 'OCRSCRIPT'
#!/usr/bin/env bash
export LD_LIBRARY_PATH="LIBPATH_PLACEHOLDER"
/home/cookie/.local/share/mark-shot/ocr-venv/bin/python -c "
from rapidocr import RapidOCR
import sys, json
e = RapidOCR()
result = e(sys.argv[1])
tokens = []
if result and result.txts:
    for i, txt in enumerate(result.txts):
        box = result.boxes[i].tolist() if result.boxes is not None else []
        tokens.append({'text': txt, 'confidence': float(result.scores[i]), 'box': box})
print(json.dumps({'backend': 'rapidocr', 'tokens': tokens}))
" "$1"
OCRSCRIPT
    $DRY_RUN_CMD sed -i "s|LIBPATH_PLACEHOLDER|$LD_PATH|" "$MARK/ocr-helper.sh"
    $DRY_RUN_CMD chmod +x "$MARK/ocr-helper.sh"

    # code-scan helper script（mark-shot 调用入口，用 {imagePath} 占位符）
    $DRY_RUN_CMD cat > "$MARK/code-scan-helper.sh" << 'SCANSCRIPT'
#!/usr/bin/env bash
export LD_LIBRARY_PATH="LIBPATH_PLACEHOLDER"
/home/cookie/.local/share/mark-shot/code-scan-venv/bin/python -c "
import zxingcpp, sys, json, numpy as np
from PIL import Image
img = Image.open(sys.argv[1]).convert('RGB')
arr = np.array(img)[:, :, ::-1]
results = zxingcpp.read_barcodes(arr)
output = {'backend': 'zxing', 'results': [], 'errors': []}
for r in results:
    output['results'].append({'text': r.text, 'format': str(r.format)})
print(json.dumps(output))
" "$1"
SCANSCRIPT
    $DRY_RUN_CMD sed -i "s|LIBPATH_PLACEHOLDER|$LD_PATH|" "$MARK/code-scan-helper.sh"
    $DRY_RUN_CMD chmod +x "$MARK/code-scan-helper.sh"
    # xdg.configFile 创建的是 nix store symlink（只读），覆盖为真实文件再注入 agenix secrets
    CFG="$HOME/.config/mark-shot/config.json"
    if [ -L "$CFG" ] && [ -f "/run/agenix/mark-shot-sensitive" ]; then
      LINK_TARGET=$(${pkgs.coreutils}/bin/readlink -f "$CFG")
      $DRY_RUN_CMD ${pkgs.python3}/bin/python3 ${./dotfiles/config/mark-shot/inject-secrets.py} "$CFG" "$LINK_TARGET"
    fi
  '';

  home.file = {

    # ── HMCL Java 列表：HMCL 扫 ~/.jdks（IntelliJ 风格目录），链入各 zulu ──
    ".jdks/zulu25".source = "${pkgs.zulu25}";
    ".jdks/zulu21".source = "${pkgs.zulu21}";
    ".jdks/zulu17".source = "${pkgs.zulu17}";
    ".jdks/zulu8".source = "${pkgs.zulu8}";
    # ── 用户头像（freedesktop 标准 ~/.face，Noctalia Greeter 登录界面 + Noctalia 控制中心读取）──
    ".face".source = ./dotfiles/avatar.png;
    # ── fastfetch logo 图片（kitty 图像协议；配置引用 ~/.local/share/fastfetch/NixOS.png）──
    ".local/share/fastfetch/NixOS.png".source = ./dotfiles/config/fastfetch/NixOS.png;
    # ── 用户目录映射（nautilus 侧栏/模板目录定位，XDG_TEMPLATES_DIR=~/Templates）──
    ".config/user-dirs.dirs" = {
      force = true;
      text = ''
        XDG_DESKTOP_DIR="$HOME/Desktop"
        XDG_DOCUMENTS_DIR="$HOME/Documents"
        XDG_DOWNLOAD_DIR="$HOME/Downloads"
        XDG_MUSIC_DIR="$HOME/Music"
        XDG_PICTURES_DIR="$HOME/Pictures"
        XDG_PUBLICSHARE_DIR="$HOME/Public"
        XDG_TEMPLATES_DIR="$HOME/Templates"
        XDG_VIDEOS_DIR="$HOME/Videos"
      '';
    };
    # ── 新建文档模板（XDG_TEMPLATES_DIR=~/Templates；nautilus 右键「新建文档」读取）──
    "Templates/空白文本.txt" = { force = true; text = ""; };
    "Templates/空白文档.md" = { force = true; text = ""; };
    "Templates/空白文档.yaml" = { force = true; text = ""; };
    "Templates/空白文档.json" = { force = true; text = ""; };
    "Templates/空白文档.sh" = { force = true; text = "#!/usr/bin/env bash\n"; executable = true; };
    # ── Neovim wrapper 菜单条目修复 ──
    # nixvim 构建的 neovim 自带 nvim.desktop（Terminal=true，图形启动器打不开）。
    # flake overlay 覆盖不到 nixvim（它用自己 pin 的 nixpkgs 构建）→ 用用户级
    # ~/.local/share/applications 覆盖（freedesktop 优先级最高，启动器优先读这里）。
    ".local/share/applications/nvim.desktop" = {
      force = true;
      text = ''
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
      MimeType=text/plain;text/x-makefile;application/x-shellscript;text/x-c;text/x-c++src;text/markdown;application/json;text/x-yaml;application/yaml;text/yaml;application/x-yaml;application/x-zerosize;
      StartupNotify=false
      '';
    };
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
    # ── KCalc 图标 hicolor 兜底 ──
    # kcalc.desktop 引用 Icon=accessories-calculator，该名仅 breeze/apps/48 有
    # （Papirus/hicolor 均无）；Noctalia V5 自研解析器走该链找不到 → 启动器无图标。
    # 放一份到 hicolor/scalable（全尺寸通配的最终兜底），与其他 symbolic 兜底同组。
    ".local/share/icons/hicolor/scalable/apps/accessories-calculator.svg" = {
      source = ./dotfiles/icons/hicolor/scalable/apps/accessories-calculator.svg;
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
      force = true;
    };
    ".config/obs-studio/plugins/obs-vdoninja/bin/64bit".source =
      selfPackages.obs-vdoninja + "/lib/obs-plugins";
    ".config/obs-studio/plugins/obs-vdoninja/data".source =
      selfPackages.obs-vdoninja + "/share/obs/obs-plugins/obs-vdoninja/locale";
    # ── 壁纸（原 resources/Wallpapers，noctalia 壁纸轮播/随机切换依赖 ~/Pictures/Wallpapers）──
    # ⚠️ 不用 home.file 软链（GC 后 store 路径失效会断链）→ 由下方
    #    home.activation.wallpaperRealFiles 复制为真实文件。
    # 视频壁纸（mpvpaper 播放；noctalia 壁纸组件已禁用，背景层由 mpvpaper 接管）
    # 原 .gtkrc-2.0 内容已并入 gtk.gtk2.extraConfig（fcitx 输入法），不再手动部署避免模块冲突
    ".local/bin/random-anime-wallpaper-noctalia" = {
      source = ./dotfiles/local/bin/random-anime-wallpaper-noctalia;
      executable = true;
    };
    # SHORiN 私有脚本迁移（对应 binds.kdl：Mod+F3 录屏菜单、Mod+F5 快存、Mod+F8 快读）
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
    #   niri-force-kill-window（Alt+F4 强杀窗口）。
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
    # ── NyxNiri 新增 niri 脚本（护眼模式 / Scratchpad 终端 / 星环菜单）──
    # 对应 NyxNiri 绑定：Mod+N（护眼）、Mod+Grave（scratch 终端）、Mod+A（星环菜单）。
    # 星环菜单本体由 selfPackages.nyxniri-scratch-menu 包装（提供 pygobject/GI 依赖）。
    ".config/niri/scripts/toggle-eyecare.sh" = {
      source = ./dotfiles/config/niri/scripts/toggle-eyecare.sh;
      executable = true;
    };
    ".config/niri/scripts/niri-scratch-toggle.sh" = {
      source = ./dotfiles/config/niri/scripts/niri-scratch-toggle.sh;
      executable = true;
    };
    ".config/niri/scripts/niri-scratch-menu.py" = {
      source = ./dotfiles/config/niri/scripts/niri-scratch-menu.py;
      executable = true;
    };
    # NyxNiri fish 缓存清理脚本（星环菜单 clean-cache 入口）
    ".config/fish/clean-cache" = {
      source = ./dotfiles/config/fish/clean-cache;
      executable = true;
    };
    # ── NyxMellow fcitx5 动态皮肤模板（Noctalia V5 模板输入，渲染到 themes/nyxmellow/）──
    ".local/share/fcitx5/themes/nyxmellow/templates/theme.conf" = {
      source = ./dotfiles/local/share/fcitx5/themes/nyxmellow/templates/theme.conf;
    };
    ".local/share/fcitx5/themes/nyxmellow/templates/panel.svg" = {
      source = ./dotfiles/local/share/fcitx5/themes/nyxmellow/templates/panel.svg;
    };
    ".local/share/fcitx5/themes/nyxmellow/templates/highlight.svg" = {
      source = ./dotfiles/local/share/fcitx5/themes/nyxmellow/templates/highlight.svg;
    };

    # ── 开发工具链国内镜像源 ──
    # npm → npmmirror（淘宝镜像）；prefix 指向用户目录——NixOS 的 nodejs 在只读
    # store，npm -g 默认装 store 失败（ENOENT），用户前缀 + PATH 才可用
    ".npmrc".text = ''
      registry=https://registry.npmmirror.com
      prefix=/home/cookie/.npm-global
    '';
    # cargo → 中科大 crates.io 稀疏索引
    ".cargo/config.toml".text = ''
      [source.crates-io]
      replace-with = 'ustc'
      [source.ustc]
      registry = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/"
      [net]
      git-fetch-with-cli = true
    '';
    # pip → 中科大 PyPI
    ".config/pip/pip.conf".text = ''
      [global]
      index-url = https://mirrors.ustc.edu.cn/pypi/simple
      trusted-host = mirrors.ustc.edu.cn
    '';
    # uv → 中科大 PyPI 作为默认源
    ".config/uv/uv.toml".text = ''
      [[index]]
      url = "https://mirrors.ustc.edu.cn/pypi/simple"
      default = true
    '';
  };

  services.polkit-gnome.enable = true;   # polkit 认证代理

  # ── gvfs 守护（Thunar/Nautilus 的回收站/挂载/远程文件支持）──
  # 本版 home-manager 无 services.gvfs 模块，改用 systemd.user 显式启用 gvfs 单元。
  systemd.user.services = {
    gvfs-daemon = {
      Unit = { Description = "Virtual filesystem service"; PartOf = [ "graphical-session.target" ]; };
      Service = { ExecStart = "${pkgs.gvfs}/libexec/gvfsd"; Type = "dbus"; BusName = "org.gtk.vfs.Daemon"; };
      Install.WantedBy = [ "graphical-session.target" ];
    };
    gvfs-udisks2-volume-monitor = {
      Unit = { Description = "Virtual filesystem service - disk device monitor"; PartOf = [ "graphical-session.target" ]; };
      Service = { ExecStart = "${pkgs.gvfs}/libexec/gvfs-udisks2-volume-monitor"; };
      Install.WantedBy = [ "graphical-session.target" ];
    };
    gvfs-metadata = {
      Unit = { Description = "Virtual filesystem metadata service"; PartOf = [ "graphical-session.target" ]; };
      Service = { ExecStart = "${pkgs.gvfs}/libexec/gvfsd-metadata"; };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };

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
      name = "HarmonyOS Sans SC";
      size = 10;
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

  # 不在 nixpkgs 的包走 flake / ./pkgs 自构建（见 README 自构建一节）
  # 闭源 App（微信/QQ/Discord）走 Flatpak（configuration.nix 的 flatpak-repo 自动装）
}
