# 影音娱乐（播放器、图像/视频、办公、下载、浏览器）
{ pkgs, mark-shot, hmLib, ... }:

{
  home.packages = with pkgs; [
    hmLib.mpvRifeWrapped
    opencc                                    # mpv 字幕繁简转换
    p7zip                                     # mpv 解压字幕字体包
    ffmpeg                                    # mpv 提取字幕轨道
    yt-dlp                                    # mpv 在线视频
    vapoursynth                                # mpv VapourSynth（vspipe）
    kdePackages.kdenlive                         # kdenlive（KDE 视频剪辑；26.05 属 kdePackages 不在顶层）
    kdePackages.kcalc                            # kcalc（KDE 计算器；26.05 属 kdePackages，gear 区）
    upscaler
    gimp                                      # gimp（图像编辑；3.x GTK3）
    pavucontrol
    easyeffects
    libreoffice                               # ⚠️ 勿 .override langs（wrapper 直接 override 返回函数报错）
    gnome-clocks                              # gnome-clocks
    transmission_4-gtk                        # transmission_4-gtk（26.05 移除 transmission_3-gtk / transmission-gtk）
    localsend
    mark-shot.packages.${pkgs.stdenv.hostPlatform.system}.default
    mpvpaper                                   # 视频壁纸（mpv 渲染 wlr-layer-shell，niri 启动项播放 hatsune-miku.mp4）
    imv                                        # 图片查看器（mimeapps.list 的 image/* 默认打开器）
    google-chrome                             # google-chrome (替代 firefox; unfree 已开启)
    video-downloader                          # yt-dlp 图形前端
  ];
}
