{ pkgs, ... }:

{
  home.packages = with pkgs; [
    cliphist
    qt6Packages.fcitx5-configtool
  ];
}
