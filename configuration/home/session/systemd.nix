{ hmLib, pkgs, ... }:

{
  systemd.user.sessionVariables = hmLib.devEnv // {
    # Nautilus 扩展环境由 nautilus-with-extensions 自身的 wrapper 提供。
    GI_TYPELIB_PATH = "${pkgs.nautilus}/lib/girepository-1.0";

    # XDG_DATA_DIRS 由系统环境提供，不在此覆盖。
    # X11/XWayland 应用需要 GTK/Qt 输入法模块。
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
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
