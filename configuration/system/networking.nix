# 基础网络：主机名、NetworkManager、systemd-resolved 和 DNS。
# 防火墙只在这里设置全局策略；功能端口由对应模块声明。
{ hostname, ... }:

{
  # 取自 flake.nix 的 hostname（单一数据源，勿在此硬编码）
  networking.hostName = hostname;
  networking.firewall.enable = true;
  networking.networkmanager.enable = true;

  # 使用 systemd-resolved 接管 DNS：保留本机常用 DNS，同时允许 VPN / DHCP
  # 通过 NetworkManager 写入按链路 DNS 与路由域，不再强制所有连接共用裸 resolv.conf。
  services.resolved.enable = true;
  networking.networkmanager.dns = "systemd-resolved";
  networking.nameservers = [ "119.29.29.29" "2402:4e00::" ];

  services.resolved.settings.Resolve = {
    FallbackDNS = [
      "223.5.5.5"
      "1.1.1.1"
      "2606:4700:4700::1111"
    ];
  };
}
