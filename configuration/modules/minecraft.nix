# Minecraft 局域网联机的端口与组播路由。
{ pkgs, ... }:

{
  networking.firewall = {
    # MC 服务端监听端口（TCP）。
    allowedTCPPorts = [ 13960 ];
    # MC Java 版的局域网发现：客户端向组播组 224.0.2.60 的 4445/UDP
    # 发送通告，包内才携带上面那个实际服务端口。故发现端口是 4445，
    # 不是 13960 —— 后者无需开 UDP。
    allowedUDPPorts = [ 4445 ];
  };

    # MC 局域网发现的组播组走 lo，只针对 224.0.2.60/32。
  systemd.services.minecraft-multicast-loopback = {
    description = "Route Minecraft LAN-discovery multicast group to lo";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.iproute2}/bin/ip route replace 224.0.2.60/32 dev lo";
    };
  };
}
