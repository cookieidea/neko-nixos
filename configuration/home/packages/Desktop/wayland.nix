# Wayland 工具（截图、通知、X11 兼容等）
{ pkgs, mark-shot, ... }:

{
  home.packages = with pkgs; [
    mark-shot.packages.${pkgs.stdenv.hostPlatform.system}.default  # 截图标注 + OCR（为 niri 设计）
    zenity
    xdg-terminal-exec
    libnotify
    xsettingsd
    xprop
    xhost
  ];
}
