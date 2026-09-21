# ATRI 系统配置入口：聚合 system/ + device/ + modules/{programs,services,virtualisation,pkgs}
{ ... }:

{
  imports = [
    # --- 纯系统级配置 ---
    ../system/nix.nix
    ../system/boot.nix
    ../system/networking.nix
    ../system/i18n.nix
    ../system/audio-bluetooth.nix
    ../system/security-users.nix
    ../system/secrets.nix

    # --- 硬件特定 ---
    ./device.nix

    # --- 程序 / 服务 / 虚拟化 模块 ---
    ./modules.nix
  ];
}
