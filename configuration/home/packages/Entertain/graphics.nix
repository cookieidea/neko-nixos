{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gimp
    krita
    imv
  ];
}
