# GPU：AMD 显卡驱动、OpenCL/ROCm、I2C(DDC/CI)、Ollama、HIP 运行时
{ pkgs, ... }:

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

  # I2C：ddcutil 通过 DDC/CI 調外接显示器亮度、读 EDID。
  # 需加载 i2c-dev（否则无 /dev/i2c-*）+ i2c 组权限（普通用户否则 EACCES）。
  # 显示器为 Philips 24E2N1110 @ HDMI-A-1（/dev/i2c-6），无 sysfs backlight 设备。
  hardware.i2c.enable = true;
  # hardware.i2c.enable 只建 i2c 组、加载 i2c-dev，不改设备节点属主（仍是 root:root 0600），
  # 普通用户跑 ddcutil 会 EACCES。补 udev 规则把 /dev/i2c-* 归到 i2c 组。
  services.udev.extraRules = ''
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
  '';
  services.xserver.videoDrivers = [ "amdgpu" ];
  # 12400F 无核显 → 不需要 intel 驱动；非笔记本双显卡 → 不需要 NVIDIA Prime/offload。

  # HIP 运行时（PyTorch/llama.cpp/ollama 找 /opt/rocm）
  systemd.tmpfiles.rules = let
    rocmEnv = pkgs.symlinkJoin {
      name = "rocm-combined";
      paths = with pkgs.rocmPackages; [ rocblas hipblas clr ];
    };
  in [
    "L+ /opt/rocm - - - - ${rocmEnv}"
    "d /.Trash 1777 root root - -"   # 根分区回收站（Nautilus 删根分区文件用）
  ];

  # Ollama（AMD ROCm）
  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;
    rocmOverrideGfx = "10.3.0";  # RX 6600 = gfx1032
  };
}
