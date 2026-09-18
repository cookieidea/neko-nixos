# udisks2：USB 自动挂载
{ pkgs, ... }:

{
  services.udisks2.enable = true;   # USB 自动挂载
}
