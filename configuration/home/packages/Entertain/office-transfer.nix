{ pkgs, ... }:

{
  home.packages = with pkgs; [
    libreoffice
    kdePackages.kcalc                         # kcalc（KDE 计算器）
    transmission_4-gtk
    localsend
  ];
}
