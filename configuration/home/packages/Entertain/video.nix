{ pkgs, ... }:

{
  home.packages = with pkgs; [
    kdePackages.kdenlive
    upscaler
    video-downloader
  ];
}
