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

  # 休眠使用独立 swap 分区（nvme0n1p2）。
  #
  # 用 UUID 而非 LABEL：UUID 由 mkswap 生成后基本不变，而 LABEL 可被
  # swaplabel 或重新格式化改掉 —— 那样正常运行不受影响（swapDevices 也用
  # UUID），但休眠恢复会静默失效。此处与 hardware-config.nix 的
  # swapDevices 保持同一标识符，便于核对。
  boot.resumeDevice = "/dev/disk/by-uuid/d075506b-2e2f-4451-b0e2-a59da638e8ba";
  # LACT / AMD 调优所需内核参数。
  boot.kernelParams = [
    "split_lock_mitigate=0"
    "amdgpu.ppfeaturemask=0xffffffff"
    "clearcpuid=514"
  ];
}
