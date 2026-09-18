# 内核、引导（GRUB/双系统）、休眠、内核参数
{ pkgs, ... }:

{
  # 内核：CachyOS RT-BORE（实时调度 + BORE，直播/推流低延迟）
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-rt-bore;

  boot.kernel.sysctl."vm.max_map_count" = 2147483642;
  boot.loader.timeout = 10; # GRUB 选择系统等待 10s

  # 引导：GRUB(UEFI) + os-prober（双系统检测 Windows）；efiInstallAsRemovable 兜底
  boot.loader.grub = {
    enable = true;
    useOSProber = true;
    efiSupport = true;
    device = "nodev";
    configurationLimit = 20;
    efiInstallAsRemovable = true;
    # BlueArchive 主题（aris/爱丽丝）；其余 4 套未用主题已移出仓库
    # 注意：本文件在 modules/system/ 下，相对路径需回退两级到仓库根
    theme = ../../assets/grub-theme/aris/Alice;
  };
  boot.supportedFilesystems = [ "btrfs" ];
  boot.initrd.supportedFilesystems = [ "btrfs" ];

  # 休眠：btrfs swapfile 官方不支持恢复 → 独立 SWAP 分区（docs/install-btrfs.md 创建）。
  # 显式声明 resumeDevice 兜底（26.05 initrd 会自动检测，异常 EFI 主板也可靠）。
  boot.resumeDevice = "/dev/disk/by-label/SWAP";
  # LACT / AMD 超频解锁（ppfeaturemask 全开）
  boot.kernelParams = [
    "split_lock_mitigate=0" "amdgpu.ppfeaturemask=0xffffffff" "clearcpuid=514" ];
}
