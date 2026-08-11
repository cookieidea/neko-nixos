# Self-built packages for the Shorin Arch → NixOS conversion.
#
# Each entry is a Nix derivation wired into the flake's `packages.<system>`
# output (so `nix build .#<name>` works) and into home.nix `home.packages`
# (so they get installed with `nixos-rebuild switch`).
#
# Source repos were taken from the original Arch setup
# (SHORiN-KiWATA/shorin-arch-setup, scripts/04k-shorin-noctalia-quickshell.sh
# and the AUR `-git` package list). Revisions are pinned to a known commit so
# builds are reproducible; bump `rev` + `sha256` when you want newer code.
#
# NOTE: noctalia-shell is intentionally NOT here — it is provided by the
# `noctalia` flake input (pinned to v4.7.7) and added in home.nix directly.
{ pkgs }:

{
  niri-sidebar   = import ./niri-sidebar   { inherit pkgs; };
  pins           = import ./pins           { inherit pkgs; };
  miyu           = import ./miyu           { inherit pkgs; };
  pywalfox       = import ./pywalfox       { inherit pkgs; };
  shorin-contrib = import ./shorin-contrib { inherit pkgs; };
  proton-wrapper = import ./proton-wrapper { inherit pkgs; };
  splayer-next   = import ./splayer-next   { inherit pkgs; };
}
