# 内核、引导（GRUB/双系统）、休眠、内核参数
{ pkgs, ... }:

{
  # 内核：CachyOS RT-BORE（实时调度 + BORE）
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-rt-bore;

  boot.kernel.sysctl."vm.max_map_count" = 2147483642;
  boot.loader.timeout = 10; # GRUB 选择系统等待 10s

  # 引导：GRUB(UEFI) + os-prober（双系统检测 Windows）
  boot.loader.grub = {
    enable = true;
    useOSProber = true;
    efiSupport = true;
    device = "nodev";
    configurationLimit = 20;
    efiInstallAsRemovable = true;
    # BlueArchive 主题（aris/爱丽丝）
    theme = ../assets/grub-theme/aris/Alice;
  };
  boot.supportedFilesystems = [ "btrfs" ];
  boot.initrd.supportedFilesystems = [ "btrfs" ];

  # 休眠：独立 SWAP 分区（docs/install-btrfs.md 创建）
  boot.resumeDevice = "/dev/disk/by-label/SWAP";
  # LACT / AMD 超频解锁（ppfeaturemask 全开）
  boot.kernelParams = [
    "split_lock_mitigate=0" "amdgpu.ppfeaturemask=0xffffffff" "clearcpuid=514" ];
}
