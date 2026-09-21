# KDE Connect：手机 ↔ 电脑（文件互传/剪贴板同步/媒体控制）
#
# 归口理由：防火墙端口范围只服务于 KDE Connect。
# HM 侧的服务定义见 configuration/home/desktop/default.nix。
{ ... }:

{
  networking.firewall.allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
  networking.firewall.allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
}
