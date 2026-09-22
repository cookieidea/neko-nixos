# 内核、引导、休眠和内核参数。
{ pkgs, ... }:

{
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-rt-bore;

  boot.kernel.sysctl."vm.max_map_count" = 2147483642;
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

  boot.kernelParams = [
    "split_lock_mitigate=0"
    "amdgpu.ppfeaturemask=0xffffffff"
    "clearcpuid=514"
  ];
}
