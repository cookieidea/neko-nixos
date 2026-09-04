# 自构建包（flake 的 packages.<system> + home.nix 安装，`nix build .#<name>` 可单独构建）
#
# Source repos were taken from the original Arch setup
# (SHORiN-KiWATA/shorin-arch-setup, scripts/04k-shorin-noctalia-quickshell.sh
# and the AUR `-git` package list). Revisions are pinned to a known commit so
# builds are reproducible; bump `rev` + `sha256` when you want newer code.
#
# NOTE: noctalia-shell is intentionally NOT here — it now comes from nixpkgs
# (pkgs.noctalia-shell, a quickshell config + qs wrapper) and is added in
# home.nix directly, replacing the standalone `noctalia` v4 app flake input.
{ pkgs, rustToolchain, astral-bundle }:

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
  axolotl         = import ./axolotl { inherit pkgs rustToolchain; };
  nyxniri-scratch-menu = import ./nyxniri-scratch-menu.nix { inherit pkgs; };
  # Astral 组网客户端（Flutter+Rust；bundle 由 pkgs/astral/build.sh 联网构建，
  # flake 输入 astral-bundle 以 path 引用，升级跑 build.sh 即可）
  astral          = import ./astral { inherit pkgs; lib = pkgs.lib; src = astral-bundle; };
}
