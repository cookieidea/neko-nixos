# dsh Web UI 端口。与模块绑定，停用 dsh 时自动移除防火墙规则。
{ ... }:

{
  networking.firewall.allowedTCPPorts = [ 3081 ];
}
