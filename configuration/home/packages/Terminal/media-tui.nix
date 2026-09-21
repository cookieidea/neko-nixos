{ pkgs, ... }:

{
  home.packages = with pkgs; [
    yazi
    timg
    cava
    cmatrix
    lolcat
    sl
  ];
}
