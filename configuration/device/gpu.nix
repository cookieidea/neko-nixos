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
    # 6750 GRE 10GB 报告为 gfx1032，而 ollama-rocm 附带的 rocblas 只提供
    # gfx1030 内核（实测 rocblas/library 下 gfx1032 文件数为 0），
    # 故让 ROCm 按 gfx1030 加载。
    rocmOverrideGfx = "10.3.0";
    # ollama 把 HIP 后端放在 lib/ollama/rocm_v7_2/libggml-hip.so，但它默认
    # 只在 lib/ollama 下扫描后端，导致启动时只加载 CPU 后端：
    #   common_param: - CPU : 12th Gen Intel(R) Core(TM) i5-12400F
    #   load_tensors: CPU model buffer size = ...
    # 表现为推理全部在 CPU 上跑。显式指向该后端文件后设备可见：
    #   ROCm0: AMD Radeon RX 6750 GRE 10GB (10224 MiB, 10182 MiB free)
    environmentVariables.GGML_BACKEND_PATH = "${pkgs.ollama-rocm}/lib/ollama/rocm_v7_2/libggml-hip.so";
  };
}
