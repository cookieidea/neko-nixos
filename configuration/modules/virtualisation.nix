# 游戏与虚拟化：Steam、libvirtd、Waydroid、Docker、distrobox。
{ pkgs, username, ... }:

{
  programs.gamemode.enable = true;
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    libgcc.lib
    libxcb
    libglvnd
    glib
  ];

  programs.steam.enable = true;
  programs.steam.fontPackages = with pkgs; [ sarasa-gothic ];
  programs.steam.extraCompatPackages = with pkgs; [ proton-ge-bin ];
  programs.steam.remotePlay.openFirewall = true;
  programs.steam.dedicatedServer.openFirewall = true;

  virtualisation.libvirtd.enable = true;
  virtualisation.waydroid.enable = true;
  virtualisation.waydroid.package = pkgs.waydroid-nftables;
  services.geoclue2.enable = true;
  systemd.packages = [ pkgs.waydroid-helper ];
  systemd.services.waydroid-mount.wantedBy = [ "multi-user.target" ];

  virtualisation.docker.enable = true;

  # 普通用户默认使用 rootless Docker，避免 docker 组直接获得 root-equivalent daemon 访问。
  # rootful docker.service 仍保留；需要管理宿主机 daemon 时使用 sudo docker。
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
    daemon.settings.registry-mirrors = [
      "https://docker.1ms.run"
      "https://docker.m.daocloud.io"
    ];
  };

  environment.etc."distrobox/distrobox.conf".text = ''
    container_additional_volumes="/nix/store:/nix/store:ro /etc/profiles/per-user:/etc/profiles/per-user:ro /etc/static/profiles/per-user:/etc/static/profiles/per-user:ro"
  '';

  users.users.${username}.extraGroups = [
    "libvirtd"
    "uinput"
    "adbusers"
    "gamemode"
  ];
}
