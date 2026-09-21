# Minecraft：局域网联机所需的网络配置
#
# 归口理由：这些端口/路由只为 Minecraft 联机存在。放在功能模块里，
# 删掉 MC 时相关副作用会一起消失，不会在 networking.nix 里留下孤儿规则。
{ pkgs, ... }:

{
  # MC 局域网联机端口
  networking.firewall.allowedTCPPorts = [ 13960 ];
  networking.firewall.allowedUDPPorts = [ 13960 ];

  # IPv4 组播经 lo 投递（MC 的 LAN 发现依赖组播）
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
