# 硬件特定配置（本机硬件：GPU/CPU/存储）
{ ... }:

{
  imports = [
    ./device/hardware-config.nix
    ./device/gpu.nix
    # 休眠恢复设备：从 swapDevices 推导（单一数据源）。
    ./device/resume.nix
  ];
}
