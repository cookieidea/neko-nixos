# gvfs：虚拟文件系统（系统层启用）
{ pkgs, ... }:

{
  # 指定 package 与 home.nix 的 GIO_EXTRA_MODULES 同源
  services.gvfs = {
    enable = true;
    package = pkgs.gvfs;
  };
}
