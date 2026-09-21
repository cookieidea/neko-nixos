# 游戏与虚拟化：Steam、libvirtd、Waydroid、Docker、distrobox。
{ pkgs, username, ... }:

{
  programs.gamemode.enable = true; # 游戏性能优化服务
  programs.nix-ld.enable = true;   # 跑预编译二进制
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib     # libstdc++.so.6
    zlib                  # libz.so.1
    libgcc.lib           # libgcc_s.so.1
    libxcb               # libxcb.so.1
    libglvnd             # libGL.so.1
    glib                 # libgthread-2.0.so.0
  ];

  programs.steam.enable = true;
  # Steam 中文字体。
  programs.steam.fontPackages = with pkgs; [ sarasa-gothic ];
  # GE-Proton。
  programs.steam.extraCompatPackages = with pkgs; [ proton-ge-bin ];
  # Steam 远程游玩和专用服务器端口。
  programs.steam.remotePlay.openFirewall = true;
  programs.steam.dedicatedServer.openFirewall = true;

  virtualisation.libvirtd.enable = true;
  # Waydroid Android 容器网络。
  virtualisation.waydroid.enable = true;
  virtualisation.waydroid.package = pkgs.waydroid-nftables;
  services.geoclue2.enable = true;   # Waydroid GPS 转发
  systemd.packages = [ pkgs.waydroid-helper ];
  systemd.services.waydroid-mount.wantedBy = [ "multi-user.target" ];

  virtualisation.docker.enable = true;
  # Docker Hub 镜像。
  virtualisation.docker.daemon.settings.registry-mirrors = [
    "https://docker.1ms.run"
    "https://docker.xuanyuan.me"
    "https://docker.m.daocloud.io"
  ];
  # distrobox：挂载 /nix/store 和用户 profile。
  environment.etc."distrobox/distrobox.conf".text = ''
    container_additional_volumes="/nix/store:/nix/store:ro /etc/profiles/per-user:/etc/profiles/per-user:ro /etc/static/profiles/per-user:/etc/static/profiles/per-user:ro"
  '';

  # 本模块涉及的用户组。
  users.users.${username}.extraGroups = [
    "libvirtd"    # virt-manager 免 sudo
    "docker"      # docker 免 sudo
    "uinput"      # Waydroid / 手柄模拟输入
    "adbusers"    # adb / Waydroid
    "gamemode"    # gamemoded 性能调度
  ];

}
