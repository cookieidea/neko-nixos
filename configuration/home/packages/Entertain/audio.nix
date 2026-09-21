{ pkgs, ... }:

{
  home.packages = with pkgs; [
    pavucontrol
    easyeffects
    gnome-clocks
  ];
}
