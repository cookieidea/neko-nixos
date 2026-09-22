{ pkgs, selfPackages, hmLib, ... }:

{
  home.packages = with pkgs; [
    # Nautilus 的扩展、PATH 和运行时变量由自构建包统一处理。
    selfPackages.nautilus-with-extensions
    nautilus-python
    localsearch
    gvfs
    ffmpegthumbnailer
    file-roller
    webp-pixbuf-loader
    poppler
    jpegoptim
    pngquant
    hmLib.xdgOpenWithGio
  ];
}
