{ pkgs, ... }:

{
  home.packages = with pkgs; [
    eza
    bat
    btop
    fd
    fastfetch
  ];
}
