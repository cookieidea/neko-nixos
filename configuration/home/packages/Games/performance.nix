{ pkgs, ... }:

{
  home.packages = with pkgs; [
    mangohud
    mangojuice
  ];
}
