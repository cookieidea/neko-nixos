{ ... }:

{
  imports = [
    # 桌面与应用
    ./modules/desktop.nix
    ./modules/minecraft.nix
    ./modules/dsh.nix
    ./modules/flatpak.nix

    # 服务
    ./modules/services/openssh.nix
    ./modules/services/udisks2.nix
    ./modules/services/gvfs.nix
    ./modules/services/snapper.nix
    ./modules/services/sunshine.nix
    ./modules/services/lact-smartd.nix
    ./modules/services/kdeconnect.nix
    ./modules/services/astral.nix

    # 虚拟化
    ./modules/virtualisation.nix
  ];
}
