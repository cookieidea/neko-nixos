{ pkgs, ... }:

{
  home.packages = with pkgs; [
    adwaita-icon-theme
    papirus-icon-theme
    hicolor-icon-theme
    font-awesome
    kdePackages.breeze
    adw-gtk3
    nwg-look
    matugen
    gnome-keyring
  ];
}
