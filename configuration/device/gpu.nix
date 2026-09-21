# GPU：AMD 显卡驱动、OpenCL/ROCm、I2C(DDC/CI)、Ollama、HIP 运行时
{ pkgs, username, ... }:

{
  # GPU：AMD（amdgpu + mesa RADV + VA-API 硬解）
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;   # Steam/Proton 32 位游戏必需
  hardware.graphics.extraPackages = with pkgs; [
    vulkan-loader
    libva
  ];
  hardware.amdgpu.opencl.enable = true;
  environment.variables.ROC_ENABLE_PRE_VEGA = "1";

  # I2C：ddcutil 经 DDC/CI 调外接显示器亮度（Philips 24E2N1110 @ HDMI-A-1）
  # 本机显示器支持 DDC/CI，i2c 组用于免 root 访问 /dev/i2c-*
  users.users.${username}.extraGroups = [ "i2c" ];
  hardware.i2c.enable = true;
  # udev 规则：/dev/i2c-* 归 i2c 组
  services.udev.extraRules = ''
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
  '';
  services.xserver.videoDrivers = [ "amdgpu" ];

  # HIP 运行时（/opt/rocm）
  systemd.tmpfiles.rules = let
    rocmEnv = pkgs.symlinkJoin {
      name = "rocm-combined";
      paths = with pkgs.rocmPackages; [ rocblas hipblas clr ];
    };
  in [
    "L+ /opt/rocm - - - - ${rocmEnv}"
    "d /.Trash 1777 root root - -"   # 根分区回收站
  ];

  # Ollama（AMD ROCm）
  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;
    rocmOverrideGfx = "10.3.0";  # RX 6600 = gfx1032
  };
}
