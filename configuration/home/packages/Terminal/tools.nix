# 通用终端工具。eza / bat 由 programs.eza、programs.bat 安装与配置，此处不重复。
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    btop
    fd
    fastfetch
  ];
}
