# DeepSeek Harness（dsh）：Web UI 端口
#
# 归口理由：3081 是 dsh web 的监听端口。端口声明放这里，
# 卸载 dsh 时不会遗留防火墙放行。
{ ... }:

{
  networking.firewall.allowedTCPPorts = [ 3081 ];
}
