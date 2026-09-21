# 基础网络：主机名、NetworkManager 和 DNS。
# 防火墙只在这里设置全局策略；功能端口由对应模块声明。
{ hostname, ... }:

{
  # 取自 flake.nix 的 hostname（单一数据源，勿在此硬编码）
  networking.hostName = hostname;
  networking.firewall.enable = true;
  networking.networkmanager.enable = true;
  # DNS：使用固定 DNSPod 地址，不由 DHCP 覆盖。
  networking.networkmanager.dns = "none";
  networking.nameservers = [ "119.29.29.29" "2402:4e00::" ];
}
