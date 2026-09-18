# LACT 显卡控制 + smartd 磁盘健康监控
{ pkgs, ... }:

{
  # 应用级服务
  services.lact.enable = true;
  services.smartd.enable = true;   # 磁盘健康监控（SMART）
}
