{ pkgs, username, ... }:

{
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  hardware.graphics.extraPackages = with pkgs; [
    vulkan-loader
    libva
  ];
  hardware.amdgpu.opencl.enable = true;
  environment.variables.ROC_ENABLE_PRE_VEGA = "1";

  # DDC/CI
  users.users.${username}.extraGroups = [ "i2c" ];
  hardware.i2c.enable = true;
  services.udev.extraRules = ''
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
  '';
  services.xserver.videoDrivers = [ "amdgpu" ];

  # ROCm 运行时
  systemd.tmpfiles.rules = let
    rocmEnv = pkgs.symlinkJoin {
      name = "rocm-combined";
      paths = with pkgs.rocmPackages; [ rocblas hipblas clr ];
    };
  in [
    "L+ /opt/rocm - - - - ${rocmEnv}"
    "d /.Trash 1777 root root - -"
  ];

  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;
    rocmOverrideGfx = "10.3.0";
  };
}
