# niri 本体由 NixOS 的 programs.niri 模块安装（模块会把 cfg.package
# 放进 environment.systemPackages 与 sessionPackages），此处不重复。
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    kitty
    fuzzel
  ];
}
