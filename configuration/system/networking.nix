# 网络：主机名、防火墙、DNS、组播回环
{ pkgs, ... }:

{
  networking.hostName = "ATRI";
  # 防火墙：默认拒绝入站；13960=MC 联机，3081=dsh web，1714-1764=KDE Connect
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 13960 3081 ];
    allowedUDPPorts = [ 13960 ];
    allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
    allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
  };
  networking.networkmanager.enable = true;
  # DNS：腾讯 DNSPod；dns="none" 让 nameservers 静态写入（不被 DHCP 覆盖）
  networking.networkmanager.dns = "none";
  networking.nameservers = [ "119.29.29.29" "2402:4e00::" ];

  # 组播回环：IPv4 组播经 lo 投递（MC 局域网联机扫描依赖；cachyos 内核需显式加路由）
  systemd.services.multicast-loopback = {
    description = "Add IPv4 multicast route via lo for local loopback delivery";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.iproute2}/bin/ip route replace 224.0.0.0/4 dev lo";
    };
  };
}
