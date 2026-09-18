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
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "video" "audio" "docker" "uinput" "adbusers" "gamemode" "i2c" ];
  };
}
