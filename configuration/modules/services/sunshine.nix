# Sunshine 串流（Moonlight）。
{ ... }:

{
  services.sunshine = {
    enable = true;
    autoStart = false;
    # 保留 KMS 抓屏所需的 CAP_SYS_ADMIN；Sunshine 未强制固定捕获后端。
    capSysAdmin = true;
    openFirewall = true;
  };
  hardware.uinput.enable = true;
}
