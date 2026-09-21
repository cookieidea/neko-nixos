{ ... }:

{
  imports = [
    ./system.nix
    ./hardware.nix
    ./virtualisation.nix
    ./network.nix
    ./communication.nix
    ./storage.nix
    ./custom.nix
  ];
}
