{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gnome-font-viewer
    usbutils
    pciutils
  ];
}
