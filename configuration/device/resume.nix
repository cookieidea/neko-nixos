# 休眠恢复设备：由 swapDevices 推导，不在此重复写 UUID。
#
# 背景：boot.resumeDevice 原先硬编码在 system/boot.nix，而 swapDevices 在
# device/hardware-config.nix —— 同一个分区写两遍。换 swap 分区时若只改一处，
# 会出现「正常 swap 可用、休眠恢复静默失效」的配置漂移（这类失败很难察觉）。
#
# 这里从 config.swapDevices 取第一个块设备推导，保持单一数据源：
# 只需维护 hardware-config.nix（本就不该手改，由 nixos-generate-config 生成）。
#
# 说明：沿用 by-uuid 而非 by-label —— UUID 由 mkswap 生成后基本不变，
# 而 LABEL 可被 swaplabel 或重新格式化改掉。
{ config, lib, ... }:

let
  # swapDevices 的 device 字段可能是路径字符串；只取字符串形式的块设备
  # （排除 swapfile 之类），首个即用作 resume 目标。
  swapDevices = map (s: s.device) (builtins.filter (s: s ? device) config.swapDevices);
  resumeDevice = if swapDevices == [ ] then null else builtins.head swapDevices;
in
{
  # boot.resumeDevice 是 types.str（默认 ""），故用 mkIf 控制是否赋值，
  # 不能直接写 null。
  boot.resumeDevice = lib.mkIf (resumeDevice != null) resumeDevice;
}
