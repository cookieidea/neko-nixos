# LACT 显卡控制 + smartd 磁盘健康监控
{ pkgs, ... }:

{
  services.lact.enable = true;
  services.smartd.enable = true;   # 磁盘健康监控（SMART）
}
