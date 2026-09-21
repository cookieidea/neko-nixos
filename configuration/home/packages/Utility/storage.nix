{ pkgs, ... }:

{
  home.packages = with pkgs; [
    btrfs-assistant
    gnome-disk-utility                        # 磁盘管理 GUI
  ];
}
