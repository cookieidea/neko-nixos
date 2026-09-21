# Sunshine 串流（Moonlight）。
{ ... }:

{
  # 使用 KMS 抓屏和 uinput 输入注入。
  services.sunshine = {
    enable = true;
    autoStart = false;
    capSysAdmin = true;
    openFirewall = true;
  };
  hardware.uinput.enable = true;
}
