{ pkgs, ... }:

{
  home.packages = with pkgs; [
    zenity
    xdg-terminal-exec
    libnotify
    xsettingsd
    xprop
    xhost
  ];
}
