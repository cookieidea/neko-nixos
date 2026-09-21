# Sunshine 串流（Moonlight；capSysAdmin + uinput）
{ ... }:

{
  # Sunshine（Moonlight 串流）：capSysAdmin 供 KMS 抓屏，uinput 模拟键鼠/手柄
  services.sunshine = {
    enable = true;
    autoStart = false;
    capSysAdmin = true;
    openFirewall = true;
  };
  hardware.uinput.enable = true;
}
