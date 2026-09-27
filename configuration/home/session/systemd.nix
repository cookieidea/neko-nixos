{ hmLib, ... }:

{
  systemd.user.sessionVariables = hmLib.devEnv // {
    # 输入法走 Wayland text-input 协议，不设全局 immodule 变量。
  };

  systemd.user.services.noctalia-wallpaper = {
    Unit = {
      Description = "Set random anime wallpaper via noctalia";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "%h/.config/scripts/noctalia-wallpaper-autostart.sh";
      TimeoutStartSec = 300;
      Restart = "on-failure";
      RestartSec = 15;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
