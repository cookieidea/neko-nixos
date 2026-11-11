{ pkgs, selfPackages, bilihud, cooknixvim, ... }:

let
  # 上游包的 makeWrapperArgs 里写死了 "${qtWrapperArgs[@]}"，新版 nixpkgs
  # 的 makeCWrapper 不接受这个字面量而报错。这里清空它，Qt 插件路径由
  # wrapQtAppsHook 自己处理。
  bilihudPkg = (bilihud.packages.${pkgs.stdenv.hostPlatform.system}.default)
    .overrideAttrs (_: { makeWrapperArgs = [ ]; });
in
{
  home.packages = with pkgs; [
    selfPackages.niri-sidebar
    selfPackages.nyxniri-scratch-menu
    selfPackages.pins
    splayer-next
    selfPackages.ab-download-manager
    selfPackages.tabby-terminal
    selfPackages.astral
    bilihudPkg
    cooknixvim.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
