# 桌面环境与外观（niri、图标/光标主题、文件管理器生态、剪贴板）
{ pkgs, selfPackages, hmLib, ... }:

{
  home.packages = with pkgs; [
    niri                                       # niri 合成器
    kitty                                      # 终端
    fuzzel                                     # 启动器
    adwaita-icon-theme                          # Adwaita 基底图标
    papirus-icon-theme                          # Papirus 图标主题
    hicolor-icon-theme                          # hicolor 兜底主题
    (pkgs.symlinkJoin {
      name = "nautilus-wrapper";
      paths = [ pkgs.nautilus ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/nautilus \
          --set NAUTILUS_4_EXTENSION_DIR "${selfPackages.nautilus-with-extensions}/lib/nautilus/extensions-4" \
          --prefix PATH : "${pkgs.lib.makeBinPath [ pkgs.imagemagick pkgs.jpegoptim pkgs.pngquant pkgs.ffmpeg pkgs.coreutils ]}"
      '';
    })                                              # nautilus + image-converter（symlinkJoin 保留 desktop 文件）
    nautilus-python                             # nautilus Python 扩展加载器
    localsearch                                 # nautilus 全文搜索后端
    zenity                                      # mpv 文件对话框
    gnome-keyring                             # 密钥环
    gvfs                                      # 虚拟文件系统（smb/mtp/gphoto2 挂载）
    ffmpegthumbnailer                         # nautilus 视频缩略图
    file-roller                               # 归档 GUI
    webp-pixbuf-loader                        # webp 缩略图
    poppler                                   # PDF 缩略图
    gst_all_1.gst-plugins-base                # GStreamer 基础插件
    gst_all_1.gst-plugins-good                # GStreamer 常规插件
    gst_all_1.gst-libav                       # GStreamer libav
    font-awesome                              # Font Awesome 图标字体
    cliphist                                   # 剪贴板历史
    libnotify                                 # notify-send
    xsettingsd                                 # GTK 主题/字体经 XSETTINGS 注入
    xprop                                       # XWayland 属性查询
    btrfs-assistant                            # btrfs 快照管理
    kdePackages.breeze                           # 光标主题 Breeze_Cursors
    xhost                                      # XWayland 授权
    qt6Packages.fcitx5-configtool              # fcitx5 配置 GUI
    xdg-terminal-exec                          # 终端选择器
    hmLib.xdgOpenWithGio                             # trash:// 等 gvfs URI 交给 gio
    adw-gtk3                                     # libadwaita 主题 adw-gtk3-dark
    nwg-look                                   # GTK 主题设置
    jpegoptim                                   # JPEG 压缩（nautilus-image-converter）
    pngquant                                    # PNG 压缩（nautilus-image-converter）
    matugen                                    # 主题生成器
  ];
}
