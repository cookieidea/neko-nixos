{ pkgs, ... }:

{
  home.packages = with pkgs; [
    niri
    kitty
    fuzzel
  ];
}
