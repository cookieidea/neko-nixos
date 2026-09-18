# home.packages：用户级软件包总表
{ hmLib, pkgs, config, lib, desktop, username, cooknixvim, bilihud, selfPackages, noctalia, bestclient, mark-shot, llm-agents-nix, ... }:

{
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
    hmLib.mpvRifeWrapped
    opencc                                    # mpv 字幕繁简转换
    p7zip                                     # mpv 解压字幕字体包
    ffmpeg                                    # mpv 提取字幕轨道
    yt-dlp                                    # mpv 在线视频
    vapoursynth                                # mpv VapourSynth（vspipe）
    # obs-studio 改由 programs.obs-studio 模块提供（含 VDO.Ninja 插件，见下）
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
    lazygit                                   # Git 终端 UI（TUI）
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
    hmLib.lunarclientWayland                       # lunar-client + SDL_VIDEO_DRIVER=wayland（见上方 let 块）
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
    hmLib.xdgOpenWithGio                             # trash:// 等 gvfs URI 正确交给 gio
    adw-gtk3                                     # libadwaita 主题 adw-gtk3-dark（nixpkgs 属性名 adw-gtk3，非 adw-gtk-theme）
    nwg-look                                   # GTK 主题设置（原脚本 + dotfiles 已部署 nwg-look/gsettings）
    icoextract                                 # Windows exe/ico 图标缩略图（原 FM_PKGS1）
    cava                                       # 音频可视化（终端彩蛋，原 04k TERM_PKGS）
  ] ++ [

  # opencode（AI 编程 Agent）：改用 llm-agents.nix 的包（跟 dsh 同源）。
  # 不用 nixpkgs 的 1.15.10（比在用的 1.18.x 旧，会降级）；llm-agents.nix 跟得更紧。
  # 用户配置/数据在 ~/.config/opencode 与 ~/.local/share/opencode，与包无关，换包不丢。
  # noctalia-shell（桌面 shell，quickshell 配置 + qs 封装）直接用 nixpkgs 自带的
  # `noctalia-shell` 包，不再用独立的 noctalia v4 应用（见文末注释）。

    llm-agents-nix.packages.${system}.opencode
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
    bilihud.packages.${pkgs.stdenv.hostPlatform.system}.default  # B 站直播弹幕阅读器（PyQt6 + layer-shell 全屏浮窗）
    # CookNixvim：模块化 Neovim 配置（基于 nix-community/nixvim 的完整配置），
    # 产物 packages.<sys>.default 提供 nvim 命令（替代原 programs.nixvim 简易配置）
    cooknixvim.packages.${pkgs.stdenv.hostPlatform.system}.default        # nvim（CookNixvim）
  ];
}
