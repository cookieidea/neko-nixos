# NixOS 系统配置入口（聚合 modules/system/ 下的各模块）
{ config, pkgs, lib, username, noctalia-greeter, selfPackages, ... }:

{
  imports = [
    ./modules/system/nix.nix
    ./modules/system/boot.nix
    ./modules/system/networking.nix
    ./modules/system/i18n.nix
    ./modules/system/audio-bluetooth.nix
    ./modules/system/gpu.nix
    ./modules/system/desktop.nix
    ./modules/system/secrets.nix
    ./modules/system/security-users.nix
    ./modules/system/virtualisation.nix
    ./modules/system/services.nix
  ];
}
