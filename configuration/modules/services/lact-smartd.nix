# LACT 显卡控制和 smartd 磁盘健康监控。
{ ... }:

{
  services.lact.enable = true;
  services.smartd.enable = true;   # 磁盘健康监控（SMART）
}
