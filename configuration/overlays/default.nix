  # 以 NixOS module 形式应用 overlays，定义在 list.nix。
{ nix-cachyos-kernel, ... }:

{
  nixpkgs.overlays = import ./list.nix { inherit nix-cachyos-kernel; };
}
