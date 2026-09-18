# 游戏与虚拟化：Steam、libvirtd、Waydroid、Docker、distrobox
{ pkgs, ... }:

{
  programs.gamemode.enable = true; # gamemoderun 系统服务（游戏性能优化）
  programs.nix-ld.enable = true;   # 跑预编译二进制（游戏/工具的 patchelf 兜底）
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib     # libstdc++.so.6
    zlib                  # libz.so.1
    libgcc.lib           # libgcc_s.so.1
    libxcb               # libxcb.so.1
    libglvnd             # libGL.so.1
    glib                 # libgthread-2.0.so.0
  ];

  programs.steam.enable = true;
  # Steam 中文字体（用静态 sarasa）
  programs.steam.fontPackages = with pkgs; [ sarasa-gothic ];
  # GE-Proton
  programs.steam.extraCompatPackages = with pkgs; [ proton-ge-bin ];
  # 远程游玩 / 专用服务器：自动放行所需端口
  programs.steam.remotePlay.openFirewall = true;
  programs.steam.dedicatedServer.openFirewall = true;

  virtualisation.libvirtd.enable = true;
  # Waydroid（Android 容器，nftables 版）
  virtualisation.waydroid.enable = true;
  virtualisation.waydroid.package = pkgs.waydroid-nftables;
  services.geoclue2.enable = true;   # Waydroid GPS 转发
  systemd.packages = [ pkgs.waydroid-helper ];
  systemd.services.waydroid-mount.wantedBy = [ "multi-user.target" ];

  virtualisation.docker.enable = true;
  # Docker Hub 国内镜像
  virtualisation.docker.daemon.settings.registry-mirrors = [
    "https://docker.1ms.run"
    "https://docker.xuanyuan.me"
    "https://docker.m.daocloud.io"
  ];
  # distrobox：挂载 /nix/store 与 per-user profiles
  environment.etc."distrobox/distrobox.conf".text = ''
    container_additional_volumes="/nix/store:/nix/store:ro /etc/profiles/per-user:/etc/profiles/per-user:ro /etc/static/profiles/per-user:/etc/static/profiles/per-user:ro"
  '';
}
