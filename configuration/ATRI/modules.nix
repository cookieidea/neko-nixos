# 聚合 programs / services / virtualisation 模块
{ ... }:

{
  imports = [
    # --- 系统级程序 ---
    ../modules/programs/desktop.nix

    # --- 系统服务 ---
    ../modules/services/openssh.nix
    ../modules/services/udisks2.nix
    ../modules/services/gvfs.nix
    ../modules/services/snapper.nix
    ../modules/services/sunshine.nix
    ../modules/services/lact-smartd.nix

    # --- 虚拟化 / 游戏运行时 ---
    ../modules/virtualisation/default.nix
  ];
}
