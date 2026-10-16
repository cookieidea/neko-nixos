# DDNet 联机的端口。
{ ... }:

{
  networking.firewall = {
    # DDNet 默认端口，TCP 与 UDP 都需要。
    allowedTCPPorts = [ 8303 ];
    allowedUDPPorts = [ 8303 ];
  };
}
