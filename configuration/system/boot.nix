# 内核、引导、休眠和内核参数。
{ pkgs, ... }:

{
  # CachyOS RT-BORE 内核。
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-rt-bore;

  boot.kernel.sysctl."vm.max_map_count" = 2147483642;
  boot.loader.timeout = 10; # GRUB 选择系统等待 10s

  # GRUB UEFI + os-prober。
  boot.loader.grub = {
    enable = true;
    useOSProber = true;
    efiSupport = true;
    device = "nodev";
    configurationLimit = 20;
    efiInstallAsRemovable = true;
    # Blue Archive / Aris GRUB 主题。
    theme = ../assets/grub-theme/aris/Alice;
  };
  boot.supportedFilesystems = [ "btrfs" ];
  boot.initrd.supportedFilesystems = [ "btrfs" ];

  # 休眠使用独立 swap 分区。
  boot.resumeDevice = "/dev/disk/by-label/SWAP";
  # LACT / AMD 调优所需内核参数。
  boot.kernelParams = [
    "split_lock_mitigate=0" "amdgpu.ppfeaturemask=0xffffffff" "clearcpuid=514" ];
}
