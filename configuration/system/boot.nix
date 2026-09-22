# 内核、GRUB 和启动参数。
{ pkgs, ... }:

{
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-rt-bore;

  # Chromium、Java、Waydroid 等高 VMA 应用使用更大的映射上限。
  boot.kernel.sysctl."vm.max_map_count" = 262144;

  boot.loader.timeout = 10;
  boot.loader.grub = {
    enable = true;
    useOSProber = true;
    efiSupport = true;
    device = "nodev";
    configurationLimit = 20;
    efiInstallAsRemovable = true;
    theme = ../assets/grub-theme/aris/Alice;
  };

  boot.supportedFilesystems = [ "btrfs" ];
  boot.initrd.supportedFilesystems = [ "btrfs" ];

  # LACT 的 AMD Overdrive 功能需要开放 amdgpu power feature mask。
  # 不在这里关闭 split-lock / CPUID 等内核安全或兼容性机制。
  boot.kernelParams = [
    "amdgpu.ppfeaturemask=0xffffffff"
  ];
}
