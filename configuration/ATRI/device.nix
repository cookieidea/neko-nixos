# 硬件特定配置（本机硬件：GPU/CPU/存储）
{ ... }:

{
  imports = [
    ../device/hardware/hardware-config.nix
    ../device/hardware/gpu.nix
  ];
}
