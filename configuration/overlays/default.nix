# 以 NixOS module 形式应用 overlays。
#
# 实际定义在 overlays/list.nix —— 那份同时被 flake.nix 用于构造自己的 pkgs
# 实例，从而保证 flake pkgs 与 NixOS pkgs 的 overlay 配置一致。
{ nix-cachyos-kernel, ... }:

{
  nixpkgs.overlays = import ./list.nix { inherit nix-cachyos-kernel; };
}
