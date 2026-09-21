{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gcc
    gnumake
    pkg-config
    patchelf
    pnpm
  ];
}
