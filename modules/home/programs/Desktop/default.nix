# 桌面环境与外观（niri、图标/光标主题、文件管理器生态、剪贴板）
{ pkgs, selfPackages, hmLib, ... }:

{
  home.packages = with pkgs; [
    niri                                       # niri 合成器本体（greetd/Noctalia Greeter 会话拉起，也放这里保持 PATH 一致）
    kitty                                      # 终端（binds: Mod+Return / Mod+T / Mod+Slash / opencode）
    fuzzel                                     # 启动器兜底（binds: Mod+Z 失败回退 fuzzel）
    adwaita-icon-theme                          # Adwaita 基底图标（默认 freedesktop 标准）
    papirus-icon-theme                          # Papirus（丰富的应用图标，覆盖 Steam/Flatpak 等）
    hicolor-icon-theme                          # hicolor 兜底主题（Flatpak 应用图标/桌面文件图标扫描依赖）
    (pkgs.runCommand "nautilus-wrapper" { buildInputs = [ pkgs.makeWrapper ]; } ''
      makeWrapper ${pkgs.nautilus}/bin/nautilus $out/bin/nautilus \
        --set NAUTILUS_4_EXTENSION_DIR "${selfPackages.nautilus-extensions.nautilus-with-extensions}/lib/nautilus/extensions-4" \
        --prefix PATH : "${pkgs.lib.makeBinPath [ pkgs.imagemagick pkgs.jpegoptim pkgs.pngquant pkgs.ffmpeg pkgs.coreutils ]}"
    '')                                              # nautilus + image-converter + video-to-audio（binds: Mod+E）
    nautilus-python                             # nautilus Python 扩展加载器
    localsearch                                 # nautilus 全文搜索后端（Tracker3/LocalSearch3）
    zenity                                      # zenity（mpv input_plus 打开文件对话框，Linux 替代 openfile.exe）
    gnome-keyring                             # 密钥环（登录钥匙串，nautilus/远程/应用依赖）
    gvfs                                      # 虚拟文件系统（smb/mtp/gphoto2 挂载）
    ffmpegthumbnailer                         # 视频缩略图（nautilus）
    file-roller                               # 归档 GUI（= ark 的 GNOME 版）
    webp-pixbuf-loader                        # webp 缩略图
    poppler                                   # PDF 缩略图（libpoppler-glib）
    gst_all_1.gst-plugins-base                # GStreamer 基础插件
    gst_all_1.gst-plugins-good                # GStreamer 常规插件
    gst_all_1.gst-libav                       # GStreamer libav（解码）
    font-awesome                              # Font Awesome 图标字体（原 otf-font-awesome）
    cliphist                                   # 剪贴板历史（noctalia config.toml 的 clipboard watch 命令）
    libnotify                                 # notify-send（niri-pick / niri-force-kill-window 依赖）
    xsettingsd                                 # GTK 主题/字体经 XSETTINGS 注入应用（niri 无 DE 时需要）
    xprop                                       # xprop（26.05 起 xorg 属性集弃用，xorg.xprop 改为顶层 xprop；niri-force-kill-window 依赖）
    btrfs-assistant                            # btrfs 快照管理 CLI（quickload Mod+F8 的回滚后端）
    kdePackages.breeze                           # 光标主题 Breeze_Cursors（cursor.kdl 指定；breeze 包含光标，非独立 breeze-cursors 属性）
    xhost                                      # XWayland 授权（config.kdl spawn-at-startup "xhost"；26.05 xorg 包集移到顶层）
    qt6Packages.fcitx5-configtool              # fcitx5 配置 GUI（原 fcitx5-configtool；26.05 移到 qt6Packages）
    xdg-terminal-exec                          # 终端选择器（xdg-open 按 xdg-terminals.list 选 kitty）
    hmLib.xdgOpenWithGio                             # trash:// 等 gvfs URI 正确交给 gio
    adw-gtk3                                     # libadwaita 主题 adw-gtk3-dark（nixpkgs 属性名 adw-gtk3，非 adw-gtk-theme）
    nwg-look                                   # GTK 主题设置（原脚本 + dotfiles 已部署 nwg-look/gsettings）
    jpegoptim                                   # nautilus-image-converter 按目标大小压缩 JPEG
    pngquant                                    # nautilus-image-converter 按目标大小压缩 PNG
    matugen                                    # 主题生成器（random-anime-wallpaper-noctalia 与 noctalia-shell 模板直接调用）
  ];
}
