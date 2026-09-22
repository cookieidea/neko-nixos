# 安全策略、polkit 和用户账户。
{ username, ... }:

{
  security.polkit.enable = true;
  # Noctalia greeter 外观同步允许 wheel 免密调用 pkexec。
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
    # 功能相关组由对应模块追加；停用功能时权限也会随模块移除。
    #   libvirtd/docker/uinput/adbusers/gamemode → modules/virtualisation.nix
    #   i2c                                   → device/gpu.nix
    #   video/audio         → 基础（显卡/声卡设备访问）
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
  };
}
