# 自构建包（flake packages + home.nix 安装，`nix build .#<name>` 单独构建）
# rev 固定已知 commit 保可复现，升级改 rev + sha256
# noctalia-shell 来自 nixpkgs（home.nix 直接装），不在这里
{ pkgs, astral-bundle }:
let
  vsPlugins = import ./vs-plugins { inherit pkgs; };
in
rec {
  inherit (vsPlugins)
    l-smash
    vapoursynth-lsmash
    vapoursynth-akarin
    vapoursynth-rife-ncnn
    k7sfunc
    vapoursynth-with-plugins;

  niri-sidebar   = import ./niri-sidebar   { inherit pkgs; };
  pins           = import ./pins           { inherit pkgs; };
  shorin-contrib = import ./shorin-contrib { inherit pkgs; };
  splayer-next   = import ./splayer-next   { inherit pkgs; };
  ab-download-manager = import ./ab-download-manager { inherit pkgs; };
  tabby-terminal  = import ./tabby  { inherit pkgs; };
  obs-vdoninja    = import ./obs-vdoninja { inherit pkgs; };
  purevox         = import ./purevox { inherit pkgs; };
  bedrockboot     = import ./bedrockboot { inherit pkgs; };
  nyxniri-scratch-menu = import ./nyxniri-scratch-menu.nix { inherit pkgs; };
  # astral 的 bundle 由 pkgs/astral/build.sh 联网构建（flake 输入 astral-bundle）
  astral          = import ./astral { inherit pkgs; lib = pkgs.lib; src = astral-bundle; };
  harmonyos-sans-sc = import ./harmonyos-sans-sc { inherit pkgs; };
}
