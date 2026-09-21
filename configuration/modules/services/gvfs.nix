# gvfs 虚拟文件系统。
{ pkgs, ... }:

{
  # 与 Home Manager 的 GIO_EXTRA_MODULES 保持同源。
  services.gvfs = {
    enable = true;
    package = pkgs.gvfs;
  };
}
