{ config, lib, ... }:

let
  # 仅处理 /dev/... 形式的块设备 swap。
  blockSwaps = builtins.filter (s: lib.hasPrefix "/dev/" s.device) config.swapDevices;
in
{
  assertions = [
    {
      assertion = builtins.length blockSwaps <= 1;
      message = ''
        device/resume.nix 只支持单个块设备 swap。
        当前检测到 ${toString (builtins.length blockSwaps)} 个，请显式设置 boot.resumeDevice。
      '';
    }
    {
      assertion = config.swapDevices == [ ] || blockSwaps != [ ];
      message = ''
        device/resume.nix 只支持 /dev/... 形式的 swap。
        swapfile 需要显式设置 boot.resumeDevice 和 offset。
      '';
    }
  ];

  boot.resumeDevice = lib.mkIf (blockSwaps != [ ]) (builtins.head blockSwaps).device;
}
