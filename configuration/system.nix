{ ... }:

{
  imports = [
    ./system/nix.nix
    ./system/boot.nix
    ./system/networking.nix
    ./system/i18n.nix
    ./system/audio-bluetooth.nix
    ./system/security-users.nix
    ./system/secrets.nix
    ./system/packages.nix
    ./device.nix
    ./modules.nix
  ];
}
