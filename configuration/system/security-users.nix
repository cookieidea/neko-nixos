# 安全：polkit 与用户账户
{ username, ... }:

{
  security.polkit.enable = true;
  # Noctalia greeter 外观同步（pkexec）免密放行 wheel
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
        if (action.id == "org.noctalia.greeter.sync-appearance" &&
            subject.isInGroup("wheel")) {
            return polkit.Result.YES;
        }
    });
  '';

  users.users.${username} = {
    isNormalUser = true;
    description = username;
    # 基础组。功能相关组由各功能模块自行追加（见下方注释），
    # 这样停用某功能时其权限会一并消失。
    #   libvirtd/docker     → modules/virtualisation/default.nix
    #   uinput/adbusers     → 同上（Waydroid 需要）
    #   gamemode            → 同上
    #   i2c                 → device/hardware/gpu.nix（DDC 亮度控制）
    #   video/audio         → 基础（显卡/声卡设备访问）
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
  };
}
