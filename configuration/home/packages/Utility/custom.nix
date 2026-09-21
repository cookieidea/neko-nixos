{ pkgs, selfPackages, bilihud, cooknixvim, ... }:

{
  home.packages = with pkgs; [
    selfPackages.niri-sidebar
    selfPackages.nyxniri-scratch-menu
    selfPackages.pins
    selfPackages.shorin-contrib
    selfPackages.splayer-next
    selfPackages.ab-download-manager
    selfPackages.tabby-terminal
    selfPackages.astral
    bilihud.packages.${pkgs.stdenv.hostPlatform.system}.default
    cooknixvim.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
