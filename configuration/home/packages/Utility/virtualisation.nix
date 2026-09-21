{ pkgs, ... }:

{
  home.packages = with pkgs; [
    virt-manager
    virt-viewer
    wineWow64Packages.stable
    icoextract
  ];
}
