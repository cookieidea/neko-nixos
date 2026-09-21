# KDE Connect：手机与电脑互联。防火墙端口与该服务一起管理。
{ ... }:

{
  networking.firewall.allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
  networking.firewall.allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
}
