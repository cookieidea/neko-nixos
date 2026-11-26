# 音频、蓝牙和电源管理。
{ pkgs, ... }:

{
  # PipeWire（PulseAudio / ALSA / JACK）。
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    jack.enable = true;
  };

  # pactl / paplay / parec 等 PulseAudio 客户端工具。PipeWire 的
  # pipewire-pulse 兼容这套协议，所以只装工具、不启用 pulseaudio 服务。
  # PureVox 之类的应用依赖 pactl 来切换虚拟声卡。
  environment.systemPackages = [ pkgs.pulseaudio ];

  hardware.bluetooth.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  services.blueman.enable = true;
}
