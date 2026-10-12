{ pkgs, ... }:

{
  home.packages = with pkgs; [
    lutris
    protonplus
    bottles
  ];
}
