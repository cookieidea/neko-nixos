# WSL 覆盖层：复用 configuration.nix 的公共部分（niri/Noctalia/输入法/软件包/home-manager），
# 用 mkForce 覆盖掉实体机专属项（GRUB/btrfs/snapper/休眠/NetworkManager/GPU 控制/Steam/libvirtd/蓝牙），
# 并启用 NixOS-WSL（systemd + WSLg）。
#
# 用法（在 WSL 的 NixOS 里，仓库已 clone 到本地）：
#   nixos-rebuild switch --flake .#wsl
# 或直接引用仓库：
#   nixos-rebuild switch --flake github:cookieidea/neko-nixos#wsl
#
# ⚠️ niri 是 Wayland 合成器，WSLg 里可能因无真实 DRM 起不来；起不来时桌面可退回
#   直接用 WSLg 窗口跑应用，或改试 sway/KDE（见 docs 或询问）。
{ config, pkgs, lib, username, ... }:

{
  # ── NixOS-WSL（systemd + WSLg + 默认用户）──
  wsl.enable = true;
  wsl.defaultUser = username;

  # ── 覆盖 configuration.nix 中的实体机项 ──
  boot.loader.grub.enable = lib.mkForce false;          # WSL 引导由 NixOS-WSL 自管
  boot.resumeDevice = lib.mkForce null;                 # 无休眠
  networking.networkmanager.enable = lib.mkForce false; # WSL 网络由系统自管
  services.lact.enable = lib.mkForce false;             # 无 AMD GPU 控制（WSL 无真实 GPU）
  programs.steam.enable = lib.mkForce false;            # WSL 不装 Steam
  virtualisation.libvirtd.enable = lib.mkForce false;   # WSL 不跑 libvirtd
  hardware.bluetooth.enable = lib.mkForce false;        # 无蓝牙
  services.blueman.enable = lib.mkForce false;
  services.xserver.videoDrivers = lib.mkForce [ ];      # niri 纯 Wayland，无 X server
  services.snapper = lib.mkForce { };                   # 无 btrfs，快照关闭

  # WSL 初始密码（首次登录后请尽快 `passwd` 修改；greetd 会自动登录桌面，此密码用于 sudo）
  users.users.${username}.initialPassword = "changeme";
}
