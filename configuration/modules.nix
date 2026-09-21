# 聚合系统功能模块。
{ ... }:

{
  imports = [
    # 系统程序。
    ./modules/desktop.nix
    ./modules/minecraft.nix    # MC 联机端口 + 组播路由
    ./modules/dsh.nix          # dsh web 端口

    # 系统服务。
    ./modules/services/openssh.nix
    ./modules/services/udisks2.nix
    ./modules/services/gvfs.nix
    ./modules/services/snapper.nix
    ./modules/services/sunshine.nix
    ./modules/services/lact-smartd.nix
    ./modules/services/kdeconnect.nix   # KDE Connect 端口范围

    # 虚拟化和游戏运行时。
    ./modules/virtualisation.nix
  ];
}
