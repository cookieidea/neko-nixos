{ pkgs, ... }:

{
  home.packages = with pkgs; [
    libreoffice
    transmission_4-gtk
    localsend
  ];
}
