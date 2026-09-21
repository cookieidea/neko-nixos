# 网络基础：主机名、NetworkManager、DNS
#
# 防火墙只保留开关（默认拒绝入站）。各功能所需的端口由其自身模块声明：
#   13960 + 组播路由 → modules/programs/minecraft.nix
#   3081             → modules/programs/dsh.nix
#   1714-1764        → modules/services/kdeconnect.nix
# 这样停用某功能时，其防火墙放行会一并消失。
{ ... }:

{
  networking.hostName = "ATRI";
  networking.firewall.enable = true;
  networking.networkmanager.enable = true;
  # DNS：腾讯 DNSPod（静态写入，不被 DHCP 覆盖）
  networking.networkmanager.dns = "none";
  networking.nameservers = [ "119.29.29.29" "2402:4e00::" ];
}
