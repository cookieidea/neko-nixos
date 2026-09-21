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
    kdePackages.kdenlive                         # kdenlive（KDE 视频剪辑）
    kdePackages.kcalc                            # kcalc（KDE 计算器）
    upscaler
    gimp                                      # gimp（图像编辑）
    krita                                     # krita（绘画/数字艺术）
    pavucontrol
    easyeffects
    libreoffice                               # 勿 .override langs
    gnome-clocks
    transmission_4-gtk
    localsend
    mark-shot.packages.${pkgs.stdenv.hostPlatform.system}.default
    mpvpaper                                   # 视频壁纸（niri 启动项播放）
    imv                                        # 图片查看器
    google-chrome
    video-downloader                          # video-downloader（yt-dlp 图形前端）
  ];
}
