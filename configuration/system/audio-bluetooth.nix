# 音频、蓝牙、电源管理
{ ... }:

{
  # 音频：PipeWire（pulse/alsa/jack）
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    jack.enable = true;
  };

  hardware.bluetooth.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  services.blueman.enable = true;
}
