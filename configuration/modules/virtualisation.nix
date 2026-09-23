# 游戏与虚拟化：Steam、libvirtd、Waydroid、Docker、distrobox。
{ pkgs, lib, username, ... }:

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

  # rootless Docker 只在真实图形会话中启动。
  #
  # 背景：nixpkgs 的 rootless 单元 wantedBy = [ "default.target" ]，因此
  # **greeter 会话也会拉起它** —— 而登录界面并不需要容器，此时
  # user@1000 的 app.slice 与运行时目录尚未就绪，导致连续失败 4 次
  # （实测 15:33:35/38/40/42，间隔约 2 秒），直到真正的用户会话建立
  # （15:36:11）才成功。虽最终可用，但属无谓的启动竞态与日志噪音。
  #
  # 改为 PartOf + After graphical-session.target：随图形会话启停，
  # 且在会话就绪后才启动，greeter 会话不再触发。
  systemd.user.services.docker = {
    # NixOS 的 systemd 单元用顶层 wantedBy（生成 <target>.wants/ 符号链接），
    # 不是 Install.WantedBy。
    # 必须用 mkForce：nixpkgs 已设 wantedBy = [ "default.target" ]，列表会**合并**
    # 而非覆盖，那样 greeter 会话仍会拉起它（本次修改即失效）。
    wantedBy = lib.mkForce [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
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
