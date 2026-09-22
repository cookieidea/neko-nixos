# 休眠恢复设备：从 swapDevices 推导，避免 UUID 两处重复维护。
#
# 背景：boot.resumeDevice 原先硬编码在 system/boot.nix，与
# device/hardware-config.nix 的 swapDevices 是同一个分区却写两遍；
# 换 swap 分区时若漏改一处，会出现「正常 swap 可用、休眠恢复静默失效」的漂移。
#
# 适用范围（刻意收窄，不做「看似通用的推导器」）：
#   支持：恰好一个块设备 swap（如本机的独立 swap 分区，by-uuid）。
#   不支持：swapfile（休眠还需 swapfile offset，不能只给路径）、多个 swap
#           （无法判断哪个才是 resume 目标）、LUKS/LVM 等需要映射后设备的场景。
#   遇到不支持的情况会通过 assertions 明确报错，而不是悄悄推导出错误的值 ——
#   届时在 system/boot.nix 显式写 boot.resumeDevice 即可。
{ config, lib, ... }:

let
  # 块设备 swap：NixOS 内部同样以 "/dev/" 前缀区分设备与 swapfile
  # （见 swap.nix 的 isDevice），不能只判断 device 字段是否存在 ——
  # swapfile 同样带 device 字段。
  blockSwaps = builtins.filter (s: lib.hasPrefix "/dev/" s.device) config.swapDevices;
in
{
  assertions = [
    {
      assertion = builtins.length blockSwaps <= 1;
      message = ''
        device/resume.nix 只支持「单个块设备 swap」。
        当前检测到 ${toString (builtins.length blockSwaps)} 个，无法判断哪个用于休眠恢复。
        请在 configuration/system/boot.nix 中显式设置 boot.resumeDevice，
        或停用 device/resume.nix 的导入。
      '';
    }
    {
      assertion = config.swapDevices == [ ] || blockSwaps != [ ];
      message = ''
        device/resume.nix 检测到有 swapDevices，但没有一个是块设备（形如 /dev/...），
        推测只配置了 swapfile。休眠恢复需要块设备，仅给 swapfile 路径不足以恢复
        （还需 swapfile offset）。请显式设置 boot.resumeDevice，
        或停用 device/resume.nix 的导入。
      '';
    }
  ];

  # boot.resumeDevice 是 types.str（默认 ""），用 mkIf 控制是否赋值。
  boot.resumeDevice = lib.mkIf (blockSwaps != [ ]) (builtins.head blockSwaps).device;
}
