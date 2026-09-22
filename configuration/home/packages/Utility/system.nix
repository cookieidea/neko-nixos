{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gdu
    baobab
    file
    mission-center
  ];
}
