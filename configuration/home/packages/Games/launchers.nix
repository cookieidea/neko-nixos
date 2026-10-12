{ pkgs, ... }:

{
  home.packages = with pkgs; [
    lutris
    protonplus
    # nixpkgs 版非 flatpak 沙箱封装，关闭启动时的 Unsupported Environment 提示。
    (bottles.override { removeWarningPopup = true; })
  ];
}
