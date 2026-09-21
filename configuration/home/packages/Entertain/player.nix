{ pkgs, hmLib, ... }:

{
  home.packages = with pkgs; [
    hmLib.mpvRifeWrapped
    opencc
    p7zip
    ffmpeg
    yt-dlp
    vapoursynth
    mpvpaper
  ];
}
