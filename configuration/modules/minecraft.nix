# Minecraft：局域网联机所需的网络配置。
#
# 归口理由：这些端口/路由只为 Minecraft 联机存在。放在功能模块里，
# 删掉 MC 时相关副作用会一起消失，不会在 networking.nix 里留下孤儿规则。
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

  # 让 MC 的局域网发现组播在本机环回投递（同一台机器上的客户端要能
  # 看到本机开启的局域网世界）。
  #
  # 只针对 MC 使用的组播组 224.0.2.60/32 —— 不要写成 224.0.0.0/4：
  # 那会把整个 IPv4 组播段（含 mDNS 224.0.0.251、SSDP 239.255.255.250 等）
  # 全部改走 lo，影响 avahi 等依赖组播的服务。
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
