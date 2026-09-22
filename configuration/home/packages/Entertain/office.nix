# 办公：文档套件与计算器。
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    libreoffice
    kdePackages.kcalc                         # kcalc（KDE 计算器）
  ];
}
